struct ExploitabilityHistory
    x::Vector{Int}
    y::Vector{Float64}
    ExploitabilityHistory() = new(Int[], Float64[])
end

function Base.push!(h::ExploitabilityHistory, x, y)
    push!(h.x, x)
    push!(h.y, y)
end

mutable struct ExploitabilityCallback{SOL<:AbstractCFRSolver, ESOL<:ExploitabilitySolver}
    sol::SOL
    e_sol::ESOL
    n::Int
    state::Int
    hist::ExploitabilityHistory
end

function ExploitabilityCallback(sol::AbstractCFRSolver, n::Int=1; p::Int=1)
    e_sol = ExploitabilitySolver(sol, p)
    return ExploitabilityCallback(sol, e_sol, n, 0, ExploitabilityHistory())
end

function (cb::ExploitabilityCallback)()
    if iszero(rem(cb.state, cb.n))
        e = exploitability(cb.e_sol, cb.sol)
        push!(cb.hist, cb.state, e)
    end
    cb.state += 1
end

@recipe function f(hist::ExploitabilityHistory)
    xlabel := "Training Steps"
    @series begin
        subplot := 1
        ylabel := "Exploitability"
        label := ""
        hist.x, hist.y
    end
end

@recipe f(cb::ExploitabilityCallback) = cb.hist

mutable struct Throttle{F}
    f::F
    n::Int
    state::Int
end

function Throttle(f::Function, n::Int)
    return Throttle(f, n, 0)
end

function (t::Throttle)()
    iszero(rem(t.state, t.n)) && t.f()
    t.state += 1
end

struct CallbackChain{T<:Tuple}
	t::T
	CallbackChain(args...) = new{typeof(args)}(args)
end

Base.iterate(chain::CallbackChain, s=1) = iterate(chain.t, s)

function (chain::CallbackChain)()
	for cb in chain
		cb()
	end
end
