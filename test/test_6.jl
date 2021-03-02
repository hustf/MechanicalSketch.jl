using MechanicalSketch
import MechanicalSketch: sethue, background, foil_spline_local, boxtopleft, boxtopright
import MechanicalSketch: BoundingBox, m, mm, °, polyrotate!, polymove!, color_with_lumin
import MechanicalSketch: O, EM, poly, lumin, get_current_lumin, get_current_RGB, gsave, grestore
import MechanicalSketch: empty_figure, PALETTE,  dimension_aligned, color_from_palette, Point

let
BACKCOLOR = color_with_lumin(PALETTE[8], 70)
function restart()
    empty_figure(joinpath(@__DIR__, "test_6.png"))
    background(BACKCOLOR)
    sethue(PALETTE[7])
end
restart()
O + (0.0m, 1.0m)
SC = 15
fsp = foil_spline_local(l = SC*1000mm, t = SC * 58.4mm, c= SC * 30.76mm);
# Draw the thing, with outline

poly(fsp, :fill)
sethue(color_from_palette("indigo"))
poly(fsp, :stroke)
# Pretend we don't know the size, measure and dimension
b = BoundingBox(fsp)
dimension_aligned(boxtopleft(b), boxtopright(b))
# Test to "measure" with more precision than what we get with boundingbox
p1 = Point(-0.3 *SC * 1000mm, 0.0mm)
p2 = Point(0.7 *SC * 1000mm, 0.0mm)
dimension_aligned(p1, p2; unit = mm, offset = -8EM, digits = 0)

gsave()
for i = 0:9
    sethue(PALETTE[i + 1])
    f = SC .* foil_spline_local();
    polyrotate!(f, i * °)
    polymove!(f,  O, O + (-5m, -2m))
    poly(f, :fill)
    bckco = BACKCOLOR
    luminback = lumin(bckco)
    luminfront = get_current_lumin()
    deltalumin = luminback - luminfront
    contrastcol = color_with_lumin(get_current_RGB(), luminfront - deltalumin)
    sethue(contrastcol)
    poly(f, :stroke)
end
grestore()



MechanicalSketch.finish()
nothing
end