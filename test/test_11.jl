using MechanicalSketch
import MechanicalSketch: °, background, sethue, O, EM, finish
import MechanicalSketch: m, dimension_aligned, place_image, modify_latex
import MechanicalSketch: @latexify, latexify, LaTeXString
using JuMP    # Julia Mathematical Programming language
using Ipopt   # Nonlinear solver

let
BACKCOLOR = color_with_lumin(PALETTE[1], 80)
function restart()
    empty_figure(joinpath(@__DIR__, "test_11.png"))
    background(BACKCOLOR)
    sethue(PALETTE[1])
end
restart()

#=
Catenary Problem

# Based on https://github.com/StaffJoy/jump-examples/blob/master/src/catenary.jl
=#

# Since Ipopt is a depencency with executables, we don't include it in MechanicalSketch.
# It also don't work well with quantities. In this case, we don't bother making a wrapper,
# this is just an experiment with JuMP.

NP = 20             # number of start and end points of chainlinks
L = 1               # difference in x-coords of endlinks
h = 2 * L / (NP - 1) # length of each link

mo = Model()
set_optimizer(mo, Ipopt.Optimizer)

@variables(mo, begin
    x[1:NP], (base_name = "Pos x, c.o.g. of link", lower_bound = 0.0L, upper_bound = L)
    y[1:NP], (base_name = "Pos y, c.o.g. of link")
end)

# Anchor ends
@constraints(mo, begin
    x[1] == 0
    x[NP] == L
    y[1] == 0
    y[NP] == 0
end)

# Minimize potential energy from center of mass for link
@objective(mo, Min, sum(2:NP) do j
    (y[j-1] + y[j] ) / 2
end)

# Link together pieces
for j in 2:NP
    @constraint(mo, (x[j] - x[j-1])^2 + (y[j] - y[j-1])^2 <= h^2)
end

optimize!(mo)

if termination_status(mo) != JuMP.MathOptInterface.LOCALLY_SOLVED
    println(termination_status(mo))
 end

# Extract solution
xx = 20m .* value.(x)
yy = 20m .* value.(y)

sp = Point(-10m, 10m)

for i in 2:NP
    p1 = sp + (xx[i - 1], yy[i - 1])
    p2 = sp + (xx[i], yy[i])

    dimension_aligned(p1, p2;
        offset = 0,
        fromextension = (0.3EM, 0.3EM),
        toextension = (0.3EM, 0.3EM),
        unit = m,
        digits = 2)
end

p = O + (-0.45WI, 0.25HE)
inner = L"\frac{y_n + y_{n-1}}{2}";
inner = latexify(:((y[j-1] + y[j] ) / 2));
innerst = modify_latex(inner)
l = L"\text{Minimize: }\sum_{n=2}^{%$NP} %$innerst";
_, _, scalefactor = place_image(p, l, height = 2EM)

l2 = latexify(quote 
         (x[j] - x[j-1])^2 + (y[j] - y[j-1])^2 <= h^2
    end);
l3 = "\\textrm{;where }" * modify_latex(l2)
place_image(p + (EM, 2.35EM), LaTeXString(l3); scalefactor)

finish();

nothing
end #let