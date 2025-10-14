CFR.randpdf(p) = randpdf(Random.default_rng(), p)
CFR.randpdf(rng::Random.AbstractRNG, p::POMDPTools.Uniform) = rand(rng, p), inv(length(p.set))
CFR.randpdf(rng::Random.AbstractRNG, p::POMDPTools.UnsafeUniform) = rand(rng, p), inv(length(p.collection))
CFR.randpdf(rng::Random.AbstractRNG, p::POMDPTools.Deterministic) = p.val, 1.0

function CFR.randpdf(rng::AbstractRNG, d::POMDPTools.SparseCat)
    r = sum(d.probs)*rand(rng)
    tot = zero(eltype(d.probs))
    for (v, p) in d
        tot += p
        if r < tot
            return v, p
        end
    end
    if sum(d.probs) ≤ 0.0
        error("""
              Tried to sample from a SparseCat distribution with probabilities that sum to $(sum(d.probs)).

              vals = $(d.vals)

              probs = $(d.probs)
              """)
    end
    error("Error sampling from SparseCat distribution with vals $(d.vals) and probs $(d.probs)") # try to help with type stability
end
