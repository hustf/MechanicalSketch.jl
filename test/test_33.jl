import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, WI, EM, finish, ∙, settext
import MechanicalSketch: @import_expand, set_scale_sketch, color_with_lumin
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: clamped_velocity_matrix, matrix_to_function
import MechanicalSketch: lenient_max
import MechanicalSketch: place_image, @layer
import MechanicalSketch: lic_matrix_current
import MechanicalSketch: ColorSchemes, color_with_lumin, convolution_matrix, clamped_velocity_matrix
import MechanicalSketch: BinLegend, BinLegendVector, streamlines_add!, draw_legend
import MechanicalSketch: leonardo, fontsize
import ColorSchemes:     Paired_6, Greys_9, isoluminant_cgo_80_c38_n256
import Base.show


let
if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end

include("test_functions_33.jl")

empty_figure(joinpath(@__DIR__, "test_33.png"); 
    backgroundcolor = color_with_lumin(PALETTE[8], 10))

# Scaling and placement
physwidth = 10.0m
physheight = 4.0m
framedheight = physheight * 1.2
totheight = framedheight * 3
set_scale_sketch(totheight, HE)
totwidth = totheight * WI / HE
Δx = totwidth / 4
Δy = framedheight
Oadj = O + (0, EM /3)

# Reused velocity field from earlier tests
max_velocity = 0.5m/s
velocity_matrix = clamped_velocity_matrix(ϕ_33; physwidth = physwidth, physheight = physheight, cutoff = max_velocity);

v_xy = matrix_to_function(velocity_matrix)

streamlinepixels = falses(size(velocity_matrix))
streamlines_add!(v_xy, streamlinepixels)

cent1 = Oadj + (-Δx, Δy)
legend1 = BinLegend(;maxlegend = 1.0, minlegend = 0.0, noofbins = 2, 
                colorscheme = leonardo, 
                nan_color = color_with_lumin(PALETTE[1], 80), name = Symbol("Value{Float64}"))
bw(x::Bool) = legend1(Float64(x))
ulp, _ = place_image(cent1, bw.(streamlinepixels))
@layer begin
    fontsize(25)
    draw_legend(ulp + (EM, EM), legend1)
end
str = "    1: Streamline pixels"
settext(str, ulp, markup = true)

complex_convolution_matrix = convolution_matrix(velocity_matrix, streamlinepixels)
legend2 = BinLegendVector(;operand_example = first(complex_convolution_matrix),
        max_magn_legend = lenient_max(complex_convolution_matrix), 
        noof_ang_bins = 40, noof_magn_bins = 5,
        name = Symbol("Convolution matrix"))
cent2 = Oadj + (Δx, Δy)
ulp, _ = place_image(cent2, legend2.(complex_convolution_matrix))
@layer begin
    fontsize(25)
    draw_legend(ulp + (EM, EM), legend2)
end
str = "    2: Phase and amplitude for the animation"
settext(str, ulp, markup = true)


cent3 = Oadj + (-Δx, 0.0m)
curmat = lic_matrix_current(complex_convolution_matrix, 0, zeroval = -0.0)
legend3 = BinLegend(;maxlegend = 1.0, minlegend = -1.0, noofbins = 256, 
                       colorscheme = reverse(Greys_9), 
                       name = Symbol(" "))

ulp, _ = place_image(cent3, legend3.(curmat))
@layer begin
    fontsize(25)
    draw_legend(ulp + (EM, EM), legend3; max_vert_height = 3.0m, background_opacity = 0.4)
end
str = "    3: A single frame taken from 2"
settext(str, ulp, markup = true)


cent4 = Oadj + (Δx, 0.0m)
speedmatrix = hypot.(velocity_matrix)
binwidth = 0.1m/s
lum = 50
cols = isoluminant_cgo_80_c38_n256.colors .|> co -> color_with_lumin(co, lum)
legend4 = BinLegend(maxlegend = max_velocity, binwidth = binwidth, 
          colorscheme = cols, 
          name = :Speed)
ulp, _ = place_image(cent4, legend4.(speedmatrix));
@layer begin
    fontsize(25)
    draw_legend(ulp + (EM, EM), legend4)
end
str = "    4: isoluminant_cgo_80_c38_n256 at lumin = $lum"
settext(str, ulp, markup = true)


cent5 = Oadj + (-Δx, -Δy)
mixmat = map(legend4.(speedmatrix), curmat) do col, lu
    color_with_lumin(col, 50 + 50 * lu)
end;
ulp, _ = place_image(cent5, mixmat);
str = "    5: Chroma and hue from 4, lumin as in 3."
settext(str, ulp, markup = true)


cent6 = Oadj + (Δx, -Δy)
noofbins = 256
legend6 = BinLegend(;maxlegend = max_velocity, binwidth,
        colorscheme = Paired_6, name = :Speed)
mixmat = map(legend6.(speedmatrix), curmat) do col, lu
    color_with_lumin(col, 50 + lu * 50)
end;
ulp, _ = place_image(cent6, mixmat)
@layer begin
    fontsize(25)
    draw_legend(ulp + (EM, EM), legend6)
end
str = "    6: Colorscheme: Paired_6"
settext(str, ulp, markup = true)

set_scale_sketch(m)
finish()

end # let