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