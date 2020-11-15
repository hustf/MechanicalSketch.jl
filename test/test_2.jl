using MechanicalSketch
import MechanicalSketch: get, getinverse, textextents,  Point, rect, label,
    EM, TXTOFFV, WI, background, sethue, text, background, @colorant_str

let

this_fig = empty_figure(joinpath(@__DIR__, "test_2.png"))
midcol = MechanicalSketch.HSL(get(PALETTE, 0.5))
bckcol = MechanicalSketch.RGB(MechanicalSketch.HSL(midcol.h, midcol.s, midcol.l * 0.5))
background(bckcol)
width_px = this_fig.width
height_px = this_fig.height
for (i, c)  in  enumerate(0:0.08:1)
    colo = get(PALETTE, c)
    r, g, b = sethue(colo)
    lightness = MechanicalSketch.HSL(colo).l
    gamma = 2.2
    lumin2 = 0.2126 * r^gamma + 0.7152 * g^gamma + 0.0722 * b^gamma
    posx = width_px * (-0.5 + 0.1 * c)
    posy = height_px * - 0.5 + EM *  i
    stri = "Da jeg var på vei til kirken "
    downleftpttext = Point(posx, posy)
    x_bearing, y_bearing, twidth, theight, x_advance, y_advance = textextents(stri)
    downleftptrect = Point(posx, posy + TXTOFFV)
    rect( downleftptrect , twidth * 3, -EM, :fill)
    sethue(lightness > 0.6 ? "black" : "white")
    text(stri,  downleftpttext)
    downleftpt = Point(posx + twidth, posy)
    sethue(lumin2 > 0.5 ? "black" : "white")
    text(stri * string(c),  downleftpt)
end
stri = " α"
sethue( get(PALETTE, 0.15))
label("2" * "E", :E, Point(0 , 2EM))
sethue(get(PALETTE, getinverse(PALETTE, colorant"red" )))
label("N" * stri, :N, Point(0, 1EM), leader = true, offset = EM, leaderoffsets = [2., 3.])
label("S" * stri, :S, Point(0 , 1EM), leader = true, offset = EM, leaderoffsets = [-2., -3.])
sethue(color_from_palette("red"))
label("E" * stri, :E, Point(0, 1EM), leader = true, offset = EM, leaderoffsets = [2., 3.])
label("W" * stri, :W, Point(0 , 1EM), leader = true, offset = EM, leaderoffsets = [-2., -3.])



sethue(get(PALETTE, getinverse(PALETTE, colorant"green" )))
label("5N" * stri, :N, Point(-WI/4, 5EM), leader = true, offset = EM, leaderoffsets = [2., 3.])
label("5S" * stri, :S, Point(-WI/4, 5EM), leader = true, offset = EM, leaderoffsets = [-2., -3.])
sethue(color_from_palette("darkblue"))
label("5E" * stri, :E, Point(-WI/4, 5EM), leader = true, offset = EM, leaderoffsets = [2., 3.])
label("5W" * stri, :W, Point(-WI/4 , 5EM), leader = true, offset = EM, leaderoffsets = [-2., -3.])

sethue(get(PALETTE, getinverse(PALETTE, colorant"blue" )))
label("7" * stri, :W, Point(WI/4 , 7EM), leader = true, offset = EM, leaderoffsets = [-2., -3.])

MechanicalSketch.finish()
end