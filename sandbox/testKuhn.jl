using Plots
using CounterfactualRegret
using CounterfactualRegret: Kuhn, IIEMatrixGame

game = IIEMatrixGame([
    (1,1) (0,0) (0,0);
    (0,0) (0,2) (3,0);
    (0,0) (2,0) (0,3);
])

sol1 = CFRSolver(game; debug=true)
train!(sol1, 5000)
plot(sol1)

sol2 = DCFRSolver(game;
    alpha = 1.0,
    beta = 1.0,
    gamma = 1.0,
    debug=true
)

train!(sol2, 5000)
plot(sol2)
