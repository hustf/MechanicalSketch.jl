import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, WI, HE, finish,
    PALETTE,
    m, mm, km, kg, rope_breaking_strength, rope_weight,
    text_table, area_filled, setscale_dist, circle, °, text, g
let
BACKCOLOR = color_with_luminance(PALETTE[8], 0.8);
function restart()
    empty_figure(joinpath(@__DIR__, "test_18.png"))
    background(BACKCOLOR)
    sethue(PALETTE[1])
end
restart()
diameters = [6mm, 8mm, 10mm, 12mm]
mbls = rope_breaking_strength.(diameters)
weights = rope_weight.(diameters) |> kg/km
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

setscale_dist(sum(diameters) * 1.3/ HE)
# Horizontal positions per rope
pts = let
    posx = [0.0]mm
    pop!(posx)
    for (i,d) in enumerate(diameters)
        p = if i == 1
                -0.45 * MechanicalSketch.WI * MechanicalSketch.SCALEDIST
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
    sethue(color_with_luminance(PALETTE[5], 0.8))
    circle.(pts , radius_filled, :fill)
end

finish()
setscale_dist(20m / HE)

nothing
end