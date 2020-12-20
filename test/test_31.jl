import MechanicalSketch
import MechanicalSketch: empty_figure, sethue, O, WI, HE, EM, FS, finish
import MechanicalSketch: PALETTE, settext, setline, set_figure_height
import MechanicalSketch: circle, arrow, normalize_datarange, line
import MechanicalSketch: @import_expand, @layer, Point, Table
import MechanicalSketch: ∙, °, trace_rotate_hue, rotate_hue, noise_between_wavelengths
import MechanicalSketch: get_current_RGB, color_from_palette
import Statistics: cor
let

set_figure_height(3777)
empty_figure(joinpath(@__DIR__, "test_31.png"));

if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

global curpoint = O + (-WI / 2 + EM, -HE / 2 + 4.5EM)
include("test_functions_31.jl")
n_velocity = 4
v_calib = collect(range(0.05m/s, 0.5m/s, length = n_velocity))

# Duration for a streamline
Δt = 2.0s
# Number of sample points per set (1 to 13 forward, 2 to 13 backward)
n = 20

# Sampling frequency.
f_s = n / Δt

# How far a particle travels over the duration - both directions
streamlinelengths = v_calib * Δt

wave_per_streamline = 2

# Noise spectrum desired spectrum wavelengths
λ_min = streamlinelengths[1] / wave_per_streamline
λ_max = streamlinelengths[end] / wave_per_streamline

# Frequency of interest
f_0 = wave_per_streamline / Δt

