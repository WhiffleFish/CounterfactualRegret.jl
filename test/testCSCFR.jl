using HelloCFR
using Test
include(joinpath(@__DIR__,"..","src","games","Kuhn.jl"))
include(joinpath(@__DIR__,"..","src","games","IIEMatrix.jl"))

@testset "Matrix CSCFR" begin
    ## Rock Paper Scissors
    game = IIEMatrixGame([
        (0,0) (-1,1) (1,-1);
        (1,-1) (0,0) (-1,1);
        (-1,1) (1,-1) (0,0)
    ])
    trainer = Trainer(game)
    train!(trainer, 10_000)

    s1 = trainer.I[0].s
    s1 ./= sum(s1)
    @test ≈(s1, fill(1/3,3), rtol=0.001)

    s2 = trainer.I[1].s
    s2 ./= sum(s2)
    @test ≈(s2, fill(1/3,3), rtol=0.001)


    ## Prisoners Dilemma
    game = IIEMatrixGame([
        (-1,-1) (-3,0);
        (0,-3) (-2,-2)
    ])

    trainer = Trainer(game)
    train!(trainer, 10_000)

    s1 = trainer.I[0].s
    s1 ./= sum(s1)
    @test ≈(s1, [0,1], rtol=0.001)

    s2 = trainer.I[1].s
    s2 ./= sum(s2)
    @test ≈(s2, [0,1], rtol=0.001)
end

# https://upload.wikimedia.org/wikipedia/commons/a/a9/Kuhn_poker_tree.svg
@testset "Kuhn CSCFR" begin
    game = Kuhn()
    trainer = Trainer(game)
    train!(trainer, 1_000_000)

    s11__ = trainer.I[(1,1,Int[])].s
    s11__ ./= sum(s11__)
    α = s11__[2]
    @test 0 ≤ α ≤ 1/3
    s1200 = trainer.I[(1,2,Int[])].s
    s1200 ./= sum(s1200)
    @test ≈(s1200, [1,0], rtol=0.001)
    s1300 = trainer.I[(1,3,Int[])].s
    s1300 ./= sum(s1300)
    @test ≈(s1300, [1-3α,3α], rtol=0.001) # FAIL


    s210_ = trainer.I[(2,1,[0])].s
    s210_ ./= sum(s210_)
    @test ≈(s210_, [2/3,1/3], rtol=0.001) # FAIL
    s220_ = trainer.I[(2,2,[0])].s
    s220_ ./= sum(s220_)
    @test ≈(s220_, [1,0], rtol=0.001)
    s230_ = trainer.I[(2,3,[0])].s
    s230_ ./= sum(s230_)
    @test ≈(s230_, [0,1], rtol=0.001)


    s211_ = trainer.I[(2,1,[1])].s
    s211_ ./= sum(s211_)
    @test ≈(s211_, [1,0], rtol=0.001)
    s221_ = trainer.I[(2,2,[1])].s
    s221_ ./= sum(s221_)
    @test ≈(s221_, [2/3,1/3], rtol=0.001) # FAIL
    s231_ = trainer.I[(2,3,[1])].s
    s231_ ./= sum(s231_)
    @test ≈(s231_, [0,1], rtol=0.001)

    s1101 = trainer.I[(1,1,[0,1])].s
    s1101 ./= sum(s1101)
    @test ≈(s1101, [1,0], rtol=0.001)
    s1201 = trainer.I[(1,2,[0,1])].s
    s1201 ./= sum(s1201)
    @test ≈(s1201, [2/3-α,1/3+α], rtol=0.001) #FAIL
    s1301 = trainer.I[(1,3,[0,1])].s
    s1301 ./= sum(s1301)
    @test ≈(s1301, [0,1], rtol=0.001)
end
