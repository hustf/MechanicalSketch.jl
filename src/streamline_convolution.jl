"""
    rk4_step!(f, vx, vy, h, n)

Coordinates (vx[n + 1], vy[n + 1]) are updated with the estimated position,
along function f.
        f is a tuple-valued gradient in two dimensions
        vx and vy are vectors representing coordinates like (vx[n], vy[n])
        h is a step-size quantity. If the integration variable is time,
        it defines the length of time betweeen points. It can be negative.
"""
function rk4_step!(f, vx, vy, h, n)
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
    rk4_steps!(f, vx, vy, h)

Coordinates (vx[n > 1], vy[n > 1]) are updated with the estimated positions,
along function f.
     f(x,y) returns a tuple-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size quantity. If the integration variable is time,
     it defines the length of time betweeen points. It can be negative
"""
function rk4_steps!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    if !isnan(f(vx[1], vy[1])[1])
        for n in 1:(length(vx) - 1)
            rk4_step!(f, vx, vy, h, n)
        end
    else
        fill!(vx, NaN * vx[1])
        fill!(vy, NaN * vy[1])
    end
    nothing
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


"""
    draw_streamlines(center, xs, ys, f_xy, h)
where
    center is local origo, a Point, typically equal to global O.
    xs, ys are iterables of quantities, e.g. (-5.0:0.007942811755361398:5.0)m
    f_xy is a function of quantities x and y where the range is also a quantity
    h is a step-size quantity. If the integration variable is time,
        it defines the length of time betweeen points. It can be negative.
Optional keyword arguments:
    nsteps is the number of steps to trace, forwards and backwards from each
        randomly selected point
    probability is the number of streamlines divided by length(xs)*length(ys)

Draws a few random streamlines, starting at a random number of points picked from (xs, ys).
Streamlines are found by starting at the randomly picked centre of their extent.
They may extend outside of the rectangle defined by xs and ys.
"""
function draw_streamlines(center, xs, ys, f_xy, h; nsteps = 10, probability = 0.0001)
    gsave()
    cx = xs[1]::Quantity{Float64}
    cy = ys[1]
    @assert cx isa Quantity{Float64}
    @assert cy isa Quantity{Float64}
    # prepare a mutable but fast working buffer forward, and another backward.
    vxf = similar(SVector{nsteps}(fill(cx, nsteps)))
    vyf = similar(vxf)
    vxb = similar(vxf)
    vyb = similar(vxf)
    for (i::Int64, cx::Quantity{Float64}) in enumerate(xs), (j::Int64, cy::Quantity{Float64}) in enumerate(ys)
        vxf[1], vyf[1], vxb[1], vyb[1] = cx, cy, cx, cy
        if rand() < probability
            # Find the streamline path
            rk4_steps!(f_xy, vxf, vyf, h)
            rk4_steps!(f_xy, vxb, vyb, -h)
            # Reorder to most recent position to oldest position
            vx = vcat(reverse(vxf), vxb)
            vy = vcat(reverse(vyf), vyb)
            diminishingtrace(center, vx, vy)
        end
    end
    grestore()
    nothing
end
