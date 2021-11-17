using CounterfactualRegret
using Plots

game = SimpleIIGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = SimpleIIPlayer(game,1, [0.1,0.2,0.7])
p2 = SimpleIIPlayer(game,2, [0.1,0.2,0.7])

train_both!(p1,p2,1000)
p = plot(p1, p2, lw=2)
# savefig(p, "img/RPS_CFR.svg")

p1 = SimpleIIPlayer(game,1, [0.1,0.2,0.7])
p2 = SimpleIIPlayer(game,2, [0.1,0.2,0.7])
train_one!(p1,p2,100)
p = plot(p1, p2, lw=2)
# savefig(p, "img/RPS_CFR_exploit.svg")

@profiler train_both!(p1,p2, 50_000) recur=:flat
