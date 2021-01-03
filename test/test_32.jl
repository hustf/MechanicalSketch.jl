import MechanicalSketch
import MechanicalSketch: empty_figure, background, sethue, O, WI, HE, EM, FS, finish,
       PALETTE, setfont, settext, setline, color_with_luminance
import MechanicalSketch: dimension_aligned, move, do_action, noise_between_wavelengths
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer
import MechanicalSketch: draw_color_map, draw_real_legend, setscale_dist, lenient_min_max
import MechanicalSketch: ∙, ∇_rectangle, SVector, convolute_pixel, rk4_steps!, normalize_datarange, draw_streamlines
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
import MechanicalSketch: Movie, Scene, animate, circle, Point, arrow, poly, textextents
using BenchmarkTools
#let



if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end
# Reuse the velocityfield from here
include("test_functions_24.jl")
include("test_functions_32.jl")

# Scaling
physwidth = 10.0m
height_relative_width = 0.4
physheight = physwidth * height_relative_width
screen_width_frac = 2 / 3
setscale_dist(physwidth / (screen_width_frac * WI))

# Reuse the flow field from test_23.jl, a matrix of complex velocities with an element per pixel.
A = flowfield_23();
# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
xs = range(-physwidth/2, stop = physwidth / 2, length = size(A)[2]);
ys = range(-height_relative_width * physwidth/2, stop = height_relative_width * physwidth / 2, length = size(A)[1]);
fxy_inter = interpolate((xs, ys), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());
# TODO test whether the interpolation saves time.

# Streamline convolution preparation

# Length of a streamline in time, including forward and back
Δt = 2.0s
# Number of waves over one streamline
wave_per_streamline = 2
# Frequency of interest
f_0 = wave_per_streamline / Δt
# Number of sample points per set (1 to 9 from tracking backward, 10 (start) to including 20 forward)
n = 20
# Sampling frequency.
f_s = n / Δt
# Unitless, normalized circular frequency of interest
ω_0n = 2π ∙ f_0 / f_s

# Velocity scale from, to
v_min, v_max = lenient_min_max(A)
# Noise spectrum wavelengths
λ_min, λ_max = Δt∙(v_min, v_max) / wave_per_streamline
# Simplex noise matrix with linear spectrum - x in rows, y in columns
no = noise_between_wavelengths(λ_min, λ_max, xs, ys);
# Make a function that interpolates between noise pixels:
nxy_inter = interpolate((xs, ys), transpose(no)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());


z_transform_32(fxy, nxy, 0.0m, 0.0m, f_s, f_0, wave_per_streamline)



@time M = convolute_image_32(xs, ys, fxy, nxy, f_s, f_0, 0.5m/s, wave_per_streamline); # 30 s 50M allocations
                                                                # 26s 1.76M allocations
                                                                # 27s 2 allocations
                                                                # 28s 1.38 M all

# The distribution of phase angles (complex arguments) ought to be flat between -π and π. Let's check that:
n_pixels = round(Int, screen_width_frac * WI)
curpoint = O

phasetop, binwidth, relfreq = phase_histog(M, n_pixels)
histogrampoints = Point.(collect(phasetop * n_pixels / 2π), -EM .* relfreq)

framrat = 30/s

frames = n / Δt


function frame32(scene, framenumber)

    θ = 2π ∙ framenumber / (n * wave_per_streamline)
    u = exp(θ∙im)
    mi, ma = lenient_min_max(M)
    currentvals = map(M) do complexval
        θ_pixel = sawtooth(angle(complexval) + θ, π / wave_per_streamline)
        r = hypot(complexval)
        (1.0 + r∙cos(θ_pixel)) * r / (2.0 * ma)
    end
    draw_color_map(O, currentvals, normalize_data_range = false)
    circle(O + (3EM, -3EM), 1FS, :stroke)
    settext(string(framenumber), O + (3EM, -3EM))
    sethue("black")
    settext("<span background='green'>Relative frequency of phase angle</span>", curpoint + (0.0,  -EM ), markup=true)
    settext("<span background='green'>Angle values, min = -π, max = π</span>", O + (n_pixels * 0.2 / 2, EM), markup=true)
    @layer begin
        sethue(PALETTE[3])
        arrow(O, O + (0.0,  -EM))
        arrow(O, O + (n_pixels * 1.1 / 2, 0.0))
        poly(O .+ histogrampoints, :stroke)
        settext("π / 2 ", O + (n_pixels / 4,  0.0), markup=true)
     end
