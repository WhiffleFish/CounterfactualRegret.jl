#=
Chance Sampling Counterfactual Regret Minimization
=#

# NOTE: remove dependency on t?
function CFR(game, h, i, t, π_1, π_2)
    if isterminal(h)
        return u(i, h)
    elseif player(h) === 0 # chance player
        a = chance_action(h)
        h′ = next_hist(h,a)
        return CFR(game, h′, i, t, π_1, π_2)
    end
    I = infoset(game, h)
    A = actions(I)

    v_σ = 0.0
    v_σ_Ia = zeros(Float64, length(A))

    for (k,a) in enumerate(A)
        h′ = next_hist(h,a)
        if player(h) === 1
            v_σ_Ia[k] = CFR(game, h′, i, t, I.σ[i]*π_1, π_2)
        else
            v_σ_Ia[k] = CFR(game, h′, i, t, π_1, I.σ[i]*π_2)
        end
        v_σ += I.σ[k]*v_σ_Ia[k]
    end

    if player(h) === i
        π_i = i === 1 ? π_1 : π_2
        π_ni = i === 1 ? π_2 : π_1
        for (k,a) in enumerate(A)
            I.r[k] += π_ni*(v_σ_Ia[k] - v_σ)
            I.s[k] += π_i*I.σ[k]
        end
        regret_match!(I)
    end

    return v_σ
end

function train!(game, N::Int)
    for _ in 1:N
        for i in 1:2
            CFR(game, initialhist(game), i, 0.0, 1.0, 1.0)
        end
    end
end
