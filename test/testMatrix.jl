RPS = MatrixGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

RPS_NE_strat = fill(1/3,3)

@testset "RM RPS Convergence" begin
    init_strategy = [0.1,0.2,0.7]
    p1 = MatrixPlayer(RPS, 1, copy(init_strategy))
    p2 = MatrixPlayer(RPS, 2, copy(init_strategy))
    train_both!(p1, p2, 100_000)
    p = plot(p1,p2, lw=2)
    title!(p, "RM RPS NE")
    display(p)

    @test isapprox(p1.strategy, RPS_NE_strat, atol=0.01)
    @test isapprox(p2.strategy, RPS_NE_strat, atol=0.01)

    p1 = MatrixPlayer(RPS, 1, copy(init_strategy))
    p2 = MatrixPlayer(RPS, 2, copy(init_strategy))
    train_one!(p1, p2, 1_000)
    p = plot(p1,p2, lw=2)
    title!(p, "RM RPS Exploitative")
    display(p)

    @test isapprox(p1.strategy, Float64[1,0,0], atol=0.01)
    @test p2.strategy == init_strategy
end


PD = MatrixGame([
    (-1,-1) (-3,0);
    (0,-3) (-2,-2)
])

PD_NE_strat = Float64[0,1]

@testset "RM Prisoner's Dilemma" begin
    p1 = MatrixPlayer(PD, 1)
    p2 = MatrixPlayer(PD, 2)
    train_both!(p1,p2, 10_000)
    p = plot(p1,p2, lw=2)
    title!(p, "RM Prisoner's Dilemma")
    display(p)

    @test isapprox(p1.strategy, PD_NE_strat, atol=0.01)
    @test isapprox(p2.strategy, PD_NE_strat, atol=0.01)
end
