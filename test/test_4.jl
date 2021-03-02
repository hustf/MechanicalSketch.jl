using MechanicalSketch
import MechanicalSketch: O, label, background, sethue, setdash, fontface, fontsize, line
import MechanicalSketch: FS, EM, translate, color_with_lumin, midpoint, getrotation, rotate
import MechanicalSketch: empty_figure, finish, color_from_palette

let
    this_fig = empty_figure(joinpath(@__DIR__, "test_4.png"))
    background(color_from_palette("seagreen1"))
    sethue(color_with_lumin(color_from_palette("darkblue"), 20))

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
    finish()
end