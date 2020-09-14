import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, EM, FS, finish, Point,
       PALETTE, color_from_palette, setopacity
import MechanicalSketch: SCALEDIST,  dimension_aligned, settext, arrow, placeimage, readpng, setfont, gsave, grestore
import MechanicalSketch: ComplexQuantity, generate_complex_potential_vortex, @import_expand, string_polar_form
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_real_legend

if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

let
BACKCOLOR = color_with_luminance(PALETTE[8], 0.8)
function restart()
    empty_figure(joinpath(@__DIR__, "test_21.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()

"Vortex position"
p_vortex = (0.0, 2.5)m |> ComplexQuantity

"Vorticity, 2d flow"
K = 1.0m²/s

"2d velocity potential function. Complex quantity domain, real quantity range. "
ϕ_vortex = generate_complex_potential_vortex(; pos = p_vortex, vorticity = K)


physwidth = 20m
height_relative_width = 1 / 3
physheight = physwidth * height_relative_width
A = quantities_at_pixels(ϕ_vortex,
    physwidth = physwidth,
    height_relative_width = height_relative_width);
upleftpoint, lowrightpoint = draw_color_map(O, A)

# Add some decoration to the plot
sethue(color_with_luminance(PALETTE[5], 0.3))
dimension_aligned(O + (-physwidth / 2, physheight / 2), O + (physwidth / 2, physheight / 2))
dimension_aligned(O + p_vortex, O)

begin # Leader for a value
    p0 = (0.0 + 1.0im)m
    arrow(O + p0 - (3EM, -2EM), O + p0 )
    fvalue = ϕ_vortex(p0)
    strvalue = string(round(typeof(fvalue ), fvalue , digits = 3))
    strargument = string(p0)
    strargumentpol = string_polar_form(round(typeof(p0 ), p0 , digits = 3))
    txt =  "ϕ<sub>vortex</sub>( $strargument ) = ϕ<sub>vortex</sub>( $strargumentpol ) =$strvalue"
    settext(txt, O + p0 + (-12EM, 3EM), markup=true)
end
setfont("DejaVu Sans", FS)
str = "ϕ: Z ↣ R   is the <b>velocity potential</b>. \r            It exists for irrotational flows only. This vortex is an example."
settext(str, O + (-0.7 * physwidth, -6.3m), markup = true)
setfont("Calibri", FS)
# Add an image of the vortex formula, and vortex strength value
formulafilename = joinpath(@__DIR__, "..", "resource", "vortex.png")
img = readpng(formulafilename);
gsave()
placeimage(img, O + (4.0, -6.3)m)
grestore()
str = "K = $K"
settext(str, O + (4.0, -6.3)m + (3.3EM, 4.5EM), markup = true)


legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)

ma = maximum(A)
mi = minimum(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, mi, ze]))

draw_real_legend(legendpos, mi, ma, legendvalues)

finish()
end # let