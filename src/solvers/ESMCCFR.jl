#=
External Sampling Counterfactual Regret Minimization
- "sample only the actions of the opponent and chance (those choices external to the player)"
=#
using Random

# try `Ref{Int}` for `a_idx` to keep immutable
mutable struct MCInfoState <: AbstractInfoState
    σ::Vector{Float64}
    r::Vector{Float64}
    s::Vector{Float64}
    _tmp_σ::Vector{Float64}
    a_idx::Int
end

function MCInfoState(L::Integer)
    return MCInfoState(
        fill(1/L, L),
        zeros(L),
        fill(1/L,L),
        fill(1/L,L),
        0
    )
end

struct ESCFRSolver{M,K,G} <: AbstractCFRSolver{K,G}
    method::M
    I::Dict{K, MCInfoState}
    game::G
end

function weighted_sample(rng::AbstractRNG, w::AbstractVector)
    t = rand(rng)
    i = 1
    cw = first(w)
    while cw < t && i < length(w)
        i += 1
        @inbounds cw += w[i]
    end
    return i
end

weighted_sample(w::AbstractVector) = weighted_sample(Random.GLOBAL_RNG, w)

Random.rand(I::AbstractInfoState) = weighted_sample(I.σ)


"""
    ESCFRSolver(game::Game; method::Symbol=:vanilla, alpha::Float64 = 1.0, beta::Float64 = 1.0, gamma::Float64 = 1.0, d::Int)

Instantiate external sampling CFR solver with some `game`.

Samples a single actions from all players for single tree traversal.
Time to complete a traversal is O(|𝒜ᵢ|ᵈ), where d is the depth of the game and |𝒜ᵢ| is the size of the action space
for the acting player.
"""
function ESCFRSolver(
    game::Game{H,K};
    method = Vanilla()
    ) where {H,K}
    return ESCFRSolver(method, Dict{K, MCInfoState}(), game)
end

function regret_match!(sol::ESCFRSolver)
    for I in values(sol.I)
        regret_match!(I)
        I.a_idx = 0
    end
end

function CFR(solver::ESCFRSolver, h, i, t)
    game = solver.game
    current_player = player(game, h)

    if isterminal(game, h)
        return utility(game, i, h)
    elseif iszero(current_player) # chance player
        σ_c = chance_policy(game, h)
        a = rand(σ_c)
        h′ = next_hist(game,h,a)
        return CFR(solver, h′, i, t)
    end

    k = infokey(game, h)
    I = infoset(solver, k)
    A = actions(game, k)

    v_σ = 0.0

    if current_player == i
        v_σ_Ia = I._tmp_σ
        for (k,a) in enumerate(A)
            h′ = next_hist(game, h, a)
            v_σ_Ia[k] = CFR(solver, h′, i, t)
            v_σ += I.σ[k]*v_σ_Ia[k]
        end

        update!(solver, I, v_σ_Ia, v_σ, t)
    else
        a_idx = I.a_idx
        iszero(a_idx) && (a_idx = rand(I))
        I.a_idx = a_idx
        a = A[a_idx]
        h′ = next_hist(game, h, a)
        v_σ = CFR(solver, h′, i, t)
    end

    return v_σ
end

function update!(sol::ESCFRSolver{Discount}, I, v_σ_Ia, v_σ, t)
    (;α, β, γ) = sol.method
    s_coeff = t^γ
    for k in eachindex(v_σ_Ia)
        r = (1 - I.σ[k])*(v_σ_Ia[k] - v_σ)
        r_coeff = r > 0.0 ? t^α : t^β

        I.r[k] += r_coeff*r
        I.s[k] += s_coeff*I.σ[k]
    end
    return nothing
end

function update!(sol::ESCFRSolver{Plus}, I, v_σ_Ia, v_σ, t)
    @. I.r = max((1 - I.σ)*(v_σ_Ia - v_σ) + I.r, 0.0)
    @. I.s += t*I.σ
end

function update!(sol::ESCFRSolver{Vanilla}, I, v_σ_Ia, v_σ, t)
    @. I.r += (1 - I.σ)*(v_σ_Ia - v_σ)
    @. I.s += I.σ
end

function train!(solver::ESCFRSolver, N::Int; show_progress::Bool=false, cb=()->())
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
