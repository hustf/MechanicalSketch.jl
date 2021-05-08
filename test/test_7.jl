using MechanicalSketch
import MechanicalSketch: foil_draw, °, background, sethue, O, finish
import MechanicalSketch: m, N, kN, s, arrow, color_from_palette, color_with_lumin
import MechanicalSketch: empty_figure, PALETTE

let
BACKCOLOR = color_with_lumin(PALETTE[5], 30)
function restart()
    empty_figure(filename = joinpath(@__DIR__, "test_7.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()
p = O + (-9m, 9m)
foil_draw(p)
p += (0m, -1m)
foil_draw(p, rel_scale = 2)
p += (0m, -1m)
foil_draw(p, rel_scale = 2, backgroundcolor = BACKCOLOR)
p += (0m, -1m)
foil_draw(p, rel_scale = 4, backgroundcolor = BACKCOLOR)
p += (0m, -1m)
sethue(PALETTE[10])
foil_draw(p, rel_scale = 8, backgroundcolor = BACKCOLOR,
          α = -6°)

sethue(PALETTE[9])

p += (0m, -2m)
sethue(PALETTE[10])
foil_draw(p, rel_scale = 8, backgroundcolor = BACKCOLOR,
          α = -10°)
# Force vector
sethue(color_from_palette("green"))
arrow(p, 1kN, 5kN, α = -10°, backgroundcolor = BACKCOLOR)

# Force vector
p += (0m, -1m)
sethue(PALETTE[8])
arrow(p, 1kN, 5kN, α = 45°, backgroundcolor = BACKCOLOR, labellength = true)

p += (0m, -1m)
sethue(PALETTE[8])
arrow(p, 10kN, 0kN, α = 0°, backgroundcolor = BACKCOLOR)

# Velocity vector
p += (8m, -1m)
sethue(PALETTE[6])
arrow(p, 7m/s, 0m/s, α = 0°)

p += (0m, -1m)
sethue(PALETTE[3])
arrow(p, 30m/s, 3m/s, α = 0°)

p += (0m, -1m)
sethue(PALETTE[2])
arrow(p, 10m/s, 0m/s, α = 0°)

finish()

nothing
end