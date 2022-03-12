using CounterfactualRegret
using StaticArrays
using Test

include(joinpath(@__DIR__, "testMatrix.jl"))

include(joinpath(@__DIR__, "testExtensiveCFR.jl"))
