include("baselines.jl")
export ZeroBaseline, ExpectedValueBaseline

include("methods.jl")
export Vanilla, Discount, Plus

include("CFR.jl")
export train!, strategy
export CFRSolver

include("policy.jl")

include("CSMCCFR.jl")
export CSCFRSolver

include("ESMCCFR.jl")
export ESCFRSolver

include("OSMCCFR.jl")
export OSCFRSolver
