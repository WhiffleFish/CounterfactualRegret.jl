#=
Chance Sampling Counterfactual Regret Minimization
=#

struct CSCFRSolver{H,K,G,I} <: AbstractCFRSolver{H,K,G,I}
    explored::Vector{H}
    I::Dict{K, I}
    game::G
end

function CSCFRSolver(game::Game{H,K}; debug::Bool=false) where {H,K}
    if debug
        return CSCFRSolver(H[], Dict{K, DebugInfoState}(), game)
    else
        return CSCFRSolver(H[], Dict{K, InfoState}(), game)
    end
end

function CFR(solver::CSCFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return u(game, i, h)
    elseif player(game, h) === 0 # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return CFR(solver, h′, i, t, π_1, π_2)
    end
    I = infoset(solver, h)
    A = actions(game, h)

    v_σ = 0.0
    v_σ_Ia = zeros(Float64, length(A))

    for (k,a) in enumerate(A)
        h′ = next_hist(game, h, a)
        if player(game, h) === 1
            v_σ_Ia[k] = CFR(solver, h′, i, t, I.σ[k]*π_1, π_2)
        else
            v_σ_Ia[k] = CFR(solver, h′, i, t, π_1, I.σ[k]*π_2)
        end
        v_σ += I.σ[k]*v_σ_Ia[k]
    end

    if player(game, h) == i
        π_i = i == 1 ? π_1 : π_2
        π_ni = i == 1 ? π_2 : π_1
        for (k,a) in enumerate(A)
            I.r[k] += π_ni*(v_σ_Ia[k] - v_σ)
            I.s[k] += π_i*I.σ[k]
        end
    end

    return v_σ
end


"""
    `MonteCarloEvaluate(solver::AbstractCFRSolver, N::Int)`

Monte Carlo evaluation sampling chance player actions. \n
Returns tuple corresponding to utilities for both players.
"""
function MonteCarloEvaluate(solver::AbstractCFRSolver, N::Int)
    finalize_strategies!(solver)

    p1_eval = 0.0
    p2_eval = 0.0

    ih = initialhist(solver.game)
    for _ in 1:N
        p1_eval += MonteCarloEvaluate(solver, ih, 1, 0, 1.0, 1.0)
        p2_eval += MonteCarloEvaluate(solver, ih, 2, 0, 1.0, 1.0)
    end

    p1_eval /= N
    p2_eval /= N

    return (p1_eval, p2_eval)
end

function MonteCarloEvaluate(solver::AbstractCFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return u(game, i, h)
    elseif player(game, h) === 0 # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return MonteCarloEvaluate(solver, h′, i, t, π_1, π_2)
    end

    I = infoset(solver, h)
    A = actions(game, h)

    v_σ = 0.0

    for (k,a) in enumerate(A)
        v_σ_Ia = 0.0
        h′ = next_hist(game, h, a)
        if player(game, h) === 1
            v_σ_Ia = MonteCarloEvaluate(solver, h′, i, t, I.σ[k]*π_1, π_2)
        else
            v_σ_Ia = MonteCarloEvaluate(solver, h′, i, t, π_1, I.σ[k]*π_2)
        end
        v_σ += I.σ[k]*v_σ_Ia
    end

    return v_σ
end
