# https://arxiv.org/abs/1809.03057
struct OSCFRSolver{M,B,K,G} <: AbstractCFRSolver{K,G}
    method::M
    baseline::B
    I::Dict{K, InfoState}
    game::G
    ϵ::Float64
end

"""
    OSCFRSolver(game; method=Vanilla(), baseline=ZeroBaseline(), ϵ::Float64 = 0.6)

Instantiate outcome sampling CFR solver with some `game`.

Samples a single actions from all players for single tree traversal.
Time to complete a traversal is O(d), where d is the depth of the game.

`ϵ` - exploration parameter

Available baselines:
- [`ZeroBaseline`](@ref) - Equivalent to no baseline
- [`ExpectedValueBaseline`](@ref)
"""
function OSCFRSolver(
    game::Game{H,K};
    method      = Vanilla(),
    baseline    = ZeroBaseline(),
    ϵ::Float64  = 0.6) where {H,K}

    return OSCFRSolver(method, baseline, Dict{K, InfoState}(), game, ϵ)
end

function CFR(sol::OSCFRSolver, h, p, t, π_i=1.0, π_ni=1.0, q_h=1.0)
    (;game, baseline, ϵ) = sol
    current_player = player(game, h)

    if isterminal(game, h) # (a)
        return utility(game, p, h)

    elseif iszero(current_player)
        σ_c = chance_policy(game, h)
        a, p_c = randpdf(σ_c)
        h′ = next_hist(game,h,a)
        return CFR(sol, h′, p, t, π_i, π_ni*p_c, q_h)

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

function regret_update!(sol::OSCFRSolver{Discount}, r, ûbσIa, ûbσI, t)
    (;α, β) = sol.method
    for k in eachindex(r)
        r_k = ûbσIa[k] - ûbσI
        r[k] += if r_k > 0.0
            (t^α)*r_k
        else
            (t^β)*r_k
        end
    end
end

function regret_update!(sol::OSCFRSolver{Plus}, r, ûbσIa, ûbσI, t)
    @. r = max(ûbσIa - ûbσI + r, 0.0)
end

function regret_update!(sol::OSCFRSolver{Vanilla}, r, ûbσIa, ûbσI, t)
    @. r += ûbσIa - ûbσI
end

function strat_update!(sol::OSCFRSolver{Discount}, I, σ, π_ni, q_h, t)
    @. I.s += (t^sol.method.γ)*(π_ni / q_h) * σ
end

function strat_update!(sol::OSCFRSolver{Plus}, I, σ, π_ni, q_h, t)
    w = max(t - sol.method.d, 1)
    @. I.s += (π_ni / q_h) * w * σ
end

function strat_update!(sol::OSCFRSolver{Vanilla}, I, σ, π_ni, q_h, t)
    @. I.s += (π_ni / q_h) * σ
end

function train!(solver::OSCFRSolver, N::Int; show_progress::Bool=false, cb=()->())
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t)
        end
        cb()
        next!(prog)
    end
    solver
end
