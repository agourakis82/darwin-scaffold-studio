"""
GNN Model for Polymer Reproducibility Prediction
================================================

Predicts the coefficient of variation (CV) of polymer degradation
from molecular structure using Graph Neural Networks.

Architecture:
- Input: Molecular graph (atoms as nodes, bonds as edges)
- GNN: Message passing to learn structural features
- Output: Predicted CV and effective Omega

Key Innovation:
- Uses entropic causality law as physics-informed constraint
- Loss = MSE(CV) + lambda * |C_predicted - Omega^(-ln(2)/d)|
"""

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.nn import GCNConv, GATConv, global_mean_pool, global_add_pool
from torch_geometric.data import Data, DataLoader
from typing import List, Tuple, Dict, Optional
import json

# ============================================================================
# MOLECULAR GRAPH REPRESENTATION
# ============================================================================

# Atom features
ATOM_TYPES = ['C', 'N', 'O', 'H', 'S', 'P', 'F', 'Cl', 'Br', 'I', 'Other']
HYBRIDIZATION = ['SP', 'SP2', 'SP3', 'SP3D', 'SP3D2', 'Other']

def one_hot(value: str, options: List[str]) -> List[float]:
    """One-hot encode a categorical value"""
    encoding = [0.0] * len(options)
    try:
        idx = options.index(value)
        encoding[idx] = 1.0
    except ValueError:
        encoding[-1] = 1.0  # 'Other' category
    return encoding

def atom_features(atom_type: str, hybridization: str,
                  is_aromatic: bool, is_in_ring: bool,
                  formal_charge: int, n_hydrogens: int) -> List[float]:
    """Generate feature vector for an atom"""
    features = []
    features.extend(one_hot(atom_type, ATOM_TYPES))  # 11 features
    features.extend(one_hot(hybridization, HYBRIDIZATION))  # 6 features
    features.append(float(is_aromatic))  # 1 feature
    features.append(float(is_in_ring))  # 1 feature
    features.append(formal_charge / 2.0)  # 1 feature (normalized)
    features.append(n_hydrogens / 4.0)  # 1 feature (normalized)
    return features  # Total: 21 features

def bond_features(bond_type: str, is_conjugated: bool,
                  is_in_ring: bool) -> List[float]:
    """Generate feature vector for a bond"""
    bond_types = ['SINGLE', 'DOUBLE', 'TRIPLE', 'AROMATIC', 'Other']
    features = []
    features.extend(one_hot(bond_type, bond_types))  # 5 features
    features.append(float(is_conjugated))  # 1 feature
    features.append(float(is_in_ring))  # 1 feature
    return features  # Total: 7 features

# ============================================================================
# POLYMER DATASET
# ============================================================================

class PolymerData:
    """Polymer degradation data with structure"""
    def __init__(self, name: str, smiles: str, cv_observed: float,
                 mechanism: str, omega_raw: int,
                 temperature: float = 37.0, pH: float = 7.4):
        self.name = name
        self.smiles = smiles
        self.cv_observed = cv_observed
        self.mechanism = mechanism  # 'chain_end' or 'random'
        self.omega_raw = omega_raw
        self.temperature = temperature
        self.pH = pH

# Representative polymer data (simplified SMILES for backbone units)
POLYMER_DATASET = [
    # Chain-end scission polymers (low CV)
    PolymerData("PLA", "CC(=O)OCC", 6.2, "chain_end", 50, 37.0, 7.4),
    PolymerData("PGA", "C(=O)OCC", 5.8, "chain_end", 40, 37.0, 7.4),
    PolymerData("PCL", "CCCCCC(=O)O", 7.1, "chain_end", 80, 37.0, 7.4),
    PolymerData("PHBV", "CC(CC(=O)O)O", 6.8, "chain_end", 60, 37.0, 7.4),
    PolymerData("PDO", "OCCCO", 7.5, "chain_end", 70, 37.0, 7.4),

    # Random scission polymers (higher CV)
    PolymerData("PLGA_50_50", "CC(=O)OCC.C(=O)OCC", 15.2, "random", 200, 37.0, 7.4),
    PolymerData("PBAT", "CCOC(=O)c1ccc(C(=O)OCC)cc1", 18.5, "random", 300, 37.0, 7.4),
    PolymerData("PBS", "CCOC(=O)CCC(=O)OCC", 16.8, "random", 250, 37.0, 7.4),
    PolymerData("PU_ester", "NC(=O)OCCOC(=O)N", 21.3, "random", 400, 37.0, 7.4),
    PolymerData("PBSA", "CCOC(=O)CCC(=O)OCC.CCOC(=O)CC(=O)OCC", 19.7, "random", 350, 37.0, 7.4),

    # Crosslinked (very high CV)
    PolymerData("PGMA", "CC(C)(C(=O)OCC1OC1)C", 25.5, "random", 500, 37.0, 7.4),
    PolymerData("PDLA_crosslinked", "CC(=O)OCC.CC(=O)OCC(O)C", 28.2, "random", 600, 37.0, 7.4),
]