end

function frame32a(scene, framenumber)
    # TODO make a function generator, capturing n / Δt and adopting to frame rate 30/s
    θ = 2π ∙ framenumber / (n * wave_per_streamline)
    u = exp(θ∙im)
    mi, ma = lenient_min_max(M)
    currentvals = map(M) do complexval
        θ_pixel = sawtooth(angle(complexval) + θ, π / wave_per_streamline)
        r = hypot(complexval)
        r∙cos(θ_pixel) / ma
    end
    draw_color_map(O, currentvals, normalize_data_range = false)
    circle(O + (3EM, -3EM), 1FS, :stroke)
    settext(string(framenumber), O + (3EM, -3EM))
    sethue("black")
    settext("<span background='green'>Relative frequency of phase angle</span>", curpoint + (0.0,  -EM ), markup=true)
    settext("<span background='green'>Angle values, min = -π, max = π</span>", O + (n_pixels * 0.2 / 2, EM), markup=true)
    @layer begin
        sethue(PALETTE[3])
        arrow(O, O + (0.0,  -EM))
        arrow(O, O + (n_pixels * 1.1 / 2, 0.0))
        poly(O .+ histogrampoints, :stroke)
        settext("π / 2 ", O + (n_pixels / 4,  0.0), markup=true)
        end
end
begin
    empty_figure(joinpath(@__DIR__, "test_32.png"));
    frame32(1, 5)
    finish()
end
backdrop(scene, framenumber) =  color_with_luminance(PALETTE[8], 0.1)

demo = Movie(length(xs), length(ys), "test", 0:19)
animate(demo, [
    Scene(demo, backdrop, 0:19),
    Scene(demo, frame32, 0:19)],
    creategif = true,
    pathname = joinpath(@__DIR__, "test_32.gif"),
    framerate = n ∙ s / Δt)


begin
    empty_figure(joinpath(@__DIR__, "test_32a.png"));
    frame32a(1, 5)
    finish()
end

animate(demo, [
    Scene(demo, backdrop, 0:19),
    Scene(demo, frame32a, 0:19)],
    creategif = true,
    pathname = joinpath(@__DIR__, "test_32a.gif"),
    framerate = n ∙ s / Δt)


# Try with a uniform velocity field
A = 0.0.*A
A = map(A) do x
    complex(0.5, 0.0)m/s
end
for (i, val) in enumerate(A)
    A[i] = val * i / (length(xs) * length(ys))
end
fxy_inter = interpolate((xs, ys), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());

@time MU = convolute_image_32(xs, ys, fxy, nxy, f_s, f_0, 0.5m/s, wave_per_streamline); # 30 s 50M allocations
                                                                # 26s 1.76M allocations

function frame32b(scene, framenumber)
    θ = 2π ∙ wave_per_streamline ∙ framenumber / 20
    u = exp(θ∙im)
    mi, ma = lenient_min_max(MU)
    currentvals = map(MU) do complexval
        θ_pixel = sawtooth(angle(complexval) + θ, π / wave_per_streamline)
        r = hypot(complexval)
        r∙cos(θ_pixel) / ma
    end
    draw_color_map(O, currentvals, normalize_data_range = false)
    sethue("black")
    circle(O + (3EM, -3EM), 1FS, :stroke)
    settext(string(framenumber), O + (3EM, -3EM))
end

demo = Movie(length(xs), length(ys), "test", 0:19)
animate(demo, [
    Scene(demo, backdrop, 0:19),
    Scene(demo, frame32b, 0:19)],
    creategif=true,
    pathname= joinpath(@__DIR__, "test_32b.gif"),
    framerate = n ∙ s / Δt)

begin
    empty_figure(joinpath(@__DIR__, "test_32b.png"));
    frame32b(1, 5)
    finish()
end

finish()
#end
