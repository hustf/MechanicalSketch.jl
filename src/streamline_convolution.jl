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
            trace_diminishing(center, vx, vy)
        end
    end
    grestore()
    nothing
end

"""
    sawtooth(x, maxabs)

Return x for x in the interval [-maxabs, maxabs]

Repeating between these values.
"""
sawtooth(x, maxabs) = rem(x, 2maxabs, RoundNearest)

"""
    line_integral_convolution_complex(f_xy, n_xy, x_mid, y_mid, f_s, f_0)

Find the phase and magnitude for one pixel by projecting noise on 20 points on the streamline passing through it.
Combine Runge-Kutta 4th order and convolution.

Arguments:
f_xy    Function of x and y for visualization
n_xy    Noise function of x and y. The spectrum should be adapted for f_xy.
x_mid   Coordinate for which to evaluate. Streamlines forward and back are found for convolution.
y_mid   Coordinate for which to evaluate
f_s Sampling frequency
f_0 Frequency of interest


The resulting complex number ŝ yields:
    phase = arg(ŝ)
    magnitude = hypot(ŝ)
"""
function line_integral_convolution_complex(f_xy, n_xy, x_mid, y_mid, f_s, f_0)
    x, y = x_mid, y_mid
    # Unitless, normalized circular frequency of interest
    ω_0n = 2π ∙ f_0 / f_s
    # Frequency of interest position on the complex unit circle
    z = exp(-im * ω_0n)
    # z-transform aggregator, complex, start at mid point
    ŝ = n_xy(x, y) * z^0
    # Step length (time), negative for backwards.
    h = -1 / f_s
    for nn in -1:-1:-9
        x, y = rk4_step(f_xy, h, x, y)
        ŝ += (n_xy(x, y)) * z^-nn * (cos(π * nn / 20)^2)
    end
    # Jump back to start
    x = x_mid
    y = y_mid
    # Switch to walking forwards
    for nn in 1:10
        x, y = rk4_step(f_xy, -h, x, y)
        ŝ += n_xy(x, y) * z^-nn * (cos(π * nn / 20)^2)
    end
    ŝ
end






"""
    noise_between_wavelengths(λ_min, λ_max, x)

Generate one value of 1D OpenSimplex noise. Output has  rougly linear amplitude spectrum
between wavelengths. There is also some noise at longer wavelengths.

Wave lengths ´λ_min´, ´λ_max´ and position ´x´ are typically quantities of dimension length.

Standard deviation for random ´x´ is 0.103.
"""
function noise_between_wavelengths(λ_min, λ_max, x)
    @assert λ_min < λ_max "λ_min < λ_max"
    octaves = round(Int, log2(λ_max / λ_min), RoundUp)
    noise( 2x / λ_max, detail = octaves, persistence = 0.7)
end

"""
    noise_between_wavelengths(λ_min, λ_max, x, y)

Generate one value of 2D OpenSimplex noise. Output has  rougly linear amplitude spectrum
between wavelengths. There is also some noise at longer wavelengths.

Wave lengths ´λ_min´, ´λ_max´ and positions ´x´, ´y´ are typically quantities of dimension length.

Standard deviation for random (´x´, ´y´) is 0.103.
"""
function noise_between_wavelengths(λ_min, λ_max, x, y)
    @assert λ_min <= λ_max "λ_min < λ_max"
    octaves = if λ_min != 0 * λ_min
        min(6, max(1, round(Int, log2(λ_max / λ_min), RoundUp)))
    else
        6
    end
    noise( 2x / λ_max, 2y/ λ_max, detail = octaves, persistence = 0.7)
end

