abstract type Game{H,K} end


"""
    infokeytype(g::Game)

Returns information key type for game `g`
"""
infokeytype(::Game{H,K}) where {H,K} = K

"""
    histtype(g::Game)

Returns history type for game `g`
"""
histtype(::Game{H,K}) where {H,K} = H

"""
    initialhist(game::Game)

Return initial history with which to start the game
"""
function initialhist end


"""
    isterminal(game::Game, h)

Returns boolean - whether or not current history is terminal \n
i.e h ∈ Z
"""
function isterminal end

"""
    utility(game::Game, i::Int, h)

Returns utility of some history h for some player i
"""
function utility end


"""
    player(game::Game{H,K}, h::H)

Returns integer id corresponding to which player's turn it is at history h
0 - Chance Player
1 - Player 1
2 - Player 2
\n
If converting to IIE to Matrix Game need to implement:
    `player(game::Game{H,K}, k::K)`
"""
function player end


"""
    chance_action(game::Game, h)

Return randomly sampled action from chance player at a given history
"""
function chance_action end


"""
    chance_actions(game::Game, h)

Return all chance actions available for chance player at history h
"""
function chance_actions end

"""
    chance_policy(game::Game, h)

Return distribution over chance outcomes
"""
function chance_policy end

"""
"""
function randpdf end

"""
    next_hist(game::Game, h, a)

Given some history and action return the next history
`h′ = next_hist(game, h, a)`
"""
function next_hist end


"""
    infokey(game::Game, h)

Returns unique identifier corresponding to some information set \n
`infokey(game, h1) == infokey(game, h2)` ⟺ h1 and h2 belong to the same info set \n
(key must be immutable as it's being stored as a key in a dictionary)
"""
function infokey end


"""
    actions(game::Game, k)

Returns all actions available at some information state given by key `k` (See [`infokey`](@ref))
"""
function actions end

"""
    players(game)

Returns number of players in game (excluding chance player)
"""
function players end

"""
    observation(game, h, a, h′)

For tree building - information given to acting player in history `h`

"""
function observation end

"""
    vectorized_info(game::Game{H,K}, key::K) where {H,K}

For converting information state representation to vector.
Default behavior returns unmodified information state.
"""
function vectorized_info end

"""
    vectorized_hist(game::Game{H}, h::H) where H

For converting history representation to vector.
Default behavior returns unmodified history.
"""
function vectorized_hist end

vectorized_info(game::Game, I) = I
vectorized_hist(game::Game, h) = h

players(game::Game) = 2


#=
Ideally would dispatch on `actions(game::Game{H}, history::H) where H`, but it's not guaranteed
that history type is different from infokey type
=#
history_actions(game::Game, h) = actions(game, infokey(game, h))

chance_action(game::Game, h) = rand(chance_actions(game, h))

@inline other_player(i) = 3-i
