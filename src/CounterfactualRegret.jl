module CounterfactualRegret

using FileIO
using ProgressMeter
using RecipesBase
using Random
import POMDPTools


include("ExtensiveGames.jl")
export Game, initialhist, isterminal, utility, player, next_hist, infokey, actions
export observation
export chance_action, chance_actions, chance_policy, randpdf, other_player
export infokeytype, histtype
export vectorized_hist, vectorized_info

include(joinpath("solvers", "solvers.jl"))

include(joinpath("evaluation", "evaluation.jl"))

include(joinpath("games", "Games.jl"))

end # module
