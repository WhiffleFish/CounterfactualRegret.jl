using StatsBase

"""
Return regret vector over actions
"""
function p1regret(a1::Int, a2::Int)
    actions = [1,2,3]
    u = reward([a1,a2])[1]
    return [reward([a,a2])[1] - u for a in actions]
end

function p2regret(a1::Int, a2::Int)
    actions = [1,2,3]
    u = reward([a1,a2])[2]
    return [reward([a1,a])[2] - u for a in actions]
end

function p1regret(a1::Int, a2::Int)
    actions = [1,2,3]
    u = reward([a1,a2])[1]
    return [max(reward([a,a2])[1] - u,0) for a in actions]
end

function p2regret(a1::Int, a2::Int)
    actions = [1,2,3]
    u = reward([a1,a2])[2]
    return [max(reward([a1,a])[2] - u,0) for a in actions]
end

function fill_normed_regret!(v::Vector{Float64}, r::Vector)
    s = 0.0
    for (i,k) in enumerate(r)
        if k > 0
            s += k
            v[i] = k
        end
    end
    if s == 0
        fill!(v, 1/3)
    else
        v ./= s
    end
end

function normalized_regret_sum(r::Vector)
    new_vec = zeros(3)
    fill_normed_regret!(new_vec, r)
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
N = 10000
for i in 1:N
    fill_normed_regret!(σ_1, regret_sum_1)
    σ_1_sum .+= σ_1

    fill_normed_regret!(σ_2, regret_sum_2)
    σ_2_sum .+= σ_2

    push!(p1_hist, deepcopy(σ_1))
    push!(p2_hist, deepcopy(σ_2))

    a1 = sample(weights(σ_1))
    a2 = sample(weights(σ_2))

    p1_r = p1regret(a1, a2)
    p2_r = p2regret(a1, a2)

    regret_sum_1 += p1_r
    regret_sum_2 += p2_r
end

strat1 = sum(p1_hist)
strat1 ./= sum(strat1)

strat2 = sum(p2_hist)
strat2 ./= sum(strat2)

strat_hist = [z for z in zip(p1_hist, p2_hist)]
plot_strats(strat_hist)
@show strat1
@show strat2

@show regret_sum_1
@show regret_sum_2
