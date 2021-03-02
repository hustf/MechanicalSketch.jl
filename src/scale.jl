
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
set_scale_sketch(x::T, pixels::Int) where {T <: Length} =  push!(SCALE, :DISTANCE => x / pixels)
set_scale_sketch(x::T, pixels::Int) where {T <: Force} = push!(SCALE, :FORCE => x / pixels)
set_scale_sketch(x::T, pixels::Int) where {T <: Velocity} = push!(SCALE, :VELOCITY => x / pixels)
function set_scale_sketch()
    # Default scale
    set_scale_sketch(:Length)
    set_scale_sketch(:Force)
    set_scale_sketch(:Velocity)
end

"""
    scale_to_pt(q::Quantity)::Float64

Return the number of pixels (or pts, this may be ambiguous) corresponding to a given quantity.

    scale_to_pt(u::FreeUnits)::Float64

Return the number of pixels (or pts, this may be ambiguous) corresponding to one unit of u.

    To reset default 20m per screen height HE:
    set_scale_sketch()
    To reset default 20 kN per screen height HE:
    set_scale_sketch()
    To reset default 70 m/s per screen height HE:
    set_scale_sketch()
    70 m/s
"""
scale_to_pt(q::Length)::Float64 = upreferred(q / scale_pt_to_unit(oneunit(q)))
scale_to_pt(q::Velocity)::Float64 = upreferred(q / scale_pt_to_unit(oneunit(q)))
scale_to_pt(q::Force)::Float64 = upreferred(q / scale_pt_to_unit(oneunit(q)))
scale_to_pt(x)::Float64 = x


"""
    scale_pt_to_unit(u::FreeUnits)
"""
scale_pt_to_unit(u::FreeUnits) = scale_pt_to_unit(1∙u)
function scale_pt_to_unit(q::Length)
    @assert oneunit(q) == q "Ambiguous input. The scaling concerns one unit of the argument. Multiply by the number of units elsewhere."
    (q / unit(q)) ∙ unit(q)(SCALE[:DISTANCE])
end
function scale_pt_to_unit(q::Velocity)
    @assert oneunit(q) == q "Ambiguous input. The scaling concerns one unit of the argument. Multiply by the number of units elsewhere."
    (q / unit(q)) ∙ unit(q)(SCALE[:VELOCITY])
end
function scale_pt_to_unit(q::Force)
    @assert oneunit(q) == q "Ambiguous input. The scaling concerns one unit of the argument. Multiply by the number of units elsewhere."
    (q / unit(q)) ∙ unit(q)(SCALE[:FORCE])
end



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

function rotate(a::Angle)
    rotate(-ustrip( a |> rad))
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

NOTE! Replace this functionality with 'coords_spatial(img)' (google it)
"""
function x_y_iterators_at_pixels(;physwidth = 10.0m, physheight = 4.0m, centered = true)
    # Resolution for interpolation nodes
    nx = round(Int64, scale_to_pt(physwidth))
    ny = round(Int64, scale_to_pt(physheight))
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


