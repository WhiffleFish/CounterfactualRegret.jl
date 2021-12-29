# CounterfactualRegret.jl

## Implemented Solvers
- `CFRSolver` - Vanilla CFR solver
- `DCFRSolver` - Discounted CFR solver
- `CSCFRSolver` - Chance sampling CFR solver (Monte Carlo sampling of chance player actions)
- `ESCFRSolver` - External sampling CFR solver (Monte Carlo sampling of chance player and opposing player actions)


## Finding Kuhn Poker Nash Equilibrium with CFR
[Kuhn Poker Implementation](src/games/Kuhn.jl)

```julia
julia> using CounterfactualRegret: Kuhn

julia> using CounterfactualRegret

julia> game = Kuhn();

julia> sol = CFRSolver(game);

julia> train!(sol, 1_000_000, show_progress=false)

julia> print(sol)

Player: 2        Card: 2         h: 1__          σ: [0.666, 0.334]
Player: 2        Card: 1         h: 0__          σ: [0.667, 0.333]
Player: 2        Card: 3         h: 1__          σ: [0.0, 1.0]
Player: 1        Card: 1         h: ___          σ: [0.792, 0.208]
Player: 2        Card: 2         h: 0__          σ: [1.0, 0.0]
Player: 2        Card: 3         h: 0__          σ: [0.0, 1.0]
Player: 1        Card: 2         h: ___          σ: [1.0, 0.0]
Player: 1        Card: 3         h: ___          σ: [0.375, 0.625]
Player: 1        Card: 1         h: 01_          σ: [1.0, 0.0]
Player: 2        Card: 1         h: 1__          σ: [1.0, 0.0]
Player: 1        Card: 2         h: 01_          σ: [0.458, 0.542]
Player: 1        Card: 3         h: 01_          σ: [0.0, 1.0]
```

## Finding NE with Regret Matching
```julia
using CounterfactualRegret
using Plots

RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

init_strategy = [0.1,0.2,0.7]

p1 = player(RPS, 1, init_strategy)
p2 = player(RPS, 2, init_strategy)

train_both!(p1, p2, 10_000)
plot(p1, p2, lw=2)
```
<img src="./img/RPS_regret_match.svg">

## Finding NE with CFR
```julia
game = SimpleIIGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = SimpleIIPlayer(game,1, [0.1,0.2,0.7])
p2 = SimpleIIPlayer(game,2, [0.1,0.2,0.7])

train_both!(p1,p2,1000)
plot(p1, p2, lw=2)
```
<img src="./img/RPS_CFR.svg">

## Exploiting static opponent with CFR
```julia
p1 = SimpleIIPlayer(game,1, [0.1,0.2,0.7])
p2 = SimpleIIPlayer(game,2, [0.1,0.2,0.7])
train_one!(p1,p2,100)
plot(p1, p2, lw=2)
```
<img src="./img/RPS_CFR_exploit.svg">
