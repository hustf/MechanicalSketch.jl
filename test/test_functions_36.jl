# This should also demonstrate traits, which is
# harder to understand than simple dispatch, but allows for more re-use of code.
abstract type AbstractThing end 
abstract type Kind end
abstract type State end
Base.@kwdef mutable struct Thing{K<:Kind, S<:State} <: AbstractThing
    x::Length = 0.0m
    y::Length = 0.0m
    w::Length = (1 + √5)m / 2
    h::Length = 1.0m
    name
end

struct Section <: Kind end
struct Mounted <: State end
struct Transit <: State end
Thing{K}(;kwargs...) where {K<:Kind} = Thing{K}{Transit}(;kwargs...)

height(th::Thing{K, S}) where {K, S} = th.h

Base.@kwdef mutable struct Container{K<:Kind} <: AbstractThing    # TO DO type definition more like ColorScheme.
    children::Vector = Vector() # Intending AbstractThings here
    x::Length = 0.0∙m
    y::Length = 0.0∙m
    w::Length = (1 + √5)m      # Intending masking width
    h::Length = 2.0m           # Intending masking height
    name=""
end
children(c::Container) =  c.children
putin!(c::Container, t) = push!(children(c), t)
pop!(c::Container) = pop!(children(c))

moveto_x!(th, x) = th.x = x
moveto_y!(th, y) = th.y = y
moveto!(th, x, y) = moveto_x!(th, x), moveto_y!(th, y)
moveto!(th, pt) = moveto!(th, 1m * pt.x / get_scale_sketch(m), -1m * pt.y / get_scale_sketch(m))

move_x!(th, Δx) = th.x += Δx
move_y!(th, Δy) = th.y += Δy
move!(th, Δx, Δy) = move_x!(th, Δx), move_y!(th, Δy)
move!(th, Δpt) = move!(th, 1m * Δpt.x / get_scale_sketch(m), -1m * Δpt.y / get_scale_sketch(m))

set_w!(th, w) = th.w = w
set_h!(th, h) = th.h = h
set_width_height!(th, w, h) = set_w!(th, w), set_h!(th, h)
set_width_height!(th, pt) = set_width_height!(th, 1m * pt.x / get_scale_sketch(m), -1m * pt.y / get_scale_sketch(m))

struct Panel <: Kind end
height(c::Container{Panel}) = c.h
function drawit(c::Container{Panel})
    name = c.name
    x, y, w, h = promote(c.x, c.y, c.w, c.h)
    Δx = w / 2
    @layer begin
        translate(Point(x, y))
        # text box, pixels
        tw = 1.2 * pixelwidth(name)
        # pixel vertical offset, +y is down
        ph = -get_scale_sketch(h) 
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
        for thing in children(c)
            drawit(thing)
        end
    end
end


struct Ground <: Kind end
height(c::Container{Ground}) = 0.0m
function drawit(c::Container{Ground})
    name = c.name
    x, y, w, h = promote(c.x, c.y, c.w, c.h)
    Δx = w / 2
    pw = get_scale_sketch(w)
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
        for thing in children(c)
            drawit(thing)
        end
    end
end

function drawname(pt, name, maxwidth)
    snam = string(name)
    width = pixelwidth(snam)
    if width < get_scale_sketch(maxwidth)
        height = row_height()
        draw_background(pt - (width / 2, height / 2), width, height)
        sethue(PALETTE[6])
        text(snam, pt, halign=:center, valign = :middle)
    end
end
struct Stack <: Kind end
height(c::Container{Stack}) = sum(height, children(c); init = 0.0m)
"""
putin!(c::Container{Stack}, th::Thing{K}) where K <: Kind

Much like 'push!', but swithes the original object with a 'Mounted' type.
"""
function putin!(c::Container{Stack}, th::Thing{K}) where K <: Kind
    t = Thing{K}{Mounted}(;name = th.name, 
                           x = th.x,
                           y = height(c),
                           w = th.w, 
                           h = th.h)
    push!(children(c), t)
