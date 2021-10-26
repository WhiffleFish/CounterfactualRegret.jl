abstract type Game{H,K} end

function initialhist end

function isterminal end

function u end

function player end

function chance_action end

function next_hist end

function infokey end

function actions end

function chance_actions end # Only necessary for Vanilla CFR

@inline other_player(i) = 3-i
