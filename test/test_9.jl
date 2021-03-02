using MechanicalSketch
import MechanicalSketch: °, background, sethue, O, PT, finish, empty_figure
import MechanicalSketch:m, color_with_lumin, drawcart, setline, circle, PALETTE
let
BACKCOLOR = color_with_lumin(PALETTE[3], 70)
function restart()
    empty_figure(joinpath(@__DIR__, "test_9.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()
circle(O, 1.0m, :fill)
sethue(PALETTE[4])
drawcart()
drawcart(p = O + (0m, -3m), α = 30°)
setline(2PT)
drawcart(p = O + (0m, -6m), α = 45°)
sethue(PALETTE[9])
drawcart(p = O + (0m, -9m), α = 60°)
finish()
nothing
end