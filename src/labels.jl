"""
    box_fill_outline(pt_topleft, colfill; 
                     height = row_height(), width = EM, luminfac = 2,
                     opacity = missing)

Draw a filled box.
Default height adapts to the current 'Top API' font, which is used for text tables.
Outline color luminosity is 200% the luminosity of fill color, if possible.
For dark backgrounds, consider luminfac = 0.5.
By default, opacity is not changed from the current state. Range 0-1, where 1 is opaque.
"""
function box_fill_outline(pt_topleft, colfill; 
                          height = row_height(), width = EM, luminfac = 2, boxopacity = missing)
    gsave()
    !ismissing(boxopacity) && setopacity(boxopacity)
    sethue(colfill)
    box(pt_topleft, pt_topleft + (width, height), :fill)
    # outline
    lu = get_current_lumin()
    sethue(color_with_lumin(colfill, min(100, luminfac * lu)))
    !ismissing(boxopacity) && setopacity(boxopacity)
    box(pt_topleft, pt_topleft + (width, height), :stroke)
    grestore()
end
"""
label_boxed(pt, str; colfill = color_with_lumin(get_current_RGBA(), 0.5 * get_current_lumin()),
               luminfac = 1.0, boxopacity = 0.75, valign = :bottom)

Using the 'Toy API. For keyword arguments, see 'box_fill_outline'. Could be extended with 'text' arguments.
"""
function label_boxed(pt, str; colfill = color_with_lumin(get_current_RGBA(), 0.5 * get_current_lumin()),
               luminfac = 1.0, boxopacity = 0.75, valign = :bottom)
    @layer begin
        box_fill_outline(pt, colfill; luminfac, height = -FS / 2, width = pixelwidth(str), boxopacity)
        sethue(PALETTE[10])
        text(str, pt; valign)
    end
end

"""
    setlabel(endpoint, vx, vy, α)

Add a label at the end point, rounded absolute length with unit.
"""
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