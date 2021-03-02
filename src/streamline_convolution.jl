"""
    draw_streamlines(center, xs, ys, f_xy, h)
where
    center is local origo, a Point, typically equal to global O.
    xs, ys are quantity iterators, e.g. (-5.0:0.007942811755361398:5.0)m
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
    x = x_mid
    y = y_mid
    # Unitless, normalized circular frequency of interest
    ω_0n = 2π ∙ f_0 / f_s
    # Frequency of interest position on the complex unit circle
    z = exp(-im * ω_0n)
    # z-transform aggregator, complex, start at mid point
    ŝ = n_xy(x, y) * z^0
    # Step length (time), negative for backwards.
    h = -1 / f_s
    for nn in -1:-1:-9
        x, y = rk4_step(f_xy, h, x, y)                         # This takes 0.37 of total time in the function
                                                               # 1.130 μs (1 allocation: 32 bytes)
        ŝ += (n_xy(x, y)) * z^-nn * (cos(π * nn / 20)^2)       # This takes 144/1539 = 0.09 of total time in the function
                                                               #  449.239 ns (7 allocations: 144 bytes)
    end
    # Jump back to start
    x = x_mid
    y = y_mid
    # Switch to walking forwards
    for nn in 1:10
        x, y = rk4_step(f_xy, -h, x, y)                       # This takes 637 / 1539 = 0.41 of total time in the function
        ŝ += n_xy(x, y) * z^-nn * (cos(π * nn / 20)^2)        # This take 163 / 1539 = 0.11 of total time in the function
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
    waves_per_cycle = 2
    # One streamline is traced over a duration of
    Δt = 2.0s
    # Noise spectrum wavelengths
    λ_min, λ_max = Δt∙(v_min, v_max) / waves_per_cycle
    # Simplex noise matrix with linear spectrum - x in rows, y in columns
    mat_no = noise_between_wavelengths(λ_min, λ_max, xs, ys);
    # Make a function that interpolates between noise pixels:
    matrix_to_function(mat_no)
end

"""
    noise_for_lic(f_xy, matrix::BitMatrix; centered = true)

Create a simplex-based noise function to be used for visualizing f_xy.


Input:  f_xy: (Q, Q)  → (Q, Q) or CQ: Function taking a tuple of quantities, outputs quantities
        matrix:    Used for finding the size of output. The relation between pixel indices and spatial
            positions is implicitly given by ´scale_to_pt(m)´
        centered   keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

Output: f: (Q, Q)  → R Function taking a tuple of quantities, outputs a real number

The range is [0.0, 1.0]

The spectrum amplitudes are adapted to f_xy in order to produce larger noise amplitude for longer wavelength.
This corresponds to larger velocities.
"""
function noise_for_lic(f_xy, matrix::BitMatrix; centered = true)
    ny, nx = size(matrix)
    physwidth = nx * scale_pt_to_unit(m)
    physheight =  ny * scale_pt_to_unit(m)
    xmin = -centered * physwidth / 2
    xmax = (1 - centered / 2) * physwidth
    ymin = -centered * physheight / 2
    ymax = (1 - centered / 2) * physheight
    xs = range(xmin, xmax, length = nx)
    ys = range(ymin, ymax, length = ny)
    noise_for_lic(f_xy, xs, ys)
end

"""
    lic_matrix_current(scene, framenumber; waves_per_cycle = 2)

When called in the context of a Scene, the complex convolution matrix is input via
the scene definition, see SceneOpts, Scene and Movie.

Extract one instance in time from the phase + amplitude info in the complex input matrix.

Output: R² Matrix of floating point numbers, representing the animation at this frame
    in this scene context, intended to be displayed as an image.

    If the maximum magnitude in scene.opts.phase_magnitude_matrix, output elements
    are in the range -1.0, 1.0.