end


function drawit(c::Container{Stack})
    name = c.name
    x, y = promote(c.x, c.y)
    @layer begin
        translate(Point(x, y))
        drawname(Point(0, EM), name, 50EM)
        for thing in children(stack)
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

















#=
children(::Thing) = []
y_bot(thing) = thing.y
x_bot(thing) = thing.x
bot_point(thing) = Point(x_bot(thing), y_bot(thing))
isplaced(thing) = !isnan(x_bot(thing)) && !isnan(y_bot(thing))

y_top(thing) = y_bot(thing) + height(thing)
x_top(thing) = thing.x
isontop(tpth, btth) = x_bot(tpth) == x_bot(btth) && y_bot(tpth) == y_top(btth)

Base.@kwdef mutable struct Stack
    children::Vector{Thing} = Vector{Thing}()
    x::Length = ptgroundleft[1] * 1m / get_scale_sketch(m) + 1.5m
    y::Length = -ptgroundleft[2] * 1m / get_scale_sketch(m)
    name
end
children(stack) = stack.children

function isrooted(thing, stack)
    # this function will be used to find the height of a stack, so don't use that function here.
    if x_bot(thing) == x_bot(stack)
        if y_bot(thing) == y_bot(stack)
            return true
        end
    end
    for btth in children(stack)
        if btth != thing
            if isontop(thing, btth)
                return true
            end
        end
    end
    return false
end
=#


#=

#mountstate(::Type{<:MountedSection}) = Cylindrical()

drawit(::T, ::U) where T <: Thing  = drawit(cylindricity(T))

#=
height(stack) = sum(children(stack); init = 0.0m) do ch
    isrooted(ch, stack) ? height(ch) : 0.0m
end

function elevate_above!(thing, stack, Δy::Length)
    thing.y = y_bot(stack) + height(stack) + Δy
end

function slide_horizontal_offset!(thing, stack, Δx::Length)
    thing.x = x_top(stack) +  Δx
end
function moveit!(thing, Δx, Δy)
    thing.x += Δx
    thing.y += Δy
    foreach(c -> moveit!(c, Δx, Δy), children(thing))
end
function place_on_top!(thing, stack)
    thing.y = y_top(stack)
    thing.x = x_top(stack)
end

function place_beside!(thing, stack, Δx)
    thing.y = y_bot(stack) 
    thing.x = x_bot(stack) + Δx
end






Base.@kwdef mutable struct Panel <: SuchThings
    children::Vector{Any} = [Ground()]
    x::Length = -0.5WI_l  + 1.5m
    y::Length = -0.5HE_l + 1.5m
    framewidth::Length = 2.0m
end

function drawit(things; suffix = "")
    # Add lines to indicate 'cartoon box'
    @layer begin
        x = x_bot(things)
        Δx = things.framewidth / 2
        ybot = -HE_l / 2
        ytop = y_bot + minimum(1.0m, height(things))
        setdash("longdashed")
        line(Point(x + Δx, ybot), Point(x + Δx, ytop), :stroke)
        # Move origo to where I am
        translate(x, ybot)
        for thing in children(things)
            drawit(thing; suffix)
        end
    end
end

function drawit(stack; suffix = "", framewidth = 5m)
    btp = bot_point(stack)
    drawname(bot_point(stack) + (0, EM), stack.name * suffix, 50EM)
    # Add lines to indicate 'cartoon box'
    @layer begin
        x = x_bot(stack)
        Δx = framewidth / 2
        ybot = -1m * (HE / 2) / get_scale_sketch(m)
        ytop = y_bot(stack) + min(3m, height(stack))
        setdash("longdashed")
        line(Point(x + Δx, ybot), Point(x + Δx, ytop), :stroke)
    end
    for thing in children(stack)
        drawit(thing, isrooted(thing, stack))
    end
end


=#
=#