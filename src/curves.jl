# To do: Replace Length with any quantity, scale with scale_to_pt
# Write a macro to extend all curve-like functions which take input not a Point.
"""
    circle(p::Point, r::Length, action)
    circle(p::Point; r = missing, d = missing, action = :stroke)

    where

action can be :nothing, :fill, :stroke, :fillstroke, :fillpreserve, :strokepreserve, :clip.
    The default without keyword arguments is :nothing.
"""
circle(p::Point, r::Length, action) = circle(p, scale_to_pt(r), action)
function circle(p::Point; r = missing, d = missing, action = :stroke)
    @assert ismissing(r) + ismissing(d) == 1
    r = ismissing(d) ? r : d / 2
    circle(p, r, action)
end
"ellipse(p::Point, w::Q, h::Q; action = :stroke)  where {Q<:Quantity}"
function ellipse(p::Point, w::Q, h::Q; action = :stroke)  where {Q<:Quantity}
    ellipse(p, scale_to_pt(w), scale_to_pt(h), action)
end
"squircle(center::Point, hradius::Q, vradius::Q; action=:stroke, kwargs...)  where {Q<:Quantity}"
function squircle(center::Point, hradius::Q, vradius::Q; action = :stroke, kwargs...) where {Q<:Quantity}
    squircle(center, scale_to_pt(hradius), scale_to_pt(vradius), action;  kwargs...)
end

"rect(p::Point, w::Q, h::Q; action=:stroke, kwargs...)  where {Q<:Quantity}"
function rect(p::Point, w::Q, h::Q; action=:stroke, kwargs...)  where {Q<:Quantity}
    rect(p, scale_to_pt(w), scale_to_pt(h), action; kwargs...)
end
#= Full list of curve functions:
 circle, center3pts, ellipse, squircle,
arc, carc, arc2r, carc2r, sector, pie, curve, circlepath,
hypotrochoid, epitrochoid, spiral, intersection2circles,
intersectioncirclecircle, circlepointtangent
=#



"""
    trace_diminishing(center, vx, vy)

center is local origo, a Point, typically equal to global O.
vx, vy are vectors of corresponding coordinate quantities.

Plots a polyline until NaN or end of vectors.
The first segment is drawn with opacity 1, decreasing to one step before translucent(zero)
at the last segment
"""
function trace_diminishing(center, vx, vy)
    gsave()
    n = length(vx)
    opacity = 1.0
    xo, yo  = vx[1], vy[1]
    for (x, y) in zip(vx[2:end], vy[2:end])
        isnan(x) && break
        isnan(y) && break
        setopacity(opacity)
        move(center + (xo, yo))
        line(center + (x, y))
        do_action(:stroke)
        xo, yo = x, y
        opacity -= 1.0 / (n - 1)
    end
    grestore()
end

"""
    trace_rotate_hue(center, vx, vy; rotatehue_degrees_total = 270°)

center is local origo, a Point, typically equal to global O.
vx, vy are vectors of corresponding coordinate quantities.
rotatehue_degrees_total = 270° is the amount of hue rotation from the current
hue. It varies gradually. The hue is reset afterwards. If 360°, the starting
color and the ending color will be the same.

Plots a polyline until NaN or end of vectors.
The first segment is drawn with opacity 1, decreasing to one step before translucent(zero)
at the last segment
"""
function trace_rotate_hue(center, vx, vy; rotatehue_degrees_total = 270°)
    gsave()
    n = length(vx)
    startcolo = get_current_RGB()
    xo, yo  = vx[1], vy[1]
    count = 0
    for (x, y) in zip(vx[2:end], vy[2:end])
        isnan(x) && break
        isnan(y) && break
        move(center + (xo, yo))
        line(center + (x, y))
        do_action(:stroke)
        count += 1
        rotatedeg = count * rotatehue_degrees_total / n
        sethue(rotate_hue(startcolo, rotatedeg))
        xo, yo = x, y
    end
    grestore()
end
"""
    box_fill_outline(pt_topleft, colfill; 
                     height = row_height(), width = EM, luminfac = 2)

Draw a filled box.
Default height adapts to the current 'Top API' font, which is used for text tables.
Outline color luminosity is 200% the luminosity of fill color, if possible.
For dark backgrounds, consider luminfac = 0.5
"""
function box_fill_outline(pt_topleft, colfill; 
                          height = row_height(), width = EM, luminfac = 2)
    gsave()
    sethue(colfill)
    box(pt_topleft, pt_topleft + (width, height), :fill)
    # outline
    lu = get_current_lumin()
    sethue(color_with_lumin(colfill, min(100, luminfac * lu)))
    box(pt_topleft, pt_topleft + (width, height), :stroke)
    grestore()
end
setline(x::Length) = setline(scale_to_pt(x))