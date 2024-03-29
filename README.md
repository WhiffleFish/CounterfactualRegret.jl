# CounterfactualRegret.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://whifflefish.github.io/CounterfactualRegret.jl/dev/)
[![codecov](https://codecov.io/gh/WhiffleFish/CounterfactualRegret.jl/branch/main/graph/badge.svg?token=X32NBIUN9Z)](https://codecov.io/gh/WhiffleFish/CounterfactualRegret.jl)

## Installation
```julia
using Pkg; Pkg.add("CounterfactualRegret")
```

## Implemented Solvers

| Solver Name   | Description        |
| ------------- | ------------------ |
| `CFRSolver`   | Vanilla CFR solver |
| `CSCFRSolver` | Chance Sampling    |
| `ESCFRSolver` | External Sampling  |
| `OSCFRSolver` | Outcome Sampling   |

Each solver takes optional kwarg `method`, which can be an instantiation of either `Vanilla`, `Plus`, or `Discount` types, which correspond to Vanilla CFR, CFR+, and discounted CFR respectively.

## External Solver Packages
| Name | Status |
| ---- | ------ |
| [DeepCFR](https://github.com/WhiffleFish/DeepCFR.jl) | [![CI](https://github.com/WhiffleFish/DeepCFR.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/WhiffleFish/DeepCFR.jl/actions/workflows/CI.yml) [![codecov](https://codecov.io/gh/WhiffleFish/DeepCFR.jl/branch/main/graph/badge.svg?token=NM2KU62FG2)](https://codecov.io/gh/WhiffleFish/DeepCFR.jl) |
| [ESCHER](https://github.com/WhiffleFish/ESCHER.jl)  | [![CI](https://github.com/WhiffleFish/ESCHER.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/WhiffleFish/ESCHER.jl/actions/workflows/CI.yml) [![codecov](https://codecov.io/gh/WhiffleFish/ESCHER.jl/branch/main/graph/badge.svg?token=rpqTMWcyXc)](https://codecov.io/gh/WhiffleFish/ESCHER.jl)     |
| [POMDPBestResponse](https://github.com/WhiffleFish/BestResponsePOMDP.jl) | [![CI](https://github.com/WhiffleFish/BestResponsePOMDP.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/WhiffleFish/BestResponsePOMDP.jl/actions/workflows/CI.yml) [![codecov](https://codecov.io/gh/WhiffleFish/BestResponsePOMDP.jl/branch/main/graph/badge.svg?token=lKGu7ENcfF)](https://codecov.io/gh/WhiffleFish/BestResponsePOMDP.jl) |

## Solving a Matrix Game

```julia
using CounterfactualRegret
const CFR = CounterfactualRegret
using CounterfactualRegret.Games
using Plots

game = MatrixGame([
    (1,1) (0,0) (0,0);
    (0,0) (0,2) (3,0);
    (0,0) (2,0) (0,3);
])
sol = CFRSolver(game; debug=true)
cb = CFR.ExploitabilityCallback(sol, 10) # optional callback to monitor training
train!(sol, 10_000; cb=cb)
plot(cb, lw=2)
```

<img src="./img/matrix_exploitability.svg">

## Finding Kuhn Poker Nash Equilibrium with external sampling & discounting

[Kuhn Poker Implementation & Game Definition Tutorial](src/games/Kuhn.jl)

```julia
game = Kuhn()
sol = ESCFRSolver(game; method=Discount(α=1.0, β=1.0, γ=1.0))
cb = CFR.ExploitabilityCallback(sol)
train!(sol, 100_001; cb=cb)

hist = cb.hist
exp_idxs = 10 .^(0:5) .+ 1
plot(
    hist.x[exp_idxs], hist.y[exp_idxs];
    xscale = :log10, lw=2, label="",
    xlabel = "Training Iterations",
    ylabel = "Exploitability"
)
```

<img src="./img/kuhn_exploitability.svg">