"""
function lic_matrix_current(scene, framenumber)
    @assert scene.opts isa LicSceneOpts
    @assert scene.opts.phase_magnitude_matrix isa Array{Complex{Float64},2} string(scene.opts)
    frames_per_cycle = scene.opts.cycle_duration ∙ scene.opts.framerate
    # Where we are in the repeating cycle, [0, 1 - frame_duration]
    normalized_time = framenumber / frames_per_cycle
    # Number of waves over one streamline in the noise image
    CR² = scene.opts.phase_magnitude_matrix
    lic_matrix_current(CR², normalized_time; scene.opts.waves_per_cycle)
end

"""
    lic_matrix_current(CR²:Matrix{Complex{Float64}}, normalized_time;
                       waves_per_cycle = 2, zeroval = 0.0)

Input: CR²    Matrix of complex floating point numbers
                  phase and amplitude information. Used for rendering line-integral-convolution
                  showing a static vector field.
       normalized_time       a number in the range [0, 1], where 0 and 1 gives the same result, so pick one when looping frames.
       waves_per_cycle       Keyword argument, depending on the assumptions made when calculating CR².
       zeroval               Keyword argument, the value which replaces 0 in CR², could be used to emphasize streamlines

Output: R² Matrix of floating point numbers, representing the animation at this normalized time, intended to be displayed as an image.
Output elements are in the range -1.0, 1.0 (possible exception if 'zeroval' is outside.)
"""
function lic_matrix_current(CR²::Matrix{Complex{Float64}}, normalized_time;
                           waves_per_cycle = 2, zeroval = 0.0)
    @assert 0 <= normalized_time <= 1
    θ = 2π ∙ waves_per_cycle ∙ normalized_time
    mi, ma = lenient_min_max(CR²)
    map(CR²) do pixel_complex
        θ_pixel = sawtooth(θ + angle(pixel_complex), π )
        magn = hypot(pixel_complex) / ma
        magn > 0 ? magn∙cos(θ_pixel) : zeroval
    end
end


"""
    streamlines_add!(v_xy::Extrapolation, streamlinepixels::BitMatrix; centered = true, targetdensity = 0.42)

Input:
    v_xy: (Q, Q)  → (Q, Q)    Function taking a tuple of quantities, outputs tuple of quantities
    streamlinepixels: A matrix of booleans or real numbers where 0 indicates unoccupied pixel. The matrix
        follows the image manipulation convention: xs correspond to output rows.
    centered          Bool      Keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m
    targetdensity     Real      Keyword argument. Fraction of pixels covered by streamlines.

Input matrix streamlinepixels is modified in place.
"""
function streamlines_add!(v_xy::Extrapolation, streamlinepixels::BitMatrix; centered = true, targetdensity = 0.42)
    ny, nx = size(streamlinepixels)
    physwidth = nx * scale_pt_to_unit(m)
    physheight = ny * scale_pt_to_unit(m)
    xmin = -centered * physwidth / 2
    xmax = (1 - centered / 2) * physwidth
    ymin = -centered * physheight / 2
    ymax = (1 - centered / 2) * physheight
    xs = range(xmin, xmax, length = nx)
    ys = range(ymin, ymax, length = ny)
    # Find an approiate step length (time), negative for backwards.
    v_min, v_max = lenient_min_max(v_xy, xs, ys)
    maxsteplen = 3 * physwidth / nx
    h = maxsteplen / v_max
    #
    min_px_step = 1.0 * v_min / v_max
    bb = (first(xs), last(xs),  first(ys), last(ys))
    count = 0
    while true
        count +=1
        x = rand(xs)
        y = rand(ys)
        add_streamline!(v_xy, streamlinepixels, bb, h, min_px_step, x, y)
        # Check pixel density
        if mod(count, 10) == 0
            sum(streamlinepixels) / (nx*ny) >= targetdensity && break
        end
        # Check against a reasoable upper limit, 2500 * 4000 pixels
        count > 10^7 && break
    end
    nothing
end

"""
    view_neighbourhood_float_index(matrix, fi, fj)

A 3x3 view around integer indices. Reduced view if at edge of matrix.
"""
function view_neighbourhood_float_index(matrix, fi, fj)
    i = round(Int, fi)
    j = round(Int, fj)
    imin = max(1, i - 1)
    imax = min(size(matrix)[1], i + 1)
    jmin = max(1, j - 1)
    jmax = min(size(matrix)[2], j + 1)
    view(matrix, imin:imax, jmin:jmax)
end


"""
    float_index(maxindex::Int, mini::T, maxi::T, q::T) where T

