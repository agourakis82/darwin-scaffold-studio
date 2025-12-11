"""
PLDLAIdiosyncraticModel.jl

Modelo de Degradação Específico para PLDLA que captura suas IDIOSSINCRASIAS ÚNICAS:

1. COPOLÍMERO L/DL (70:30)
   - Segmentos L cristalizáveis vs segmentos DL amorfos
   - Distribuição não-aleatória de unidades (blocky vs random)
   - Transição vítrea intermediária entre PLLA e PDLLA

2. CRISTALIZAÇÃO TARDIA (60-90 dias)
   - PLDLA começa amorfo (Xc ≈ 8%)
   - Cristalização induzida por degradação (quimio-cristalização)
   - Aparecimento de picos Tm e Tc após 60 dias
   - Xc aumenta significativamente na fase final

3. QUEDA DRAMÁTICA DE Tg
   - Tg cai de 54°C → 36°C em 90 dias
   - Plastificação por oligômeros (autocatálise líquida)
   - Transição para estado borrachoso

4. EFEITO DO PLASTIFICANTE TEC
   - TEC reduz Tg inicial (54 → 46°C)
   - Acelera absorção de água
   - Modifica cinética de cristalização

5. PDI COMO INDICADOR DE MECANISMO
   - PDI inicial ≈ 1.84 (distribuição larga)
   - PDI aumenta a 30 dias (2.07) - cisão aleatória dominante
   - PDI diminui a 90 dias (1.49) - oligômeros uniformes

6. DEGRADAÇÃO SEM PERDA DE MASSA
   - Mn cai 87.5% em 90 dias
   - Massa permanece constante (scaffold mantém forma)
   - Erosão bulk completa, não superficial

REFERÊNCIAS ESPECÍFICAS:
- Hergesel 2025 (dados primários PUC-SP)
- Fernández et al. 2012: PLDLA 70:30 degradation
- Vert et al. 1991: Heterogeneous degradation theory
- Li 1999: Size-dependent autocatalysis

Author: Darwin Scaffold Studio
Date: 2025-12-10
"""
module PLDLAIdiosyncraticModel

using Statistics
using Printf

export PLDLAParams, PLDLAState, PLDLASimulationResult
export create_pldla_params, simulate_pldla_degradation
export calibrate_pldla_model, validate_against_kaique
export print_pldla_report, analyze_pldla_mechanisms

# ============================================================================
# CONSTANTES ESPECÍFICAS DO PLDLA
# ============================================================================

# Composição do copolímero
const L_FRACTION = 0.70    # 70% L-lactídeo
const DL_FRACTION = 0.30   # 30% DL-lactídeo

# Propriedades das unidades
const MW_LACTIDE = 144.13  # g/mol (unidade repetitiva)
const DENSITY_PLDLA = 1.25 # g/cm³

# Energia de ligação éster
const BOND_ENERGY_ESTER = 358.0  # kJ/mol (C-O)

# ============================================================================
# ESTRUTURAS DE DADOS
# ============================================================================

