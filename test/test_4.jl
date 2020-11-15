using MechanicalSketch
import MechanicalSketch: O, label, background, sethue, setdash, fontface, fontsize, line,
    FS, EM, translate, color_with_luminance, midpoint, getrotation, rotate
let
    this_fig = empty_figure(joinpath(@__DIR__, "test_4.png"))
    background(color_from_palette("seagreen1"))
    sethue(color_with_luminance(color_from_palette("darkblue"), 0.2))

    label("O", :NW, O)
    include("test_functions_4.jl")
    labelelledtri()
    rotate(π / 3)
    labelelledtri()
    MechanicalSketch.scale(0.5)
    rotate(2π / 3)
    labelelledtri()
    translate(O + (10EM, 0))
    labelelledtri()
    rotate(π)
    labelelledtri()
    label("-----------")


    MechanicalSketch.finish()
end