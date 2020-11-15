using MechanicalSketch
import MechanicalSketch: sethue, background, O, HE, color_with_luminance,
    finish, setscale_force, arrow, °, m, kN

let
empty_figure(joinpath(@__DIR__, "test_16.png"))
background(color_with_luminance(PALETTE[6], 0.8))
sethue(PALETTE[4])


function scaleindicator_force(α)
    p1 = O + 2m .* (cos(α), sin(α))
    arrow(p1, 1kN, α = α, labellength = true)
end

for i = 1:10
    sethue(PALETTE[i])
    setscale_force(20kN / HE / i)
    scaleindicator_force(36° * (i - 1))
end


finish()
# reset default:
setscale_force()
nothing
end