Linear floating index of q given that index 1 corresponds to 'mini' and 'maxindex' corresponds to 'maxi'.
"""
float_index(maxindex::Int, mini::T, maxi::T, q::T) where T = 1 + (maxindex - 1) * (q - mini) / (maxi - mini)


"""
    streamlineindices(v_xy, streamlinepixels, bb, h_abs, min_px_step, x, y)
    -> Set{Tuple{Int64, Int64}}

Return indices which would be occupied for a streamline through (x, y).
The streamline is traced forwards and backwards until
    - boundary is reached
    - flow stops / starts
    - a previously occupied pixel is hit by the streamline
    - a starting or ending point of a runge-kutta step hits within two pixels of an occupied pixel
    - the number of steps (forward or back) exceed both dimensions of streamlinepixels

Input:
    v_xy: (Q, Q)  → (Q, Q) or CQ: Function taking a tuple of quantities, outputs tuple of quantities
    streamlinepixels: A matrix of booleans or real numbers where 0 indicates unoccupied pixel. The matrix
        follows the image manipulation convention: xs correspond to output rows.
    bb: Tuple{Q, Q, Q, Q} = (minx, maxx, miny, maxy)
    h_abs:  Q, step length in time, for the Runge-Kutta 4th order method. Will be run with +h_abs and -h_abs.
    min_px_step: Exit criterion, a float number. If the process of the streamline falls below this value over one time step,
      the streamline is considered to end (or start) at that point. Measured in pixels.
    x:Q
    y:Q

where Q is a quantity.
"""
function streamlineindices(v_xy, streamlinepixels, bb, h_abs, min_px_step, x_mid, y_mid)
    ny, nx = size(streamlinepixels)
    maxsteps = 3 * max(ny, nx)
    countsteps = 0
    minx, maxx, miny, maxy = bb

    indices = Set{Tuple{Int64, Int64}}()

    x, y = x_mid, y_mid

    # Check neighborhood at start point for previous occupants

    startview = view_neighbourhood_float_index(streamlinepixels,
        float_index(ny, maxy, miny, y),
        float_index(nx, minx, maxx, x))
    if sum(startview) > 0
        return indices
    end
    # First trace forwards from x (positive time step h), then backwards
    for h_bothways in (h_abs, -h_abs)
        while true

            ro = float_index(ny, maxy, miny, y)
            ro < 1.0 && break

            ro > ny && break

            co = float_index(nx, minx, maxx, x)
            co < 1.0 && break
            co > nx && break

            # Find the end of this straight segment
            x1, y1 = rk4_step(v_xy, h_bothways, x, y)

            ro1 = float_index(ny, maxy, miny, y1)
            ro1 < 1.0 && break
            ro1 > ny && break

            co1 = float_index(nx, minx, maxx, x1)
            co1 < 1.0 && break
            co1 > nx && break

            # Is progress shorter than the given minimum step?
            if hypot(ro1 - ro, co1 - co) < min_px_step
                push!(indices, circle_algorithm(ny, nx, ro1, co1)...)
                break
            end
            # Is neighborhood at end of segment previously occupied?
            if sum(view_neighbourhood_float_index(streamlinepixels, ro1, co1)) > 0
                break
            end

            # Integer indices in this linear segment
            lineindices = bresenhams_line_algorithm(ny, nx, ro, co, ro1, co1)

            # Is any point touching previous occupants?
            pixeloccupied = sum(lineindices) do (i, j)
                    streamlinepixels[i, j] == true
                end > 0
            pixeloccupied && break

            # It's ok, store this straight line
            push!(indices, lineindices...)
            countsteps +=1

            # Avoid endless loop: Is the streamline too long (perhaps spiralling, circling?)
            if countsteps > maxsteps
                push!(indices, crossing_line_algorithm(ny, nx, ro1, co1)...)
                break
            end

            # Prepare next iteration
            x, y = x1, y1
        end
        countsteps = 0
        x, y = x_mid, y_mid
    end
    indices
end

"""
    set_true!(matrix, indices::Set{Tuple{Int64, Int64}})

