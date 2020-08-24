"""
Complex quantities represent position, velocity etc in a plane.
They are a subset of quantities, although some function methods may
need extending outside T<:Real
"""
const ComplexQuantity = Quantity{<:Complex}
const RealQuantity = Quantity{<:Real}
QuantityTuple(z::ComplexQuantity) =  reim(z)
ComplexQuantity(p::QuantityTuple) = complex(p[1] , p[2])
+(p1::Point, shift::ComplexQuantity) = p1 + QuantityTuple(shift)

function string_polar_form(z::ComplexQuantity)
    strarg_r = string(round(typeof(norm(z)), norm(z), digits = 3))
    strarg_θ = string(round(angle(z), digits = 3))
    strargument = strarg_r * "∙exp(" * strarg_θ * "im)"
end

"""
    generate_complex_potential_source(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, massflowout = 1.0m²/s)

We find the velocity potential function of a source or sink by realizing that
´´´
    2π·r·u_r = q
       where u_r is radial velocity
             q is flow
        ↕
    u_r = q / (2π·r)
´´´
The velocity potential, ϕ, is the imaginary valued function found by integrating
velocity along the velocity gradient. The sign and endpoint of the integration
can be defined as we want. With the limitation above:
´´´
    u_r  = ∇ϕ = δu / δr
    ⇑
    ϕ = ∫ q / (2πr) dr = q / (2πr) · ∫ 1 / r dr = q / (2πr) · ln(r)
´´´
"""
function generate_complex_potential_source(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, massflowout = 1.0m²/s)
    # Note: log means natural logarithm, not log10
    #
    # Note: natural logarithm of a quantity gives no meaning. We can drop the unit as long as we
    # use the scalar consistently.
    (p::ComplexQuantity) -> begin
        Δp = p - pos
        r = norm(Δp)
        massflowout ∙ log(r / m) / (2π)
    end
end


"""
    generate_complex_potential_vortex(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, vorticity= 1.0m²/s)

We find the velocity potential function of a vortex by realizing that
´´´
    u_θ = K / r
       where u_θ is tangential velocity, i.e. length per time in the tangential direction.
             K is vorticity
             Γ = K / 2π  is circulation
´´´
The velocity potential, ϕ, is the scalar valued function found by integrating
velocity along the velocity gradient. The sign and endpoint of the integration
can be defined as we want. With the limitation above:
´´´
XXX    u_θ  = ∇ϕ = δu_θ / δr
    ⇑
XXX    ϕ = ∫ K / r dr = K  · ∫ 1 / r dr = q / (2πr) · ln(r)
´´´
"""
function generate_complex_potential_vortex(; pos = ComplexQuantity((0.0, 0.0)m)::ComplexQuantity, vorticity = 1.0m²/s)
    (p::ComplexQuantity) -> begin
        Δp = p - pos
        Θ = angle(Δp)
        -vorticity ∙ Θ
    end
end



"""
quantities_at_pixels(function_complex_argument;
    physwidth = 20m,
    width_relative_screen = 2 / 3,
    height_relative_width = 1 / 3)

Return a matrix where each element contains
   pixel position |> physical position |> complex valued position |> function value
"""
function quantities_at_pixels(function_complex_argument;
    physwidth = 20m,
    width_relative_screen = 2 / 3,
    height_relative_width = 1 / 3)

    physheight = physwidth * height_relative_width

    # Discretize per pixel
    nx = round(Int, W * width_relative_screen)
    ny = round(Int, nx * height_relative_width)
    # Iterators for each pixel relative to the center, O
    pixiterx = (1:nx) .- (nx + 1)  / 2
    pixitery = (1:ny) .- (ny + 1) / 2

    # Iterators for each pixel mapped to physical dimension
    iterx = pixiterx * SCALEDIST
    itery = pixitery * -SCALEDIST

    # Matrix of physical position, one per pixel
    plane_coordinates = [(ix, iy) for iy = itery, ix = iterx]

    # Matrix of plot quantity, one per pixel
    map(qt -> function_complex_argument(ComplexQuantity(qt)), plane_coordinates)
end

absolute_scale() = ColorSchemes.linear_grey_10_95_c0_n256
complex_arg0_scale() = ColorSchemes.linear_ternary_red_0_50_c52_n256


"""
Returns (min, max) of norm(A), which often is the relevant
magnitude for complex numbers. But would hide information for
real-valued A.
"""
function lenient_min_max_complex(A::AbstractArray)
    magnitude = norm.(A)
    extrema(filter(!isnan, magnitude))
end

