import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, PT, finish
import MechanicalSketch: settext, place_image, PALETTE, color_with_lumin
import MechanicalSketch: circle, ∙, arrow_nofill, Point, @layer, sethue
import MechanicalSketch: latexify, arrow
if !@isdefined N
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand N
    @import_expand °
end
include("test_functions_39.jl")
empty_figure(joinpath(@__DIR__, "test_39.png"); 
      backgroundcolor = color_with_lumin(PALETTE[5], 90),
      hue = "black", height = 10m);
pt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
settext("<b>Flow around a cylinder</b>", pt, markup = true)
pt += (0, EM)
pt += (1m, -1m)
r = 1.0m
@layer begin
    sethue(PALETTE[8])
    circle(pt; r, action=:fill)
end
vr =  √2 / 2 ∙(r, r)
arrow_nofill(pt + 0.5vr, pt + vr;  arrowheadlength = 0.5EM)
settext("$r", pt + vr)
arrow(pt, 2EM, 0°, 30°; arrowheadlength = 0.4EM) 
pt += (0, 1.5EM)
settext("θ", pt + vr)
# 
#expression = :( δ / δr ∙ (δψ / δθ)  + δ / δθ ∙ (-δψ / δr)  = 0)



finish()