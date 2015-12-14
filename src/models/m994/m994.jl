"""
TODO: Decide whether this is the right place for this documentation...

Model994{T} <: AbstractDSGEModel{T}

The Model994 type defines the structure of the FRBNY DSGE
model. We can then concisely pass around a Model object to the
remaining steps of the model (solve, estimate, and forecast).

### Fields

#### Parameters and Steady-States
* `parameters::Vector{AbstractParameter}`: Vector of all time-invariant model parameters.

* `steady_state::Vector`: Model steady-state values, computed as a
function of elements of `parameters`.

* `keys::Dict{Symbol,Int}`: Maps human-readable names for all model
parameters and steady-states to their indices in `parameters` and
`steady_state`.

#### Inputs to Measurement and Equilibrium Condition Equations

The following fields are dictionaries that map human-readible names to
row and column indices in the matrix representations of of the
measurement equation and equilibrium conditions.

* `endogenous_states::Dict{Symbol,Int}`: Maps each state to a column
in the measurement and equilibrium condition matrices.

* `exogenous_shocks::Dict{Symbol,Int}`: Maps each shock to a column in
the measurement and equilibrium condition matrices.

* `expected_shocks::Dict{Symbol,Int}`: Maps each expected shock to a
column in the measurement and equilibrium condition matrices.

* `equilibrium_conditions::Dict{Symbol,Int}`: Maps each equlibrium
condition to a row in the model's equilibrium condition matrices.

* `endogenous_states_postgensys::Dict{Symbol,Int}`: Maps lagged states
to their columns in the measurement and equilibrium condition
equations. These are added after Gensys solves the model.

* `observables::Dict{Symbol,Int}`: Maps each observable to a row in
the model's measurement equation matrices.

#### Model Specifications and Settings

* `spec::AbstractString`: The model specification identifier, "m994",
cached here for filepath computation.

* `subspec::AbstractString`: The model subspecification number,
indicating that some parameters from the original model spec ("ss0")
are initialized differently. Cached here for filepath computation. 



* `settings::Dict{Symbol,Setting}`: Settings/flags that affect
computation without changing the economic or mathematical setup of
the model.

* `test_settings::Dict{Symbol,Setting}`: Settings/flags for testing mode

#### Other Fields

* `rng::MersenneTwister`: Random number generator. By default, it is
seeded to ensure replicability in algorithms that involve randomness
(such as Metropolis-Hastings).

* `testing::Bool`: Indicates whether the model is in testing mode. If
`true`, settings from `m.test_settings` are used in place of those in
`m.settings`.

* `_filestrings::SortedDict{Symbol,AbstractString,ForwardOrdering}`:
An alphabetized list of setting identifier strings. These are
concatenated and appended to the filenames of all output files to
avoid overwriting the output of previous estimations/forecasts that
differ only in their settings, but not in their underlying
mathematical structure. 
"""
type Model994{T} <: AbstractDSGEModel{T}
    parameters::ParameterVector{T}                  # vector of all time-invariant model parameters
    steady_state::ParameterVector{T}                # model steady-state values
    keys::Dict{Symbol,Int}                          # human-readable names for all the model
                                                    # parameters and steady-num_states

    endogenous_states::Dict{Symbol,Int}             # these fields used to create matrices in the
    exogenous_shocks::Dict{Symbol,Int}              # measurement and equilibrium condition equations.
    expected_shocks::Dict{Symbol,Int}               #
    equilibrium_conditions::Dict{Symbol,Int}        #
    endogenous_states_postgensys::Dict{Symbol,Int}  #
    observables::Dict{Symbol,Int}                   #

    spec::ASCIIString                               # Model specification number (eg "m994")
    subspec::ASCIIString                            # Model subspecification (eg "ss0")
    settings::Dict{Symbol,Setting}                  # Settings/flags for computation
    test_settings::Dict{Symbol,Setting}             # Settings/flags for testing mode
    rng::MersenneTwister                            # Random number generator
    testing::Bool                                   # Whether we are in testing mode or not
    _filestrings::SortedDict{Symbol,AbstractString, ForwardOrdering} # The strings we will print to a filename
end

description(m::Model994) = "FRBNY DSGE Model m994, $(m.subspec)"

