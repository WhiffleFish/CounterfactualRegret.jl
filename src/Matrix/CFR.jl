using Plots
import Plots.plot
using LaTeXStrings
using ProgressMeter
using PushVectors
include("TerminalCache.jl")

const SimpleIIHist = AbstractVector{Int}
const SimpleIIInfoState = Vector{Vector{Int}}

struct NullVec <: AbstractVector{Int} end
Base.size(::NullVec) = (0,)
Base.length(::NullVec) = 0

"""
Simple Imperfect Information Game
- Formulation of a matrix game as in imperfect information extensive form game
- Solved with CFR
- Takes reward matrix as input

    `SimpleIIGame(R::Matrix{NTuple{2,T}})`

## Example
```
RPS = SimpleIIGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])
```
"""
struct SimpleIIGame{T}
    R::Matrix{NTuple{2,T}}
    terminals::Matrix{Vector{Int}}
    _terminal_cache::TerminalCache
    _util_cache::PushVector{Int, Vector{Int}}
end

function SimpleInfoState(g::SimpleIIGame, i::Int)
    if i === 1
        return [Int[]]
    else
        return [Int[i] for i in 1:size(g.R,1)]
    end
end

function SimpleIIGame(R::Matrix{NTuple{2,T}}) where T
    s = size(R)
    terminals = [[i,j] for i in 1:s[1], j in 1:s[2]]
    return SimpleIIGame(R,terminals, TerminalCache(terminals), PushVector{Int}(2))
end

"""
Simple Imperfect Information Game Player

Instantiate with `SimpleIIPlayer(game, id[, initial_strategy])`
Default to uniform strategy

## Example
```
init_strategy = [0.1,0.3,0.6]
player1 = SimpleIIPlayer(game, 1, init_strategy)
```
"""
struct SimpleIIPlayer{T}
    id::Int
    game::SimpleIIGame{T}
    strategy::Vector{Float64}
    hist::Vector{Vector{Float64}}
    regret_avg::Vector{Float64}
end

player(g::SimpleIIGame, id::Int) = SimpleIIPlayer(g,id)
player(g::SimpleIIGame, id::Int, s::Vector{Float64}) = SimpleIIPlayer(g, id, s)

function SimpleIIPlayer(game::SimpleIIGame, id::Int)
    n_actions = size(game.R, id)
    strategy = fill(1/n_actions, n_actions)
    SimpleIIPlayer(
        id,
        game,
        strategy,
        [copy(strategy)],
        zeros(n_actions),
    )
end

function SimpleIIPlayer(game::SimpleIIGame, id::Int, strategy::Vector{Float64})
    n_actions = size(game.R, id)
    @assert size(game.R, id) == length(strategy)
    SimpleIIPlayer(
        id,
        game,
        copy(strategy),
        [copy(strategy)],
        zeros(n_actions),
    )
end

function clear!(p::SimpleIIPlayer)
    resize!(p.hist, 1)
    p.hist[1] .= p.strategy
    p.regret_avg .= 0.0
end

function terminals(game::SimpleIIGame, h::AbstractVector{Int})
    return game._terminal_cache[h]
end

player(::SimpleIIGame, h::AbstractVector{Int}) = length(h) < 1 ? 1 : 2
player(h) = length(h) < 1 ? 1 : 2


path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h′::AbstractVector{Int}) = path_prob(σ,i,NullVec(), h′)
path_prob(σ::NTuple{2,Vector{Float64}}, h′::AbstractVector{Int}) = path_prob(σ,NullVec(), h′)

function path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h::AbstractVector{Int}, h′::AbstractVector{Int})
    if i < 0
        return neg_path_prob(σ, -i, h, h′)
    else
        return path_prob(σ[i], i, h, h′)
    end
end

function neg_path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h::AbstractVector{Int}, h′::AbstractVector{Int})
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = @view h′[1:end-1]
        player_turn = player(h′)
        prob = (player_turn != i) ? σ[player_turn][act] : 1.0
        return prob*neg_path_prob(σ, i, h, h′)
    end
