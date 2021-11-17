struct DCFRSolver{K,G,I} <: AbstractCFRSolver{K,G,I}
    I::Dict{K, I}
    game::G
    α::Float64
    β::Float64
    γ::Float64
end

"""
Default to LCFR
    α = β = γ = 1.0
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

function CFR(solver::DCFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return utility(game, i, h)
    elseif player(game, h) === 0 # chance player
        A = chance_actions(game, h)
        s = 0.0
        for a in A
            s += CFR(solver, next_hist(game, h, a), i, t, π_1, π_2)
        end
        return s / length(A)
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
        α, β, γ = solver.α, solver.β, solver.γ
        π_i = i == 1 ? π_1 : π_2
        π_ni = i == 1 ? π_2 : π_1
        for (k,a) in enumerate(A)
            r = π_ni*(v_σ_Ia[k] - v_σ)
            r_coeff = 0.0
            if r > 0
                r_coeff = (t^α)/(t^α + 1)
            else
                r_coeff = (t^β)/(t^β + 1)
            end

            s_coeff = (t/(t+1))^γ

            I.r[k] += r
            I.r[k] *= r_coeff

            I.s[k] += π_i*I.σ[k]
            I.s[k] *= s_coeff
        end
    end

    return v_σ
end
