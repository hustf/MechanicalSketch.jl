"""
    circle(p::Point, r::Length, action)

    where

action can be :nothing, :fill, :stroke, :fillstroke, :fillpreserve, :strokepreserve, :clip.
    The default is :nothing.
"""
circle(p::Point, r::Length, action) = circle(p, scale_sketch(r), action)

function ellipse(p::Point, w::Q, h::Q, action=:none)  where {Q<:Length}
    ellipse(p, scale_sketch(w), scale_sketch(h), action)
end
function squircle(center::Point, hradius::Q, vradius::Q, action=:none;
    kwargs...) where {Q<:Length}
    squircle(center, scale_sketch(hradius), scale_sketch(vradius),
    action;
    kwargs...)
end

#= Full list of curve functions:
 circle, center3pts, ellipse, sqcircle,
arc, carc, arc2r, carc2r, sector, pie, curve, circlepath,
hypotrochoid, epitrochoid, spiral, intersection2circles,
intersectioncirclecircle, circlepointtangent
=#



"""
    diminishingtrace(center, vx, vy)

center is local origo, a Point, typically equal to global O.
vx, vy are vectors of corresponding coordinate quantities.

Plots a polyline until NaN or end of vectors.
The first segment is drawn with opacity 1, decreasing to one step before translucent(zero)
at the last segment
"""
function diminishingtrace(center, vx, vy)
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