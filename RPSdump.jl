include("RPS.jl")

I0 =  [Int[]]
I1 = [Int[1], Int[2], Int[3]]
u(1,I0,1,σ)
u(1,I0, σ)

update_strategy(1, I0, strat_hist)
update_strategy(2, I1, strat_hist)

player1_strat = [0.50, 0.25, 0.25]
player2_strat = [0.25, 0.50, 0.25]
# player1_strat = fill(1/3,3)
# player2_strat = fill(1/3,3)

σ = (player1_strat, player2_strat)
strat_hist = [σ]
for i in 2:500
    update_strategy(1, I0, strat_hist)
    σ′ = update_strategy(2, I1, strat_hist[1:end-1])
    strat_hist[end][2] .= σ′[2]
end

plot_strats(strat_hist)
u(2, [Int[1], Int[2], Int[3]], 3, σ)

path_prob(σ, -1, [Int[]])
sub_regret(1, [Int[]], σ, 3)
