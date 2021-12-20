struct TerminalCache
    v1::Vector{Vector{Int}}
    v2::Vector{Vector{Vector{Int}}}
    v3::Vector{Vector{Int}}
end

function TerminalCache(term::Matrix{Vector{Int}})
    v1 = vec(term)
    v2 = [term[i,:] for i in 1:size(term,1)]
    v3 = [[0,0]]

    return TerminalCache(v1,v2,v3)
end

Base.getindex(tc::TerminalCache) = tc.v1
Base.getindex(tc::TerminalCache, i::Int) = tc.v2[i]
function Base.getindex(tc::TerminalCache, i::Int, j::Int)
    tc.v3[1][1] = i
    tc.v3[1][2] = j
    return tc.v3
end

function Base.getindex(tc::TerminalCache, v)
    if length(v) === 0
        return tc[]
    elseif length(v) === 1
        return tc[v[1]]
    else
        return tc[v[1], v[2]]
    end
end
