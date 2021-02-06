function restart_25(backcolor)
    empty_figure(joinpath(@__DIR__, "test_25.png"))
    background(backcolor)
    sethue(PALETTE[8])
end
"Prepare Gaussian noise mask as a first iteration. Normalize it to 0..1"
function noisepic_1(A)
    no = randn(size(A));
    # That is too random (?). Let's try a more gently varying nose on the left 2/3
    rate = 0.1
    nrows = size(no)[1]
    ncols = div(size(no)[2], 3)
    for row in 1:nrows
        for col in 1:ncols
            no[row,col] = noise(row * rate * 2, col * rate * 2)
        end
        for col in (ncols+1):(2 * ncols)
            no[row,col] = noise(row * rate * 4, col * rate * 4)
        end
    end
    normalize_datarange(no)
end
"""
This is not for use in the final algorithm, just for debugging.
Plots a polyline until NaN or end of vectors.
"""
function prline_2(origo, vx, vy)
    move(origo + (vx[1], vy[1]))
    for (x, y) in zip(vx, vy)
        isnan(x) && break
        isnan(y) && break
        line(origo + (x, y))
    end
    do_action(:stroke)
end

"""
    rk4_step_1!(f, vx, vy, h, n)

Coordinates (vx[n + 1], vy[n + 1]) are updated with the estimated position,
along function f.
        f is a tuple-valued gradient in two dimensions
        vx and vy are vectors representing coordinates like (vx[n], vy[n])
        h is a step-size quantity. If the integration variable is time,
        it defines the length of time betweeen points. It can be negative.
"""
function rk4_step_1!(f, vx, vy, h, n)
    fx0, fy0 = f(vx[n], vy[n])
    x1 = vx[n] + fx0 * h * 0.5
    y1 = vy[n] + fy0 * h * 0.5
    fx1, fy1 = f(x1, y1)
    x2 = vx[n] + fx1 * h * 0.5
    y2 = vy[n] + fy1 * h * 0.5
    fx2, fy2  = f(x2, y2)
    x3 = vx[n] + fx2 * h
    y3 = vy[n] + fy2 * h
    fx3, fy3 = f(x3, y3)
    vx[n + 1] = vx[n] + 1/6 * h * ( fx0  + 2∙fx1 + 2∙fx2 + fx3 )
    vy[n + 1] = vy[n] + 1/6 * h * ( fy0  + 2∙fy1 + 2∙fy2 + fy3 )
end

"""
    rk4_steps_1!(f, vx, vy, h)

Coordinates (vx[n > 1], vy[n > 1]) are updated with the estimated positions,
along function f.
     f(x,y) returns a tuple-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size quantity. If the integration variable is time,
     it defines the length of time betweeen points. It can be negative
"""
function rk4_steps_1!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    if !isnan(f(vx[1], vy[1])[1])
        for n in 1:(length(vx) - 1)
            rk4_step_1!(f, vx, vy, h, n)
        end
    else
        fill!(vx, NaN * vx[1])
        fill!(vy, NaN * vy[1])
    end
    nothing
end


function _convolve_contrib_1(prev, w, nxy, vx, vy, i)
    @assert i > 1
    x = vx[i]
    y = vy[i]
    x0 = vx[i - 1]
    y0 = vy[i - 1]
    if isnan(x0) || isnan(y0) || isnan(x) || isnan(y)
        return prev
    end
    k = w[i]
    ds =  hypot((x - x0, y - y0))
    n = nxy(x, y)
    n * k * ds
end

