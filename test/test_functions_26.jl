"Generate a noise image for experimentation."
function noisepic_2(A, physwidth, physheight)
    n_rows, n_cols = size(A)
    no = Matrix{Float64}(undef, n_rows, n_cols)
    n_rows = size(no)[1]
    n_cols_in_division = div(size(no)[2], 3)
    length_one_cycle = CUTOFF_23 * DU_26
    dimension_aligned(OU_26 + (-0.4 * physwidth, 0.0m),  OU_26 +  (-0.4 * physwidth, length_one_cycle ))
    n_cycles = physheight / length_one_cycle
    for row in 1:n_rows
        for col in 1:n_cols
            divno = 1 + col ÷ n_cols_in_division
            rate = 1.414 * divno * n_cycles / n_rows
            # Noise is a function generating noisy data,
            # but where the lowest frequency has wavelength 1.41.
            # I.e., one full cycle when x or y varies from 0 to 1.41.
            no[row, col] = if row < div(n_rows, 2)
                noise(row * rate, col * rate)
            else
                noise(row * rate, col * rate, detail = 6, persistence = 0.9)
            end
        end
    end
    normalize_datarange(no)
end
function convolute_image_2(xs, ys, f_xy, n_xy, h, cutoff)
    # Output buffer
    M = Array{Float64}(undef, length(ys), length(xs)) # Image processing convention: a column has a horizontal line of pixels
    # Window, triangle. TODO Experiment with FIR, Hanning
    wf = SVector{NS_2}(range(1.0, 0.1, length = NS_2));
    wb = SVector{NS_2}(range(1.0, 0.1, length = NS_2));
    #x = xs[1]::Quantity{Float64}
    #y = ys[1]
    @assert eltype(xs) <: Quantity{Float64}
    @assert eltype(ys) <: Quantity{Float64}
    @assert n_xy(xs[1], ys[1]) isa Float64
    # prepare a mutable but fast working buffer forward, and another backward.
    vxf = similar(SVector{NS_2}(fill(xs[1], NS_2)))
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
        # Find the intensity for our one pixel.
        pv  = convolute_pixel(wf, wb, vxf, vyf, vxb, vyb, n_xy, h, cutoff)
        # Find the original indexes and update the image matrix
        ii = rowsy + 1 - j
        jj = i
        M[ii, jj] = pv / oneunit(pv)
    end
    normalize_datarange(M)
end



"""
    convolute_pixel(wf, wb, vxf, vyf, vxb, vyb, nxy, h, cutoff))
where
    wf    Window forward: A vector defining a convolution (filter) window, or kernel, with the same length as buffers.
          The second value is used for weighting the second coordinate.
    wb    Window backward: Similar, but for the backwards direction. The second value is used for weighting the second coordinate.
          Hence, it will be identical to wf in many cases.
    vxf   Vector or buffer of x coordinates, forward direction
    vyf   Vector y coordinates, forward.
    vxb   Vector x, backward
    vyb   Vector y, backwards direction
    nxy   Function, noise field
    h     Step length, duration
    cutoff Velocity, substituted to calculate out-of bounds streamlines
"""
function convolute_pixel(wf, wb, vxf, vyf, vxb, vyb, nxy, h, cutoff)
    @assert length(vxf) == length(vyf)
    @assert length(vxb) == length(vyb)
    x0 = vxf[1]
    y0 = vyf[1]
    prevcontrib = nxy(x0, y0) * cutoff * h
    if isnan(x0) || isnan(y0)
        return 0.0 * prevcontrib
    end
    pv = 0.0 * prevcontrib
    for i = 2:length(vxf)
        prevcontrib = _convolve_contrib(prevcontrib, wf, nxy, vxf, vyf, i)
        pv += prevcontrib
    end
    x0 = vxb[1]
    y0 = vyb[1]
    prevcontrib = nxy(x0, y0) * cutoff * h
    if isnan(x0) || isnan(y0)
        return 0.0 * prevcontrib
    end
    for i = 2:length(vxb)
        prevcontrib = _convolve_contrib(prevcontrib, wb, nxy, vxb, vyb, i)
        pv += prevcontrib
    end
    pv
end
"""
    convolute_pixel(w, vx,  vy, nxy, h, cutoff)
where
    w     Window : A vector defining a convolution (filter) window, or kernel, with the same length as buffers.
    vx    Vector or buffer of x coordinates
    vy    Vector y coordinates
    nxy   Function, noise field
    h     Step length, duration
    cutoff Maximum magnitude
"""
function convolute_pixel(w, vx, vy, nxy, h, cutoff)
    @assert length(vx) == length(vy)
    @assert length(w) == length(vy)
    x0 = vx[1]
    y0 = vy[1]
    prevcontrib = nxy(x0, y0) * cutoff * h
    if isnan(x0) || isnan(y0)
        return 0.0 * prevcontrib
    end
    pv = 0.0 * prevcontrib
    for i = 2:length(vx)
        prevcontrib = _convolve_contrib(prevcontrib, w, nxy, vx, vy, i)
        pv += prevcontrib
    end
    pv
end
function _convolve_contrib(prev, w, nxy, vx, vy, i)
    @assert i > 1
    x = vx[i]
    y = vy[i]
    x0 = vx[i - 1]
    y0 = vy[i - 1]
    if isnan(x0) || isnan(y0) || isnan(x) || isnan(y)
        return prev
    end
    k = w[i]
    ds =  hypot(x - x0, y - y0)
    n = nxy(x, y)
    n * k * ds
end