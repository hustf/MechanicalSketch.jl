"y is up, same scale as x"
scaledisty() = -SCALEDIST
"y is up, same scale as x"
scalevelocityy() = -SCALEVELOCITY
"y is up, same scale as x"
scaleforcey() = -SCALEFORCE


"""
    set_scale_sketch(s::T, pixels::Int) where {T <: Length}
    set_scale_sketch(s::T, pixels::Int) where {T <: Force}
    set_scale_sketch(s::T, pixels::Int) where {V <: Velocity}

To reset default 20m per screen height HE:
    set_scale_sketch(m), or any other length unit
    set_scale_sketch(:Length)

To reset to default 70 m/s per screen height in pixels HE:
    set_scale_sketch(m/s), or any other velocity unit
    set_scale_sketch(:Velocity)

To reset to default 20kN per screen height in pixels HE:
    set_scale_sketch(N), or any other force unit
    set_scale_sketch(:Force)

To reset all scale defaults:
    set_scale_sketch()
"""
function set_scale_sketch(x::FreeUnits)
    if 1x isa Length
        set_scale_sketch(:Length)
    elseif 1x isa Force
        set_scale_sketch(:Force)
    elseif 1x isa Velocity
        set_scale_sketch(:Velocity)
    else
        throw(DomainError(" set_scale_sketch with one argument only responds to units of length, force or velocity"))
    end
end
function set_scale_sketch(x::Symbol)
    if x == :Length
        set_scale_sketch(20m, HE)
    elseif x == :Force
        set_scale_sketch(20kN, HE)
    elseif x == :Velocity
        set_scale_sketch(70m/s, HE)
    else
        throw(DomainError(" set_scale_sketch with one argument only responds to (units of) Length, Force or Velocity"))
    end
end
set_scale_sketch(s::T, pixels::Int) where {T <: Length} = global SCALEDIST = s / pixels
set_scale_sketch(s::T, pixels::Int) where {T <: Force} = global SCALEFORCE = s / pixels
set_scale_sketch(s::T, pixels::Int) where {T <: Velocity} = global SCALEVELOCITY = s / pixels
function set_scale_sketch()
    set_scale_sketch(:Length)
    set_scale_sketch(:Force)
    set_scale_sketch(:Velocity)
end

"""
    get_scale_sketch(q::Quantity)

Return the number of pixels (or points, this may be ambiguous) corresponding to a given quantity.

    get_scale_sketch(u::FreeUnits)

Return the number of pixels (or points, this may be ambiguous) corresponding to one unit of u.

    To reset default 20m per screen height HE:
    set_scale_sketch()
    To reset default 20 kN per screen height HE:
    set_scale_sketch()
    To reset default 70 m/s per screen height HE:
    set_scale_sketch()
    70 m/s
"""
get_scale_sketch(q::Length) = upreferred(q / SCALEDIST)::Float64
get_scale_sketch(q::Velocity) = upreferred(q / SCALEVELOCITY)::Float64
get_scale_sketch(q::Force) = upreferred(q / SCALEFORCE)::Float64
get_scale_sketch(u::FreeUnits) = get_scale_sketch(1∙u)::Float64

"""
    set_figure_height(h::Int)

Updates global constant HE. Take care if functions are defined with closures (captured globals)
"""
function set_figure_height(h::Int)
    global HE = h
end
"""
    set_figure_width(w::Int)

Updates global constant WI. Take care if functions are defined with closures (captured globals)
"""
function set_figure_width(w::Int)
    global WI = w
end

"""
    x_y_iterators_at_pixels( physwidth = 10.0m, physheight = 4.0m, centered = true)
    ->(xs, ys)

Create position iterators with units corresponding to screen pixels.
    if centered = false:  (xs, ys)  >= 0m
    default: centered == true,  centered on (0.0m, 0.0m)

Use this to evaluate functions for visualization.
When looping over combinations, use ys as the inner loop for faster matrix lookup.
For image matrices, x vary over rows, y vary over columns.
"""
function x_y_iterators_at_pixels(;physwidth = 10.0m, physheight = 4.0m, centered = true)
    # Resolution for interpolation nodes
    nx = round(Int64, get_scale_sketch(physwidth))
    ny = round(Int64, get_scale_sketch(physheight))
    # Bounding box
    xmin = -centered * physwidth / 2
    xmax = (1 - centered / 2) * physwidth
    ymin = -centered * physheight / 2
    ymax = (1 - centered / 2) * physheight
    # Position iterators
    xs = range(xmin, xmax, length = nx)
    ys = range(ymax, ymin, length = ny) # Reversed order for faster matrix indexing.
    xs, ys
end


