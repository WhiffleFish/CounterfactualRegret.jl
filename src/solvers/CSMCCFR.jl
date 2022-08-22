struct CSCFRSolver{M,K,G} <: AbstractCFRSolver{K,G}
    method::M
    I::Dict{K, InfoState}
    game::G
end


"""
    CSCFRSolver(game; debug=false, method=Vanilla())

Instantiate chance sampling CFR solver with some `game`.

"""
function CSCFRSolver(
    game::Game{H,K};
    method      = Vanilla()) where {H,K}

    return CSCFRSolver(method, Dict{K, InfoState}(), game)
end

function CFR(solver::CSCFRSolver, h, i, t, π_i=1.0, π_ni=1.0)
    game = solver.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(current_player) # chance player
        A = chance_actions(game, h)
        a = rand(A)
        h′ = next_hist(game,h,a)
        return CFR(solver, h′, i, t, π_i, π_ni*inv(length(A)))
    end
    
    k = infokey(game, h)
    I = infoset(solver, k)
    A = actions(game, k)

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

function update!(sol::CSCFRSolver{Discount}, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    (;α, β, γ) = sol.method
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

function update!(sol::CSCFRSolver{Plus}, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    w = max(t-sol.method.d, 1)
    @. I.r = max(π_ni*(v_σ_Ia - v_σ) + I.r, 0.0)
    @. I.s += w*π_i*I.σ
    return nothing
end

function update!(sol::CSCFRSolver{Vanilla}, I, v_σ_Ia, v_σ, t, π_i, π_ni)
    @. I.r += π_ni*(v_σ_Ia - v_σ)
    @. I.s += π_i*I.σ
    return nothing
end
