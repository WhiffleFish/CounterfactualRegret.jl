function MatrixTest(game_type)
    ## RPS
    RPS = game_type([
        (0,0) (-1,1) (1,-1);
        (1,-1) (0,0) (-1,1);
        (-1,1) (1,-1) (0,0)
    ])
    init_strategy = [0.1,0.2,0.7]
    p1 = player(RPS, 1, init_strategy); p2 = player(RPS, 2, init_strategy)
    train_both!(p1, p2, 100_000)
    # p = plot(p1, p2, lw=2);
    # title!(p, "RM RPS NE")
    # display(p)

    RPS_NE_strat = fill(1/3,3)
    @test isapprox(p1.strategy, RPS_NE_strat, atol=0.01)
    @test isapprox(p2.strategy, RPS_NE_strat, atol=0.01)

    p1 = player(RPS, 1, init_strategy)
    p2 = player(RPS, 2, init_strategy)
    train_one!(p1, p2, 10_000)
    # p = plot(p1,p2, lw=2);
    # title!(p, "RM RPS Exploitative")
    # display(p)

    @test isapprox(p1.strategy, Float64[1,0,0], atol=0.01)
    @test p2.strategy == init_strategy


    ## Prisoners Dilemma
    PD = game_type([
        (-1,-1) (-3,0);
        (0,-3) (-2,-2)
    ])
    p1 = player(PD, 1)
    p2 = player(PD, 2)

    train_both!(p1,p2, 10_000)
    # p = plot(p1,p2, lw=2);
    # title!(p, "RM Prisoner's Dilemma")
    # display(p)

    PD_NE_strat = Float64[0,1]
    @test isapprox(p1.strategy, PD_NE_strat, atol=0.01)
    @test isapprox(p2.strategy, PD_NE_strat, atol=0.01)


    # https://sites.math.northwestern.edu/~clark/364/handouts/bimatrix-mixed.pdf
    game = game_type([
        (1,1) (0,0) (0,0);
        (0,0) (0,2) (3,0);
        (0,0) (2,0) (0,3);
    ])
    p1 = player(game, 1)
    p2 = player(game, 2)
    train_both!(p1,p2, 100_000)
    NEs = [[6/11,3/11,2/11], [0,3/5,2/5], [1,0,0]]
    s1 = p1.strategy; s2 = p2.strategy
    @test begin
        ≈(s1, NEs[1], atol=0.01) ||
        ≈(s1, NEs[2], atol=0.01) ||
        ≈(s1, NEs[3], atol=0.01)
    end
    @test begin
        ≈(s2, NEs[1], atol=0.01) ||
        ≈(s2, NEs[2], atol=0.01) ||
        ≈(s2, NEs[3], atol=0.01)
    end

    v = evaluate(p1,p2)
    @test begin
        all( .≈(v,(6/5,6/5), atol=0.01)) ||
        all( .≈(v,(6/11,6/11), atol=0.01)) ||
        all( .≈(v,(1,1), atol=0.01))
    end
end

@testset "RM Matrix" begin MatrixTest(MatrixGame) end

@testset "CFR Matrix" begin MatrixTest(SimpleIIGame) end
