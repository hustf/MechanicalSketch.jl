import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, finish, Point,
    PALETTE, color_from_palette, setopacity
import MechanicalSketch: m, scale
import MechanicalSketch: circle, ellipse, squircle
import MechanicalSketch: box, clipreset, readpng, placeimage

let
BACKCOLOR = color_with_luminance(PALETTE[8], 0.8);
function restart()
    empty_figure(joinpath(@__DIR__, "test_19.png"))
    background(BACKCOLOR)
    sethue(PALETTE[1])
end
restart()

# Some basic fill shapes...
squircle(O,  5m, 10m, :fillpreserve; rt = 0.5)
sethue(color_from_palette("red"))
circle(O + (-2m, 2m), 2m , :fillpreserve)
setopacity(0.2)
box(O + (-4m, 4m), O + (-3m, 3m), :fillpreserve)
sethue(color_from_palette("yellow"))
ellipse(O + (2m, -2m), 1m, 2m, :fillpreserve)
# Set a clip area for following actions
setopacity(0.8)
squircle(O,  5m, 10m, :clip; rt = 0.5)
sethue(color_from_palette("midnightblue"))
box(O + (-3m, 1m), O + (20m, 20m), :fillpreserve)
img = readpng(joinpath(@__DIR__, "test_1.png"))
setopacity(0.2)
placeimage(img, O; centered = true)
clipreset()
finish()
end