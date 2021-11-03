using HelloCFR

game = HelloCFR.Kuhn()

mat = Matrix(game)

g = HelloCFR.IIEMatrixGame()
Matrix(g)


##

solver = CFRSolver(g)

train!(solver, 1)

solver.I

HelloCFR.pure_strategies(solver, 2)

infodict(sol::HelloCFR.AbstractCFRSolver{H,K,G,I}) where {H,K,G,I} = sol.I::Dict{K,I}
strategy(I::HelloCFR.AbstractInfoState) = I.σ::Vector{Float64}

# return [s1, s2, s3, ...]
# sk : [(k1 => σ1), (k2 => σ2), ...]
function populate_strategies(sol::CFRSolver, p::Int)
    K = infokeytype(sol.game)
    strategies = Vector{Pair{K,Vector{Float64}}}[]
    key_map = Tuple{K,Int}[]
    for (k,I) in infodict(solver)
        if k[1] === p
            push!(key_map, (k, length(I.σ)))
        end
    end
    add_next!(strategies, Pair{K,Vector{Float64}}[], key_map)

    return strategies
end

function add_next!(
        strategies::Vector{Vector{Pair{K,Vector{Float64}}}},
        cur_vec::Vector{Pair{K,Vector{Float64}}},
        key_map::Vector{Tuple{K,Int}} ) where K

    L = length(cur_vec)
    Lf = length(key_map)
    if L === Lf
        push!(strategies, copy(cur_vec))
    else
        key, a_length = key_map[L+1]
        for i in 1:a_length
            v = copy(cur_vec)
            σ = zeros(Float64, a_length)
            σ[i] = 1.0
            push!(v, (key => σ))
            add_next!(strategies, v, key_map)
        end
    end
end

p1_strats = populate_strategies(solver, 1)
p2_strats = populate_strategies(solver, 2)

mat = Matrix{NTuple{2,Float64}}(undef,length(p1_strats), length(p2_strats))

for (i,s1) in enumerate(p1_strats)
    for (j,s2) in enumerate(p2_strats)
        for (k1,σ1) in s1
            solver.I[k1].s .= σ1
        end
        for (k2,σ2) in s2
            solver.I[k2].s .= σ2
        end
        eval = FullEvaluate(solver)
        mat[i,j] = eval
    end
end

using BenchmarkTools

mat_game = SimpleIIGame(mat)
p1 = SimpleIIPlayer(mat_game,1)
p2 = SimpleIIPlayer(mat_game,2)
train_both!(p1,p2, 1_000)

@profiler train_both!(p1,p2,1_000)

using Plots
plot(p1)

g2 = HelloCFR.IIEMatrixGame(mat)
solver = CFRSolver(g2; debug=true)
train!(solver, 800_000)
plot(solver)