#=
doc"""
Inputs: `m:: Model994`

Description:
Initializes indices for all of `m`'s states, shocks, and equilibrium conditions.
"""
=#
function initialize_model_indices!(m::Model994)
    # Endogenous states
    endogenous_states = [[
        :y_t, :c_t, :i_t, :qk_t, :k_t, :kbar_t, :u_t, :rk_t, :Rktil_t, :n_t, :mc_t,
        :π_t, :μ_ω_t, :w_t, :L_t, :R_t, :g_t, :b_t, :μ_t, :z_t, :λ_f_t, :λ_f_t1,
        :λ_w_t, :λ_w_t1, :rm_t, :σ_ω_t, :μe_t, :γ_t, :π_star_t, :Ec_t, :Eqk_t, :Ei_t,
        :Eπ_t, :EL_t, :Erk_t, :Ew_t, :ERktil_t, :y_f_t, :c_f_t, :i_f_t, :qk_f_t, :k_f_t,
        :kbar_f_t, :u_f_t, :rk_f_t, :w_f_t, :L_f_t, :r_f_t, :Ec_f_t, :Eqk_f_t, :Ei_f_t,
        :EL_f_t, :Erk_f_t, :ztil_t, :π_t1, :π_t2, :π_a_t, :R_t1, :zp_t, :Ez_t];
        [symbol("rm_tl$i") for i = 1:num_anticipated_shocks(m)]]

    # Exogenous shocks
    exogenous_shocks = [[
        :g_sh, :b_sh, :μ_sh, :z_sh, :λ_f_sh, :λ_w_sh, :rm_sh, :σ_ω_sh, :μe_sh,
        :γ_sh, :π_star_sh, :lr_sh, :zp_sh, :tfp_sh, :gdpdef_sh, :pce_sh, :gdp_sh, :gdy_sh];
        [symbol("rm_shl$i") for i = 1:num_anticipated_shocks(m)]]

    # Expectations shocks
    expected_shocks = [
        :Ec_sh, :Eqk_sh, :Ei_sh, :Eπ_sh, :EL_sh, :Erk_sh, :Ew_sh, :ERktil_sh, :Ec_f_sh,
        :Eqk_f_sh, :Ei_f_sh, :EL_f_sh, :Erk_f_sh]

    # Equilibrium conditions
    equilibrium_conditions = [[
        :euler, :inv, :capval, :spread, :nevol, :output, :caputl, :capsrv, :capev,
        :mkupp, :phlps, :caprnt, :msub, :wage, :mp, :res, :eq_g, :eq_b, :eq_μ, :eq_z,
        :eq_λ_f, :eq_λ_w, :eq_rm, :eq_σ_ω, :eq_μe, :eq_γ, :eq_λ_f1, :eq_λ_w1, :eq_Ec,
        :eq_Eqk, :eq_Ei, :eq_Eπ, :eq_EL, :eq_Erk, :eq_Ew, :eq_ERktil, :euler_f, :inv_f,
        :capval_f, :output_f, :caputl_f, :capsrv_f, :capev_f, :mkupp_f, :caprnt_f, :msub_f,
        :res_f, :eq_Ec_f, :eq_Eqk_f, :eq_Ei_f, :eq_EL_f, :eq_Erk_f, :eq_ztil, :eq_π_star,
        :π1, :π2, :π_a, :Rt1, :eq_zp, :eq_Ez];
        [symbol("eq_rml$i") for i=1:num_anticipated_shocks(m)]]

    # Additional states added after solving model
    # Lagged states and observables measurement error
    endogenous_states_postgensys = [
        :y_t1, :c_t1, :i_t1, :w_t1, :π_t1, :L_t1, :Et_π_t, :lr_t, :tfp_t, :e_gdpdef,
        :e_pce, :u_t1, :e_gdp_t, :e_gdy_t, :e_gdp_t1, :e_gdy_t1]

    # Measurement equation observables
    observables = [[
        :g_y,         # quarterly output growth
        :g_hours,      # aggregate hours growth
        :g_w,         # real wage growth
        :π_gdpdef,   # inflation (GDP deflator)
        :π_pce,      # inflation (core PCE)
        :R_n,         # nominal interest rate
        :g_c,         # consumption growth
        :g_i,         # investment growth
        :sprd,        # spreads
        :π_long,     # 10-year inflation expectation
        :R_long,      # long-term rate
        :tfp,        # total factor productivity
        :g_income];  # quarterly income growth
        [symbol("R_n$i") for i=1:num_anticipated_shocks(m)]] # compounded nominal rates

    for (i,k) in enumerate(endogenous_states);            m.endogenous_states[k]            = i end
    for (i,k) in enumerate(exogenous_shocks);             m.exogenous_shocks[k]             = i end
    for (i,k) in enumerate(expected_shocks);              m.expected_shocks[k]              = i end
    for (i,k) in enumerate(equilibrium_conditions);       m.equilibrium_conditions[k]       = i end
    for (i,k) in enumerate(endogenous_states);            m.endogenous_states[k]            = i end
    for (i,k) in enumerate(endogenous_states_postgensys); m.endogenous_states_postgensys[k] = i+length(endogenous_states) end
    for (i,k) in enumerate(observables);                  m.observables[k]                  = i end
end