"""
Parâmetros específicos do PLDLA.
Captura todas as idiossincrasias do copolímero.
"""
Base.@kwdef struct PLDLAParams
    # Identificação
    name::String = "PLDLA 70:30"

    # Composição do copolímero
    L_fraction::Float64 = L_FRACTION
    DL_fraction::Float64 = DL_FRACTION

    # Blockyness (randomização das unidades)
    # 0 = completamente aleatório, 1 = completamente blocky
    blockiness::Float64 = 0.35

    # Massa molar inicial
    Mn_initial::Float64 = 51.285  # kg/mol (Kaique)
    Mw_initial::Float64 = 94.432  # kg/mol (Kaique)
    PDI_initial::Float64 = 1.84   # Mw/Mn

    # Propriedades térmicas iniciais
    Tg_initial::Float64 = 54.0    # °C (DSC Kaique)
    Tm_initial::Float64 = NaN     # Inicialmente amorfo
    Xc_initial::Float64 = 0.08    # 8% cristalinidade inicial

    # Temperatura de degradação térmica
    Tmax_thermal::Float64 = 340.0 # °C (TG Kaique)

    # Parâmetros cinéticos base (calibrados com dados Kaique)
    # PLDLA degrada MUITO mais rápido que PLLA devido aos segmentos DL amorfos
    k_L::Float64 = 0.028          # Taxa base segmentos L (/dia) - ajustado
    k_DL::Float64 = 0.065         # Taxa base segmentos DL (/dia) - muito mais rápido
    Ea_hydrolysis::Float64 = 72.0 # kJ/mol - menor que PLLA (facilita hidrólise)

    # Autocatálise específica (CRÍTICO para PLDLA - degradação bulk intensa)
    # O acúmulo de ácido láctico no interior causa autocatálise muito forte
    alpha_L::Float64 = 0.18       # Autocatálise segmentos L - aumentado
    alpha_DL::Float64 = 0.35      # Autocatálise segmentos DL - muito forte

    # Cristalização induzida
    k_crystallization::Float64 = 0.001  # Taxa de cristalização (/dia)
    Xc_max::Float64 = 0.45              # Cristalinidade máxima alcançável
    Mn_threshold_cryst::Float64 = 20.0  # Mn abaixo do qual cristalização acelera

    # Plastificação por oligômeros
    plasticizer_sensitivity::Float64 = 0.3  # Sensibilidade a oligômeros
    oligomer_Tg_depression::Float64 = 25.0  # Queda máxima de Tg por oligômeros (°C)

    # Efeito do TEC (triethyl citrate)
    TEC_concentration::Float64 = 0.0  # % (0, 1, ou 2)
    TEC_Tg_reduction::Float64 = 4.0   # °C por 1% TEC
    TEC_water_uptake_factor::Float64 = 1.3  # Acelera absorção de água

    # Morfologia do scaffold (3D printing)
    porosity::Float64 = 0.65
    surface_area::Float64 = 10.0  # mm²/mm³
    strut_thickness::Float64 = 250.0  # μm
end

"""
Estado instantâneo do PLDLA durante degradação.
"""
mutable struct PLDLAState
    # Tempo
    t::Float64

    # Massa molar
    Mn::Float64
    Mw::Float64
    PDI::Float64

    # Composição residual
    L_remaining::Float64   # Fração de L ainda intacta
    DL_remaining::Float64  # Fração de DL ainda intacta

    # Propriedades térmicas
    Tg::Float64
    Tm::Float64
    Tc::Float64
    Xc::Float64

    # Estado de degradação
    water_content::Float64        # Fração de água absorvida
    acid_concentration::Float64   # Concentração local de ácido (mol/L)
    oligomer_fraction::Float64    # Fração de oligômeros

    # Indicadores
    phase::Symbol  # :initial, :amorphous_degradation, :crystallization, :final
    mechanism::Symbol  # :random_scission, :end_scission, :mixed
end

"""
Resultado completo da simulação.
"""
struct PLDLASimulationResult
    params::PLDLAParams
    states::Vector{PLDLAState}

    # Métricas de validação
    Mn_predicted::Vector{Float64}
    Mn_experimental::Vector{Float64}
    NRMSE::Float64

    # Análise de mecanismos
    phase_transitions::Dict{Symbol, Float64}  # Tempos de transição
    dominant_mechanisms::Dict{Symbol, Float64}  # Contribuição de cada mecanismo
end

# ============================================================================
# FUNÇÕES DE MODELAGEM ESPECÍFICA
# ============================================================================

"""
Cria parâmetros padrão do PLDLA baseados nos dados do Kaique.
"""
function create_pldla_params(;
    TEC_percent::Float64 = 0.0,
    Mn_initial::Float64 = 51.285,
    kwargs...
)
    # Ajustes baseados em TEC
    Tg_adjustment = TEC_percent * 4.0  # 4°C por 1% TEC

    return PLDLAParams(;
        Mn_initial = Mn_initial,
        Mw_initial = Mn_initial * 1.84,
        TEC_concentration = TEC_percent,
        Tg_initial = 54.0 - Tg_adjustment,
        kwargs...
    )
end

"""
Inicializa estado do PLDLA no tempo t=0.
"""
function initialize_state(params::PLDLAParams)::PLDLAState
    return PLDLAState(
        0.0,
        params.Mn_initial,
        params.Mw_initial,
        params.PDI_initial,
        params.L_fraction,
        params.DL_fraction,
        params.Tg_initial,
        params.Tm_initial,
        NaN,
        params.Xc_initial,
        0.0,
        0.0,
        0.0,
        :initial,
        :random_scission
    )
end

