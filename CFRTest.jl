using ProgressMeter
include("CFR.jl")

game = SimpleIOGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = SimpleIOPlayer(game,1, [0.1,0.2,0.7])
p2 = SimpleIOPlayer(game,2, [0.1,0.2,0.7])
I1 = SimpleInfoState(game, 1)
I2 = SimpleInfoState(game, 2)
train_one!(p1,p2)

plot_strats(p1, p2)

@profiler update_strategies!(game, (I1, I2), p1, p2)
