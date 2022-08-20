struct Vanilla end

Base.@kwdef struct Plus
    d::Float64 = 0 
end

Base.@kwdef struct Discount
    α::Float64 = 1.0
    β::Float64 = 1.0
    γ::Float64 = 1.0
end