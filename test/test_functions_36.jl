# This should also demonstrate traits, which is
# harder to understand than simple dispatch, but allows for more re-use of code.

# TO DO: Don't change the type when State changes.
# Just use two arguments. The first can be a type. 
abstract type AbstractThing end 
abstract type Kind end
abstract type State end
Base.@kwdef mutable struct Thing{K<:Kind, S<:State} <: AbstractThing
    x::Length = 0.0m   # Could potentially be a function of 'time' between animation panels.
    y::Length = 0.0m
    w::Length = (1 + √5)m / 2
    h::Length = 1.0m
    name
end
Thing{K}(;kwargs...) where {K<:Kind} = Thing{K}{Transit}(;kwargs...)
struct Section <: Kind end # We may add more types later, imperative style...
struct Mounted <: State end
struct Transit <: State end


height(th::Thing{K, S}) where {K, S} = th.h

Base.@kwdef mutable struct Container{K<:Kind, V <: AbstractVector} <: AbstractThing
    children::Vector = Vector()::V # Intending AbstractThings here
    x::Length = 0.0∙m
    y::Length = 0.0∙m
    w::Length = (1 + √5)m      # Intending masking width
    h::Length = 2.0m           # Intending masking height
    name=""
end
Container{K}(;kwargs...) where {K<:Kind} = Container{K}{Vector}(;kwargs...)

# Interfaces: Use Container.children directly....
Base.length(c::Container{K, V}) where {K, V} = length(c.children)
Base.getindex(c::Container{K, V}, I) where {K, V} = c.children[I]
Base.size(c::Container{K, V}) where {K, V} = length(c.children)
Base.IndexStyle(::Type{<:Container}) = IndexLinear()
Base.iterate(c::Container{K, V}) where {K, V} = isempty(c.children) ? nothing : (c.children[1], 2)
function Base.iterate(c::Container{K, V}, s) where {K, V}
    if (s > length(c))
        return
    end
    return c[s], s + 1
end
Base.lastindex(c::Container{K, V}) where {K, V} = lastindex(c.children)

putin!(c::Container{K, V}, t) where {K, V} = push!(c.children, t)
pop!(c::Container{K, V}) where {K, V} = pop!(c.children)

moveto_x!(th, x) = th.x = x
moveto_y!(th, y) = th.y = y
moveto!(th, x, y) = moveto_x!(th, x), moveto_y!(th, y)
moveto!(th, pt) = moveto!(th, pt.x * scale_pt_to_unit(m), -pt.y * scale_pt_to_unit(m))

move_x!(th, Δx) = th.x += Δx
move_y!(th, Δy) = th.y += Δy
move!(th, Δx, Δy) = move_x!(th, Δx), move_y!(th, Δy)
move!(th, Δpt) = move!(th, Δpt.x * scale_pt_to_unit(m), -Δpt.y * scale_pt_to_unit(m))

set_w!(th, w) = th.w = w
set_h!(th, h) = th.h = h
set_width_height!(th, w, h) = set_w!(th, w), set_h!(th, h)
set_width_height!(th, pt) = set_width_height!(th, pt.x * scale_pt_to_unit(m), -pt.y * scale_pt_to_unit(m))

struct Panel <: Kind end
height(c::Container{Panel, V}) where V = c.h
function drawit(c::Container{Panel, V}) where V
    name = c.name
    x, y, w, h = promote(c.x, c.y, c.w, c.h)
    Δx = w / 2
    @layer begin
        translate(Point(x, y))
        # text box, pixels
        tw = 1.2 * pixelwidth(name)
        # pixel vertical offset, +y is down
        ph = -scale_to_pt(h) 
        #
        p1 = Point(-Δx, 0h)
        p2 = Point(-Δx, h)
        p3 = Point(Δx, h)
        tpxr = p3.x - EM
        tpx = tpxr - tw / 2
        tpxl = max(p2.x + EM, tpx - tw / 2)
        p2_1 = Point(tpxl, ph)
        p2_2 = Point(tpx, ph)
        p2_3 = Point(tpxr, ph)
        p4 = Point(Δx, 0h)
        @layer begin
            sethue(PALETTE[10])
            brush(p1, p2)
            brush(p2, p2_1)
            brush(p2_3, p3)
            brush(p3, p4)
            brush(p4, p1)
            text(name, p2_2; valign = :center, halign = :center)
        end
        # add mask
         box(p2 + (5, 5), p4 + (-5, -5), :clip; vertices=false)
        # draw children, with this layer's origo
        for thing in c
            drawit(thing)
        end
    end
