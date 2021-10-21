const RPSInfoKey = Int
const RPSHist = Vector{Int}

struct RPS <: Game{RPSHist, RPSInfoKey}
    R::Matrix{Tuple{Int,Int}}
end

RPS() = RPS([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

HelloCFR.initialhist(::RPS) = Int[]

HelloCFR.isterminal(::RPS, h::RPSHist) = length(h) > 1

function HelloCFR.u(game::RPS, i::Int, h::RPSHist)
    length(h) > 1 ? game.R[h[1], h[2]][i] : 0
end

HelloCFR.player(::RPS, h::RPSHist) = length(h)+1

HelloCFR.next_hist(::RPS, h, a) = [h;a]

HelloCFR.infokey(::RPS, h) = length(h)

HelloCFR.actions(::RPS, ::Any) = 1:3
