using Plots
import Plots.plot
using ProgressMeter
using PushVectors
import Base.==
include("TerminalCache.jl")

const SimpleIOHist = AbstractVector{Int}
const InfoState = Vector{Vector{Int}}

struct NullVec <: AbstractVector{Int} end
Base.size(::NullVec) = (0,)
Base.length(::NullVec) = 0

struct SimpleIOGame{T}
    R::Matrix{NTuple{2,T}}
    terminals::Matrix{Vector{Int}}
    _terminal_cache::TerminalCache
    _util_cache::PushVector{Int, Vector{Int}}
end

function SimpleInfoState(g::SimpleIOGame, i::Int)
    if i === 1
        return [Int[]]
    else
        return [Int[i] for i in 1:size(g.R,1)]
    end
end

function SimpleIOGame(R::Matrix{NTuple{2,T}}) where T
    s = size(R)
    terminals = [[i,j] for i in 1:s[1], j in 1:s[2]]
    return SimpleIOGame(R,terminals, TerminalCache(terminals), PushVector{Int}(2))
end

struct SimpleIOPlayer{T}
    id::Int
    game::SimpleIOGame{T}
    strategy::Vector{Float64}
    hist::Vector{Vector{Float64}}
    regret_avg::Vector{Float64} # N inferrable by `length(hist)-1`
end

function SimpleIOPlayer(game::SimpleIOGame, id::Int)
    n_actions = size(game.R, id)
    strategy = fill(1/n_actions, n_actions)
    SimpleIOPlayer(
        id,
        game,
        strategy,
        [deepcopy(strategy)],
        zeros(n_actions),
    )
end

function SimpleIOPlayer(game::SimpleIOGame, id::Int, strategy::Vector{Float64})
    n_actions = size(game.R, id)
    @assert size(game.R, id) == length(strategy)
    SimpleIOPlayer(
        id,
        game,
        strategy,
        [deepcopy(strategy)],
        zeros(n_actions),
    )
end

function clear!(p::SimpleIOPlayer)
    resize!(p.hist, 1)
    p.hist[1] .= p.strategy
    p.regret_avg .= 0.0
end

function terminals(game::SimpleIOGame, h::AbstractVector{Int})
    return game._terminal_cache[h]
end

player(::SimpleIOGame, h::AbstractVector{Int}) = length(h) < 1 ? 1 : 2
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

function path_prob(σ::NTuple{2,Vector{Float64}}, I::InfoState, i::Int)
    s = 0.0
    for h in I
        s += path_prob(σ, i, h)
    end
    return s
end

function u(game::SimpleIOGame, i::Int, h′::AbstractVector{Int})
    game.R[h′[1], h′[2]][i]
end

function u(game::SimpleIOGame, i::Int, I::InfoState, σ::NTuple{2,Vector{Float64}})
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

function u(game::SimpleIOGame, i::Int, I::InfoState, a::Int, σ::NTuple{2,Vector{Float64}})
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

function sub_regret(game::SimpleIOGame,i::Int,I::InfoState,σ::NTuple{2, Vector{Float64}},a::Int)
    max(path_prob(σ, I, -i)*(u(game,i,I,a,σ) - u(game,i, I, σ)),0)
end

function update_strategy!(game::SimpleIOGame, I::InfoState, p1::SimpleIOPlayer, p2::SimpleIOPlayer; pushp2::Bool=true)
    σ = p1.strategy
    ra = p1.regret_avg
    T = length(p1.hist)
    for a in 1:length(σ)
        sr = sub_regret(game,1,I,(last(p1.hist),last(p2.hist)),a)
        ra[a] += (sr-ra[a])/T
    end
    copyto!(σ,ra)

    s = sum(σ)
    s == 0 ? fill!(σ,1/3) : σ ./= s
    push!(p1.hist, deepcopy(σ))
    pushp2 && push!(p2.hist, deepcopy(p2.strategy)) # consider changing
    return σ
end

function update_strategies!(game::SimpleIOGame, Is::NTuple{2,InfoState}, p1::SimpleIOPlayer, p2::SimpleIOPlayer)
    σ1 = p1.strategy
    ra1 = p1.regret_avg
    T1 = length(p1.hist)
    for a in 1:length(σ1)
        sr = sub_regret(game,1,Is[1],(last(p1.hist),last(p2.hist)),a)
        ra1[a] += (sr-ra1[a])/T1
    end
    copyto!(σ1, ra1)
    s = sum(σ1)
    s == 0 ? fill!(σ1,1/3) : σ1 ./= s

    σ2 = p2.strategy
    ra2 = p2.regret_avg
    T2 = length(p2.hist)
    for a in 1:length(σ2)
        sr = sub_regret(game,2,Is[2],(last(p1.hist),last(p2.hist)),a)
        ra2[a] += (sr-ra2[a])/T2
    end
    copyto!(σ2, ra2)
    s = sum(σ2)
    s == 0 ? fill!(σ2,1/3) : σ2 ./= s

    σ1′ = Vector{Float64}(undef, length(σ1))
    copyto!(σ1′, σ1)
    push!(p1.hist, σ1′)
    σ2′ = Vector{Float64}(undef, length(σ2))
    copyto!(σ2′, σ2)
    push!(p2.hist, σ2′)
    return σ1, σ2
end

function train_both!(p1::SimpleIOPlayer, p2::SimpleIOPlayer, N::Int; progress::Bool=false)
    game = p1.game
    I1 = SimpleInfoState(game, 1)
    I2 = SimpleInfoState(game, 2)
    L1 = length(p1.hist)
    L2 = length(p2.hist)

    @showprogress enabled=!progress for i in 1:N
        σ1, σ2 = update_strategies!(game, (I1,I2), p1, p2)
    end
    return p1, p2
end

function train_one!(p1::SimpleIOPlayer, p2::SimpleIOPlayer, N::Int; progress::Bool=false)
    I = SimpleInfoState(p1.game, 1)
    @showprogress enabled=!progress for i in 1:N
        update_strategy!(p1.game, I, p1, p2)
    end
    return p1
end

function Plots.plot(p1::SimpleIOPlayer, p2::SimpleIOPlayer)
    plt1 = Plots.plot()
    for i in 1:length(p1.strategy)
        Plots.plot!(plt1, [p1.hist[j][i] for j in 1:length(p1.hist)], label=i)
    end
    plt2 = Plots.plot()
    for i in 1:length(p2.strategy)
        Plots.plot!(plt2, [p2.hist[j][i] for j in 1:length(p2.hist)], label="")
    end
    title!(plt1, "Player 1")
    ylabel!(plt1, "Strategy Action Proportion")
    title!(plt2, "Player 2")
    plot(plt1, plt2, layout= @layout [a b])
    xlabel!("Training Steps")
end
