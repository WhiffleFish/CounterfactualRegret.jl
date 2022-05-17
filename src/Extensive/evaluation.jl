"""
    `evaluate(solver::AbstractCFRSolver)`

Evaluate full tree traversed by CFR solver. \n
Returns tuple corresponding to utilities for both players.
"""
function evaluate(sol::AbstractCFRSolver)
    return Tuple(evaluate(sol, p) for p in 1:players(sol.game))
end

function evaluate(sol::AbstractCFRSolver, p::Int)
    return evaluate(sol, initialhist(sol.game), p)
end

function evaluate(solver::AbstractCFRSolver, h, i)
    game = solver.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(current_player) # chance player
        A = chance_actions(game, h)
        s = 0.0
        for a in A
            s += evaluate(solver, next_hist(game, h, a), i)
        end
        return s / length(A)
    end

    I = infokey(game, h)
    A = actions(game, h)

    v_σ = 0.0

    σ = strategy(solver, I)

    for (k,a) in enumerate(A)
        v_σ += σ[k]*evaluate(solver, next_hist(game, h, a), i)
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
        return utility(game, i, h)
    elseif iszero(player(game, h)) # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return MonteCarloEvaluate(solver, h′, i, t, π_1, π_2)
    end

    I = infokey(game, h)
    A = actions(game, h)

    v_σ = 0.0
    σ = strategy(solver, I)
    for (k,a) in enumerate(A)
        v_σ_Ia = 0.0
        h′ = next_hist(game, h, a)
        if player(game, h) === 1
            v_σ_Ia = MonteCarloEvaluate(solver, h′, i, t, σ[k]*π_1, π_2)
        else
            v_σ_Ia = MonteCarloEvaluate(solver, h′, i, t, π_1, σ[k]*π_2)
        end
        v_σ += σ[k]*v_σ_Ia
    end

    return v_σ
end
