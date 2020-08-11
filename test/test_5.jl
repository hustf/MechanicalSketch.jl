using MechanicalSketch
import MechanicalSketch: sethue, background, O, EM, H, m, color_with_luminance

empty_figure(joinpath(@__DIR__, "test_5.png"))
background(color_with_luminance(PALETTE[6], 0.3))
sethue(PALETTE[3])

let
    p1 = O
    p2 = (6EM, 2EM)
    dimension_aligned(O, O + (6EM, 2EM))

    p1 = O + Point(-2.0m, 0.0m)
    p2 = O + Point(-2.0m, 1.0m)
    dimension_aligned(p1, p2)

    p1 = O + Point(-10.0m, -9.0m)
    p2 = O + Point(10.0m, -9.0m)
    dimension_aligned(p1, p2)

    p1 = O + Point(-10.0m, -10.0m)
    p2 = O + Point(-10.0m, 10.0m)
    dimension_aligned(p1, p2)


    p1 = O + Point(10.0m, 10.0m)
    p2 = O + Point(10.0m, -10.0m)
    dimension_aligned(p1, p2)


    MechanicalSketch.finish()
end