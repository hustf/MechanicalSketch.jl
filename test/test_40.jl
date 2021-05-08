using Revise
import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, PT, FS, finish
import MechanicalSketch: settext, place_image, PALETTE, color_with_lumin, circle, line
import MechanicalSketch: circle, ∙, arrow_nofill, Point, @layer, sethue, draw_expr
import MechanicalSketch: latexify, arrow, Quantity, readsvg, unit, ustrip
import MechanicalSketch: ForwardDiff, box_fill_outline, brush, setopacity
import MechanicalSketch: @ev_draw, snapshot, preview, currentdrawing, show_expression
import ForwardDiff:      derivative, Tag, Dual, can_dual
import MechanicalSketch: MechanicalUnits, @L_str
import MechanicalUnits:  FreeUnits
using MechGluecode

# Plot dependencies in 'test_functions_37.jl'

if !@isdefined N
    @import_expand(~m, ~s, °, N)
end
include("test_functions_37.jl")
include("test_functions_40.jl")

empty_figure(backgroundcolor = color_with_lumin(PALETTE[5], 90),
        hue = "black", height = 10m);
# Placement grid for plots
nvert = 2
plys = range(- HE / 2 + 0.5EM, HE /2 - + EM, length = nvert + 1)
plxs = [-3EM, 9EM]
height = 0.18WI

# Starting point, line spacing, latex scaling (size varies with contents)
cpt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
Δcpy = 2
scalelatex = 3.143
pcpt = cpt

pcpt = cpt
@ev_draw("Quantities q can't be dual numbers, hence trans-
cendental `f(q) = A∙sin(ωq)` is not auto-differentiable.
Substitute:",
    quote
        g(q) = q / oneunit(q)
        string("⟹ q = g(q) · oneunit(q)")
        f(q) =  9.81N ∙ sin(3∙2π / s ∙ g(q) ∙ oneunit(q) )
    end)

@ev_draw("Applicable ranges in different units:",
    quote
        𝐭_1 = range(0.001, 1, length = 200)s
        𝐭_2 = 𝐭_1 |> ms
    end)
𝐲_1 = f.(𝐭_1)
pl1 = plot(𝐭_1, 𝐲_1 ; label = "f(t₁ )");
ptul, ptbr = place_image_37(O + (plxs[1], plys[1]), pl1; height)

𝐲_2 = f.(𝐭_2)
pl2 = plot(𝐭_2, 𝐲_2 ; label = "f(t₂)");
ptul, ptbr = place_image_37(O + (plxs[2], plys[1]), pl2; height)
snapshot()

# TODO
# use Chain rules to differentiate rules?
# -> Chain rules not used by ForwardDiff. Other packages? ForwardDiff2 defunct.
# Also, Macrotools, postwalk, prewalk: No type info.
# Mjolnir.jl @trace can do much more. Could be used for substitutions
# @edit derivative(f, 1.2)
# Anyway, this is complicated, while simple finite difference differentiation might
# do the trick better. https://github.com/JuliaDiff/FiniteDiff.jl
# On the other hand, defining chain rules for units (in a separate package)
# may work well with DifferentialEquations....

@ev_draw("Forward differentiation, chain rule",
        quote
            g′(q) = 1 / oneunit(q)
            f′(q) = g′(q) * derivative.(f, g(q))
            𝐱_ul = range(0.1, 1, length = 200)
            𝐱 = range(0.1, 1, length = 200)s
        end)



#pl1 = plot(f, 𝐱_ul; label = "f(xᵤₗ)");
#ptul, ptbr = place_image_37(O + (-3EM, plys[1]), pl1; height)

#pl2 = plot(f′, 𝐱_ul; label = "f′(xᵤₗ)");
#ptul, ptbr = place_image_37(O + (9EM, plys[1]), pl2; height)



#𝐲′  = f′.(𝐱)
#pl4 = plot(𝐱, 𝐲′; label = "f′(x)");
#ptul, ptbr = place_image_37(O + (9EM, plys[2]), pl4; height)

@layer begin
    sethue(PALETTE[4])
    setopacity(0.5)
    #brush(ptul, ptbr)
    #brush(Point(ptul.x, ptbr.y), Point(ptbr.x, ptul.y))
end

snapshot(fname = joinpath(@__DIR__, "test_40.png"))
