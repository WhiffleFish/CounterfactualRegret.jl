const KuhnActionHist = StaticPushVector{3,Int}
const KuhnInfoKey = Tuple{Int, Int, KuhnActionHist} # [player, player_card, action_hist]
const PASS = 0
const BET = 1

"""
- `cards`       : vector containing card representation for each player
- `action_hist` : vector containing history of actions
    - `0`  : check/fold
    - `1`  : bet
"""
struct KuhnHist
    cards::SVector{2,Int}
    action_hist::KuhnActionHist
end

Base.length(h::KuhnHist) = length(h.action_hist)

#=
Stored parameters are all possible dealt card suit combinations
J - 1
Q - 2
K - 3
=#
"""
Kuhn Poker

"Kuhn poker is an extremely simplified form of poker developed by Harold W. Kuhn as a
simple model zero-sum two-player imperfect-information game, amenable to a complete
game-theoretic analysis. In Kuhn poker, the deck includes only three playing cards,
for example a King, Queen, and Jack. One card is dealt to each player, which may place
bets similarly to a standard poker. If both players bet or both players pass, the player
with the higher card wins, otherwise, the betting player wins."
- https://en.wikipedia.org/wiki/Kuhn_poker
"""
struct Kuhn <: Game{KuhnHist, KuhnInfoKey}
    cards::Vector{SVector{2,Int}}
    Kuhn() = new([SVector(i,j) for i in 1:3, j in 1:3 if i != j])
end

#=
Initial history that marks the start of the game.
No cards have been chosen yet: `hist.cards = SA[0,0]`
and no players have taken any actions yet: `hist.cards = SA[-1,-1,-1]`
=#
CFR.initialhist(::Kuhn) = KuhnHist(SA[0,0], KuhnActionHist())

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
    if as == SA[PASS, PASS]
        return has_higher_card ? 1. : -1.
    elseif as == SA[PASS, BET, PASS]
        return i==2 ? 1. : -1.
    elseif as == SA[PASS, BET, BET]
        return has_higher_card ? 2. : -2.
    elseif as == SA[BET, PASS]
        return i==1 ? 1. : -1.
    elseif as == SA[BET, BET]
        return has_higher_card ? 2. : -2.
    else
        return 0.
    end
end

#=
Player P(h) is the player who takes an action after history h
=#
function CFR.player(::Kuhn, h::KuhnHist)
    return any(iszero, h.cards) ? 0 : mod(length(h),2) + 1
end

#=
Non-chance player actions available at some info key `k`
=#
CFR.actions(::Kuhn, ::Any) = PASS:BET

#=
Chance player actions available at some history h.
Chance player can choose from any of the available card permutations stored in `game.cards`.
=#
CFR.chance_actions(game::Kuhn, h::KuhnHist) = game.cards

#=
Next history resulting from chance player action.
`h` here is always the initial history, as the chance player always has the first turn in Kuhn Poker.
The history here is modified by changing the dealt cards to the ones chosen by the chance player.
=#
CFR.next_hist(::Kuhn, h, a::SVector{2,Int}) = KuhnHist(a, h.action_hist)

#=
Next history resulting from non-chance player action.
For example, if the current action history is [0,-1,-1] (player 1 has checked)
and player 2 bets (action 1), then the next action history becomes [0,1,-1]
=#
CFR.next_hist(::Kuhn, h::KuhnHist, a::Int) = KuhnHist(h.cards, push(h.action_hist, a))

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
    a = convert(SVector{3,Float32}, action_hist.v)
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
