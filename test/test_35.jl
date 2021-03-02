import MechanicalSketch
import MechanicalSketch: empty_figure, O, WI, HE, finish
import MechanicalSketch: PALETTE
import MechanicalSketch: circle, scale_to_pt, scale_pt_to_unit
import MechanicalSketch: @import_expand, @layer, Point
import MechanicalSketch: ∙, °
import MechanicalSketch: placeimage, readsvg, readpng, color_with_lumin
import MechanicalSketch: Luxor, Length, set_scale_sketch, text, SVGimage
import Luxor:            Cairo.CairoSurfaceBase, translate, scale

let

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
include("test_functions_35.jl")
empty_figure(joinpath(@__DIR__, "test_35.png"),
    backgroundcolor = color_with_lumin(PALETTE[8], 30));

totheight = 10.0m
set_scale_sketch(totheight, HE)
totwidth = totheight * WI / HE
Δx = totwidth / 4
Δy = totheight / 4
centers = reshape([Point(x, y) for x in Δx * [-1, 0, 1], y in Δy * [1, 0, -1]], :, 1)
θs = [180, 225, 270]°

for (i, cent) in enumerate(centers)
    circle(cent; d = 1m)
    circle.(cent; r = 2m)
    text(string(i), cent + (1, 1)m, )
end
svfnam = joinpath("..", "resource", "dn69ygSyBh.svg")
isfile(svfnam)
sv = readsvg(svfnam)
place_image_35(centers[1], sv, centered = true)
place_image_35(centers[2], sv, centered = false)
place_image_35(centers[3], sv, centered = true, height = 1m)
place_image_35(centers[4], sv, centered = false, height = 1m)
place_image_35(centers[5], sv, centered = true, width = 1m)
place_image_35(centers[6], sv, centered = false, width = 1m)
place_image_35(centers[7] + 2m .* (cos(θs[1]), sin(θs[1])), sv, centered = true, width = 1m)
place_image_35(centers[8] + 2m .* (cos(θs[2]), sin(θs[2])), sv, centered = true, width = 1m)
place_image_35(centers[9] + 2m .* (cos(θs[2]), sin(θs[2])), sv, centered = false, width = 1m)

end # let

finish()
