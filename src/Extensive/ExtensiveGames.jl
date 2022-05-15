abstract type Game{H,K} end

infokeytype(::Game{H,K}) where {H,K} = K
histtype(::Game{H,K}) where {H,K} = H

"""
    `initialhist(game::Game)`

Return initial history with which to start the game
"""
function initialhist end


"""
    `isterminal(game::Game, h)`

Returns boolean - whether or not current history is terminal \n
i.e h ∈ Z
"""
function isterminal end

"""
    `utility(game::Game, i::Int, h)`

Returns utility of some history h for some player i
"""
function utility end


"""
    `player(game::Game{H,K}, h::H)`

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
    `chance_action(game::Game, h)`

Return randomly sampled action from chance player at a given history
"""
function chance_action end


"""
    chance_actions(game::Game, h)

Return all chance actions available for chance player at history h
"""
function chance_actions end


"""
    `next_hist(game::Game, h, a)`

Given some history and action return the next history
`h′ = next_hist(game, h, a)`
"""
function next_hist end


"""
    `infokey(game::Game, h)`

Returns unique identifier corresponding to some information set \n
`infokey(game, h1) == infokey(game, h2)` ⟺ h1 and h2 belong to the same info set \n
(key must be immutable as it's being stored as a key in a dictionary)
"""
function infokey end


"""
    `actions(game::Game, h)`

Returns all actions available at some history
"""
function actions end

"""
    `players(game)`

Returns number of players in game (excluding chance player)
"""
function players end

players(game::Game) = 2

@inline other_player(i) = 3-i
