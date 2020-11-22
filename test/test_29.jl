import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, WI, EM, finish
import MechanicalSketch: @import_expand, text

let


if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand ~N
    @import_expand s
end
include("test_functions_27.jl")
empty_figure(joinpath(@__DIR__, "test_29.png"));
text("Empty test", O + (-WI / 2 + EM, -HE / 2 + EM))

finish()
end