struct FLSynapseParameter
end

@snn_kw mutable struct FLSynapse{MFT=Matrix{Float32},VFT=Vector{Float32},FT=Float32}
    param::FLSynapseParameter = FLSynapseParameter()
    W::MFT  # synaptic weight
    rI::VFT # postsynaptic rate
    rJ::VFT # presynaptic rate
    g::VFT  # postsynaptic conductance
    P::MFT  # <rᵢrⱼ>⁻¹
    q::VFT  # P * r
    u::VFT # force weight
    w::VFT # output weight
    f::FT = 0 # postsynaptic traget
    z::FT = 0.5randn()  # output z ≈ f
    records::Dict = Dict()
end

function FLSynapse(pre, post; σ = 1.5, p = 0.0, α = 1, kwargs...)
    rI, rJ, g = post.r, pre.r, post.g
    W = σ * 1 / √pre.N * randn(post.N, pre.N) # normalized recurrent weight
    w = 1 / √post.N * (2rand(post.N) .- 1) # initial output weight
    u = 2rand(post.N) .- 1 # initial force weight
    P = α * I(post.N) # initial inverse of C = <rr'>
    q = zeros(post.N)
    FLSynapse(;@symdict(W, rI, rJ, g, P, q, u, w)..., kwargs...)
end

function forward!(c::FLSynapse, param::FLSynapseParameter)
    z = dot(w, rI)
    BLAS.A_mul_B!(q, P, rJ)
    BLAS.A_mul_B!(g, W, rJ)
    BLAS.axpy!(z, u, g)
end

function plasticity!(c::FLSynapse, param::FLSynapseParameter, dt::Float32, t::Float32)
    C = 1 / (1 + dot(q, rI))
    BLAS.axpy!(C * (f - z), q, w)
    BLAS.ger!(-C, q, q, P)
end
