
circle(p::Point, r::Length, action) = circle(p, scale(r), action)

function ellipse(p::Point, w::Q, h::Q, action=:none)  where {Q<:Length}
    ellipse(p, scale(w), scale(h), action)
end
function squircle(center::Point, hradius::Q, vradius::Q, action=:none;
    kwargs...) where {Q<:Length}
    squircle(center, scale(hradius), scale(vradius),
    action;
    kwargs...)
end

#= Full list of curve functions:
 circle, center3pts, ellipse, sqcircle,
arc, carc, arc2r, carc2r, sector, pie, curve, circlepath,
hypotrochoid, epitrochoid, spiral, intersection2circles,
intersectioncirclecircle, circlepointtangent
=#