RPS = SimpleIIGame([
    (0,0) (-1,1) (1,-1);
    (1,-1) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

RPS_NE_strat = fill(1/3,3)

@testset "CFR RPS Convergence" begin
    init_strategy = [0.1,0.2,0.7]
    p1 = SimpleIIPlayer(RPS, 1, copy(init_strategy))
    p2 = SimpleIIPlayer(RPS, 2, copy(init_strategy))
    train_both!(p1, p2, 100_000)
    p = plot(p1,p2, lw=2)
    title!(p, "CFR RPS NE")
    display(p)

    @test isapprox(p1.strategy, RPS_NE_strat, atol=0.01)
    @test isapprox(p2.strategy, RPS_NE_strat, atol=0.01)

    p1 = SimpleIIPlayer(RPS, 1, copy(init_strategy))
    p2 = SimpleIIPlayer(RPS, 2, copy(init_strategy))
    train_one!(p1, p2, 1_000)
    p = plot(p1,p2, lw=2)
    title!(p, "CFR RPS Exploitative")
    display(p)

    @test isapprox(p1.strategy, Float64[1,0,0], atol=0.01)
    @test p2.strategy == init_strategy
end


PD = SimpleIIGame([
    (-1,-1) (-3,0);
    (0,-3) (-2,-2)
])

PD_NE_strat = Float64[0,1]

@testset "CFR Prisoner's Dilemma" begin
    p1 = SimpleIIPlayer(PD, 1)
    p2 = SimpleIIPlayer(PD, 2)
    train_both!(p1,p2, 10_000)
    p = plot(p1,p2, lw=2)
    title!(p, "CFR Prisoner's Dilemma")
    display(p)

    @test isapprox(p1.strategy, PD_NE_strat, atol=0.01)
    @test isapprox(p2.strategy, PD_NE_strat, atol=0.01)
end
