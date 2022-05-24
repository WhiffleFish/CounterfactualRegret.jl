@testset "Plots" begin

    ## RM Plotting
    game = MatrixGame([
        (0,0) (-1,1) (1,-1);
        (1,-1) (0,0) (-1,1);
        (-1,1) (1,-1) (0,0)
    ])

    p1 = player(game, 1, [0.2,0.3,0.5])
    p2 = player(game, 2, [0.2,0.3,0.5])
    train_both!(p1, p2, 100)

    l1 = length(p1.hist)
    l2 = length(first(p1.hist))
    mat = CFR.cumulative_strategies(p1)
    @test size(mat) == (l1, l2)

    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), p1,p2) ≠ nothing
    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), p1) ≠ nothing


    ## Matrix CFR Plotting

    game = SimpleIIGame([
        (0,0) (-1,1) (1,-1);
        (1,-1) (0,0) (-1,1);
        (-1,1) (1,-1) (0,0)
    ])

    p1 = player(game, 1, [0.2,0.3,0.5])
    p2 = player(game, 2, [0.2,0.3,0.5])
    train_both!(p1, p2, 100)

    l1 = length(p1.hist)
    l2 = length(first(p1.hist))
    mat = CFR.cumulative_strategies(p1)
    @test size(mat) == (l1, l2)

    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), p1,p2) ≠ nothing
    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), p1) ≠ nothing


    ## CFR plotting

    game = IIEMatrixGame()

    sol = CFRSolver(game; debug=true)
    train!(sol, 100)

    hist = sol.I[0].hist
    l1 = length(hist)
    l2 = length(first(hist))
    mat = Games.cumulative_strategies(hist)
    @test size(mat) == (l1, l2)

    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), sol) ≠ nothing
    @test RecipesBase.apply_recipe(Dict{Symbol,Any}(), sol.I[0]) ≠ nothing
end
