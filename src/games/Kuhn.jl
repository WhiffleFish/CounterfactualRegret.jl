using Random
using StaticArrays

const PASS = 0
const BET = 1
const KuhnInfoKey = Tuple{Int, Int, Vector{Int}} # [player, player_card, action_hist]

struct Hist
    cards::SVector{2,Int}
    action_hist::Vector{Int}
end

Base.:(==)(h1::Hist, h2::Hist) = h1.cards==h2.cards && h1.action_hist==h2.action_hist

Base.length(h::Hist) = length(h.action_hist)

struct Kuhn <: Game{Hist, KuhnInfoKey} end

# FIXME: lots of gc
HelloCFR.initialhist(::Kuhn) = Hist(SA[0,0], Int[])

function HelloCFR.isterminal(::Kuhn, h::Hist) # requires some sequence of actions
    h = h.action_hist
    L = length(h)
    if L > 1
        if h[1] == BET || h[2] == PASS || L > 2
            return true
        else
            return false
        end
    else
        return false
    end
end

function HelloCFR.u(::Kuhn, i::Int, h::Hist)
    as = h.action_hist
    cards = h.cards
    L = length(as)
    has_higher_card = cards[i] > cards[other_player(i)]
    if L ≥ 2
        if last(as) == PASS # +1 to player with highest card
            return has_higher_card ? 1 : -1
        else # +2 to player with highest card
            return has_higher_card ? 2 : -2
        end
    else
        return 0
    end
end

function HelloCFR.player(::Kuhn, h::Hist)
    if any(iszero, h.cards)
        return 0
    else
        return length(h)%2 + 1
    end
end

function HelloCFR.chance_action(::Kuhn, h::Hist) # FIXME This is horiffically inefficient
    return randperm(3)[1:2]
end

function HelloCFR.next_hist(::Kuhn, h, a::Vector{Int}) # TODO : remove Int[] gc (replace with NullVec)
    return Hist(
        @SVector [a[i] for i in 1:2]
        , Int[]
    )
end

# probably want to memoize or something
function HelloCFR.next_hist(::Kuhn, h::Hist, a::Int)
    return Hist(h.cards, [h.action_hist;a])
end

"""
Map history to key unique to all histories in one info set
"""
function HelloCFR.infokey(g::Kuhn, h::Hist)
    p = player(g,h)
    card = p > 0 ? h.cards[p] : 0
    return (p, card, h.action_hist) # [player, player_card, action_hist]
end

HelloCFR.actions(::Kuhn, h::Hist) = PASS:BET
