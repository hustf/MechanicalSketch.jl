import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, EM, WI, HE, FS, finish,
       PALETTE
import MechanicalSketch: dimension_aligned, settext, setfont, set_scale_sketch
import MechanicalSketch: @import_expand, x_y_iterators_at_pixels
import MechanicalSketch: draw_color_map, draw_complex_legend, lenient_min_max
import MechanicalSketch: LegendVectorLike

let
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end


BACKCOLOR = color_with_luminance(PALETTE[8], 0.8)
function restart()
    empty_figure(joinpath(@__DIR__, "test_22aa.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()



"A complex domain function defined in the unit circle"
foo(z)= hypot(z) <= 1.0m ? z : NaN * z

physwidth = 2.2m
physheight = physwidth
set_scale_sketch(1.1physwidth, HE)

xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
A = [foo(complex(x, y)) for y in ys, x in xs]
mi, ma = lenient_min_max(A)
mea = (mi + ma) / 2

legend = LegendVectorLike(ma)
legend((1.0m, 1.0m))
legend(A[1,1])
colmat = map(legend, A)

upleftpoint, lowrightpoint = draw_color_map(O, A)


setfont("DejaVu Sans", FS)
str = "f: Z ↣ Z ,  f(z) = z \r inside the unit circle"
settext(str, O + (-WI/2 + 2EM, 0.5HE - 3EM), markup = true)
setfont("Calibri", FS)

legendpos = lowrightpoint + (0.0m, physheight)



legendvalues = reverse(sort([ma, mi, mea]))

draw_complex_legend(legendpos, mi, ma, legendvalues)

dimension_aligned(O + (-1.0m, 0.0m ),  O +  (-1.0m, 1.0m ))

finish()
set_scale_sketch(m)

end # let