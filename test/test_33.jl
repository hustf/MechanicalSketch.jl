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
import MechanicalSketch: ColorSchemes.Paired_6, placeimage, color_with_lumin


#let
if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
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

# Reused velocity field from earlier tests
velocity_matrix = clamped_velocity_matrix(ϕ_33; physwidth = physwidth, physheight = physheight, cutoff = 0.5m/s);

v_xy = matrix_to_function(velocity_matrix)

streamlinepixels = falses(size(velocity_matrix))
streamlines_add!(v_xy, streamlinepixels)

cent1 = O + (-Δx, Δy)
ulp, _ = draw_color_map(cent1, streamlinepixels * 1.0)
str = "    1: Streamline pixels"
settext(str, ulp, markup = true)


# For optimizing parameters
function iterate_line!(streamlinepixels)
    streamlinepixels = falses(size(velocity_matrix))
    streamline_add!(v_xy, streamlinepixels)
    pngimage(streamlinepixels)
end
#iterate_line!(streamlinepixels)

#=
# One complex matrix: Phase and amplitude for the visualization. This can generate cyclic movies
complex_convolution_matrix = convolute_image_33(velocity_matrix, streamlinepixels)
=#
complex_convolution_matrix = convolute_image_33(velocity_matrix, streamlinepixels)

cent2 = O + (Δx, Δy)
# One complex matrix: Phase and amplitude for the animation. This can generate cyclic movies
ulp, _ = draw_color_map(cent2, complex_convolution_matrix)
str = "    2: Phase and amplitude for the animation"
settext(str, ulp, markup = true)


cent3 = O + (-Δx, 0.0m)
# One complex matrix: Phase and amplitude for the visualization. This can generate cyclic movies
curmat = lic_matrix_current(complex_convolution_matrix, 0, zeroval = -0.5)
ulp, _ = draw_color_map(cent3, curmat)
str = "    3: A single frame of animation"
settext(str, ulp, markup = true)


cent4 = O + (Δx, 0.0m)
# One complex matrix: Phase and amplitude for the visualization. This can generate cyclic movies
speedmat = hypot.(velocity_matrix)
function windcolorscale(normalizedval)
    @assert 0 <= normalizedval <= 1
    colorno = 1 + round(Int, (6 - 1) * normalizedval) 
    Paired_6[colorno]
end
normalizedspeed = normalize_datarange(speedmat)
colormat = windcolorscale.(normalizedspeed);
ulp, _ = draw_color_map(cent4, colormat, normalize_data_range = false);
str = "    4: Color scale from velocity"
settext(str, ulp, markup = true)


cent5 = O + (-Δx, -Δy)
# The range of luminance is normalized to 0..100
luminmat = 100 * normalize_datarange(curmat)
mixmat = map(colormat, luminmat) do col, lu
    color_with_lumin(col, lu)
end
ulp, _ = draw_color_map(cent5, mixmat, normalize_data_range = false);
str = "    5: Luminance from 3, Chroma and hue from 4"
settext(str, ulp, markup = true)




finish()

