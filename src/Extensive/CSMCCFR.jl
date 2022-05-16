#=
Chance Sampling Counterfactual Regret Minimization
=#

struct CSCFRSolver{K,G,I} <: AbstractCFRSolver{K,G,I}
    I::Dict{K, I}
    game::G
end


"""
    `CSCFRSolver(game::Game{H,K}; debug::Bool=false)`

Instantiate chance sampling CFR solver with some `game`.

If `debug=true`, record history of strategies over training period, allowing
for training history of individual information states to be plotted with
`Plots.plot(is::DebugInfoState)`

"""
function CSCFRSolver(game::Game{H,K}; debug::Bool=false) where {H,K}
    if debug
        return CSCFRSolver(Dict{K, DebugInfoState}(), game)
    else
        return CSCFRSolver(Dict{K, InfoState}(), game)
    end
end

function CFR(solver::CSCFRSolver, h, i, t, π_i=1.0, π_ni=1.0)
    game = solver.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(current_player) # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return CFR(solver, h′, i, t, π_i, π_ni)
    end
    I = infoset(solver, h)
    A = actions(game, h)

    v_σ = 0.0
    v_σ_Ia = I._tmp_σ

    if current_player == i
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(solver, h′, i, t, I.σ[k]*π_i, π_ni)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
        @. I.r += π_ni*(v_σ_Ia - v_σ)
        @. I.s += π_i*I.σ
    else
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(solver, h′, i, t, π_i, I.σ[k]*π_ni)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
    end

    return v_σ
end
