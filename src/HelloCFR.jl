module HelloCFR

include(joinpath("Matrix", "MatrixGames.jl"))
export MatrixGame, MatrixPlayer, clear!, train_both!, train_one!
export evaluate


include(joinpath("Matrix", "CFR.jl"))
export SimpleIIGame, SimpleIIPlayer


include(joinpath("Extensive", "ExtensiveGames.jl"))
export Game, initialhist, isterminal, u, player, next_hist, infokey, actions
export chance_action, chance_actions, other_player
export infokeytype, histtype


include(joinpath("Extensive", "CFR.jl"))
include(joinpath("Extensive", "CSCFR.jl"))
include(joinpath("Extensive", "DCFR.jl"))
export CFRSolver, CSCFRSolver, DCFRSolver, train!
export FullEvaluate, MonteCarloEvaluate

include(joinpath("Games", "Extensive2Matrix.jl"))
include(joinpath("Games", "IIEMatrix.jl"))
include(joinpath("Games", "Kuhn.jl"))

end # module
