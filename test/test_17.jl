import MechanicalSketch
import MechanicalSketch: mm, kg, m, set_scale_sketch, HE, WI, EM, PT, circle, text, N, kN, PALETTE,
    color_with_luminance, empty_figure, background, sethue, O, °, finish,
    line, setline, setopacity
let
# Rope data from https://www.hendrikvedergroup.com/_asset/_public/Hendrik-Veder-Group/Downloads/8896-03-Dyneema-folder-offset_LR-v4.pdf
# Diameters below 12 mm are excluded here, because they vary too much for reasonable generalization. Properties are generally better for
# smaller rope
ROPE_D = [12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44,
    46, 48, 50, 52, 56, 60, 64, 68, 72, 80, 88, 96]mm
ROPE_WEIGHT = [9.50, 12.80, 16, 20.80, 25.50, 30.50, 35.80, 41, 46.50, 52, 57, 62.50, 68, 74, 84, 93,
    102, 111, 121, 131, 141, 163, 175, 200, 226, 254, 313, 379, 451]kg/100m
ROPE_MINIMUM_BREAK = [161.90, 215.80, 269.80, 343.30, 407.10, 490.50, 569, 647.40, 725.90, 799.50, 868.20, 941.70, 1020.20,
    1098.70, 1245.80, 1373.40, 1491.10, 1618.60, 1755.90, 1893.30, 2020.80, 2315.10, 2472, 2766.30, 3099.90, 3413.80, 4139.70,
    4934.30, 5768.10]kN
ρ_SK75 = 0.975 * 0.001kg/(10mm)^3
σ_TS_SK75 = 3600N/mm^2

BACKCOLOR = color_with_luminance(PALETTE[8], 0.9);
function restart()
    empty_figure(joinpath(@__DIR__, "test_17.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
    set_scale_sketch(sum(ROPE_D) * 1.3, HE)
end
restart()

# Horizontal positions per rope
pts = let
    posx = [0.0]mm
    pop!(posx)
    for (i,d) in enumerate(ROPE_D)
        p = if i == 1
                -0.45 * MechanicalSketch.WI * MechanicalSketch.SCALEDIST
        else
            posx[i-1] + max(60.0mm, d*1.1)
        end
        push!(posx, p)
    end
    pts = map(x-> O +(x, 700.0mm), posx)
end
let
    circle.(pts, ROPE_D ./ 2,:fill)
    labs = string.(ROPE_D)
    text.(labs, O + (0, EM) .+pts, -60.0°)
end

circlearea(d) = π / 4 * d^2
circleradius(A) = sqrt(A/π)
# Plot packed area
let
    A_rope = ROPE_WEIGHT ./ ρ_SK75 |> mm^2
    sethue(color_with_luminance(PALETTE[5], 0.8))
    circle.(pts , circleradius.(A_rope),:fill)
end

"Relative filled areas, actual to full circle"
area_rel =  (ROPE_WEIGHT ./ ρ_SK75 |> mm^2) ./ circlearea.(ROPE_D)
# Plot relative filled areas
setline(3PT)
bottoms = map(pt -> pt + (0.0mm, -600.0mm), pts)
tops = map(pt -> pt + (0.0mm, 300.0mm), bottoms)
line.(bottoms, tops, :stroke)
stri = "Fill factors and approximation (green line)"
text(stri, tops[1] + (0.0, -0.5EM))


sethue(PALETTE[4])
map(tops, bottoms, area_rel) do t, b, rel
    line(b, b + (t - b) * rel, :stroke)
end
# lsq method applied
fill_factor(d) = (-0.003*d/mm + 0.853)
area_filled(d) = fill_factor(d)* circlearea(d)

# Plot appproximated area
sethue(PALETTE[3])
setopacity(0.5)
map(tops, bottoms, ROPE_D) do t, b, d
    rel = fill_factor(d)
    top = b + (t - b) * rel
    line(top + (-0.5EM, 0.0), top + (0.5EM, 0.0), :stroke)
end
setopacity(1.0)


ideal_spin_strength(d) = area_filled(d) * σ_TS_SK75 |> kN
spinfactors = ROPE_MINIMUM_BREAK./ ideal_spin_strength.(ROPE_D)
#lsq method applied
spin_factor(d) = 5*10^-5 * (d/mm)^2 + -0.0059*(d/mm) + 0.5504
breaking_strength(d) = spinfactor(d) * ideal_spin_strength(d)


# Plot spin factors
setline(3PT)
sethue(color_with_luminance(PALETTE[5], 0.8))
bottoms = map(pt -> pt + (0.0mm, -1200.0mm), pts)
tops = map(pt -> pt + (0.0mm, 300.0mm), bottoms)
line.(bottoms, tops, :stroke)
stri = "Spin factors and approximation (green line)"
text(stri, tops[1] + (0.0, -0.5EM))

sethue(PALETTE[4])
map(tops, bottoms, spinfactors) do t, b, rel
    line(b, b + (t - b) * rel, :stroke)
end

# Plot appproximated spin factor
sethue(PALETTE[3])
setopacity(0.5)
map(tops, bottoms, ROPE_D) do t, b, d
    rel = spin_factor(d)
    top = b + (t - b) * rel
    line(top + (-0.5EM, 0.0), top + (0.5EM, 0.0), :stroke)
end
setopacity(1.0)


finish()
# Reset default
set_scale_sketch()

nothing
end