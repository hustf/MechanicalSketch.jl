ϕ_vortex_33 =  generate_complex_potential_vortex(; pos = complex(0.0, 1.0)m, vorticity = 1.0m²/s / 2π)
ϕ_source_33 = generate_complex_potential_source(; pos = complex(3.0, 0.0)m, massflowout = 1.0m²/s)
ϕ_sink_33 = generate_complex_potential_source(; pos = -complex(3.0, 0.0)m, massflowout = -1.0m²/s)
ϕ_33(p) = ϕ_vortex_33(p) + ϕ_source_33(p) + ϕ_sink_33(p)


"""
    streamlines_add!(v_xy::Extrapolation, streamlinepixels::BitMatrix; centered = true)

Input:
    v_xy: (Q, Q)  → (Q, Q)    Function taking a tuple of quantities, outputs tuple of quantities
    streamlinepixels: A matrix of booleans or real numbers where 0 indicates unoccupied pixel. The matrix
        follows the image manipulation convention: xs correspond to output rows.

Input streamlinepixels is modified in place.
"""
function streamlines_add!(v_xy::Extrapolation, streamlinepixels::BitMatrix; centered = true)
    ny, nx = size(streamlinepixels)
    physwidth = 1.0m * nx / get_scale_sketch(m)
    physheight = 1.0m * ny / get_scale_sketch(m)
    xmin = -centered * physwidth / 2
    xmax = (1 - centered / 2) * physwidth
    ymin = -centered * physheight / 2
    ymax = (1 - centered / 2) * physheight
    xs = range(xmin, xmax, length = nx)
    ys = range(ymin, ymax, length = ny)
    #xs = (1:nx)m / get_scale_sketch(m) .- centered * physwidth / 2
    #ys = (1:ny)m / get_scale_sketch(m) .- centered * physheight/ 2
    # Find an approiate step length (time), negative for backwards.
    v_min, v_max = lenient_min_max(v_xy, xs, ys)
    maxsteplen = 3 * physwidth / nx
    h = maxsteplen / v_max
    min_px_step = 1.0 * v_min / v_max
    bb = (first(xs), last(xs),  first(ys), last(ys))

    for i in range(1, nx * ny, step = 50)
        x = rand(xs)
        y = rand(ys)
        add_streamline!_33(v_xy, streamlinepixels, (first(xs), last(xs),  first(ys), last(ys)), h, min_px_step, x, y)
    end

    nothing
end

#=
"""
    view_float_index(matrix, fi, fj)

view matrix at rounded indexes
"""
view_float_index(matrix, fi, fj) = view(matrix, round(Int, fi), round(Int, fj))
=#
"""
    view_neighbourhood_float_index(matrix, fi, fj)

A 3x3 view around rounded indices. Reduced view if at edge of matrix.
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


float_index(n, mini::T, maxi::T, q::T) where T <: Length = 1 + (n - 1) * (q - mini) / (maxi - mini)

"""
    streamlineindices_33(v_xy, streamlinepixels, bb, h_abs, min_px_step, x, y)
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
function streamlineindices_33(v_xy, streamlinepixels, bb, h_abs, min_px_step, x_mid, y_mid)
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
    bb: Tuple{Q, Q, Q, Q} = (minx, maxx, miny, maxy)
    h_abs:  Q, step length in time, for the Runge-Kutta 4th order method. Will be run with +h_abs and -h_abs.
    min_px_step: Exit criterion, a float number. If the process of the streamline falls below this value over one time step,
        the streamline is considered to end (or start) at that point. Measured in pixels.
    x:Q  Position coordinate
    y:Q  Position coordinate

where Q is a quantity.
"""
function add_streamline!_33(v_xy, streamlinepixels, bb, h_abs, min_px_step, x, y)
    indices = streamlineindices_33(v_xy, streamlinepixels, bb, h_abs, min_px_step, x, y)
    set_true!(streamlinepixels, indices)
    nothing
end


"""
    convolute_image_33(matrix::Array{Quantity{Complex{Float64}, D, U}, 2},
                       streamlinepixels::BitMatrix) where {D, U};
                       centered = true)

