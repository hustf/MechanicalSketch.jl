import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, finish
import MechanicalSketch: readsvg, place_image, settext, Quantity, ustrip, unit
import MechanicalSketch: Point, julialogo, PALETTE, color_with_lumin, @svg
import MechanicalSketch: background, color_with_alpha, scale, @layer, setopacity
import MechanicalSketch: rotate, translate
using MechGluecode
import Plots.plot
# Plot dependencies in 'test_functions_37.jl'

if !@isdefined N
    @import_expand(~m, s, °, N)
end
include("test_functions_37.jl")
empty_figure(filename = joinpath(@__DIR__, "test_37.png");
      backgroundcolor = color_with_lumin(PALETTE[5], 90),
      hue = "black");
@layer begin
    scale(4)
    rotate(30°)
    translate(-WI /10, -HE / 8)
    background(color_with_alpha(PALETTE[5], 0))
    julialogo(;bodycolor = color_with_alpha(PALETTE[1], 0.1) )
end;
pt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
settext("<b>Plot recipe with svg style modifications</b>", pt, markup = true)
pt += (0, EM)

x = 0.0s:1.0s:5.0s
y = x .* N ./ s

settext("MechGlueCode has quantity plot recipes:", pt)
pl1 = plot(x, y);
ptul, ptlr = place_image_37(pt, pl1, height = 0.25HE)
pt += (0, 2EM + ptlr[2] - ptul[2])

settext("When guides are specified, postfix units:", pt)
pl2 = plot(x, y, xguide = "Time", yguide = "Force");
ptul, ptlr = place_image_37(pt, pl2, height = 0.25HE)
pt += (0, 2EM + ptlr[2] - ptul[2])

settext("This recipe treats axes independently:", pt)
pl2 = plot(x, y, xguide = "Time");
ptul, ptlr = place_image_37(pt, pl2, height = 0.25HE)
pt += (0, 2EM + ptlr[2] - ptul[2])

pt = O + (0, -HE / 4 + EM)
settext("No recipe change required for 3d:", pt)
n = 100
ts = range(0, stop = 8π, length = n)
x = ts * N .* map(cos, ts)
y = (0.1ts) * N .* map(sin, ts) .|> N
z = (1:n)s
pl3 = plot(x, y, z, zcolor = reverse(z./s),
      m = (10, 0.8, :blues, Plots.stroke(0)),
      leg = false, cbar = true, w = 5,
      zguide = "Time");
plot!(pl3, zeros(n), zeros(n), 1:n, w = 10);
ptul, ptlr = place_image_37(pt, pl3; width = 0.45WI)

finish()
