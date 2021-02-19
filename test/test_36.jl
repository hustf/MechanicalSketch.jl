import MechanicalSketch

let

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
empty_figure(joinpath(@__DIR__, "test_36.png"),
    backgroundcolor = color_with_lumin(PALETTE[4], 80));


end # let

finish()
