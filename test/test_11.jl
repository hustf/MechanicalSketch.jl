using MechanicalSketch
import MechanicalSketch: °, background, sethue, O, finish,
      m, dimension_aligned, EM
using JuMP    # Julia Mathematical Programming language
using Ipopt   # Nonlinear solver
let
BACKCOLOR = color_with_luminance(PALETTE[1], 0.7)
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

# TODO: Define a subset of Quantity where the numeric type is <:Real. See if that works directly as a variable for JuMP

NP = 20             # number of start and end points of chainlinks
L = 1              # difference in x-coords of endlinks
h = 2 * L / (NP - 1) # length of each link

mo = Model()
set_optimizer(mo, Ipopt.Optimizer)

@variables(mo, begin
    x[1:NP], (base_name = "Pos x, c.o.g. of link", lower_bound = 0, upper_bound = L)
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
finish()
nothing
end #let