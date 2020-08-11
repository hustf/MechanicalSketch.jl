using MechanicalSketch
import MechanicalSketch: W, O, line, label, EM, background, sethue, setdash, midpoint,
    rotate, fontface, getrotation, fontsize, FS, scale, translate, color_with_luminance
let
    this_fig = empty_figure(joinpath(@__DIR__, "test_4.png"))
    background(color_from_palette("seagreen1"))
    sethue(color_with_luminance(color_from_palette("darkblue"), 0.2))

    label("O", :NW, O)
    function labelelledtri()
        p1 = O + (10EM, 0)
        line(O, p1, :stroke)
        label(string(p1), :SE, p1)

        p2 = p1 + (0, 10EM)
        line(p1, p2, :stroke)
        label(string(p2), :SE, p2)

        setdash("longdashed")
        line(p2, O, :stroke)
        setdash("solid")
        label("longdashed", :NE, midpoint(p2, O))

        fontface("Calibri-bold")
        fontsize(FS * 1.2)
        label("Rotation " * string(round(getrotation()*180/π)) * "°", :N, midpoint(O, p1))
        fontsize(FS)
    end

    labelelledtri()
    rotate(π / 3)
    labelelledtri()
    scale(0.5)
    rotate(2π / 3)
    labelelledtri()
    translate(O + (10EM, 0))
    labelelledtri()
    rotate(π)
    labelelledtri()
    label("-----------")


    MechanicalSketch.finish()
end