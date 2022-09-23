"""
    evaluate(solver::AbstractCFRSolver)

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
    A = actions(game, I)

    v_σ = 0.0

    σ = strategy(solver, I)

    for (k,a) in enumerate(A)
        v_σ += σ[k]*evaluate(solver, next_hist(game, h, a), i)
    end

    return v_σ
end


function approx_eval(sol, n, game::Game, p)
    s = 0.0
    h0 = initialhist(game)
    for i ∈ 1:n
        s += _approx_eval(sol, game, p, h0)
    end
    return s / n
end

function _approx_eval(sol, game::Game, p, h)
    game = sol.game
    if isterminal(game, h)
        return utility(game, p, h)
    elseif iszero(player(game, h))
        a = rand(chance_actions(game, h))
        return _approx_eval(sol, game, p, next_hist(game, h, a))
    else
        A = actions(game, h)
        I = infokey(game, h)
        σ = strategy(sol, I)
        a = A[weighted_sample(σ)]
        return _approx_eval(sol, game, p, next_hist(game, h, a))
    end
end
