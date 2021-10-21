module HelloCFR

include("MatrixGames.jl")
export MatrixGame, MatrixPlayer, clear!, train_both!, train_one!

include("CFR.jl")
export SimpleIOGame, SimpleIOPlayer, SimpleInfoState

include("CSCFR.jl")
export Game, Trainer, train!, other_player
export initialhist, isterminal, u, player, next_hist, infokey, actions

end # module
