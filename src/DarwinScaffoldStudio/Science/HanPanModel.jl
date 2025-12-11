"""
HanPanModel.jl

Implementação do modelo Han & Pan (2009) para benchmark.

REFERÊNCIA:
Han X, Pan J. "A model for simultaneous crystallisation and biodegradation
of biodegradable polymers." Biomaterials 30(3):423-430, 2009.
DOI: 10.1016/j.biomaterials.2008.10.001

MODELO TEÓRICO:
==============
O modelo captura a interação entre:
1. Hidrólise autocatalítica das cadeias poliméricas
2. Cristalização induzida pela degradação (cadeias curtas cristalizam)
3. Proteção das regiões cristalinas contra hidrólise
4. Difusão de oligômeros

EQUAÇÕES FUNDAMENTAIS:
=====================

1. Cisão de cadeia (Chain scission):
   dCe/dt = k₁ × Ce × Cw × (1 + k₂ × Cm)

   Onde:
   - Ce = concentração de ligações éster
   - Cw = concentração de água
   - Cm = concentração de monômeros/oligômeros (autocatálise)
   - k₁ = constante de taxa de hidrólise
   - k₂ = constante de autocatálise

2. Difusão de oligômeros:
   ∂Cm/∂t = D × ∇²Cm + R_prod - R_cryst

3. Cristalização (Avrami modificado):
   dXc/dt = k_c × (Xc_max - Xc) × f(Mn)

   Onde f(Mn) aumenta quando Mn diminui (maior mobilidade)

4. Taxa efetiva considerando cristalização:
   k_eff = k₁ × (1 - Xc)^n

   Onde n = expoente de proteção (~1-2)

Author: Darwin Scaffold Studio
Date: 2025-12-11
"""
module HanPanModel

using Statistics
using Printf

export HanPanParams, HanPanState, simulate_han_pan
export validate_han_pan, compare_with_darwin
export HAN_PAN_ORIGINAL_PARAMS

# ============================================================================
# CONSTANTES DO MODELO ORIGINAL
# ============================================================================

"""
Parâmetros originais do paper Han & Pan 2009.
Calibrados para PLLA em PBS 37°C.
"""
const HAN_PAN_ORIGINAL_PARAMS = Dict(
    :k1 => 0.0058,        # Taxa de hidrólise base (/dia)
    :k2 => 4.5,           # Fator de autocatálise
    :Ea => 80.0,          # Energia de ativação (kJ/mol)
    :D => 1e-12,          # Coeficiente de difusão (m²/s)
    :k_cryst => 0.002,    # Taxa de cristalização (/dia)
    :n_protect => 1.5,    # Expoente de proteção cristalina
    :Xc_max => 0.75,      # Cristalinidade máxima
    :Mn_cryst_onset => 30.0,  # Mn abaixo do qual cristalização acelera
)

# ============================================================================
# ESTRUTURAS DE DADOS
# ============================================================================

"""
Parâmetros do modelo Han & Pan.
"""
Base.@kwdef struct HanPanParams
    # Cinética de hidrólise
    k1::Float64 = 0.0058      # Taxa base (/dia)
    k2::Float64 = 4.5         # Fator de autocatálise
    Ea::Float64 = 80.0        # Energia de ativação (kJ/mol)

    # Difusão (simplificado - modelo 0D)
    D::Float64 = 1e-12        # m²/s (não usado em 0D)
    sample_thickness::Float64 = 2.0  # mm

    # Cristalização
    k_cryst::Float64 = 0.002  # Taxa de cristalização (/dia)
    n_protect::Float64 = 1.5  # Expoente de proteção
    Xc_max::Float64 = 0.75    # Cristalinidade máxima
    Mn_cryst_onset::Float64 = 30.0  # kg/mol

    # Condições iniciais
    Mn_initial::Float64 = 100.0   # kg/mol
    Xc_initial::Float64 = 0.50    # Cristalinidade inicial
    Ce_initial::Float64 = 1.0     # Concentração de éster normalizada

    # Condições experimentais
    temperature::Float64 = 310.15  # K (37°C)
end

"""
Estado do sistema Han & Pan.
"""
mutable struct HanPanState
    t::Float64          # Tempo (dias)
    Mn::Float64         # Massa molar (kg/mol)
    Ce::Float64         # Concentração de éster (normalizada)
    Cm::Float64         # Concentração de monômeros
    Xc::Float64         # Cristalinidade
    k_eff::Float64      # Taxa efetiva
