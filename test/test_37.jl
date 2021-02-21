import MechanicalSketch: PALETTE, color_with_lumin, empty_figure, @import_expand, finish
import MechanicalSketch: readsvg, O, HE, place_image, tex2svg_string
import MechanicalSketch: @latexify

let

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
empty_figure(joinpath(@__DIR__, "test_37.png"),
    backgroundcolor = color_with_lumin(PALETTE[4], 80));
l = @latexify f(x) = x^2;
svgs = tex2svg_string(l);
svgi = readsvg(svgs)
place_image(O, svgi, height = 4m, centered = true)
place_image(O, svgi, width = 10m, centered = true)
place_image(O, svgi, centered = true)
place_image(O + (-0.25WI, -0.25HE), l, height = 1m)
finish()
end#let
