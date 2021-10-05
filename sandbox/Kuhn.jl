const PASS = 0
const BET = 1

#=
π_i : Player i's probability of reaching h
=#

struct Kuhn end

struct Player{I}
    id::Int
    regret::Dict{I,Vector{Float64}}
    strategy::Dict{I,Vector{Float64}}
end

function player(::Kuhn, h)
    l = length(h)
    if l === 0
        return 0
    elseif l % 2 === 0
        return 2
    else
        return 1
    end
end

function u(game::Kuhn,u,h)

end

function CFR(h, i, t, π_1, π_2)
    if isterminal(h)
        return u(i,h)
    elseif ischance(h)
        a = chance(h) # sample chance
        return CFR([h;a], i, t, π_1, π_2)
    end
    I = infoset(h)
    A = actions(I)
    v_σ = 0
    v_σ_Ia = zeros(Float64, length(A))

    for (i,a) in enumerate(A)
        if player(h) == 1
            v_σ_Ia[i] = CFR([h;a], i, t, σ_t(I,a)*π_1, π_2)
        else
            v_σ_Ia[i] = CFR([h;a], i, t, π_1, σ_t(I,a)*π_2)
        end
        v_σ += σ_t(I,a)*v_σ_Ia[i]
    end

    if player(h) == i
        for (i,a) in enumerate(A)
            r_I[i] +=
        end
        regret_match(σ)
    end
end