"""
    convolute_pixel_1(wf, wb, vxf, vyf, vxb, vyb, nxy, h, cutoff)
where
    wf    Window forward: A vector defining a convolution (filter) window, or kernel, with the same length as buffers.
          The second value is used for weighting the second coordinate.
    wb    Window backward: Similar, but for the backwards direction. The second value is used for weighting the second coordinate.
          Hence, it will be identical to wf in many cases.
    vxf   Vector or buffer of x coordinates, forward direction
    vyf   Vector y coordinates, forward.
    vxb   Vector x, backward
    vyb   Vector y, backwards direction
    fxy   Function, vector field (output is a tuple)
    nxy   Function, noise field
    h     Step length, duration
    cutoff Velocity, substituted to calculate out-of bounds streamlines
"""
function convolute_pixel_1(wf, wb, vxf, vyf, vxb, vyb, nxy, h, cutoff)
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
        prevcontrib = _convolve_contrib_1(prevcontrib, wf, nxy, vxf, vyf, i)
        pv += prevcontrib
    end
    x0 = vxb[1]
    y0 = vyb[1]
    prevcontrib = nxy(x0, y0) * cutoff * h
    if isnan(x0) || isnan(y0)
        return 0.0 * prevcontrib
    end
    for i = 2:length(vxb)
        prevcontrib = _convolve_contrib_1(prevcontrib, wb, nxy, vxb, vyb, i)
        pv += prevcontrib
    end
    pv
end

function convolute_image_1(xs, ys, f_xy, n_xy, h, cutoff)
    # Output buffer
    M = Array{Float64}(undef, length(ys), length(xs)) # Image processing convention: a column has a horizontal line of pixels
    # Window, triangle. Experiment with FIR, Hanning
    wf = SVector{NS_1}(range(1.0, 0.1, length = NS_1));
    wb = SVector{NS_1}(range(1.0, 0.1, length = NS_1));
    cx = xs[1]::Quantity{Float64}
    cy = ys[1]
    @assert cx isa Quantity{Float64}
    @assert cy isa Quantity{Float64}
    @assert n_xy(cx, cy) isa Float64
    @assert first(ys) < last(ys)
    # prepare a mutable but fast working buffer forward, and another backward.
    vxf = similar(SVector{NS_1}(fill(cx, NS_1)))
    vyf = similar(vxf)
    vxb = similar(vxf)
    vyb = similar(vxf)
    @assert wf[1] == 1.0    # Since hardcoded below (??)
    @assert wb[1] == 1.0
    i = 1
    j = 1
    rowsy = length(ys)
    for (i::Int64, cx::Quantity{Float64}) in enumerate(xs), (j::Int64, cy::Quantity{Float64}) in enumerate(ys)
        vxf[1], vyf[1], vxb[1], vyb[1] = cx, cy, cx, cy
        # Find the streamline path
        # Put coordinates to sample in forward and aft buffers (no need to store them in memory really?
        rk4_steps_1!(f_xy, vxf, vyf, h)
        rk4_steps_1!(f_xy, vxb, vyb, -h)
        # Find the intensity for our one pixel.
        pv  = convolute_pixel_1(wf, wb, vxf, vyf, vxb, vyb, n_xy, h, cutoff)
        # Find the original indexes and update the image matrix
        ii = rowsy + 1 - j
        jj = i
        M[ii, jj] = pv / oneunit(pv)
    end
    normalize_datarange(M)
end


"Draws a few random streamlines. xs and ys are iterators covering 'all' coordinates for function f_xy"
function draw_streamlines_1(origo, xs, ys, f_xy, h)
    cx = xs[1]::Quantity{Float64}
    cy = ys[1]
    @assert cx isa Quantity{Float64}
    @assert cy isa Quantity{Float64}
    # prepare a mutable but fast working buffer forward, and another backward.
    vxf = similar(SVector{NS_1}(fill(cx, NS_1)))
    vyf = similar(vxf)
    vxb = similar(vxf)
    vyb = similar(vxf)
    for (i::Int64, cx::Quantity{Float64}) in enumerate(xs), (j::Int64, cy::Quantity{Float64}) in enumerate(ys)
        vxf[1], vyf[1], vxb[1], vyb[1] = cx, cy, cx, cy
        if rand() < 0.0002
            # Find the streamline path
            rk4_steps_1!(f_xy, vxf, vyf, h)
            rk4_steps_1!(f_xy, vxb, vyb, -h)
            # Blueish is forward
            sethue(PALETTE[1])
            prline_2(origo, vxf, vyf)
            # Reddish and darker is backward
            sethue(color_with_luminance(PALETTE[4], 0.3))
            prline_2(origo, vxb, vyb)
            sethue(PALETTE[8])
        end
    end
    nothing
end