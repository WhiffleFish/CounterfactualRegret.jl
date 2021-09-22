using Plots
const RPSHist = Vector{Int}

function reward(h::RPSHist)
    a1, a2 = h
    if a1 == a2
        return (0,0)
    elseif a1 === 1
        if a2 === 2
            return (-1,1)
        else
            return (1,-1)
        end
    elseif a1 === 2
        if a2 === 1
            return (1,-1)
        else
            return (-1,1)
        end
    else
        if a2 === 1
            return (-1,1)
        else
            return (1,-1)
        end
    end
end

const term = [[i,j] for i in [1,2,3], j in [1,2,3]]

player(h) = length(h) < 1 ? 1 : 2

function terminals(h)
    if length(h) == 0
        return term
    elseif length(h) == 1
        return [[h;k] for k in [1,2,3]]
    else
        return [h]
    end
end

terminal(h) = terminals
actions(h) = [1,2,3]

path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h′::RPSHist) = path_prob(σ,i,Int[], h′)
path_prob(σ::NTuple{2,Vector{Float64}}, h′::RPSHist) = path_prob(σ,Int[], h′)

function path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h::RPSHist, h′::RPSHist)
    if i < 0
        return neg_path_prob(σ, -i, h, h′)
    else
        return path_prob(σ[i], i, h, h′)
    end
end

function neg_path_prob(σ::NTuple{2,Vector{Float64}}, i::Int, h::RPSHist, h′::RPSHist)
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = h′[1:end-1]
        player_turn = player(h′)
        prob = (player_turn != i) ? σ[player_turn][act] : 1.0
        return prob*neg_path_prob(σ, i, h, h′)
    end
end

function path_prob(σ_i::Vector{Float64}, i::Int, h::RPSHist, h′::RPSHist)
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = h′[1:end-1]
        prob = (player(h′) == i) ? σ_i[act] : 1.0
        return prob*path_prob(σ_i, i, h, h′)
    end
end

function path_prob(σ::NTuple{2,Vector{Float64}}, h::RPSHist, h′::RPSHist)
    if h′ == h
        return 1.0
    else
        act = last(h′)
        h′ = h′[1:end-1]
        prob = σ[player(h′)][act]
        return prob*path_prob(σ, h, h′)
    end
end

function path_prob(σ::NTuple{2,Vector{Float64}}, I::Vector{RPSHist}, i::Int)
    sum(path_prob(σ, i, h) for h in I)
end

function u(i, h′::RPSHist)
    reward(h′)[i]
end

function u(i::Int, I::Vector{RPSHist}, σ::NTuple{2,Vector{Float64}})
    num = 0.0
    den = 0.0
    for h in I
        pi_I = path_prob(σ, -i, h)
        den += pi_I
        for h′ in terminals(h)
            num += pi_I*path_prob(σ,h,h′)*u(i,h′)
        end
    end
    return num/den
end

function u(i::Int, I::Vector{RPSHist}, a::Int, σ::NTuple{2,Vector{Float64}})
    num = 0.0
    den = 0.0
    for h in I
        h = [h;a] # what if it isn't the player's turn?
        pi_I = path_prob(σ, -i, h)
        den += pi_I
        for h′ in terminals(h)
            num += pi_I*path_prob(σ,h,h′)*u(i,h′)
        end
    end
    return num/den
end

function sub_regret(i::Int,I::Vector{RPSHist},σ::NTuple{2, Vector{Float64}},a::Int)
    path_prob(σ, -i, I)*(u(i,I,a,σ) - u(i, I, σ))
end

function immediate_regret(i::Int, I::Vector{RPSHist}, σ::NTuple{2, Vector{Float64}})
    # TODO: replace with `actions` call
    maximum(sub_regret(i,I,σ,a) for a in [1,2,3])
end

function update_strategy(i::Int, I::Vector{RPSHist},σ_vec::Vector{NTuple{2, Vector{Float64}}})
    σ′ = deepcopy(last(σ_vec))
    T = length(σ_vec)
    for a in [1,2,3]
        RT = sum(sub_regret(i,I,σ,a) for σ in σ_vec)/T
        RTp = max(RT,0)
        σ′[i][a] = RTp
    end
    s = sum(σ′[i])
    s == 0 ? fill!(σ′[i],1/3) : σ′[i] .= σ′[i] ./ s

    push!(σ_vec, σ′)
    return σ′
end

function update_strategies(Is::NTuple{2,Vector{RPSHist}},σ_vec::Vector{NTuple{2, Vector{Float64}}})
    σs = deepcopy(last(σ_vec)),deepcopy(last(σ_vec))
    T = length(σ_vec)
    for i in [1,2]
        for a in [1,2,3]
            RT = sum(sub_regret(i,Is[i],σ,a) for σ in σ_vec)/T
            RTp = max(RT,0)
            σs[i][i][a] = RTp
        end
        s = sum(σs[i][i])
        s == 0 ? fill!(σ[i][i],1/3) : σs[i][i] .= σs[i][i] ./ s
    end
    σ′ = (first(σs)[1],last(σs)[2])
    # append σ′ to list of strats
    push!(σ_vec, σ′)
    return σ′
end

function plot_strats(σ_vec::Vector{NTuple{2, Vector{Float64}}})
    d = Dict(1=>"rock", 2=>"paper", 3=>"scissors")
    p1 = plot()
    for i in 1:3
        plot!(p1, [σ_vec[j][1][i] for j in eachindex(σ_vec)], label=d[i])
    end
    p2 = plot()
    for i in 1:3
        plot!(p2, [σ_vec[j][2][i] for j in eachindex(σ_vec)], label="")
    end
    plot(p1, p2, layout= @layout [a b])
end