end


struct Ground <: Kind end
height(c::Container{Ground, V}) where V = 0.0m
function drawit(c::Container{Ground, V}) where V
    name = c.name
    x, y, w, h = promote(c.x, c.y, c.w, c.h)
    Δx = w / 2
    pw = scale_to_pt(w)
    @layer begin
        translate(Point(x, y))
        ptul = Point(-Δx, 0h)
        groundbox = BoundingBox(rect(ptul, w, h))
        @layer begin
            grc = PALETTE[6]
            grcb = color_with_lumin(PALETTE[6], 10)
            gradient = mesh(
                box(groundbox, vertices=true),
                [grcb, grc, grc, grcb])
            setmesh(gradient)
            paint()
            sethue(grc)
            hatchx = range(0, pw, step = 20)
            ptx = [ptul+ (x, 0.0) for x in hatchx]
            rule.(ptx, π / 4; boundingbox = groundbox)
        end
        # draw children, with this layer's origo
        for thing in c
            drawit(thing)
        end
    end
end

function drawname(pt, name, maxwidth)
    snam = string(name)
    width = pixelwidth(snam)
    if width < scale_to_pt(maxwidth)
        height = row_height()
        draw_background(pt - (width / 2, height / 2), width, height)
        sethue(PALETTE[6])
        text(snam, pt, halign=:center, valign = :middle)
    end
end
struct Stack <: Kind end
height(c::Container{Stack, V}) where V = sum(height, c; init = 0.0m)
"""
putin!(c::Container{Stack}, th::Thing{K}) where K <: Kind

Much like 'push!', but swithes the original object with a 'Mounted' type.
"""
function putin!(c::Container{Stack, V}, th::Thing{K}) where {V, K <: Kind}
    t = Thing{K}{Mounted}(;name = th.name, 
                           x = th.x,
                           y = height(c),
                           w = th.w, 
                           h = th.h)
    push!(c.children, t)
end


function drawit(c::Container{Stack, V}) where V
    name = c.name
    x, y = promote(c.x, c.y)
    @layer begin
        translate(Point(x, y))
        drawname(Point(0, EM), name, 50EM)
        for thing in c
            drawit(thing)
        end
    end
end

function drawit(th::Thing{Section, S}) where S<:State
    name = th.name
    x, y, w, h = promote(th.x, th.y, th.w, th.h)
    @layer begin
        pt = Point(x, y)  + (x, y)
        center = Point(x, y + h / 2)
        pt0 = pt - ( w / 2, 0.0w )
        pt1 = pt + ( w / 2, 0.0w )
        ble = cylinderblend(pt0, pt1, S)
        setblend(ble)
        squircle(center, w / 2, h / 2; rt = 0.15, action = :fill)
        drawname(center, name, w)
    end
end

function cylinderblend(pt0, pt1, ::Type{T}) where T
    ble = blend(pt0, pt1)
    # Blend colours
    vc = (parse(RGBA, s) for s in ("gold4", "gold3", "gold2", "gold1"))
    c1, c2, c3, c4 = if T <: Mounted
        vc
    else
        map(c-> color_with_saturation.(c, 0.01), vc)
    end
    bcs = [c1, c2, c3, c4, c3, c2, c1]
    # Corresponding path length ∈(0..1)
    bls  = 0.5 .+ 0.5 .* [-1, -0.71, 0.5, 0, 0.5, 0.71, 1]
    for (l, c) in zip(bls, bcs)
        addstop(ble, l, c)
    end
    ble
end
