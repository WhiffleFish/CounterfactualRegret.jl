using StatsBase

function p1regret(a1::Int, a2::Int)
    actions = [1,2,3]
    max_regret = 0
    u = reward([a1,a2])[1]
    for a in actions
        r = reward([a,a2])[1] - u
        if r > max_regret
            max_regret = r
        end
    end
    return max_regret > 0 ? max_regret : 0
end

function p2regret(a1::Int, a2::Int)
    actions = [1,2,3]
    max_regret = 0
    u = reward([a1,a2])[2]
    for a in actions
        r = reward([a1,a])[2] - u
        if r > max_regret
            max_regret = r
        end
    end
    return max_regret > 0 ? max_regret : 0
end

regret_sum_1 = zeros(3)
regret_sum_2 = zeros(3)
σ_1 = [0.5,0.4,0.1]# fill(1/3,3)
σ_1_sum = zeros(3)
σ_2 = [0.5,0.4,0.1]#fill(1/3,3)
σ_2_sum = zeros(3)
p1_hist = Vector{Float64}[deepcopy(σ_1)]
p2_hist = Vector{Float64}[deepcopy(σ_2)]


# DRY
N = 1000
for i in 1:N
    s1 = sum(regret_sum_1)
    if s1 > 0
        σ_1 .= regret_sum_1 ./ s1
    else
        fill!(σ_1, 1/3)
    end
    σ_1_sum .+= σ_1

    s2 = sum(regret_sum_2)
    if s2 > 0
        σ_2 .= regret_sum_2 ./ s2
    else
        fill!(σ_2, 1/3)
    end
    σ_2_sum .+= σ_2

    push!(p1_hist, deepcopy(σ_1))
    push!(p2_hist, deepcopy(σ_2))

    a1 = sample(weights(σ_1))
    a2 = sample(weights(σ_2))

    p1_r = p1regret(a1, a2)
    p2_r = p2regret(a1, a2)

    regret_sum_1[a1] += p1_r
    regret_sum_2[a2] += p2_r
end

strat1 = sum(p1_hist)
strat1 ./= sum(strat1)

strat2 = sum(p2_hist)
strat2 ./= sum(strat2)

p1_hist
p2_hist

regret_sum_1
regret_sum_2
