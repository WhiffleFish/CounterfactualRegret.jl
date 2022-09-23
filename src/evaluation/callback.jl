struct ExploitabilityHistory
    x::Vector{Int}
    y::Vector{Float64}
    ExploitabilityHistory() = new(Int[], Float64[])
end

function Base.push!(h::ExploitabilityHistory, x, y)
    push!(h.x, x)
    push!(h.y, y)
end

"""
    ExploitabilityCallback(sol::AbstractCFRSolver, n=1; p=1)

- `sol` :
- `n`   : Frequency with which to query exploitability e.g. `n=10` indicates checking exploitability every 10 CFR iterations
- `p`   : Player whose exploitability is being measured

Usage:
```
using CounterfactualRegret
const CFR = CounterfactualRegret

game = CFR.Games.Kuhn()
sol = CFRSolver(game)
train!(sol, 10_000, cb=ExploitabilityCallback(sol))
```
"""
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
    xlabel --> "Training Steps"
    @series begin
        ylabel --> "Exploitability"
        label --> ""
        hist.x, hist.y
    end
end

@recipe f(cb::ExploitabilityCallback) = cb.hist

"""

Wraps a function, causing it to trigger every `n` CFR iterations

```
test_cb = Throttle(() -> println("test"), 100)
```
Above example will print `"test"` every 100 CFR iterations
"""
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


"""
Chain together multiple callbacks

Usage:
```
using CounterfactualRegret
const CFR = CounterfactualRegret


game = CFR.Games.Kuhn()
sol = CFRSolver(game)
exp_cb = ExploitabilityCallback(sol)
test_cb = Throttle(() -> println("test"), 100)
train!(sol, 10_000, cb=CFR.CallbackChain(exp_cb, test_cb))
```
"""
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


mutable struct MCTSExploitabilityCallback{M<:ISMCTS}
    mcts::M
    n::Int
    eval_iter::Int
    state::Int
    hist::ExploitabilityHistory
    function MCTSExploitabilityCallback(mcts::ISMCTS, n=1; eval_iter=mcts.max_iter)
        new{typeof(mcts)}(mcts, n, eval_iter, 0, ExploitabilityHistory())
    end
end

ExploitabilityCallback(mcts::ISMCTS, n; eval_iter=mcts.max_iter) = MCTSExploitabilityCallback(mcts, n;eval_iter) 

function exploitability(cb::MCTSExploitabilityCallback)
    mcts = cb.mcts
    v_exploit = run(mcts)
    v_current = approx_eval(mcts.sol, cb.eval_iter, mcts.sol.game, mcts.player)
    return v_exploit - v_current
end

function (cb::MCTSExploitabilityCallback)()
    if iszero(rem(cb.state, cb.n))
        push!(cb.hist, cb.state, exploitability(cb))
    end
    cb.state += 1
end

@recipe f(cb::MCTSExploitabilityCallback) = cb.hist
