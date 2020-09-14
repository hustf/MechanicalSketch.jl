module MechanicalSketch
import Luxor
import Luxor: Drawing,Turtle, Pencolor, Penwidth, Forward, Turn, HueShift, Point,
paper_sizes,
Tiler, Partition,
rescale,

finish, preview,
origin, rulers, background,

@png, @pdf, @svg, @eps, @draw,

newpath, closepath, newsubpath,

BezierPath, BezierPathSegment, bezier, bezier′, bezier′′, makebezierpath, drawbezierpath, bezierpathtopoly, beziertopoly, pathtobezierpaths,
bezierfrompoints, beziercurvature, bezierstroke, setbezierhandles, shiftbezierhandles, brush,

strokepath, fillpath,

rect, box, cropmarks,

setantialias, setline, setlinecap, setlinejoin, setdash,

move, rmove, line, rule, rline, arrow, arrowhead, dimension,

BoundingBox, boxwidth, boxheight, boxdiagonal, boxaspectratio,
boxtop, boxbottom, boxtopleft, boxtopcenter, boxtopright, boxmiddleleft,
boxmiddlecenter, boxmiddleright, boxbottomleft, boxbottomcenter,
boxbottomright,

intersectboundingboxes, boundingboxesintersect, pointcrossesboundingbox,

boxmap,

circle, circlepath, ellipse, hypotrochoid, epitrochoid, squircle, center3pts, curve,
arc, carc, arc2r, carc2r, isarcclockwise, arc2sagitta, carc2sagitta,
spiral, sector, intersection2circles,
intersection_line_circle, intersectionlinecircle, intersectioncirclecircle, ispointonline,
intersectlinepoly, polyintersect, polyintersections, circlepointtangent,
circletangent2circles, pointinverse,

ngon, ngonside, star, pie,
do_action, paint, paint_with_alpha, fillstroke,

Point, O, randompoint, randompointarray, midpoint, between, slope, intersectionlines,
pointlinedistance, getnearestpointonline, isinside,
perpendicular, crossproduct, dotproduct, distance,
prettypoly, polysmooth, polysplit, poly, simplify,  polycentroid,
polysortbyangle, polysortbydistance, offsetpoly, polyfit,

polyperimeter, polydistances, polyportion, polyremainder, nearestindex,
polyarea, polysample, insertvertices!,

polymove!, polyscale!, polyrotate!, polyreflect!,

@polar, polar,

strokepreserve, fillpreserve,
gsave, grestore, @layer,
scale, rotate, translate,
clip, clippreserve, clipreset,

getpath, getpathflat, pathtopoly,

fontface, fontsize, text, textpath, label,
textextents, textoutlines, textcurve, textcentred, textcentered, textright,
textcurvecentred, textcurvecentered,
textwrap, textlines, splittext, textbox, texttrack,

setcolor, setopacity, sethue, setgrey, setgray,
randomhue, randomcolor, @setcolor_str,
getmatrix, setmatrix, transform,

setfont, settext,

Blend, setblend, blend, addstop, blendadjust,
blendmatrix, rotationmatrix, scalingmatrix, translationmatrix,
cairotojuliamatrix, juliatocairomatrix, getrotation, getscale, gettranslation,

setmode, getmode,

GridHex, GridRect, nextgridpoint,

Table, highlightcells,

readpng, placeimage,

julialogo, juliacircles,

barchart,

mesh, setmesh, mask,

# animation
Movie, Scene, animate,

lineartween, easeinquad, easeoutquad, easeinoutquad, easeincubic, easeoutcubic,
easeinoutcubic, easeinquart, easeoutquart, easeinoutquart, easeinquint, easeoutquint,
easeinoutquint, easeinsine, easeoutsine, easeinoutsine, easeinexpo, easeoutexpo,
easeinoutexpo, easeincirc, easeoutcirc, easeinoutcirc, easingflat, easeinoutinversequad, easeinoutbezier,

# noise
noise, initnoise,