"""
Calcula taxa de absorção de água específica para PLDLA.
Considera: cristalinidade, TEC, e porosidade.
"""
function calculate_water_uptake(
    state::PLDLAState,
    params::PLDLAParams,
    dt::Float64
)::Float64
    # Taxa base de absorção
    k_water = 0.02  # /dia

    # Efeito da cristalinidade (barreira)
    Xc_factor = (1.0 - state.Xc)^1.5

    # Efeito do TEC (hidrofílico)
    TEC_factor = 1.0 + params.TEC_concentration * (params.TEC_water_uptake_factor - 1.0)

    # Efeito da porosidade (maior área superficial)
    porosity_factor = 1.0 + (params.porosity - 0.5)

    # Saturação sigmoidal
    saturation = 0.95  # 95% saturação máxima
    k_effective = k_water * Xc_factor * TEC_factor * porosity_factor

    # Cinética de 1ª ordem com saturação
    new_water = state.water_content + k_effective * (saturation - state.water_content) * dt

    return clamp(new_water, 0.0, saturation)
end

"""
Calcula taxas de degradação diferenciadas para segmentos L e DL.
IDIOSSINCRASIA: Segmentos DL degradam mais rápido que segmentos L.
"""
function calculate_degradation_rates(
    state::PLDLAState,
    params::PLDLAParams;
    T::Float64 = 310.15
)::Tuple{Float64, Float64}
    R = 8.314e-3  # kJ/(mol·K)
    T_ref = 310.15

    # Fator de temperatura (Arrhenius)
    f_T = exp(-params.Ea_hydrolysis / R * (1/T - 1/T_ref))

    # Fator de água
    f_water = state.water_content

    # Fator de autocatálise (ácido local)
    # IDIOSSINCRASIA: Autocatálise é maior para DL
    f_acid_L = 1.0 + params.alpha_L * state.acid_concentration
    f_acid_DL = 1.0 + params.alpha_DL * state.acid_concentration

    # Fator de cristalinidade
    # IDIOSSINCRASIA: Segmentos L em regiões cristalinas são protegidos
    L_protection = state.Xc * 0.7  # 70% de proteção em regiões cristalinas
    f_Xc_L = 1.0 - L_protection
    f_Xc_DL = 1.0  # DL sempre amorfo, sem proteção

    # Fator de blockiness
    # Copolímeros blocky: degradação heterogênea
    # Copolímeros random: degradação mais uniforme
    f_block = 1.0 + 0.3 * params.blockiness

    # Taxas finais
    k_L = params.k_L * f_T * f_water * f_acid_L * f_Xc_L
    k_DL = params.k_DL * f_T * f_water * f_acid_DL * f_block

    return (k_L, k_DL)
end

"""
Modelo de cristalização induzida por degradação (quimio-cristalização).
IDIOSSINCRASIA: PLDLA cristaliza apenas quando Mn cai significativamente.
"""
function calculate_crystallization(
    state::PLDLAState,
    params::PLDLAParams,
    dt::Float64
)::Tuple{Float64, Float64, Float64}

    # Cristalização só começa quando Mn cai abaixo do threshold
    if state.Mn > params.Mn_threshold_cryst
        return (state.Xc, NaN, NaN)
    end

    # Mobilidade aumentada por cadeias curtas
    mobility_factor = (params.Mn_threshold_cryst / state.Mn)^0.5

    # Fator de oligômeros (plastificação)
    oligomer_factor = 1.0 + 2.0 * state.oligomer_fraction

    # Taxa de cristalização
    k_cryst = params.k_crystallization * mobility_factor * oligomer_factor

    # Cristalinidade máxima limitada pela composição L
    Xc_max_effective = params.Xc_max * params.L_fraction / L_FRACTION

    # Cinética de Avrami simplificada (n=1)
    Xc_new = state.Xc + k_cryst * (Xc_max_effective - state.Xc) * dt

    # Quando Xc > 15%, picos Tm e Tc aparecem
    if Xc_new > 0.15
        # Tm depende de Mn (oligômeros menores = Tm menor)
        Tm_base = 170.0  # PLLA puro
        Tm_depression = 70.0 * (1.0 - state.Mn / params.Mn_initial)
        Tm = Tm_base - Tm_depression

        # Tc aparece ~8-10°C acima de Tm no resfriamento
        Tc = Tm + 8.0
    else
        Tm = NaN
        Tc = NaN
    end

    return (Xc_new, Tm, Tc)
