"""
    arrow(p::Point, f::F; kwargs...) where F <: Force

Draw a single force arrow with filled head.

    p        starting position.
    f        scalar force quantity.
    α = 0°   is direction to the right, positive values rotate around z axis.

"""
arrow(p::Point, f::F; kwargs...) where F <: Force = arrow(p, f, 0 * f; kwargs...)


"""
    arrow(p::Point, f::ForceTuple; kwargs...)

Draw a single velocity arrow - no filled arrow head.

p     starting position (at the normal between vanes tip and arrow spine)
F     is a force tuple referred to an x-axis which can optionally be rotated around z by
      keyword argument α.
components = false: No components forces on the x and y axes are drawn.
"""
function arrow(p::Point, f::ForceTuple; components = true, kwargs...)
    if !components
        αcalc = atan(f[2], f[1]) |> rad |> °
        F = hypot(f)
        arrow(p, F, 0.0 * f[2]; kwargs..., α = αcalc)
    else
        arrow(p, f[1], f[2]; kwargs...)
    end
end

"""
    arrow(p::Point, Fx::F, Fy::F;
        α::Angle = 0°,
        linewidth = PT,
        backgroundcolor = colorant"white",
        labellength::Bool = false) where {F <: Force}

Draw a force arrow with filled head resultant, and perpendicular components in dashed style.
p                  starting position.
Fx, Fy             scalar velocity perpendicular components.
α                  defines the direction of the x component.
backgroundcolor    is used to pick colors for components and label outlines
labellength = true adds a label with arrow length (i.e. vector norm) and unit
"""
function arrow(p::Point, Fx::F, Fy::F;
                α::Angle = 0°,
                linewidth = PT,
                backgroundcolor = colorant"white",
                labellength::Bool = false) where {F <: Force}
    # TODO linewidth - drop or implement
    # TODO backgroundcolor - drop or implement
    ΔFx = Point(Fx * cos(α), Fx *sin(α))
    ΔFy = Point(-Fy * sin(α), Fy *cos(α))
    ΔF = ΔFx + ΔFy

    # Prepare color selection
    luminback = lumin(backgroundcolor)
    luminfront = get_current_lumin()
    avglumin = (luminback + luminfront) / 2
    curcol = get_current_RGB()
    avgcol = color_with_lumin(curcol, avglumin)
    # Draw the components, but only if the resultant is not coincident with one of them.
    if hypot(ΔFx) > 0 && hypot(ΔFy) > 0
        gsave()
        setdash("longdashed")
        deltalumin = luminback - luminfront
        lesscontrast = color_with_lumin(get_current_RGB(), luminfront + deltalumin)
        sethue(lesscontrast)
        shaftlength = hypot(ΔFx)
        arrowheadlength = shaftlength > 3 * EM ? EM :  shaftlength / 3
        arrow_nofill(p, p + ΔFx, arrowheadlength = arrowheadlength, arrowheadangle = pi/12, linewidth = PT / 2)
        shaftlength = hypot(ΔFy)
        arrowheadlength = shaftlength > 3 * EM ? EM :  shaftlength / 3
        arrow_nofill(p, p + ΔFy, arrowheadlength = arrowheadlength, arrowheadangle = pi/12, linewidth = PT / 2)
        grestore()
    end

    # Draw the resultant arrow
    endpoint = p + ΔF
    shaftlength = hypot(ΔF)
    arrowheadlength = shaftlength > 3 * EM ? EM :  shaftlength / 3
    if !isapprox(shaftlength, 0.0)
        arrow(p, endpoint, arrowheadlength = arrowheadlength, arrowheadangle = pi/12, linewidth = PT)
    else
        # with shaft length approximately zero, draw two opposing arrows with minimum possible shaft lengths
        tiny = oneunit(shaftlength) # almost zero
        arrow(p + ( tiny, 0), endpoint, arrowheadlength = arrowheadlength, arrowheadangle = pi/12, linewidth = PT)
        arrow(p + (-tiny, 0), endpoint, arrowheadlength = arrowheadlength, arrowheadangle = pi/12, linewidth = PT)
    end

    # add an optional label with the euclidean length of the resultant, at the tip of it.
    if labellength
        sethue(avgcol)
        fontface("Calibri bold")
        setlabel(endpoint, Fx, Fy, α)
        fontface("Calibri")
        sethue(curcol)
        setlabel(endpoint, Fx, Fy, α)
    end
end


