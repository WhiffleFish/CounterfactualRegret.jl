abstract type IIESolver end # Imperfect Information Extensive Game Solver
abstract type AbstractInfoState end
abstract type AbstractCFRSolver{K,G<:Game,I<:AbstractInfoState} <: IIESolver end

infokeytype(::AbstractCFRSolver{K}) where K = K

struct InfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    _tmp_σ::Vector{Float64}
end

function InfoState(L::Int)
    return InfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L, L),
        fill(1/L, L),
    )
end

struct DebugInfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    _tmp_σ::Vector{Float64}
    hist::Vector{Vector{Float64}}
end

function DebugInfoState(L::Int)
    return DebugInfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L, L),
        fill(1/L, L),
        Vector{Float64}[]
    )
end

struct CFRSolver{K,G,I} <: AbstractCFRSolver{K,G,I}
    I::Dict{K, I}
    game::G
end

"""
    `CFRSolver(game::Game{H,K}; debug::Bool=false)`

Instantiate vanilla CFR solver with some `game`.

If `debug=true`, record history of strategies over training period, allowing
for training history of individual information states to be plotted with
`Plots.plot(is::DebugInfoState)`

"""
function CFRSolver(game::Game{H,K}; debug::Bool=false) where {H,K}
    if debug
        return CFRSolver(Dict{K, DebugInfoState}(), game)
    else
        return CFRSolver(Dict{K, InfoState}(), game)
    end
end

const REG_CFRSOLVER{K,G} = AbstractCFRSolver{K,G,InfoState}
const DEBUG_CFRSOLVER{K,G} = AbstractCFRSolver{K,G,DebugInfoState}

function infoset(solver::AbstractCFRSolver{K,G,INFO}, h) where {K,G,INFO}
    game = solver.game
    k = infokey(game, h)
    I = get!(solver.I, k) do
        INFO(length(actions(game,h)))
    end
    return I
end

function regret_match!(σ::AbstractVector, r::AbstractVector)
    s = 0.0
    for (i,r_i) in enumerate(r)
        if r_i > 0
            s += r_i
            σ[i] = r_i
        else
            σ[i] = 0.0
        end
    end
    s > 0 ? (σ ./= s) : fill!(σ,1/length(σ))
end

regret_match!(I::AbstractInfoState) = regret_match!(I.σ, I.r)

function regret_match!(sol::AbstractCFRSolver)
    for I in values(sol.I)
        regret_match!(I)
    end
end

function CFR(solver::CFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return utility(game, i, h)
    elseif player(game, h) === 0 # chance player
        A = chance_actions(game, h)
        s = 0.0
        for a in A
            s += CFR(solver, next_hist(game, h, a), i, t, π_1, π_2)
        end
        return s / length(A)
    end

    I = infoset(solver, h)
    A = actions(game, h)

    v_σ = 0.0
    v_σ_Ia = I._tmp_σ

    for (k,a) in enumerate(A)
        h′ = next_hist(game, h, a)
        if player(game, h) === 1
            v_σ_Ia[k] = CFR(solver, h′, i, t, I.σ[k]*π_1, π_2)
        else
            v_σ_Ia[k] = CFR(solver, h′, i, t, π_1, I.σ[k]*π_2)
        end
        v_σ += I.σ[k]*v_σ_Ia[k]
    end

    if player(game, h) == i
        π_i = i == 1 ? π_1 : π_2
        π_ni = i == 1 ? π_2 : π_1
        for (k,a) in enumerate(A)
            I.r[k] += π_ni*(v_σ_Ia[k] - v_σ)
            I.s[k] += π_i*I.σ[k]
        end
    end

    return v_σ
end

function train!(solver::REG_CFRSOLVER, N::Int; show_progress::Bool=false, cb=()->())
    regret_match!(solver)
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t, 1.0, 1.0)
        end
        for I in values(solver.I)
            regret_match!(I)
        end
        cb()
        next!(prog)
    end
    finalize_strategies!(solver)
end

function train!(solver::DEBUG_CFRSOLVER, N::Int; show_progress::Bool=false, cb=()->())
    regret_match!(solver)
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t, 1.0, 1.0)
        end
        for I in values(solver.I)
            regret_match!(I)
            push!(I.hist, copy(I.s) ./ sum(I.s))
        end
        cb()
        next!(prog)
    end
    finalize_strategies!(solver)
end

function finalize_strategies!(solver::AbstractCFRSolver)
    for I in values(solver.I)
        I.σ .= I.s
        s = sum(I.σ)
        s > 0 ? I.σ ./= sum(I.σ) : fill!(I.σ, 1/length(I.σ))
    end
end

function strategy(sol::AbstractCFRSolver{K}, I::K) where K
    infostate = get(sol.I, I, nothing)
    if isnothing(infostate)
        L = length(first(values(sol.I)).σ)
        return fill(inv(L), L)
    else
        σ_I = infostate.s
        return σ_I ./ sum(σ_I)
    end
end

## extras


@recipe function f(I::AbstractInfoState)

    xlabel := "Training Steps"

    L = length(I.σ)
    labels = Matrix{String}(undef, 1, L)
    for i in eachindex(labels); labels[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 1
        ylabel := "Strategy"
        labels := labels
        reduce(hcat,I.hist)'
    end

end

function Base.print(io::IO, sol::AbstractCFRSolver)
    for (k,I) in sol.I
        σ = copy(I.s)
        σ ./= sum(σ)
        println(io, k,"\t",round.(σ, digits=3))
    end
end
