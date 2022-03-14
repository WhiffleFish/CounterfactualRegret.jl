@testset "Extensive2Matrix" begin
    game = CFR.IIEMatrixGame()
    mat = Matrix(game)

    @test all(
        all(mat[i] .≈ game.R[i]) for i in eachindex(mat, game.R)
    )

    game = CFR.IIEMatrixGame([
        (rand(),rand()) ((rand(),rand()))
        (rand(),rand()) ((rand(),rand()))
    ])
    mat = Matrix(game)

    @test all(
        all(mat[i] .≈ game.R[i]) for i in eachindex(mat, game.R)
    )
end
