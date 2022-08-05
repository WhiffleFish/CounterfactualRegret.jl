"""
    `evaluate(solver::AbstractCFRSolver)`

Evaluate full tree traversed by CFR solver. \n
Returns tuple corresponding to game values for players given the strategies provided by the solver.
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
