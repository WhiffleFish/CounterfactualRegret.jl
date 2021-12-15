using Random
using RecipesBase
using LaTeXStrings
# restricted to 2-player game

"""
    `train_both!(player1, player2, N::Int)`

Find Nash equilibrium by training two players against each other

## Example
```
RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])
init_strategy = [0.1,0.3,0.6]
player1 = MatrixPlayer(RPS, 1, copy(init_strategy))
player2 = MatrixPlayer(RPS, 2, copy(init_strategy))
train_both!(player1, player2, 1000)
```
"""
function train_both! end

"""
    `train_one!(player1, player2, N::Int)`

Train only player 1 while keeping strategy of player 2 constant.
Yields strategy for player 1 that is maximally exploitative of player 2.

```
RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])
init_strategy = [0.1,0.3,0.6]
player1 = MatrixPlayer(RPS, 1, copy(init_strategy))
player2 = MatrixPlayer(RPS, 2, copy(init_strategy))
train_one!(player1, player2, 1000)
```
"""
function train_one! end

"""
Matrix Game
- Solved with regret matching
- Takes reward matrix as input

    `MatrixGame(R::Matrix{NTuple{2,T}})`

## Example
```
RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])
```
"""
struct MatrixGame{T}
    R::Matrix{NTuple{2,T}}
end

"""
Matrix Game Player

Instantiate with `MatrixPlayer(game, id[, initial_strategy])`
Default to uniform strategy

## Example
```
init_strategy = [0.1,0.3,0.6]
player1 = MatrixPlayer(game, 1, init_strategy)
```
"""
struct MatrixPlayer{T}
    id::Int
    game::MatrixGame{T}
    strategy::Vector{Float64}
    hist::Vector{Vector{Float64}}
    regret_sum::Vector{Float64}
    strat_sum::Vector{Float64}
end

player(g::MatrixGame, id::Int) = MatrixPlayer(g, id)
player(g::MatrixGame, id::Int, s::Vector{Float64}) = MatrixPlayer(g, id, s)

function MatrixPlayer(game::MatrixGame, id::Int)
    n_actions = size(game.R, id)
    strategy = fill(1/n_actions, n_actions)
    MatrixPlayer(
        id,
        game,
        strategy,
        [copy(strategy)],
        zeros(n_actions),
        copy(strategy)
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
        copy(strategy),
        [copy(strategy)],
        zeros(n_actions),
        copy(strategy)
    )
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

function gen_action(rng::AbstractRNG, p::MatrixPlayer)
    σ = p.strategy
    t = rand(rng)
    i = 1
    cw = σ[1]
    while cw < t && i < length(σ)
        i += 1
        @inbounds cw += σ[i]
    end
    return i
end

gen_action(p::MatrixPlayer) = gen_action(Random.GLOBAL_RNG, p)

function update_regret!(p::MatrixPlayer, a1::Int, a2::Int)
    p.regret_sum .+= regret(p.game, p.id, a1, a2)
end

function fill_normed_regret!(v::Vector{Float64}, r::Vector)
    s = 0.0
    for (i,k) in enumerate(r)
        if k > 0
            s += k
            v[i] = k
        else
            v[i] = 0.0
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
    p.strat_sum .+= σ
    s = copy(p.strat_sum)
    s ./= sum(s)
    push!(p.hist, s)
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

function train_both!(p1::MatrixPlayer, p2::MatrixPlayer, N::Int; show_progress::Bool=false)
    prog = Progress(N; enabled=show_progress)
    for i in 1:N
        a1, a2 = gen_action(p1), gen_action(p2)

        update_regret!(p1, a1, a2)
        update_regret!(p2, a1, a2)

        update_strategy!(p1)
        update_strategy!(p2)

        next!(prog)
    end
    finalize_strategy!(p1)
    finalize_strategy!(p2)
end

function train_one!(p1::MatrixPlayer, p2::MatrixPlayer, N::Int; show_progress::Bool=false)
    prog = Progress(N; enabled=show_progress)
    for i in 1:N
        a1, a2 = gen_action(p1), gen_action(p2)

        update_regret!(p1, a1, a2)

        update_strategy!(p1)
        next!(prog)
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

@recipe function f(p1::MatrixPlayer, p2::MatrixPlayer)
    layout --> 2
    link := :both
    framestyle := [:axes :axes]

    xlabel := "Training Steps"

    L1 = length(p1.strategy)
    labels1 = Matrix{String}(undef, 1, L1)
    for i in eachindex(labels1); labels1[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 1
        ylabel := "Strategy"
        title := "Player 1"
        labels := labels1
        reduce(hcat,p1.hist)'
    end

    L2 = length(p2.strategy)
    labels2 = Matrix{String}(undef, 1, L2)
    for i in eachindex(labels2); labels2[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 2
        title := "Player 2"
        labels := labels2
        reduce(hcat,p2.hist)'
    end
end

@recipe function f(p::MatrixPlayer)

    xlabel := "Training Steps"

    L = length(p.strategy)
    labels = Matrix{String}(undef, 1, L)
    for i in eachindex(labels); labels[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 1
        ylabel := "Strategy"
        title := "Player 1"
        labels := labels
        cumulative_strategies(p)
    end
end
