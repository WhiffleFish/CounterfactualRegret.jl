"""
Vanilla CFR update methods described in:
- Regret Minimization in Games with Incomplete Informationj
    - https://proceedings.neurips.cc/paper/2007/file/08d98638c6fcd194a4b1e6992063e944-Paper.pdf
- Monte Carlo Sampling for Regret Minimization in Extensive Games
    - https://proceedings.neurips.cc/paper/2009/file/00411460f7c92d2124a67ea0f4cb5f85-Paper.pdf
"""
struct Vanilla end


"""
CFR+ update method described in:
- Solving Large Imperfect Information Games Using CFR+
    - https://arxiv.org/abs/1407.5042

Paramters:
    - `d` - averaging delay in number of iterations
        - update weight given by `max(t-d, 0)` where `t` is the current iteration count
"""
Base.@kwdef struct Plus
    d::Float64 = 0 
end


"""
Discounted CFR described in:
- Solving Imperfect-Information Games via Discounted Regret Minimization
    - https://arxiv.org/abs/1809.04040

Parameters: 
- `α` - discount on positive regret
- `β` - discount on negative regret
- `γ` - discount on strategy 
"""
Base.@kwdef struct Discount
    α::Float64 = 1.0
    β::Float64 = 1.0
    γ::Float64 = 1.0
end