abstract type IIESolver end # Imperfect Information Extensive Game Solver
abstract type AbstractInfoState end
abstract type AbstractCFRSolver{K,G<:Game} <: IIESolver end

infokeytype(::AbstractCFRSolver{K}) where K = K

"""
    strategy(solver, k)

Return the current strategy of solver `sol` for information key `k`

If sufficiently trained ([`train!`](@ref)), this should be close to a Nash Equilibrium strategy.
"""
function strategy end

"""
    train!(sol::AbstractCFRSolver, n; cb=()->(), show_progress=false)

Train a CFR solver for `n` iterations with optional callbacks `cb` and optional progress bar `show_progress`
"""
function train! end


struct InfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    _tmp_σ::Vector{Float64}
end

function InfoState(L::Integer)
    return InfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L, L),
        fill(1/L, L),
    )
end

struct CFRSolver{M,K,G} <: AbstractCFRSolver{K,G}
    method::M
    I::Dict{K, InfoState}
    game::G
end

"""
    CFRSolver(game; method=Vanilla())

Instantiate vanilla CFR solver with some `game`.

"""
function CFRSolver(
    game::Game{H,K};
    method = Vanilla()) where {H,K}

    return CFRSolver(method, Dict{K, InfoState}(), game)
end

function infoset(solver::AbstractCFRSolver{K,G}, k::K) where {K,G}
    infotype = eltype(values(solver.I))
    return get!(solver.I, k) do
        infotype(length(actions(solver.game, k)))
    end
end

function regret_match!(σ::AbstractVector, r::AbstractVector)
    s = 0.0
    for (i,r_i) in enumerate(r)
        if r_i > 0.0
            s += r_i
            σ[i] = r_i
        else
            σ[i] = 0.0
        end
    end
    s > 0.0 ? (σ ./= s) : fill!(σ,1/length(σ))
end

regret_match!(I::AbstractInfoState) = regret_match!(I.σ, I.r)

function regret_match!(sol::AbstractCFRSolver)
    for I in values(sol.I)
        regret_match!(I)
    end
end

function CFR(sol::CFRSolver, h, i, t, π_i=1.0, π_ni=1.0)
    game = sol.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(current_player) # chance player
        σ_c = chance_policy(game, h)
        s = 0.0
        for (a,p) in POMDPTools.weighted_iterator(σ_c)
            s += p * CFR(sol, next_hist(game, h, a), i, t, π_i, π_ni*p)
        end
        return s
    end

    k = infokey(game, h)
    I = infoset(sol, k)
    A = actions(game, k)

    v_σ = 0.0
    v_σ_Ia = I._tmp_σ

    if current_player == i
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(sol, h′, i, t, I.σ[k]*π_i, π_ni)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
        regret_update!(sol, I, v_σ_Ia, v_σ, t, π_ni)
    else
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(sol, h′, i, t, π_i, I.σ[k]*π_ni)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end
        strat_update!(sol, I, π_i, t)
    end

    return v_σ
end

function regret_update!(sol::CFRSolver{Discount}, I, v_σ_Ia, v_σ, t, π_ni)
    (;α, β) = sol.method

    for k in eachindex(v_σ_Ia)
        r = π_ni*(v_σ_Ia[k] - v_σ)
        r_coeff = if r > 0.0
            ta = t^α
            ta/(ta + 1)
        else
            tb = t^β
            tb/(tb + 1)
        end

        I.r[k] += r
        I.r[k] *= r_coeff
    end
    return I.r
end

function strat_update!(sol::CFRSolver{Discount}, I, π_i, t)
    I.s .+= π_i*I.σ
    return I.s .*= (t/(t+1))^sol.method.γ
end

function regret_update!(sol::CFRSolver{Plus}, I, v_σ_Ia, v_σ, t, π_ni)
    return @. I.r = max(π_ni*(v_σ_Ia - v_σ) + I.r, 0.0)
end

function strat_update!(sol::CFRSolver{Plus}, I, π_i, t)
    w = max(t-sol.method.d, 1)
    return @. I.s += w*π_i*I.σ
end

function regret_update!(sol::CFRSolver{Vanilla}, I, v_σ_Ia, v_σ, t, π_ni)
    return @. I.r += π_ni*(v_σ_Ia - v_σ)
end

function strat_update!(sol::CFRSolver{Vanilla}, I, π_i, t)
    return @. I.s += π_i*I.σ
end

function train!(solver::AbstractCFRSolver, N::Int; show_progress::Bool=false, cb=()->())
    regret_match!(solver)
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t)
        end
        regret_match!(solver)
        cb()
        next!(prog)
    end
    solver
end

function strategy(sol::AbstractCFRSolver, I)
    infostate = get(sol.I, I, nothing)
    if isnothing(infostate)
        L = length(actions(sol.game, I))
        return fill(inv(L), L)
    else
        σ_I = infostate.s
        return σ_I ./ sum(σ_I)
    end
end

## extras

function Base.print(io::IO, sol::AbstractCFRSolver)
    for (k,I) in sol.I
        σ = copy(I.s)
        σ ./= sum(σ)
        println(io, k,"\t",round.(σ, digits=3))
    end
end