def create_synthetic_graph(smiles: str) -> Data:
    """
    Create a PyTorch Geometric Data object from SMILES.
    (Simplified version - in practice use RDKit)
    """
    # Parse SMILES to get atoms and bonds
    # This is a simplified parser - real implementation would use RDKit
    atoms = []
    bonds = []

    # Simple atom extraction (very simplified)
    atom_chars = {'C': 'C', 'N': 'N', 'O': 'O', 'H': 'H', 'S': 'S', 'c': 'C', 'n': 'N', 'o': 'O'}

    current_atoms = []
    for char in smiles:
        if char in atom_chars:
            current_atoms.append(atom_chars[char])

    if not current_atoms:
        current_atoms = ['C', 'C', 'O', 'C']  # Default

    n_atoms = len(current_atoms)

    # Create node features
    x = []
    for i, atom in enumerate(current_atoms):
        features = atom_features(
            atom_type=atom,
            hybridization='SP3',
            is_aromatic=(atom in ['c', 'n', 'o']),
            is_in_ring=False,
            formal_charge=0,
            n_hydrogens=2
        )
        x.append(features)

    x = torch.tensor(x, dtype=torch.float)

    # Create edge index (simple chain connectivity)
    edge_index = []
    edge_attr = []

    for i in range(n_atoms - 1):
        # Forward edge
        edge_index.append([i, i + 1])
        edge_attr.append(bond_features('SINGLE', False, False))

        # Backward edge (undirected)
        edge_index.append([i + 1, i])
        edge_attr.append(bond_features('SINGLE', False, False))

    # Add some random connections for rings/branches
    if n_atoms > 4 and np.random.random() > 0.5:
        i, j = 0, n_atoms - 1
        edge_index.append([i, j])
        edge_attr.append(bond_features('SINGLE', False, True))
        edge_index.append([j, i])
        edge_attr.append(bond_features('SINGLE', False, True))

    edge_index = torch.tensor(edge_index, dtype=torch.long).t().contiguous()
    edge_attr = torch.tensor(edge_attr, dtype=torch.float)

    return Data(x=x, edge_index=edge_index, edge_attr=edge_attr)

def prepare_dataset() -> List[Tuple[Data, Dict]]:
    """Prepare dataset for training"""
    dataset = []

    for polymer in POLYMER_DATASET:
        graph = create_synthetic_graph(polymer.smiles)

        # Add global features
        global_features = torch.tensor([
            polymer.temperature / 100.0,
            polymer.pH / 14.0,
            1.0 if polymer.mechanism == 'chain_end' else 0.0,
            np.log10(polymer.omega_raw) / 3.0
        ], dtype=torch.float)

        graph.global_features = global_features
        graph.y = torch.tensor([polymer.cv_observed], dtype=torch.float)
        graph.omega_raw = polymer.omega_raw
        graph.mechanism = polymer.mechanism

        dataset.append((graph, {
            'name': polymer.name,
            'cv': polymer.cv_observed,
            'omega': polymer.omega_raw,
            'mechanism': polymer.mechanism
        }))

    return dataset

# ============================================================================
# GNN MODEL
# ============================================================================

