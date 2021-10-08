using Random

const PASS = 0
const BET = 1
const KuhnInfoKey = Tuple{Int, Int, Vector{Int}} # [player, player_card, action_hist]

struct Hist
    cards::Vector{Int}
    action_hist::Vector{Int}
end

Base.:(==)(h1::Hist, h2::Hist) = h1.cards==h2.cards && h1.action_hist==h2.action_hist

Base.length(h::Hist) = length(h.action_hist)

struct InfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
end

struct DebugInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    hist::Vector{Vector{Float64}}
end

struct Kuhn # move explored,I to some solver type
    explored::Vector{Hist}
    I::Dict{KuhnInfoKey, InfoState} # [player, player_card, action_hist]
end

Kuhn() = Kuhn(Vector{Int}[], Dict{KuhnInfoKey, InfoState}())

# FIXME: lots of gc
initialhist(::Kuhn) = Hist([0,0], Int[])

function InfoState(L::Int)
    return InfoState(
        fill(1/L, L),
        zeros(L),
        zeros(Float64,L)
    )
end

@inline other_player(i) = 3-i

function isterminal(h) # requires some sequence of actions
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

function u(i,h)
    as = h.action_hist
    cards = h.cards
    L = length(as)
    has_higher_card = cards[i] > cards[other_player(i)]
    if L > 2
        if last(as) == PASS # +1 to player with highest card
            has_higher_card ? 1 : -1
        else # +2 to player with highest card
            has_higher_card ? 2 : -2
        end
    elseif L > 1
        if last(as) == PASS # +1 to player with highest card
            has_higher_card ? 1 : -1
        else # +2 to player with highest card
            has_higher_card ? 2 : -2
        end
    else
        return 0
    end
end

function player(h)
    if any(iszero, h.cards)
        return 0
    else
        return length(h)%2 + 1
    end
end

function chance_action(h) # FIXME This is horiffically inefficient
    return randperm(3)[1:2]
end

function next_hist(h, a::Vector{Int}) # TODO : remove Int[] gc (replace with NullVec)
    return Hist(a,Int[])
end

# probably want to memoize or something
function next_hist(h, a::Int)
    return Hist(h.cards, [h.action_hist;a])
end

"""
Map history to key unique to all histories in one info set
"""
function infokey(h)
    p = player(h)
    card = p > 0 ? h.cards[p] : 0
    return (p, card, h.action_hist) # [player, player_card, action_hist]
end

function infoset(game, h)
    k = infokey(h)
    if h ∈ game.explored # if h stored, return corresponding infoset pointer
        return game.I[k]
    else
        push!(game.explored, h)
        if haskey(game.I, k)
            return game.I[k]
        else
            I = InfoState(length(actions(h)))
            game.I[k] = I
            return I
        end
    end
end

actions(I::InfoState) = PASS:BET
actions(h::Hist) = PASS:BET

function regret_match!(I)
    s = 0.0
    σ = I.σ
    for (i,r_i) in enumerate(I.r)
        if r_i > 0
            s += r_i
            σ[i] = r_i
        else
            σ[i] = 0.0
        end
    end

    s > 0 ? (σ ./= s) : fill!(σ,1/length(σ))
end
