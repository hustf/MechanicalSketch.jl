import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, EM, FS, finish, Point,
       PALETTE, color_from_palette, setfont, settext
import MechanicalSketch: dimension_aligned
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, norm
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_real_legend, draw_complex_legend, setscale_dist, lenient_min_max
import MechanicalSketch: ∙, ∇_rectangle

let
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

"""
    ϕ(p::ComplexQuantity)
    → Quantity
2d velocity potential function. Complex quantity domain, real quantity range.
"""
ϕ(p) = ϕ_vortex(p) + ϕ_source(p) + ϕ_sink(p)

ϕ(p_source)
ϕ(p_vortex+p_source)

# Plot the real-valued function
physwidth = 5.0m
height_relative_width = 0.4
physheight = physwidth * height_relative_width
setscale_dist(3.0physwidth / W)
A = quantities_at_pixels(ϕ,
    physwidth = physwidth,
    height_relative_width = height_relative_width);
upleftpoint, lowrightpoint = draw_color_map(O + (0.0, -0.25H + EM), A)
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)
ma = maximum(A)
mi = minimum(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, mi, ze]))
draw_real_legend(legendpos, mi, ma, legendvalues)
setfont("DejaVu Sans", FS)
str = "ϕ: Z ↣ R  is the flow potenial"
settext(str, O + (-W/2 + EM, -0.5H + 2EM), markup = true)
setfont("Calibri", FS)


# Plot the complex-valued function, aka velocity vectors.
B = begin
        unclamped = ∇_rectangle(ϕ,
            physwidth = physwidth,
            height_relative_width = height_relative_width);
        map(unclamped) do u
            norm(u) > 0.5m/s ? NaN∙u : u
        end
    end

upleftpoint, lowrightpoint = draw_color_map(O + (0.0, + 0.25H + 0.5EM ), B)
setfont("DejaVu Sans", FS)
str = "∇ϕ: Z ↣ Z  is the flow gradient, aka velocity vectors"
settext(str, O + (-W/2 + EM, 1.5EM), markup = true)
setfont("Calibri", FS)

legendpos = lowrightpoint + (0.0m, physheight)

mi, ma = lenient_min_max(B)
mea = (mi + ma) / 2
legendvalues = reverse(sort([ma, mi, mea]))
draw_complex_legend(legendpos, mi, ma, legendvalues)


finish()
end #let