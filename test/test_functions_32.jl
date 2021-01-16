
ϕ_vortex_32 =  generate_complex_potential_vortex(; pos = complex(0.0, 1.0)m, vorticity = 1.0m²/s / 2π)
ϕ_source_32 = generate_complex_potential_source(; pos = complex(3.0, 0.0)m, massflowout = 1.0m²/s)
ϕ_sink_32 = generate_complex_potential_source(; pos = -complex(3.0, 0.0)m, massflowout = -1.0m²/s)
ϕ_32(p) = ϕ_vortex_32(p) + ϕ_source_32(p) + ϕ_sink_32(p)



"""
    convolute_image_32(f_xy; physwidth = 10.0m, physheight = 4.0m)

Input:
    f_xy: (Q, Q)  → Q   Function taking two coordinates, outputs a quantity
    physwidth
    physheight
    cutoff

Output:
    Array{Complex{Float64},2}

where
    Q = Quantity

Outputs phase and amplitude information for every pixel in a line-integral-convolution rendering.

The input typically represents velocities.
"""
function convolute_image_32(f_xy; physwidth = 10.0m, physheight = 4.0m)
    # Resolution
    nx = round(Int64, get_scale_sketch(physwidth))
    ny = round(Int64, get_scale_sketch(physheight))
    # Iterators for position - linear integration between points.
    xs = range(-physwidth / 2, stop = physwidth / 2, length = nx)
    ys = range(-physheight / 2, stop = physheight / 2, length = ny)
    # Make a continuous function, interpolated between pixels. This is supposed to
    # be faster than the original function (which it may not be)
    fxy = if f_xy isa Extrapolation
        fxy
    else
        function_to_interpolated_function(f_xy; physwidth = physwidth, physheight = physheight)
    end
    convolute_image_32(fxy, xs, ys)
end

"""
    convolute_image_32(f_xy::Extrapolation, n_xy::Extrapolation, xs, ys)

Input:
    f_xy: (Q, Q)  → Q   Function taking two coordinates, outputs a quantity
    physwidth
    physheight
    cutoff

Output:
    Array{Complex{Float64},2}

where
    Q = Quantity

"""
function convolute_image_32(f_xy::Extrapolation, n_xy::Extrapolation, xs, ys)
    # Image processing convention: a column has a horizontal line of pixels
    M = Array{Complex{Float64}}(undef, length(ys), length(xs))
    @assert eltype(xs) <: Quantity{Float64}
    @assert eltype(ys) <: Quantity{Float64}
    @assert n_xy(xs[1], ys[1]) isa Float64
    # Length of a streamline in time, including forward and back
    Δt = 2.0s
    # Number of waves over one streamline
    wave_per_streamline = 2
    # Frequency of interest
    freq_0 = wave_per_streamline / Δt
    # Number of sample points per set (1 to 9 from tracking backward, 10 (start) to including 20 forward)
    n = 20
    # Sampling frequency.
    freq_s = n / Δt
    rowsy = length(ys)
    for (i::Int64, x::Quantity{Float64}) in enumerate(xs), (j::Int64, y::Quantity{Float64}) in enumerate(ys)
        # Find the phase and magnitude for one pixel by projecting noise on 20 points on the streamline passing through it
        pv  = line_integral_convolution_complex(f_xy, n_xy, x, y, freq_s, freq_0)
        # Find the original indexes and update the image matrix
        M[rowsy + 1 - j, i] = pv
    end
    M
end

"""
    convolute_image_32(f_xy, xs, ys)
"""
function convolute_image_32(f_xy, xs, ys)
    # Prepare a noise function:
    # Simplex based continuous noise function
    nxy = noise_for_lic(f_xy, xs, ys)
    # Convolute forward and back for every pixel
    convolute_image_32(f_xy, nxy, xs, ys)
end


"""
    convolute_image_32(matrix::Array{Quantity{Complex{Float64}, D, U}, 2}) where {D, U}

Assuming the image processing convention: a column has a horizontal line of pixels.
"""
function convolute_image_32(matrix::Array{Quantity{Complex{Float64}, D, U}, 2}) where {D, U}
    # Make a continuous function, interpolated between pixels.
    fxy = matrix_to_function(matrix)
    ny, nx = size(matrix)
    # We assume every element correspond to a position, unit of length
    physwidth = nx * 1m / get_scale_sketch(m)
    physheight = ny * 1m / get_scale_sketch(m)
    # Iterators for position - linear integration between points.
    xs = range(-physwidth / 2, stop = physwidth / 2, length = nx)
    ys = range(-physheight / 2, stop = physheight / 2, length = ny)
    convolute_image_32(fxy, xs, ys)
end






"""
    phase_histog(z, n_bins)
    -> binends, binwidth, relative_bin_counts

z is a collection of complex numbers
n_bins is the number of bins for the histogram
"""
function phase_histog(z, n_bins)
    binwidth = 2π / n_bins
    binends = range(binwidth - π, π, length = n_bins)
    binno(θ) = 1 + round(Int, (θ + π)/ (binwidth ), RoundDown)
    bincounts = [0 for bin in binends]
    for x in z
        θ = angle(x)
        bincounts[binno(θ)] += 1
    end
    binends, binwidth, normalize_datarange(bincounts / sum(bincounts))
end