Mofifies the matrix elements at indices to one / true
"""
function set_true!(matrix, indices::Set{Tuple{Int64, Int64}})
    occupied = one(eltype(matrix))
    for (i, j) in indices
        matrix[i, j] = occupied
    end
    nothing
end


"""
    add_streamline!(v_xy, occupied_matrix, bb, h_abs, min_px_step, x, y)

Modify occupied_matrix: set elements entered by a streamline through (x, y) to true or to 1 depending on type.

The streamline is traced forwards and backwards until
    - boundary is reached
    - flow stops / starts
    - a previously occupied pixel is hit by the streamline
    - a starting or ending point of a runge-kutta step hits within two pixels of an occupied pixel
    - the number of steps  (forward or back) exceed both dimensions of streamlinepixels

Input:
    v_xy: (Q, Q)  → (Q, Q) or CQ: Function taking a tuple of quantities, outputs tuple of quantities
    streamlinepixels: A matrix of booleans or real numbers where 0 indicates unoccupied pixel. The matrix
        follows the image manipulation convention: xs correspond to output rows.
    bb: Tuple{Q, Q, Q, Q} = (minx, maxx, miny, maxy), coordinates for 'v_xy'
    h_abs:  Q, step length in time, for the Runge-Kutta 4th order method. Will be run with +h_abs and -h_abs.
    min_px_step: Exit criterion, a float number. If the process of the streamline falls below this value over one time step,
        the streamline is considered to end (or start) at that point. Measured in pixels.
    x:Q  Position coordinate
    y:Q  Position coordinate

where Q is a quantity.
"""
function add_streamline!(v_xy, streamlinepixels, bb, h_abs, min_px_step, x, y)
    indices = streamlineindices(v_xy, streamlinepixels, bb, h_abs, min_px_step, x, y)
    set_true!(streamlinepixels, indices)
    nothing
end


"""
    convolution_matrix(matrix::Array{Quantity{Complex{Float64}, D, U}, 2};
                       centered = true; targetdensity = 0.42) where {D, U}

Input:
    matrix:           CQ²       Matrix of complex quantities, representing 2d vectors. Typically velocities.
    centered          Bool      Keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m
    targetdensity     Real      Keyword argument. Fraction of pixels covered by streamlines.

    The relation between pixel indices and spatial positions is implicitly given by ´scale_to_pt(m)´ together with 'centered'

Output:
    CR²

where
    Q   = Quantity
    CQ² = Complex quantity matrix
    CR² = Matrix of complex floating point numbers

Streamlines are randomly added until the density of pixels reaches targetdensity'
Output phase and amplitude information for 'streamlinepixels'.
Used for rendering line-integral-convolution showing a static vector field.
"""
#
function convolution_matrix(matrix::Array{Quantity{Complex{Float64}, D, U}, 2};
                           centered = true, targetdensity = 0.42) where {D, U}
    v_xy = matrix_to_function(matrix)
    streamlinepixels = falses(size(matrix))
    streamlines_add!(v_xy::Extrapolation, streamlinepixels::BitMatrix; centered, targetdensity)
    convolution_matrix(v_xy, streamlinepixels; centered)
end


"""
    convolution_matrix(matrix::Array{Quantity{Complex{Float64}, D, U}, 2},
                       streamlinepixels::BitMatrix) where {D, U};
                       centered = true)

Input:
    matrix:           CQ²       Matrix of complex quantities, representing 2d vectors. Typically velocities.
    streamlinepixels: Bool²     Matrix of bits, where 'true' indicates that a line-integral-convolution should be found for this pixel.
    centered          Bool      Keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

    Both matrix arguments must have the same number of rows and columns.
    The relation between pixel indices and spatial positions is implicitly given by ´scale_to_pt(m)´ together with 'centered'

Output:
    CR²

where
    Q   = Quantity
    CQ² = Complex quantity matrix
    CR² = Matrix of complex floating point numbers

