using StatsBase
using Plots
import Plots.plot
# restricted to 2-player game
struct MatrixGame{T}
    R::Matrix{NTuple{2,T}}
end

struct MatrixPlayer{T}
    id::Int
    game::MatrixGame{T}
    strategy::Vector{Float64}
    hist::Vector{Vector{Float64}}
    regret_sum::Vector{Float64}
    strat_sum::Vector{Float64}
end

function MatrixPlayer(game::MatrixGame, id::Int)
    n_actions = size(game.R, id)
    MatrixPlayer(
        id,
        game,
        fill(1/n_actions, n_actions),
        [deepcopy(strategy)],
        zeros(n_actions),
        deepcopy(strategy)
    )
end

function clear!(p::MatrixPlayer)
    resize!(p.hist, 1)
    p.regret_sum .= 0.0
    p.strat_sum .= p.strategy
    p.hist[1] .= p.strategy
end

function MatrixPlayer(game::MatrixGame, id::Int, strategy::Vector{Float64})
    n_actions = size(game.R, id)
    MatrixPlayer(
        id,
        game,
        strategy,
        [deepcopy(strategy)],
        zeros(n_actions),
        deepcopy(strategy)
    )
end

function joint_hist(p1::MatrixPlayer, p2::MatrixPlayer)
    L = length(p1_hist)
    @assert length(p1_hist) == length(p2_hist)
    return [(p1.hist[i], p2.hist[i]) for i in 1:L]
end

function regret(game::MatrixGame, i::Int, a1::Int, a2::Int)
    u = game.R[a1,a2][i]
    if i === 1
        return [
            max(game.R[a,a2][i], 0)
            for a in 1:size(game.R, i)
            ]
    elseif i === 2
        return [
            max(game.R[a1,a][i], 0)
            for a in 1:size(game.R, i)
            ]
    else
        error("i must be 1 or 2")
    end
end

# Maybe start strategy as being weight vector?
gen_action(p::MatrixPlayer) = sample(weights(p.strategy))

function update_regret!(p::MatrixPlayer, a1::Int, a2::Int)
    p.regret_sum .+= regret(p.game, p.id, a1, a2)
end

function fill_normed_regret!(v::Vector{Float64}, r::Vector)
    s = 0.0
    for (i,k) in enumerate(r)
        if k > 0
            s += k
            v[i] = k
        end
    end
    if s == 0
        fill!(v, 1/3)
    else
        v ./= s
    end
end

function update_strategy!(p::MatrixPlayer)
    fill_normed_regret!(p.strategy, p.regret_sum)
    push!(p.hist, deepcopy(p.strategy))
    p.strat_sum .+= p.strategy
end

function finalize_strategy!(p::MatrixPlayer)
    p.strategy .= sum(p.hist)
    p.strategy ./= sum(p.strategy)
end

function train_both!(p1::MatrixPlayer, p2::MatrixPlayer, N::Int)
    for i in 1:N
        a1, a2 = gen_action(p1), gen_action(p2)

        update_regret!(p1, a1, a2)
        update_regret!(p2, a1, a2)

        update_strategy!(p1)
        update_strategy!(p2)
    end
    finalize_strategy!(p1)
    finalize_strategy!(p2)
end

function train_one!(p1::MatrixPlayer, p2::MatrixPlayer, N::Int)
    for i in 1:N
        a1, a2 = gen_action(p1), gen_action(p2)

        update_regret!(p1, a1, a2)

        update_strategy!(p1)
    end
    finalize_strategy!(p1)
end

function Plots.plot(p1::MatrixPlayer, p2::MatrixPlayer)
    plot1 = Plots.plot()
    for i in 1:length(p1.strategy)
        plot!(plot1, [p1.hist[j][i] for j in eachindex(p1.hist)], label=i)
    end
    plot2 = Plots.plot()
    for i in 1:length(p2.strategy)
        plot!(plot2, [p2.hist[j][i] for j in eachindex(p2.hist)], label="")
    end
    title!(plot1, "Player 1")
    ylabel!(plot1, "Strategy Action Proportion")
    title!(plot2, "Player 2")
    Plots.plot(plot1, plot2, layout= @layout [a b])
    xlabel!("Training Steps")
end

function plot(p1::MatrixPlayer)
    plot1 = Plots.plot()
    for i in 1:length(p1.strategy)
        plot!(plot1, [p1.hist[j][i] for j in eachindex(p1.hist)], label=i)
    end
    ylabel!(plot1, "Strategy Action Proportion")
    return plot1
end
