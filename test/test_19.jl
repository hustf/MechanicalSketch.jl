import MechanicalSketch
import MechanicalSketch: color_with_lumin, color_from_palette, empty_figure, background, sethue, O
import MechanicalSketch: PALETTE, m, finish, WI, HE, EM, place_image
import MechanicalSketch: circle, ellipse, squircle, rect
import MechanicalSketch: box, clipreset, readpng, placeimage, setopacity

#let
BACKCOLOR = color_with_lumin(PALETTE[8], 80);
function restart()
    empty_figure(filename = joinpath(@__DIR__, "test_19.png"))
    background(BACKCOLOR)
    sethue(PALETTE[1])
end
restart()

# Some basic fill shapes...
squircle(O,  5m, 10m; action = :fillpreserve, rt = 0.5)
sethue(color_from_palette("red"))
circle(O + (-2m, 2m), 2m , :fillpreserve)
setopacity(0.2)
box(O + (-4m, 4m), O + (-3m, 3m), :fillpreserve)
sethue(color_from_palette("yellow"))
ellipse(O + (2m, -2m), 1m, 2m; action = :fillpreserve)
# Set a clip area for following actions
setopacity(0.8)
squircle(O,  5m, 10m; action = :clip, rt = 0.5)
sethue(color_from_palette("midnightblue"))
box(O + (-3m, 1m), O + (20m, 20m), :fillpreserve)
img = readpng(joinpath(@__DIR__, "test_1.png"))
setopacity(0.2)
place_image(O, img; centered = true, alpha = 0.1)
clipreset()

place_image(O + (-WI / 2, -HE / 2), img; centered = true, alpha = 0.2)
place_image(O, img; centered = false, alpha = 0.2)
pt = O + (-WI / 4, HE / 4)
ptul, ptbr, sc = place_image(pt, img; centered = true, alpha = 0.9, scalefactor = 0.5)
pt = O + (WI / 4, -HE / 4)
ptul, ptbr, sc = place_image(pt, img; centered = true, scalefactor = 0.25)

finish()

#end