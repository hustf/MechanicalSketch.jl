using MechanicalSketch
import MechanicalSketch: °, background, sethue, O, PT, finish,
      m, s, arrow, color_with_lumin

let
BACKCOLOR = color_with_lumin(PALETTE[8], 70)
function restart()
    empty_figure(joinpath(@__DIR__, "test_8.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()
p = O + (0m, 0m)
arrow(p, 30m/s, 3m/s, α = 0°, backgroundcolor = BACKCOLOR)
arrow(p, 30m/s, 3m/s, α = 30°, backgroundcolor = BACKCOLOR)
arrow(p, 30m/s, 0m/s, α = 90°, backgroundcolor = BACKCOLOR)
arrow(p, 30m/s, 0m/s, α = 180°, backgroundcolor = BACKCOLOR)
arrow(p, 30m/s, 0m/s, α = 225°, backgroundcolor = BACKCOLOR)
arrow(p, 30m/s, 0m/s, α = 270°, backgroundcolor = BACKCOLOR)
arrow(p, 30m/s, 0m/s, α = 300°, backgroundcolor = BACKCOLOR)

for i = 1:10
    sethue(PALETTE[i])
    α = 36° * i
    p = O + (-8m, -2m) + Point(1m * cos(α), 1m * sin(α))
    arrow(p, i * 3m/s, 0m/s, α = α, backgroundcolor = BACKCOLOR,  labellength = true)
end

for i = 1:10
    sethue(PALETTE[i])
    α = 36° * i
    p = O + (8m, 4m) + Point(1m * cos(α), 1m * sin(α))
    arrow(p, 0m/s, i * 3m/s, α = α, backgroundcolor = BACKCOLOR, linewidth = 2PT)
end

for i = 1:20
    sethue(get(PALETTE, i / 20))
    α = 18° * i
    p = O + (8m, -4m) + Point(2m * cos(α), 2m * sin(α))
    arrow(p, 0.0m/s, i * 1.5m/s, α = α, backgroundcolor = BACKCOLOR, linewidth = 1.5PT)
end


finish()
nothing
end