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

include(joinpath("solvers", "solvers.jl"))

include(joinpath("evaluation", "evaluation.jl"))

include(joinpath("games", "Games.jl"))

end # module
