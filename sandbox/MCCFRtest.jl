using Revise
using HelloCFR
using HelloCFR: IIEMatrixGame, Kuhn

game = Kuhn()
sol = ESCFRSolver(game)
train!(sol, 1_000)

sol.I[(1,2,[0,1])]

game = IIEMatrixGame([
    (-1,-1) (-3,0);
    (0,-3) (-2,-2)
])

sol = ESCFRSolver(game;debug=true)
train!(sol, 10_000)

using Plots
using Test
plot(sol)

I0 = first(values(sol.I))
