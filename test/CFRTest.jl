using HelloCFR
using Plots

game = SimpleIOGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = SimpleIOPlayer(game,1, [0.1,0.2,0.7])
p2 = SimpleIOPlayer(game,2, [0.1,0.2,0.7])

train_both!(p1,p2,10000)
train_one!(p1,p2,100)
plot(p1, p2)

@profiler train_both!(p1,p2, 50_000) recur=:flat
