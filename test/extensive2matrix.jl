@testset "Extensive2Matrix" begin
    game = MatrixGame()
    mat = Matrix(game)

    @test all(
        all(mat[i] .≈ game.R[i]) for i in eachindex(mat, game.R)
    )

    game = MatrixGame([
        (rand(),rand()) ((rand(),rand()))
        (rand(),rand()) ((rand(),rand()))
    ])
    mat = Matrix(game)

    @test all(
        all(mat[i] .≈ game.R[i]) for i in eachindex(mat, game.R)
    )
end
