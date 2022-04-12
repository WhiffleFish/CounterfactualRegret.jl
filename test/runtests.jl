using CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using Random
using RecipesBase
using LinearAlgebra
using Test

Random.seed!(1337)

include(joinpath(@__DIR__, "matrix.jl"))

include(joinpath(@__DIR__, "extensiveCFR.jl"))

include(joinpath(@__DIR__, "plots.jl"))

include(joinpath(@__DIR__, "printing.jl"))

include(joinpath(@__DIR__, "extensive2matrix.jl"))

include(joinpath(@__DIR__, "exploitability.jl"))
