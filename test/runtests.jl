using CounterfactualRegret
using StaticArrays
using Random
using Test

Random.seed!(1337)

include(joinpath(@__DIR__, "testMatrix.jl"))

include(joinpath(@__DIR__, "testExtensiveCFR.jl"))
