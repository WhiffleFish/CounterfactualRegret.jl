#=
Chance Sampling Counterfactual Regret Minimization
=#

struct CSCFRSolver{method,K,G,I} <: AbstractCFRSolver{K,G,I}
    m::Val{method}
    I::Dict{K, I}
    game::G
    α::Float64
    β::Float64
    γ::Float64
end


"""
    `CSCFRSolver(game::Game{H,K}; debug::Bool=false)`

Instantiate chance sampling CFR solver with some `game`.

If `debug=true`, record history of strategies over training period, allowing
for training history of individual information states to be plotted with
`Plots.plot(is::DebugInfoState)`

"""
function CSCFRSolver(
    game::Game{H,K};
    method::Symbol  = :vanilla,
    alpha::Float64  = 1.0,
    beta::Float64   = 1.0,
    gamma::Float64  = 1.0,
    debug::Bool     = false) where {H,K}

    if method ∈ (:vanilla, :discount, :plus)
        if debug
            return CSCFRSolver(Val(method), Dict{K, DebugInfoState}(), game, alpha, beta, gamma)
        else
            return CSCFRSolver(Val(method), Dict{K, InfoState}(), game, alpha, beta, gamma)
        end
    else
        error("method $method ∉ (:vanilla, :discount, :plus)")
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
        update!(solver, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    else
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(solver, h′, i, t, π_i, I.σ[k]*π_ni)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
    end

    return v_σ
end

function update!(sol::CSCFRSolver{:discount}, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    (;α, β, γ) = sol
    s_coeff = (t/(t+1))^γ
    for k in eachindex(v_σ_Ia)
        r = π_ni*(v_σ_Ia[k] - v_σ)
        r_coeff = if r > 0.0
            ta = t^α
            ta/(ta + 1)
        else
            tb = t^β
            tb/(tb + 1)
        end

        I.r[k] += r
        I.r[k] *= r_coeff

        I.s[k] += π_i*I.σ[k]
        I.s[k] *= s_coeff
    end
    return nothing
end

function update!(sol::CSCFRSolver{:plus}, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    @. I.r = max(π_ni*(v_σ_Ia - v_σ) + I.r, 0.0)
    @. I.s += π_i*I.σ
    return nothing
end

function update!(sol::CSCFRSolver{:vanilla}, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    @. I.r += π_ni*(v_σ_Ia - v_σ)
    @. I.s += π_i*I.σ
    return nothing
end
