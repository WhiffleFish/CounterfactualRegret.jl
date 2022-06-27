module CounterfactualRegret

using ProgressMeter
using RecipesBase


include(joinpath("Extensive", "ExtensiveGames.jl"))
export Game, initialhist, isterminal, utility, player, next_hist, infokey, actions
export chance_action, chance_actions, other_player
export infokeytype, histtype

include(joinpath("Extensive", "baselines.jl"))
export ZeroBaseline, ExpectedValueBaseline

include(joinpath("Extensive", "CFR.jl"))
include(joinpath("Extensive", "CSMCCFR.jl"))
include(joinpath("Extensive", "ESMCCFR.jl"))
include(joinpath("Extensive", "OSMCCFR.jl"))
export CFRSolver, CSCFRSolver, ESCFRSolver, OSCFRSolver
export train!, strategy


include(joinpath("Extensive", "evaluation.jl"))
export evaluate


include(joinpath("Extensive", "exploitability.jl"))
export ExploitabilitySolver, exploitability

include(joinpath("Extensive", "callback.jl"))

# Miscellaneous Games
include(joinpath("games", "Games.jl"))

end # module
