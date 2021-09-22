include("MatrixGames.jl")

RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = MatrixPlayer(RPS, 1, [0.1,0.2,0.7])
p2 = MatrixPlayer(RPS, 2, [0.1,0.2,0.7])

train_one!(p1, p2, 5000)
plot(p1, p2)

clear!(p1)
clear!(p2)
