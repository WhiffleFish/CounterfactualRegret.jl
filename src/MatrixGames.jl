using StatsBase
using Plots
using LaTeXStrings
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
    @assert length(strategy) == n_actions
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
            game.R[a,a2][i] - u
            for a in 1:size(game.R, i)
            ]
    elseif i === 2
        return [
            game.R[a1,a][i] - u
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
        fill!(v, 1/length(v))
    else
        v ./= s
    end
end

function update_strategy!(p::MatrixPlayer)
    fill_normed_regret!(p.strategy, p.regret_sum)
    σ = p.strategy
    σ′ = Vector{Float64}(undef, length(σ))
    copyto!(σ′, σ)
    push!(p.hist, σ′)

    p.strat_sum .+= σ
end

function finalize_strategy!(p::MatrixPlayer)
    σ = p.strategy .= 0.0
    for σ_i in p.hist
        σ .+= σ_i
    end
    σ ./= sum(σ)
end

function evaluate(p1::MatrixPlayer, p2::MatrixPlayer)
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

function cumulative_strategies(p::MatrixPlayer)
    mat = Matrix{Float64}(undef, length(p.hist), length(p.strategy))
    σ = zeros(Float64, length(p.strategy))

    for (i,σ_i) in enumerate(p.hist)
        σ = σ + (σ_i - σ)/i
        mat[i,:] .= σ
    end
    return mat
end

function Plots.plot(p1::MatrixPlayer, p2::MatrixPlayer; kwargs...)
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

function Plots.plot(p::MatrixPlayer; kwargs...)
    L = length(p.strategy)
    labels = Matrix{String}(undef, 1, L)
    for i in eachindex(labels); labels[i] = L"a_{%$(i)}"; end

    plt = Plots.plot(cumulative_strategies(p), labels=labels; kwargs...)

    title!(plt, "Player 1")
    ylabel!(plt, "Strategy Action Proportion")
    xlabel!(plt, "Training Steps")
end
