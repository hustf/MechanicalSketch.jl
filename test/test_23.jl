#= ForwardDiff is removed from dependencies in this version.
import MechanicalSketch
import MechanicalSketch: color_with_lumin, background, O, WI, HE, EM, FS, finish,
       PALETTE, color_from_palette, setfont, settext, empty_figure, sethue, @layer
import MechanicalSketch: dimension_aligned
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, BinLegend, BinLegendVector, draw_legend
import MechanicalSketch: place_image, set_scale_sketch, lenient_min_max
import MechanicalSketch: ∙, ∇_rectangle, x_y_iterators_at_pixels

let
BACKCOLOR = color_with_lumin(PALETTE[8], 10)
function restart()
    empty_figure(filename = joinpath(@__DIR__, "test_23.png"))
    background(BACKCOLOR)
    sethue(PALETTE[8])
end
restart()


if !@isdefined m²
    @import_expand(m, s)
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
OT = O + (-EM, -0.25HE + EM)
physwidth = 10.0m
physheight = 0.4 * physwidth
set_scale_sketch(physwidth, round(Int, WI * 2 / 3))
xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
A = [ϕ(complex(x, y)) for y in ys, x in xs]
toplegend = BinLegend(;maxlegend = maximum(A), minlegend = -maximum(A),
                      noofbins = 256, name = :Potential)
colormat = toplegend.(A);
upleftpoint, lowrightpoint = place_image(OT, colormat)
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)
draw_legend(legendpos, toplegend)

# Text
setfont("DejaVu Sans", FS)
str = "ϕ: Z ↣ R  is the flow potenial"
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)
settext("Source", OT + (real(p_source), imag(p_source)))
settext("Vortex", OT + (real(p_vortex), imag(p_vortex)))
@layer begin
    sethue(BACKCOLOR)
    settext("Sink", OT - (real(p_source), imag(p_source)))
end
str = "∇ϕ: Z ↣ Z  is the flow gradient, aka velocity vectors"
settext(str, O + (-WI/2 + EM, 1.5EM), markup = true)


# Plot the complex-valued function, aka velocity vectors.
B = begin
        unclamped = ∇_rectangle(ϕ; physwidth, physheight)
        map(unclamped) do u
            hypot(u) > 0.5m/s ? NaN∙u : u
        end
    end

OB = O + (-EM, + 0.25HE + 0.5EM )
mi, ma = lenient_min_max(B)
botlegend = BinLegendVector(;operand_example = first(B),
        max_magn_legend = ma, noof_magn_bins = 30, noof_ang_bins = 36,
        name = :Velocity)
colormat = botlegend.(B)
ulp, lrp = place_image(OB, colormat)
legendpos = lrp + (EM, 0) + (0.0m, physheight)
draw_legend(legendpos, botlegend)


# Position indicator
dimension_aligned(OB + (-physwidth / 2, physheight / 2), OB + (physwidth / 2, physheight / 2))
dimension_aligned(OB + p_vortex, OB)
dimension_aligned(OB + (-physwidth / 2, - physheight / 2 ),  OB +  (-physwidth / 2, physheight / 2 ))

finish()
end #let
=#