struct ObsHist
    hist::Vector{UInt64}
end

"""
- `id       ::  UInt`                       : index of node in tree.nodes
- `h        ::  H`                          : history returned by underlying game
- `obs_hist ::  NTuple{2, Vector{UInt64}}`  : action-observation history of each player
- `player   ::  Int`                        : player whose turn it is to play
- `terminal ::  Bool`                       : check if history is terminal
- `utility  ::  NTuple{2,Float64}`          : utility of history if history is terminal
- `children ::  Vector{UInt}`               : id's of chilren nodes ha ∀ a ∈ 𝒜(h)
- `infokey  ::  UInt`
"""
struct TreeHist{H}
    id          :: UInt64
    h           :: H
    obs_hist    :: NTuple{2, Vector{UInt64}} # (maybe don't need to store ALL observations)
    actions     :: UnitRange{UInt}
    player      :: Int
    terminal    :: Bool
    utility     :: NTuple{2,Float64} # assume 2 player game
    children    :: Vector{UInt} # See if we can reduce to UnitRange{UInt}
    infokey     :: UInt
end

struct GameTree{G<:Game, H} <: Game{TreeHist{H}, UInt}
    nodes::Vector{TreeHist{H}}
    infokey2idx::Dict{Vector{UInt}, UInt}
    idx2infokey::Vector{Vector{UInt}}
    game::G
end

Base.length(tree::GameTree) = length(tree.nodes)

function _init_tree(game::Game{H}) where H
    GameTree(TreeHist{H}[], Dict{Vector{UInt}, UInt}(), Vector{UInt}[], game)
end

"""
Constructs history node and adds to tree
----! does not add to children of preceding node !----
"""
function add_hist!(tree::GameTree{G,H}, h::H, obs_hist::NTuple{2,Vector{UInt}}) where {G,H}
    game = tree.game
    id = UInt(length(tree)) + 1
    p = player(game, h)
    terminal = isterminal(tree.game, h)
    u1 = terminal ? utility(game, 1, h) : 0.0
    u2 = terminal ? utility(game, 2, h) : 0.0
    A = iszero(p) ? chance_actions(game, h) : actions(game, h)
    act = UInt(1):UInt(length(A))


    # infokey
    tree_h = if iszero(p) # chance player
        TreeHist(id, h, obs_hist, act, p, terminal, (u1,u2), UInt[], UInt(0))
    else
        player_info = obs_hist[p]
        I = terminal ? UInt(0) : get!(tree.infokey2idx, player_info) do
            push!(tree.idx2infokey, player_info)
            UInt(length(tree.idx2infokey))
        end
        TreeHist(id, h, obs_hist, act, p, terminal, (u1,u2), UInt[], I)
    end

    push!(tree.nodes, tree_h)
    return tree_h
end

function GameTree(game::Game)
    tree = _init_tree(game)
    h = initialhist(game)
    obs_hist = ([UInt(1)], [UInt(2)])
    h0 = add_hist!(tree, h, obs_hist)
    _build_tree(tree, h0)
    return tree
end

function _build_tree(tree::GameTree, parent::TreeHist)
    game = tree.game
    isterminal(tree, parent) && return
    p = player(tree, parent)

    A = iszero(p) ? chance_actions(game, parent.h) : actions(game, parent.h)

    for (i,a) in enumerate(A)
        obs_hist = (copy(parent.obs_hist[1]), copy(parent.obs_hist[2]))
        h′ = next_hist(game, parent.h, a)
        o = observation(game, parent.h, a, h′)

        !iszero(p) && push!(obs_hist[p], UInt(i))
        for (i,o_i) in enumerate(o)
            i != p && push!(obs_hist[i], hash(o_i))
        end

        tree_h′ = add_hist!(tree, h′, obs_hist)
        push!(parent.children, tree_h′.id)
        _build_tree(tree, tree_h′)
    end
end


## CounterfactualRegret.jl glue

CFR.initialhist(g::GameTree) = first(g.nodes)

CFR.player(::GameTree, h::TreeHist) = h.player

CFR.chance_actions(::GameTree, h::TreeHist) = h.actions

CFR.actions(::GameTree, h::TreeHist) = h.actions

CFR.isterminal(::GameTree, h::TreeHist) = h.terminal

CFR.utility(::GameTree, i, h::TreeHist) = h.utility[i]

CFR.next_hist(g::GameTree, h::TreeHist, a::UInt) = g.nodes[h.children[a]]

CFR.infokey(::GameTree, h::TreeHist) = h.infokey