end

"""
Modelo de queda de Tg por plastificação com oligômeros.
IDIOSSINCRASIA: Tg cai dramaticamente de 54°C → 36°C.
"""
function calculate_Tg_depression(
    state::PLDLAState,
    params::PLDLAParams
)::Float64
    # Efeito do TEC (inicial)
    Tg_TEC = params.TEC_concentration * params.TEC_Tg_reduction

    # Efeito dos oligômeros (dinâmico)
    # Fox equation modificada para oligômeros como plastificante
    w_oligomer = state.oligomer_fraction
    Tg_oligomer = 20.0  # Tg dos oligômeros (muito baixa)
    Tg_polymer = params.Tg_initial - Tg_TEC

    # Plastificação por oligômeros
    if w_oligomer > 0.01
        # Modelo de Fox: 1/Tg = w1/Tg1 + w2/Tg2
        # Convertendo para Kelvin
        Tg_polymer_K = Tg_polymer + 273.15
        Tg_oligomer_K = Tg_oligomer + 273.15

        Tg_mix_K = 1.0 / ((1-w_oligomer)/Tg_polymer_K + w_oligomer/Tg_oligomer_K)
        Tg_new = Tg_mix_K - 273.15
    else
        Tg_new = Tg_polymer
    end

    # Queda adicional por degradação da cadeia principal
    # Mn baixo = mais pontas de cadeia = maior mobilidade
    Mn_factor = (state.Mn / params.Mn_initial)^0.3
    Tg_chain_length = params.oligomer_Tg_depression * (1.0 - Mn_factor)

    Tg_final = Tg_new - Tg_chain_length

    return max(Tg_final, 25.0)  # Mínimo físico razoável
end

"""
Modelo de evolução do PDI.
IDIOSSINCRASIA: PDI sobe (cisão aleatória) e depois cai (oligômeros uniformes).
"""
function calculate_PDI_evolution(
    state::PLDLAState,
    params::PLDLAParams,
    k_L::Float64,
    k_DL::Float64
)::Float64

    # Extensão da degradação
    degradation_extent = 1.0 - state.Mn / params.Mn_initial

    if degradation_extent < 0.3
        # Fase inicial: Cisão aleatória → PDI aumenta
        # Máximo em ~30% degradação
        PDI = params.PDI_initial + 0.3 * (degradation_extent / 0.3)
    elseif degradation_extent < 0.6
        # Fase intermediária: Estabilização
        PDI = params.PDI_initial + 0.3 - 0.2 * ((degradation_extent - 0.3) / 0.3)
    else
        # Fase final: Oligômeros uniformes → PDI diminui
        PDI = params.PDI_initial + 0.1 - 0.5 * ((degradation_extent - 0.6) / 0.4)
    end

    return max(PDI, 1.0)  # PDI mínimo = 1
end

"""
Determina a fase e mecanismo dominante da degradação.
"""
function determine_phase_and_mechanism(
    state::PLDLAState,
    params::PLDLAParams
)::Tuple{Symbol, Symbol}

    degradation_extent = 1.0 - state.Mn / params.Mn_initial

    # Fase
    if degradation_extent < 0.1
        phase = :initial
    elseif state.Xc < 0.15
        phase = :amorphous_degradation
    elseif degradation_extent > 0.8
        phase = :final
    else
        phase = :crystallization
    end

    # Mecanismo
    if state.PDI > params.PDI_initial
        mechanism = :random_scission
    elseif state.PDI < params.PDI_initial - 0.2
        mechanism = :end_scission
    else
        mechanism = :mixed
    end

    return (phase, mechanism)
end

# ============================================================================
# SIMULAÇÃO PRINCIPAL
# ============================================================================

