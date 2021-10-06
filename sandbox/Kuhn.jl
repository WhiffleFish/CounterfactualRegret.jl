using Random
using Combinatorics
const PASS = 0
const BET = 1

#=
- π_i : Player i's probability of reaching h
- What is action space of chance player?
=#

struct KuhnHistory end
struct KuhnInfoSet end

struct KuhnState
    player::Int
    cards::Vector{Int}
    actions::Vector{Int}
end

other_player(i) = 3 - i

# Is this markov? Can we do this? MAKE IT MARKOV
function next_state(s::KuhnState, a)
    return KuhnState(
        otherplayer(s.player),
        s.cards,
        [s.actions;a]
    )
end

# chance player
function next_state(s::KuhnState, a::Vector{Int})
    return KuhnState(1,a,Int[])
end

struct Kuhn
    histories::Dict{KuhnInfoSet, KuhnHistory}
    infosets::Dict{KuhnHistory, KuhnInfoSet}
    cards::Vector{Int}
    chance_actions::Vector{Vector{Int}}
end

function Kuhn()
    return Kuhn([1,1], [p[1:2] for p in permutations([1,2,3])])
end

struct Player{I}
    id::Int
    regret::Dict{I,Vector{Float64}}
    strategy::Dict{I,Vector{Float64}}
end

mutable struct KuhnNode
    infoset::String
    regret_sum::Vector{Float64}
    strategy::Vector{Float64}
    strategy_sum::Vector{Float64}
end

"""
Player 0 is chance
"""
function player(::Kuhn, h)
    l = length(h)
    if l === 0
        return 0
    else
        return 2 - l%2
    end
end

player(::Kuhn, s::KuhnState) = s.player

function chance_action(::Kuhn, h)
    return [1,2,3][randperm(3)]
end

function u(game::Kuhn, i::Int, h)
    if length(h) > 2 ## NOTE: Length check probably wrong
        terminal_pass = h[end] == PASS
        double_bet = h[end-2:end] == [BET,BET]
        is_player_card_higher = game.cards[i] > game.cards[other_player(i)]

        if terminal_pass
            if h == [PASS,PASS]
                return is_player_card_higher ? 1 : -1
            else
                return 1
            end
        elseif double_bet
            return is_player_card_higher ? 2 : -2
        else
            return 0
        end
    else
        return 0
    end
end

function isterminal(game::Kuhn, h)
    if length(h) > 3
        return true
    elseif length(h) == 3
        return h[end] == PASS || view(h,2:end) == [BET,BET]
    else
        return false
    end
end

function histories(game::Kuhn, I::KuhnInfoSet)
    return game.histories[I]
end

# TODO NOTE HACK FIXME
# How do we describe an info set other than a collection of histories???
function infoset(game::Kuhn, h::KuhnHistory)
    if haskey(game.infosets[h])
        return game.infosets[h]
    else

    end
end

function infoset(game::Kuhn, h) #wrong, assumes 1 history maps to 1 info set and vice versa
    if haskey(game.infosets, h)
        return game.infosets[h]
    else
        infoset = KuhnInfoSet()
        game.infosets[h] = infoset
        return infoset
    end
end

function CFR(h, i, t, π_1, π_2)
    if isterminal(game, h)
        return u(game, i, h)
    elseif player(h) === 0 # chance player
        a = chance_action(game, h) # sample chance
        return CFR([h;a], i, t, π_1, π_2)
    end
    I = infoset(h)
    A = actions(I)
    v_σ = 0.0
    v_σ_Ia = zeros(Float64, length(A))

    for (i,a) in enumerate(A)
        if player(h) === 1
            v_σ_Ia[i] = CFR([h;a], i, t, σ_t(I,a)*π_1, π_2)
        else
            v_σ_Ia[i] = CFR([h;a], i, t, π_1, σ_t(I,a)*π_2)
        end
        v_σ += σ_t(I,a)*v_σ_Ia[i]
    end

    if player(h) == i
        for (i,a) in enumerate(A)
            r_I[i] += ???
        end
        regret_match(σ)
    end
end
