struct CFRPolicy{K,V}
    d::Dict{K,V}
end

function CFRPolicy(sol::AbstractCFRSolver)
    return CFRPolicy(Dict(
        Iterators.map(sol.I) do (k,I)
            k => I.s ./ sum(I.s)
        end
    ))
end

function update_policy!(p::CFRPolicy, sol::AbstractCFRSolver)
    (;d) = p
    for (k,I) ∈ sol.I
        σ = get!(d, k) do
            similar(I.s)
        end
        σ .= I.s ./ sum(I.s)
    end
    p
end

function strategy(p::CFRPolicy, k)
    return get(p.d, k) do
        v = similar(first(values(p.d)))
        v .= inv(length(v))
        v
    end
end
