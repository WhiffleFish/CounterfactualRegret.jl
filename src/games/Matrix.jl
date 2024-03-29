const MAT_INFO_KEY = Int

struct MatHist{N}
    h::SVector{N,Int}
end

function Base.length(h::MatHist)
    l = 0
    for a in h.h
        iszero(a) && break
        l += 1
    end
    return l
end

"""
Matrix game of arbitrary dimensionality

Defaults to 2-player zero-sum rock-paper-scissors

- NOTE: N>2 player general-sum games have ill-defined convergence properties for counterfactual regret solvers
"""
struct MatrixGame{N,T} <: Game{MatHist{N}, MAT_INFO_KEY}
    R::Array{NTuple{N,T}, N}
end

MatrixGame() = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

CFR.initialhist(::MatrixGame{N}) where N = MatHist(@SVector zeros(Int,N))

CFR.isterminal(::MatrixGame, h::MatHist) = length(h) === length(h.h)

function CFR.utility(game::MatrixGame{N,T}, i::Int, h::MatHist) where {N,T}
    isterminal(game, h) ? game.R[h.h...][i] : zero(T)
end

CFR.player(::MatrixGame, h::MatHist) = length(h)+1

CFR.player(::MatrixGame, k::MAT_INFO_KEY) = k+1

CFR.players(::MatrixGame{N}) where N = N

function CFR.next_hist(::MatrixGame, h::MatHist, a)
    l = length(h)
    return MatHist(setindex(h.h, a, l+1))
end

CFR.infokey(::MatrixGame, h) = length(h)

function CFR.actions(game::MatrixGame, k)
    return 1:size(game.R, player(game,k))
end


## extras

CFR.vectorized_hist(::MatrixGame, h::MatHist) = h.h

CFR.vectorized_info(::MatrixGame, I::Int) = SA[Float32(I)]

function Base.print(io::IO, solver::CFR.AbstractCFRSolver{K,G}) where {K,G<:MatrixGame}
    println(io)
    for (k,v) in solver.I
        p = player(solver.game, k)
        σ = copy(v.s)
        σ ./= sum(σ)
        σ = round.(σ, digits=3)
        println(io, "Player: $(p) \t σ: $σ")
    end
end
