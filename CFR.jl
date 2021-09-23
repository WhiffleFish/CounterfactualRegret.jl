using Plots
using ProgressMeter

const SimpleIOHist = Vector{Int}
const InfoState = Vector{SimpleIOHist}

struct SimpleIOGame{T}
    R::Matrix{NTuple{2,T}}
    terminals::Matrix{Vector{Int}}
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
    return SimpleIOGame(R,terminals)
end

struct SimpleIOPlayer{T}
    id::Int
    game::SimpleIOGame{T}
    strategy::Vector{Float64}
    hist::Vector{Vector{Float64}}
end

function SimpleIOPlayer(game::SimpleIOGame, id::Int)
    n_actions = size(game.R, id)
    SimpleIOPlayer(
        id,
        game,
        fill(1/n_actions, n_actions),
        [deepcopy(strategy)],
    )
end

function SimpleIOPlayer(game::SimpleIOGame, id::Int, strategy::Vector{Float64})
    n_actions = size(game.R, id)
    SimpleIOPlayer(
        id,
        game,
        strategy,
        [deepcopy(strategy)],
    )
end

function clear!(p::SimpleIOPlayer)
    resize!(p.hist, 1)
    p.hist[1] .= p.strategy
end

function terminals(game::SimpleIOGame, h)
    if length(h) == 0
        return game.terminals
    elseif length(h) == 1
        return game.terminals[h[1],:]
    else
        return [h]
    end
end

player(::SimpleIOGame, h) = length(h) < 1 ? 1 : 2
player(h) = length(h) < 1 ? 1 : 2


path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h′::SimpleIOHist) = path_prob(σ,i,Int[], h′)
path_prob(σ::NTuple{2,Vector{Float64}}, h′::SimpleIOHist) = path_prob(σ,Int[], h′)

function path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h::SimpleIOHist, h′::SimpleIOHist)
    if i < 0
        return neg_path_prob(σ, -i, h, h′)
    else
        return path_prob(σ[i], i, h, h′)
    end
end

function neg_path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h::SimpleIOHist, h′::SimpleIOHist)
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = h′[1:end-1]
        player_turn = player(h′)
        prob = (player_turn != i) ? σ[player_turn][act] : 1.0
        return prob*neg_path_prob(σ, i, h, h′)
    end
end

function path_prob(σ_i::Vector{Float64}, i::Int, h::SimpleIOHist, h′::SimpleIOHist)
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = h′[1:end-1]
        prob = (player(h′) == i) ? σ_i[act] : 1.0
        return prob*path_prob(σ_i, i, h, h′)
    end
end

function path_prob(σ::NTuple{2,Vector{Float64}}, h::SimpleIOHist, h′::SimpleIOHist)
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = h′[1:end-1]
        prob = σ[player(h′)][act]
        return prob*path_prob(σ, h, h′)
    end
end

function path_prob(σ::NTuple{2,Vector{Float64}}, I::InfoState, i::Int)
    sum(path_prob(σ, i, h) for h in I)
end

function u(game::SimpleIOGame, i::Int, h′::SimpleIOHist)
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

function u(game::SimpleIOGame, i::Int, I::Vector{SimpleIOHist}, a::Int, σ::NTuple{2,Vector{Float64}})
    num = 0.0
    den = 0.0
    for h in I
        h = [h;a] # what if it isn't the player's turn?
        pi_I = path_prob(σ, -i, h)
        den += pi_I
        for h′ in terminals(game,h)
            num += pi_I*path_prob(σ,h,h′)*u(game,i,h′)
        end
    end
    return num/den
end

function sub_regret(game::SimpleIOGame,i::Int,I::Vector{SimpleIOHist},σ::NTuple{2, Vector{Float64}},a::Int)
    max(path_prob(σ, I, -i)*(u(game,i,I,a,σ) - u(game,i, I, σ)),0)
end

function update_strategy!(game::SimpleIOGame, I::InfoState, p1::SimpleIOPlayer, p2::SimpleIOPlayer; pushp2::Bool=true)
    σ = p1.strategy
    T = length(p1.hist)
    for a in 1:length(σ)
        RT = sum(sub_regret(game,1,I,σ,a) for σ in zip(p1.hist,p2.hist))/T
        RTp = max(RT,0)
        σ[a] = RTp
    end
    s = sum(σ)
    s == 0 ? fill!(σ,1/3) : σ ./= s
    push!(p1.hist, deepcopy(σ))
    pushp2 && push!(p2.hist, deepcopy(p2.strategy)) # consider changing
    return σ
end

function update_strategies!(game::SimpleIOGame, Is::NTuple{2,InfoState}, p1::SimpleIOPlayer, p2::SimpleIOPlayer)
    σ1 = p1.strategy
    T1 = length(p1.hist)
    for a in 1:length(σ1)
        RT = sum(sub_regret(game,1,Is[1],σ,a) for σ in zip(p1.hist,p2.hist))/T1
        RTp = max(RT,0)
        σ1[a] = RTp
    end
    s = sum(σ1)
    s == 0 ? fill!(σ1,1/3) : σ1 ./= s
    push!(p1.hist, deepcopy(σ1))

    σ2 = p2.strategy
    T2 = length(p2.hist)
    for a in 1:1:length(σ2)
        RT = sum(sub_regret(game,2,Is[2],σ,a) for σ in zip(p1.hist,p2.hist))/T2
        RTp = max(RT,0)
        σ2[a] = RTp
    end
    s = sum(σ2)
    s == 0 ? fill!(σ2,1/3) : σ2 ./= s
    push!(p2.hist, deepcopy(σ2))

    return σ1, σ2
end

function train_both!(p1::SimpleIOPlayer, p2::SimpleIOPlayer)
    I1 = SimpleInfoState(game, 1)
    I2 = SimpleInfoState(game, 2)
    @showprogress for i in 1:N
        update_strategies!(game, (I1,I2), p1, p2)
    end
    return p1, p2
end

function train_one!(p1, p2)
    I = SimpleInfoState(game, 1)
    @showprogress for i in 1:N
        update_strategy!(p1.game, I, p1, p2)
    end
    return p1
end

function plot_strats(p1::SimpleIOPlayer, p2::SimpleIOPlayer)
    plt1 = Plots.plot()
    for i in 1:length(p1.strategy)
        Plots.plot!(plt1, [p1.hist[j][i] for j in 1:length(p1.hist)], label=i)
    end
    plt2 = Plots.plot()
    for i in 1:3
        Plots.plot!(plt2, [p2.hist[j][i] for j in 1:length(p2.hist)], label="")
    end
    title!(plt1, "Player 1")
    ylabel!(plt1, "Strategy Action Proportion")
    title!(plt2, "Player 2")
    plot(plt1, plt2, layout= @layout [a b])
    xlabel!("Training Steps")
end
