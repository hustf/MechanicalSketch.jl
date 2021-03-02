"""
Complex quantities represent position, velocity etc in a plane.
They are a subset of quantities, although some function methods may
need extending outside T<:Real

"""

# TODO improve this. We want to use promotion to define tuples with
# identical types.
# It might also be nice to use traits, so that we can dispatch on 
# 2d quantities.
#=
 dimensionality(T<:Real) = Val{1}()
....etc  d

There are propably examples in Julia base, for n-dimensional arrays.

 foo(x::T) where T = foo(dimensionality(T), x)
 foo(::Val{2}, x) = 

 angle(::Val{2}, x::{Quantity{<:Complex} })
 =#

const ComplexQuantity = Quantity{<:Complex}

const RealQuantity = Quantity{<:Real}
const VelocityTuple = Tuple{Velocity, Velocity}
const PositionTuple = Tuple{Length, Length}
const ForceTuple = Tuple{Force, Force}

const QuantityTuple = Tuple{Quantity, Quantity}
ComplexQuantity(p::QuantityTuple) = complex(p[1] , p[2])
QuantityTuple(z::ComplexQuantity) =  reim(z)

function string_polar_form(z::ComplexQuantity)
    strarg_r = string(round(unit(hypot(z)), hypot(z), digits = 3))
    strarg_θ = string(round(angle(z), digits = 3))
    strargument = strarg_r * "∙exp(" * strarg_θ * "im)"
end