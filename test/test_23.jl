import MechanicalSketch
import MechanicalSketch: color_with_luminance, background, O, WI, HE, EM, FS, finish,
       PALETTE, color_from_palette, setfont, settext, empty_figure, sethue, @layer
import MechanicalSketch: dimension_aligned
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_real_legend, draw_complex_legend, set_scale_sketch, lenient_min_max
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
ϕ(p_vortex + p_source)

# Plot the real-valued function
physwidth = 10.0m
physheight = 0.4 * physwidth
set_scale_sketch(physwidth, round(Int, WI * 2 / 3))
A = quantities_at_pixels(ϕ,
    physwidth = physwidth,
    physheight = physheight);
OT = O + (0.0, -0.25HE + EM)
upleftpoint, lowrightpoint = draw_color_map(OT, A)
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)
ma = maximum(A)
mi = minimum(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
draw_real_legend(legendpos, mi, ma, legendvalues)
setfont("DejaVu Sans", FS)
str = "ϕ: Z ↣ R  is the flow potenial"
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)

settext("Source", OT + (real(p_source), imag(p_source)))
settext("Vortex", OT + (real(p_vortex), imag(p_vortex)))
@layer begin
    sethue(BACKCOLOR)
    settext("Sink", OT - (real(p_source), imag(p_source)))
end
setfont("Calibri", FS)


# Plot the complex-valued function, aka velocity vectors.
B = begin
        unclamped = ∇_rectangle(ϕ,
            physwidth = physwidth,
            physheight = physheight);
        map(unclamped) do u
            hypot(u) > 0.5m/s ? NaN∙u : u
        end
    end

OB = O + (0.0, + 0.25HE + 0.5EM )
upleftpoint, lowrightpoint = draw_color_map(OB, B)
setfont("DejaVu Sans", FS)
str = "∇ϕ: Z ↣ Z  is the flow gradient, aka velocity vectors"
settext(str, O + (-WI/2 + EM, 1.5EM), markup = true)
setfont("Calibri", FS)

legendpos = lowrightpoint + (0.0m, physheight)

mi, ma = lenient_min_max(B)
mea = (mi + ma) / 2
legendvalues = reverse(sort([ma, mi, mea]))
draw_complex_legend(legendpos, mi, ma, legendvalues)

dimension_aligned(OB + (-physwidth / 2, physheight / 2), OB + (physwidth / 2, physheight / 2))
dimension_aligned(OB + p_vortex, OB)
dimension_aligned(OB + (-physwidth / 2, - physheight / 2 ),  OB +  (-physwidth / 2, physheight / 2 ))


finish()
end #let