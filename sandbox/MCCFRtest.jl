using Revise
using CounterfactualRegret
using CounterfactualRegret: IIEMatrixGame, Kuhn, SpaceGame

game = SpaceGame(5,10)
sol = ESCFRSolver(game;debug=true)

train!(sol, 10_000)

using Plots
V = collect(values(sol.I))
V[9]
plot(V[9])
plot(sol.I[(2,6,2)])


sol.I[(2,4,1)]

plot(reduce(hcat,sol.I[(2,8,1)].hist)')

FullEvaluate(sol)

print(sol)
