"""
Complex quantities represent position, velocity etc in a plane.
They are a subset of quantities, although some function methods may
need extending outside T<:Real
"""
const ComplexQuantity = Quantity{T} where {T<:Complex}
QuantityTuple(z::ComplexQuantity) = (real(z), imag(z))
ComplexQuantity(p::QuantityTuple) = p[1] + im * p[2]
+(p1::Point, shift::ComplexQuantity) = p1 + QuantityTuple(shift)
"""
    generate_complex_potential_source(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, massflowout = 1.0m³/s)

We find the velocity potential function of a source or sink by realizing that
´´´
    2π·r·u_r = q
       where u_r is radial velocity
             q is flow
        ↕
    u_r = q / (2π·r)
´´´
The velocity potential, ϕ, is the scalar function found by integrating
velocity along the velocity gradient. The sign and endpoint of the integration
can be defined as we want. With the limitation above:
´´´
    u_r  = ∇ϕ = δu / δr
    ⇑
    ϕ = ∫ q / (2πr) dr = q / (2πr) · ∫ 1 / r dr = q / (2πr) · ln(r)
´´´
"""
function generate_complex_potential_source(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, massflowout = 1.0m³/s)
    # Note: log means natural logarithm, not log10
    #
    # Note: natural logarithm of a quantity gives no meaning. We can drop the unit as long as we
    # use the scalar consistently.
    (p::ComplexQuantity) -> begin
        Δp = p - pos
        r = norm(Δp)
        massflowout ∙ log(r / m) / (2π)
    end
end
