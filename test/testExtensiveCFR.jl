using CounterfactualRegret: IIEMatrixGame, Kuhn

function CFRMatrixTest(sol_type, N::Int)
    ## Rock Paper Scissors
    game = IIEMatrixGame([
        (0,0) (-1,1) (1,-1);
        (1,-1) (0,0) (-1,1);
        (-1,1) (1,-1) (0,0)
    ])
    trainer = sol_type(game)
    train!(trainer, N)
    s1 = trainer.I[0].s
    s1 ./= sum(s1)
        @test ≈(s1, fill(1/3,3), atol=0.01)
    s2 = trainer.I[1].s
    s2 ./= sum(s2)
        @test ≈(s2, fill(1/3,3), atol=0.01)
    F_eval = FullEvaluate(trainer)
        @test all( .≈(F_eval,(0,0), atol=0.01))
    MC_eval = MonteCarloEvaluate(trainer,1)
        @test all( .≈(MC_eval,(0,0), atol=0.01))

    ## Prisoners Dilemma
    game = IIEMatrixGame([
        (-1,-1) (-3,0);
        (0,-3) (-2,-2)
    ])
    trainer = sol_type(game)
    train!(trainer, N)
    s1 = trainer.I[0].s
    s1 ./= sum(s1)
        @test ≈(s1, [0,1], atol=0.01)
    s2 = trainer.I[1].s
    s2 ./= sum(s2)
        @test ≈(s2, [0,1], atol=0.01)
    F_eval = FullEvaluate(trainer)
        @test all( .≈(F_eval,(-2,-2), atol=0.01))
    MC_eval = MonteCarloEvaluate(trainer,1)
        @test all( .≈(MC_eval,(-2,-2), atol=0.01))

    # https://sites.math.northwestern.edu/~clark/364/handouts/bimatrix-mixed.pdf
    game = CounterfactualRegret.IIEMatrixGame([
        (1,1) (0,0) (0,0);
        (0,0) (0,2) (3,0);
        (0,0) (2,0) (0,3);
    ])
    trainer = sol_type(game)
    train!(trainer, N)
    NEs = [[6/11,3/11,2/11], [0,3/5,2/5], [1,0,0]]
    s1 = trainer.I[0].s
    s1 ./= sum(s1)
        @test begin
            ≈(s1, NEs[1], atol=0.01) ||
            ≈(s1, NEs[2], atol=0.01) ||
            ≈(s1, NEs[3], atol=0.01)
        end
    s2 = trainer.I[1].s
    s2 ./= sum(s2)
        @test begin
            ≈(s2, NEs[1], atol=0.01) ||
            ≈(s2, NEs[2], atol=0.01) ||
            ≈(s2, NEs[3], atol=0.01)
        end
    F_eval = FullEvaluate(trainer)
    @test begin
        all( .≈(F_eval,(6/5,6/5), atol=0.01)) ||
        all( .≈(F_eval,(6/11,6/11), atol=0.01)) ||
        all( .≈(F_eval,(1,1), atol=0.01))
    end
    MC_eval = MonteCarloEvaluate(trainer,1)
    @test begin
        all( .≈(F_eval,(6/5,6/5), atol=0.01)) ||
        all( .≈(F_eval,(6/11,6/11), atol=0.01)) ||
        all( .≈(F_eval,(1,1), atol=0.01))
    end
end

function CFRKuhnTest(sol_type, N::Int, atol::Float64)
    game = Kuhn()
    trainer = sol_type(game)
    train!(trainer, N)

    s11__ = trainer.I[(1,1,SA[-1,-1,-1])].s
    s11__ ./= sum(s11__)
    α = s11__[2]
    @test 0 ≤ α ≤ 1/3
    s1200 = trainer.I[(1,2,SA[-1,-1,-1])].s
    s1200 ./= sum(s1200)
    @test ≈(s1200, [1,0], atol=atol)
    s1300 = trainer.I[(1,3,SA[-1,-1,-1])].s
    s1300 ./= sum(s1300)
    @test ≈(s1300, [1-3α,3α], atol=atol)


    s210_ = trainer.I[(2,1,SA[0,-1,-1])].s
    s210_ ./= sum(s210_)
    @test ≈(s210_, [2/3,1/3], atol=atol)
    s220_ = trainer.I[(2,2,SA[0,-1,-1])].s
    s220_ ./= sum(s220_)
    @test ≈(s220_, [1,0], atol=atol)
    s230_ = trainer.I[(2,3,SA[0,-1,-1])].s
    s230_ ./= sum(s230_)
    @test ≈(s230_, [0,1], atol=atol)


    s211_ = trainer.I[(2,1,SA[1,-1,-1])].s
    s211_ ./= sum(s211_)
    @test ≈(s211_, [1,0], atol=atol)
    s221_ = trainer.I[(2,2,SA[1,-1,-1])].s
    s221_ ./= sum(s221_)
    @test ≈(s221_, [2/3,1/3], atol=atol)
    s231_ = trainer.I[(2,3,SA[1,-1,-1])].s
    s231_ ./= sum(s231_)
    @test ≈(s231_, [0,1], atol=atol)

    s1101 = trainer.I[(1,1,SA[0,1,-1])].s
    s1101 ./= sum(s1101)
    @test ≈(s1101, [1,0], atol=atol)
    s1201 = trainer.I[(1,2,SA[0,1,-1])].s
    s1201 ./= sum(s1201)
    @test ≈(s1201, [2/3-α,1/3+α], atol=atol)
    s1301 = trainer.I[(1,3,SA[0,1,-1])].s
    s1301 ./= sum(s1301)
    @test ≈(s1301, [0,1], atol=atol)
end

@testset "IIE Solvers" begin
    @testset "CFR Matrix" begin CFRMatrixTest(CFRSolver, 100_000) end
    @testset "CFR Kuhn" begin CFRKuhnTest(CFRSolver, 100_000, 0.03) end

    @testset "CSCFR Matrix" begin CFRMatrixTest(CSCFRSolver, 100_000) end
    @testset "CSCFR Kuhn" begin CFRKuhnTest(CSCFRSolver, 1_000_000, 0.03) end

    @testset "DCFR Matrix" begin CFRMatrixTest(DCFRSolver, 100_000) end
    @testset "DCFR Kuhn" begin CFRKuhnTest(DCFRSolver, 200_000, 0.03) end

    @testset "ESCFR Matrix" begin CFRMatrixTest(ESCFRSolver, 500_000) end
    @testset "ESCFR Kuhn" begin CFRKuhnTest(ESCFRSolver, 1_000_000, 0.03) end
end
