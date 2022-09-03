"""
    StaticPushVector{N,T}(x1, x2, x3, ...)
    StaticPushVector{N}(v::Union{NTuple,SVector}, fill_val)

Create `StaticPushVector` of eltype `T` and total length `N
"""
struct StaticPushVector{N,T} <: AbstractVector{T}
    v::SVector{N,T}
    len::Int

    # FIXME: weird and clunky? Maybe???
    # code_wantype seems weirdly clean though??????
    function StaticPushVector{N1,T}(args::Vararg{Any,N2}) where {N1, N2, T}
        remaining = N1 - N2
        return new{N1,T}(
            SVector{N1,T}(args..., @SVector(fill(-one(T),remaining))...),
            N2
        )
    end
    function StaticPushVector{N1}(tup::Union{NTuple{N2, T}, SVector{N2, T}}, fill_val=-one(T)) where {N1, N2, T}
        remaining = N1 - N2
        return new{N1,T}(
            SVector{N1,T}(tup..., @SVector(fill(fill_val,remaining))...),
            N2
        )
    end
    StaticPushVector(v::SVector{N,T},len::Int) where {N,T} = new{N,T}(v,len)
end

const SPV = StaticPushVector

Base.getindex(::Type{SPV{N,T}}, args...) where {N,T} = StaticPushVector{N,T}(args...)
Base.getindex(::Type{SPV{N}}, args::Vararg{T}) where {N,T} = StaticPushVector{N,T}(args...)

function StaticArrays.setindex(v::StaticPushVector, x, i)
    # @boundscheck checkbounds(v, i)
    return StaticPushVector(setindex(v.v, x, i), v.len)
end

function StaticArrays.push(v::StaticPushVector, x)
    v′ = setindex(v.v, x, v.len+1)
    return StaticPushVector(v′, v.len+1)
end

@inline Base.length(v::StaticPushVector) = v.len
@inline Base.size(v::StaticPushVector) = (v.len,)

function Base.getindex(v::StaticPushVector, i)
    @boundscheck checkbounds(v, i)
    @inbounds v.v[i]
end