# experimental polygon functions
polyremovecollinearpoints, polytriangulate!, polytriangulate,
ispointinsidetriangle, ispolyclockwise, polyorientation,

# Turtle
Circle, Rectangle, Penup, Pendown, Message, Reposition, Orientation,
# misc
layoutgraph, image_as_matrix,

# internals and etc.

get_current_redvalue, get_current_greenvalue, get_current_bluevalue, weighted_color_mean,
Colors, parse

using MechanicalUnits
import MechanicalUnits.Unitfu: Power, oneunit, numtype
@import_expand kW # Don't use ~ since that would also import W, which we use elsewhere.

import LinearAlgebra: norm
# TODO: using, not import.
import REPL.TerminalMenus
import ColorSchemes
import ColorSchemes: getinverse, get
import ColorSchemes: HSL, HSLA, RGB, RGBA, HSV, LCHuv, LCHuvA
import Base: -, +, *, /, abs
import Colors: @colorant_str
import FileIO: @format_str, File, save
import ForwardDiff
import StaticArrays
import StaticArrays: SA, SVector
export Drawing, empty_figure,
    color_from_palette,
    color_with_luminance,
    PALETTE,
    dimension_aligned,
    SCALEDIST,
    Point
const CHORD_ZERO = 0.25
const FOIL_CHORD_POS = [0, 0.0125, 0.025, 0.05, 0.075, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1]
const FOIL_HALF_T = [0, 0.117, 0.1575, 0.2179, 0.2649, 0.3042, 0.4146, 0.4764, 0.5, 0.4816, 0.4149, 0.3159, 0.1989, 0.0811, 0.0306, 0]
const FOIL_CAMBER = [0, 0.0494, 0.0975, 0.19, 0.2775, 0.36, 0.64, 0.84, 0.96, 1, 0.96, 0.84, 0.64, 0.36, 0.19, 0]
const CHORD_LENGTH_DEFAULT = 1226mm
const THICKNESS_DEFAULT = 30.2mm
const CAMBER_DEFAULT = 18.15mm
const PALETTE = ColorSchemes.seaborn_bright


"""
Font size FS for Luxor, corresponding to Word points.
    fsize_pt = 11
    fsize_pt * ( 300 / 72 ) * 81 / (81 + 8)
"""
const FS = 9 * ( 300 / 72 )
"""
The unit EM, as in .css, corresponds to text + margins above and below
"""
const EM = Int(round(FS * 1.16))
"""
Text position is given from the baseline, but text extends below that.
"""
const TXTOFFV = Int(round(FS * 0.16))
"""
For line thickness, we are used to points.
"""
const PT = Int(round(EM / 12))
"""
We want to make high quality figures for A4 with 5 cm total margin. Width and height are
    a4_w_72dpi, _ = Luxor.paper_sizes["A4"]
    marginfrac = 50 / 210
    w_300f = a4_w_72dpi * (1 - marginfrac) * 300 / 72
    W = Int(round(w_300f))
    H = Int(round(w_300f * 2 / 3))
"""
const W = 1889
const H = 1259
global SCALEDIST = 20m / H
global SCALEVELOCITY = 70m/s / H
global SCALEFORCE = 20kN / H


# Note, this could be extended by modulus, such that points to the left of the screen
# would appear at right. But that could make some strange bugs too.
# CONSIDER generalize to quantity, let scale(x) do the transformation?
Point(x::T, y::T) where T<:Length = Point(x / SCALEDIST, y / scaledisty())
Point(x::T, y::T) where T<:Velocity = Point(x / SCALEVELOCITY , y / scalevelocityy())
Point(x::T, y::T) where T<:Force = Point(x / SCALEFORCE , y / scaleforcey())

const QuantityTuple = NTuple{2, <:Quantity}
const VelocityTuple = NTuple{2, <:Velocity}
const PositionTuple = NTuple{2, <: Length}
const ForceTuple = NTuple{2, <: Force}

