include(joinpath(@__DIR__, "..", "sandbox", "Kuhn.jl"))
include(joinpath(@__DIR__, "..", "sandbox", "CSCFR.jl"))

game = Kuhn()
train!(game, 10_000)

@profiler train!(game, 100_000) recur=:flat

@benchmark train!(game, 10_000)

game.I
