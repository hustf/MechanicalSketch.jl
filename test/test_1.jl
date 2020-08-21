using MechanicalSketch
import MechanicalSketch: foil_points_local, foil_spline_local, background,
    empty_figure,
    text,
    circle,
    Turtle,
    Pencolor,
    Penwidth,
    Forward,
    Turn,
    HueShift,
    O,
    sethue,
    finish,
    preview,
    EM,
    m
let
    this_fig = empty_figure(joinpath(@__DIR__, "test_1.png"))
    background("midnightblue")

    foil_points_local()

    foil_points_local(l = 1, t = 0.02, c= 0.05)
    foil_spline_local(l = 1m, t = 0.02m, c= 0.05m)

    foil_spline_local(l = 1, t = 0.02, c= 0.05)
    posy = 0
    posx = -this_fig.width / 2
    sethue("green")
    stri = "Da jeg var på vei til kirken ∈ dag morges så kom jeg forbi en liten sjømann. En frisk og hyggelig liten sjømann som hilste meg."
    text(stri, posx, posy)
    sethue("yellow")
    posy += EM

    text("1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890",
        posx, posy)
    circle(O, 20, :stroke)
    t = Turtle()
    Pencolor(t, "cyan")
    Penwidth(t, 1.5)
    n = 5
    for i in 1:400
        Forward(t, n)
        Turn(t, 89.5)
        HueShift(t)
        n += 0.75
    end
    finish()
end
