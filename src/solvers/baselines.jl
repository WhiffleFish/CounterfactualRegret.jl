"want simple vector-like behavior without allocating"
struct FillVec{T} <: AbstractVector{T}
    val::T
    len::Int
    FillVec(val, len) = new{typeof(val)}(val, Int(len))
end

@inline Base.length(v::FillVec) = v.len

@inline Base.size(v::FillVec) = (v.len,)

@inline function Base.getindex(v::FillVec, i)
    @boundscheck checkbounds(v, i)
    return v.val
end

"""
Default static baseline of 0 - equivalent to not using a baseline
"""
struct ZeroBaseline end

(::ZeroBaseline)(I, l::Integer) = FillVec(0.0, l)

update!(::ZeroBaseline, I, û) = 0.0

# ----------------------------------------

"""
Expected Value Baseline (Schmid 2018)

Uses aggregation counterfactual value estimates from previous runs as a
baseline. "Learning rate" or exponential decay rate for learning the baseline
is given by paramter α.

The stored action values for some information key `k` are retrieved by calling
`(b::ExpectedValueBaseline{K})(k, l)`, where `l` is the length of the action space
at the given information state represented by `k`.
"""
struct ExpectedValueBaseline{K}
    d::Dict{K,Vector{Float64}}
    α::Float64
end

function ExpectedValueBaseline(::Game{H,K}, α=0.5) where {H,K}
    return ExpectedValueBaseline(Dict{K,Vector{Float64}}(), α)
end

function (b::ExpectedValueBaseline{K})(I::K, l::Integer) where K
    return get!(b.d, I) do
        zeros(Float64, l)
    end
end

function update!(b::ExpectedValueBaseline{K}, I::K, û) where K
    (;α, d) = b
    û̄ = d[I]
    return @. û̄ = (1-α)*û̄ + α*û
end
