mutable struct MCTSNode
    q_a::Vector{Float64}
    n_a::Vector{Int}
    n::Int
    MCTSNode(l::Int) = new(zeros(Float64, l), zeros(Int, l), 0)
end

function zero!(node::MCTSNode)
    fill!(node.q_a, 0.)
    fill!(node.n_a, 0)
    node.n = 0
end

struct MaxUCB
    c::Float64
    MaxUCB(c=1.0) = new(c)
end

function best_action(crit::MaxUCB, node::MCTSNode)
    (;q_a, n_a) = node
    iszero(node.n) && return rand(eachindex(q_a, n_a))

    best_idx = 0
    best_val = -Inf
    logn = log(node.n)
    @inbounds for i ∈ eachindex(q_a, n_a)
        iszero(n_a[i]) && return i
        ucb = q_a[i] + crit.c*sqrt(logn / n_a[i])
        if ucb > best_val
            best_idx = i
            best_val = ucb
        end
    end
    return best_idx
end

struct PolyUCB
    c::Float64
    β::Float64
    PolyUCB(c=1.0, β=1/4) = new(c,β)
end

function best_action(crit::PolyUCB, node::MCTSNode)
    (;q_a, n_a) = node
    iszero(node.n) && return rand(eachindex(q_a, n_a))
    best_idx = 0
    best_val = -Inf
    βn = node.n^crit.β
    @inbounds for i ∈ eachindex(q_a, n_a)
        ucb = q_a[i] + crit.c*βn / sqrt(n_a[i])
        if ucb > best_val
            best_idx = i
            best_val = ucb
        end
    end
    return best_idx
end

struct MaxQ end

function best_action(crit::MaxQ, node::MCTSNode)
    (;q_a, n_a) = node
    best_idx = 0
    best_val = -Inf
    @inbounds for i ∈ eachindex(q_a, n_a)
        ucb = q_a[i]
        if ucb > best_val
            best_idx = i
            best_val = ucb
        end
    end
    return best_idx
end

struct ISMCTS{SOL, K, EV, CRIT}
    sol::SOL
    eval::EV
    d::Dict{K,MCTSNode}
    criterion::CRIT
    max_iter::Int
    max_time::Float64
    player::Int
end

function ISMCTS(
    sol::AbstractCFRSolver;
    eval = RolloutEvaluator(),
    criterion = PolyUCB(),
    max_iter = 1_000,
    max_time = Inf,
    player = 1)

    return ISMCTS(
        sol,
        eval,
        Dict{infokeytype(sol.game), MCTSNode}(),
        criterion,
        max_iter,
        max_time,
        player
    )
end

function zero!(mcts::ISMCTS)
    for node ∈ values(mcts.d)
        zero!(node)
    end
end

function Base.run(mcts::ISMCTS)
    t0 = time()
    zero!(mcts)
    h0 = initialhist(mcts.sol.game)
    iter = 0
    val = 0.
    while iter < mcts.max_iter && time() - t0 < mcts.max_time
        val += traverse(mcts, h0, mcts.player)
        iter += 1
    end
    return val / iter
end

function Base.get!(mcts::ISMCTS{S,K}, I::K) where {S,K}
    is_new = false
    return get!(mcts.d, I) do
        is_new = true
        MCTSNode(length(actions(mcts.sol.game, I)))
    end, is_new
end

struct RolloutEvaluator end

function (ro::RolloutEvaluator)(sol, h, i)
    game = sol.game
    p = player(game, h)
    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(p)
        h′ = next_hist(game, h, rand(chance_actions(game, h)))
        return ro(sol, h′, i)
    else
        I = infokey(game, h)
        A = actions(game, I)
        σ = strategy(sol, I)
        a_idx = weighted_sample(σ)
        h′ = next_hist(game, h, A[a_idx])
        return ro(sol, h′, i)
    end
end

function traverse(mcts::ISMCTS, h, i)
    game = mcts.sol.game
    p = player(game, h)
    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(p)
        h′ = next_hist(game, h, rand(chance_actions(game, h)))
        return traverse(mcts, h′, i)
    elseif p == i
        I = infokey(game, h)
        A = actions(game, I)
        node, is_new = get!(mcts, I)
        if is_new
            return mcts.eval(mcts.sol, h, i)
        else
            node.n += 1
            a_idx = best_action(mcts.criterion, node)
            h′ = next_hist(game, h, A[a_idx])
            û = traverse(mcts, h′, i)
            n = node.n_a[a_idx] += 1
            node.q_a[a_idx] += (û - node.q_a[a_idx]) / n
        end
    else
        I = infokey(game, h)
        A = actions(game, I)
        σ = strategy(mcts.sol, I)
        a_idx = weighted_sample(σ)
        h′ = next_hist(game, h, A[a_idx])
        return traverse(mcts, h′, i)
    end
end
