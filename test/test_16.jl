using MechanicalSketch
import MechanicalSketch: sethue, background, O, HE, color_with_lumin
import MechanicalSketch: finish, set_scale_sketch, arrow, °, m, kN, empty_figure
import MechanicalSketch: PALETTE

let
empty_figure(filename = joinpath(@__DIR__, "test_16.png"))
background(color_with_lumin(PALETTE[6], 80))
sethue(PALETTE[4])


function scaleindicator_force(α)
    p1 = O + 2m .* (cos(α), sin(α))
    arrow(p1, 1kN, α = α, labellength = true)
end

for i = 1:10
    sethue(PALETTE[i])
    set_scale_sketch(20kN,  HE * i)
    scaleindicator_force(36° * (i - 1))
end


finish()
# reset default:
set_scale_sketch()
nothing
end