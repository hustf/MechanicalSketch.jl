using MechanicalSketch
import MechanicalSketch: sethue, background, O, HE, m, s, color_with_luminance,
    finish, set_scale_sketch, arrow, °

let
empty_figure(joinpath(@__DIR__, "test_15.png"))
background(color_with_luminance(PALETTE[6], 0.8))
sethue(PALETTE[4])


function scaleindicator_velocity(α)
    p1 = O + 2m .* (cos(α), sin(α))
    arrow(p1, 1m/s, α = α, labellength = true)
end

for i = 1:10
    sethue(PALETTE[i])
    set_scale_sketch(70m/s, HE * i)
    scaleindicator_velocity(36° * (i - 1))
end

finish()

# Reset default:
set_scale_sketch()
nothing
end