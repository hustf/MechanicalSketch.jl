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
get_scale_sketch(q::Length) = upreferred(q / SCALEDIST)
get_scale_sketch(q::Velocity) = upreferred(q / SCALVELOCITY)
get_scale_sketch(q::Force) = upreferred(q / SCALEFORCE)
get_scale_sketch(u::FreeUnits) = get_scale_sketch(1∙u)

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