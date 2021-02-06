import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue
import MechanicalSketch: PALETTE, O, WI, HE, EM, FS, finish, x_y_iterators_at_pixels
import MechanicalSketch: dimension_aligned, settext, arrow, placeimage, readpng, setfont, gsave, grestore
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, @import_expand, string_polar_form
import MechanicalSketch: draw_color_map, draw_real_legend

let
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

BACKCOLOR = color_with_luminance(PALETTE[8], 0.8)
function restart()
    empty_figure(joinpath(@__DIR__, "test_20.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()

"Source position"
p_source = (-7.5, 0.0)m |> ComplexQuantity

"Flow rate, 2d flow"
q_source = 1.0m²/s

"2d velocity potential function. Complex quantity domain, real quantity range."
ϕ_source = generate_complex_potential_source(; pos = p_source, massflowout = q_source)

physwidth = 20m
physheight = physwidth / 3
xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
A = [ϕ_source(complex(x, y)) for y in ys, x in xs] # 0.189560 seconds (1.17 M allocations: 34.138 MiB, 64.04% compilation time)

upleftpoint, lowrightpoint = draw_color_map(O, A)


# Add some decoration to the plot
sethue(color_with_luminance(PALETTE[5], 0.3))
dimension_aligned(O + (-physwidth / 2, physheight / 2), O + (physwidth / 2, physheight / 2))
dimension_aligned(O + p_source, O + (-7.5 + 1.0im)m)
dimension_aligned(O + (-physwidth / 2, - physheight / 2 ),  O +  (-physwidth / 2, physheight / 2 ))

begin # Leader for a value
    p0 = (-7.5 + 1.0im)m
    arrow(O + p0 + (2EM, -EM), O + p0)
    fvalue = ϕ_source(p0)
    strvalue = string(round(typeof(fvalue ), fvalue , digits = 3))
    strargument = string(p0)
    txt =  "ϕ<sub>source</sub>(" * strargument * ") = " * strvalue
    settext(txt, O + p0 + (3EM, -EM), markup=true)
end
begin # Leader for another value
    p0 = (-4.0 - 2.0im)m
    arrow(O + p0 + (2EM, -EM), O + p0)
    fvalue = ϕ_source(p0)
    strargument = string_polar_form(p0)
    strvalue = string(round(typeof(fvalue), fvalue , digits = 3))
    txt =  "ϕ<sub>source</sub>( " * strargument * " ) = " * strvalue
    settext(txt, O + p0 + (3EM, -EM), markup=true)
end
setfont("DejaVu Sans", FS)
str = "ϕ: Z ↣ R   is the <b>velocity potential</b>. \r            It exists for irrotational flows only. This source is an example."
settext(str, O + (-0.7 * physwidth, -6.3m), markup = true)
setfont("Calibri", FS)
# Add an image of the source formula, and source strength value
formulafilename = joinpath(@__DIR__, "..", "resource", "source.png")
img = readpng(formulafilename);
gsave()
placeimage(img, O + (4.0, -6.3)m)
grestore()
str = "q = $q_source"
settext(str, O + (4.0, -6.3)m + (3.3EM, 4.5EM), markup = true)


legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)

ma = maximum(A)
mi = minimum(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, mi, ze, (ma + mi)  / 2]))

draw_real_legend(legendpos, mi, ma, legendvalues)

finish()
end # let