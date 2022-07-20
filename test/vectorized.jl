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
    h = next_hist(game, h0, first(chance_actions(game, h0)))
    I = infokey(game, h)
    @test vectorized_hist(game, h) isa AbstractVector
    @test vectorized_info(game, I) isa AbstractVector
end
