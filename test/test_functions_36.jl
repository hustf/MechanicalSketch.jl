module module_36
abstract type SuchThings end
struct Ground <: SuchThings end
struct StandingCylinder <: SuchThings end
struct PanelComic <: SuchThings end

# Todo: Since we're defining structs, put this in a module.
# Todo: Perhaps generalize SingleThing{T}. SuchThings -> AbstractThing.
# Consider traits, but that's a bit too much structure here.
Base.@kwdef mutable struct SingleThing # traits for properties perhaps? E.g. history.
    w::Length = (1 + √5)m / 2
    h::Length = 1.0m
    x::Length = NaN∙m
    y::Length = NaN∙m
    name
end
children(::SingleThing) = []
y_bot(thing) = thing.y
x_bot(thing) = thing.x
bot_point(thing) = Point(x_bot(thing), y_bot(thing))
isplaced(thing) = !isnan(x_bot(thing)) && !isnan(y_bot(thing))
height(thing::SingleThing) = thing.h
y_top(thing) = y_bot(thing) + height(thing)
x_top(thing) = thing.x
isontop(tpth, btth) = x_bot(tpth) == x_bot(btth) && y_bot(tpth) == y_top(btth)

Base.@kwdef mutable struct Stack
    children::Vector{SingleThing} = Vector{SingleThing}()
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
function drawit(th::SingleThing, isrooted)
    if isplaced(th)
        w, h, x, y, name = th.w, th.h, th.x, th.y, th.name
        @layer begin
            pt = Point(x, y)
            center = Point(x, y + h / 2)
            ptzero = pt - ( w / 2, 0w )
            ptone = pt + ( w / 2, 0w )
            ble = blend(ptzero, ptone)
            # Blend colours
            c1, c2, c3, c4 = if isrooted
                (parse(RGBA, s) for s in ("gold4", "gold3", "gold2", "gold1"))
            else
                (color_with_saturation(parse(RGBA, s), 0.01) for s in ("gold4", "gold3", "gold2", "gold1"))
            end
            bcs = [c1, c2, c3, c4, c3, c2, c1]
            # Corresponding path length ∈(0..1)
            bls  = 0.5 .+ 0.5 .* [-1, -0.71, 0.5, 0, 0.5, 0.71, 1]
            for (l, c) in zip(bls, bcs)
                addstop(ble, l, c)
            end
            setblend(ble)
            squircle(center, w / 2, h / 2; rt = 0.15, action = :fill)
            drawname(center, name, w)
        end
    end
end

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

function drawit(stack::Stack; suffix = "")
    btp = bot_point(stack)
    drawname(bot_point(stack) + (0, EM), stack.name * suffix, 50EM)
    for thing in children(stack)
        drawit(thing, isrooted(thing, stack))
    end
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


function drawit(::Ground)
    groundbox = BoundingBox(rect(ptgroundleft, WI, 2EM))
    @layer begin
        grc = PALETTE[6]
        grcb = color_with_lumin(PALETTE[6], 10)
        gradient = mesh(
            box(groundbox, vertices=true),
            [grcb, grc, grc, grcb])
        setmesh(gradient)
        paint()
        sethue(grc)
        hatchx = range(0, WI - 2EM, length = 100)
        ptx = [ptgroundleft + (x, 0.0) for x = hatchx]
        rule.(ptx, π / 4; boundingbox = groundbox)
    end
end
end