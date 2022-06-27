
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

struct ZeroBaseline end

(::ZeroBaseline)(I, l::Integer) = FillVec(0.0, l)

update!(::ZeroBaseline, I, û) = 0.0

# ----------------------------------------

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
