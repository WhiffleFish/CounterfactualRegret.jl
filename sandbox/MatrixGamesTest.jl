using CounterfactualRegret
using Plots

RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

init_strategy = [0.1,0.2,0.7]

p1 = MatrixPlayer(RPS, 1, copy(init_strategy))
p2 = MatrixPlayer(RPS, 2, copy(init_strategy))

train_both!(p1, p2, 100_000)
plot(p1,p2, lw=2)

train_one!(p1,p2, 1_000)
plot(p1)

@profiler train_both!(p1, p2, 50_000)
