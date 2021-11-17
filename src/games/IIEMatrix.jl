const MAT_INFO_KEY = Int
const MAT_HIST = Vector{Int}

struct IIEMatrixGame{T} <: Game{MAT_HIST, MAT_INFO_KEY}
    R::Matrix{Tuple{T,T}}
end

IIEMatrixGame(g::MatrixGame) = IIEMatrixGame(g.R)

IIEMatrixGame() = IIEMatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

CounterfactualRegret.initialhist(::IIEMatrixGame) = Int[]

CounterfactualRegret.isterminal(::IIEMatrixGame, h::MAT_HIST) = length(h) > 1

function CounterfactualRegret.utility(game::IIEMatrixGame, i::Int, h::MAT_HIST)
    length(h) > 1 ? game.R[h[1], h[2]][i] : 0
end

CounterfactualRegret.player(::IIEMatrixGame, h::MAT_HIST) = length(h)+1

CounterfactualRegret.player(::IIEMatrixGame, k::MAT_INFO_KEY) = k+1

CounterfactualRegret.next_hist(::IIEMatrixGame, h, a) = [h;a]

CounterfactualRegret.infokey(::IIEMatrixGame, h) = length(h)

function CounterfactualRegret.actions(game::IIEMatrixGame, h::MAT_HIST)
    length(h) == 0 ? (1:size(game.R,1)) : (1:size(game.R,2))
end


## extras


import Base.print

function Base.print(solver::AbstractCFRSolver{H,K,G}) where {H,K,G<:IIEMatrixGame}
    println("\n")
    for (k,v) in solver.I
        σ = copy(v.s)
        σ ./= sum(σ)
        σ = round.(σ, digits=3)
        println("Player: $(k) \t σ: $σ")
    end
end

function cumulative_strategies(hist::Vector{Vector{Float64}})
    Lσ = length(hist[1])
    mat = Matrix{Float64}(undef, length(hist), Lσ)
    σ = zeros(Float64, Lσ)

    for (i,σ_i) in enumerate(hist)
        σ = σ + (σ_i - σ)/i
        mat[i,:] .= σ
    end
    return mat
end

@recipe function f(sol::AbstractCFRSolver{H,K,G}) where {H,K,G <: IIEMatrixGame}
    layout --> 2
    link := :both
    framestyle := [:axes :axes]

    xlabel := "Training Steps"

    L1 = length(sol.I[0].σ)
    labels1 = Matrix{String}(undef, 1, L1)
    for i in eachindex(labels1); labels1[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 1
        ylabel := "Strategy"
        title := "Player 1"
        labels := labels1
        cumulative_strategies(sol.I[0])
    end

    L2 = length(sol.I[1].σ)
    labels2 = Matrix{String}(undef, 1, L2)
    for i in eachindex(labels2); labels2[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 2
        title := "Player 2"
        labels := labels2
        cumulative_strategies(sol.I[1])
    end
end
