struct Spectrum_29
    cyclefrequency
    spectralamplitude
end
function Spectrum_29(spect::Spectrogram; unitfreq = 1, unitdens = 1)
    binwidth = spect.freq.multiplier
    amplitudes = sqrt.( 2 * spect.power * binwidth) * unitdens
    # amplitudes can be a matrix if the sample size was larger than the window length
    avgamplitudes = mean(amplitudes, dims = 2)
    Spectrum_29(spect.freq * unitfreq, avgamplitudes)
end

function sampledspectrum_29(v, sampledistance; minimumcyclefrequency = NaN, maximumwavelength = NaN)
    welldefined = xor(isnan(minimumcyclefrequency), isnan(maximumwavelength))
    @assert welldefined "either minimumcyclefrequency or maximumwavelength must be given"
    minimumcyclefrequency = isnan(minimumcyclefrequency) ? 1 / maximumwavelength : minimumcyclefrequency
    @assert dimension(sampledistance * minimumcyclefrequency) == NoDims
    unitλ =  oneunit(sampledistance)
    unitv = oneunit(eltype(v))
    maxcyclesamples =  round(Int, upreferred( 1 / (minimumcyclefrequency * sampledistance)))
    windowlength =  min(nextfastfft(maxcyclesamples * 8), length(v))
    # Calculate parameter for a Tukey window with 10 % of window
    # length outside of flat region
    x_flat = 0.5 * 0.9
    α = 1 - 2x_flat
    wind = tukey(windowlength, α)
    onsid = !(eltype(v) <: ComplexQuantity)
    spectul = spectrogram(v / unitv, windowlength,
        onesided = onsid,
        fs = 1 / (sampledistance / unitλ),
        window = wind
        )
    Spectrum_29(spectul, unitfreq = 1 / unitλ, unitdens = unitv)
end

function spectrumbars_29(spect::Spectrum_29)
    iter = zip(spect.cyclefrequency[2:end], spect.spectralamplitude[2:end])
    pts = Vector{Point}()
    maxa = maximum(spect.spectralamplitude[2:end])
    for (f, a) in iter
        λ = 1 / f
        y = a * 2EM * SCALEDIST / maxa
        push!(pts,  Point(λ, 0y))
        push!(pts,  Point(λ, y))
        push!(pts,  Point(λ, 0y))
    end
    pts
end

function draw_spectrumbars_29(origo, spect::Spectrum_29)
    spectpoints = spectrumbars_29(spect)
    prettypoly(origo .+ spectpoints, :stroke, vertexlabels = (n,l ) -> begin
        mod(n, 3) == 2 && circle(O, 0.006m, :stroke)
    end)
end


function draw_spectrum_29(origo, spect::Spectrum_29)
    draw_spectrumbars_29(origo, spect)
    λ_max = 1 / spect.cyclefrequency[2]
    @layer begin
        sethue(PALETTE[3])
        arrow(origo, origo + (0.0,  -2EM))
        settext("<i>Amplitude</i>", origo + (0.0,  -2EM ), markup=true)
        arrow(origo, origo + (min(1.05λ_max, 0.95 * SCALEDIST * WI), 0.0m))
        settext("<i>Wave length, λ [m]</i>", origo + ( 0.8 * SCALEDIST * WI, 0.0m), markup=true)
    end
end

islocalmax(v, i) = i > 1 && i < length(v) && v[i - 1] < v[i] > v[i + 1]

"""
   two_largest_maxima_amplitude_wavelength(spect::Spectrum_29)

   Returns two tuples, (λ_1, a_1), (λ_2, a_2)

where
   λ_1 is the wavelength of the peak amplitude in the spectrum
   a_1 is the peak amplitude in the spectrum
   (λ_2, a_2) is the second largest peak
"""
function two_largest_maxima_amplitude_wavelength(spect::Spectrum_29)
    amps = spect.spectralamplitude
    ua = eltype(amps)
    freqs = spect.cyclefrequency
    uλ = typeof(1 / freqs[1])

    local_maxima_indices = [i for i= 1:length(amps) if islocalmax(amps, i)]
    local_maxima_values = [amps[i] for i in local_maxima_indices]
    sorted_maxima_indices = sortperm(local_maxima_values, rev = true )
    ind1, ind2 = local_maxima_indices[sorted_maxima_indices[1]], local_maxima_indices[sorted_maxima_indices[2]]

    round3(typ, x) = typ <: Quantity ? round(typ, x, digits = 3) : round(x, digits = 3)

    λ_1 = round3(uλ, 1 / freqs[ind1])
    a_1 = round3(ua, amps[ind1])
    λ_2 = round3(uλ, 1 / freqs[ind2])
    a_2 = round3(ua, amps[ind2])

    return (λ_1, a_1), (λ_2, a_2)
end