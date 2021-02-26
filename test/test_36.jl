import MechanicalSketch: @import_expand, color_with_lumin, empty_figure, finish
import MechanicalSketch: rect, squircle, PALETTE, ∙, WI, HE, O, EM
import MechanicalSketch: @latexify, latexify, place_image, modify_latex
import MechanicalSketch: paint, setmesh, mesh, box, rule, BoundingBox
import MechanicalSketch: @layer, color_with_lumin, setline, sethue, Length
import MechanicalSketch: get_scale_sketch, pixelwidth, text, draw_background
import MechanicalSketch: Point, row_height, circle, blend, addstop, setblend
import MechanicalSketch: setdash, line, RGBA, chroma, saturation, color_with_saturation
import MechanicalSketch: settext, brush, translate, pixelwidth, box
import MechanicalSketch: setopacity
import Base: pop!

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end

# TO DO find a better, easier way. For example, convert to length? That is too general.
WI_l = 1m * WI / get_scale_sketch(m)
HE_l = 1m * HE / get_scale_sketch(m)
include("test_functions_36.jl")

empty_figure(joinpath(@__DIR__, "test_36.png"), height = 15m);
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
moveto_x!(pa, -WI_l / 2 + 1.2 * 3.5w / 2)
Δy = height(pa) * (2 /  (1 + √5))^3
ground = Container{Ground}(; y = Δy, w = 5 *  height(pa), h = Δy)
putin!(pa, ground)
stack = Container{Stack}(; x = -1m, name = "Stack")
putin!(ground, stack)
putin!(stack, Thing{Section}{Mounted}(;name = "1st"))
drawit(pa)

#
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
