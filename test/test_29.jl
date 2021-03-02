import MechanicalSketch
import MechanicalSketch: empty_figure, PALETTE, O, HE, WI, EM, finish, ∙, Point
import MechanicalSketch: @import_expand, set_scale_sketch, settext, scale_pt_to_unit
import MechanicalSketch: noise, normalize_datarange, place_image, BinLegend, @layer
import MechanicalSketch: poly, dimension_aligned, sethue, arrow, circle, prettypoly, Greys_9
using  MechanicalSketch: MechanicalUnits, upreferred, ComplexQuantity, Quantity
import MechanicalUnits:  dimension, NoDims
import DSP.Periodograms: spectrogram, Spectrogram
import DSP.Util:         nextfastfft
import DSP.Windows:      tukey
import Statistics:       mean
#let
if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
end
empty_figure(joinpath(@__DIR__, "test_29.png"));

curpoint = O + (-WI / 2 + EM, -HE / 2 + 3EM)
velocities = range(0.05m/s, stop= 0.5m/s, length = 3)
settext("
The flow field visualization should have a linear relationship between velocity and luminosity.
We need to control the noise image wavelength spectrum to get that.
", curpoint)


curpoint += (0, 4EM)
settext("
For reference, let's first illustrate two equal amplitude wavelengths, <i>λ</i>, as greyscale:
    <b>cos(<small>2π <sup>x</sup> / <sub>0.5m</sub></small>) + 0.5cos(2π <sup>x</sup> / <sub>0.05m</sub>)</b>
", curpoint, markup = true)


curpoint += (0, 3EM)
n_pixels = round(Int, 0.9WI)
physwidth = 2.0m
set_scale_sketch(physwidth, n_pixels)
length_one_pixel = physwidth / n_pixels
twowave(x) = cos(2π∙x / 0.5m) + 0.5cos(2π∙x / 0.05m)
no = [twowave(x) for x in (1:n_pixels)*length_one_pixel]
nno = normalize_datarange(no)
greylegend = BinLegend(;maxlegend = 1.0, noofbins = 128, colorscheme = reverse(Greys_9))
@layer begin
    place_image(curpoint, greylegend.(nno); centered = false)
    place_image(curpoint + (0,1), greylegend.(nno); centered = false)
    place_image(curpoint + (0,2), greylegend.(nno); centered = false)
    sethue(PALETTE[3])
    dimension_aligned(curpoint, curpoint + (physwidth, 0.0m), offset = -2.5EM)
    dimension_aligned(curpoint, curpoint + (0.5m, 0.0m), offset = -EM, toextension = (0EM, 7EM))
end


curpoint += (0, 3EM)
settext("
The same greyscale values shown as a curve:", curpoint)
curpoint += (0, EM)
points = map(1:n_pixels, nno) do xul, yul
    (xul, -yul * EM)
end
poly(curpoint .+ points, :stroke)


curpoint += (0, 2EM)
settext("
Amplitude-wavelength spectrum from sampling the same values:", curpoint, markup=true)


curpoint += (0, 3EM)
include("test_functions_29.jl")
spectrum = sampledspectrum_29(no .- 0.5, length_one_pixel, maximumwavelength = 0.5m)
draw_spectrum_29(curpoint, spectrum)


curpoint += (0, 2EM)



(λ_1, a_1), (λ_2, a_2) = two_largest_maxima_amplitude_wavelength(spectrum)
settext("
    Local maxima are (λ, amplitude) = [$((λ_1, a_1)), $((λ_2, a_2))]",
    curpoint, markup=true)


curpoint += (0, 2EM)
settext("
We can sample from a longer example and get a finer spectrum resolution:", curpoint)


curpoint += (0, 3EM)
longnoise = [twowave(x) for x in (1:100n_pixels)*length_one_pixel]
spectrum = sampledspectrum_29(longnoise, length_one_pixel, maximumwavelength = 0.5m)
draw_spectrum_29(curpoint, spectrum)


curpoint += (0, 2EM)
(λ_1, a_1), (λ_2, a_2) = two_largest_maxima_amplitude_wavelength(spectrum)
settext("
    Local maxima are (λ, amplitude) = [$((λ_1, a_1)), $((λ_2, a_2))]",
    curpoint, markup=true)

finish()
set_scale_sketch()
#end
