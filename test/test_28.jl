import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, finish
import MechanicalSketch: color_with_lumin, color_from_palette, set_scale_sketch
import MechanicalSketch: sethue, settext, WI, EM, circle, arrow
import MechanicalSketch: @import_expand, Quantity

let
BACKCOLOR = color_with_lumin(PALETTE[8], 90);

if !@isdefined N
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand ~N
    @import_expand s
end

include("test_functions_28.jl")

fi = "Reaction forces.txt"
lfina = joinpath(@__DIR__, "../resource/", fi)
matchlines = matchinglines(lfina, [3s], ["Vert"]);
thisline = matchlines[3]
thisname = split(thisline, "\t")[1]

Fx, Fy, Fz, _, _, _, px, py, pz = parse.(Quantity{Float64}, split(thisline, '\t')[3:end-1])


empty_figure(joinpath(@__DIR__, "test_28.png"),
    backgroundcolor = BACKCOLOR,
    hue = color_from_palette("blue"));

set_scale_sketch(20m, HE)
set_scale_sketch(1500kN, HE)
sethue(color_from_palette("black"))
circle(O, 6269.0mm, :stroke)
circle(O, 5623.0mm, :stroke)

sethue(color_from_palette("green"))
drawforces(O, lfina, "xy", [3s], ["Stopper"]; components = false, labellength = true)
sethue(color_from_palette("red"))
drawforces(O, lfina, "xy", [3s], ["VertWeld"]; components = false, labellength = true)
sethue(color_from_palette("blue"))
drawforces(O, lfina, "xy", [3s], ["Deck stopper"]; components = false, labellength = true)

str = "View from above"
settext(str, O + (-WI/2 + EM, -HE / 2  + 2EM) , markup = true)

finish()
set_scale_sketch()
end