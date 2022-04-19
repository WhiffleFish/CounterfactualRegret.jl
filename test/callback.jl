@testset "callback" begin
    # Exploitability Callback
    game = CFR.Kuhn()
    sol = CFRSolver(game)
    cb = CFR.ExploitabilityCallback(sol, 100)
    train!(sol, 100_000, cb = cb)

    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), cb) ≠ nothing
    @test length(cb.hist.y) == length(cb.hist.x) == 1_000
    @test 0.0 < last(cb.hist.y) < 1e-2

    game = CFR.IIEMatrixGame([(randn(), randn()) for i in 1:5, j in 1:5])
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
end
