import MechanicalSketch
import MechanicalSketch: empty_figure, sethue, O, WI, HE, EM, FS, finish
import MechanicalSketch: PALETTE, settext, setline, set_figure_height
import MechanicalSketch: circle, arrow, normalize_datarange, line
import MechanicalSketch: @import_expand, @layer, Point, Table
import MechanicalSketch: ∙, °, trace_rotate_hue, rotate_hue, noise_between_wavelengths
import MechanicalSketch: get_current_RGB, color_from_palette, get_scale_sketch
import MechanicalSketch: placeimage, readsvg, readpng, color_with_luminance, upreferred
import MechanicalSketch: Luxor, Length
import Luxor:            Cairo.CairoSurfaceBase, SVGimage, Rsvg, translate, scale, getscale, rect

#let


if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
end
include("test_functions_35.jl")
empty_figure(joinpath(@__DIR__, "test_35.png"),
    backgroundcolor = color_with_luminance(PALETTE[8], 0.3));
# Temp
#using LaTeXStrings
#using Latexify # min 0.14.8
svfnam = joinpath("..", "svg", "dn69ygSyBh.svg")
isfile(svfnam)
sv = readsvg(svfnam)
pn = readpng("test_1.png");
# Todo, create new constructors for image types in placeimage?
get_width_height_35(sv)
get_width_height_35(pn)
placeimage_35(sv, O, height =  HE * m / get_scale_sketch(m), centered = true)
placeimage_35(sv, O, height =  HE * m / get_scale_sketch(m), centered = false)

finish()
#=
r = Rsvg.handle_new_from_file(svfnam)
@edit Rsvg.handle_get_dimensions(r)
d = Rsvg.RsvgDimensionData(1,1,1,1)
Rsvg.handle_get_dimensions(r, d)
finish()
=#
