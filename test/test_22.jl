import MechanicalSketch
import MechanicalSketch: color_with_lumin, empty_figure, background, sethue, O,  WI, HE, FS, EM, finish
import MechanicalSketch: settext, setfont, set_scale_sketch, PALETTE, Point
import MechanicalSketch: @import_expand, x_y_iterators_at_pixels
import MechanicalSketch: place_image, lenient_max
import MechanicalSketch: BinLegendVector, draw_legend
import MechanicalSketch: color_with_lumin
import MechanicalSketch.Luxor.ColorTypes: LCHuvA, LCHabA, HSVA, HSLA, LCHabA, RGBA
let
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end


BACKCOLOR = color_with_lumin(PALETTE[8], 70)
function restart()
    empty_figure(joinpath(@__DIR__, "test_22.png"))
    background(BACKCOLOR)
    sethue(color_with_lumin(PALETTE[6], 10))
end
restart()


"A complex domain function defined in the unit circle"
foo(z)= hypot(z) <= 1.0m ? z : NaN * z

physwidth = 2.2m
physheight = physwidth
totheight = 2.1 * physheight
set_scale_sketch(totheight, HE)
centers = totheight / 4 * Point.([(-1.2, 1), (1.2, 1), 
                                 (-1.2, -1), (0,0) ,(1.2, -1)])

xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
A = [foo(complex(x, y)) for y in ys, x in xs]
ma = lenient_max(A)


setfont("DejaVu Sans", FS)
str = "Direction ↣ hue\nin five color spaces"
settext(str, O + (-WI/2 + 0.5EM, -0.5HE + 3EM), markup = true)
str = "f: Z ↣ Z ,  f(z) = z \r inside the unit circle"
settext(str, O + (-WI/2 + 0.5EM, 0.5HE - EM), markup = true)

nomcol_1 = HSVA(0.0f0,1.0f0,1.0f0,1.0f0)

# nominal colors for legends, each of a different type but looking the same
nomcols = [nomcol_1,
            convert(HSLA, nomcol_1),
            convert(LCHuvA, nomcol_1),
            convert(LCHabA, nomcol_1),
            convert(RGBA, nomcol_1)]

legends = map(nomcols) do nomco
    BinLegendVector(;operand_example = complex(1.0m, 1.0m),
        max_magn_legend = ma, noof_magn_bins = 8, noof_ang_bins = 40,
        nominal_color = nomco, name = Symbol(string(typeof(nomco))))
end

for (nomco, center, legend) in zip(nomcols, centers, legends)
    colormat = legend.(A)
    ulp, lrp = place_image(center, colormat)
    legendpos = center + (-3EM, 2EM + (ulp[2] - lrp[2]) / 2)
    draw_legend(legendpos, legend)
end

finish()
set_scale_sketch(m) # default

end # let