"""
arrow(p::Point, v::V; kwargs...) where V<:Velocity

Draw a single velocity arrow - no filled arrow head.

p        starting position (at the normal between vanes tip and arrow spine).
v        scalar velocity
α = 0°   is direction to the right, positive values rotate around z axis.
"""
arrow(p::Point, v::V; kwargs...) where V<:Velocity = arrow(p, v, 0 * v; kwargs...)




"""
    arrow(p::Point, v::VelocityTuple; kwargs...)

Draw a single velocity arrow - no filled arrow head.

p     starting position (at the normal between vanes tip and arrow spine)
v     is a 2-tuple here, but you can optionally rotate the x-axis by keyword argument α.
"""
arrow(p::Point, v::VelocityTuple; kwargs...) = arrow(p, v[1], v[2]; kwargs...)


"""
    arrow(p::Point, vx::V, vy::V;
               α::Angle = 0°,
               linewidth = PT,
               backgroundcolor = colorant"white",
               labellength::Bool = false) where {V <: Velocity}

Draw a single velocity arrow - no filled arrow head.

p                   starting position (at the normal between vanes tip and arrow spine).
vx, vy              scalar velocity perpendicular components.
α                   defines the direction of the x component.
backgroundcolor     is used to pick a color for an outline.
labellength = true  label at the point with arrow length and unit
"""
function arrow(p::Point, vx::V, vy::V;
               α::Angle = 0°,
               linewidth = PT,
               backgroundcolor = colorant"white",
               labellength::Bool = false) where {V <: Velocity}
    Δvx = Point(vx * cos(α), vx *sin(α))
    Δvy = Point(-vy * sin(α), vy *cos(α))
    Δv = Δvx + Δvy
    endpoint = p + Δv
    luminback = lumin(backgroundcolor)
    luminfront = get_current_lumin()
    avglumin = (luminback + luminfront) / 2
    curcol = get_current_RGB()
    avgcol = color_with_lumin(backgroundcolor, avglumin)
    gsave()
    setline(linewidth * 2)
    sethue(avgcol)
    curved_point_arrow_with_vanes(p, Δv, endpoint, linewidth)
    sethue(curcol)
    setline(linewidth)
    curved_point_arrow_with_vanes(p, Δv, endpoint, linewidth)
    # add a label with the euclidean length of the arrow, at the tip of it.
    if labellength
        sethue(avgcol)
        fontface("Calibri bold")
        setlabel(endpoint, vx, vy, α)
        fontface("Calibri")
        sethue(curcol)
        setlabel(endpoint, vx, vy, α)
    end
    grestore()
    return nothing
end

"Add a label at the end point, rounded absolute length with unit."
function setlabel(endpoint, vx, vy, α)
    Δvx = (vx * cos(α), vx *sin(α))
    Δvy = (-vy * sin(α), vy *cos(α))
    Δv = Δvx + Δvy
    l = hypot(Δv)
    rounded = round(unit(l), l, digits = 1)
    direction = atan(Δv[2], Δv[1]) |> °
    labdir = direction + 90°
    labpos = if -90° <= labdir < -70°
        :S
    elseif labdir < -20°
        :SE
    elseif labdir < 20°
        :E
    elseif labdir < 70°
        :NE
    elseif labdir < 110°
        :N
    elseif labdir < 160°
        :NW
    elseif labdir < 200°
        :W
    elseif labdir < 250°
        :SW
    else
        :S
    end
    label(string(rounded) , labpos, endpoint, offset = div(EM, 4))