function Model994(subspec::AbstractString="ss8")

    # Model-specific specifications
    spec               = split(basename(@__FILE__),'.')[1]   
    subspec            = subspec
    settings           = Dict{Symbol,Setting}()
    test_settings      = Dict{Symbol,Setting}()
    rng                = MersenneTwister()        # Random Number Generator
    testing            = false                       
    _filestrings       = SortedDict{Symbol,AbstractString, ForwardOrdering}()
    
    # initialize empty model
    m = Model994{Float64}(
            # model parameters and steady state values
            @compat(Vector{AbstractParameter{Float64}}()), @compat(Vector{Float64}()), Dict{Symbol,Int}(),

            # model indices
            Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(),
                          
            spec,
            subspec,
            settings,
            test_settings,
            rng,
            testing,
            _filestrings)

    # Set settings
    default_settings(m)
    default_test_settings(m)
    
    # Initialize parameters
    m <= parameter(:α,      0.1596, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     Normal(0.30, 0.05),         fixed=false,
                   description="α: Capital elasticity in the intermediate goods sector's Cobb-Douglas production function.",
                   texLabel="\\alpha")

    m <= parameter(:ζ_p,   0.8940, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.1),          fixed=false,
                   description="ζ_p: The Calvo parameter. In every period, (1-ζ_p) of the intermediate goods producers optimize prices. ζ_p of them adjust prices according to steady-state inflation, π_star.",
                   texLabel="\\zeta_p")

    m <= parameter(:ι_p,   0.1865, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.15),         fixed=false,
                   description="ι_p: The persistence of last period's inflation in the equation that describes the intertemporal change in prices for intermediate goods producers who cannot adjust prices. The change in prices is a geometric average of steady-state inflation (π_star, with weight (1-ι_p)) and last period's inflation (π_{t-1})).",
                   texLabel="\\iota_p")

    m <= parameter(:δ,      0.025,  fixed=true,
                   description="δ: The capital depreciation rate.", texLabel="\\delta" )     

    ## TODO
    m <= parameter(:Upsilon,  1.000,  (0., 10.),     (1e-5, 0.),      DSGE.Exponential(),    GammaAlt(1., 0.5),          fixed=true,
                   description="Υ: This is the something something.",
                   texLabel="\\mathcal{\\Upsilon}") 

    ## TODO - ask Marc and Marco
    m <= parameter(:Φ,   1.1066, (1., 10.),     (1.00, 10.00),   DSGE.Exponential(),    Normal(1.25, 0.12),         fixed=false,
                   description="Φ: This is the something something.",
                   texLabel="\\Phi")

    m <= parameter(:S′′,       2.7314, (-15., 15.),   (-15., 15.),     Untransformed(),  Normal(4., 1.5),            fixed=false,
                   description="S'': The second derivative of households' cost of adjusting investment.", texLabel="S\\prime\\prime")

    m <= parameter(:h,        0.5347, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.7, 0.1),          fixed=false,
                   description="h: Consumption habit persistence.", texLabel="h")

    ## TODO - ask Marc and Marco
    m <= parameter(:ppsi,     0.6862, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.15),         fixed=false,
                   description="ppsi: This is the something something.", texLabel="ppsi")

    ## TODO - ask Marc and Marco
    m <= parameter(:ν_l,     2.5975, (1e-5, 10.),   (1e-5, 10.),     DSGE.Exponential(),    Normal(2, 0.75),            fixed=false,
                   description="ν_l: The coefficient of relative risk aversion on the labor term of households' utility function.", texLabel="\nu_l")
    
    m <= parameter(:ζ_w,   0.9291, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.1),          fixed=false,
                   description="ζ_w: (1-ζ_w) is the probability with which households can freely choose wages in each period. With probability ζ_w, wages increase at a geometrically weighted average of the steady state rate of wage increases and last period's productivity times last period's inflation.",
                   texLabel="\\zeta_w")

    #TODO: Something to do with intertemporal changes in wages? – Check in tex file
    m <= parameter(:ι_w,   0.2992, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.15),         fixed=false,
                   description="ι_w: This is the something something.",
                   texLabel="\\iota_w")

    m <= parameter(:λ_w,      1.5000,                                                                               fixed=true,
                   description="λ_w: The wage markup, which affects the elasticity of substitution between differentiated labor services.",
                   texLabel="\\lambda_w")     

    m <= parameter(:β,      0.1402, (1e-5, 10.),   (1e-5, 10.),     DSGE.Exponential(),    GammaAlt(0.25, 0.1),        fixed=false,  scaling = x -> 1/(1 + x/100),
                   description="β: Discount rate.",       
                   texLabel="\\beta ")

    m <= parameter(:ψ1,     1.3679, (1e-5, 10.),   (1e-5, 10.00),   DSGE.Exponential(),    Normal(1.5, 0.25),          fixed=false,
                   description="ψ₁: Weight on inflation gap in monetary policy rule.",
                   texLabel="\\psi_1")

    m <= parameter(:ψ2,     0.0388, (-0.5, 0.5),   (-0.5, 0.5),     Untransformed(),  Normal(0.12, 0.05),         fixed=false,
                   description="ψ₂: Weight on output gap in monetary policy rule.",
                   texLabel="\\psi_2")

    m <= parameter(:ψ3,     0.2464, (-0.5, 0.5),   (-0.5, 0.5),     Untransformed(),  Normal(0.12, 0.05),         fixed=false,
                   description="ψ₃: Weight on rate of change of output gap in the monetary policy rule.",
                   texLabel="\\psi_3")

    m <= parameter(:π_star,   0.5000, (1e-5, 10.),   (1e-5, 10.),     DSGE.Exponential(),    GammaAlt(0.75, 0.4),        fixed=true,  scaling = x -> 1 + x/100,
                   description="π_star: The steady-state rate of inflation.",  
                   texLabel="\\pi_*")   

    m <= parameter(:σ_c,   0.8719, (1e-5, 10.),   (1e-5, 10.),     DSGE.Exponential(),    Normal(1.5, 0.37),          fixed=false,
                   description="σ_c: This is the something something.",
                   texLabel="\\sigma_{c}")
    
    m <= parameter(:ρ,      0.7126, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.75, 0.10),        fixed=false,
                   description="ρ: The degree of inertia in the monetary policy rule.",
                   texLabel="\\rho")
    
    m <= parameter(:ϵ_p,     10.000,                                                                               fixed=true,
                   description="ϵ_p: This is the something something.",
                   texLabel="\\varepsilon_{p}")     

    m <= parameter(:ϵ_w,     10.000,                                                                               fixed=true,
                   description="ϵ_w: This is the something something.",
                   texLabel="\\varepsilon_{w}")     

    # financial frictions parameters
    m <= parameter(:Fω,      0.0300, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.03, 0.01),         fixed=true,    scaling = x -> 1 - (1-x)^0.25,
                   description="F(ω): The cumulative distribution function of ω (idiosyncratic iid shock that increases or decreases entrepreneurs' capital).",
                   texLabel="F(\omega)")
    
    m <= parameter(:sprd,     1.7444, (0., 100.),      (1e-5, 0.),    DSGE.Exponential(),   GammaAlt(2., 0.1),           fixed=false,  scaling = x -> (1 + x/100)^0.25,
                   description="spr_*: This is the something something.",   
                   texLabel="spr_*")

    m <= parameter(:ζ_spb, 0.0559, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.05, 0.005),        fixed=false,
                   description="ζ_spb: The elasticity of the expected exess return on capital (or 'spread') with respect to leverage.",
                   texLabel="\\zeta_{spb}")
    
    m <= parameter(:γ_star, 0.9900, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.99, 0.002),        fixed=true,
                   description="γ_star: This is the something something.",
                   texLabel="\\gamma_*")

    # exogenous processes - level
    m <= parameter(:γ,      0.3673, (-5.0, 5.0),     (-5., 5.),     Untransformed(), Normal(0.4, 0.1),            fixed=false, scaling = x -> x/100, 
                   description="γ: The log of the steady-state growth rate of technology.", # check this, I thinkt that's γ_star
                   texLabel="\\gamma")

    m <= parameter(:Lmean,  -45.9364, (-1000., 1000.), (-1e3, 1e3),   Untransformed(), Normal(-45, 5),              fixed=false,
                   description="Lmean: This is the something something.",
                   texLabel="Lmean")

    m <= parameter(:g_star,    0.1800,                                                                               fixed=true,
                   description="g_star: This is the something something.",
                   texLabel="g_*")  

    # exogenous processes - autocorrelation 
    m <= parameter(:ρ_g,      0.9863, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_g: AR(1) coefficient in the government spending process.",
                   texLabel="\\rho_g")

    m <= parameter(:ρ_b,      0.9410, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_b: AR(1) coefficient in the intertemporal preference shifter process.",
                   texLabel="\\rho_b")

    m <= parameter(:ρ_μ,     0.8735, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_μ: AR(1) coefficient in capital adjustment cost process.",
                   texLabel="\\rho_{\\mu}")

    m <= parameter(:ρ_z,      0.9446, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_z: AR(1) coefficient in the technology process.",
                   texLabel="\\rho_z")

    m <= parameter(:ρ_λ_f,    0.8827, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_λ_f: AR(1) coefficient in the price mark-up shock process.",
                   texLabel="\\rho_{\\lambda_f}") 

    m <= parameter(:ρ_λ_w,    0.3884, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_λ_w: AR(1) coefficient in the wage mark-up shock process.", # CHECK THIS
                   texLabel="\\rho_{\\lambda_f}")

    #monetary policy shock - see eqcond
    m <= parameter(:ρ_rm,     0.2135, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_rm: AR(1) coefficient in the monetary policy shock process.", # CHECK THIS
                   texLabel="\\rho_{rm}")

    # TODO - check this
    m <= parameter(:ρ_σ_w,   0.9898, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.75, 0.15),         fixed=false,
                   description="ρ_σ_w: The standard deviation of entrepreneurs' capital productivity follows an exogenous process with mean ρ_σ_w. Innovations to the process are called _spread shocks_.",
                   texLabel="\\rho_{\\sigma \\omega}")

    # TODO - We're skipping this for now
    m <= parameter(:ρ_μe,    0.7500, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.75, 0.15),         fixed=true,
                   description="ρ_μ_e: Verification costs are a fraction μ_e of the amount the bank extracts from an entrepreneur in case of bankruptcy???? This doesn't seem right because μ_e isn't a process (p12 of PDF)",
                   texLabel="\\rho_{\\mu_e}")

    ## TODO
    m <= parameter(:ρ_γ,   0.7500, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.75, 0.15),         fixed=true,  description="ρ_γ: AR(1) coefficient on XX process.",              texLabel="\\rho_{\\gamma}")    
    m <= parameter(:ρ_π_star,   0.9900, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=true,  description="ρ_π_star: This is the something something.",         texLabel="\\rho_{pi}^*")   
    m <= parameter(:ρ_lr,     0.6936, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_lr: This is the something something.",             texLabel="\\rho_{lr}")      
    m <= parameter(:ρ_z_p,     0.8910, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_z_p: This is the something something.",             texLabel="\\rho_{z^p}")    
    m <= parameter(:ρ_tfp,    0.1953, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_tfp: This is the something something.",            texLabel="\\rho_{tfp}")     
    m <= parameter(:ρ_gdpdef, 0.5379, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_gdpdef: GDP deflator.",                            texLabel="\\rho_{gdpdef}")  
    m <= parameter(:ρ_pce,    0.2320, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_pce: This is the something something.",            texLabel="\\rho_{pce}")     

    m <= parameter(:ρ_gdp,    0.0, (-0.999, 0.999),  (-0.999, 0.999), SquareRoot(), Normal(0.0, 0.2), fixed=false,
                   description = "ρ_gdp: Something something",
                   texLabel = "\\rho_{gdp}")
    
    m <= parameter(:ρ_gdy,    0.0, (-0.999, 0.999), (-0.999, 0.999), SquareRoot(), Normal(0.0, 0.2), fixed=false,
                   description = "ρ_gdy: Something something",
                   texLabel = "\\rho_{gdy}")
    
    m <= parameter(:varρ_gdp, 0.0, (-0.999, 0.999),  (-0.999, 0.999), SquareRoot(), Normal(0.0, 0.4), fixed=false,
                   description = "varρ_gdp: Something something",
                   texLabel = "var\\rho_{gdp}")

    
    m <= parameter(:me_level, 1.0, fixed=true,
                   description = "me_level: Indicates whether measurement error is in levels (if zero, measurement error is in growth rates)",
                   texLabel = "melevel")

    
    # exogenous processes - standard deviation
    m <= parameter(:σ_g,      2.5230, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_g: The standard deviation of the government spending process.",
                   texLabel="\\sigma_{g}")
    
    m <= parameter(:σ_b,      0.0292, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_b: This is the something something.",
                   texLabel="\\sigma_{b}")

    m <= parameter(:σ_μ,     0.4559, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_μ: The standard deviation of the exogenous marginal efficiency of investment shock process.",
                   texLabel="\\sigma_{\\mu}")

    ## TODO
    m <= parameter(:σ_z,      0.6742, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_z: This is the something something.",
                   texLabel="\\sigma_{z}")

    m <= parameter(:σ_λ_f,    0.1314, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_λ_f: The mean of the process that generates the price elasticity of the composite good.  Specifically, the elasticity is (1+λ_{f,t})/(λ_{f_t}).",
                   texLabel="\\sigma_{\\lambda_f}")

    ## TODO
    m <= parameter(:σ_λ_w,    0.3864, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_λ_w: This is the something something.",
                   texLabel="\\sigma_{\\lambda_w}")

    ## TODO
    m <= parameter(:σ_rm,     0.2380, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_rm: This is the something something.",
                   texLabel="\\sigma_{rm}")
    
    m <= parameter(:σ_σ_ω,   0.0428, (1e-7,100.),     (1e-5, 0.),    DSGE.Exponential(),   RootInverseGamma(4., 0.05),  fixed=false,
                   description="σ_σ_ω: The standard deviation of entrepreneurs' capital productivity follows an exogenous process with standard deviation σ_σ_ω.",
                   texLabel="\\sigma_{\\sigma_\\omega}")
    
    m <= parameter(:σ_μe,    0.0000, (1e-7,100.),     (1e-5, 0.),    DSGE.Exponential(),   RootInverseGamma(4., 0.05),  fixed=true,  description="σ_μ_e: This is the something something.",           texLabel="\\sigma_{μe}")
    m <= parameter(:σ_γ,   0.0000, (1e-7,100.),     (1e-5, 0.),    DSGE.Exponential(),   RootInverseGamma(4., 0.01),  fixed=true,  description="σ_γ: This is the something something.",             texLabel="\\sigma_{\\gamma}")    
    m <= parameter(:σ_π_star,   0.0269, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(6., 0.03),  fixed=false, description="σ_π_star: This is the something something.",        texLabel="\\sigma_{pi}^*")   
    m <= parameter(:σ_lr,     0.1766, (1e-8,10.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.75),  fixed=false, description="σ_lr: This is the something something to do with long run inflation expectations.",
                   texLabel="\\sigma_{lr}")      
    m <= parameter(:σ_z_p,     0.1662, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_z_p: This is the something something.",            texLabel="\\sigma_{z^p}")    
    m <= parameter(:σ_tfp,    0.9391, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_tfp: This is the something something.",           texLabel="\\sigma_{tfp}")     
    m <= parameter(:σ_gdpdef, 0.1575, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_gdpdef: This is the something something.",        texLabel="\\sigma_{gdpdef}")  
    m <= parameter(:σ_pce,    0.0999, (1e-8, 5.),      (1e-8, 5.),    DSGE.Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_pce: This is the something something.",           texLabel="\\sigma_{pce}")     
    m <= parameter(:σ_gdp, 0.1, (1e-8, 5.), (1e-8, 5.), DSGE.Exponential(),
                   RootInverseGamma(2., 0.10), fixed=false,
                   description = "σ_gdp: Something something",
                   texLabel="\\sigma_{gdp}")

    m <= parameter(:σ_gdy, 0.1, (1e-8, 5.), (1e-8, 5.), DSGE.Exponential(),
                   RootInverseGamma(2., 0.10), fixed=false,  
                   description = "σ_gdp: Something something",
                   texLabel="\\sigma_{gdp}")
    
    # standard deviations of the anticipated policy shocks
    for i = 1:num_anticipated_shocks_padding(m)
        if i < 13
            m <= parameter(symbol("σ_rm$i"), .2, (1e-7, 100.), (1e-5, 0.), DSGE.Exponential(),
                           RootInverseGamma(4., .2), fixed=false,
                           description="σ_rm$i: This is the something something.",
                           texLabel=@sprintf("\\sigma_ant{%d}",i))
        else
            m <= parameter(symbol("σ_rm$i"), .0, (1e-7, 100.), (1e-5, 0.),
                           DSGE.Exponential(), RootInverseGamma(4., .2), fixed=true,
                           description="σ_rm$i: This is the something something.",
                           texLabel=@sprintf("\\sigma_ant{%d}",i))
        end
    end

    ## TODO - look at etas in eqcond and figure out what they are, then confirm with Marc and Marco
    m <= parameter(:η_gz,       0.8400, (1e-5, 0.999), (1e-5, 0.999), SquareRoot(),
                   BetaAlt(0.50, 0.20), fixed=false,
                   description="η_gz: Has to do with correlation of g and z shocks.",
                   texLabel="\\eta_{gz}")        

    m <= parameter(:η_λ_f,      0.7892, (1e-5, 0.999), (1e-5, 0.999), SquareRoot(),
                   BetaAlt(0.50, 0.20),         fixed=false,
                   description="η_λ_f: This is the something something.",
                   texLabel="\\eta_{\\lambda_f}")

    m <= parameter(:η_λ_w,      0.4226, (1e-5, 0.999), (1e-5, 0.999), SquareRoot(),
                   BetaAlt(0.50, 0.20),         fixed=false,
                   description="η_λ_w: AR(2) coefficient on wage markup shock process.",
                   texLabel="\\eta_{\\lambda_w}")

    m <= parameter(:modelα_ind, 0.0000, (0.000, 1.000), (0., 0.), Untransformed(),
                   BetaAlt(0.50, 0.20), fixed=true,
                   description="modelα_ind: Indicates whether to use the model's endogenous α in the capacity utilization adjustment of total factor productivity.",
                   texLabel="i_{\\alpha}^model")
    
    m <= parameter(:Γ_gdpdef,  1.0354, (-10., 10.), (-10., -10.),  Untransformed(),
                   Normal(1.00, 2.), fixed=false,
                   description="Γ_gdpdef: This is the something something to do with the gdp deflator.",
                   texLabel="\\Gamma_{gdpdef}")

    m <= parameter(:δ_gdpdef,   0.0181, (-9.1, 9.1), (-10., -10.),  Untransformed(),
                   Normal(0.00, 2.),            fixed=false,
                   description="δ_gdpdef: This is the something something.",
                   texLabel="\\delta_{gdpdef}")


    m <= parameter(:γ_gdy, 1.0, (-10., 10.), (-10., -10.), Untransformed(), Normal(1.0, 2.0), fixed=true,
                   description = "This is the something something",
                   texLabel="\\gamma_{gdy}")

    m <= parameter(:δ_gdy, 0.0, (-10., 10.), (-10., -10.) , Untransformed(), Normal(0.0, 2.0), fixed=true,
                   description = "this is the something something",
                   texLabel="\\delta_{gdy}")
    
    # steady states
    m <= SteadyStateParameter(:zstar,  NaN, description="steady-state growth rate of productivity", texLabel="\\z_*")
    m <= SteadyStateParameter(:rstar,   NaN, description="steady-state something something", texLabel="\\r_*")
    m <= SteadyStateParameter(:Rstarn,  NaN, description="steady-state something something", texLabel="\\R_*_n")
    m <= SteadyStateParameter(:rkstar,  NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= SteadyStateParameter(:wstar,   NaN, description="steady-state something something", texLabel="\\w_*")
    m <= SteadyStateParameter(:Lstar,   NaN, description="steady-state something something", texLabel="\\L_*") 
    m <= SteadyStateParameter(:kstar,   NaN, description="Effective capital that households rent to firms in the steady state.", texLabel="\\k_*")
    m <= SteadyStateParameter(:kbarstar, NaN, description="Total capital owned by households in the steady state.", texLabel="\\bar{k}_*")
    m <= SteadyStateParameter(:istar,  NaN, description="Detrended steady-state investment", texLabel="\\i_*")
    m <= SteadyStateParameter(:ystar,  NaN, description="steady-state something something", texLabel="\\y_*")
    m <= SteadyStateParameter(:cstar,  NaN, description="steady-state something something", texLabel="\\c_*")
    m <= SteadyStateParameter(:wl_c,   NaN, description="steady-state something something", texLabel="\\wl_c")
    m <= SteadyStateParameter(:nstar,  NaN, description="steady-state something something", texLabel="\\n_*")
    m <= SteadyStateParameter(:vstar,  NaN, description="steady-state something something", texLabel="\\v_*")
    m <= SteadyStateParameter(:ζ_spσ_ω,  NaN, description="steady-state something something", texLabel="\\zeta_{sp_σ_w}")
    m <= SteadyStateParameter(:ζ_spμe,   NaN, description="steady-state something something", texLabel="\\zeta_{sp_μ_e}")
    m <= SteadyStateParameter(:ζ_nRk,     NaN, description="steady-state something something", texLabel="\\zeta_{n_R_k}")
    m <= SteadyStateParameter(:ζ_nR,      NaN, description="steady-state something something", texLabel="\\zeta{n_R}")
    m <= SteadyStateParameter(:ζ_nqk,     NaN, description="steady-state something something", texLabel="\\zeta{n_q_k}")
    m <= SteadyStateParameter(:ζ_nn,      NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= SteadyStateParameter(:ζ_nμe,    NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= SteadyStateParameter(:ζ_nσ_ω,   NaN, description="steady-state something something", texLabel="\\BLAH")


    initialize_model_indices!(m)
    initialize_subspec(m)
    steadystate!(m)
    return m
end

# functions that are used to compute financial frictions
# steady-state values from parameter values
@inline function ζ_spb_fn(z, σ, sprd)
    zetaratio = ζ_bω_fn(z, σ, sprd)/ζ_zω_fn(z, σ, sprd)
    nk = nk_fn(z, σ, sprd)
    return -zetaratio/(1-zetaratio)*nk/(1-nk)
end

@inline function ζ_bω_fn(z, σ, sprd)
    nk          = nk_fn(z, σ, sprd)
    μstar       = μ_fn(z, σ, sprd)
    ω_star       = ω_fn(z, σ)
    Γstar       = Γ_fn(z, σ)
    Gstar       = G_fn(z, σ)
    dΓ_dω_star   = dΓ_dω_fn(z)
    dG_dω_star   = dG_dω_fn(z, σ)
    d2Γ_dω2star = d2Γ_dω2_fn(z, σ)
    d2G_dω2star = d2G_dω2_fn(z, σ)
    return ω_star*μstar*nk*(d2Γ_dω2star*dG_dω_star - d2G_dω2star*dΓ_dω_star)/
        (dΓ_dω_star - μstar*dG_dω_star)^2/sprd/(1 - Γstar + dΓ_dω_star*(Γstar - μstar*Gstar)/
            (dΓ_dω_star - μstar*dG_dω_star))
end

@inline function ζ_zω_fn(z, σ, sprd)
    μstar = μ_fn(z, σ, sprd)
    return ω_fn(z, σ)*(dΓ_dω_fn(z) - μstar*dG_dω_fn(z, σ))/
        (Γ_fn(z, σ) - μstar*G_fn(z, σ))
end

nk_fn(z, σ, sprd) = 1 - (Γ_fn(z, σ) - μ_fn(z, σ, sprd)*G_fn(z, σ))*sprd
μ_fn(z, σ, sprd)  =
    (1 - 1/sprd)/(dG_dω_fn(z, σ)/dΓ_dω_fn(z)*(1 - Γ_fn(z, σ)) + G_fn(z, σ))
ω_fn(z, σ)        = exp(σ*z - σ^2/2)
G_fn(z, σ)        = cdf(Normal(), z-σ)
Γ_fn(z, σ)        = ω_fn(z, σ)*(1 - cdf(Normal(), z)) + cdf(Normal(), z-σ)
dG_dω_fn(z, σ)    = pdf(Normal(), z)/σ
d2G_dω2_fn(z, σ)  = -z*pdf(Normal(), z)/ω_fn(z, σ)/σ^2
dΓ_dω_fn(z)       = 1 - cdf(Normal(), z)
d2Γ_dω2_fn(z, σ)  = -pdf(Normal(), z)/ω_fn(z, σ)/σ
dG_dσ_fn(z, σ)    = -z*pdf(Normal(), z-σ)/σ
d2G_dωdσ_fn(z, σ) = -pdf(Normal(), z)*(1 - z*(z-σ))/σ^2
dΓ_dσ_fn(z, σ)    = -pdf(Normal(), z-σ)
d2Γ_dωdσ_fn(z, σ) = (z/σ-1)*pdf(Normal(), z)

#=
doc"""
Inputs: `m::Model994`

Description: (Re)calculates the model's steady-state values. `steadystate!(m)` must be called whenever the parameters of `m` are updated. 
"""
=#
# (Re)calculates steady-state values
function steadystate!(m::Model994)
    SIGWSTAR_ZERO = 0.5
    
    m[:zstar]    = log(1+m[:γ]) + m[:α]/(1-m[:α])*log(m[:Upsilon])
    m[:rstar]    = exp(m[:σ_c]*m[:zstar]) / m[:β]
    m[:Rstarn]   = 100*(m[:rstar]*m[:π_star] - 1)
    m[:rkstar]   = m[:sprd]*m[:rstar]*m[:Upsilon] - (1-m[:δ])
    m[:wstar]    = (m[:α]^m[:α] * (1-m[:α])^(1-m[:α]) * m[:rkstar]^(-m[:α]) / m[:Φ])^(1/(1-m[:α]))
    m[:Lstar]    = 1.
    m[:kstar]    = (m[:α]/(1-m[:α])) * m[:wstar] * m[:Lstar] / m[:rkstar]
    m[:kbarstar] = m[:kstar] * (1+m[:γ]) * m[:Upsilon]^(1 / (1-m[:α]))
    m[:istar]    = m[:kbarstar] * (1-((1-m[:δ])/((1+m[:γ]) * m[:Upsilon]^(1/(1-m[:α])))))
    m[:ystar]    = (m[:kstar]^m[:α]) * (m[:Lstar]^(1-m[:α])) / m[:Φ]
    m[:cstar]    = (1-m[:g_star])*m[:ystar] - m[:istar]
    m[:wl_c]     = (m[:wstar]*m[:Lstar])/(m[:cstar]*m[:λ_w])

    # FINANCIAL FRICTIONS ADDITIONS
    # solve for σ_ω_star and zω_star
    zω_star = quantile(Normal(), m[:Fω].scaledvalue)
    σ_ω_star = SIGWSTAR_ZERO
    try 
        σ_ω_star = fzero(sigma -> ζ_spb_fn(zω_star, sigma, m[:sprd]) - m[:ζ_spb], 0.5)
    catch
        σ_ω_star = SIGWSTAR_ZERO
    end
    # evaluate ωbarstar
    ωbarstar = ω_fn(zω_star, σ_ω_star)

    # evaluate all BGG function elasticities
    Gstar                   = G_fn(zω_star, σ_ω_star)
    Γstar               = Γ_fn(zω_star, σ_ω_star)
    dGdω_star            = dG_dω_fn(zω_star, σ_ω_star)
    d2Gdω2star          = d2G_dω2_fn(zω_star, σ_ω_star)
    dΓdω_star        = dΓ_dω_fn(zω_star)
    d2Γdω2star      = d2Γ_dω2_fn(zω_star, σ_ω_star)
    dGdσstar            = dG_dσ_fn(zω_star, σ_ω_star)
    d2Gdωdσstar     = d2G_dωdσ_fn(zω_star, σ_ω_star)
    dΓdσstar        = dΓ_dσ_fn(zω_star, σ_ω_star)
    d2Γdωdσstar = d2Γ_dωdσ_fn(zω_star, σ_ω_star)

    # evaluate μ, nk, and Rhostar
    μestar       = μ_fn(zω_star, σ_ω_star, m[:sprd])
    nkstar        = nk_fn(zω_star, σ_ω_star, m[:sprd])
    Rhostar       = 1/nkstar - 1

    # evaluate wekstar and vkstar
    wekstar       = (1-m[:γ_star]/m[:β])*nkstar - m[:γ_star]/m[:β]*(m[:sprd]*(1-μestar*Gstar) - 1)
    vkstar        = (nkstar-wekstar)/m[:γ_star]

    # evaluate nstar and vstar
    m[:nstar]       = nkstar*m[:kstar]
    m[:vstar]       = vkstar*m[:kstar]

    # a couple of combinations
    ΓμG      = Γstar - μestar*Gstar
    ΓμGprime = dΓdω_star - μestar*dGdω_star

    # elasticities wrt ωbar 
    ζ_bw       = ζ_bω_fn(zω_star, σ_ω_star, m[:sprd])
    ζ_zw       = ζ_zω_fn(zω_star, σ_ω_star, m[:sprd])
    ζ_bw_zw    = ζ_bw/ζ_zw

    # elasticities wrt σ_ω
    ζ_bσ_ω      = σ_ω_star * (((1 - μestar*dGdσstar/dΓdσstar) /
        (1 - μestar*dGdω_star/dΓdω_star) - 1)*dΓdσstar*m[:sprd] + μestar*nkstar*
            (dGdω_star*d2Γdωdσstar - dΓdω_star*d2Gdωdσstar)/ΓμGprime^2) /
                ((1 - Γstar)*m[:sprd] + dΓdω_star/ΓμGprime*(1-nkstar))
    ζ_zσ_ω      = σ_ω_star * (dΓdσstar - μestar*dGdσstar) / ΓμG
    m[:ζ_spσ_ω] = (ζ_bw_zw*ζ_zσ_ω - ζ_bσ_ω) / (1-ζ_bw_zw)

    # elasticities wrt μe
    ζ_bμe      = μestar * (nkstar*dΓdω_star*dGdω_star/ΓμGprime+dΓdω_star*Gstar*m[:sprd]) /
        ((1-Γstar)*ΓμGprime*m[:sprd] + dΓdω_star*(1-nkstar))
    ζ_zμe      = -μestar*Gstar/ΓμG
    m[:ζ_spμe] = (ζ_bw_zw*ζ_zμe - ζ_bμe) / (1-ζ_bw_zw)

    # some ratios/elasticities
    Rkstar        = m[:sprd]*m[:π_star]*m[:rstar] # (rkstar+1-δ)/Upsilon*π_star
    ζ_gw       = dGdω_star/Gstar*ωbarstar
    ζ_Gσ_ω    = dGdσstar/Gstar*σ_ω_star

    # elasticities for the net worth evolution
    m[:ζ_nRk]    = m[:γ_star]*Rkstar/m[:π_star]/exp(m[:zstar])*(1+Rhostar)*(1 - μestar*Gstar*(1 - ζ_gw/ζ_zw))
    m[:ζ_nR]     = m[:γ_star]/m[:β]*(1+Rhostar)*(1 - nkstar + μestar*Gstar*m[:sprd]*ζ_gw/ζ_zw)
    m[:ζ_nqk]    = m[:γ_star]*Rkstar/m[:π_star]/exp(m[:zstar])*(1+Rhostar)*(1 - μestar*Gstar*(1+ζ_gw/ζ_zw/Rhostar)) - m[:γ_star]/m[:β]*(1+Rhostar)
    m[:ζ_nn]     = m[:γ_star]/m[:β] + m[:γ_star]*Rkstar/m[:π_star]/exp(m[:zstar])*(1+Rhostar)*μestar*Gstar*ζ_gw/ζ_zw/Rhostar
    m[:ζ_nμe]   = m[:γ_star]*Rkstar/m[:π_star]/exp(m[:zstar])*(1+Rhostar)*μestar*Gstar*(1 - ζ_gw*ζ_zμe/ζ_zw)
    m[:ζ_nσ_ω]  = m[:γ_star]*Rkstar/m[:π_star]/exp(m[:zstar])*(1+Rhostar)*μestar*Gstar*(ζ_Gσ_ω-ζ_gw/ζ_zw*ζ_zσ_ω)

    return m
end

function settings_m994(m::Model994)

    # Anticipated shocks
    m <= Setting(:num_anticipated_shocks,         6, "Number of anticipated policy shocks")
    m <= Setting(:num_anticipated_shocks_padding, 20, "Padding for anticipated policy shocks")
    m <= Setting(:num_anticipated_lags,  24, "Number of periods back to incorporate zero bound expectations")

    return default_settings(m)
end