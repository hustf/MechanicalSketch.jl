import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, EM, WI, HE, FS, finish,
       PALETTE
import MechanicalSketch: dimension_aligned, settext, setfont
import MechanicalSketch: @import_expand
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_complex_legend, setscale_dist, lenient_min_max

let
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end


BACKCOLOR = color_with_luminance(PALETTE[8], 0.8)
function restart()
    empty_figure(joinpath(@__DIR__, "test_22.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()



"A complex domain function defined in the unit circle"
 foo(z)= hypot(z) <= 1.0m ? z : NaN*m

physwidth = 2.2m
height_relative_width = 1 / 1
physheight = physwidth * height_relative_width
setscale_dist(1.1physwidth / HE)
A = quantities_at_pixels(foo,
    physwidth = physwidth,
    height_relative_width = height_relative_width);
upleftpoint, lowrightpoint = draw_color_map(O, A)


setfont("DejaVu Sans", FS)
str = "f: Z ↣ Z ,  f(z) = z \r inside the unit circle"
settext(str, O + (-WI/2 + 2EM, 0.5HE - 3EM), markup = true)
setfont("Calibri", FS)

legendpos = lowrightpoint + (0.0m, physheight)

mi, ma = lenient_min_max(A)
mea = (mi + ma) / 2

legendvalues = reverse(sort([ma, mi, mea]))

draw_complex_legend(legendpos, mi, ma, legendvalues)

dimension_aligned(O + (-1.0m, 0.0m ),  O +  (-1.0m, 1.0m ))

finish()
setscale_dist(20m / HE)
end # let