Output phase and amplitude information for 'streamlinepixels'. Used for rendering line-integral-convolution showing a static vector field.
"""
function convolution_matrix(matrix::Array{Quantity{Complex{Float64}, D, U}, 2},
                            streamlinepixels::BitMatrix;
                            centered = true) where {D, U}
    @assert size(matrix) == size(streamlinepixels)
    # Make a continuous function, interpolated between pixels.
    fxy = matrix_to_function(matrix)
    convolution_matrix(fxy, streamlinepixels, centered = centered)
end



"""
    convolution_matrix(f_xy, streamlinepixels::BitMatrix; centered = true)

Input:
    f_xy: (Q, Q)  → (Q, Q)   Function taking two coordinates, outputs a tuple of quantities. The range of function f_xy typically represents velocities
    streamlinepixels:        Bool², matrix where 'true' indicates that a line-integral-convolution should be calculate for this pixel.
    centered                 Keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

    The relation between pixel indices and spatial positions is implicitly given by ´scale_to_pt(m)´ and 'centered'

Output:
    CR²

where
    Q   = Quantity
    CR² = Matrix of complex floating point numbers

Output phase and amplitude information for 'streamlinepixels'. Used for rendering line-integral-convolution showing a static vector field.
"""
function convolution_matrix(f_xy, streamlinepixels::BitMatrix; centered = true)
    # Make a continuous function, interpolated between pixels. This is supposed to
    # be faster than the original function (which it may not be)
    fxy = if f_xy isa Extrapolation
        f_xy
    else
        ny, nx = size(streamlinepixels)
        physwidth = nx * scale_pt_to_unit(m)
        physheight = ny * scale_pt_to_unit(m)
        function_to_interpolated_function(f_xy; physwidth = physwidth, physheight = physheight)
    end
    # Prepare a noise function:
    # Simplex based continuous noise function
    nxy = noise_for_lic(f_xy, streamlinepixels)
    # Convolute forward and back for every pixel
    convolution_matrix(f_xy, nxy, streamlinepixels, centered = centered)
end

"""
    convolution_matrix(f_xy, n_xy, streamlinepixels::BitMatrix; centered = true)

Input:
    f_xy: (Q, Q)  → (Q, Q)   Function taking two coordinates, outputs a tuple of quantities
    n_xy: (Q, Q)  → R        Noise function of x and y. The spectrum should be adapted for f_xy
    streamlinepixels:        Bool², matrix where 'true' indicates that a line-integral-convolution should be calculate for this pixel.
    centered                 keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

    The relation between pixel indices and spatial positions is implicitly given by ´scale_to_pt(m)´

Output:
    CR²

where
    Q = Quantity
    R = Float64
    CR² = Matrix of complex floating point numbers

Output phase and amplitude information for 'streamlinepixels'. Used for rendering line-integral-convolution showing a static vector field.
"""
function convolution_matrix(f_xy::Extrapolation, n_xy::Extrapolation, streamlinepixels::BitMatrix; centered = true)
    ny, nx = size(streamlinepixels)
    physwidth = nx * scale_pt_to_unit(m)
    physheight = ny * scale_pt_to_unit(m)
    xmin = -centered * physwidth / 2
    xmax = (1 - centered / 2) * physwidth
    ymin = -centered * physheight / 2
    ymax = (1 - centered / 2) * physheight
    xs = range(xmin, xmax, length = nx)
    ys = range(ymax, ymin, length = ny)
    # Image processing convention: a column has a horizontal line of pixels
    CR² = zeros(Complex{Float64}, ny, nx)
    @assert eltype(xs) <: Quantity{Float64}
    @assert eltype(ys) <: Quantity{Float64}
    @assert n_xy(xs[1], ys[1]) isa Float64
    # Length of a streamline section in time, including forward and back
    Δt = 2.0s
    # Number of waves over one streamline
    wave_per_streamline = 2
    # Frequency of interest
    freq_0 = wave_per_streamline / Δt
    # Number of sample points per set (1 to 9 from tracking backward, 10 (start) to including 20 forward)
    n = 20
    # Sampling frequency.
    freq_s = n / Δt
    for (ro, y) in zip(1:ny, ys), (co, x) in zip(1:nx, xs)
        if streamlinepixels[ro, co]
            # Find the phase and magnitude for one pixel by projecting noise on 20 points on the streamline passing through it
            pv  = line_integral_convolution_complex(f_xy, n_xy, x, y, freq_s, freq_0)
            # Find the original indexes and update the image matrix
            CR²[ro, co] = pv
        end
    end
    CR²
end


"""
LicSceneOpts(cycle_duration, O;
            framerate = 30.0s⁻¹,
            phase_magnitude_matrix = Matrix{Complex{Float64}}(undef, 0, 0),
            data = missing,
            legend = missing,
            waves_per_cycle = 2,
            luminosity_variation = 0.67 )

