
function noise_between_wavelengths_30(λ_min, λ_max, x)
    @assert λ_min < λ_max "λ_min < λ_max"
    octaves = round(Int, log2(λ_max / λ_min), RoundUp)
    noise( 2.0x / λ_max, detail = octaves, persistence = 0.7)
end

wavelengths(spectrum::Spectrum_29) = 1 ./ spectrum.cyclefrequency

function amplitude_interpolated(spectrum::Spectrum_29, wavelength::Length)
    λs = wavelengths(spectrum)
    as = spectrum.spectralamplitude
    iabove = findlast(x -> isless(wavelength, x), λs)
    ibelow = min(iabove + 1, length(λs))
    Δx = λs[iabove] - λs[ibelow]
    Δy = as[iabove] - as[ibelow]
    frac = (wavelength - λs[ibelow] ) / Δx
    as[ibelow] + frac * Δy
end