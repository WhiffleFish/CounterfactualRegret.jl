# https://arxiv.org/abs/1809.03057
struct OSCFRSolver{method,B,K,G,I} <: AbstractCFRSolver{K,G,I}
    m::Val{method}
    baseline::B
    I::Dict{K, I}
    game::G
    α::Float64
    β::Float64
    γ::Float64
    ϵ::Float64
    d::Int
end

"""
    OSCFRSolver(game::Game; method::Symbol=:vanilla, baseline = ZeroBaseline(), alpha::Float64 = 1.0, beta::Float64 = 1.0, gamma::Float64 = 1.0, d::Int, ϵ::Float64 = 0.6,)

Instantiate outcome sampling CFR solver with some `game`.

Samples a single actions from all players for single tree traversal.
Time to complete a traversal is O(d), where d is the depth of the game. 

Available methods:
- `:vanilla` default (Zinkevich 2009)
- `:discount` uses `alpha`, `beta`, `gamma` kwargs for discounted OSCFR (Brown 2019)
    - `alpha`   - discount on positive regret
    - `beta`    - discount on negative regret
    - `gamma`   - discount on strategy 
- `:plus` employs OSCFR+ with linear weighting and initial weighting threshold `d` (Tammelin 2014)

`ϵ` - exploration parameter

Available baselines:
- `ZeroBaseline` - Equivalent to no baseline
- [`ExpectedValueBaseline`](@ref)
"""
function OSCFRSolver(
    game::Game{H,K};
    method::Symbol  = :vanilla,
    baseline        = ZeroBaseline(),
    alpha::Float64  = 1.0,
    beta::Float64   = 1.0,
    gamma::Float64  = 1.0,
    ϵ::Float64      = 0.6,
    d::Int          = 0) where {H,K}

    if method ∈ (:vanilla, :discount, :plus)
        return OSCFRSolver(Val(method), baseline, Dict{K, InfoState}(), game, alpha, beta, gamma, ϵ, d)
    else
        error("method $method ∉ (:vanilla, :discount, :plus)")
    end
end

function CFR(sol::OSCFRSolver, h, p, t, π_i=1.0, π_ni=1.0, q_h=1.0)
    (;game, baseline, ϵ) = sol
    current_player = player(game, h)

    if isterminal(game, h) # (a)
        return utility(game, p, h)

    elseif iszero(current_player)
        A = chance_actions(game, h)
        a = rand(A)
        h′ = next_hist(game,h,a)
        return CFR(sol, h′, p, t, π_i, π_ni*inv(length(A)), q_h)

    elseif current_player == p
        k = infokey(game, h)
        I = infoset(sol, k)
        A = actions(game, k)

        σ = regret_match!(I) # (b)

        a_idx = rand() > ϵ ? weighted_sample(σ) : rand(eachindex(A))
        a = A[a_idx]
        p_a = σ[a_idx]*(1-ϵ) + ϵ/length(A)
        h′ = next_hist(game, h, a)

        K = infokey(game, h)
        b = baseline(K, length(A))

        u = CFR(sol, h′, p, t, π_i*σ[a_idx], π_ni, q_h*p_a)

        ûbσha = I._tmp_σ

        ûbσh = 0.0
        for (k,a) in enumerate(A)
            bIa = b[k]
            ûbσha[k] = if k == a_idx
                ξha = p_a
                bIa + ((u - bIa) / ξha)
            else
                bIa
            end
            ûbσh += σ[k]*ûbσha[k]
        end

        ûbσI = 0.0
        ûbσIa = ûbσha .*= (π_ni / q_h)
        for k in eachindex(ûbσIa) # (d)
            ûbσI += σ[k]*ûbσIa[k]
        end

        regret_update!(sol, I.r, ûbσIa, ûbσI, t)

        update!(baseline, K, ûbσIa)

        return ûbσh
    else
        k = infokey(game, h)
        I = infoset(sol, k)
        A = actions(game, k)
        
        σ = I.σ

        K = infokey(game, h)
        b = sol.baseline(K, length(A))

        a_idx = weighted_sample(σ)
        a = A[a_idx]
        h′ = next_hist(game, h, a)

        u = CFR(sol, h′, p, t, π_i, π_ni*σ[a_idx], q_h*σ[a_idx])

        ûbσh = 0.0
        for (k,a) in enumerate(A)
            bIa = b[k]
            ûbσha = if k == a_idx
                ξha = σ[k]
                bIa + (u - bIa) / ξha
            else
                bIa
            end
            ûbσh += σ[k]*ûbσha
        end

        strat_update!(sol, I, σ, π_ni, q_h, t)

        return ûbσh
    end
end

function regret_update!(sol::OSCFRSolver{:discount}, r, ûbσIa, ûbσI, t)
    (;α, β) = sol
    for k in eachindex(r)
        r_k = ûbσIa[k] - ûbσI
        r[k] += if r_k > 0.0
            (t^α)*r_k
        else
            (t^β)*r_k
        end
    end
end

function regret_update!(sol::OSCFRSolver{:plus}, r, ûbσIa, ûbσI, t)
    @. r = max(ûbσIa - ûbσI + r, 0.0)
end

function regret_update!(sol::OSCFRSolver{:vanilla}, r, ûbσIa, ûbσI, t)
    @. r += ûbσIa - ûbσI
end

function strat_update!(sol::OSCFRSolver{:discount}, I, σ, π_ni, q_h, t)
    @. I.s += (t^sol.γ)*(π_ni / q_h) * σ
end

function strat_update!(sol::OSCFRSolver{:plus}, I, σ, π_ni, q_h, t)
    @. I.s += (π_ni / q_h) * t * σ
end

function strat_update!(sol::OSCFRSolver{:vanilla}, I, σ, π_ni, q_h, t)
    @. I.s += (π_ni / q_h) * σ
end

function train!(solver::OSCFRSolver, N::Int; show_progress::Bool=false, cb=()->())
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, max(t-solver.d,0))
        end
        cb()
        next!(prog)
    end
    finalize_strategies!(solver)
end
