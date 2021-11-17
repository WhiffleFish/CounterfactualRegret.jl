using StaticArrays

const SpaceGameInfoState = NTuple{3,Int} # (player, time, budget)

struct SpaceGameHist
    p::Int # current player
    t::Int # current time step
    score::Int # score dependent on terminal history is clunky here
    budget::Int # How many more times can ground station scan
    mode_change::Bool # Did sat mode change on last turn
end

# Satellite is player 1
# Gound station is player 2
struct SpaceGame <: Game{SpaceGameHist, SpaceGameInfoState}
    budget::Int # How often can we look
    T::Int # Max simulation time steps
end

CounterfactualRegret.player(::SpaceGame, h::SpaceGameHist) = h.p

CounterfactualRegret.actions(::SpaceGame, h::SpaceGameHist) = SA[:wait, :act]

function score(g::SpaceGame, h::SpaceGameHist, a)
    dist_from_origin = min(h.t, g.T+1-h.t)
    s = g.T+1 - dist_from_origin
    if h.mode_change
        return a == :act ? s : -s
    else
        return 0
    end
end


function CounterfactualRegret.next_hist(g::SpaceGame, h::SpaceGameHist , a)
    if player(g,h) == 1
        return SpaceGameHist(2, h.t, h.score, h.budget, a == :act)
    else
        s = score(g,h,a)
        budget = h.budget
        a == :act && (budget -= 1)
        budget == 0 && (s -= (g.T - (h.t+1)))
        return SpaceGameHist(1, h.t+1, s, budget, false)
    end
end

CounterfactualRegret.isterminal(g::SpaceGame, h::SpaceGameHist) = h.t ≥ g.T || h.budget == 0

CounterfactualRegret.initialhist(g::SpaceGame) = SpaceGameHist(1, 0, 0, g.budget, false)

CounterfactualRegret.utility(::SpaceGame, i::Int, h::SpaceGameHist) = i == 2 ? h.score : -h.score

CounterfactualRegret.infokey(::SpaceGame, h::SpaceGameHist) = (h.p, h.t, h.p===2 ? h.budget : 0)
