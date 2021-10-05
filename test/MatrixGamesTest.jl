using HelloCFR
using Plots

RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = MatrixPlayer(RPS, 1, [0.1,0.2,0.7])
p2 = MatrixPlayer(RPS, 2, [0.1,0.2,0.7])

train_both!(p1, p2, 500_000)
train_one!(p1,p2, 10_000)
plot(p1,p2)

@profiler train_both!(p1, p2, 50_000)
