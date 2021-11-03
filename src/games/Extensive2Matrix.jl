
infodict(sol::HelloCFR.AbstractCFRSolver{H,K,G,I}) where {H,K,G,I} = sol.I::Dict{K,I}
strategy(I::HelloCFR.AbstractInfoState) = I.σ::Vector{Float64}

function pure_strategies(sol::CFRSolver, p::Int)
    game = sol.game
    K = infokeytype(sol.game)
    strategies = Vector{Pair{K,Vector{Float64}}}[]
    key_map = Tuple{K,Int}[]
    for (k,I) in infodict(sol)
        if player(game,k) === p
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

function Base.Matrix(game::Game)
    # find all info states
    solver = CFRSolver(game)
    train!(solver, 1)

    # enumerate all pure strategies
    p1_strats = pure_strategies(solver, 1)
    p2_strats = pure_strategies(solver, 2)

    # evaluate all pure strategies
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

    return mat
end
