module Games

using ..CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using RecipesBase

include("Extensive2Matrix.jl")
include("Matrix.jl")
export MatrixGame

include("Kuhn.jl")
export Kuhn

include("CoinToss.jl")
export CoinToss

end
