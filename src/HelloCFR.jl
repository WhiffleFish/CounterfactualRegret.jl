module HelloCFR

include("MatrixGames.jl")
export MatrixGame, MatrixPlayer, clear!, train_both!, train_one!

include("CFR.jl")
export SimpleIOGame, SimpleIOPlayer, SimpleInfoState

end # module
