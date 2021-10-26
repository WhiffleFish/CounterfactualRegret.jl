module HelloCFR

include(joinpath("Matrix", "MatrixGames.jl"))
export MatrixGame, MatrixPlayer, clear!, train_both!, train_one!
export evaluate


include(joinpath("Matrix", "CFR.jl"))
export SimpleIIGame, SimpleIIPlayer


include(joinpath("Extensive", "ExtensiveGames.jl"))
export Game, initialhist, isterminal, u, player, next_hist, infokey, actions
export chance_action, chance_actions, other_player


include(joinpath("Extensive", "CFR.jl"))
include(joinpath("Extensive", "CSCFR.jl"))
export CFRSolver, CSCFRSolver, train!


include(joinpath("Games", "IIEMatrix.jl"))
include(joinpath("Games", "Kuhn.jl"))

end # module
