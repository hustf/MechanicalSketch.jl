

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






