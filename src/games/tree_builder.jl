struct GameTree{G<:Game, H} <: Game{GameTreeHist{H}, Vector{UInt}}
    nodes::Vector{GameTreeHist{H}}
    infokey2idx::Dict{Vector{UInt}, UInt}
    idx2infokey::Vector{Vector{UInt}}
    game::G
end

"""
- `id::UInt`                            : index of node in tree.nodes
- `h::H`                                : history returned by underlying game
- `obs_hist::NTuple{2, Vector{UInt64}}` : action-observation history of each player
- `player::Int`                         : player whose turn it is to play
- `terminal::Bool`                      : check if history is terminal
- `utility::NTuple{2,Float64}`          : utility of history if history is terminal
"""
struct TreeHist{H}
    id          :: UInt64
    h           :: H
    obs_hist    :: NTuple{2, Vector{UInt64}} # (maybe don't need to store ALL observations)
    actions     :: UnitRange{UInt}
    player      :: Int
    terminal    :: Bool
    utility     :: NTuple{2,Float64} # assume 2 player game
    children    :: Vector{UInt}
    infokey     :: UInt
end

function build_tree(game::Game)
    tree = GameTree(game)
    h = initialhist(game)
    terminal = isterminal(game, h)
    u1 = terminal ? utility(game, h, 1) : 0.0
    u2 = terminal ? utility(game, h, 2) : 0.0
    A = actions(game, h)
    act = UInt(1):UInt(length(A))
    h0 = TreeHist(UInt(1), h, (UInt[1], UInt[2]), act, player(game, h), teriminal, (u1, u2), UInt[], UInt(1))
    push!(tree.nodes, h0)

    _build_tree(tree, h0)
end

function _build_tree(tree, h)
    game = tree.game
    p = h.player
    obs_hist = deepcopy(h.obs_hist)
    for (i,a) in enumerate(actions(game, h.h))
        id = UInt(length(tree.nodes))
        h′ = next_hist(game, h.h, a)
        o = observation(game, h.h, a, h′)
        !iszero(p) && push!(obs_hist[p], UInt(i))
        for (i,o_i) in enumerate(o)
            i != p && push!(obs_hist[i], hash(o_i))
        end
        terminal = isterminal(game, h′)
        u1 = terminal ? utility(game, h′, 1) : 0.0
        u2 = terminal ? utility(game, h′, 2) : 0.0
        p′ = player(game, h′)
        I = get!(tree.infokey2idx, obs_hist[p′]) do
            push!(tree.idx2infokey, obs_hist[p′])
            length(tree.idx2infokey)
        end
        tree_h′ = TreeHist(
            id,
            h′,
            obs_hist,
            UInt(1):UInt(length(actions(game, h′))),
            p′,
            terminal,
            (u1, u2),
            UInt[],
            I
        )
        push!(tree.nodes, tree_h′)
        push!(h.children, tree_h′)
        !terminal && _build_tree(tree, tree_h′)
    end
end


## CounterfactualRegret.jl glue
CFR.player(::GameTree, h::TreeHist) = h.player

CFR.chance_actions(::GameTree, h::TreeHist) = h.actions

CFR.actions(::GameTree, h::TreeHist) = h.actions

CFR.isterminal(::GameTree, h::TreeHist) = h.terminal

CFR.utility(::GameTree, h::TreeHist, i) = h.utility[i]

CFR.next_hist(g::GameTree, h::TreeHist, a::UInt) = g.children[(h.id, a)]

CFR.infokey(::GameTree, h::TreeHist) = h.infokey