end
function curved_point_arrow_with_vanes(p, Δv, endpoint, linewidth)
    arrowheadangle = pi/24

    isapprox(Δv, Point(0,0)) && throw(error("can't draw velocity arrow between two identical points"))
    shaftlength = hypot(Δv)
    arrowheadlength = shaftlength > 3 * EM ? EM :  shaftlength / 3

    shaftangle = atan(p.y - endpoint.y, p.x - endpoint.x)

    # shorten the length so that lines
    # stop before we get to the arrow
    # thus wide shafts won't stick out through the head of the arrow.
    max_undershoot = shaftlength - ((linewidth/2) / tan(arrowheadangle))
    ratio = max_undershoot / shaftlength
    tox = p.x + Δv.x * ratio
    toy = p.y + Δv.y * ratio
    fromx = p.x
    fromy = p.y

    # draw the shaft of the arrow
    newpath()
    line(Point(fromx, fromy), Point(tox, toy), :stroke)

    # draw the arrowhead
    arrowheadtopsideangle = shaftangle + arrowheadangle
    arrowheadtopsidemidangle = shaftangle + 0.67arrowheadangle
    topx = endpoint.x + cos(arrowheadtopsideangle) * arrowheadlength
    topy = endpoint.y + sin(arrowheadtopsideangle) * arrowheadlength
    topmidx = endpoint.x + cos(arrowheadtopsidemidangle) * arrowheadlength / 2
    topmidy = endpoint.y + sin(arrowheadtopsidemidangle) * arrowheadlength / 2

    arrowheadbottomsideangle = shaftangle - arrowheadangle
    arrowheadbottomsidemidangle = shaftangle - 0.67arrowheadangle
    botx = endpoint.x + cos(arrowheadbottomsideangle) * arrowheadlength
    boty = endpoint.y + sin(arrowheadbottomsideangle) * arrowheadlength
    botmidx = endpoint.x + cos(arrowheadbottomsidemidangle) * arrowheadlength / 2
    botmidy = endpoint.y + sin(arrowheadbottomsidemidangle) * arrowheadlength / 2

    poly([Point(topx, topy), Point(topmidx, topmidy), endpoint,
        Point(botmidx, botmidy), Point(botx, boty)], :stroke)

    # draw the rearmost vane
    vaneangle = shaftangle + π / 3
    vanelength = arrowheadlength / 2
    vanex = fromx + cos(vaneangle) * vanelength
    vaney = fromy + sin(vaneangle) * vanelength

    # draw the mid vane
    from1x = p.x + Δv.x * (1 - ratio)
    from1y = p.y + Δv.y * (1 - ratio)
    vane1x = from1x + cos(vaneangle) * vanelength
    vane1y = from1y + sin(vaneangle) * vanelength

    # draw the front vane
    from2x = p.x + Δv.x * 2 * (1 - ratio)
    from2y = p.y + Δv.y * 2 * (1 - ratio)
    vane2x = from2x + cos(vaneangle) * vanelength
    vane2y = from2y + sin(vaneangle) * vanelength

    #poly([Point(vanex, vaney), Point(fromx, fromy)] , :stroke)
    #poly([Point(vane1x, vane1y), Point(from1x, from1y)] , :stroke)
    #poly([Point(vane2x, vane2y), Point(from2x, from2y)] , :stroke)

    poly([Point(vanex, vaney), Point(fromx, fromy), Point(from1x, from1y),
        Point(vane1x, vane1y), Point(from1x, from1y), Point(from2x, from2y),
        Point(vane2x, vane2y)] , :stroke)

end






"""
Same as Luxor.arrow, except for leaving the arrow head unfilled
"""
function arrow_nofill(startpoint::Point, endpoint::Point;
    linewidth=1.0,
    arrowheadlength=10,
    arrowheadangle=pi/8,
    decoration = 0.5,
    decorate = () -> ())
    gsave()
    setlinejoin("butt")
    setline(linewidth)

    isapprox(startpoint, endpoint) && throw(error("can't draw arrow between two identical points"))
    shaftlength = distance(startpoint, endpoint)
    shaftangle = atan(startpoint.y - endpoint.y, startpoint.x - endpoint.x)
    arrowheadtopsideangle = shaftangle + arrowheadangle
    # shorten the length so that lines
    # stop before we get to the arrow
    # thus wide shafts won't stick out through the head of the arrow.
    max_undershoot = shaftlength - ((linewidth/2) / tan(arrowheadangle))
    ratio = max_undershoot/shaftlength
    tox = startpoint.x + (endpoint.x - startpoint.x) * ratio
    toy = startpoint.y + (endpoint.y - startpoint.y) * ratio
    fromx = startpoint.x
    fromy = startpoint.y

    # draw the shaft of the arrow
    newpath()
    line(Point(fromx, fromy), Point(tox, toy), :stroke)

    # draw the arrowhead
    topx = endpoint.x + cos(arrowheadtopsideangle) * arrowheadlength
    topy = endpoint.y + sin(arrowheadtopsideangle) * arrowheadlength
    arrowheadbottomsideangle = shaftangle - arrowheadangle
    botx = endpoint.x + cos(arrowheadbottomsideangle) * arrowheadlength
    boty = endpoint.y + sin(arrowheadbottomsideangle) * arrowheadlength
    poly([Point(topx, topy), endpoint, Point(botx, boty)], :stroke)

    # prepare to add decorations at point along shaft
    for decpos in decoration
        decpoint = between(startpoint, endpoint, decpos)
        slp = slope(startpoint, endpoint)
        @layer begin
            translate(decpoint)
            rotate(slp)
            decorate()
        end
    end
    grestore()
end