end

function path_prob(σ_i::Vector{Float64}, i::Int, h::AbstractVector{Int}, h′::AbstractVector{Int})
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = @view h′[1:end-1]
        prob = (player(h′) == i) ? σ_i[act] : 1.0
        return prob*path_prob(σ_i, i, h, h′)
    end
end

function path_prob(σ::NTuple{2,Vector{Float64}}, h::AbstractVector{Int}, h′::AbstractVector{Int})
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = @view h′[1:end-1]
        prob = σ[player(h′)][act]
        return prob*path_prob(σ, h, h′)
    end
end

function path_prob(σ::NTuple{2,Vector{Float64}}, I::SimpleIIInfoState, i::Int)
    s = 0.0
    for h in I
        s += path_prob(σ, i, h)
    end
    return s
end

function u(game::SimpleIIGame, i::Int, h′::AbstractVector{Int})
    game.R[h′[1], h′[2]][i]
end

function u(game::SimpleIIGame, i::Int, I::SimpleIIInfoState, σ::NTuple{2,Vector{Float64}})
    num = 0.0
    den = 0.0
    for h in I
        pi_I = path_prob(σ, -i, h)
        den += pi_I
        for h′ in terminals(game,h)
            num += pi_I*path_prob(σ,h,h′)*u(game,i,h′)
        end
    end
    return num/den
end

function u(game::SimpleIIGame, i::Int, I::SimpleIIInfoState, a::Int, σ::NTuple{2,Vector{Float64}})
    num = 0.0
    den = 0.0
    for hk in I
        h = append!(game._util_cache,  hk)
        push!(h, a)
        pi_I = path_prob(σ, -i, h)
        den += pi_I
        for h′ in terminals(game,h)
            num += pi_I*path_prob(σ,h,h′)*u(game,i,h′)
        end
        empty!(h)
    end
    return num/den
end

function sub_regret(game::SimpleIIGame,i::Int,I::SimpleIIInfoState,σ::NTuple{2, Vector{Float64}},a::Int)
    path_prob(σ, I, -i)*(u(game,i,I,a,σ) - u(game,i, I, σ))
end

function update_strategy!(game::SimpleIIGame, I::SimpleIIInfoState, p1::SimpleIIPlayer, p2::SimpleIIPlayer; pushp2::Bool=true)
    σ = p1.strategy
    ra = p1.regret_avg
    T = length(p1.hist)
    norm_sum = 0.0
    for a in 1:length(σ)
        sr = sub_regret(game,1,I,(last(p1.hist),last(p2.hist)),a)
        ra[a] += (sr-ra[a])/T
        if ra[a] > 0.0
            norm_sum += ra[a]
            σ[a] = ra[a]
        else
            σ[a] = 0.0
        end
    end
    norm_sum === 0.0 ? fill!(σ,1/length(σ)) : σ ./= norm_sum

    σ1′ = copy(σ)
    push!(p1.hist, σ1′)
    if pushp2
        σ2′ = copy(p2.strategy)
        push!(p2.hist, σ2′)
    end
    return σ
end

function update_strategies!(game::SimpleIIGame, Is::NTuple{2,SimpleIIInfoState}, p1::SimpleIIPlayer, p2::SimpleIIPlayer)
    σ1 = p1.strategy
    ra1 = p1.regret_avg
    T1 = length(p1.hist)
    norm_sum = 0.0
    for a in 1:length(σ1)
        sr = sub_regret(game,1,Is[1],(last(p1.hist),last(p2.hist)),a)
        ra1[a] += (sr-ra1[a])/T1
        if ra1[a] > 0.0
            norm_sum += ra1[a]
            σ1[a] = ra1[a]
        else
            σ1[a] = 0.0
        end
    end

    norm_sum === 0.0 ? fill!(σ1,1/length(σ1)) : σ1 ./= norm_sum

    σ2 = p2.strategy
    ra2 = p2.regret_avg
    T2 = length(p2.hist)
    norm_sum = 0.0
    for a in 1:length(σ2)
        sr = sub_regret(game,2,Is[2],(last(p1.hist),last(p2.hist)),a)
        ra2[a] += (sr-ra2[a])/T2
        if ra2[a] > 0.0
            norm_sum += ra2[a]
            σ2[a] = ra2[a]
        else
            σ2[a] = 0.0
        end
    end
    norm_sum === 0.0 ? fill!(σ2,1/length(σ2)) : σ2 ./= norm_sum

    push!(p1.hist, copy(σ1))
    push!(p2.hist, copy(σ2))
    return σ1, σ2
