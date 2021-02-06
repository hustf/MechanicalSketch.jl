import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, WI, EM, FS, PT, finish, ∙, Point, settext
import MechanicalSketch: @import_expand, set_scale_sketch, Length
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: clamped_velocity_matrix, matrix_to_function, function_to_interpolated_function
import MechanicalSketch: Quantity, bresenhams_line_algorithm, get_scale_sketch, lenient_min_max
import MechanicalSketch: rk4_step, Extrapolation, draw_color_map, pngimage
import MechanicalSketch: box_line_algorithm, crossing_line_algorithm, circle_algorithm
import MechanicalSketch: function_to_interpolated_function, noise_for_lic, line_integral_convolution_complex
import MechanicalSketch: LicSceneOpts, lic_matrix_current, rotate_hue, complex_arg0_scale, normalize_datarange
import MechanicalSketch: ColorSchemes, placeimage, rotate_hue, color_with_lumin
import MechanicalSketch: ColorLegendIsoBins, setfont, FS, fontsize, background, sethue, dimension_aligned, line
import Base.show
import MechanicalSketch: Movie, Scene, animate, color_matrix_current, draw_legend, @layer
import MechanicalSketch: fontsize, fontface, setfont, setline, setdash, origin, setmatrix, color_with_luminance
import MechanicalSketch: convolution_matrix


let

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
include("test_functions_33.jl")

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
cent1 = Oadj + (-Δx, Δy)
cent2 = Oadj + ( Δx, Δy)
cent3 = Oadj + (-Δx, 0.0m)
cent4 = Oadj + ( Δx, 0.0m)
cent5 = Oadj + (-Δx, -Δy)



# Reused velocity field from earlier tests
max_velocity = 0.5m/s
velocity_matrix = clamped_velocity_matrix(ϕ_33; physwidth = physwidth, physheight = physheight, cutoff = max_velocity);
speedmatrix = hypot.(velocity_matrix)
c1 = convolution_matrix(velocity_matrix)

legen = ColorLegendIsoBins(maxlegend = max_velocity, noofbins = 6, name = :Speed)

function scenepic(scene, framenumber)
    colmat = color_matrix_current(scene, framenumber)
    draw_color_map(scene.opts.O, colmat, normalize_data_range = false)
end

function sc1(scene, framenumber)
    ulp, lrp = scenepic(scene, framenumber)
    str = "    1: Luminosity variation = 1 / 6"
    settext(str, ulp, markup = true)

end
function sc2(scene, framenumber)
    ulp, _ = scenepic(scene, framenumber)
    str = "    2: Luminosity variation = 2 / 6"
    settext(str, ulp, markup = true)
end

function sc3(scene, framenumber)
    ulp, _ = scenepic(scene, framenumber)
    str = "    3: Luminosity variation = 3 / 6"
    settext(str, ulp, markup = true)
end
function sc4(scene, framenumber)
    ulp, _ = scenepic(scene, framenumber)
    str = "    4: Luminosity variation = 4 / 6"
    settext(str, ulp, markup = true)
end

function sc5(scene, framenumber)
    ulp, lrp = scenepic(scene, framenumber)
    str = "    5: Luminosity variation = 5 / 6"
    settext(str, ulp, markup = true)
    # Centre of this scene's rectangle
    O = scene.opts.O
    # Top left of legend
    legendpos = O + ((lrp[1] - ulp[1]) / 2 + EM, (ulp[2] - lrp[2]) / 2)
    @layer begin
        sethue("white")
        # Font for the 'toy' text interface
        fontface("Calibri")
        # 1 pt font size = 12/72 inch - by the book.
        # Letter spacing works differently here than in Word, so we adjust a little.
        fontsize(FS)
        draw_legend(legendpos, scene.opts.legend)
    end
end

function backdrop(scene, framenumber)
    setfont("Calibri", FS)
    fontsize(FS)
    O = scene.opts.O
    background(color_with_lumin(PALETTE[6], 30))
    sethue(PALETTE[3])
    Δt = scene.opts.cycle_duration
    frames_per_cycle = Δt ∙ scene.opts.framerate
    # Where we are in the repeating cycle, [0, 1 - frame_duration]
    normalized_time = framenumber / frames_per_cycle
    t = Δt ∙ normalized_time

    dimension_aligned(O + (-2.0m, physheight / 2), O + (-1.0m, physheight / 2),
        fromextension = (0, EM), toextension = (0, EM), offset = -EM)
    dimension_aligned(O + (-3.0m, physheight / 2), O + (-2.0m, physheight / 2),
        fromextension = (0, EM), toextension = (0, EM), offset = -EM)
    dimension_aligned(O + (-4.0m, physheight / 2), O + (-3.0m, physheight / 2),
        fromextension = (0, EM), toextension = (0, EM), offset = -EM)
    for i = 0:4
        x = t ∙ 0.5m/s + i ∙ 1.0m - 4.0m
        line(O + (x, 1.1 * physheight / 2), O + (x, physheight / 2), :stroke)
    end
end
movie = Movie(WI, HE, "Five flow fields with varying luminosity variation", 15:15)
Δt = 2.0s
framerate = 30/s
endframe = Δt ∙ framerate - 1
o1 = LicSceneOpts(Δt,  cent1; phase_magnitude_matrix = c1, data = speedmatrix, legend = legen, luminosity_variation = 1 / 6)
o2 = LicSceneOpts(Δt,  cent2; phase_magnitude_matrix = c1, data = speedmatrix, legend = legen, luminosity_variation = 2 / 6)
o3 = LicSceneOpts(Δt,  cent3; phase_magnitude_matrix = c1, data = speedmatrix, legend = legen, luminosity_variation = 3 / 6)
o4 = LicSceneOpts(Δt,  cent4; phase_magnitude_matrix = c1, data = speedmatrix, legend = legen, luminosity_variation = 4 / 6)
o5 = LicSceneOpts(Δt,  cent5; phase_magnitude_matrix = c1, data = speedmatrix, legend = legen, luminosity_variation = 5 / 6)

scenes = [  Scene(movie, backdrop, 0:endframe, optarg = LicSceneOpts(Δt, O)),
            Scene(movie, sc1, 0:endframe, optarg = o1),
            Scene(movie, sc2, 0:endframe, optarg = o2),
            Scene(movie, sc3, 0:endframe, optarg = o3),
            Scene(movie, sc4, 0:endframe, optarg = o4),
            Scene(movie, sc5, 0:endframe, optarg = o5)];

animate(movie, scenes;
    creategif = true,
    pathname = joinpath(@__DIR__, "test_34.png"),
    framerate = framerate * s)

end # Let