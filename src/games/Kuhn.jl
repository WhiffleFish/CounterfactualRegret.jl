using StaticArrays

const PASS = 0
const BET = 1
const KuhnInfoKey = Tuple{Int, Int, SVector{3,Int}} # [player, player_card, action_hist]

struct Hist
    cards::SVector{2,Int}
    action_hist::SVector{3,Int}
end

function Base.length(h::Hist)
    l = 0
    for a in h.action_hist
        a === -1 && break
        l += 1
    end
    return l
end

struct Kuhn <: Game{Hist, KuhnInfoKey}
    cards::Vector{SVector{2,Int}}
end

Kuhn() = Kuhn([SVector(i,j) for i in 1:3, j in 1:3 if i != j])

CounterfactualRegret.initialhist(::Kuhn) = Hist(SA[0,0], SA[-1,-1,-1])

function CounterfactualRegret.isterminal(::Kuhn, h::Hist) # requires some sequence of actions
    L = length(h)
    h = h.action_hist
    if L > 1
        return h[1] == BET || h[2] == PASS || L > 2
    else
        return false
    end
end

function CounterfactualRegret.utility(::Kuhn, i::Int, h::Hist)
    as = h.action_hist
    cards = h.cards
    L = length(as)
    has_higher_card = cards[i] > cards[other_player(i)]
    if as == SA[PASS, PASS, -1]
        return has_higher_card ? 1 : -1
    elseif as == SA[PASS, BET, PASS]
        return i==2 ? 1 : -1
    elseif as == SA[PASS, BET, BET]
        return has_higher_card ? 2 : -2
    elseif as == SA[BET, PASS, -1]
        return i==1 ? 1 : -1
    elseif as == SA[BET, BET, -1]
        return has_higher_card ? 2 : -2
    else
        return 0
    end
end

function CounterfactualRegret.player(::Kuhn, h::Hist)
    if any(iszero, h.cards)
        return 0
    else
        return length(h)%2 + 1
    end
end

CounterfactualRegret.player(::Kuhn, k::KuhnInfoKey) = first(k)

function CounterfactualRegret.chance_actions(game::Kuhn, h::Hist)
    return game.cards
end

function CounterfactualRegret.chance_action(game::Kuhn, h::Hist)
    return rand(game.cards)
end

function CounterfactualRegret.next_hist(::Kuhn, h, a::SVector{2,Int})
    return Hist(a, h.action_hist)
end

function CounterfactualRegret.next_hist(::Kuhn, h::Hist, a::Int)
    L = length(h)
    action_hist = setindex(h.action_hist, a, L+1)
    return Hist(h.cards, action_hist)
end


function CounterfactualRegret.infokey(g::Kuhn, h::Hist)
    p = player(g,h)
    card = p > 0 ? h.cards[p] : 0
    return (p, card, h.action_hist) # [player, player_card, action_hist]
end

CounterfactualRegret.actions(::Kuhn, h::Hist) = PASS:BET


## Extra

function Base.print(io::IO, solver::AbstractCFRSolver{K,G}) where {K,G<:Kuhn}
    println(io)
    for (k,v) in solver.I
        h = k[3]
        h_str = rpad(join(h),3,"_")
        σ = copy(v.s)
        σ ./= sum(σ)
        σ = round.(σ, digits=3)
        println(io, "Player: $(k[1]) \t Card: $(k[2]) \t h: $(join(h_str)) \t σ: $σ")
    end
end
