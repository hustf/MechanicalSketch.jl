using MechanicalSketch
import MechanicalSketch: °, background, sethue, O, PT, EM, finish
import MechanicalSketch: color_from_palette, color_with_lumin
import MechanicalSketch: m, °, kN, mm, PALETTE
import MechanicalSketch: m, m², m³, s, N, kN, kPa, g, kg
import MechanicalSketch: arrow, drawcart, circle, foil_draw
import MechanicalSketch: line, showpower, empty_figure
import MechanicalSketch: rope_pos_tension, setline, kW

let
BACKCOLOR = PALETTE[8];
function restart()
    empty_figure(joinpath(@__DIR__, "test_13.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()

#  Physical constants

"Rope shape coefficient at Reynold's number range. It is
applied to the velocity components in a plane normal to the section"
Cs = 1.4

"Density air"
ρ_air = 1.322kg/m³

#  Scale-general constants

"Rope minimum breaking stress"
σ_MB = 41.2kN / (π / 4  * (6mm)^2 ) |> N/mm^2
# or
σ_MB = kN / (π / 4  * (6mm)^2 ) |> N/mm^2
# or
σ_MB = 5768kN / (π / 4  * (96mm)^2 ) |> N/mm^2
# or
σ_MB = 407.1kN / (π / 4  * (20mm)^2 ) |> N/mm^2

"Wing loading, dimensioning, from Boeing 737"
p_wing_dim = 690kg*g/m² |> kPa

# Model

"Rope safety factor"
Sf_s = 1.75

"Cart position"
p = (3m, -9m)

"Wind speed scalar"
v_w = 10m/s

"Wind velocity vector"
w = (0m/s, v_w)

"Cart velocity"
v_cart = -10m/s

"Generated wind speed vector, same for kite and cart since the model is quasi static"
w_generated = (-v_cart, 0m/s)

"Relative wind velocity vector"
w_rel = w + w_generated

"Relative wind velocity"
v = hypot(w_rel)

"Relative wind direction to screen x-axis"
α_w_rel = atan(w_rel[2], w_rel[1]) |> °

"Diameter rope"
diameter_rope = 6mm

"Wing area, kite"
A_k = σ_MB * π / 4 * diameter_rope^2 / Sf_s / p_wing_dim |> m²

"Aspect ratio kite"
AR = 7

"Average chord length, kite"
l_c = A_k / AR / m

"Optimal angle of attack to wind (positive clockwise by convention, defined by chord, not by zero lift)"
α_a = 8°

"Chord angle to global x, positive around z"
α_chord = α_w_rel - α_a

"Lift coefficient at optimal angle of attack, considering aspect ratio"
Cl = 1.25

"Lift to drag, optimal angle"
Cl_Cd = 14

"Foil pressure on wing projected on chord-span area"
pl = 0.5 * Cl * ρ_air * v^2 |> kPa

"Foil shear stress on wing projected on chord-span area, including body drag"
pd = pl / Cl_Cd

"Foil force component in chord coordinates"
Lift, Drag = A_k .* (pl, pd) .|> kN

"Foil force vector in chord coordinates"
Fk = (Drag, Lift)

"Change the diameter of rope from the sensible values"
diameter_rope = 20 * diameter_rope |> m

"Length of rope"
Ls = 15m

"Number of rope sections (one less than rope nodes)"
Ns = 100

"Rope positions from foil origo, oriented in global axes"
psf, Ts = rope_pos_tension(Ls, Ns, diameter_rope, Cs, ρ_air, v, α_w_rel, Fk, α_chord);

"Foil position"
p_foil = p - psf[end]

"Rope positions, global axes"
ps =  map(p-> p + p_foil, psf);

"Tangent at rope end"
Δ = ps[end-1] - ps[end]

"Unit vector, rope end"
eΔ = Δ ./ hypot(Δ)

"Force vector, rope end"
Fc = eΔ .* Ts[end]

"Braking force scalar, cart, positive is actual braking"
F_brake = -Fc[1]

"Braking power, cart"
power = -F_brake * v_cart |> kW

"Horizontal force, foil"
Fk_x =  -Fk[2] * sin(α_chord) + Fk[1] *cos(α_chord)

"Working power, kite"
power_kite = Fk_x * v_cart |> kW

"Horizontal force, rope"
Fs =  -Fk_x - F_brake |> N

"Braking power, rope"
power_rope = -Fs  * v_cart |> kW

###########################
# Drawing only
###########################

#"Cart position"
circle(O + p, 0.1m, :stroke)
drawcart(p = O +p)

#"Generated wind speed vector, same for kite and cart since the model is quasi static"
sethue(color_with_lumin(color_from_palette("green"), 85))
arrow(O + p + 0.5w_generated + 2w,
    w_generated,
    backgroundcolor = BACKCOLOR,
    labellength = true)


#"Relative wind velocity"
sethue(sethue(PALETTE[1]))
arrow(O + p + 0.5w_rel , w_rel,
    backgroundcolor = BACKCOLOR,
    labellength = true)


# Draw the foil
sethue(color_from_palette("blue"))
foil_draw(O + p_foil, α = α_chord, rel_scale = 1, l = l_c, backgroundcolor = BACKCOLOR);

# And the force on foil
sethue(color_from_palette("indigo"))
arrow(O + p_foil, Fk, α = α_chord,
    backgroundcolor = BACKCOLOR,
    labellength = true)

# Draw the relative wind in front of the kite
sethue(PALETTE[1])
arrow(O + p_foil - 1.5w_rel , w_rel,
    backgroundcolor = BACKCOLOR,
    labellength = false)

#"Rope positions, global axes"
setline(diameter_rope)
for i = 1:Ns
    line(O + ps[i], O + ps[i+1], :stroke)
end
setline(0.5PT)

#"Force vector, rope end"
sethue(PALETTE[5])
arrow(O + p, Fc,
    backgroundcolor = BACKCOLOR,
    labellength = true)

#"Braking force scalar, cart, positive is actual braking"
sethue(PALETTE[6])
arrow(O + p, F_brake,
    backgroundcolor = BACKCOLOR,
    labellength = true)

#"Braking power, cart"
sethue(color_from_palette("yellow"))
showpower(O + p + (10EM, 0), power; backgroundcolor = BACKCOLOR)

#"Horizontal force, foil"
sethue(PALETTE[6])
arrow(O + p_foil, Fk_x,
    backgroundcolor = BACKCOLOR,
    labellength = true)

#"Working power, kite"
sethue(color_from_palette("yellow"))
showpower(O + p_foil + (10EM, 0), power_kite; backgroundcolor = BACKCOLOR)


#"Horizontal force, rope"
sethue(color_with_lumin(PALETTE[6], 10))
arrow(O + 0.5p_foil + 0.5p, Fs,
    backgroundcolor = BACKCOLOR,
    labellength = true)

#"Braking power, rope"
sethue(color_from_palette("yellow"))
showpower(O + 0.5p_foil + 0.5p + (10EM, 0), power_rope; backgroundcolor = BACKCOLOR)

finish()
nothing
end