end

# ============================================================================
# FUNÇÕES DO MODELO
# ============================================================================

"""
Calcula fator de temperatura (Arrhenius).
"""
function arrhenius_factor(T::Float64, Ea::Float64, T_ref::Float64=310.15)::Float64
    R = 8.314e-3  # kJ/(mol·K)
    return exp(-Ea / R * (1/T - 1/T_ref))
end

"""
Calcula taxa de cristalização baseada em Mn.
Cadeias curtas têm maior mobilidade → cristalizam mais.
"""
function crystallization_rate(
    Mn::Float64,
    Xc::Float64,
    params::HanPanParams
)::Float64

    if Xc >= params.Xc_max
        return 0.0
    end

    # Fator de mobilidade (aumenta quando Mn diminui)
    if Mn > params.Mn_cryst_onset
        mobility_factor = 1.0
    else
        mobility_factor = (params.Mn_cryst_onset / Mn)^0.5
    end

    # Cinética de Avrami simplificada
    rate = params.k_cryst * mobility_factor * (params.Xc_max - Xc)

    return max(rate, 0.0)
end

"""
Calcula taxa efetiva de hidrólise considerando:
1. Autocatálise por oligômeros
2. Proteção por cristalinidade
"""
function effective_hydrolysis_rate(
    Ce::Float64,
    Cm::Float64,
    Xc::Float64,
    params::HanPanParams;
    T::Float64 = 310.15
)::Float64

    # Fator de temperatura
    f_T = arrhenius_factor(T, params.Ea)

    # Autocatálise
    autocatalysis = 1.0 + params.k2 * Cm

    # Proteção cristalina
    # Regiões cristalinas são impermeáveis à água
    crystalline_protection = (1.0 - Xc)^params.n_protect

    # Taxa efetiva
    k_eff = params.k1 * f_T * autocatalysis * crystalline_protection

    return k_eff
end

"""
Simula modelo Han & Pan.
Modelo 0D (homogêneo) - simplificação do modelo original que inclui difusão.
"""
function simulate_han_pan(
    params::HanPanParams;
    t_max::Float64 = 365.0,
    dt::Float64 = 0.5
)::Vector{HanPanState}

    states = HanPanState[]

    # Estado inicial
    Mn = params.Mn_initial
    Ce = params.Ce_initial
    Cm = 0.0  # Sem oligômeros inicialmente
    Xc = params.Xc_initial

    state = HanPanState(0.0, Mn, Ce, Cm, Xc, 0.0)
    push!(states, deepcopy(state))

    for t in dt:dt:t_max
        # 1. Taxa efetiva de hidrólise
        k_eff = effective_hydrolysis_rate(Ce, Cm, Xc, params; T=params.temperature)

        # 2. Cisão de cadeia
        # dCe/dt = -k_eff × Ce
        dCe = -k_eff * Ce * dt
        Ce = max(Ce + dCe, 0.01)

        # 3. Produção de oligômeros
        # Proporcional à degradação
        dCm = -dCe * 0.5  # 50% vira oligômeros solúveis
        Cm = max(Cm + dCm, 0.0)

        # 4. Perda de oligômeros por difusão (simplificado)
        # Em modelo 0D, assumimos perda gradual
        Cm = Cm * (1.0 - 0.01 * dt)  # 1%/dia de perda

        # 5. Atualização de Mn
        # Mn ∝ 1 / (número de cadeias)
        # Quando Ce diminui, mais cadeias curtas
        Mn_new = params.Mn_initial * Ce^1.2
        Mn = max(Mn_new, 0.5)

        # 6. Cristalização
        dXc = crystallization_rate(Mn, Xc, params) * dt
        Xc = min(Xc + dXc, params.Xc_max)

        # Salvar estado
        state = HanPanState(t, Mn, Ce, Cm, Xc, k_eff)
        push!(states, deepcopy(state))
    end

    return states
end

# ============================================================================
# VALIDAÇÃO E COMPARAÇÃO
# ============================================================================

