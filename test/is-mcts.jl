@testset "is-mcts" begin
    game = Kuhn()

    ## MaxUCB
    sol = CFRSolver(game)
    true_exploit_cb = ExploitabilityCallback(sol, 10)
    max_ucb_cb      = ExploitabilityCallback(ISMCTS(sol; max_iter=100_000, criterion=CFR.MaxUCB()), 10)
    poly_ucb_cb     = ExploitabilityCallback(ISMCTS(sol; max_iter=100_000, criterion=CFR.PolyUCB()), 10)
    max_q_cb        = ExploitabilityCallback(ISMCTS(sol; max_iter=100_000, criterion=CFR.MaxQ()), 10)

    cb_chain = CFR.CallbackChain(true_exploit_cb, max_ucb_cb, poly_ucb_cb, max_q_cb)
    train!(sol, 100; cb=cb_chain)

    err_ucb = abs.(max_ucb_cb.hist.y .- true_exploit_cb.hist.y)
    err_poly = abs.(poly_ucb_cb.hist.y .- true_exploit_cb.hist.y)
    err_q = abs.(max_q_cb.hist.y .- true_exploit_cb.hist.y)

    @test all(err_ucb[2:end] .< 0.1)
    @test all(err_poly[2:end] .< 0.1)
    @test all(err_q[2:end] .< 0.2)
end
