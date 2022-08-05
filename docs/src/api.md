# API Documentation

Docstrings for interface members can be [accessed through Julia's built-in documentation system](https://docs.julialang.org/en/v1/manual/documentation/index.html#Accessing-Documentation-1) or in the list below.

```@meta
CurrentModule = CounterfactualRegret
```

## Contents

```@contents
Pages = ["api.md"]
```

## Index

```@index
Pages = ["api.md"]
```

## Game Functions

```@docs
infokeytype
histtype
initialhist
isterminal
utility
player
chance_action
chance_actions
next_hist
infokey
actions
players
observation
vectorized_info
vectorized_hist
```

## Solvers
```@docs
train!
strategy
CFRSolver
CSCFRSolver
ESCFRSolver
OSCFRSolver
```

## Games
```@docs
Games.MatrixGame
Games.Kuhn
```

## Extras
```@docs
ExploitabilityCallback
Throttle
CallbackChain
exploitability
evaluate
ExpectedValueBaseline
ZeroBaseline
```
