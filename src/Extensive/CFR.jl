abstract type IIESolver end # Imperfect Information Extensive Game Solver
abstract type AbstractInfoState end
abstract type AbstractCFRSolver{H,K,G<:Game,I<:AbstractInfoState} <: IIESolver end

struct InfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
end

struct DebugInfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    hist::Vector{Vector{Float64}}
end

function DebugInfoState(L::Int)
    return DebugInfoState(
        fill(1/L, L),
        zeros(L),
        zeros(Float64,L),
        Vector{Float64}[fill(1/L, L)]
    )
end

function InfoState(L::Int)
    return InfoState(
        fill(1/L, L),
        zeros(L),
        zeros(Float64,L)
    )
end

struct CFRSolver{H,K,G,I} <: AbstractCFRSolver{H,K,G,I}
    explored::Vector{H}
    I::Dict{K, I}
    game::G
end

function CFRSolver(game::Game{H,K}; debug::Bool=false) where {H,K}
    if debug
        return CFRSolver(H[], Dict{K, DebugInfoState}(), game)
    else
        return CFRSolver(H[], Dict{K, InfoState}(), game)
    end
end

const REG_CFRSOLVER{H,K,G} = AbstractCFRSolver{H,K,G,InfoState}
const DEBUG_CFRSOLVER{H,K,G} = AbstractCFRSolver{H,K,G,DebugInfoState}

function infoset(solver::AbstractCFRSolver{H,K,G,INFO}, h::H) where {H,K,G,INFO}
    game = solver.game
    k = infokey(game, h)
    if h ∈ solver.explored # if h stored, return corresponding infoset pointer
        return solver.I[k]
    else
        push!(solver.explored, h)
        if haskey(solver.I, k)
            return solver.I[k]
        else
            I = INFO(length(actions(game,h)))
            solver.I[k] = I
            return I
        end
    end
end

function regret_match!(I::AbstractInfoState)
    s = 0.0
    σ = I.σ
    for (i,r_i) in enumerate(I.r)
        if r_i > 0
            s += r_i
            σ[i] = r_i
        else
            σ[i] = 0.0
        end
    end
    s > 0 ? (σ ./= s) : fill!(σ,1/length(σ))
end

function CFR(solver::CFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return u(game, i, h)
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
    v_σ_Ia = zeros(Float64, length(A))

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

function train!(solver::REG_CFRSOLVER, N::Int)
    ih = initialhist(solver.game)
    for _ in 1:N
        for i in 1:2
            CFR(solver, ih, i, 0.0, 1.0, 1.0)
        end
        for I in values(solver.I)
            regret_match!(I)
        end
    end
end

function train!(solver::DEBUG_CFRSOLVER, N::Int)
    ih = initialhist(solver.game)
    for _ in 1:N
        for i in 1:2
            CFR(solver, ih, i, 0.0, 1.0, 1.0)
        end
        for I in values(solver.I)
            regret_match!(I)
            push!(I.hist, copy(I.σ))
        end
    end
end

function finalize_strategies!(solver::AbstractCFRSolver)
    for I in values(solver.I)
        I.σ .= I.s
        s = sum(I.σ)
        s > 0 ? I.σ ./= sum(I.σ) : fill!(I.σ, 1/length(I.σ))
    end
end

function evaluate(solver::CFRSolver, N::Int)
    finalize_strategies!(solver)

    p1_eval = 0.0
    p2_eval = 0.0

    ih = initialhist(solver.game)
    for _ in 1:N
        p1_eval += evaluate(solver, ih, 1, 0, 1.0, 1.0)
        p2_eval += evaluate(solver, ih, 2, 0, 1.0, 1.0)
    end

    p1_eval /= N
    p2_eval /= N

    return (p1_eval, p2_eval)
end

function evaluate(solver::CFRSolver, h, i, t, π_1, π_2)
    game = solver.game
    if isterminal(game, h)
        return u(game, i, h)
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

    for (k,a) in enumerate(A)
        v_σ_Ia = 0.0
        h′ = next_hist(game, h, a)
        if player(game, h) === 1
            v_σ_Ia = evaluate(solver, h′, i, t, I.σ[k]*π_1, π_2)
        else
            v_σ_Ia = evaluate(solver, h′, i, t, π_1, I.σ[k]*π_2)
        end
        v_σ += I.σ[k]*v_σ_Ia
    end

    return v_σ
end
