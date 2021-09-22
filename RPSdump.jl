include("RPS.jl")

I0 =  [Int[]]
I1 = [Int[1], Int[2], Int[3]]

player1_strat = [0.50, 0.25, 0.25]
player2_strat = [0.50, 0.25, 0.25]

function train(player1_strat, player2_strat, N::Int)
    σ = (player1_strat, player2_strat)
    strat_hist = [σ]
    for i in 2:N
        update_strategies((I0,I1), strat_hist)
    end
    return strat_hist
end

strat_hist = train(player1_strat, player2_strat, 500)
plot_strats(strat_hist)

##
for i in 2:100
    update_strategy(1, I0, strat_hist)
    σ′ = update_strategy(2, I1, strat_hist[1:end-1])
    strat_hist[end][2] .= σ′[2]
end
