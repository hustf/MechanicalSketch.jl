import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, EM, FS, finish, Point,
       PALETTE, color_from_palette
import MechanicalSketch: dimension_aligned
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, norm
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_real_legend, draw_complex_legend, setscale_dist, lenient_min_max
import MechanicalSketch: ∙ #, generate_∇fz_Z_to_Z_from_fz, settext_centered_above_with_markup

#let
BACKCOLOR = color_with_luminance(PALETTE[8], 0.1)
function restart()
    empty_figure(joinpath(@__DIR__, "test_23.png"))
    background(BACKCOLOR)
    sethue(PALETTE[8])
end
restart()


if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

"Source position"
p_source = complex(3.0, 0.0)m
"Flow rate, 2d flow"
q_source = 1.0m²/s
"Vortex position"
p_vortex = complex(0.0, 1.0)m
"Vorticity, 2d flow"
K = 1.0m²/s / 2π

ϕ_vortex =  generate_complex_potential_vortex(; pos = p_vortex, vorticity = K)
ϕ_source = generate_complex_potential_source(; pos = p_source, massflowout = q_source)
ϕ_sink = generate_complex_potential_source(; pos = -p_source, massflowout = -q_source)


ϕ_vortex(p_source)

import MechanicalSketch.gradient_complex_quantity_in
using BenchmarkTools
@btime gradient_complex_quantity_in(ϕ_vortex)
#=
"""
    ϕ(p::ComplexQuantity)
    Z -> R
2d velocity potential function. Complex quantity domain, real quantity range.
"""
ϕ(p) = ϕ_vortex(p) + ϕ_source(p) + ϕ_sink(p)

ϕ(p_source)
ϕ(p_vortex+p_source)

# Plot the real-valued function
physwidth = 5.0m
height_relative_width = 0.45
physheight = physwidth * height_relative_width
setscale_dist(3.0physwidth / W)
A = quantities_at_pixels(ϕ,
    physwidth = physwidth,
    height_relative_width = height_relative_width);
upleftpoint, lowrightpoint = draw_color_map(O + (0.0, -0.25H ), A)
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)
ma = maximum(A)
mi = minimum(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, mi, ze]))
draw_real_legend(legendpos, mi, ma, legendvalues)

#=
fi(x) = 1.0
fii(x) = 1.0m^2/s
fuu(x) = 1.0m^2/s
fø(x) = x*1.0m^2/s
fæ(x) = x

@code_warntype quantities_at_pixels(fi);
@btime quantities_at_pixels(fi);
@code_lowered quantities_at_pixels(fi);
@code_warntype quantities_at_pixels(fii);
@btime quantities_at_pixels(fii);
@code_warntype quantities_at_pixels(ϕ_source);
@btime quantities_at_pixels(ϕ_source);
@code_warntype quantities_at_pixels(fø);
@btime quantities_at_pixels(fø);

fææ(x) = x/s
@btime quantities_at_pixels(fæ);
@lowered quantities_at_pixels(fæ);



fa() = quantities_at_pixels(ϕ,
    physwidth = physwidth,
    height_relative_width = height_relative_width)
@btime fa();
=#
"""
    ∇ϕ(p::ComplexQuantity)
    -> Z{ComplexQuantity}

Gradient of the velocity potential, aka 'velocity'.
"""
∇ϕ(p) = generate_∇fz_Z_to_Z_from_fz(ϕ_vortex, typeof(1.0m), typeof(1.0m²∙s⁻¹))(p)
∇ϕ(complex(0.0,0.1)m)
#=
# Plot the complex-valued function
function clamped_∇ϕ(p)
    unclamped =  ∇ϕ(p)
    norm(unclamped) > 0.5m/s ? NaN∙m : unclamped
end
foo() = quantities_at_pixels(clamped_∇ϕ,
    physwidth = physwidth,
    height_relative_width = height_relative_width)

B = foo()
@btime foo()
fifi() = quantities_at_pixels(∇ϕ,
physwidth = physwidth,
height_relative_width = height_relative_width)


upleftp, downrightp = draw_color_map(O + (0.0, + 0.25H ), B)
legendpos = downrightp + (EM, 0) + (0.0m, physheight)
mi, ma = lenient_min_max(B)
mea = (mi + ma) / 2
legendvalues = reverse(sort([ma, mi, mea]))
draw_complex_legend(legendpos, mi, ma, legendvalues)

# some decoration
dimension_aligned(O + (upleftp[1], downrightp[2]) , upleftp )
settext_centered_above_with_markup("Source", O + p_source + (0.0, + 0.25H + 0.5EM))
settext_centered_above_with_markup("Sink", O + (-p_source) + (0.0, + 0.25H + 0.5EM))
settext_centered_above_with_markup("Vortex", O + p_vortex + (0.0, + 0.25H + 0.5EM))
finish()

setscale_dist(20m / H)

#end # let
=#


function ϕ_vortex_xvec(x::NTuple{2, QF})
    ϕ_vortex(complex(x[1], x[2]))
end


ϕ_vortex_xvec((0.1, 0.2)m)

gradient(ϕ_vortex_xvec, [(0.1, 0.2)m, (0.2, 0.23)m])
=#