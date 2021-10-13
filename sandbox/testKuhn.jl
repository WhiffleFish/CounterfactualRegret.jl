include(joinpath(@__DIR__, "..", "sandbox", "CSCFR.jl"))
include(joinpath(@__DIR__, "..", "sandbox", "Kuhn.jl"))

game = Kuhn()
trainer = Trainer(game)

train!(trainer, 100_000)

@profiler train!(trainer, 100_000) recur=:flat

trainer.I

using BenchmarkTools

@benchmark train!(trainer, 1_000)
