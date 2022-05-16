struct DCFRSolver{K,G,I} <: AbstractCFRSolver{K,G,I}
    I::Dict{K, I}
    game::G
    α::Float64
    β::Float64
    γ::Float64
end

"""
    `DCFRSolver(game::Game{H,K}; debug::Bool=false)`

- α - positive regret discount factor
- β - negative regret discount factor
- γ - strategy discount factor

Default to LCFR (linear)
    α = β = γ = 1.0

Instantiate discounted CFR solver with some `game`.

If `debug=true`, record history of strategies over training period, allowing
for training history of individual information states to be plotted with
`Plots.plot(is::DebugInfoState)`
"""
function DCFRSolver(
        game::Game{H,K};
        alpha::Float64 = 1.0,
        beta::Float64 = 1.0,
        gamma::Float64 = 1.0,
        debug::Bool=false) where {H,K}

    if debug
        return DCFRSolver(Dict{K, DebugInfoState}(), game, alpha, beta, gamma)
    else
        return DCFRSolver(Dict{K, InfoState}(), game, alpha, beta, gamma)
    end
end

function CFR(solver::DCFRSolver, h, i, t, π_i=1.0, π_ni=1.0)
    game = solver.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(player(game, h)) # chance player
        A = chance_actions(game, h)
        s = 0.0
        for a in A
            s += CFR(solver, next_hist(game, h, a), i, t, π_i, π_ni)
        end
        return s / length(A)
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
    else
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(solver, h′, i, t, π_i, I.σ[k]*π_ni)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
    end

    if current_player == i
        (;α, β, γ) = solver
        s_coeff = (t/(t+1))^γ

        for (k,a) in enumerate(A)
            r = π_ni*(v_σ_Ia[k] - v_σ)
            r_coeff = if r > 0.0
                (t^α)/(t^α + 1)
            else
                (t^β)/(t^β + 1)
            end

            I.r[k] += r
            I.r[k] *= r_coeff

            I.s[k] += π_i*I.σ[k]
            I.s[k] *= s_coeff
        end
    end

    return v_σ
end
