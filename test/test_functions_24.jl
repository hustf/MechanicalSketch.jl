function restart(backcolor)
    empty_figure(joinpath(@__DIR__, "test_24.png"))
    background(backcolor)
    sethue(PALETTE[8])
end
"""
    prline_1(vx, vy)

This is not for use in the final algorithm, just for debugging.
Plots a polyline until NaN or end of vectors.
"""
function prline_1(origo, vx, vy)
    move(origo + (vx[1], vy[1]))
    for (x, y) in zip(vx, vy)
        isnan(x) && break
        isnan(y) && break
        line(origo + (x, y))
    end
    do_action(:stroke)
end

"""
    euler_step_complex_1!(f, vx, vy, h, n)

Coordinates (vx[n + 1], vy[n + 1]) are updated with the estimated position,
along function f.
     f is a complex-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size factor
"""
function euler_step_complex_1!(f, vx, vy, h, n)
    @assert length(vx) == length(vy)
    @assert n < length(vx)
    f0 = f(vx[n], vy[n])
    vx[n + 1] = vx[n] + real(f0) * h
    vy[n + 1] = vy[n] + imag(f0) * h
end
"""
    euler_forwardsteps_1!(f, vx, vy, h)

Coordinates (vx[n > 1], vy[n > 1]) are updated with the estimated positions,
along function f.
     f is a complex-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size factor
"""
function euler_forwardsteps_1!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    for n in 1:(length(vx) - 1)
        euler_step_complex_1!(f, vx, vy, h, n)
    end
end

"""
    rk4_step_complex_1!(f, vx, vy, h, n)

Coordinates (vx[n + 1], vy[n + 1]) are updated with the estimated position,
along function f.
     f is a complex-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size quantity. If the integration variable is time,
     it defines the length of time betweeen points.
"""
function rk4_step_complex_1!(f, vx, vy, h, n)
    @assert length(vx) == length(vy)
    @assert n < length(vx)
    f0 = f(vx[n], vy[n])
    x1 = vx[n] + real(f0) * h * 0.5
    y1 = vy[n] + imag(f0) * h * 0.5
    f1 = f(x1, y1)
    x2 = vx[n] + real(f1) * h * 0.5
    y2 = vy[n] + imag(f1) * h * 0.5
    f2 = f(x2, y2)
    x3 = vx[n] + real(f2) * h
    y3 = vy[n] + imag(f2) * h
    f3 = f(x3, y3)
    vx[n + 1] = vx[n] + 1/6 * h * real( f0  + 2∙f1 + 2∙f2 + f3 )
    vy[n + 1] = vy[n] + 1/6 * h * imag( f0  + 2∙f1 + 2∙f2 + f3 )
end

"""
    rrk4_forwardsteps_1!(f, vx, vy, h)


Coordinates (vx[n > 1], vy[n > 1]) are updated with the estimated positions,
along function f.
     f(x,y) returns a complex-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size quantity. If the integration variable is time,
     it defines the length of time betweeen points.
"""
function rrk4_forwardsteps_1!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    for n in 1:(length(vx) - 1)
        rk4_step_complex_1!(f, vx, vy, h, n)
    end
end
@inline function euler_step_complex_2!(f, vx, vy, h, n)
    @assert length(vx) == length(vy)
    @assert n < length(vx)
    f0 = f(vx[n], vy[n])
    vx[n + 1] = vx[n] + real(f0) * h
    vy[n + 1] = vy[n] + imag(f0) * h
end
@inline function rk4_step_complex_2!(f, vx, vy, h, n)
    @assert length(vx) == length(vy)
    @assert n < length(vx)
    f0 = f(vx[n], vy[n])
    x1 = vx[n] + real(f0) * h * 0.5
    y1 = vy[n] + imag(f0) * h * 0.5
    f1 = f(x1, y1)
    x2 = vx[n] + real(f1) * h * 0.5
    y2 = vy[n] + imag(f1) * h * 0.5
    f2 = f(x2, y2)
    x3 = vx[n] + real(f2) * h
    y3 = vy[n] + imag(f2) * h
    f3 = f(x3, y3)
    vx[n + 1] = vx[n] + 1/6 * h * real( f0  + 2∙f1 + 2∙f2 + f3 )
    vy[n + 1] = vy[n] + 1/6 * h * imag( f0  + 2∙f1 + 2∙f2 + f3 )
end
function euler_forwardsteps_2!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    for n in 1:(length(vx) - 1)
        euler_step_complex_2!(f, vx, vy, h, n)
    end
end
function rrk4_forwardsteps_2!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    for n in 1:(length(vx) - 1)
        rk4_step_complex_2!(f, vx, vy, h, n)
    end
end
# Inconclusive inlining for both . Redefine the inner functions without assertions

function euler_step_complex_3!(f, vx, vy, h, n)
    f0 = f(vx[n], vy[n])
    vx[n + 1] = vx[n] + real(f0) * h
    vy[n + 1] = vy[n] + imag(f0) * h