end

function train_both!(p1::SimpleIIPlayer, p2::SimpleIIPlayer, N::Int; progress::Bool=false)
    game = p1.game
    I1 = SimpleInfoState(game, 1)
    I2 = SimpleInfoState(game, 2)
    L1 = length(p1.hist)
    L2 = length(p2.hist)

    @showprogress enabled=!progress for i in 1:N
        update_strategies!(game, (I1,I2), p1, p2)
    end
    finalize_strategy!(p1)
    finalize_strategy!(p2)
    return p1, p2
end

function train_one!(p1::SimpleIIPlayer, p2::SimpleIIPlayer, N::Int; progress::Bool=false)
    I = SimpleInfoState(p1.game, 1)
    @showprogress enabled=!progress for i in 1:N
        update_strategy!(p1.game, I, p1, p2)
    end
    finalize_strategy!(p1)
    return p1
end

function cumulative_strategies(p::SimpleIIPlayer)
    mat = Matrix{Float64}(undef, length(p.hist), length(p.strategy))
    σ = zeros(Float64, length(p.strategy))

    for (i,σ_i) in enumerate(p.hist)
        σ = σ + (σ_i - σ)/i
        mat[i,:] .= σ
    end
    return mat
end

function avg_strat(p::SimpleIIPlayer)
    return sum(p.hist)/length(p.hist)
end

function finalize_strategy!(p::SimpleIIPlayer) # `sum` causes gc
    σ = p.strategy .= 0.0
    for σ_i in p.hist
        σ .+= σ_i
    end
    σ ./= sum(σ)
end

function evaluate(p1::SimpleIIPlayer, p2::SimpleIIPlayer)
    # strategies assumed already finalized
    game = p1.game
    σ1 = p1.strategy
    σ2 = p2.strategy
    R = game.R
    s1,s2 = size(R)
    p1_eval = 0.0
    p2_eval = 0.0
    for i in 1:s1, j in 1:s2
        prob = σ1[i]*σ2[j]
        p1_eval += prob*R[i,j][1]
        p2_eval += prob*R[i,j][2]
    end
    return p1_eval, p2_eval
end

function Plots.plot(p1::SimpleIIPlayer, p2::SimpleIIPlayer; kwargs...)
    L = length(p1.strategy)
    labels = Matrix{String}(undef, 1, L)
    for i in eachindex(labels); labels[i] = L"a_{%$(i)}"; end

    plt1 = Plots.plot(cumulative_strategies(p1), labels=labels; kwargs...)

    plt2 = Plots.plot(cumulative_strategies(p2), labels=""; kwargs...)

    title!(plt1, "Player 1")
    ylabel!(plt1, "Strategy Action Proportion")
    title!(plt2, "Player 2")
    plot(plt1, plt2, layout= @layout [a b])
    xlabel!("Training Steps")
end

function Plots.plot(p::SimpleIIPlayer; kwargs...)
    L = length(p.strategy)
    labels = Matrix{String}(undef, 1, L)
    for i in eachindex(labels); labels[i] = L"a_{%$(i)}"; end

    plt = Plots.plot(cumulative_strategies(p), labels=labels; kwargs...)

    title!(plt, "Player 1")
    ylabel!(plt, "Strategy Action Proportion")
    xlabel!(plt, "Training Steps")
end
