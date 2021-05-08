import MechanicalSketch
import MechanicalSketch: color_with_lumin, empty_figure, background, sethue, O, WI, HE, finish
import MechanicalSketch: PALETTE, scale_pt_to_unit, m, mm, km, kg, rope_breaking_strength, rope_weight
import MechanicalSketch: text_table, area_filled, set_scale_sketch, circle, °, text, g, empty_figure
let
BACKCOLOR = color_with_lumin(PALETTE[8], 80);
function restart()
    empty_figure(filename = joinpath(@__DIR__, "test_18.png"))
    background(BACKCOLOR)
    sethue(PALETTE[1])
end
restart()
diameters = [6mm, 8mm, 10mm, 12mm]
mbls = rope_breaking_strength.(diameters)
weights = rope_weight.(diameters) .|> kg/km
circleradius(A) = sqrt(A/π)
radius_filled = circleradius.(area_filled.(diameters))

pos = O - (0.25WI, 0.0)
text_table(pos, diameters = diameters,
                packed_d = 2 .* radius_filled,
                MBL = mbls,
                mbl = mbls .|> g,
                Lineweight = weights)

#
# Draw the rope cross sections
#

set_scale_sketch(sum(diameters) * 1.3, HE)
# Horizontal positions per rope
pts = let
    posx = [0.0]mm
    pop!(posx)
    for (i,d) in enumerate(diameters)
        p = if i == 1
                -0.45 * WI * scale_pt_to_unit(m)
        else
            posx[i-1] + max(5.0mm, d*1.1)
        end
        push!(posx, p)
    end
    pts = map(x-> O +(x, 10.0mm), posx)
end
let
    circle.(pts, 0.5 .* diameters ,:fill)
    labs = string.(diameters)
    plabs = map(diameters, pts) do d, p
        offset = (-0.25 , 0.65 ) .* d
        p + offset
    end
    text.(labs, plabs, 10.0°)
end
# Plot packed area
let
    sethue(color_with_lumin(PALETTE[5], 80))
    circle.(pts , radius_filled, :fill)
end

finish()
set_scale_sketch()

nothing
end