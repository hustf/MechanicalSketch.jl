"""
Input:
    f: CQ  → Q
Output:
    f: Q²  → Q
where
    Q = Quantity
    CQ = ComplexQuantity
    Q² = SVector{2, Quantity{T, D, U}} where {T <: Real, D, U})
"""
function generate_Q²_to_Q_from_CQ_to_Q(CQ_to_Q)
    function λ1(p::SVector{2, Quantity{T, D, U}}) where {T, D, U}
        CQ_to_Q(complex(p[1], p[2]))::Quantity{T}
    end
end

"""
Input:
    f: Q²  → Q, one_q_in::Quantity
Output:
    f: R²  → Q
where
    Q = Quantity
    Q² = SVector{2, Quantity{T, D, U}} where {T <: Real, D, U})
    R² = SVector{2, <:Real}
"""
function generate_R²_to_Q_from_Q²_to_Q(Q²_to_Q, one_q_in::Quantity)
    function λ2(p::SVector{2, T}) where {T}
        Q²_to_Q(p∙one_q_in)::Quantity{T}
    end
end

"""
Input:
    f: R²  → Q
Output:
    f: R²  → R
where
    Q = Quantity
    R² = SVector{2, <:Real}
    R  <: Real
"""
function generate_R²_to_R_from_R²_to_Q(R²_to_Q)
    function λ3(p::SVector{2, T}) where {T}
        q = R²_to_Q(p)
        (q / oneunit(q))::T
    end
end

"""
Input:
    f: R² → R, one_q_in
    ulxy:: R², all unitless coordinates for which we want the gradient
    one_q_out    One unit of the output quantity
Output:
    CQ²    A matrix of complex output quantitities, i.e. gradients with units.
where
    Q = Quantity{complex or dual}
    CQ = ComplexQuantity
    R² = Vector{<:Real}
"""
function ∇_R²_in_CQ_out(R²_to_R, ulxy, one_q_out::Quantity{T}) where {T}
    chnk = ForwardDiff.Chunk{2}()
    cfg = ForwardDiff.GradientConfig(R²_to_R, ulxy[1,1], chnk)
    # Note could be sped up using in-place evaluation, but would need to drop StaticArrays.
    map(ulxy) do ul
        r² = ForwardDiff.gradient(R²_to_R, ul, cfg, Val{false}())::SVector{2, T}
        complex(r²[1]*one_q_out, r²[2]∙one_q_out)
    end
end


"""
    ∇_matrix(CQ_to_Q, xyq::Array{SVector{2, R}} where {R<:Quantity{T}} where T
    → CQ²    A matrix of complex output quantitities, i.e. gradients with units.
where
    CQ_to_Q: CQ  → Q
    other parameters define the points for which to evaluate the gradient ∇ of function CQ_to_Q
where
    CQ is a complex valued Quantity (a coordinate in a vector field, or a vector at a point)
    Q is a real valued Quantity

Calculates the gradient given a matrix of coordinates. Coordinates are complex valued quantities.
Normally used by ∇_rectangle
"""
function ∇_matrix(CQ_to_Q, xyq::AbstractArray{SVector{2, R}}) where {R<:Quantity{T}} where T
    q_in_first = complex(first(xyq)[1], first(xyq)[2])
    one_q_in = oneunit(eltype(first(xyq)))
    one_q_value = oneunit(CQ_to_Q(q_in_first))
    ulxy = xyq / one_q_in
    # Make a wrapper function to make ForwardDiff work with complex quantities
    # Do it in several steps to make the compiler understand
    Q²_to_Q = generate_Q²_to_Q_from_CQ_to_Q(CQ_to_Q)
    R²_to_Q = generate_R²_to_Q_from_Q²_to_Q(Q²_to_Q, one_q_in)
    R²_to_R = generate_R²_to_R_from_R²_to_Q(R²_to_Q)
    # Take the gradient of real-valued, non-quantity functions and then add units again.
    ∇_R²_in_CQ_out(R²_to_R, ulxy, one_q_value / one_q_in )
end

"""
    ∇_rectangle(CQ_to_Q;
        physwidth = 20.0,
        width_relative_screen = 2.0 / 3,
        height_relative_width = 1.0 / 3)
    → CQ²    A matrix of complex output quantitities, i.e. gradients with units.
where
    CQ_to_Q: CQ  → Q
    other parameters define the points for which to evaluate the gradient ∇ of function CQ_to_Q
where
    CQ is a complex valued Quantity (a coordinate in a vector field, or a vector at a point)
    Q is a real valued Quantity

Calculates the gradient given the extents of a rectangle and how they relate to screen pixels.
"""
function ∇_rectangle(CQ_to_Q;
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

    # Matrix of 2-element static vectors, one per pixel
    xyq = [SA[ix * SCALEDIST, -iy * SCALEDIST] for iy = pixitery, ix = pixiterx]
    ∇_matrix(CQ_to_Q, xyq)
end
