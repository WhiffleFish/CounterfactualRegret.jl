using CounterfactualRegret
using CounterfactualRegret.Games
using CounterfactualRegret.Games: KuhnActionHist
const CFR = CounterfactualRegret
using StaticArrays
using Random
using RecipesBase
using LinearAlgebra
using Test

Random.seed!(1337)

include(joinpath(@__DIR__, "staticpushvectors.jl"))

include(joinpath(@__DIR__, "extensiveCFR.jl"))

include(joinpath(@__DIR__, "exploitability.jl"))

include(joinpath(@__DIR__, "is-mcts.jl"))

include(joinpath(@__DIR__, "printing.jl"))

include(joinpath(@__DIR__, "extensive2matrix.jl"))

include(joinpath(@__DIR__, "callback.jl"))

include(joinpath(@__DIR__, "tree_building.jl"))

include(joinpath(@__DIR__, "vectorized.jl"))
