import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, WI, EM, finish, ∙, Point, settext
import MechanicalSketch: @import_expand, set_scale_sketch, Length
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: clamped_velocity_matrix, matrix_to_function, function_to_interpolated_function
import MechanicalSketch: Quantity, bresenhams_line_algorithm, get_scale_sketch, lenient_min_max
import MechanicalSketch: rk4_step, Extrapolation, draw_color_map, pngimage
import MechanicalSketch: box_line_algorithm, crossing_line_algorithm, circle_algorithm
import MechanicalSketch: function_to_interpolated_function, noise_for_lic, line_integral_convolution_complex
import MechanicalSketch: LicSceneOpts, lic_matrix_current, rotate_hue, complex_arg0_scale, normalize_datarange
import MechanicalSketch: ColorSchemes, placeimage, rotate_hue, color_with_lumin, convolution_matrix, clamped_velocity_matrix
import MechanicalSketch: ColorLegendIsoBins, streamlines_add!
import ColorSchemes:     Paired_6
import Base.show


let
if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
include("test_functions_33.jl")

empty_figure(joinpath(@__DIR__, "test_33.png"));

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
ulp, _ = draw_color_map(cent1, streamlinepixels * 1.0)
str = "    1: Streamline pixels"
settext(str, ulp, markup = true)

complex_convolution_matrix = convolution_matrix(velocity_matrix, streamlinepixels)

cent2 = Oadj + (Δx, Δy)
ulp, _ = draw_color_map(cent2, complex_convolution_matrix)
str = "    2: Phase and amplitude for the animation"
settext(str, ulp, markup = true)


cent3 = Oadj + (-Δx, 0.0m)
curmat = lic_matrix_current(complex_convolution_matrix, 0, zeroval = -0.0)
ulp, _ = draw_color_map(cent3, curmat)
str = "    3: A single frame taken from 2"
settext(str, ulp, markup = true)


cent4 = Oadj + (Δx, 0.0m)
speedmatrix = hypot.(velocity_matrix)
binwidth = max_velocity / 8
legend4 = ColorLegendIsoBins(maxlegend = max_velocity, binwidth = binwidth, colorscheme = Paired_6)
colormat = legend4.(speedmatrix);
ulp, _ = draw_color_map(cent4, colormat, normalize_data_range = false);
str = "    4: Color legend for speed, binwidth = $(round(m/s, binwidth, digits=4))"
settext(str, ulp, markup = true)


cent5 = Oadj + (-Δx, -Δy)
mixmat = map(legend4.(speedmatrix), normalize_datarange(curmat)) do col, lu
    color_with_lumin(col, 100 * lu)
end;
ulp, _ = draw_color_map(cent5, mixmat, normalize_data_range = false);
str = "    5: Luminance from 3, Chroma and hue from 4"
settext(str, ulp, markup = true)


cent6 = Oadj + (Δx, -Δy)
noofbins = 6
legend6 = ColorLegendIsoBins(maxlegend = max_velocity, noofbins = noofbins)
mixmat = map(legend6.(speedmatrix), normalize_datarange(curmat)) do col, lu
    color_with_lumin(col, 100 * lu)
end;
ulp, _ = draw_color_map(cent6, mixmat, normalize_data_range = false);
str = "    6: Same, with default colorscheme, noofbins = $noofbins"
settext(str, ulp, markup = true)



finish()

end # let