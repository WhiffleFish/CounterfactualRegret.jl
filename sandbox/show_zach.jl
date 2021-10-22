using HelloCFR, Plots

## Validating RPS outcome
mat_game = SimpleIOGame([
    (0,0) (-1,1) (1,-1);
    (10,-10) (0,0) (-1,1);
    (-1,1) (1,-1) (0,0)
])

p1 = SimpleIOPlayer(mat_game,1, [0.1,0.2,0.7])
p2 = SimpleIOPlayer(mat_game,2, [0.1,0.2,0.7])

train_both!(p1,p2,100000)

plot(p1,p2)

mat_σ1 = p1.strategy
mat_σ2 = p2.strategy

evaluate(p1,p2)

include(joinpath(@__DIR__, "RPS.jl"))

game = RPS(mat_game.R)

trainer = Trainer(game)

train!(trainer, 100_000)

e1,e2 = evaluate(trainer,100)
trainer.I

extensive_σ1,extensive_σ2 = deepcopy(trainer.I[0].s), deepcopy(trainer.I[1].s)
extensive_σ1 ./= sum(extensive_σ1)
extensive_σ2 ./= sum(extensive_σ2)

@show extensive_σ1
@show mat_σ1
println()
@show extensive_σ2
@show mat_σ2

## Kuhn Poker result
include(joinpath(@__DIR__, "Kuhn.jl"))

function print(trainer::Trainer)
    println("\n\n")
    for (k,v) in trainer.I
        h = k[3]
        h_n = string.(h)
        while length(h_n) < 3
            push!(h_n, "_")
        end
        σ = deepcopy(v.s)
        σ ./= sum(σ)
        σ = round.(σ, digits=3)
        println("Player: $(k[1]) \t Card: $(k[2]) \t h: $(join(h_n)) \t σ: $σ")
    end
end

game = Kuhn()

trainer = Trainer(game)

train!(trainer, 100_000)

evaluate(trainer, 1_000_000)

evaluate(trainer, 1_000_000)

print(trainer)
