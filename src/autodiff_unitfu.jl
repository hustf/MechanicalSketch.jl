"""
    generate_Q²_to_Q_from_CQ_to_Q(CQ_to_Q)
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
    generate_R²_to_Q_from_Q²_to_Q(Q²_to_Q, one_q_in::Quantity)
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
    generate_R²_to_R_from_R²_to_Q(R²_to_Q)
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
    ∇_R²_in_CQ_out(R²_to_R, ulxy, one_q_out::Quantity{T}) where {T}
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
        complex(r²[1] ∙ one_q_out, r²[2]∙one_q_out)
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
        cutoff = NaN,
        physwidth = 10.0m,
        physheight = 4.0m)
    → CQ²    A matrix of complex output quantitities, i.e. gradients with units.
where
    CQ_to_Q: CQ  → Q
    other parameters define the points for which to evaluate the gradient ∇ of function CQ_to_Q
where
    CQ is a complex valued Quantity (a coordinate in a vector field, or a vector at a point)
    Q is a real valued Quantity

Calculates the gradient given the extents of a rectangle and how they relate to screen pixels.

Optional argument cutoff: In case given, the magnitude (vector length) is limited to that
value without changing vector direction.

"""
function ∇_rectangle(CQ_to_Q;
    physwidth = 10.0m,
    physheight = 4.0m,
    cutoff = NaN)

    xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)

    # Matrix of 2-element static vectors, one per pixel
    xyq = [SA[x, y] for y in ys, x in xs]
    if isnan(cutoff)
        ∇_matrix(CQ_to_Q, xyq)
    else
        unclamped = ∇_matrix(CQ_to_Q, xyq)
        map(unclamped) do u
            hypot(u) > cutoff ? cutoff * u / hypot(u) : u
        end
    end
end

"""
    clamped_velocity_matrix(CQ_to_Q; physwidth = 1.0m, physheight = 1.0m, cutoff = 0.5m/s)

Input:
    CQ_to_Q: CQ  → Q   Function taking coordinates as a complex quantity, outputs a quantity
    physwidth
    physheight
    cutoff

Output:
    CQ²
where
    Q = Quantity
    CQ = ComplexQuantity, coordinates as a complex quantity
    CQ² = Matrix of complex quantitites, typically velocity vectors

Differentiates the complex potential function CQ_to_Q. Evaluates at pixels in a matrix corresponding to
physical dimensions and current sketch scale. Limits values to cutoff.
"""
function clamped_velocity_matrix(CQ_to_Q; physwidth = 1.0m, physheight = 1.0m, cutoff = 0.5m/s)
    unclamped = ∇_rectangle(CQ_to_Q; physwidth, physheight)
    map(unclamped) do u
        hypot(u) > cutoff ? cutoff∙u / hypot(u) : u
    end
end

"""
    ∇(f; physwidth, physheight)
    → derivative function (x, y) based on linear interpolation between pixels.

The values of the output function varies linearly between pixels. Take
care if differentiating twice!
"""
function ∇(f; physwidth = 10.0m, physheight = 4.0m)
    matrix_to_function(∇_rectangle(f; physwidth, physheight))
end