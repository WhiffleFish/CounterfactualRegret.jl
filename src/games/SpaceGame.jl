using StaticArrays

const SpaceGameInfoState = Tuple{Int,Int} # (time, player)

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

HelloCFR.player(::SpaceGame, h::SpaceGameHist) = h.p

HelloCFR.actions(::SpaceGame, h::SpaceGameHist) = SA[:wait, :act]

function score(g::SpaceGame, h::SpaceGameHist, a)
    if h.mode_change
        return a == :act ? 1 : -1
    else
        return 0
    end
end


function HelloCFR.next_hist(g::SpaceGame, h::SpaceGameHist , a)
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

HelloCFR.isterminal(g::SpaceGame, h::SpaceGameHist) = h.t ≥ g.T || h.budget == 0

HelloCFR.initialhist(g::SpaceGame) = SpaceGameHist(1, 0, 0, g.budget, false)

HelloCFR.utility(::SpaceGame, i::Int, h::SpaceGameHist) = i == 2 ? h.score : -h.score

HelloCFR.infokey(::SpaceGame, h::SpaceGameHist) = (h.p, h.t)
