function CFRMatrixTest(sol_type, N::Int; atol=0.01, debug=true, kwargs::NamedTuple=(;))
    ## Rock Paper Scissors
    game = MatrixGame([
        (0,0) (-1,1) (1,-1);
        (1,-1) (0,0) (-1,1);
        (-1,1) (1,-1) (0,0)
    ])
    sol = sol_type(game; kwargs...)
    train!(sol, N)
    s1 = sol.I[0].s
    s1 ./= sum(s1)
        @test ≈(s1, fill(1/3,3), atol=atol)
    s2 = sol.I[1].s
    s2 ./= sum(s2)
        @test ≈(s2, fill(1/3,3), atol=atol)
    F_eval = evaluate(sol)
        @test all( .≈(F_eval,(0,0), atol=atol))

    ## Prisoners Dilemma
    game = MatrixGame([
        (-1,-1) (-3,0);
        (0,-3) (-2,-2)
    ])
    sol = sol_type(game; kwargs...)
    train!(sol, N)
    s1 = sol.I[0].s
    s1 ./= sum(s1)
        @test ≈(s1, [0,1], atol=atol)
    s2 = sol.I[1].s
    s2 ./= sum(s2)
        @test ≈(s2, [0,1], atol=atol)
    F_eval = evaluate(sol)
        @test all( .≈(F_eval,(-2,-2), atol=atol))

    # https://sites.math.northwestern.edu/~clark/364/handouts/bimatrix-mixed.pdf
    game = MatrixGame([
        (1,1) (0,0) (0,0);
        (0,0) (0,2) (3,0);
        (0,0) (2,0) (0,3);
    ])
    sol = sol_type(game; kwargs...)
    train!(sol, N)
    NEs = [[6/11,3/11,2/11], [0,3/5,2/5], [1,0,0]]
    s1 = sol.I[0].s
    s1 ./= sum(s1)
        @test begin
            ≈(s1, NEs[1], atol=atol) ||
            ≈(s1, NEs[2], atol=atol) ||
            ≈(s1, NEs[3], atol=atol)
        end
    s2 = sol.I[1].s
    s2 ./= sum(s2)
        @test begin
            ≈(s2, NEs[1], atol=atol) ||
            ≈(s2, NEs[2], atol=atol) ||
            ≈(s2, NEs[3], atol=atol)
        end
    F_eval = evaluate(sol)
    @test begin
        all( .≈(F_eval,(6/5,6/5), atol=atol)) ||
        all( .≈(F_eval,(6/11,6/11), atol=atol)) ||
        all( .≈(F_eval,(1,1), atol=atol))
    end

    if debug
        sol = sol_type(game; debug=true, kwargs...)
        train!(sol, 100_000)

        @test CFR.infokeytype(sol) === Int
        @test CFR.histtype(game) === Games.MatHist{2}
    end
end

function CFRKuhnTest(sol_type, N::Int, atol::Float64; kwargs...)
    game = Kuhn()
    sol = sol_type(game; kwargs...)
    train!(sol, N)

    s11__ = sol.I[(1,1,SA[-1,-1,-1])].s
    s11__ ./= sum(s11__)
    α = s11__[2]
    @test 0 ≤ α ≤ 1/3
    s1200 = sol.I[(1,2,SA[-1,-1,-1])].s
    s1200 ./= sum(s1200)
    @test ≈(s1200, [1,0], atol=atol)
    s1300 = sol.I[(1,3,SA[-1,-1,-1])].s
    s1300 ./= sum(s1300)
    @test ≈(s1300, [1-3α,3α], atol=atol)


    s210_ = sol.I[(2,1,SA[0,-1,-1])].s
    s210_ ./= sum(s210_)
    @test ≈(s210_, [2/3,1/3], atol=atol)
    s220_ = sol.I[(2,2,SA[0,-1,-1])].s
    s220_ ./= sum(s220_)
    @test ≈(s220_, [1,0], atol=atol)
    s230_ = sol.I[(2,3,SA[0,-1,-1])].s
    s230_ ./= sum(s230_)
    @test ≈(s230_, [0,1], atol=atol)


    s211_ = sol.I[(2,1,SA[1,-1,-1])].s
    s211_ ./= sum(s211_)
    @test ≈(s211_, [1,0], atol=atol)
    s221_ = sol.I[(2,2,SA[1,-1,-1])].s
    s221_ ./= sum(s221_)
    @test ≈(s221_, [2/3,1/3], atol=atol)
    s231_ = sol.I[(2,3,SA[1,-1,-1])].s
    s231_ ./= sum(s231_)
    @test ≈(s231_, [0,1], atol=atol)

    s1101 = sol.I[(1,1,SA[0,1,-1])].s
    s1101 ./= sum(s1101)
    @test ≈(s1101, [1,0], atol=atol)
    s1201 = sol.I[(1,2,SA[0,1,-1])].s
    s1201 ./= sum(s1201)
    @test ≈(s1201, [2/3-α,1/3+α], atol=atol)
    s1301 = sol.I[(1,3,SA[0,1,-1])].s
    s1301 ./= sum(s1301)
    @test ≈(s1301, [0,1], atol=atol)
end

function KuhnExploitabilityTest(sol_type, N::Int, tol::Float64=1e-2; kwargs...)
    game = Kuhn()
    sol = sol_type(game; kwargs...)
    cb = CFR.ExploitabilityCallback(sol, 100)
    train!(sol, N, cb=cb)
    @test last(cb.hist.y) < tol
end

@testset verbose=true "IIE Solvers" begin
    @testset "CFR" begin
        @test_throws ErrorException CFRSolver(Kuhn(); method=:ayyylmao)
        CFRMatrixTest(CFRSolver, 100_000)
        CFRKuhnTest(CFRSolver, 100_000, 0.03)
        CFRKuhnTest(CFRSolver, 100_000, 0.03; method=:discount)
        CFRKuhnTest(CFRSolver, 100_000, 0.03; method=:plus)
    end

    @testset "CSCFR" begin
        @test_throws ErrorException CSCFRSolver(Kuhn(); method=:ayyylmao)
        CFRMatrixTest(CSCFRSolver, 100_000)
        CFRKuhnTest(CSCFRSolver, 1_000_000, 0.03)
        CFRKuhnTest(CSCFRSolver, 1_000_000, 0.03; method=:discount)
        CFRKuhnTest(CSCFRSolver, 1_000_000, 0.03; method=:plus)
    end

    @testset "ESCFR" begin
        @test_throws ErrorException ESCFRSolver(Kuhn(); method=:ayyylmao)
        CFRMatrixTest(ESCFRSolver, 500_000; debug=false)
        CFRKuhnTest(ESCFRSolver, 1_000_000, 0.03)
        CFRKuhnTest(ESCFRSolver, 1_000_000, 0.03; method=:discount)
        CFRKuhnTest(ESCFRSolver, 1_000_000, 0.03; method=:plus)
    end

    @testset "OSCFR" begin
        @test_throws ErrorException OSCFRSolver(Kuhn(); method=:ayyylmao)
        CFRMatrixTest(OSCFRSolver, 1_000_000; atol=0.05, debug=false)
        KuhnExploitabilityTest(OSCFRSolver, 1_000_000, 1e-2)
        KuhnExploitabilityTest(OSCFRSolver, 1_000_000, 1e-2; baseline=ExpectedValueBaseline(Kuhn()))
        KuhnExploitabilityTest(OSCFRSolver, 1_000_000, 1e-2; method=:discount)
        KuhnExploitabilityTest(OSCFRSolver, 1_000_000, 1.5e-2; method=:plus)
    end
end
