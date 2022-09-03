module Games

using ..CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using RecipesBase

include("util.jl")
export StaticPushVector, SPV

include("Extensive2Matrix.jl")
include("Matrix.jl")
export MatrixGame

include("Kuhn.jl")
export Kuhn

include("CoinToss.jl")
export CoinToss

include("tree_builder.jl")
export GameTree

end
