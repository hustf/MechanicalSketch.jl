

"""
    generate_complex_potential_source(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, massflowout = 1.0m²/s)
    -> f::Z->R

We find the velocity potential function of a source or sink by realizing that
´´´
    2π·r·u_r = q
       where u_r is radial velocity
             q is flow
        ↕
    u_r = q / (2π·r)
´´´
The velocity potential, ϕ, is the imaginary valued function found by integrating
velocity along the velocity gradient. The sign and endpoint of the integration
can be defined as we want. With the limitation above:
´´´
    u_r  = ∇ϕ = δu / δr
    ⇑
    ϕ = ∫ q / (2πr) dr = q / (2πr) · ∫ 1 / r dr = q / (2πr) · ln(r)
´´´
"""
function generate_complex_potential_source(; pos = complex(0.0, 0.0)m, massflowout = 1.0m²/s)
    # Note: log means natural logarithm, not log10
    #
    # Note: natural logarithm of a quantity gives no meaning. We can drop the unit as long as we
    # use the scalar consistently.
    @assert massflowout != zero(massflowout)
    # Would call this ϕ_s(p)
    (p::ComplexQuantity) -> begin
        Δp = p - pos
        r = hypot(Δp)
        massflowout ∙ log(r / oneunit(r)) / (2π)
    end
end

"""
    generate_complex_potential_vortex(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, vorticity= 1.0m²/s)
    -> f::Z->R

We find the velocity potential function of a vortex by realizing that velocity
´´´
    u_θ = K / r
       where u_θ is tangential velocity, i.e. length per time in the tangential direction.
             K is vorticity
             Γ = K / 2π  is circulation
´´´
The velocity potential, ϕ, is the scalar valued function found by integrating
velocity along the velocity gradient. The sign and endpoint of the integration
can be defined as we want. 
"""
function generate_complex_potential_vortex(; pos = complex(0.0, 0.0)m, vorticity = 1.0m²/s)
    # Would call this ϕ_v(p)
    (p::ComplexQuantity) -> begin
        Δp = p - pos
        Θ = -angle(Δp)
        vorticity ∙ Θ
    end
end



"""
quantities_at_pixels(CQ_to_Q;
    physwidth = 10.0m,
    physheight = 4.0m)
    → Q    A matrix of output quantitities
where
    CQ_to_Q: CQ  → Q     - a function
    other parameters define the points for which to evaluate CQ_to_Q
where
    CQ is a complex valued Quantity (a coordinate in a vector field, or a vector at a point)
    Q is a real valued Quantity
# TODO - is this practically the same as function_to_matrix, defined elsewhere?
# Consider using traits for complex arguments
"""
function quantities_at_pixels(CQ_to_Q;
    physwidth = 10.0m,
    physheight = 4.0m,
    centered = true)
    @error "quantities_at_pixels to be replaced by function_to matrix."
    xs, ys = x_y_iterators_at_pixels(;physwidth, physheight, centered)
    [CQ_to_Q(complex(x, y)) for y in ys, x in xs]
end

absolute_scale() = ColorSchemes.linear_grey_10_95_c0_n256
complex_arg0_scale() = ColorSchemes.linear_ternary_red_0_50_c52_n256





"Scale and move real values to fit in the closed interval 0.0 to 1.0, given minimum and maximum values in A"
normalize_datarange_real(mi, ma, A) = map(A) do x
    @assert ma != mi
    if isnan(x) || isinf(x)
        mi
    else
        (x - mi) / (ma - mi)
    end
end
"""
Scale and move the magnitude (modulus, absolute value) of complex values
to fit in the closed interval 0.0 to 1.0, without changing the argument (angle).
The argument of the minimum value(s) is lost, since the angle is undefined for zero.
"""
normalize_datarange_complex(mi, ma, A) = map(A) do x
    @assert ma != mi
    if isnan(x) || isinf(x)
        mi
    else
        θ = angle(x)
        r = (hypot(x) - mi) / (ma - mi)
        r * complex(cos(θ), sin(θ))
    end
end
"""
    normalize_datarange(A)

normalize the elements in matrix A from 0.0 to 1.0, type preserving type.
This includes complex values, in which case the magnitude is normalized.
"""
function normalize_datarange(A::AbstractArray{<:RealQuantity})
    # Minimum and maximum value
    mi, ma = lenient_min_max(A)
    normalize_datarange_real(mi, ma, A)
end
function normalize_datarange(A::AbstractArray{<:Real})
    # Minimum and maximum value
    mi, ma = lenient_min_max(A)
    normalize_datarange_real(mi, ma, A)
end
function normalize_datarange(A)
    # Minimum and maximum magnitude
    mi, ma = lenient_min_max(A)
    normalize_datarange_complex(mi, ma, A)
end


"""
    hue_from_complex_argument!(color_values, A)
    Changes the hue in collection color_values by roting based on complex arguments in A

Take a matrix of colors, modify elements of it by changing hue to be according to
the argument (polar angle) of a complex number

Ref. domain colouring, complex plane https://en.wikipedia.org/wiki/Domain_coloring
"""
function hue_from_complex_argument!(color_values, A)
    @assert length(A) == length(color_values)
    for i in 1:length(A) # Works for matrices also
        cqua = A[i]
        if !isnan(cqua) && !isinf(cqua)
            ang = angle(complex(cqua))rad
            col = color_values[i]
            if col != RGB(0.0, 0.0, 0.0)
                color_values[i] = rotate_hue(col, ang)
            end
        end
    end
end


"""
    color_matrix(qua::AbstractArray; normalize_data_range = true) -> RGBA

Map a collection of quantities to colors, transparent
pixels for NaN and Inf values.

# TODO adapt ColorLegend for this functionality?
"""
function color_matrix(qua::AbstractArray; normalize_data_range = true)
    @warn "color_matrix to be replaced"
    # Boolean collection, valid elements which should be opaque
    valid_element = map(x-> isnan(x) || isinf(x) ? false : true, qua)

     # Map value or magnitude to [0.0, 1.0], invalid elements are 1.0
    norm_real_values = hypot.(normalize_data_range ? normalize_datarange(qua) : qua)

    # Map [0.0, 1.0] to perceived luminosity color map
    color_values = if eltype(qua) <: RealQuantity || eltype(qua) <: Real
        get(absolute_scale(), norm_real_values)
    else
        # Complex quanitity
        get(complex_arg0_scale(), norm_real_values)
    end
    # If input is complex, adjust the hue
    if !(eltype(qua) <: RealQuantity || eltype(qua) <: Real)
        # Set hue from complex argument (angle)
        # while not changing perceived luminance
        hue_from_complex_argument!(color_values, qua)
    end

    # Add transparency for any invalid elements
    map(color_values, valid_element) do co, valid
        RGBA(ColorSchemes.red(co), ColorSchemes.green(co), ColorSchemes.blue(co), Float64(valid))
    end
end