This info may be passed through function calls to frame drawing functions.
LicSceneOpts optionally contains information needed to process frames based on line-integral-convolution,
ref. lic_matrix_current.

Input:
    cycle_duration::Time{Float64}
    framerate::typeof(30.0s⁻¹)
    O::Point                                    The origo in the local context of this scene.
    phase_magnitude_matrix::Matrix{ComplexF64}  See below
    data                                        See below
    legend                                      If 'data' exists, also supply a ColorLegend.
    waves_per_cycle                             Default is two, should be according to how 'phase_magnitude_matrix' was found.
    luminosity_variation                        Default is 0.67, possible range is [0,1], where 1.0 is full luminosity variation with convolution.

The phase at 'framenumber' and 'phase_magnitude_pixel' (from '..matrix') is found thus:
    θ = 2π ∙ waves_per_cycle ∙ framenumber / frames_per_cycle
    θ_pixel = sawtooth(θ + angle(pixel_complex), π )

Along with the magnitude, the phase information and 'framenumber' this is used to find the
current luminosity at a pixel.

If LicSceneOpts.data contains a matrix of the same size as 'phase_magnitude_matrix', that
can be used to find chroma and hue for the pixel. The conversion function is given by LicSceneOpts.legend.
"""
struct LicSceneOpts
    cycle_duration::Time{Float64}
    framerate::typeof(30.0s⁻¹)
    O::Point
    phase_magnitude_matrix::Matrix{ComplexF64}
    data
    legend
    waves_per_cycle
    luminosity_variation
end
# Constructor
function LicSceneOpts(cycle_duration, O;
            framerate = 30.0s⁻¹,
            phase_magnitude_matrix = Matrix{Complex{Float64}}(undef, 0, 0),
            data = missing,
            legend = missing,
            waves_per_cycle = 2,
            luminosity_variation = 0.67)
    LicSceneOpts(cycle_duration, framerate, O,
                 phase_magnitude_matrix, data, legend, waves_per_cycle, luminosity_variation)
end

"""
    color_matrix_current(scene, framenumber)

Input: scene     Defines options. See Movie, Scene, SceneOpts.

Output: Color² Matrix of colors representing the animation at this frame.
"""
function color_matrix_current(scene, framenumber)
    @assert scene isa Scene
    @assert scene.opts isa LicSceneOpts
    curmat = lic_matrix_current(scene, framenumber)
    speedmat = scene.opts.data
    color_matrix_mix(curmat, speedmat, scene.opts.legend, scene.opts.luminosity_variation)
end

"""
    color_matrix_mix(lumin_mat, quant_scalar_mat, legend, luminosity_variation)

Input: 
    lumin_mat              Matrix{Float64} - determines luminosity at a pixel. Values in the range -1.0 to 1.0.
    quant_scalar_mat       Matrix of quantities, which are converted to colors using 'legend'
    legend                 <: ColorLegend
    luminosity_variation   Possible range is [0,1], recommended is 0.67. 1.0:full luminosity variation with convolution.

Output: Color² Matrix of colors representing the animation at this frame.
"""
function color_matrix_mix(lumin_mat, quant_scalar_mat, legend, luminosity_variation)
    map(legend.(quant_scalar_mat), lumin_mat) do col, lu
        # lu will be in the range -1.0 to 1.0
        lum = 50 * (lu * luminosity_variation + 1.0)
        # lum will be in the range 0 to 100.
        color_with_lumin(col, lum)
    end
end