import MechanicalSketch
import MechanicalSketch: empty_figure, background, sethue, O, WI, HE, EM, FS, finish
import MechanicalSketch: PALETTE, setfont, settext, setline, set_figure_height
import MechanicalSketch: circle, arrow, prettypoly, normalize_datarange, poly, line
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer, Point, Table
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_real_legend, draw_complex_legend, setscale_dist, lenient_min_max
import MechanicalSketch: ∙, °, ∇_rectangle, SVector, trace_rotate_hue, convolute_pixel, rk4_steps!
import MechanicalSketch: draw_streamlines, rotate_hue, get_current_RGB, color_from_palette
import MechanicalSketch: noise_between_wavelengths, text_table, trace_diminishing
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
import Random: MersenneTwister
#let

set_figure_height(3777)
empty_figure(joinpath(@__DIR__, "test_31.png"));

if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

curpoint = O + (-WI / 2 + EM, -HE / 2 + 4.5EM)
include("test_functions_31.jl")
v_calib = collect(range(0.05m/s, 0.5m/s, length = 4))
Δt = 2.0s
streamlinelengths = 2 * v_calib * Δt
λ_min = 0.5 * streamlinelengths[1]
λ_max = 0.5 * streamlinelengths[end]
n = 20
f_s = n / Δt
f_0 = 2 / Δt
settext("
For each velocity
    <i>v<sub>calib</sub></i> = $v_calib, we pick five sets of <i>n</i> = $n streamline noise samples.
For comparison, five sample sets with one harmonic wave each.
", curpoint, markup = true)


# Make a matrix with a streamline sample set per column
n_samples_per_velocity = 5
n_streamlines = length(streamlinelengths) * n_samples_per_velocity
samples = zeros(n, n_streamlines + 5)
for i in 1:length(streamlinelengths)
    for j in 1:n_samples_per_velocity
        col = (i-1) * n_samples_per_velocity + j
        samples[:, col] = samplepoints(streamlinelengths[i], λ_min , λ_max)
    end
end
samples = normalize_datarange(samples)
# Add some harmonic sample sets
for (i, ωn) in enumerate([0.1, 0.2, 0.3, 0.5, 1]π)
    col = length(streamlinelengths) * (n_samples_per_velocity ) + i
    samples[:, col] = 0.5 .+ [0.5sin(ωn ∙ sampleno) for sampleno in 1:n]
end


# Show the sample sets as individual plots
for i in 1:length(streamlinelengths) + 1
    global curpoint += (0.0, 2.5EM)
    if i <= length(streamlinelengths)
        settext("$(v_calib[i])", curpoint)
    else
        settext("ω<sub>n</sub> = \n  [0.1 0.2 0.3 0.5 1]π",
            curpoint + (-EM, 0), markup = true, valign = "bottom")
    end
    for j in 1:5
        col = (i-1) * 5 + j
        origo = curpoint + (EM * 6.5 * j, 0.0)
        draw_sampleplot_31(origo, samples[:, col] * 2EM, 5.5EM)
    end
end


curpoint += (0, 8EM)

settext("
From each sample set above we are going to find the value for one pixel. Sampling frequency is
    <i>f<sub>s</sub> = n / Δt  = </i> $f_s
We want to extract a value based on each sample set's harmonic component with frequency
    <i>f<sub>0</sub></i> = 2 / Δt = $f_0.
After a Fourier transformation, normalized angular frequencies are:
", curpoint, markup = true)


curpoint += (0, 3EM)
ω_s = 2π
ω_Nyq = π
ω_0n = 2π ∙ f_0 / f_s
explanationcolumn = ["Sampling frequency",
    "    ...unitless or normalized ",
    "Nyquist frequency (highest detectable)",
    "Frequency to keep after filtering",
    "     ...unitless, normalized",
    "     ...as a fraction of Nyquist"]
mathcolumn = ["<i>ω<sub>s</sub> = 2πf<sub>s</sub></i> ",
    "<i>ω<sub>sn</sub> = 2π</i> ",
    "<i>ω<sub>Nyq</sub></i> = π",
    "<i>ω<sub>0</sub> = 2π∙f<sub>0</sub></i>",
    "<i>ω<sub>0n</sub> = 2π∙f<sub>0</sub> / f<sub>s</sub></i>",
    "<i>ω<sub>0n</sub> / ω<sub>Nyq</sub></i> = $(ω_0n / π)"]
ta = Table(6, 2, 20EM, 1.2EM)  # 5 rows, 10 columns, colwidth, colheight
for r in 1:size(ta)[1]
    for c in 1:size(ta)[2]
        settext(c ==1 ? explanationcolumn[r] : mathcolumn[r],
            curpoint + (11EM, 0) + ta[r, c], markup = true)
    end
end

curpoint += (0, 6 * 1.2EM + 2EM)
settext("
For natural frequency <i>ω<sub>0n</sub></i> = $(ω_0n / π)∙π on the unit circle in the complex plane,
the z-transform contributions and sum can be plotted:
", curpoint, markup = true)

for i in 1:length(streamlinelengths) + 1
    global curpoint += (0.0, 2.5EM)
    @layer begin
        ŝ_avg = complex(0.0,0.0)
        for j in 1:5
            col = (i-1) * 5 + j
            origo = curpoint + (3EM + EM * 6.5 * j, -0.5 * EM)
            vs =  samples[:, col]
            vŝ = z_transform_contributions(vs, exp(-im * ω_0n))
            # Plot contributions while circling
            sethue(color_from_palette("red"))
            setline(1)
            trace_rotate_hue(origo, EM * real.(vŝ), EM * imag.(vŝ))
            # Plot coordinate system
            sethue(PALETTE[3])
            arrow(origo, origo + (0.0,  -EM))
            arrow(origo, origo + (EM, 0.0))
            # Plot resultant
            ŝ = sum(vŝ)
            ŝ_avg += ŝ  / 5
            ŝ_pt = EM * Point(real(ŝ), imag(ŝ))
            setline(2)
            line(origo, origo + ŝ_pt, :stroke)
            sethue("white")
            circle(origo + ŝ_pt, 0.02m, :stroke)
        end
    end
    str_amp = round(hypot(ŝ_avg), digits = 2)
    if i <= length(streamlinelengths)
        settext("$(v_calib[i]) ampl. = $str_amp", curpoint)
    else
        settext("ω<sub>n</sub> = \n  [0.1 0.2 0.3 0.5 1]π",
            curpoint + (-EM, 0), markup = true, valign = "bottom")
    end
end



finish()
set_figure_height(round(Int, 3777 / 2))
#end
