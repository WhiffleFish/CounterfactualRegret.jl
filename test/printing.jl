@testset "Printing" begin
    io = IOBuffer()

    game = MatrixGame()
    sol = ESCFRSolver(game)
    train!(sol, 100_000)

    print(io, sol)
    @test String(take!(io)) isa String

    game = Kuhn()
    sol = ESCFRSolver(game)
    train!(sol, 1_000_000)

    print(io, sol)
    @test String(take!(io)) isa String

    # ----
    
    game = CoinToss()
    sol = CFRSolver(game)
    train!(sol, 10_000)
    print(io, sol)
    @test String(take!(io)) isa String
end
