#=
Chance Sampling Counterfactual Regret Minimization
=#

abstract type Game{H,K} end

function initialhist end

function isterminal end

function u end

function player end

function chance_action end

function next_hist end

function infokey end

function actions end

struct InfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
end

struct DebugInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    hist::Vector{Vector{Float64}}
end

function InfoState(L::Int)
    return InfoState(
        fill(1/L, L),
        zeros(L),
        zeros(Float64,L)
    )
end

struct Trainer{H, K, G}
    explored::Vector{H}
    I::Dict{K, InfoState} # [player, player_card, action_hist]
    game::G
end

function Trainer(game::Game{H,K}) where {H,K}
    return Trainer(H[], Dict{K, InfoState}(), game)
end
@inline other_player(i) = 3-i

function infoset(trainer, h)
    game = trainer.game
    k = infokey(game, h)
    if h ∈ trainer.explored # if h stored, return corresponding infoset pointer
        return trainer.I[k]
    else
        push!(trainer.explored, h)
        if haskey(trainer.I, k)
            return trainer.I[k]
        else
            I = InfoState(length(actions(game,h)))
            trainer.I[k] = I
            return I
        end
    end
end

function regret_match!(I)
    s = 0.0
    σ = I.σ
    for (i,r_i) in enumerate(I.r)
        if r_i > 0
            s += r_i
            σ[i] = r_i
        else
            σ[i] = 0.0
        end
    end

    s > 0 ? (σ ./= s) : fill!(σ,1/length(σ))
end

# NOTE: remove dependency on t?
function CFR(trainer::Trainer, h, i, t, π_1, π_2)
    game = trainer.game
    if isterminal(game, h)
        return u(game, i, h)
    elseif player(game, h) === 0 # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return CFR(trainer, h′, i, t, π_1, π_2)
    end
    I = infoset(trainer, h)
    # change to `actions(game, h)` to remove dependency on BOTH this and `actions(game,I)`
    A = actions(game, h)

    v_σ = 0.0
    v_σ_Ia = zeros(Float64, length(A))

    for (k,a) in enumerate(A)
        h′ = next_hist(game, h,a)
        if player(game, h) === 1
            v_σ_Ia[k] = CFR(trainer, h′, i, t, I.σ[k]*π_1, π_2)
        else
            v_σ_Ia[k] = CFR(trainer, h′, i, t, π_1, I.σ[k]*π_2)
        end
        v_σ += I.σ[k]*v_σ_Ia[k]
    end

    if player(game, h) === i
        π_i = i === 1 ? π_1 : π_2
        π_ni = i === 1 ? π_2 : π_1
        for (k,a) in enumerate(A)
            I.r[k] += π_ni*(v_σ_Ia[k] - v_σ)
            I.s[k] += π_i*I.σ[k]
        end
    end

    return v_σ
end

function train!(trainer::Trainer, N::Int)
    for _ in 1:N
        for i in 1:2
            CFR(trainer, initialhist(trainer.game), i, 0.0, 1.0, 1.0)
        end
        for I in values(trainer.I)
            regret_match!(I)
        end
    end
end