"""
Valida modelo Han & Pan contra dados experimentais.
"""
function validate_han_pan(
    params::HanPanParams,
    experimental_times::Vector{Float64},
    experimental_Mn::Vector{Float64}
)::Dict{String, Any}

    # Simular
    states = simulate_han_pan(params; t_max=maximum(experimental_times) + 10)

    # Extrair Mn nos tempos experimentais
    Mn_pred = Float64[]
    for t in experimental_times
        idx = findfirst(s -> s.t >= t, states)
        if idx !== nothing
            push!(Mn_pred, states[idx].Mn)
        else
            push!(Mn_pred, states[end].Mn)
        end
    end

    # Métricas
    residuals = Mn_pred .- experimental_Mn
    RMSE = sqrt(mean(residuals.^2))
    NRMSE = RMSE / (maximum(experimental_Mn) - minimum(experimental_Mn)) * 100
    R2 = 1.0 - sum(residuals.^2) / sum((experimental_Mn .- mean(experimental_Mn)).^2)

    return Dict(
        "times" => experimental_times,
        "Mn_experimental" => experimental_Mn,
        "Mn_predicted" => Mn_pred,
        "residuals" => residuals,
        "RMSE" => RMSE,
        "NRMSE" => NRMSE,
        "R2" => R2,
        "states" => states
    )
end

"""
Compara modelo Han & Pan com modelo Darwin.
Retorna análise comparativa.
"""
function compare_with_darwin(
    experimental_times::Vector{Float64},
    experimental_Mn::Vector{Float64},
    darwin_Mn::Vector{Float64},
    han_pan_Mn::Vector{Float64}
)::Dict{String, Any}

    # Métricas Darwin
    res_darwin = darwin_Mn .- experimental_Mn
    RMSE_darwin = sqrt(mean(res_darwin.^2))
    NRMSE_darwin = RMSE_darwin / (maximum(experimental_Mn) - minimum(experimental_Mn)) * 100
    R2_darwin = 1.0 - sum(res_darwin.^2) / sum((experimental_Mn .- mean(experimental_Mn)).^2)

    # Métricas Han & Pan
    res_hp = han_pan_Mn .- experimental_Mn
    RMSE_hp = sqrt(mean(res_hp.^2))
    NRMSE_hp = RMSE_hp / (maximum(experimental_Mn) - minimum(experimental_Mn)) * 100
    R2_hp = 1.0 - sum(res_hp.^2) / sum((experimental_Mn .- mean(experimental_Mn)).^2)

    # Comparação
    darwin_wins = NRMSE_darwin < NRMSE_hp
    improvement = (NRMSE_hp - NRMSE_darwin) / NRMSE_hp * 100

    return Dict(
        "darwin" => Dict(
            "NRMSE" => NRMSE_darwin,
            "R2" => R2_darwin,
            "RMSE" => RMSE_darwin
        ),
        "han_pan" => Dict(
            "NRMSE" => NRMSE_hp,
            "R2" => R2_hp,
            "RMSE" => RMSE_hp
        ),
        "darwin_wins" => darwin_wins,
        "improvement_percent" => improvement,
        "summary" => darwin_wins ?
            "Darwin $(round(improvement, digits=1))% melhor que Han&Pan" :
            "Han&Pan $(round(-improvement, digits=1))% melhor que Darwin"
    )
end

# ============================================================================
# RELATÓRIO
# ============================================================================

"""
Imprime relatório de comparação.
"""
function print_comparison_report(comparison::Dict{String, Any})
    println("="^70)
    println("  BENCHMARK: Darwin vs Han & Pan (2009)")
    println("="^70)

    darwin = comparison["darwin"]
    hp = comparison["han_pan"]

    println("\n📊 MÉTRICAS DE PRECISÃO:")
    println("-"^50)
    println("  Modelo      │ NRMSE (%) │  R²   │ RMSE")
    println("-"^50)
    @printf("  Darwin      │   %5.1f   │ %.3f │ %.2f\n",
            darwin["NRMSE"], darwin["R2"], darwin["RMSE"])
    @printf("  Han & Pan   │   %5.1f   │ %.3f │ %.2f\n",
            hp["NRMSE"], hp["R2"], hp["RMSE"])
    println("-"^50)

    if comparison["darwin_wins"]
        @printf("\n  ✅ Darwin é %.1f%% mais preciso\n", comparison["improvement_percent"])
    else
        @printf("\n  ⚠️  Han & Pan é %.1f%% mais preciso\n", -comparison["improvement_percent"])
        println("     Investigar: o que Han & Pan captura que Darwin não captura?")
    end

    println("="^70)
end

end # module