class AtomEncoder(nn.Module):
    """Encode atom features"""
    def __init__(self, in_features: int, hidden_dim: int):
        super().__init__()
        self.mlp = nn.Sequential(
            nn.Linear(in_features, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.mlp(x)

class MessagePassingLayer(nn.Module):
    """Graph attention message passing"""
    def __init__(self, hidden_dim: int, heads: int = 4):
        super().__init__()
        self.conv = GATConv(hidden_dim, hidden_dim // heads, heads=heads)
        self.norm = nn.LayerNorm(hidden_dim)

    def forward(self, x: torch.Tensor, edge_index: torch.Tensor) -> torch.Tensor:
        h = self.conv(x, edge_index)
        h = self.norm(h + x)  # Residual connection
        return F.relu(h)

class PolymerGNN(nn.Module):
    """
    GNN for predicting polymer degradation CV.

    Physics-informed: Uses entropic causality law as constraint.
    """
    def __init__(self,
                 atom_features: int = 21,
                 hidden_dim: int = 128,
                 n_layers: int = 4,
                 global_features: int = 4):
        super().__init__()

        self.atom_encoder = AtomEncoder(atom_features, hidden_dim)

        self.mp_layers = nn.ModuleList([
            MessagePassingLayer(hidden_dim) for _ in range(n_layers)
        ])

        self.global_encoder = nn.Linear(global_features, hidden_dim)

        # Predict effective Omega
        self.omega_head = nn.Sequential(
            nn.Linear(hidden_dim * 2, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, 1),
            nn.Softplus()  # Omega must be positive
        )

        # Predict CV directly
        self.cv_head = nn.Sequential(
            nn.Linear(hidden_dim * 2, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, 1),
            nn.Softplus()  # CV must be positive
        )

        # Physics parameters (learnable)
        self.log_lambda = nn.Parameter(torch.tensor(np.log(np.log(2) / 3)))
        self.log_alpha = nn.Parameter(torch.tensor(np.log(0.055)))
        self.log_omega_max = nn.Parameter(torch.tensor(np.log(2.73)))

    def forward(self, data: Data) -> Dict[str, torch.Tensor]:
        x, edge_index, batch = data.x, data.edge_index, data.batch

        # Encode atoms
        h = self.atom_encoder(x)

        # Message passing
        for mp in self.mp_layers:
            h = mp(h, edge_index)

        # Global pooling
        h_graph = global_mean_pool(h, batch)  # [batch_size, hidden_dim]

        # Encode global features
        h_global = self.global_encoder(data.global_features)
        if h_global.dim() == 1:
            h_global = h_global.unsqueeze(0)

        # Combine
        h_combined = torch.cat([h_graph, h_global], dim=-1)

        # Predict Omega_eff
        omega_raw = self.omega_head(h_combined)

        # Apply physics: Omega_eff = min(alpha * Omega_raw, Omega_max)
        alpha = torch.exp(self.log_alpha)
        omega_max = torch.exp(self.log_omega_max)
        omega_eff = torch.min(alpha * omega_raw, omega_max)
        omega_eff = torch.clamp(omega_eff, min=2.0)  # Minimum 2

        # Physics-based CV prediction: C = Omega^(-lambda)
        lmbda = torch.exp(self.log_lambda)
        causality = omega_eff ** (-lmbda)
        cv_physics = 30.0 * (1 - causality)  # Baseline 30%

        # Direct CV prediction
        cv_direct = self.cv_head(h_combined)

        # Combine physics and direct predictions
        cv_combined = 0.5 * cv_physics + 0.5 * cv_direct

        return {
            'cv': cv_combined,
            'cv_physics': cv_physics,
            'cv_direct': cv_direct,
            'omega_eff': omega_eff,
            'omega_raw': omega_raw,
            'causality': causality,
            'lambda': lmbda,
            'alpha': alpha,
            'omega_max': omega_max
        }

class PhysicsInformedLoss(nn.Module):
    """
    Loss function with physics constraint.

    L = L_mse + lambda_physics * L_physics
    """
    def __init__(self, lambda_physics: float = 0.1):
        super().__init__()
        self.lambda_physics = lambda_physics
        self.mse = nn.MSELoss()

    def forward(self, predictions: Dict[str, torch.Tensor],
                targets: torch.Tensor) -> Dict[str, torch.Tensor]:

        # MSE loss on CV
        loss_mse = self.mse(predictions['cv'].squeeze(), targets.squeeze())

        # Physics consistency loss
        # cv_physics and cv_direct should agree
        loss_physics = self.mse(predictions['cv_physics'].squeeze(),
                                 predictions['cv_direct'].squeeze())

        # Regularization on learned parameters
        # lambda should be close to ln(2)/3 = 0.231
        target_lambda = np.log(2) / 3
        loss_lambda = (predictions['lambda'] - target_lambda) ** 2

        # alpha should be in reasonable range
        loss_alpha = F.relu(predictions['alpha'] - 0.2) + F.relu(0.01 - predictions['alpha'])

        # omega_max should be in reasonable range
        loss_omega_max = F.relu(predictions['omega_max'] - 10.0) + F.relu(2.0 - predictions['omega_max'])

        # Total loss
        total_loss = (loss_mse +
                      self.lambda_physics * loss_physics +
                      0.01 * loss_lambda.mean() +
                      0.01 * loss_alpha.mean() +
                      0.01 * loss_omega_max.mean())

        return {
            'total': total_loss,
            'mse': loss_mse,
            'physics': loss_physics,
            'lambda_reg': loss_lambda.mean(),
        }

# ============================================================================
# TRAINING
# ============================================================================

def train_model(model: PolymerGNN,
                dataset: List[Tuple[Data, Dict]],
                n_epochs: int = 200,
                lr: float = 0.001) -> Dict:
    """Train the GNN model"""

    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, n_epochs)
    criterion = PhysicsInformedLoss(lambda_physics=0.1)

    # Create data loader
    graphs = [g for g, _ in dataset]
    loader = DataLoader(graphs, batch_size=4, shuffle=True)

    history = {'loss': [], 'mse': [], 'physics_params': []}

    for epoch in range(n_epochs):
        model.train()
        epoch_loss = 0
        epoch_mse = 0

        for batch in loader:
            optimizer.zero_grad()

            predictions = model(batch)
            losses = criterion(predictions, batch.y)

            losses['total'].backward()
            optimizer.step()

            epoch_loss += losses['total'].item()
            epoch_mse += losses['mse'].item()

        scheduler.step()

        avg_loss = epoch_loss / len(loader)
        avg_mse = epoch_mse / len(loader)

        history['loss'].append(avg_loss)
        history['mse'].append(avg_mse)

        # Log physics parameters
        with torch.no_grad():
            history['physics_params'].append({
                'lambda': np.exp(model.log_lambda.item()),
                'alpha': np.exp(model.log_alpha.item()),
                'omega_max': np.exp(model.log_omega_max.item())
            })

        if (epoch + 1) % 20 == 0:
            params = history['physics_params'][-1]
            print(f"Epoch {epoch+1:3d}: Loss={avg_loss:.4f}, MSE={avg_mse:.4f}, "
                  f"lambda={params['lambda']:.3f}, alpha={params['alpha']:.3f}, "
                  f"omega_max={params['omega_max']:.2f}")

    return history

def evaluate_model(model: PolymerGNN,
                   dataset: List[Tuple[Data, Dict]]) -> Dict:
    """Evaluate model on dataset"""

    model.eval()
    results = []

    with torch.no_grad():
        for graph, meta in dataset:
            # Add batch dimension
            graph.batch = torch.zeros(graph.x.size(0), dtype=torch.long)

            predictions = model(graph)

            results.append({
                'name': meta['name'],
                'cv_true': meta['cv'],
                'cv_pred': predictions['cv'].item(),
                'omega_eff': predictions['omega_eff'].item(),
                'causality': predictions['causality'].item(),
                'mechanism': meta['mechanism']
            })

    # Compute metrics
    cv_true = np.array([r['cv_true'] for r in results])
    cv_pred = np.array([r['cv_pred'] for r in results])

    mae = np.mean(np.abs(cv_true - cv_pred))
    rmse = np.sqrt(np.mean((cv_true - cv_pred) ** 2))
    correlation = np.corrcoef(cv_true, cv_pred)[0, 1]

    return {
        'results': results,
        'mae': mae,
        'rmse': rmse,
        'correlation': correlation
    }

# ============================================================================
# MAIN
# ============================================================================

def main():
    print("=" * 70)
    print("GNN MODEL FOR POLYMER REPRODUCIBILITY PREDICTION")
    print("=" * 70)
    print()

    # Prepare dataset
    print("Preparing dataset...")
    dataset = prepare_dataset()
    print(f"Dataset size: {len(dataset)} polymers")
    print()

    # Create model
    print("Creating model...")
    model = PolymerGNN(
        atom_features=21,
        hidden_dim=64,
        n_layers=3,
        global_features=4
    )

    n_params = sum(p.numel() for p in model.parameters())
    print(f"Model parameters: {n_params:,}")
    print()

    # Train
    print("Training...")
    print("-" * 70)
    history = train_model(model, dataset, n_epochs=100, lr=0.005)
    print("-" * 70)
    print()

    # Evaluate
    print("Evaluating...")
    evaluation = evaluate_model(model, dataset)

    print()
    print("=" * 70)
    print("RESULTS")
    print("=" * 70)
    print()

    print(f"{'Polymer':<20} {'CV_true':>8} {'CV_pred':>8} {'Omega_eff':>10} {'Mechanism':>12}")
    print("-" * 70)

    for r in evaluation['results']:
        print(f"{r['name']:<20} {r['cv_true']:>8.1f} {r['cv_pred']:>8.1f} "
              f"{r['omega_eff']:>10.2f} {r['mechanism']:>12}")

    print("-" * 70)
    print()
    print(f"Mean Absolute Error: {evaluation['mae']:.2f}%")
    print(f"RMSE: {evaluation['rmse']:.2f}%")
    print(f"Correlation: {evaluation['correlation']:.3f}")
    print()

    # Final physics parameters
    final_params = history['physics_params'][-1]
    print("Learned Physics Parameters:")
    print(f"  lambda = {final_params['lambda']:.4f} (theory: {np.log(2)/3:.4f})")
    print(f"  alpha = {final_params['alpha']:.4f} (literature: 0.055)")
    print(f"  omega_max = {final_params['omega_max']:.2f} (literature: 2.73)")

    return model, evaluation, history

if __name__ == "__main__":
    main()
