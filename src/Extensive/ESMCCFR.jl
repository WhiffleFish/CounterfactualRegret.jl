#=
External Sampling Counterfactual Regret Minimization
- "sample only the actions of the opponent and chance (those choices external to the player)"
=#
using Random

# try `Ref{Int}` for `a_idx` to keep immutable
mutable struct MCInfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    a_idx::Int
end

mutable struct DebugMCInfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    hist::Vector{Vector{Float64}}
    a_idx::Int
end

function MCInfoState(L::Int)
    return MCInfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L,L),
        0
    )
end

function DebugMCInfoState(L::Int)
    return DebugMCInfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L, L),
        Vector{Float64}[],
        0
    )
end

struct ESCFRSolver{K,G,I} <: AbstractCFRSolver{K,G,I}
    I::Dict{K, I}
    game::G
end

"""
Generate random action index from info state according to strategy σ
"""
function Random.rand(rng::AbstractRNG, I::AbstractInfoState)
    σ = I.σ
    t = rand(rng)
    i = 1
    cw = σ[1]
    while cw < t && i < length(σ)
        i += 1
        @inbounds cw += σ[i]
    end
    return i
end

Random.rand(I::AbstractInfoState) = rand(Random.GLOBAL_RNG, I)

function ESCFRSolver(game::Game{H,K}; debug::Bool=false) where {H,K}
    if debug
        return ESCFRSolver(Dict{K, DebugMCInfoState}(), game)
    else
        return ESCFRSolver(Dict{K, MCInfoState}(), game)
    end
end

# TODO: Validate regret update. Not entirely confident in code nor MCCFR paper eqn.
function CFR(solver::ESCFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return utility(game, i, h)
    elseif player(game, h) === 0 # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return CFR(solver, h′, i, t, π_1, π_2)
    end

    I = infoset(solver, h)
    A = actions(game, h)

    v_σ = 0.0

    if player(game, h) === i
        v_σ_Ia = zeros(Float64, length(A))
        π_i = i == 1 ? π_1 : π_2
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            if i === 1
                v_σ_Ia[k] = CFR(solver, h′, i, t, I.σ[k]*π_1, π_2)
            else
                v_σ_Ia[k] = CFR(solver, h′, i, t, π_1, I.σ[k]*π_2)
            end
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
        for (k,a) in enumerate(A)
            I.r[k] += (1 - I.σ[k])*(v_σ_Ia[k] - v_σ)
            I.s[k] += π_i*I.σ[k]
        end
    else
        a_idx = I.a_idx
        a_idx == 0 && (a_idx = rand(I))
        I.a_idx = a_idx
        a = A[a_idx]
        h′ = next_hist(game, h, a)
        v_σ = CFR(solver, h′, i, t, π_1, π_2)
    end

    return v_σ
end

function train!(solver::ESCFRSolver{K,G,INFO}, N::Int) where {K,G,INFO<:MCInfoState}
    ih = initialhist(solver.game)
    for t in 1:N
        for i in 1:2
            CFR(solver, ih, i, t, 1.0, 1.0)
        end
        for I in values(solver.I)
            regret_match!(I)
            I.a_idx = 0
        end
    end
end

function train!(solver::ESCFRSolver{K,G,INFO}, N::Int) where {K,G,INFO<:DebugMCInfoState}
    ih = initialhist(solver.game)
    for t in 1:N
        for i in 1:2
            CFR(solver, ih, i, t, 1.0, 1.0)
        end
        for I in values(solver.I)
            regret_match!(I)
            push!(I.hist, copy(I.s) ./ sum(I.s))
            I.a_idx = 0
        end
    end
end
