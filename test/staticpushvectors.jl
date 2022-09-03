@testset "StaticPushVectors" begin
    spv1 = StaticPushVector{5, Int}(1,2,3,4)
    @test spv1.v[5] == -1
    @test_throws BoundsError spv1[5]
    @test length(spv1.v) == 5
    @test length(spv1) == 4 == spv1.len == only(size(spv1))
    spv2 = push(spv1, 5)
    @test length(spv2) == 5 == spv2.len == only(size(spv2))
    @test length(spv2.v) == 5

    spv3 = setindex(spv2, 5, 5)
    @test spv3[5] == 5

    ##

    spv = StaticPushVector{4}((1,2,3), 0)
    @test spv.v[4] == 0
    @test length(spv) == 3 == spv.len == only(size(spv))
    @test length(spv.v) == 4

    spv = StaticPushVector(SA[1,2,3], 2)
    @test length(spv) == 2 == spv.len == only(size(spv))
    @test length(spv.v) == 3

    ##
    @test SPV{5, Float64}[1,2,3] === StaticPushVector(SA[1.,2.,3.,-1.,-1.], 3)
    @test SPV{5}[1,2,3] === StaticPushVector(SA[1,2,3,-1,-1], 3)
end
