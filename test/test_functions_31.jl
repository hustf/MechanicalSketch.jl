"Lowpass filter coefficients, n is an even number,
cutoff ω_c = 0.75ω_n"
function lowpass_coefficients_2(n)
    @assert iseven(n)
    # Single side, odd number
    m = div(n - 1,  2)
    ωc = π
    rng = -m:1:-1
    # Filter coefficients h
    h = sin.(ωc * rng) ./ (rng * π)
    push!(h, ωc / π)
    append!(h, reverse(h[1:m]))
    h
end

"Highpass filter coefficients, n is an even number,
cutoff ω_c = 0.25ω_n"
function highpass_coefficients_2(n)
    @assert iseven(n)
    # Single side, odd number
    m = div(n - 1,  2)
    ωc = π / 4
    rng = -m:1:-1
    # Filter coefficients h
    h = - sin.(ωc * rng) ./ (rng * π)
    push!(h, 1 - ωc / π)
    append!(h, reverse(h[1:m]))
    h
end

"Bandpass filter coefficients, n is an even number,
cutoff ω_c = [0.25, 0.75)ω_n "
function bandpass_coefficients_2(n)
    highpass_coefficients_2(n) .* lowpass_coefficients_2(n)
end

"Blackman window coeffients, n is an even number"
function blackman_coefficients_3(n)
    @assert iseven(n)
    m = div(n - 1,  2)
    freqs = (-m:1:m) * π / m
    0.42 .+ 0.5 * cos.( freqs) .+ 0.08 * cos.(2 * freqs)
end

"Finite impulse response filter, high pass, total length n (even)"
function fir_coefficients_2(n)
    #highpass_coefficients_2(n) .* blackman_coefficients_3(n)
    #blackman_coefficients_3(n)
    [1.0 for i in 1:n-1]
end


function convolute_image_4(xs, ys, f_xy, n_xy, h, cutoff)
    # Output buffer
    M = Array{Float64}(undef, length(ys), length(xs)) # Image processing convention: a column has a horizontal line of pixels
    fir = SVector{NS_4 * 2 -1}(fir_coefficients_2(NS_4 * 2))
    @assert eltype(xs) <: Quantity{Float64}
    @assert eltype(ys) <: Quantity{Float64}
    @assert n_xy(xs[1], ys[1]) isa Float64
    # prepare a mutable but fast working buffer forward, and another backward.
    vxf = similar(SVector{NS_4}(fill(xs[1], NS_4)))
    vyf = similar(vxf)
    vxb = similar(vxf)
    vyb = similar(vxf)
    rowsy = length(ys)
    for (i::Int64, x::Quantity{Float64}) in enumerate(xs), (j::Int64, y::Quantity{Float64}) in enumerate(ys)
        vxf[1], vyf[1], vxb[1], vyb[1] = x, y, x, y
        # Find the streamline path
        # Put coordinates to sample in forward and aft buffers (no need to store them in memory really?)
        rk4_steps!(f_xy, vxf, vyf, h)
        rk4_steps!(f_xy, vxb, vyb, -h)
        vx = vcat(reverse(vxf), vxb[1:(end -1)])
        vy = vcat(reverse(vyf), vyb[1:(end -1)])
        # Find the intensity for our one pixel.
        pv  = convolute_pixel(fir, vx, vy, n_xy, h, cutoff)
        # Find the original indexes and update the image matrix
        ii = rowsy + 1 - j
        jj = i
        M[ii, jj] = pv / oneunit(pv)
    end
    M
end

function samplepoints(streamlinelength, λ_min , λ_max)
    x0 = rand() * 1000.0m
    xs = range(x0, x0 + streamlinelength, length = 20)
    no = noise_between_wavelengths(λ_min, λ_max, xs, normalize = false)
end

function samplebars_31(samples, maxwidth)
    pts = Vector{Point}()
    maxx = length(samples)
    for (i, a) in enumerate(samples)
        x = maxwidth * i / maxx
        y = - a
        push!(pts,  Point(x, 0y))
        push!(pts,  Point(x, y))
    end
    pts
end

function draw_samplebars_31(origo, samples, maxwidth; rotatehue_degrees_total = 0°)
    startcolo = get_current_RGB()
    samplepoints = samplebars_31(samples,  maxwidth)
    function foovertex(n)
        if mod(n, 3) == 2
            rotatedeg = (n - 1) * rotatehue_degrees_total / length(samplepoints)
            sethue(rotate_hue(startcolo, rotatedeg))
            circle(O, 0.006m, :stroke)
        end
    end
    @layer begin
        for i in range(1, length(samplepoints) - 1, step = 2)
            line(origo + samplepoints[i], origo + samplepoints[i + 1], :stroke)
            foovertex(i)
        end
    end
end

function draw_sampleplot_31(origo, samples, maxwidth)
    @layer begin
        sethue(color_from_palette("red"))
        draw_samplebars_31(origo, samples, maxwidth, rotatehue_degrees_total = 270°)
        sethue(PALETTE[3])
        arrow(origo, origo + (0.0,  -2EM))
        arrow(origo, origo + (6EM, 0.0))
    end
end

"""
    z_transform_contributions(vs::T, z::Complex)
        -> Complex
where
    vs are the samples
    z is a point in the complex plane
"""
function z_transform_contributions(vs::T, z::Complex) where {T<:Union{AbstractRange, Vector}}
    [s * z^-(i - 1) for (i, s) in enumerate(vs)]
end
z_transform_contributions_points(vs, z) = [EM * Point(real(ŝ), imag(ŝ)) for ŝ in z_transform_contributions(vs, z)]