"""
Simula degradação do PLDLA com modelo idiossincrático completo.
"""
function simulate_pldla_degradation(
    params::PLDLAParams;
    t_max::Float64 = 90.0,
    dt::Float64 = 0.5,
    T::Float64 = 310.15
)::Vector{PLDLAState}

    states = PLDLAState[]
    state = initialize_state(params)
    push!(states, deepcopy(state))

    for t in dt:dt:t_max
        state.t = t

        # 1. Absorção de água
        state.water_content = calculate_water_uptake(state, params, dt)

        # 2. Taxas de degradação diferenciadas
        k_L, k_DL = calculate_degradation_rates(state, params; T=T)

        # 3. Degradação das frações L e DL
        dL = -k_L * state.L_remaining * dt
        dDL = -k_DL * state.DL_remaining * dt

        state.L_remaining = max(0.0, state.L_remaining + dL)
        state.DL_remaining = max(0.0, state.DL_remaining + dDL)

        # 4. Atualização de Mn
        # Composição ponderada
        total_remaining = state.L_remaining + state.DL_remaining
        if total_remaining > 0.01
            # Taxa média ponderada
            k_avg = (k_L * state.L_remaining + k_DL * state.DL_remaining) / total_remaining
            degradation_extent = 1.0 - state.Mn / params.Mn_initial
            autocatalysis = 1.0 + 0.06 * degradation_extent  # α médio

            dMn = -k_avg * state.Mn * autocatalysis * dt
            state.Mn = max(0.5, state.Mn + dMn)
        end

        # 5. Atualização de Mw e PDI
        state.PDI = calculate_PDI_evolution(state, params, k_L, k_DL)
        state.Mw = state.Mn * state.PDI

        # 6. Produção de ácido e oligômeros
        state.acid_concentration = 5.0 * (1.0 - state.Mn / params.Mn_initial)
        state.oligomer_fraction = 0.3 * (1.0 - state.Mn / params.Mn_initial)^1.5

        # 7. Cristalização induzida
        state.Xc, state.Tm, state.Tc = calculate_crystallization(state, params, dt)

        # 8. Queda de Tg
        state.Tg = calculate_Tg_depression(state, params)

        # 9. Fase e mecanismo
        state.phase, state.mechanism = determine_phase_and_mechanism(state, params)

        push!(states, deepcopy(state))
    end

    return states
end

# ============================================================================
# VALIDAÇÃO CONTRA DADOS DO KAIQUE
# ============================================================================

"""
Dados experimentais do Kaique Hergesel (PUC-SP 2025).
"""
const KAIQUE_DATA = Dict(
    :PLDLA => Dict(
        :time => [0.0, 30.0, 60.0, 90.0],
        :Mn => [51.285, 25.447, 18.313, 7.904],
        :Mw => [94.432, 52.738, 35.861, 11.801],
        :PDI => [1.84, 2.07, 1.95, 1.49],
        :Tg => [54.0, 54.0, 48.0, 36.0],
        :Tm => [NaN, NaN, NaN, 113.0],
        :Tc => [NaN, NaN, NaN, 121.0]
    ),
    :PLDLA_TEC1 => Dict(
        :time => [0.0, 30.0, 60.0, 90.0],
        :Mn => [44.998, 19.257, 11.749, 8.122],
        :Mw => [85.759, 31.598, 22.409, 12.114],
        :PDI => [1.90, 1.64, 1.90, 1.49],
        :Tg => [49.0, 49.0, 38.0, 41.0]
    ),
    :PLDLA_TEC2 => Dict(
        :time => [0.0, 30.0, 60.0, 90.0],
        :Mn => [32.733, 15.040, 12.616, 6.636],
        :Mw => [68.364, 26.926, 19.417, 8.391],
        :PDI => [2.08, 1.79, 1.53, 1.26],
        :Tg => [46.0, 44.0, 22.0, 35.0]
    )
)

"""
Valida modelo contra dados experimentais do Kaique.
"""
function validate_against_kaique(
    params::PLDLAParams;
    material::Symbol = :PLDLA
)::Dict{String, Any}

    data = KAIQUE_DATA[material]
    times = data[:time]
    Mn_exp = data[:Mn]

    # Simular
    states = simulate_pldla_degradation(params; t_max=maximum(times))

    # Extrair Mn nos tempos experimentais
    Mn_pred = Float64[]
    for t in times
        idx = findfirst(s -> s.t >= t, states)
        if idx !== nothing
            push!(Mn_pred, states[idx].Mn)
        else
            push!(Mn_pred, states[end].Mn)
        end
    end

    # Calcular métricas
    residuals = Mn_pred .- Mn_exp
    RMSE = sqrt(mean(residuals.^2))
    NRMSE = RMSE / (maximum(Mn_exp) - minimum(Mn_exp)) * 100
    R2 = 1.0 - sum(residuals.^2) / sum((Mn_exp .- mean(Mn_exp)).^2)

    # Erro por ponto
    errors = abs.(residuals) ./ Mn_exp .* 100

    return Dict(
        "times" => times,
        "Mn_experimental" => Mn_exp,
        "Mn_predicted" => Mn_pred,
        "residuals" => residuals,
        "errors_percent" => errors,
        "RMSE" => RMSE,
        "NRMSE" => NRMSE,
        "R2" => R2,
        "states" => states
    )
