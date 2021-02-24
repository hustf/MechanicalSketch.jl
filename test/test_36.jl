import MechanicalSketch: @import_expand, color_with_lumin, empty_figure, finish
import MechanicalSketch: rect, squircle, PALETTE, ∙, WI, HE, O, EM
import MechanicalSketch: @latexify, latexify, place_image, modify_latex
import MechanicalSketch: paint, setmesh, mesh, box, rule, BoundingBox
import MechanicalSketch: @layer, color_with_lumin, setline, sethue, Length
import MechanicalSketch: get_scale_sketch, pixelwidth, text, draw_background
import MechanicalSketch: Point, row_height, circle, blend, addstop, setblend
import MechanicalSketch: setdash, line, RGBA, chroma, saturation, color_with_saturation
import MechanicalSketch: settext

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
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
settext("Each panel, too:", pt, markup = true)

finish()
#=

ptgroundleft = O + (-WI / 2,  HE / 2 - 2EM)


# Positional frames
suffix = "@1"
framewidth = 2m
stacks = Vector{Stack}()
push!(stacks, Stack(;name = "Tower 1", x = (-WI_l + framewidth ) / 2 ))
drawit.(stacks; suffix, framewidth)
#
suffix = "@2"
framewidth = 3m
stack = last(stacks)
moveit!(stack, framewidth, 0m)
push!(stack.children, SingleThing(name = "1st"))
thing = last(children(stack))
place_on_top!(thing, stack)
drawit.(stacks; suffix, framewidth)
# 
suffix = "@3"

moveit!(stack, framewidth, 0m)
framewidth = 6m
push!(stack.children, SingleThing(name = "2nd"))
thing = last(children(stack))
Δx = 2m
place_beside!(thing, stack, Δx)
drawit.(stacks; suffix, framewidth)


finish()
=#