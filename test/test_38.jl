import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, PT, finish
import MechanicalSketch: settext, place_image, PALETTE, color_with_lumin
import MechanicalSketch: circle, ∙, arrow_nofill, Point, @layer, sethue
import MechanicalSketch: latexify, arrow, generate_complex_potential_vortex
import MechanicalSketch: generate_complex_potential_source, ∇, color_matrix
import MechanicalSketch: fontsize, draw_legend, draw_streamlines, ∇_rectangle
import ColorSchemes:     isoluminant_cgo_80_c38_n256

if !@isdefined N
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand N
    @import_expand °
end
include("test_functions_33.jl")
ϕ = ϕ_33
include("test_functions_39.jl")


# Scaling and placement
physwidth = 10.0m
physheight = 4.0m
framedheight = physheight * 1.2
totheight = framedheight * 4
totwidth = totheight * WI / HE
Δx = totwidth / 4
Δy = framedheight / 2
Oadj = O + (-3EM, EM /3)
cent1 = Oadj + ( Δx, 3Δy)
cent2 = Oadj + ( Δx, Δy)
cent3 = Oadj + ( Δx, -Δy)
cent4 = Oadj + ( Δx, -3Δy)

empty_figure(joinpath(@__DIR__, "test_38.png"); 
      backgroundcolor = color_with_lumin(PALETTE[5], 90),
      hue = "black", height = totheight);

pt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
settext("Potential field, defined previously:", pt)
expression = :(ϕ(𝐫));
ptul, ptbr, latexscale = place_image(pt + (EM, 0), latexify(expression); height = 1.2EM, centered = false)
pt += (0, 1.5EM + ptbr.y - ptul.y)

settext("Steady flow velocity field at <b>r</b>:", pt, markup = true)
expression = :( 𝐕(𝐫) = 𝐢∙u(𝐫) + 𝐣∙v(𝐫) = ∇ϕ(𝐫))
ptul, ptbr = place_image(pt + (EM, 0), latexify(expression); scalefactor = latexscale, centered = false)

𝐕 = ∇(ϕ)
colmat, legend1 = color_matrix(𝐕; centered = true, maxlegend = 1.0m/s)
ulp, _ = place_image(cent1, colmat)

@layer begin
    fontsize(25)
    draw_legend(ulp + (0.5EM, 0.5EM) + (physwidth, 0.0m), legend1)
end
# To better indicate positive direction for this static image:
@layer begin
    sethue(PALETTE[8])
    draw_streamlines(cent1, 𝐕, probability = 0.001)
end


pt += (0, 1.5EM + ptbr.y - ptul.y)
settext("Local acceleration, steady flow:", pt, markup = true)
# Strictly incorrect, use paranthesis or .
expression = :(𝐚 = d𝐕 / dt = X) # 𝐕∙(∇𝐕) = 𝐕.∙∇∇ϕ = 𝐕.∙ ∇²ϕ) 
ptul, ptbr, _ = place_image(pt + (EM, 0), latexify(expression); scalefactor = latexscale, centered = false)
pt += (0, 1.5EM + ptbr.y - ptul.y)
#𝐚 = ∇_rectangle(𝐕)


finish()
