module CounterfactualRegret

using ProgressMeter
using RecipesBase
using Random


include("ExtensiveGames.jl")
export Game, initialhist, isterminal, utility, player, next_hist, infokey, actions
export observation
export chance_action, chance_actions, other_player
export infokeytype, histtype
export vectorized_hist, vectorized_info


include(joinpath("solvers", "baselines.jl"))
export ZeroBaseline, ExpectedValueBaseline

include(joinpath("solvers", "methods.jl"))
export Vanilla, Discount, Plus

include(joinpath("solvers", "CFR.jl"))
include(joinpath("solvers", "CSMCCFR.jl"))
include(joinpath("solvers", "ESMCCFR.jl"))
include(joinpath("solvers", "OSMCCFR.jl"))
export CFRSolver, CSCFRSolver, ESCFRSolver, OSCFRSolver
export train!, strategy


include(joinpath("evaluation", "evaluation.jl"))
export evaluate

include(joinpath("evaluation", "exploitability.jl"))
include(joinpath("evaluation", "is-mcts.jl"))
export ExploitabilitySolver, exploitability, ISMCTS

include(joinpath("evaluation", "callback.jl"))
export ExploitabilityCallback

# Miscellaneous Games
include(joinpath("games", "Games.jl"))

end # module
