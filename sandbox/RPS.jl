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

initialhist(::RPS) = Int[]

isterminal(::RPS, h::RPSHist) = length(h) > 1

function u(game::RPS, i::Int, h::RPSHist)
    length(h) > 1 ? game.R[h[1], h[2]][i] : 0
end

player(::RPS, h::RPSHist) = length(h)+1

next_hist(::RPS, h, a) = [h;a]

infokey(::RPS, h) = length(h)

actions(::RPS, ::Any) = 1:3
