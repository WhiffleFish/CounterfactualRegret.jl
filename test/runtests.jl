using HelloCFR, Plots
using Test

include(joinpath(@__DIR__, "testMatrix.jl"))

include(joinpath(@__DIR__, "testCFR.jl"))

include(joinpath(@__DIR__, "testExtensiveCFR.jl"))