end

"""
Calibra parâmetros do modelo usando dados do Kaique.
"""
function calibrate_pldla_model(;
    material::Symbol = :PLDLA,
    n_iterations::Int = 100
)::PLDLAParams

    data = KAIQUE_DATA[material]
    Mn_exp = data[:Mn]
    times = data[:time]

    # Parâmetros iniciais
    best_params = create_pldla_params(
        Mn_initial = Mn_exp[1],
        TEC_percent = material == :PLDLA_TEC1 ? 1.0 : (material == :PLDLA_TEC2 ? 2.0 : 0.0)
    )
    best_error = Inf

    # Grid search para parâmetros críticos
    # NOTA: PLDLA degrada MUITO rápido - faixas ajustadas para capturar isso
    k_L_range = range(0.025, 0.050, length=10)      # Taxa L mais alta
    k_DL_range = range(0.050, 0.100, length=10)     # Taxa DL muito mais alta
    alpha_range = range(0.15, 0.45, length=6)       # Autocatálise forte

    for k_L in k_L_range
        for k_DL in k_DL_range
            for alpha in alpha_range
                params = PLDLAParams(
                    Mn_initial = Mn_exp[1],
                    Mw_initial = Mn_exp[1] * data[:PDI][1],
                    PDI_initial = data[:PDI][1],
                    Tg_initial = data[:Tg][1],
                    TEC_concentration = material == :PLDLA_TEC1 ? 1.0 : (material == :PLDLA_TEC2 ? 2.0 : 0.0),
                    k_L = k_L,
                    k_DL = k_DL,
                    alpha_L = alpha * 0.5,  # L tem menos autocatálise
                    alpha_DL = alpha        # DL tem autocatálise máxima
                )

                result = validate_against_kaique(params; material=material)

                if result["NRMSE"] < best_error
                    best_error = result["NRMSE"]
                    best_params = params
                end
            end
        end
    end

    return best_params
end

# ============================================================================
# ANÁLISE DE MECANISMOS
# ============================================================================

"""
Analisa mecanismos de degradação e transições de fase.
"""
function analyze_pldla_mechanisms(states::Vector{PLDLAState})::Dict{String, Any}

    # Detectar transições de fase
    phase_transitions = Dict{Symbol, Float64}()
    current_phase = states[1].phase

    for state in states
        if state.phase != current_phase
            phase_transitions[state.phase] = state.t
            current_phase = state.phase
        end
    end

    # Contribuição de cada mecanismo
    random_count = count(s -> s.mechanism == :random_scission, states)
    end_count = count(s -> s.mechanism == :end_scission, states)
    mixed_count = count(s -> s.mechanism == :mixed, states)
    total = length(states)

    mechanisms = Dict(
        :random_scission => random_count / total,
        :end_scission => end_count / total,
        :mixed => mixed_count / total
    )

    # Evolução de L vs DL
    L_degradation = [1.0 - s.L_remaining / states[1].L_remaining for s in states]
    DL_degradation = [1.0 - s.DL_remaining / states[1].DL_remaining for s in states]

    # Razão de degradação DL/L (quanto mais rápido DL degrada)
    DL_L_ratio = mean(DL_degradation ./ (L_degradation .+ 0.01))

    # Cristalização
    Xc_evolution = [s.Xc for s in states]
    crystallization_onset = findfirst(s -> s.Xc > 0.15, states)
    crystallization_time = crystallization_onset !== nothing ? states[crystallization_onset].t : NaN

    return Dict(
        "phase_transitions" => phase_transitions,
        "mechanisms" => mechanisms,
        "L_degradation" => L_degradation,
        "DL_degradation" => DL_degradation,
        "DL_L_ratio" => DL_L_ratio,
        "Xc_evolution" => Xc_evolution,
        "crystallization_onset_time" => crystallization_time,
        "final_Xc" => Xc_evolution[end],
        "Tg_drop" => states[1].Tg - states[end].Tg,
        "PDI_max" => maximum(s.PDI for s in states),
        "PDI_final" => states[end].PDI
    )