# Vector subtraction and division using QuantityTuples
+(tup1::QuantityTuple, tup2::QuantityTuple) = .+(tup1, tup2)
-(tup1::QuantityTuple, tup2::QuantityTuple) = .-(tup1, tup2)

# QuantityTuples and scalar operations

*(x::Number, tup::QuantityTuple) = .*(x, tup)
*(tup::QuantityTuple, x::Number) = .*(tup, x)
/(x::Number, tup::QuantityTuple) = ./(x, tup)
/(tup::QuantityTuple, x::Number) = ./(tup, x)
-(tup::QuantityTuple) = .-(tup)

# extending points with quantity tuples - will work for e.g. 3.0m/mm = 3000.0
+(p1::Point, shift::NTuple{2, Quantity}) = p1 + Point(shift[1], shift[2])
-(p1::Point, shift::NTuple{2, Quantity}) = p1 - Point(shift[1], shift[2])
*(p1::Point, shift::NTuple{2, Quantity}) = p1 * Point(shift[1], shift[2])
/(p1::Point, shift::NTuple{2, Quantity}) = p1 / Point(shift[1], shift[2])
# extending points with mixed tuples
+(p1::Point, shift::Tuple{Quantity, Real}) = p1 + Point(shift[1], shift[2])
-(p1::Point, shift::Tuple{Quantity, Real}) = p1 - Point(shift[1], shift[2])
*(p1::Point, shift::Tuple{Quantity, Real}) = p1 * Point(shift[1], shift[2])
/(p1::Point, shift::Tuple{Quantity, Real}) = p1 / Point(shift[1], shift[2])
# opposite order
+(p1::Point, shift::Tuple{Real, Quantity}) = p1 + Point(shift[1], shift[2])
-(p1::Point, shift::Tuple{Real, Quantity}) = p1 - Point(shift[1], shift[2])
*(p1::Point, shift::Tuple{Real, Quantity}) = p1 * Point(shift[1], shift[2])
/(p1::Point, shift::Tuple{Real, Quantity}) = p1 / Point(shift[1], shift[2])

"""
Rotations given with units occur around the positive z axis, when y is up and x is to the right.
We don't dispatch on the dimension of angles, because the dimension is NonDims
"""
const Angle = Union{typeof(1.0°), typeof(1°), typeof(1.0rad), typeof(1rad)}
polyrotate!(f, ang::Angle) = polyrotate!(f, - ustrip( ang |> rad))


"""
    empty_figure(filename = "HiThere.png")

Establish a drawing sized for A4 300 dpi figures,
black on white figure, line width 3 pt  default.
"""
function empty_figure(filename = "HiThere.png")
    fig = Drawing(W, H, filename)
    # Font for the 'toy' text interface
    # (use e.g. JuliaMono for unicode symbols like ∈. There are no nice fonts for text AND math.
    fontface("Calibri")
    # 1 pt font size = 12/72 inch - by the book.
    # Letter spacing works differently here than in Word, so we adjust a little.
    fontsize(FS)
    setfont("Calibri", FS)
    background("white")
    sethue("black")
    setline(0.5PT)
    setdash("solid")
    # Origo at centre
    origin()
    # Scale and rotation - x right, y up ('z' is in.). And rotations may
    # clockwise. Just deal with it. Or stick to using dimensions.

    setmatrix([1, 0, 0, 1, W / 2, H / 2])
    fig
end


"""
    text(t, pt::Point, angle::T; kwargs) where {T <: Angle}
For angles with unit, use rotation around z axis.
"""
text(t, pt::Point, angle::T) where {T <: Angle} = text(t, pt; angle = - ustrip( angle |> rad))

include("scale.jl")
include("colors.jl")
include("dimension_aligned.jl")
include("foil.jl")
include("arrow.jl")
include("cart.jl")
include("rope.jl")
include("power.jl")
include("table.jl")
include("curves.jl")
include("flow.jl")
include("autodiff_unitfu.jl")

end # module
