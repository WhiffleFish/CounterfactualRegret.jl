struct TossHist
    h::SVector{2,Int}
    flip::Symbol
end

struct TossInfoState
    p::Int
    flip::Symbol
end

struct CoinToss <: Game{TossHist,TossInfoState} end

function Base.length(h::TossHist)
    return if h.flip === :null
        0
    elseif iszero(first(h.h))
        1
    else
        2
    end
end

function CFR.actions(game::CoinToss, h::TossHist)
    return isone(player(game, h)) ? (1:2) : (1:3)
end

function CFR.next_hist(game::CoinToss, h::TossHist, a::Int)
    return TossHist(setindex(h.h, a, player(game,h)), h.flip)
end

function CFR.utility(::CoinToss, i::Int, h::TossHist)
    return if h.flip === :heads
        if h.h === SA[1,0]
            isone(i) ? 0.50 : -0.50
        elseif h.h === SA[2,1]
            isone(i) ? -1.0 : 1.0
        elseif h.h === SA[2,2]
            isone(i) ? 1.0 : -1.0
        elseif h.h === SA[2,3]
            isone(i) ? 1.0 : -1.0
        end
    else
        if h.h === SA[1,0]
            isone(i) ? -0.50 : 0.50
        elseif h.h === SA[2,1]
            isone(i) ? 1.0 : -1.0
        elseif h.h === SA[2,2]
            isone(i) ? 1.0 : -1.0
        elseif h.h === SA[2,3]
            isone(i) ? -1.0 : 1.0
        end
    end
end

function CFR.isterminal(::CoinToss, h::TossHist)
    return isone(first(h.h)) || !iszero(last(h.h))
end

function CFR.infokey(::CoinToss, h::TossHist)
    return if iszero(first(h.h)) # player 1 - knows flip outcome
        TossInfoState(1, h.flip)
    else # player 2 - no knowledge of flip outcome
        TossInfoState(2, :null)
    end
end

CFR.chance_actions(::CoinToss, ::TossHist) = (:heads, :tails)

CFR.initialhist(::CoinToss) = TossHist(@SVector(zeros(Int,2)), :null)

CFR.next_hist(::CoinToss, h::TossHist, a::Symbol) = TossHist(h.h, a)

CFR.player(::CoinToss, h) = length(h)
