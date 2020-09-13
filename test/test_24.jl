import MechanicalSketch
import MechanicalSketch: @import_expand
import MechanicalSketch.TypedFunction
import MechanicalSketch.generate_complex_potential_vortex
import MechanicalSketch.Quantity

if !@isdefined m²
    @import_expand m
    @import_expand s
end
g(z, x::Int, y::Int) = x + z#
g(z, x::Int, y::Int) = x + y#
g(x::Int, y::Float64) = x + y
g(x::Int) = x
g() = 2
g(x::T,y::T) where T = 1
g(x::Task) = (1,2)
g(x::AbstractVector) = ()

g(2, 3.0)

tf1 = TypedFunction(g, (Int, Float64), Float64)
tf1(2, 3.0)

tf1

g(2)
tf2 = TypedFunction(g, (Int), (Int))
tf2(2)

tf1

g()
tf3 = TypedFunction(g, (), (Int))
tf3()

tf1

g(2.0, 3.0)

# The following changes tf1! How? Revise?
# tf1 is just a reference to that method.
# It would perhaps be prudent to not pick f(x::T,y::T), since

@Juno.enter TypedFunction(f, (Float64, Float64), (Int))
tf4 = TypedFunction(g, (Float64, Float64), (Int))
tf1

tf4(2.0, 3.0)

tf1

f(@async 1+1)
tf5 = TypedFunction(f, (Task), (Int,Int))
tf5(@async 1+1)

tf1

f([2,3])
tf6 = TypedFunction(f, (AbstractVector), ())
tf6([2,3])

tf1

tf1 isa TypedFunction{T, I, O} where {T, I, O}
tf1 isa TypedFunction{T, I, O} where {T, I, O <: Number}
tf1 isa TypedFunction{T, I, O} where {T, I <: Tuple{Number, Float64}, O <: Number}
g(f::TypedFunction{T, I, O}) where {T, I <: Tuple{Number, Float64}, O <: Number} = 1
g(f::TypedFunction{T, I, O}) where {T, I <: Tuple{Number}, O <:Number} = 2
g(f::TypedFunction{T, I, O}) where {T, I <: Tuple{}, O <: Int} = 3

@assert g(tf1) == 1
@assert g(tf2) == 2
@assert g(tf3) == 3

match_signature(f, (Float64,Int,Int), (Float64),false)

match_signature(abs,(Int),(Int),false)

foo(x) = "Unknown type"
foo(x::Float64) = "Float64"
foo(x::Complex) = "Complex"
foo(x::Quantity) = "Quantity"
foo(x::Quantity{Float64}) = "Quantity{Float64}"
foo(x::Quantity<:Complex) = "Quantity{<:Complex}"
foo(x::Quantity{Complex{Float64}}) = "Quantity{Complex{Float64}}"



foo(1)
foo(1.0)
foo(1+1im)
foo(1.0+1.0im)
foo(1m)
foo(1.0m)
foo((1.0+1.0im)m)

@enter generate_complex_potential_vortex()
import MechanicalSketch.generate_complex_potential_source
import MechanicalSketch.generate_complex_potential_vortex
ϕ_source =  generate_complex_potential_source()
ϕ_vortex =  generate_complex_potential_vortex()

MechanicalSketch.generate_CF_to_QF()




ϕ_vortex(complex(1.0m, 0.1m))
typeof(complex(1.0m, 0.1m))
ϕ = TypedFunction(ϕ_vortex , typeof(complex(1.0m, 0.1m)), typeof(1.0m²/s))
