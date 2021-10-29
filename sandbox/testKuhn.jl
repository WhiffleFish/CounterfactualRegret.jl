using HelloCFR
using HelloCFR: Kuhn

game = Kuhn()
solver = CFRSolver(game; debug=false)

train!(solver, 1000)

@profiler train!(solver, 100_000)
