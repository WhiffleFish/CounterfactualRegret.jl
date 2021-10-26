using HelloCFR
# include(joinpath(@__DIR__, "..", "src", "games", "CSCFR.jl"))
include(joinpath(@__DIR__, "..", "src", "games", "Kuhn.jl"))

game = Kuhn()
trainer = Trainer(game; debug=true)

train!(trainer, 1000)

@profiler train!(trainer, 100_000) recur=:flat

trainer.I

FAILURE_KEYS = [(1,3,[]),(2,1,[0]),(2,2,[1]),(1,2,[0,1])]

using Plots
k = 3
trainer.I[FAILURE_KEYS[k]]
f1 = trainer.I[FAILURE_KEYS[k]].hist
plot(reduce(hcat, f1)')

trainer.I

using BenchmarkTools

@benchmark train!(trainer, 1_000)
