@testset "is-mcts" begin
    game = Kuhn()

    ## MaxUCB
    sol = CFRSolver(game)
    true_exploit_cb = ExploitabilityCallback(sol, 10)
    true_nashconv_cb= NashConvCallback(sol, 10)
    max_ucb_cb      = MCTSExploitabilityCallback(sol, 10; max_iter=100_000, criterion=CFR.MaxUCB())
    poly_ucb_cb     = MCTSExploitabilityCallback(sol, 10; max_iter=100_000, criterion=CFR.PolyUCB())
    max_q_cb        = MCTSExploitabilityCallback(sol, 10; max_iter=100_000, criterion=CFR.MaxQ())
    nashconv_cb     = MCTSNashConvCallback(sol, 10; max_iter=100_000)


    cb_chain = CFR.CallbackChain(true_exploit_cb, true_nashconv_cb, max_ucb_cb, poly_ucb_cb, max_q_cb, nashconv_cb)
    train!(sol, 100; cb=cb_chain)

    err_ucb = abs.(max_ucb_cb.hist.y .- true_exploit_cb.hist.y)
    err_poly = abs.(poly_ucb_cb.hist.y .- true_exploit_cb.hist.y)
    err_q = abs.(max_q_cb.hist.y .- true_exploit_cb.hist.y)

    err_nashconv = abs.(nashconv_cb.hist.y .- true_nashconv_cb.hist.y)

    @test all(err_ucb[2:end] .< 0.1)
    @test all(err_poly[2:end] .< 0.1)
    @test all(err_q[2:end] .< 0.2)
    @test all(err_nashconv[2:end] .< 0.2)
end
