#= DSP is removed from test dependencies in this version.
import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, WI, EM, finish, ∙, Point
import MechanicalSketch: @import_expand, set_scale_sketch, scale_pt_to_unit, settext
import MechanicalSketch: noise, normalize_datarange, place_image, @layer
import MechanicalSketch: poly, dimension_aligned, sethue, arrow, circle, prettypoly
import MechanicalSketch: Length, noise_between_wavelengths, Greys_9, BinLegend
import DSP.Periodograms: spectrogram, Spectrogram
import DSP.Util:         nextfastfft
import DSP.Windows:      tukey
import MechanicalSketch: MechanicalUnits.dimension, NoDims, upreferred, ComplexQuantity, Quantity
import Statistics:       mean

let
if !@isdefined m²
    @import_expand(~m, s)
end
empty_figure(filename = joinpath(@__DIR__, "test_30.png"));


global curpoint = O + (-WI / 2 + EM, -HE / 2 + 3.5EM)
v_b = (0.05m/s, 0.5m/s)
settext("
From test 21 to 27, streamline velocity bounds are
    <i>v<sub>b</sub></i> = $(collect(v_b))
", curpoint, markup=true)

curpoint += (0, 4EM)
Δt = 2.0s
wave_per_streamline = 2
λ_b = Δt ∙ v_b  / wave_per_streamline
λ_calibration = collect(range(λ_b[1], λ_b[2], length = 4))

settext("
Tracing a particle over Δt = $Δt forward ($(Δt / 2)) and back ($(Δt / 2)) we want to sample $wave_per_streamline harmonic noise waves with length λ.
    <i>λ<sub>b</sub></i> = Δt ∙ v<sub>b</sub> / $wave_per_streamline = $λ_b
Between bounds, we want a linearly increasing noise function amplitude.
", curpoint, markup = true)


curpoint += (0, 3.5EM)
n_pixels = round(Int, 0.9 * WI)
physwidth = 3.0m
set_scale_sketch(physwidth, n_pixels)
length_one_pixel = physwidth / n_pixels
include("test_functions_29.jl")
include("test_functions_30.jl")
no = normalize_datarange([noise_between_wavelengths(λ_b..., x) for x in (1:n_pixels) * length_one_pixel])
greylegend = BinLegend(;maxlegend = 1.0, noofbins = 128, colorscheme = reverse(Greys_9))
@layer begin
    place_image(curpoint, greylegend.(no); centered = false)
    place_image(curpoint + (0,1), greylegend.(no); centered = false)
    place_image(curpoint + (0,2), greylegend.(no); centered = false)
    sethue(PALETTE[3])
    dimension_aligned(curpoint, curpoint + (λ_calibration[1], 0.0m), offset = -EM,
        fromextension = (0, EM), toextension = (0, 0.5EM))
    dimension_aligned(curpoint, curpoint + (λ_calibration[4], 0.0m), offset = -3EM,
        fromextension = (EM, EM), toextension = (EM, 5EM))
end


curpoint += (0, 3EM)
settext("
The shape looks clearer shown as a curve:", curpoint)


curpoint += (0, EM)
points = map(1:n_pixels, no) do xul, yul
    curpoint + (xul, -yul * EM)
end
poly(points, :stroke)


curpoint += (0, 3EM)
settext("
Spectrum from sampling the curve over $(100 * maximum(λ_b)):
", curpoint)

curpoint += (0, 2EM)
longnoise = normalize_datarange([noise_between_wavelengths(λ_b..., x) for x in (1:100n_pixels)*length_one_pixel])
spectrum = sampledspectrum_29(longnoise, length_one_pixel, maximumwavelength = maximum(λ_b))
draw_spectrum_29(curpoint, spectrum)


curpoint += (0, 5EM)
(λ_1, a_1), (λ_2, a_2) = two_largest_maxima_amplitude_wavelength(spectrum)
a_calibration = map(λ-> amplitude_interpolated(spectrum, λ), λ_calibration)
a_calibration_normalized = round.(a_calibration / maximum(a_calibration), digits = 2)
settext("
    Local amplitude maxima are (λ, amplitude) = [$((λ_1, a_1)), $((λ_2, a_2))]
    Normalized amplitudes at <i>λ<sub>calibration</sub></i> = $λ_calibration :
                                                                      $a_calibration_normalized, which is acceptably linear.
    ",
    curpoint, markup=true)


curpoint += (0, 2EM)
binwidth = 1 / (n_pixels - 1)
binno(x) = 1 + round(Int, x / (binwidth ), RoundDown)
binends = range(binwidth, 1.0, length = n_pixels)
bincounts = [0 for bin in binends]
for x in longnoise
    bincounts[binno(x)] += 1
end
relative_frequency = normalize_datarange(bincounts / sum(bincounts))
histogrampoints = Point.(collect(0.9 * WI * binends), -EM * relative_frequency )
poly(curpoint .+ histogrampoints, :stroke)

@layer begin
    sethue(PALETTE[3])
    arrow(curpoint, curpoint + (0.0,  -EM))
    settext("<i>Relative frequency</i>", curpoint + (0.0,  -EM ), markup=true)
    arrow(curpoint, curpoint + (0.95 * WI, 0.0))
    settext("<i>Noise values</i>, max 1.0", curpoint + ( 0.8 * scale_pt_to_unit(m) * WI, 0.0m), markup=true)
end

finish()
end
=#