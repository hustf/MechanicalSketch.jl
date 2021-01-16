import MechanicalSketch
import MechanicalSketch: background, sethue, O, WI, HE, EM, FS
import MechanicalSketch: PALETTE, setfont, settext, setline, fontsize, color_with_luminance
import MechanicalSketch: dimension_aligned
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer
import MechanicalSketch: draw_color_map, set_scale_sketch, get_scale_sketch, lenient_min_max, ∙
import MechanicalSketch: clamped_velocity_matrix, line_integral_convolution_complex, lic_matrix_current, LicSceneOpts
import MechanicalSketch: normalize_datarange, matrix_to_function, noise_for_lic, function_to_interpolated_function
import MechanicalSketch: Movie, Scene, animate, circle, line, Point, arrow, poly
import MechanicalSketch: Time, get_scale_sketch, sawtooth
import Interpolations:   Extrapolation

using BenchmarkTools
let


if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

include("test_functions_32.jl")

# Scaling and placement
physwidth = 10.0m
physheight = 4.0m
totheight = physheight * 1.1 * 3
set_scale_sketch(totheight, HE)
totwidth = totheight * WI / HE
Δx = totwidth / 2 - 0.55 * physwidth
Δy = physheight * 1.1

# Reused velocity field from earlier tests
velocity_matrix = clamped_velocity_matrix(ϕ_32; physwidth = physwidth, physheight = physheight, cutoff = 0.5m/s);
# One complex matrix: Phase and amplitude for the visualization. This can generate cyclic movies
complex_convolution_matrix = convolute_image_32(velocity_matrix);
# The distribution of phase angles (complex argument) ought to be flat between -π and π. Let's check that:
n_pixels = round(Int, get_scale_sketch(physwidth))
phasetop, binwidth, relfreq = phase_histog(complex_convolution_matrix, n_pixels)
histogrampoints = Point.(collect(phasetop * n_pixels / 2π), -EM .* relfreq);


# We'll also prepare a uniform flow field, constant velocity 0.5 m/s.
fxy_unif(x, y) = (0.5, 0.0)m∙s⁻¹
# Phase and amplitude for the visualization. This can generate cyclic movies
complex_convolution_matrix_uniform = convolute_image_32(fxy_unif, physwidth = physwidth, physheight = physheight)

# We'll also plot a vertically uniform flow field, horizontally increasing velocity from 0 to 0.5 m/s.
fxy_lin(x, y) = (0.5 * (x / physwidth + 0.5), 0.0)m∙s⁻¹
# Phase and amplitude for the visualization. This can generate cyclic movies
complex_convolution_matrix_linear = convolute_image_32(fxy_lin, physwidth = physwidth, physheight = physheight)


# Define scene functions (parts of each image)

# Rectangular flow field plot including a visual frame counter
function plot_flowfield(scene, framenumber)
    @assert scene.opts isa LicSceneOpts string(typeof(scene.opts))
    currentvals = lic_matrix_current(scene, framenumber)
    draw_color_map(scene.opts.O, currentvals, normalize_data_range = false)
end

# Histogram plot, overlay to the flow field
function plot_histogram(scene, framenumber)
    @assert scene.opts isa LicSceneOpts
    histogrampoints = scene.opts.data
    @assert histogrampoints isa Array{Point,1}
    n_pixel_x = size(histogrampoints)[1]
    @layer let
        O = scene.opts.O
        settext("<span background='green'>Relative frequency of phase angle</span>",
            O + (-5EM,  -EM ), markup=true)
        settext("<span background='green'>Angle values, min = -π, max = π</span>",
            O + (n_pixel_x / 2, 1.5EM), markup=true, halign = "right")
        sethue(PALETTE[3])
        arrow(O, O + (0.0,  -EM))
        arrow(O, O + (n_pixel_x * 1.1 / 2, 0.0))
        poly(O .+ histogrampoints, :stroke)
        settext("π / 2 ", O + (n_pixels / 4,  0.0), markup=true)
     end
end

# Overlay to the flow field
function plot_frame_indicator(scene, framenumber)
    @assert scene.opts isa LicSceneOpts
    @layer let
        O = scene.opts.O
        sethue(PALETTE[9])
        setline(3)
        circle(O + (3EM, -3EM), 1FS, :stroke)
        frames_per_cycle = scene.opts.cycle_duration ∙ (scene.opts.framerate∙s⁻¹)
        # Where we are in the repeating cycle, [0, 1 - frame_duration]
        normalized_time = framenumber / frames_per_cycle
        θ = 2π ∙ normalized_time
        line(O + (3EM, -3EM), O + (3.0EM, -3.0EM) + (cos(θ), sin(θ)) .* FS, :stroke)
        settext(string(framenumber), O + (4EM, -4EM))
    end
end

function backdrop(scene, framenumber)
    setfont("Calibri", FS)
    fontsize(FS)
    O = scene.opts.O
    background(color_with_luminance(PALETTE[6], 0.3))
    sethue(PALETTE[3])
    Δt = scene.opts.cycle_duration
    frames_per_cycle = Δt ∙ (scene.opts.framerate∙s⁻¹)
    # Where we are in the repeating cycle, [0, 1 - frame_duration]
    normalized_time = framenumber / frames_per_cycle
    t = Δt ∙ normalized_time
    settext("Uniform velocity 0.5 m/s:\nCheck that one pixel moves \n$(Δt * 0.5m/s) over $Δt",
        O + (-WI / 2 + EM, 0.0), markup=true)
    dimension_aligned(O + (-3.0m, physheight / 2), O + (-2.0m, physheight / 2),
        fromextension = (0, EM), toextension = (0, EM), offset = -EM)
    dimension_aligned(O + (-4.0m, physheight / 2), O + (-3.0m, physheight / 2),
        fromextension = (0, EM), toextension = (0, EM), offset = -EM)
    dimension_aligned(O + (-5.0m, physheight / 2), O + (-4.0m, physheight / 2),
        fromextension = (0, EM), toextension = (0, EM), offset = -EM)

    settext("t = $(round(s,t, digits=2))",
        O + (-WI / 2 + EM, -4EM), markup=true)

    for i = 0:9
        x = t ∙ 0.5m/s + i ∙ 1.0m -5.0m
        line(O + (x, 1.1 * physheight / 2), O + (x, physheight / 2), :stroke)
    end
end


Δt = 2.0s
endframe = Int(floor(Δt ∙ (30∙s⁻¹)) - 1)
movie = Movie(WI, HE, "Three flow fields", 15:15)
scenes = [
    Scene(movie, backdrop, 0:endframe,             optarg = LicSceneOpts(NaN, Δt, 30, O)),
    Scene(movie, plot_flowfield, 0:endframe,       optarg = LicSceneOpts(complex_convolution_matrix, Δt, 30, O + (Δx, -Δy))),
    Scene(movie, plot_histogram, 0:endframe,       optarg = LicSceneOpts(histogrampoints, Δt, 30, O + (Δx, -Δy ))),
    Scene(movie, plot_frame_indicator, 0:endframe, optarg = LicSceneOpts(NaN, Δt, 30, O + (Δx, -Δy ))),
    Scene(movie, plot_flowfield, 0:endframe,       optarg = LicSceneOpts(complex_convolution_matrix_uniform, Δt, 30, O )),
    Scene(movie, plot_flowfield, 0:endframe,       optarg = LicSceneOpts(complex_convolution_matrix_linear, Δt, 30, O + (Δx, Δy)))
    ];


animate(movie, scenes,
    creategif = true,
    pathname = joinpath(@__DIR__, "test_32.gif"),
    framerate = 30)

end # let