Input:
    matrix:           CQ²       Matrix of complex quantities, representing 2d vectors. Typically velocities.
    streamlinepixels: Bool²     Matrix of bits, where 'true' indicates that a line-integral-convolution should be found for this pixel.
    centered          Bool      Keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

    Both matrix arguments must have the same number of rows and columns.
    The relation between pixel indices and spatial positions is implicitly given by ´get_scale_sketch(m)´ together with 'centered'

Output:
    CR²

where
    Q   = Quantity
    CQ² = Complex quantity matrix
    CR² = Matrix of complex floating point numbers

Output phase and amplitude information for 'streamlinepixels'. Used for rendering line-integral-convolution showing a static vector field.
"""
function convolute_image_33(matrix::Array{Quantity{Complex{Float64}, D, U}, 2},
                            streamlinepixels::BitMatrix;
                            centered = true) where {D, U}
    @assert size(matrix) == size(streamlinepixels)
    # Make a continuous function, interpolated between pixels.
    fxy = matrix_to_function(matrix)
    convolute_image_33(fxy, streamlinepixels, centered = centered)
end



"""
    convolute_image_33(f_xy, streamlinepixels::BitMatrix; centered = true)

Input:
    f_xy: (Q, Q)  → (Q, Q)   Function taking two coordinates, outputs a tuple of quantities. The range of function f_xy typically represents velocities
    streamlinepixels:        Bool², matrix where 'true' indicates that a line-integral-convolution should be calculate for this pixel.
    centered                 Keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

    The relation between pixel indices and spatial positions is implicitly given by ´get_scale_sketch(m)´ and 'centered'

Output:
    CR²

where
    Q   = Quantity
    CR² = Matrix of complex floating point numbers

Output phase and amplitude information for 'streamlinepixels'. Used for rendering line-integral-convolution showing a static vector field.
"""
function convolute_image_33(f_xy, streamlinepixels::BitMatrix; centered = true)
    # Make a continuous function, interpolated between pixels. This is supposed to
    # be faster than the original function (which it may not be)
    fxy = if f_xy isa Extrapolation
        f_xy
    else
        ny, nx = size(streamlinepixels)
        physwidth = 1.0m * nx / get_scale_sketch(m)
        physheight = 1.0m * ny / get_scale_sketch(m)
        function_to_interpolated_function(f_xy; physwidth = physwidth, physheight = physheight)
    end
    # Prepare a noise function:
    # Simplex based continuous noise function
    nxy = noise_for_lic(f_xy, streamlinepixels)
    # Convolute forward and back for every pixel
    convolute_image_33(f_xy, nxy, streamlinepixels, centered = centered)
end

"""
    convolute_image_33(f_xy, n_xy, streamlinepixels::BitMatrix; centered = true)

Input:
    f_xy: (Q, Q)  → (Q, Q)   Function taking two coordinates, outputs a tuple of quantities
    n_xy: (Q, Q)  → R        Noise function of x and y. The spectrum should be adapted for f_xy
    streamlinepixels:        Bool², matrix where 'true' indicates that a line-integral-convolution should be calculate for this pixel.
    centered                 keyword argument. If true, values at the centre of the matrix corresponds to (x,y) = (0, 0)m

    The relation between pixel indices and spatial positions is implicitly given by ´get_scale_sketch(m)´

Output:
    CR²

where
    Q = Quantity
    R = Float64
    CR² = Matrix of complex floating point numbers

Output phase and amplitude information for 'streamlinepixels'. Used for rendering line-integral-convolution showing a static vector field.
"""
function convolute_image_33(f_xy::Extrapolation, n_xy::Extrapolation, streamlinepixels::BitMatrix; centered = true)
    ny, nx = size(streamlinepixels)
    physwidth = 1.0m * nx / get_scale_sketch(m)
    physheight = 1.0m * ny / get_scale_sketch(m)
    xmin = -centered * physwidth / 2
    xmax = (1 - centered / 2) * physwidth
    ymin = -centered * physheight / 2
    ymax = (1 - centered / 2) * physheight
    xs = range(xmin, xmax, length = nx)
    ys = range(ymin, ymax, length = ny)
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