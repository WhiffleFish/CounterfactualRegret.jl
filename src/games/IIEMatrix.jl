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


## Extra


import Base.print

function Base.print(solver::AbstractCFRSolver{H,K,IIEMatrixGame{T},I}) where {H,K,T,I}
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

function Plots.plot(solver::AbstractCFRSolver{H,K,IIEMatrixGame{T},DebugInfoState};kwargs...) where {H,K,T}
    p1 = solver.I[0]
    p2 = solver.I[1]

    L = length(p1.σ)
    labels = Matrix{String}(undef, 1, L)
    for i in eachindex(labels); labels[i] = L"a_{%$(i)}"; end

    plt1 = Plots.plot(cumulative_strategies(p1.hist), labels=labels; kwargs...)

    plt2 = Plots.plot(cumulative_strategies(p2.hist), labels=""; kwargs...)

    title!(plt1, "Player 1")
    ylabel!(plt1, "Strategy Action Proportion")
    title!(plt2, "Player 2")
    plot(plt1, plt2, layout= @layout [a b])
    xlabel!("Training Steps")
end
