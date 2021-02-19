import MechanicalSketch
import MechanicalSketch: color_with_lumin, empty_figure, background, sethue, O, EM, FS, finish, PALETTE
import MechanicalSketch: dimension_aligned, settext, arrow, placeimage, readpng, setfont, gsave, grestore
import MechanicalSketch: ComplexQuantity, generate_complex_potential_vortex, @import_expand, string_polar_form
import MechanicalSketch: place_image, x_y_iterators_at_pixels, ColSchemeNoMiddle
import MechanicalSketch: BinLegend, draw_legend

let
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end


BACKCOLOR = color_with_lumin(PALETTE[8], 80)
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
physheight = physwidth / 3
xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
A = [ϕ_vortex(complex(x, y)) for y in ys, x in xs]
legend = BinLegend(;maxlegend = maximum(A), minlegend = minimum(A), noofbins = 20,
    name = :Potential)

colormat = legend.(A);
ulp, lrp = place_image(O, colormat);

# Add some decoration to the plot
sethue(color_with_lumin(PALETTE[5], 30))
dimension_aligned(O + (-physwidth / 2, physheight / 2), O + (physwidth / 2, physheight / 2))
dimension_aligned(O + p_vortex, O)
dimension_aligned(O + (-physwidth / 2, - physheight / 2 ),  O +  (-physwidth / 2, physheight / 2 ))

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
str = "ϕ: Z ↣ R   is the velocity potential, here for a vortex.\r            Surprise: It is irrotational outside of the centre."
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


legendpos = O + ((lrp[1] - ulp[1]) / 2 + EM, (ulp[2] - lrp[2]) / 2)

draw_legend(legendpos, legend)

finish()
nothing
end # let
