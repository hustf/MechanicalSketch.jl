import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, EM, FS, finish, Point,
       PALETTE, color_from_palette, setopacity
import MechanicalSketch: SCALEDIST,  dimension_aligned, settext, arrow, placeimage, readpng, setfont, gsave, grestore
import MechanicalSketch: ComplexQuantity, generate_complex_potential_vortex, @import_expand, string_polar_form
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_absolute_value_legend, norm, setscale_dist

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
 foo(z)= norm(z) <= 1.0m ? z : NaN*m

physwidth = 2.2m
height_relative_width = 1 / 1
physheight = physwidth * height_relative_width
setscale_dist(2.2m / H)
A = quantities_at_pixels(foo, 
    physwidth = physwidth, 
    height_relative_width = height_relative_width);
upleftpoint, lowrightpoint = draw_color_map(O, A)

legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)

finish()
setscale_dist(20m / H)
