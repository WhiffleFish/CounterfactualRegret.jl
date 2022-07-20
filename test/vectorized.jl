@testset "vectorized" begin
    game = MatrixGame()
    h0 = initialhist(game)
    I0 = infokey(game, h0)
    @test vectorized_hist(game, h0) isa AbstractVector
    @test vectorized_info(game, I0) isa AbstractVector

    game = Kuhn()
    h0 = initialhist(game)
    h = next_hist(game, h0, first(chance_actions(game, h0)))
    I = infokey(game, h)
    @test vectorized_hist(game, h) isa AbstractVector
    @test vectorized_info(game, I) isa AbstractVector

    game = CoinToss()
    h0 = initialhist(game)
    h1 = next_hist(game, h0, first(chance_actions(game, h0)))
    h2 = next_hist(game, h0, last(chance_actions(game, h0)))
    I1 = infokey(game, h1)
    I2 = infokey(game, h2)
    @test vectorized_hist(game, h1) isa AbstractVector
    @test vectorized_info(game, I1) isa AbstractVector
    @test vectorized_hist(game, h2) isa AbstractVector
    @test vectorized_info(game, I2) isa AbstractVector

    # check default behavior
    struct VecGameTest <: CFR.Game{SVector{2,Int}, SVector{1,Int}} end
    h = CFR.initialhist(::VecGameTest) = SA[1,2]
    I = CFR.infokey(::VecGameTest, h) = SA[first(h)]
    @test vectorized_hist(game, h) === h
    @test vectorized_info(game, I) === I
end
