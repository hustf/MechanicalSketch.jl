using MechanicalSketch
import MechanicalSketch: sethue, background, O, EM, HE, m, color_with_lumin, finish, set_scale_sketch
import MechanicalSketch: dimension_aligned, empty_figure, PALETTE

let
empty_figure(filename = joinpath(@__DIR__, "test_14.png"))
background(color_with_lumin(PALETTE[6], 90))
sethue(PALETTE[4])


# 20m horizontal
p1 = O + (-10.0m, -9.0m)
p2 = O + (10.0m, -9.0m)
dimension_aligned(p1, p2)

# 20 m vertical
p1 = O + (-10.0m, -10.0m)
p2 = O + (-10.0m, 10.0m)
dimension_aligned(p1, p2)


function scaleindicators(offset = 4EM)
    # 1m vertical
    p1 = O + (-2.0m, 0.0m)
    p2 = O + (-2.0m, 1.0m)
    dimension_aligned(p1, p2,  offset = offset)

    # 1m horizontal
    p1 = O
    p2 = O + (1.0m, 0.0m)
    dimension_aligned(p1, p2,  offset = offset)
end

for i = 1:10
    sethue(PALETTE[i])
    set_scale_sketch(20m, round(Int, HE * i))
    scaleindicators(i * EM)
end

finish()

# Reset to default:
set_scale_sketch()
nothing
end