"""
    noise_between_wavelengths(λ_min, λ_max, xs, normalize = true) -> Array{T,1} where T <: Number

Generate a vector of 1D OpenSimplex noise. Output has  rougly linear amplitude spectrum
between wavelengths. There is also some noise at longer wavelengths.

Wave lengths ´λ_min´, ´λ_max´ and position 'xs´ are typically quantities of dimension length.
Position xs is an iterator or vector.

If ´normalize = true´, as is default, the standard deviation for a long ´xs´ is  0.1604.

If ´normalize = false´, the standard deviation for random ´xs´ is 0.103.
"""
function noise_between_wavelengths(λ_min, λ_max, xs::T; normalize = true) where T <: Union{AbstractRange, Vector}
    no = [ noise_between_wavelengths(λ_min, λ_max, x) for x in xs]
    normalize ? normalize_datarange(no) : no
end
"""
    noise_between_wavelengths(λ_min, λ_max, xs, ys; normalize = true) -> Array{T,2} where T <: Number

Generate a matrix of 2D OpenSimplex noise. Output has  rougly linear amplitude spectrum
between wavelengths. There is also some noise at longer wavelengths.

Wave lengths ´λ_min´, ´λ_max´ and position iterators ´xs´, ´ys´ are typically quantities of dimension length.
Positions ´xs´ and ´ys´ are iterators or vectors.

If ´normalize = true´, as is default, the standard deviation for a large matrix is 0.1604.

If ´normalize = false´, the standard deviation for random ´xs´ is 0.103.

NOTE that the output matrix follows the image manipulation convention: xs correspond to output rows.
"""
function noise_between_wavelengths(λ_min, λ_max, xs::T, ys::T; normalize = true) where T <: Union{AbstractRange, Vector}
    no = [ noise_between_wavelengths(λ_min, λ_max, x, y) for y in ys, x in xs]
    normalize ? normalize_datarange(no) : no
end

"""
    noise_for_lic(f_xy, xs, ys)

Create a simplex-based noise function to be used for visualizing f_xy.


Input: f_xy: (Q, Q)  → (Q, Q) or CQ: Function taking a tuple of quantities, outputs quantities
    xs and ys are iterators of Q, i.e. pixel cooridinates

Output: f: (Q, Q)  → R Function taking a tuple of quantities, outputs a real number

The range is [0.0, 1.0]

The spectrum amplitudes are adapted to f_xy in order to produce larger noise amplitude for longer wavelength.
This corresponds to larger velocities.
"""
function noise_for_lic(f_xy, xs, ys)
    # Velocity scale from, to
    v_min, v_max = lenient_min_max(f_xy, xs, ys)
    # Number of waves over one streamline
    wave_per_streamline = 2
    # One streamline is traced over a duration of
    Δt = 2.0s
    # Noise spectrum wavelengths
    λ_min, λ_max = Δt∙(v_min, v_max) / wave_per_streamline
    # Simplex noise matrix with linear spectrum - x in rows, y in columns
    mat_no = noise_between_wavelengths(λ_min, λ_max, xs, ys);
    # Make a function that interpolates between noise pixels:
    matrix_to_function(mat_no)
end


"Extract one instance in time from the phase + amplitude info in the complex input matrix"
function lic_matrix_current(scene, framenumber)
    @assert scene.opts isa LicSceneOpts
    @assert scene.opts.data isa Array{Complex{Float64},2} string(scene.opts)
    frames_per_cycle = scene.opts.cycle_duration ∙ (scene.opts.framerate∙s⁻¹)
    # Where we are in the repeating cycle, [0, 1 - frame_duration]
    normalized_time = framenumber / frames_per_cycle
    # Number of waves over one streamline in the noise image
    wave_per_streamline = 2
    θ = 2π ∙ wave_per_streamline ∙ normalized_time
    mi, ma = lenient_min_max(scene.opts.data)

    map(scene.opts.data) do pixel_complex
        θ_pixel = sawtooth(θ + angle(pixel_complex), π )
        hypot(pixel_complex)∙cos(θ_pixel) / ma
    end
end


"""
struct LicSceneOpts
    data
    cycle_duration::Time{Float64}
    framerate::Int
    O::Point
end
This info may be passed through function calls to frame drawing functions.
It contains the information needed to process frames based on
line-integral-convolution, ref. lic_matrix_current
"""
struct LicSceneOpts
    data
    cycle_duration::Time{Float64}
    framerate::Int
    O::Point
end