const MAT_INFO_KEY = Int
const MAT_HIST = Vector{Int}

struct IIEMatrixGame <: Game{MAT_HIST, MAT_INFO_KEY}
    R::Matrix{Tuple{Int,Int}}
end

IIEMatrixGame() = IIEMatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

HelloCFR.initialhist(::IIEMatrixGame) = Int[]

HelloCFR.isterminal(::IIEMatrixGame, h::MAT_HIST) = length(h) > 1

function HelloCFR.u(game::IIEMatrixGame, i::Int, h::MAT_HIST)
    length(h) > 1 ? game.R[h[1], h[2]][i] : 0
end

HelloCFR.player(::IIEMatrixGame, h::MAT_HIST) = length(h)+1

HelloCFR.next_hist(::IIEMatrixGame, h, a) = [h;a]

HelloCFR.infokey(::IIEMatrixGame, h) = length(h)

function HelloCFR.actions(game::IIEMatrixGame, h::MAT_HIST)
    length(h) == 0 ? (1:size(game.R,1)) : (1:size(game.R,2))
end