# Number of sample sets per velocity
sets_per_v = 10
settext("
For each velocity
    <i>v<sub>calib</sub></i> = $v_calib, we pick $sets_per_v sets of <i>n</i> = $n streamline noise samples.
Finally, $sets_per_v sample sets with periodic waves.
", curpoint, markup = true)


# Make a matrix with a streamline sample set per column,
# plus one for periodic waves

sample_matrix = zeros(n, n_velocity * sets_per_v)
for i in 1:n_velocity
    for j in 1:sets_per_v
        col = (i-1) * sets_per_v + j
        sample_matrix[:, col] = samplepoints(streamlinelengths[i], λ_min , λ_max, n)
    end
end
sample_matrix = normalize_datarange(sample_matrix)

# Add set_per_v columns. These are periodic (with respect to time) sample sets
n_columns = (n_velocity + 1 ) * sets_per_v
sample_matrix = hcat(sample_matrix, zeros(n, sets_per_v))
linfractions = range(f_0 / f_s, step = ((1 - f_0 / f_s)) / 3,  length = sets_per_v)
f_periodic = f_0 * linfractions.^2
for (i, f) in enumerate(f_periodic)
    col = n_velocity * (sets_per_v ) + i
    ω = 2π∙f
    # Time range over the window with n samples
    trng = range(1 / (n - 1), 1, length = n) * Δt
    ϕ = π ∙ rand()
    sample_matrix[:, col] = [0.5 + 0.5sin(ω ∙ tim - ϕ) for tim in trng]
end


# Show the sample sets as individual plots
for i in 1:(n_velocity + 1)
    global curpoint += (0.0, 2.5EM)
    # Text of this row
    if i <= n_velocity
        settext("$(v_calib[i])", curpoint)
    else
        settext(" 0.5 + sin(2π∙f - ϕ)
         ϕ is random, f = ...",
            curpoint + (-EM, 0), markup = true, valign = "bottom")
    end
    # Plot sample set for this row
    for j in 1:sets_per_v
        col = (i - 1) * sets_per_v + j
        origo = curpoint + (8.5EM +EM * 3.25 * (j - 1), 0.0)
        draw_sampleplot_31(origo, sample_matrix[:, col] * 2EM, 2.25EM)
        if i > n_velocity
            str = round(s⁻¹, f_periodic[j], digits = 2)
            settext("$str", origo)
        end
    end
end


curpoint += (0, 8EM)

settext("
From each sample set above we are going to find the value for one pixel. Sampling frequency is
    <i>f<sub>s</sub> = n  / Δt  = </i> $f_s
We want to extract a value based on each sample set's component with frequency
    <i>f<sub>0</sub></i> = 2 / Δt = $f_0.
After a Fourier transformation, normalized angular frequencies are:
", curpoint, markup = true)


curpoint += (0, 3EM)
ω_s = 2π ∙ f_s
ω_Nyq = π
ω_0n = 2π ∙ f_0 / f_s
explanationcolumn = ["Sampling frequency",
    "    ...unitless, normalized to radians per sample",
    "Nyquist frequency (highest detectable)",
    "Frequency to keep after filtering",
    "     ...unitless, normalized",
    "     ...as a fraction of Nyquist"]
mathcolumn = ["<i>ω<sub>s</sub> = 2πf<sub>s</sub></i> = $f_s",
    "<i>ω<sub>sn</sub> = 2π</i> ",
    "<i>ω<sub>Nyq</sub></i> = π",
    "<i>ω<sub>0</sub> = 2π∙f<sub>0</sub></i> = $(round(s⁻¹, 2π∙f_0, digits = 2))",
    "<i>ω<sub>0n</sub> = 2π∙f<sub>0</sub> / f<sub>s</sub></i> = $(round(2π∙f_0 / f_s, digits = 2)) = $(round(2∙f_0 / f_s, digits = 2))π ",
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
We will illustrate the extraction of magnitude at frequency <i>ω<sub>0n</sub></i> = $(ω_0n / π)∙π
by use of the z-transform. The average magnitude is noted:
", curpoint, markup = true)


vmagn1 = []
for i in 1:(n_velocity + 1)
    # Plot z-transformed sample sets for this row
    global curpoint += (0.0, 2.5EM)
    @layer begin
        ŝ_avg = complex(0.0,0.0)
        for j in 1:sets_per_v
            col = (i - 1) * sets_per_v + j
            origo = curpoint + (8.5EM + EM * 3.25 * (j - 0.5), -0.5 * EM)
            vs =  sample_matrix[:, col]
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
            ŝ_avg += ŝ  / sets_per_v
            ŝ_pt = EM * Point(real(ŝ), imag(ŝ))
            setline(2)
            line(origo, origo + ŝ_pt, :stroke)
            sethue("white")
            circle(origo + ŝ_pt, 0.02m, :stroke)
        end
    end
    if i <= n_velocity
        push!(vmagn1, hypot(ŝ_avg))
    end
    # text for this row of transformed sample sets
    str_amp = round(hypot(ŝ_avg), digits = 2)
    if i <= n_velocity
        settext("$(v_calib[i]) magn ω<sub>0</sub> = $str_amp",
        curpoint, markup = true)
    else
        settext(" 0.5 + sin(2π∙f - ϕ)
            magnitude ω<sub>0</sub> = $str_amp",
               curpoint + (-EM, 0), markup = true, valign = "bottom")
    end
end



##############################################################################

curpoint += (0, 6 * 1.2EM )
settext("
The correlation is $(round(cor(v_calib * s / m , vmagn1), digits = 3)) between the four magnitudes and velocities.

Let us subtract 0.5, apply a blackman window and add 0.5 to the same sample sets and look for an improvement:
", curpoint, markup = true)
sample_matrix = [(sample_matrix[i, j] - 0.5) * blackman_20(i) + 0.5 for i = 1:n, j = 1:n_columns]



# Show the sample sets as individual plots
for i in 1:(n_velocity + 1)
    global curpoint += (0.0, 2.5EM)
    # Text of this row
    if i <= n_velocity
        settext("$(v_calib[i])", curpoint)
    else
        settext("0.5 + sin(2π∙f), f = ...",
            curpoint + (-EM, 0), markup = true, valign = "bottom")
    end
    # Plot sample set for this row
    for j in 1:sets_per_v
        col = (i - 1) * sets_per_v + j
        origo = curpoint + (8.5EM +EM * 3.25 * (j - 1), 0.0)
        draw_sampleplot_31(origo, sample_matrix[:, col] * 2EM, 2.25EM)
        if i > n_velocity
            str = round(s⁻¹, f_periodic[j], digits = 2)
            settext("$str", origo)
        end
    end
end


curpoint += (0, 0EM)

vmagn2 = []
for i in 1:(n_velocity + 1)
    # Plot z-transformed sample sets for this row
    global curpoint += (0.0, 2.5EM)
    @layer begin
        ŝ_avg = complex(0.0,0.0)
        for j in 1:sets_per_v
            col = (i - 1) * sets_per_v + j
            origo = curpoint + (8.5EM + EM * 3.25 * (j - 0.5), -0.5 * EM)
            vs =  sample_matrix[:, col]
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
            ŝ_avg += ŝ  / sets_per_v
            ŝ_pt = EM * Point(real(ŝ), imag(ŝ))
            setline(2)
            line(origo, origo + ŝ_pt, :stroke)
            sethue("white")
            circle(origo + ŝ_pt, 0.02m, :stroke)
        end
    end
    if i <= n_velocity
        push!(vmagn2, hypot(ŝ_avg))
    end
    # text for this row of transformed sample sets
    str_amp = round(hypot(ŝ_avg), digits = 2)
    if i <= n_velocity
        settext("$(v_calib[i]) magn ω<sub>0</sub> = $str_amp",
        curpoint, markup = true)
    else
        settext(" 0.5 + sin(2π∙f - ϕ)
            magnitude ω<sub>0</sub> = $str_amp",
               curpoint + (-EM, 0), markup = true, valign = "bottom")
    end
end





curpoint += (0, 4EM)

settext("
The correlation is $(round(cor(v_calib * s / m , vmagn2), digits = 3)) between the four magnitudes and velocities.
There's likely  no help in using windows to extract this single frequency.
", curpoint, markup = true)



finish()
set_figure_height(round(Int, 3777 / 2))
end
