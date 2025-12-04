# Optimize Scaffold

Optimize scaffold design for a specific material and use case.

## Arguments
$ARGUMENTS should be in format: `material use_case` (e.g., "PCL Bone" or "Hydrogel Cartilage")

## Instructions

1. Parse the material and use case from arguments
2. Get current scaffold metrics (or use defaults)
3. Run optimization using thesis-level optimization loop
4. Present optimal parameters with scientific justification

### Supported Materials
- PCL (E = 400 MPa)
- PLA (E = 3500 MPa)
- Hydrogel (E = 0.1 MPa)
- Collagen

### Supported Use Cases
- Bone: min_modulus=100 MPa, pore_size=100-200um, flat surfaces
- Cartilage: min_modulus=5 MPa, pore_size=200-400um, curved surfaces
- Skin: high porosity, thin structures
- Neural: aligned channels, low stiffness

### Output Format
Provide:
1. Recommended porosity (%)
2. Recommended pore size (um)
3. Predicted mechanical properties (E, strength)
4. Predicted cell viability score
5. Fabrication method recommendation
6. Literature references supporting the design
