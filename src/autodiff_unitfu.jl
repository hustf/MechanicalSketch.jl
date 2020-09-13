"""
Input:
    f: CQ  → Q
Output:
    f: Q²  → Q
where
    Q = Quantity
    CQ = ComplexQuantity
    Q² = Vector{Quantity{T, D, U}} where {T, D, U})
"""
function generate_Q²_to_Q_from_CQ_to_Q(CQ_to_Q)
    (p::Vector{Quantity{T, D, U}} where {T, D, U}) -> begin
        CQ_to_Q(complex(p[1], p[2]))
    end
end

"""
Input:
    f: Q²  → Q, one_q_in::Quantity
Output:
    f: R²  → Q
where
    Q = Quantity
    Q² = Vector{Quantity{T, D, U}} where {T, D, U})
    R² = Vector{<:Real}
"""
function generate_R²_to_Q_from_Q²_to_Q(Q²_to_Q, one_q_in::Quantity)
    (p::Vector{<:Real}) -> begin
        Q²_to_Q(p∙one_q_in)
    end
end

"""
Input:
    f: R²  → Q
Output:
    f: R²  → R
where
    Q = Quantity
    R² = Vector
"""
function generate_R²_to_R_from_R²_to_Q(R²_to_Q)
    (p::Vector{<:Real})-> begin
        R²_to_Q(p) / oneunit(R²_to_Q(p))
    end
end

"""
Input:
    f: CQ  → Q, one_q_in
Output:
    f: R²  → R
where
    Q = Quantity
    CQ = ComplexQuantity
    R² = Vector{<:Real}
"""

function gradient_real_in_CQ_out(R²_to_R, ulxy, one_q_out)
    chnk = ForwardDiff.Chunk{2}()
    cfg = ForwardDiff.GradientConfig(R²_to_R, ulxy[1,1], chnk)
    #D = ForwardDiff.DiffResults.DiffResult()
    # 398 ms, 336Mb
    out = similar(ulxy)
    map(ulxy) do ul
        r² = ForwardDiff.gradient(R²_to_R, ul, cfg, Val{false}())::Vector{Float64}
        complex(r²[1]*one_q_out, r²[2]∙one_q_out)
    end
end
function gradient_quantities(CQ_to_Q, xyq::Array{Vector{S}}) where {S<:Quantity{T}} where T
    # 362 ms, 316 Mb
    # 334 ms, 316 Mb
    q_in_first = complex(xyq[firstindex(xyq)]...)
    one_q_in = oneunit(eltype(xyq[firstindex(xyq)]))
    one_q_value = oneunit(CQ_to_Q(q_in_first))
    typeout = typeof(one_q_value / one_q_in)
    typecout = typeof(complex(one_q_value / one_q_in, one_q_value / one_q_in))
    ulxy = xyq / one_q_in

    #389.962 ms (3803545 allocations: 316.44 MiB)
    Q²_to_Q = generate_Q²_to_Q_from_CQ_to_Q(CQ_to_Q)
    R²_to_Q = generate_R²_to_Q_from_Q²_to_Q(Q²_to_Q, one_q_in)
    R²_to_R = generate_R²_to_R_from_R²_to_Q(R²_to_Q)
    # 394 ms due to T
    # 340 ms
    #map(gradient_real_in_out(R²_to_R, ulxy)) do (x, y)
    #    complex(x,y)∙one_q_value
    #end
    # 334 ms, 312 Mb
    
    gradient_real_in_CQ_out(R²_to_R, ulxy, one_q_value / one_q_in )
end

function gradient_complex_quantity_in(CQ_to_Q;
    physwidth = 20.0,
    width_relative_screen = 2.0 / 3,
    height_relative_width = 1.0 / 3)

    physheight = physwidth * height_relative_width

    # Discretize per pixel
    nx = round(Int64, W * width_relative_screen)
    ny = round(Int64, nx * height_relative_width)
    # Iterators for each pixel relative to the center, O
    pixiterx = (1 - div(nx + 1, 2):(nx - div(nx, 2)))
    pixitery = (1 - div(ny + 1, 2):(ny - div(ny, 2)))

    # Matrix of 2-element vectors, one per pixel
    xyq = [[ix * SCALEDIST, -iy * SCALEDIST] for iy = pixitery, ix = pixiterx]
    gradient_quantities(CQ_to_Q, xyq)
end
