"""
Complex quantities represent position, velocity etc in a plane.
They are a subset of quantities, although some function methods may
need extending outside T<:Real

"""
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