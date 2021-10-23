using HelloCFR
using Plots

## Regret Matching

R = [
    (0,0) (-1,1) (1,-1) (3,3);
    (1,-1) (0,0) (-1,1) (2,2);
    (-1,1) (1,-1) (0,0) (2,2);
]

R = [
    (-1,-1) (-3,0);
    (0,-3) (-2,-2)
]

mat_game = MatrixGame(R)

p1 = MatrixPlayer(mat_game, 1, [0.1,0.2,0.6])
p2 = MatrixPlayer(mat_game, 2, [0.1,0.2,0.6,0.1])

p1 = MatrixPlayer(mat_game, 1, [0.0,1.0])
p2 = MatrixPlayer(mat_game, 2, [0.0,1.0])

train_both!(p1,p2, 10_000)
plot(p1,p2)

p1

evaluate(p1,p2)

## CFR

ext_game = SimpleIOGame(R)
p1 = SimpleIOPlayer(ext_game, 1, [0.1,0.2,0.7])
p2 = SimpleIOPlayer(ext_game, 2, [0.1,0.2,0.6,0.1])

p1 = SimpleIOPlayer(ext_game, 1, [1.0,0.0])
p2 = SimpleIOPlayer(ext_game, 2, [1.0,0.0])

train_both!(p1,p2, 1000)
plot(p1,p2)

p1

include("..\\sandbox\\RPS.jl")
game = RPS(R)

trainer = Trainer(game)

train!(trainer, 1_000)

trainer

actions(game, Int[2])
