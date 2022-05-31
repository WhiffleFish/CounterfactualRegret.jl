struct OSCFRSolver{method,K,G,I} <: AbstractCFRSolver{K,G,I}
    m::Val{method}
    I::Dict{K, I}
    game::G
    α::Float64
    β::Float64
    γ::Float64
    ϵ::Float64
end

function OSCFRSolver(
    game::Game{H,K};
    method::Symbol  = :vanilla,
    alpha::Float64  = 1.0,
    beta::Float64   = 1.0,
    gamma::Float64  = 1.0,
    ϵ::Float64      = 0.6) where {H,K}

    if method ∈ (:vanilla, :discount, :plus)
        return OSCFRSolver(Val(method), Dict{K, InfoState}(), game, alpha, beta, gamma, ϵ)
    else
        error("method $method ∉ (:vanilla, :discount, :plus)")
    end
end

function CFR(sol::OSCFRSolver, h, p, t, π_i=1.0, π_ni=1.0, s=1.0)
    (;game,ϵ) = sol
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, p, h)/s , 1.0

    elseif iszero(current_player)
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return CFR(sol, h′, p, t, π_i, π_ni, s)

    elseif current_player == p
        I = infoset(sol, h)
        A = actions(game, h)
        σ = regret_match!(I)

        σ′ = I._tmp_σ .= ϵ/length(A) .+ (1-ϵ) .* σ

        a_idx = weighted_sample(σ′)
        a = A[a_idx]
        h′ = next_hist(game, h, a)
        u, π_tail = CFR(sol, h′, p, t, π_i*σ[a_idx], π_ni, s*σ′[a_idx])

        W = u*π_ni
        regret_update!(sol, I, σ, W, a_idx, π_tail, t)

        return u, π_tail*σ[a_idx]
    else
        I = infoset(sol, h)
        A = actions(game, h)
        σ = I.σ

        a_idx = weighted_sample(σ)
        a = A[a_idx]
        h′ = next_hist(game, h, a)
        u, π_tail = CFR(sol, h′, p, t, π_i, π_ni*σ[a_idx], s*σ[a_idx])
        strat_update!(sol, I, σ, π_ni, s, t)

        return u, π_tail*σ[a_idx]
    end
end

function regret_update!(sol::OSCFRSolver{:discount}, I, σ, W, a_idx, π_tail, t)
    (;α, β) = sol
    for k in eachindex(σ)
        r_k = if k == a_idx
            W*π_tail*(1 - σ[a_idx])
        else
            -W*σ[a_idx]
        end
        I.r[k] += if r_k > 0.0
            (t^α)*r_k
        else
            (t^β)*r_k
        end
    end
end

function regret_update!(sol::OSCFRSolver{:plus}, I, σ, W, a_idx, π_tail, t)
    for k in eachindex(σ)
        I.r[k] = if k == a_idx
            max(W*π_tail*(1 - σ[a_idx]) + I.r[k], 0.0)
        else
            max(-W*σ[a_idx] + I.r[k], 0.0)
        end
    end
end

function regret_update!(sol::OSCFRSolver{:vanilla}, I, σ, W, a_idx, π_tail, t)
    for k in eachindex(σ)
        I.r[k] += if k == a_idx
            W*π_tail*(1 - σ[a_idx])
        else
            -W*σ[a_idx]
        end
    end
end

function strat_update!(sol::OSCFRSolver{:discount}, I, σ, π_ni, s, t)
    I.s .+= (t^sol.γ)*(π_ni / s) .* σ
end

function strat_update!(sol::OSCFRSolver{:plus}, I, σ, π_ni, s, t)
    I.s .+= (π_ni / s) .* σ
end

function strat_update!(sol::OSCFRSolver{:vanilla}, I, σ, π_ni, s, t)
    I.s .+= (π_ni / s) .* σ
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
    finalize_strategies!(solver)
end
