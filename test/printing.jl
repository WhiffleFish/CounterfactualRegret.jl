@testset "Printing" begin
    io = IOBuffer()

    game = IIEMatrixGame()
    sol = ESCFRSolver(game)
    train!(sol, 100_000)

    print(io, sol)
    @test String(take!(io)) isa String

    game = Kuhn()
    sol = ESCFRSolver(game)
    train!(sol, 1_000_000)

    print(io, sol)
    @test String(take!(io)) isa String
end
