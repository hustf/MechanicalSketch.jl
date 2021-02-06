"""
    function_to_interpolated_function(f_xy; physwidth = 10.0m, physheight = 4.0m)

Input: f: (Q, Q)  → (Q, Q) Function taking a tuple quantities, outputs a tuple of quantities
    physwidth:  Q
    physheight: Q

Output: f: (Q, Q)  → (Q, Q) Function taking a tuple quantities, outputs a tuple of quantities

Convert the function f_xy into an interpolated function. The output function is linearly interpolated
between pixels, based on the currently defined sketch scale.

The output of the function can be otherwise; this is just the originally intended use.
"""
function function_to_interpolated_function(f_xy; physwidth = 10.0m, physheight = 4.0m, centered = true)
    # Position iterators
    xs, ys = x_y_iterators_at_pixels(;physwidth, physheight, centered)
    tuplemat = [f_xy(x, y) for x in xs, y in reverse(ys)]
    fxy_inter = interpolate((xs, reverse(ys)),
        tuplemat,
        Gridded(Linear()));
    # Extend the domain, using the same values as on the domain border. Don't know how the closest point
    # on domain boundary is found.
    extrapolate(fxy_inter, Flat())
end


"""
    matrix_to_function(matrix::Array{Quantity{Complex{Float64}, D, U}, 2}) where {D, U}


Input: CQ²

Output: f: (Q, Q)  → (Q, Q) Function taking coordinates as a complex quantity, outputs a tuple of quantities

where
    Q = Quantity
    CQ² = Matrix of complex quantities

Convert the matrix with complex quantity elements into a vector-valued function.
The output function is linearly interpolated between pixels, based on the currently defined sketch scale.
"""
function matrix_to_function(matrix::Array{Quantity{Complex{Float64}, D, U}, 2}) where {D, U}
    # Image processing convention: a column has a horizontal line of pixels
    ny, nx = size(matrix)
    # We assume every element correspond to a position, unit of length
    physwidth = nx * 1m / get_scale_sketch(m)
    physheight = ny * 1m / get_scale_sketch(m)
    xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
    # Adapt to Interpolations
    tuplemat = map( cmplx -> (real(cmplx), imag(cmplx)), transpose(matrix)[ : , end:-1:1])
    # Function that can interpolate between nodes.
    fxy_inter = interpolate((xs, reverse(ys)),
        tuplemat,
        Gridded(Linear()));
    # Extend the domain, using the same values as on the domain border. Don't know how the closest point
    # on domain boundary is found.
    extrapolate(fxy_inter, Flat())
end


"""
    matrix_to_function(matrix::Array{Float64,2})

Input: R²

Output: f: (R, R) → R function that interpolates between coordinates

where
    R = Real number
    R² = Matrix of real numbers

    (Q, Q) Tuple of quantities

Convert the matrix with real-valued elements into a real-valued function. The domain of the function
is quantities, i.e. two position coordinates. The size of the domain is taken from current sketch scale.
The output function is linearly interpolated between pixels, based on the currently defined sketch scale.
"""
function matrix_to_function(matrix::Array{Float64,2})
    # Image processing convention: a column has a horizontal line of pixels
    ny, nx = size(matrix)
    # We assume every element correspond to a position, unit of length
    physwidth = nx * 1m / get_scale_sketch(m)
    physheight = ny * 1m / get_scale_sketch(m)
    
    xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
    # Adapt to Interpolations
    transposed_matrix = transpose(matrix)[ : , end:-1:1]
    # Function that can interpolate between nodes.
    fxy_inter = interpolate((xs, reverse(ys)),
        transposed_matrix,
        Gridded(Linear()));
    # Extend the domain, using the same values as on the domain border. Don't know how the closest point
    # on domain boundary is found.
    extrapolate(fxy_inter, Flat())
end

