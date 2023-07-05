@testset "callback" begin
    # Exploitability Callback
    game = Kuhn()
    sol = CFRSolver(game)
    cb = CFR.ExploitabilityCallback(sol, 100)
    train!(sol, 100_000, cb = cb)

    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), cb) ≠ nothing
    @test length(cb.hist.y) == length(cb.hist.x) == 1_000
    @test 0.0 < last(cb.hist.y) < 1e-2

    game = MatrixGame([(randn(), randn()) for i in 1:5, j in 1:5])
    sol = CFRSolver(game)
    cb = CFR.ExploitabilityCallback(sol, 100)
    train!(sol, 100_000, cb = cb)

    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), cb) ≠ nothing
    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), cb.hist) ≠ nothing
    @test 0.0 < last(cb.hist.y) < 1e-2
    @test length(cb.hist.y) == length(cb.hist.x) == 1_000

    ## Throttle
    sol = ESCFRSolver(game)
    io = IOBuffer()
    f = () -> println(io, length(sol.I))
    save_freq = 10
    train_iter = 101
    cb = CFR.Throttle(f,save_freq)
    train!(sol, train_iter, cb = cb)
    str = String(take!(io))
    @test length(split(str, "\n")) == div(train_iter, save_freq) + 2

    ## chain
    sol = ESCFRSolver(game)
    io = IOBuffer()
    g = () -> println(io, length(sol.I))
    save_freq = 10
    train_iter = 1001
    ecb = CFR.ExploitabilityCallback(sol, 100)
    cb = CFR.CallbackChain(ecb,  CFR.Throttle(g, save_freq))
    train!(sol, train_iter, cb = cb)

    str = String(take!(io))
    @test first(ecb.hist.y) > last(ecb.hist.y) > 0.0
    @test length(ecb.hist.y) == length(ecb.hist.x) == 11
    @test length(split(str, "\n")) == div(train_iter, save_freq) + 2

    ## ModelSaver
    game = Kuhn()
    save_dir = joinpath(pwd(), "checkpoints")
    sol = ESCFRSolver(game)
    cb = CFR.ModelSaverCallback(sol, 100; save_dir)
    train!(sol, 1000; cb)
    checkpoints = readdir(save_dir, join=true)
    @test length(checkpoints) == 10
    for checkpoint in checkpoints
        policy = CFR.load_model(checkpoint)
        @test policy isa CFR.CFRPolicy
    end

    policy = CFR.load_model(first(checkpoints))

    I = (2,1,KuhnActionHist(0))
    σ1 = strategy(policy, I)
    σ2 = strategy(sol, I)
    @test σ1 ≠ σ2
    CFR.update_policy!(policy, sol)
    @test strategy(policy, I) ≈ σ2
    rm(save_dir, recursive=true)
end
