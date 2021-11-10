using HelloCFR

game = SpaceGame(5,10)

solver = CFRSolver(game)
@time train!(solver, 1)


##
@profiler train!(solver, 10) recur=:flat

#=
Checking if history already explored takes a LONG time
`h::T ∈ v::Vector{T}` takes really long.
Consider changing to something like:
`h::T ∈ v::Set{T}` however it requires x to be immutable
=#
