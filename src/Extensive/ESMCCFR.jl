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
    _tmp_σ::Vector{Float64}
    a_idx::Int
end

function MCInfoState(L::Int)
    return MCInfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L,L),
        fill(1/L,L),
        0
    )
end

mutable struct DebugMCInfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    _tmp_σ::Vector{Float64}
    hist::Vector{Vector{Float64}}
    a_idx::Int
end

function DebugMCInfoState(L::Int)
    return DebugMCInfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L, L),
        fill(1/L, L),
        Vector{Float64}[],
        0
    )
end

struct ESCFRSolver{K,G,I} <: AbstractCFRSolver{K,G,I}
    I::Dict{K, I}
    game::G
end

function weighted_sample(rng::AbstractRNG, w::AbstractVector)
    t = rand(rng)
    i = 1
    cw = first(w)
    while cw < t && i < length(w)
        i += 1
        @inbounds cw += w[i]
    end
    return i
end

weighted_sample(w::AbstractVector) = weighted_sample(Random.GLOBAL_RNG, w)

Random.rand(I::AbstractInfoState) = weighted_sample(I.σ)


"""
    `ESCFRSolver(game::Game{H,K}; debug::Bool=false)`

Instantiate external sampling CFR solver with some `game`.

If `debug=true`, record history of strategies over training period, allowing
for training history of individual information states to be plotted with
`Plots.plot(is::DebugInfoState)`

"""
function ESCFRSolver(game::Game{H,K}; debug::Bool=false) where {H,K}
    if debug
        return ESCFRSolver(Dict{K, DebugMCInfoState}(), game)
    else
        return ESCFRSolver(Dict{K, MCInfoState}(), game)
    end
end

function regret_match!(sol::ESCFRSolver)
    for I in values(sol.I)
        regret_match!(I)
        I.a_idx = 0
    end
end

function CFR(solver::ESCFRSolver, h, i, t)
    game = solver.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(current_player) # chance player
        a = chance_action(game, h)
        h′ = next_hist(game,h,a)
        return CFR(solver, h′, i, t)
    end

    I = infoset(solver, h)
    A = actions(game, h)

    v_σ = 0.0

    if current_player == i
        v_σ_Ia = I._tmp_σ
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(solver, h′, i, t)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end

        @. I.r += (1 - I.σ)*(v_σ_Ia - v_σ)
        @. I.s += I.σ
    else
        a_idx = I.a_idx
        iszero(a_idx) && (a_idx = rand(I))
        I.a_idx = a_idx
        a = A[a_idx]
        h′ = next_hist(game, h, a)
        v_σ = CFR(solver, h′, i, t)
    end

    return v_σ
end

function train!(solver::ESCFRSolver{K,G,INFO}, N::Int; show_progress::Bool=false, cb=()->()) where {K,G,INFO<:MCInfoState}
    regret_match!(solver)
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t)
        end
        regret_match!(solver)
        cb()
        next!(prog)
    end
    finalize_strategies!(solver)
end

function train!(solver::ESCFRSolver{K,G,INFO}, N::Int; show_progress::Bool=false, cb=()->()) where {K,G,INFO<:DebugMCInfoState}
    regret_match!(solver)
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t)
        end
        for I in values(solver.I)
            regret_match!(I)
            push!(I.hist, copy(I.s) ./ sum(I.s))
            I.a_idx = 0
        end
        cb()
        next!(prog)
    end
    finalize_strategies!(solver)
end