end
function rk4_step_complex_3!(f, vx, vy, h, n)
    f0 = f(vx[n], vy[n])
    x1 = vx[n] + real(f0) * h * 0.5
    y1 = vy[n] + imag(f0) * h * 0.5
    f1 = f(x1, y1)
    x2 = vx[n] + real(f1) * h * 0.5
    y2 = vy[n] + imag(f1) * h * 0.5
    f2 = f(x2, y2)
    x3 = vx[n] + real(f2) * h
    y3 = vy[n] + imag(f2) * h
    f3 = f(x3, y3)
    vx[n + 1] = vx[n] + 1/6 * h * real( f0  + 2∙f1 + 2∙f2 + f3 )
    vy[n + 1] = vy[n] + 1/6 * h * imag( f0  + 2∙f1 + 2∙f2 + f3 )
end
function euler_forwardsteps_3!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    for n in 1:(length(vx) - 1)
        euler_step_complex_3!(f, vx, vy, h, n)
    end
end
function rrk4_forwardsteps_3!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    for n in 1:(length(vx) - 1)
        rk4_step_complex_3!(f, vx, vy, h, n)
    end
end
# Removing inner assertions was infavourable for Euler, favourable for RK4.

# Redefine the outer functions too without assertions

function euler_forwardsteps_4!(f, vx, vy, h)
    for n in 1:(length(vx) - 1)
        euler_step_complex_3!(f, vx, vy, h, n)
    end
end
function rrk4_forwardsteps_4!(f, vx, vy, h)
    for n in 1:(length(vx) - 1)
        rk4_step_complex_3!(f, vx, vy, h, n)
    end
end

# Removing outer assertions was favourable for Euler, not for RK4.

# Proceed with the optimal versions so far.
# Use @fastmath


@fastmath function euler_step_complex_4!(f, vx, vy, h, n)
    @assert length(vx) == length(vy)
    @assert n < length(vx)
    @fastmath f0 = f(vx[n], vy[n])
    @fastmath vx[n + 1] = vx[n] + real(f0) * h
    @fastmath vy[n + 1] = vy[n] + imag(f0) * h
end
@fastmath function rk4_step_complex_4!(f, vx, vy, h, n)
    @fastmath f0 = f(vx[n], vy[n])
    @fastmath x1 = vx[n] + real(f0) * h * 0.5
    @fastmath y1 = vy[n] + imag(f0) * h * 0.5
    @fastmath f1 = f(x1, y1)
    @fastmath  x2 = vx[n] + real(f1) * h * 0.5
    @fastmath y2 = vy[n] + imag(f1) * h * 0.5
    @fastmath f2 = f(x2, y2)
    @fastmath x3 = vx[n] + real(f2) * h
    @fastmath y3 = vy[n] + imag(f2) * h
    @fastmath f3 = f(x3, y3)
    @fastmath vx[n + 1] = vx[n] + 1/6 * h * real( f0  + 2∙f1 + 2∙f2 + f3 )
    @fastmath vy[n + 1] = vy[n] + 1/6 * h * imag( f0  + 2∙f1 + 2∙f2 + f3 )
end
@fastmath function euler_forwardsteps_5!(f, vx, vy, h)
    @fastmath for n in 1:(length(vx) - 1)
        euler_step_complex_4!(f, vx, vy, h, n)
    end
end
@fastmath function rrk4_forwardsteps_5!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    @fastmath for n in 1:(length(vx) - 1)
        rk4_step_complex_4!(f, vx, vy, h, n)
    end
end

# Below, we're reusing code to generate the same flow field as in test_23. The cutoff value is no longer NaN.
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end
ϕ_vortex_23 =  generate_complex_potential_vortex(; pos = complex(0.0, 1.0)m, vorticity = 1.0m²/s / 2π)
ϕ_source_23 = generate_complex_potential_source(; pos = complex(3.0, 0.0)m, massflowout = 1.0m²/s)
ϕ_sink_23 = generate_complex_potential_source(; pos = -complex(3.0, 0.0)m, massflowout = -1.0m²/s)
ϕ_23(p) = ϕ_vortex_23(p) + ϕ_source_23(p) + ϕ_sink_23(p)

PHYSWIDTH_23 = 10.0m
HEIGHT_RELATIVE_WIDTH_23 = 0.4
PHYSHEIGHT_23 = PHYSWIDTH_23 * HEIGHT_RELATIVE_WIDTH_23
SCREEN_WIDTH_FRAC_23 = 2 / 3
CUTOFF_23 = 0.5m/s
setscale_dist(PHYSWIDTH_23 / (SCREEN_WIDTH_FRAC_23 * WI))

"""
The test flow field from test_23 as a matrix of complex velocities with one element per pixel.
We're filling the above-cutoff values with the cutoff value instead of with NaN.
"""
function flowfield_23()
    begin
        unclamped = ∇_rectangle(ϕ_23,
            physwidth = PHYSWIDTH_23,
            height_relative_width = HEIGHT_RELATIVE_WIDTH_23);
        map(unclamped) do u
            hypot(u) > CUTOFF_23 ? CUTOFF_23∙u / hypot(u) : u
        end
    end;
end