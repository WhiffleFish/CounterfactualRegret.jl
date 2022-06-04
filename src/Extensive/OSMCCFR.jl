struct OSCFRSolver{method,B,K,G,I} <: AbstractCFRSolver{K,G,I}
    m::Val{method}
    baseline::B
    I::Dict{K, I}
    game::G
    α::Float64
    β::Float64
    γ::Float64
    ϵ::Float64
end

function OSCFRSolver(
    game::Game{H,K};
    method::Symbol  = :vanilla,
    baseline        = ZeroBaseline(),
    alpha::Float64  = 1.0,
    beta::Float64   = 1.0,
    gamma::Float64  = 1.0,
    ϵ::Float64      = 0.6) where {H,K}

    if method ∈ (:vanilla, :discount, :plus)
        return OSCFRSolver(Val(method), baseline, Dict{K, InfoState}(), game, alpha, beta, gamma, ϵ)
    else
        error("method $method ∉ (:vanilla, :discount, :plus)")
    end
end

function CFR(sol::OSCFRSolver, h, p, t, π_i=1.0, π_ni=1.0, q_h=1.0)
    (;game, baseline, ϵ) = sol
    current_player = player(game, h)

    if isterminal(game, h) # (a)
        return utility(game, p, h)

    elseif iszero(current_player)
        A = chance_actions(game, h)
        a = rand(A)
        h′ = next_hist(game,h,a)
        return CFR(sol, h′, p, t, π_i, π_ni*inv(length(A)), q_h)

    elseif current_player == p
        I = infoset(sol, h)
        A = actions(game, h)
        σ = regret_match!(I) # (b)

        σ′ = I._tmp_σ .= ϵ/length(A) .+ (1-ϵ) .* σ

        a_idx = weighted_sample(σ′)
        a = A[a_idx]
        h′ = next_hist(game, h, a)

        K = infokey(game, h)
        b = baseline(K, length(A))

        u = CFR(sol, h′, p, t, π_i*σ[a_idx], π_ni, q_h*σ′[a_idx])

        ûbσha = Vector{Float64}(undef, length(A))

        for (k,a) in enumerate(A)
            bIa = b[k]
            ûbσha[k] = if k == a_idx
                ξha = σ′[k]
                bIa + ((u - bIa) / ξha)
            else
                bIa
            end
        end

        ûbσh = 0.0
        for (k,a) in enumerate(A) # (c)
            ûbσh += σ[k]*ûbσha[k]
        end

        ûbσIa = (π_ni / q_h) * ûbσha
        ûbσI = 0.0

        for k in eachindex(ûbσIa) # (d)
            ûbσI += σ[k]*ûbσIa[k]
        end

        regret_update!(sol, I.r, ûbσIa, ûbσI, t)

        update!(baseline, K, ûbσIa)

        return ûbσh
    else
        I = infoset(sol, h)
        A = actions(game, h)
        σ = I.σ

        K = infokey(game, h)
        b = sol.baseline(K, length(A))

        a_idx = weighted_sample(σ)
        a = A[a_idx]
        h′ = next_hist(game, h, a)

        u = CFR(sol, h′, p, t, π_i, π_ni*σ[a_idx], q_h*σ[a_idx])

        ûbσha = Vector{Float64}(undef, length(A))

        for (k,a) in enumerate(A)
            bIa = b[k]
            ûbσha[k] = if k == a_idx
                ξha = σ[k]
                bIa + (u - bIa) / ξha
            else
                bIa
            end
        end

        ûbσh = 0.0
        for (k,a) in enumerate(A) # (c)
            ûbσh += σ[k]*ûbσha[k]
        end

        strat_update!(sol, I, σ, π_ni, q_h, t)

        return ûbσh
    end
end

function regret_update!(sol::OSCFRSolver{:discount}, r, ûbσIa, ûbσI, t)
    (;α, β) = sol
    for k in eachindex(r)
        r_k = ûbσIa[k] - ûbσI
        r[k] += if r_k > 0.0
            (t^α)*r_k
        else
            (t^β)*r_k
        end
    end
end

function regret_update!(sol::OSCFRSolver{:plus}, r, ûbσIa, ûbσI, t)
    @. r = max(ûbσIa - ûbσI + r, 0.0)
end

function regret_update!(sol::OSCFRSolver{:vanilla}, r, ûbσIa, ûbσI, t)
    @. r += ûbσIa - ûbσI
end

function strat_update!(sol::OSCFRSolver{:discount}, I, σ, π_ni, q_h, t)
    I.s .+= (t^sol.γ)*(π_ni / q_h) .* σ
end

function strat_update!(sol::OSCFRSolver{:plus}, I, σ, π_ni, q_h, t)
    I.s .+= (π_ni / q_h) .* σ
end

function strat_update!(sol::OSCFRSolver{:vanilla}, I, σ, π_ni, q_h, t)
    I.s .+= (π_ni / q_h) .* σ
end

function train!(solver::OSCFRSolver, N::Int; show_progress::Bool=false, cb=()->())
    ih = initialhist(solver.game)
    prog = Progress(N; enabled=show_progress)
    for t in 1:N
        for i in 1:players(solver.game)
            CFR(solver, ih, i, t)
        end
        cb()
        next!(prog)
    end
    finalize_strategies!(solver)
end