"""
    lenient_min_max(A)

Neglecting NaN and Inf values, return
- Minimum and maximum value out of real arrays.
- Minimum and maximum magnitude out of complex valued arrays.

"""
lenient_min_max(A::AbstractArray{<:RealQuantity}) = extrema(filter(x-> !isnan(x) && !isinf(x), A))
lenient_min_max(A::AbstractArray{<:Real}) = extrema(filter(x-> !isnan(x) && !isinf(x), A))
lenient_min_max(A) = lenient_min_max_complex(A)

normalizereal(mi, ma, A) = map(A) do x
    if isnan(x) || isinf(x)
        1.0
    else
        (x - mi) / (ma - mi)
    end
end

normalizecomplex(mi, ma, A) = map(A) do x
    if isnan(x) || isinf(x)
        1.0
    else
        (norm(x) - mi) / (ma - mi)
    end
end

function normalize(A::AbstractArray{<:RealQuantity})
    # Minimum and maximum value
    mi, ma = lenient_min_max(A)
    normalizereal(mi, ma, A)
end
function normalize(A::AbstractArray{<:Real})
    # Minimum and maximum value
    mi, ma = lenient_min_max(A)
    normalizereal(mi, ma, A)
end
function normalize(A)
    # Minimum and maximum magnitude
    mi, ma = lenient_min_max(A)
    normalizecomplex(mi, ma, A)
end


"""
    hue_from_complex_argument!(color_values, A)
    Changes the hue in collection color_values by roting based on complex arguments in A

Take a matrix of colors, modify elements of it by changing hue to be according to
the argument (polar angle) of a complex number

Ref. domain colouring, complex plane https://en.wikipedia.org/wiki/Domain_coloring
"""
function hue_from_complex_argument!(color_values, A)
    @assert length(A) == length(color_values)
    for i in 1:length(A) # Works for matrices also
        cqua = A[i]
        if !isnan(cqua) && !isinf(cqua)
            ang = angle(complex(cqua))rad
            col = color_values[i]
            if col != RGB(0.0, 0.0, 0.0)
                color_values[i] = rotate_hue(col, ang)
            end
        end
    end
end


"""
    color_matrix(qua::AbstractArray) -> RGBA

Map a collection of quantities to colors, transparent
pixels for NaN and Inf values.
"""
function color_matrix(qua::AbstractArray)
    # Boolean collection, valid elements which should be opaque
    valid_element = map(x-> isnan(x) || isinf(x) ? false : true, qua)

     # Map value or magnitude to [0.0, 1.0], invalid elements are 1.0
    norm_values = normalize(qua)

    # Map [0.0, 1.0] to perceived luminosity color map
    color_values = if eltype(qua) <: RealQuantity
        get(absolute_scale(), norm_values)
    else
        get(complex_arg0_scale(), norm_values)
    end
    # If input is complex
    if !(eltype(qua) <: RealQuantity)
        # Set hue from complex argument (angle)
        # while not changing perceived luminance
        hue_from_complex_argument!(color_values, qua)
    end

    # Add transparency for any invalid elements
    map(color_values, valid_element) do co, valid
        RGBA(ColorSchemes.red(co), ColorSchemes.green(co), ColorSchemes.blue(co), Float64(valid))
    end
end


"""
    pngimage(quantities)
Convert a matrix to a png image, one pixel per element
"""
function pngimage(quantities)
    tempfilename = joinpath(@__DIR__, "tempsketch.png")
    save(File(format"PNG", tempfilename), color_matrix(quantities))
    img = readpng(tempfilename);
    rm(tempfilename)
    img
end


"""
    draw_color_map(centerpoint::Point, quantities::Matrix)
    -> (upper left point, lower right point)

The color map is centered on p, one pixel per value in the matrix
"""
function draw_color_map(centerpoint::Point, quantities::Matrix)
    img = pngimage(quantities)
    # Put the png format picture on screen
    gsave() # Possible bug in placeimage, guard against it.
    placeimage(img, centerpoint; centered = true)
    grestore()
    pixheight, pixwidth = size(quantities)
    (centerpoint - (pixwidth / 2, pixheight / 2), centerpoint + (pixwidth / 2, pixheight / 2))
