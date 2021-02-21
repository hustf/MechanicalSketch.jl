using MechanicalSketch
import MechanicalSketch: foil_spline_local
import MechanicalSketch: text, circle, Turtle, Pencolor, Penwidth, Forward, Turn
import MechanicalSketch: HueShift, O, sethue, finish, EM, WI, background
let
    empty_figure(joinpath(@__DIR__, "test_1.png"));
    background("midnightblue")

    posx = -WI / 2
    sethue("green")
    stri = "Da jeg var på vei til kirken ∈ dag morges så kom jeg forbi en liten sjømann. En frisk og hyggelig liten sjømann som hilste meg."
    text(stri, posx, 0)
    sethue("yellow")
  
    text("1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890",
        posx, EM)
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
