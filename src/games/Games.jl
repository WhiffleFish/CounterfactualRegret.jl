module Games

using ..CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using RecipesBase
using LaTeXStrings

include("Extensive2Matrix.jl")
include("IIEMatrix.jl")
export IIEMatrixGame

include("Kuhn.jl")
export Kuhn

include("CoinToss.jl")
export CoinToss

end