end

# ============================================================================
# RELATÓRIO
# ============================================================================

"""
Imprime relatório detalhado do modelo PLDLA idiossincrático.
"""
function print_pldla_report(
    params::PLDLAParams,
    validation::Dict{String, Any},
    analysis::Dict{String, Any}
)
    println("="^90)
    println("  MODELO IDIOSSINCRÁTICO DE DEGRADAÇÃO DO PLDLA")
    println("  Capturando características únicas do copolímero 70:30 L/DL")
    println("="^90)

    println("\n📋 PARÂMETROS DO MATERIAL:")
    println("-"^70)
    @printf("  Copolímero: %.0f%% L / %.0f%% DL\n", params.L_fraction*100, params.DL_fraction*100)
    @printf("  Blockiness: %.2f\n", params.blockiness)
    @printf("  Mn inicial: %.2f kg/mol\n", params.Mn_initial)
    @printf("  PDI inicial: %.2f\n", params.PDI_initial)
    @printf("  Tg inicial: %.1f°C\n", params.Tg_initial)
    @printf("  Xc inicial: %.1f%%\n", params.Xc_initial * 100)
    if params.TEC_concentration > 0
        @printf("  TEC: %.0f%%\n", params.TEC_concentration)
    end

    println("\n🔬 IDIOSSINCRASIAS MODELADAS:")
    println("-"^70)
    println("  1. Degradação diferenciada L vs DL")
    @printf("     k_L = %.4f /dia, k_DL = %.4f /dia\n", params.k_L, params.k_DL)
    @printf("     Razão k_DL/k_L = %.2f (DL degrada %.0f%% mais rápido)\n",
            params.k_DL/params.k_L, (params.k_DL/params.k_L - 1)*100)

    println("  2. Cristalização tardia (quimio-cristalização)")
    @printf("     Threshold Mn < %.0f kg/mol\n", params.Mn_threshold_cryst)
    @printf("     Xc máx = %.0f%%\n", params.Xc_max * 100)

    println("  3. Plastificação por oligômeros")
    @printf("     Queda máxima de Tg: %.0f°C\n", params.oligomer_Tg_depression)

    println("\n📊 VALIDAÇÃO CONTRA DADOS EXPERIMENTAIS (Kaique 2025):")
    println("-"^70)
    println("  Dia │ Mn Exp (kg/mol) │ Mn Pred (kg/mol) │ Erro (%)")
    println("-"^70)

    for i in eachindex(validation["times"])
        @printf("  %3.0f │     %6.2f      │      %6.2f      │  %5.1f%%\n",
                validation["times"][i],
                validation["Mn_experimental"][i],
                validation["Mn_predicted"][i],
                validation["errors_percent"][i])
    end

    println("-"^70)
    @printf("  NRMSE: %.1f%%\n", validation["NRMSE"])
    @printf("  R²: %.3f\n", validation["R2"])

    println("\n🔄 ANÁLISE DE MECANISMOS:")
    println("-"^70)
    @printf("  Razão degradação DL/L: %.2f\n", analysis["DL_L_ratio"])
    @printf("  Cristalização inicia: %.0f dias\n", analysis["crystallization_onset_time"])
    @printf("  Xc final: %.1f%%\n", analysis["final_Xc"] * 100)
    @printf("  Queda de Tg: %.1f°C\n", analysis["Tg_drop"])
    @printf("  PDI máximo: %.2f (t ≈ 30 dias)\n", analysis["PDI_max"])
    @printf("  PDI final: %.2f\n", analysis["PDI_final"])

    println("\n📈 TRANSIÇÕES DE FASE:")
    for (phase, time) in analysis["phase_transitions"]
        @printf("  → %s: dia %.0f\n", phase, time)
    end

    println("\n🎯 MECANISMOS DOMINANTES:")
    for (mech, frac) in analysis["mechanisms"]
        @printf("  %s: %.0f%% do tempo\n", mech, frac * 100)
    end

    if validation["NRMSE"] < 10.0
        println("\n✅ MODELO EXCELENTE (NRMSE < 10%)")
    elseif validation["NRMSE"] < 15.0
        println("\n✅ MODELO BOM (NRMSE < 15%)")
    else
        println("\n⚠️  MODELO PRECISA REFINAMENTO")
    end

    println("="^90)
end

end # module
