function Games.observation(game::Kuhn, h, a::SVector{2,Int}, h′)
    return (a[1], a[2])
end

function Games.observation(game::Kuhn, h, a::Int, h′)
    return (a, a)
end

@testset "tree building" begin
    game = Kuhn()
    game_sol = CFRSolver(game)
    game_cb = CFR.ExploitabilityCallback(game_sol, 1_000)

    tree = GameTree(game)
    tree_sol = CFRSolver(tree)
    tree_cb = CFR.ExploitabilityCallback(tree_sol, 1_000)

    train!(game_sol, 1_000_000; cb=game_cb)
    train!(tree_sol, 1_000_000; cb=tree_cb)

    @test all(game_cb.hist.y .≈ tree_cb.hist.y)

    @test length(game_sol.I) == length(tree_sol.I)

    game_strats = [strategy(game_sol, infokey(game, n.h)) for n in tree.nodes]
    tree_strats = [strategy(tree_sol, n.infokey) for n in tree.nodes]

    diffs = zeros(length(game_strats))
    for i in eachindex(game_strats)
        diffs[i] = sum(abs, game_strats[i] .- tree_strats[i])
    end

    @test maximum(diffs) < 1e-2

    # ------------------------------------------------------------------

    game_sol = ESCFRSolver(game)
    game_cb = CFR.ExploitabilityCallback(game_sol, 1_000)

    tree = GameTree(game)
    tree_sol = ESCFRSolver(tree)
    tree_cb = CFR.ExploitabilityCallback(tree_sol, 1_000)

    train!(game_sol, 1_000_000; cb=game_cb)
    train!(tree_sol, 1_000_000; cb=tree_cb)

    @test length(game_sol.I) == length(tree_sol.I)

    game_strats = [strategy(game_sol, infokey(game, n.h)) for n in tree.nodes]
    tree_strats = [strategy(tree_sol, n.infokey) for n in tree.nodes]

    diffs = zeros(length(game_strats))
    for i in eachindex(game_strats)
        diffs[i] = sum(abs, game_strats[i] .- tree_strats[i])
    end

    @test last(tree_cb.hist.y) < 1e-2
    @test sum(diffs) / length(diffs) < 0.5

    # ------------------------------------------------------------------

    game_sol = OSCFRSolver(game)
    game_cb = CFR.ExploitabilityCallback(game_sol, 1_000)

    tree = GameTree(game)
    tree_sol = OSCFRSolver(tree)
    tree_cb = CFR.ExploitabilityCallback(tree_sol, 1_000)

    train!(game_sol, 1_000_000; cb=game_cb)
    train!(tree_sol, 1_000_000; cb=tree_cb)

    @test length(game_sol.I) == length(tree_sol.I)

    game_strats = [strategy(game_sol, infokey(game, n.h)) for n in tree.nodes]
    tree_strats = [strategy(tree_sol, n.infokey) for n in tree.nodes]

    diffs = zeros(length(game_strats))
    for i in eachindex(game_strats)
        diffs[i] = sum(abs, game_strats[i] .- tree_strats[i])
    end

    @test last(tree_cb.hist.y) < 1e-2
    @test sum(diffs) / length(diffs) < 0.5
end
