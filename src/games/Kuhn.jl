const PASS = 0
const BET = 1
const KuhnInfoKey = Tuple{Int, Int, SVector{3,Int}} # [player, player_card, action_hist]

"""
- `cards`       : vector containing card representation for each player
- `action_hist` : vector containing history of actions
    - `-1` : null action i.e. no action has been taken here
    - `0`  : check/fold
    - `1`  : bet
"""
struct KuhnHist
    cards::SVector{2,Int}
    action_hist::SVector{3,Int}
end

#=
Convenience function for determining how far into the game we are.
e.g. an action history of [-1,-1,-1] implies no player has taken an action yet (length 0)
and an action history of [1,0,-1] implies that player 1 has betted (1) and player 2 has folded (0).
=#
function Base.length(h::KuhnHist)
    l = 0
    for a in h.action_hist
        a === -1 && break
        l += 1
    end
    return l
end

#=
Stored parameters are all possible dealt card suit combinations
J - 1
Q - 2
K - 3
=#
struct Kuhn <: Game{KuhnHist, KuhnInfoKey}
    cards::Vector{SVector{2,Int}}
    Kuhn() = new([SVector(i,j) for i in 1:3, j in 1:3 if i != j])
end

#=
Initial history that marks the start of the game.
No cards have been chosen yet: `hist.cards = SA[0,0]`
and no players have taken any actions yet: `hist.cards = SA[-1,-1,-1]`
=#
CFR.initialhist(::Kuhn) = KuhnHist(SA[0,0], SA[-1,-1,-1])

#=
Check if current history is terminal i.e h ∈ 𝒵
=#
function CFR.isterminal(::Kuhn, h::KuhnHist)
    L = length(h)
    h = h.action_hist
    if L > 1
        return h[1] == BET || h[2] == PASS || L > 2
    else
        return false
    end
end

#=
Utility of some terminal history i.e. uᵢ(h) where h ∈ 𝒵
=#
function CFR.utility(::Kuhn, i::Int, h::KuhnHist)
    as = h.action_hist
    cards = h.cards
    L = length(as)
    has_higher_card = cards[i] > cards[other_player(i)]
    if as == SA[PASS, PASS, -1]
        return has_higher_card ? 1. : -1.
    elseif as == SA[PASS, BET, PASS]
        return i==2 ? 1. : -1.
    elseif as == SA[PASS, BET, BET]
        return has_higher_card ? 2. : -2.
    elseif as == SA[BET, PASS, -1]
        return i==1 ? 1. : -1.
    elseif as == SA[BET, BET, -1]
        return has_higher_card ? 2. : -2.
    else
        return 0.
    end
end

#=
Player P(h) is the player who takes an action after history h
=#
function CFR.player(::Kuhn, h::KuhnHist)
    if any(iszero, h.cards)
        return 0
    else
        return length(h)%2 + 1
    end
end

#=
Non-chance player actions available at some history h
=#
CFR.actions(::Kuhn, h::KuhnHist) = PASS:BET

#=
Chance player actions available at some history h.
Chance player can choose from any of the available card permutations stored in `game.cards`.
=#
function CFR.chance_actions(game::Kuhn, h::KuhnHist)
    return game.cards
end

#=
Next history resulting from chance player action.
`h` here is always the initial history, as the chance player always has the first turn in Kuhn Poker.
The history here is modified by changing the dealt cards to the ones chosen by the chance player.
=#
function CFR.next_hist(::Kuhn, h, a::SVector{2,Int})
    return KuhnHist(a, h.action_hist)
end

#=
Next history resulting from non-chance player action.
For example, if the current action history is [0,-1,-1] (player 1 has checked)
and player 2 bets (action 1), then the next action history becomes [0,1,-1]
=#
function CFR.next_hist(::Kuhn, h::KuhnHist, a::Int)
    L = length(h)
    action_hist = setindex(h.action_hist, a, L+1)
    return KuhnHist(h.cards, action_hist)
end

#=
Information state representation.
At any history will only know their card, and the history of previous actions.
=#
function CFR.infokey(g::Kuhn, h::KuhnHist)
    p = player(g,h)
    card = p > 0 ? h.cards[p] : 0
    return (p, card, h.action_hist) # [player, player_card, action_hist]
end


## Extra

function CFR.vectorized_hist(::Kuhn, h::KuhnHist)
    (;cards, action_hist) = h
    c = convert(SVector{2,Float32}, cards)
    a = convert(SVector{3,Float32}, action_hist)
    SA[c..., a...]
end

function CFR.vectorized_info(::Kuhn, I::Tuple)
    p, pc, hist = I
    h = convert(SVector{3,Float32}, hist)
    SA[Float32(p), Float32(pc), h...]
end

function Base.print(io::IO, solver::CFR.AbstractCFRSolver{K,G}) where {K,G<:Kuhn}
    println(io)
    for (k,v) in solver.I
        h = k[3]
        Lp1 = findfirst(==(-1), h)
        h_str = rpad(join(h[1:Lp1-1]),3,"_")
        σ = copy(v.s)
        σ ./= sum(σ)
        σ = round.(σ, digits=3)
        println(io, "Player: $(k[1]) \t Card: $(k[2]) \t h: $(join(h_str)) \t σ: $σ")
    end
end
