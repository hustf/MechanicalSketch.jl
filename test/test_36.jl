import MechanicalSketch: @import_expand, color_with_lumin, empty_figure, finish
import MechanicalSketch: rect, squircle, PALETTE, ∙, WI, HE, O, EM
import MechanicalSketch: @latexify, latexify, place_image, modify_latex
import MechanicalSketch: paint, setmesh, mesh, box, rule, BoundingBox
import MechanicalSketch: @layer, color_with_lumin, setline, sethue, Length
import MechanicalSketch: scale_to_pt, pixelwidth, text, draw_background
import MechanicalSketch: Point, row_height, circle, blend, addstop, setblend
import MechanicalSketch: setdash, line, RGBA, chroma, saturation, color_with_saturation
import MechanicalSketch: settext, brush, translate, pixelwidth, box
import MechanicalSketch: setopacity, scale_to_pt, scale_pt_to_unit
import Base.pop!


if !@isdefined m²
    @import_expand(~m, s, °)
end
include("test_functions_36.jl")

empty_figure(filename = joinpath(@__DIR__, "test_36.png"), height = 15m);
pt = O + (-WI / 2, -HE / 2) + (EM, 2.5EM)
str = "<big>Testing</big>    <i>a)</i> latex    <i>b)</i> brush strokes    <i>c)</i> sequence of cropped panels\r
       The blocks use the golden ratio:"
settext(str, pt, markup = true)
pt += (0, 0.5EM)
# This assigns value to w:
expression = :(w = (1.0m * (1 + √5)) / 2)
eval(expression)
showexpression = :($expression = $(round(m, w; digits =3)))
ptul, ptbr, latexscale = place_image(pt + (3EM, 0), latexify(showexpression); height = 3EM, centered = false)
pt += (0, 1.5EM + ptbr[2] - ptul[2])
settext("Each 'comic panel', too. Panel origo is circled:", pt, markup = true)
# A panel has origo at the middle of the bottom line (that's how it will be drawn)
pt += (0.0m, - 2.5m)
panelorigo = pt + (3EM, 0) + (w, 0.0m)
circle(panelorigo; d= 1m)
pa = Container{Panel}(name = "panel")
moveto!(pa, panelorigo )
drawit(pa)
pt += (0, 2EM)
settext("Start comic strip:", pt, markup = true)
#
pa.name = "1"
move_y!(pa, -7m)
set_width_height!(pa, 3.5w, 3.5m)
moveto_x!(pa, 1.2 * 3.5w / 2 + scale_pt_to_unit(m) * (-WI / 2 ))
Δy = height(pa) * (2 /  (1 + √5))^3
ground = Container{Ground}(; y = Δy, w = 5 *  height(pa), h = Δy)
putin!(pa, ground)
stack = Container{Stack}(; x = -1m, name = "Stack")
putin!(ground, stack)
putin!(stack, Thing{Section}{Mounted}(;name = "1st"))
drawit(pa)

pa.name = "2"
move_x!(pa,  1.2 * 3.5w)
putin!(ground, Thing{Section}{Transit}(;name = "2nd", y = 0.25m, x = 1.0m ))
drawit(pa)

#
pa.name = "3"
move_x!(pa,  1.2 * 3.5w)
putin!(stack, Thing{Section}{Mounted}(;name = "2nd"))
pop!(ground)
drawit(pa)

finish()

#=import MechanicalSketch: BezierPath, BezierPathSegment, bezier, bezier′, bezier′′, makebezierpath, drawbezierpath, bezierpathtopoly, beziertopoly, pathtobezierpaths,
bezierfrompoints, beziercurvature, bezierstroke, setbezierhandles, shiftbezierhandles
h = 1m
empty_figure(filename = joinpath(@__DIR__, "test_36.png"), height = 15m);
pts = [Point(-w,-w),
Point(-w,w),
Point(w,w),
Point(w,-w),
Point(-w,-w)]

for (sm, ptx) in zip(range(0.0, 1.0; length = 4), 0.5.*[-0.75WI, -0.25WI, 0.25WI, 0.75WI])
   pt = Point(ptx, 0.0)
   be = makebezierpath(pts .+ pt; smoothing = sm)
   drawbezierpath(be, :stroke; close = true)
end
be = makebezierpath(pts; smoothing = 0.1)
=#