end
"""
    draw_real_legend(p::Point, min_quantity, max_quantity, legendvalues)
    -> text values (the function also draws the legend)

p is the upper left position for the legend
min_quantity and max_quantity is used for determining the color.
legendvalues is an iterable collection with the same units as min_quantity and max_quantity.

The legend is vertically aligned on the dots in legendvalues
"""
function draw_real_legend(p::Point, min_quantity, max_quantity, legendvalues)
    gsave()
    rowhe = row_height()
    for (i, v) in enumerate(legendvalues)
        dimless = (v - min_quantity) / (max_quantity - min_quantity)
        colo = get(absolute_scale(), dimless)
        sethue(colo)
        box(p + (0.0, i * rowhe), p + (EM, (i + 1 ) * rowhe ), :fillpreserve)
        strvalue = string(round(typeof(v), v, digits = 3))
    end
    grestore()
    text_table(p, Legend = legendvalues)
end

"""
    draw_complex_legend(p::Point, min_abs_quantity, max_abs_quantity, legendvalues)
    -> text values (the function also draws the legend)

p is the upper left position for the legend
min_abs_quantity and max_abs_quantity is used for determining the color.
legendvalues is an iterable collection with the same units.

The legend is vertically aligned on the dots in legendvalues
"""
function draw_complex_legend(p::Point, min_abs_quantity::T, max_abs_quantity::T, legendvalues::AbstractArray{T}) where {T<:RealQuantity}
    gsave()
    rowhe = row_height()
    # Legend magnitude
    for (i, v) in enumerate(legendvalues)
        dimless = (v - min_abs_quantity) / (max_abs_quantity - min_abs_quantity)
        upleft = p + (0.0, i * rowhe)
        downright = p + (EM, (i + 1 ) * rowhe)
        realcolo = get(complex_arg0_scale(), dimless)
        n = EM
        for (j, x) in enumerate(range(upleft[1], downright[1], length=n))
            sethue(rotate_hue(realcolo, (j - 1) * 360° / n))
            box(Point(x, upleft[2]), downright, :fillpreserve)
        end
        strvalue = string(round(typeof(v), v, digits = 3))
    end
    # Legend argument
    argumentwidth = 5EM
    upleft = p + (0.0, (length(legendvalues) + 3) * rowhe)
    downright = p + (argumentwidth, ((length(legendvalues) + 4)) * rowhe)
    realcolo = get(complex_arg0_scale(), 1.0)
    n =  argumentwidth
    for (j, x) in enumerate(range(upleft[1], downright[1], length=n))
        sethue(rotate_hue(realcolo, (j - 1) * 360° / n))
        box(Point(x, upleft[2]), downright, :fillpreserve)
    end
    grestore()
    strangles = "0°  120°  240°"
    draw_header(upleft + (0.0, - FS / 3 ), [pixelwidth(strangles)], [strangles])
    # Print magnitude text
    text_table(p, Legend = legendvalues)
end

## Automatic differentiation with units, using some internal functions for the legwork
## of stripping and adding units appropriately. The alternative would be to extending
## the automatic differentiation package to support complex numbers with units.
"Internal function generator used by 'generate_∇_R2_to_R2_unitless_function'"
function generate_R2_to_R2_unitless_function_from_Z_to_Z_function(fz, unitin_fz, unitout_fz)
    p::Vector -> fz(complex(p[1]∙unitin_fz, p[2]∙unitin_fz)) / unitout_fz
end

"Internal function generator used by 'generate_∇fz_Z_to_Z_from_fz'"
function generate_∇_R2_to_R2_unitless_function_from_Z_to_Z_function(fz, unitin_fz, unitout_fz)
    R2_to_R2_unitless_function = generate_R2_to_R2_unitless_function_from_Z_to_Z_function(fz, unitin_fz,  unitout_fz)
    p::Vector ->  gradient(R2_to_R2_unitless_function, p)
end
"""
    generate_∇fz_Z_to_Z_from_fz(fz, typein_fz::Type, typeout_fz::Type)

Using ForwardDiff, this function wraps the process of removing units, finding the gradient
and replacing the proper units.

Example:
typein_fz: typeof(a typical unitful quantity used to evaluate fz)
typeout_fz: typeof(a typical unitful quantity produced by fz)

The generated gradient function will have units 'units_in / units_out'.
"""
function generate_∇fz_Z_to_Z_from_fz(fz, typein_fz::Type, typeout_fz::Type)
    unitin = oneunit(typein_fz)
    unitout = oneunit(typeout_fz)
    ∇_R2_to_R2_unitless_function = generate_∇_R2_to_R2_unitless_function_from_Z_to_Z_function(fz, unitin, unitout)
    p::ComplexQuantity -> begin
        unitless_vector = [real(p/unitin), imag(p/unitin)]
        unitless_result = ∇_R2_to_R2_unitless_function(unitless_vector)
        quantity_vector = unitless_result∙unitout / unitin
        complex(quantity_vector[1], quantity_vector[2])
    end
end
