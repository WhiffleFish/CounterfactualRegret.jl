using CounterfactualRegret
using CounterfactualRegret.Games
const CFR = CounterfactualRegret
using StaticArrays
using Random
using RecipesBase
using LinearAlgebra
using Test

Random.seed!(1337)

include(joinpath(@__DIR__, "extensiveCFR.jl"))

include(joinpath(@__DIR__, "plots.jl"))

include(joinpath(@__DIR__, "printing.jl"))

include(joinpath(@__DIR__, "extensive2matrix.jl"))

include(joinpath(@__DIR__, "exploitability.jl"))

include(joinpath(@__DIR__, "callback.jl"))

include(joinpath(@__DIR__, "tree_building.jl"))

include(joinpath(@__DIR__, "vectorized.jl"))
