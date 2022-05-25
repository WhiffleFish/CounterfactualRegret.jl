@testset "Plots" begin
    game = MatrixGame()

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
