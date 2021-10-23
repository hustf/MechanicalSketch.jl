module MechanicalSketch
import Luxor
import Luxor:
# Layout
Drawing, SVGimage,
paper_sizes,
Tiler, Partition,
rescale, currentdrawing,

finish, preview, snapshot,
origin, rulers, background,

@png, @pdf, @svg, @eps, @draw, @drawsvg, @savesvg,

# Turtle
Turtle, Pencolor, Penwidth, Forward, Turn, HueShift,

# Play

newpath, closepath, newsubpath,

BezierPath, BezierPathSegment, bezier, bezier′, bezier′′, makebezierpath, drawbezierpath, bezierpathtopoly, beziertopoly, pathtobezierpaths,
bezierfrompoints, beziercurvature, bezierstroke, setbezierhandles, beziersegmentangles,
shiftbezierhandles, brush,

strokepath, fillpath,

rect, box, cropmarks,

setantialias, setline, setlinecap, setlinejoin, setdash,

move, rmove, line, rule, rline, arrow, arrowhead, dimension, tickline,

BoundingBox, boxwidth, boxheight, boxdiagonal, boxaspectratio,
boxtop, boxbottom, boxtopleft, boxtopcenter, boxtopright, boxmiddleleft,
boxmiddlecenter, boxmiddleright, boxbottomleft, boxbottomcenter,
boxbottomright,

intersectboundingboxes, boundingboxesintersect, pointcrossesboundingbox,

BoxmapTile, boxmap,

circle, circlepath, crescent, ellipse, hypotrochoid, epitrochoid,
squircle, center3pts, curve,
arc, carc, arc2r, carc2r, isarcclockwise, arc2sagitta, carc2sagitta,
spiral, sector, intersection2circles,
intersection_line_circle, intersectionlinecircle, intersectioncirclecircle, ispointonline,
ispointonpoly,
intersectlinepoly, polyintersect, polyintersections, circlepointtangent,
circletangent2circles, pointinverse, pointcircletangent, circlecircleoutertangents,
circlecircleinnertangents, ellipseinquad,

ngon, ngonside, star, pie, polycross,
do_action, paint, paint_with_alpha, fillstroke, setstrokescale,
setblendextend, 

Point, O, randompoint, randompointarray, midpoint, between, slope, intersectionlines,
pointlinedistance, getnearestpointonline, isinside,
perpendicular, crossproduct, dotproduct, distance,
prettypoly, polysmooth, polysplit, poly, simplify,  polycentroid,
polysortbyangle, polysortbydistance, offsetpoly, polyfit,
currentpoint, hascurrentpoint, getworldposition, anglethreepoints,

polyperimeter, polydistances, polyportion, polyremainder, nearestindex,
polyarea, polysample, insertvertices!,

polymove!, polyscale!, polyrotate!, polyreflect!,

@polar, polar,

strokepreserve, fillpreserve,
gsave, grestore, @layer,
scale, rotate, translate, rotate_point_around_point,
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

readpng, readsvg, placeimage, svgstring,

julialogo, juliacircles,

barchart,

mesh, setmesh, add_mesh_patch, mask,

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
ispointinsidetriangle, ispolyclockwise, polyorientation, ispolyconvex,

# triangles
trianglecircumcenter, triangleincenter, trianglecenter, triangleorthocenter,

# Turtle
Circle, Rectangle, Penup, Pendown, Message, Reposition, Orientation,

# misc
image_as_matrix, @imagematrix, image_as_matrix!, @imagematrix!,

# experimental
layoutgraph, Style, applystyle,
tidysvg,

# internals and etc (not exported by Luxor).

get_current_redvalue, get_current_greenvalue, get_current_bluevalue, get_current_alpha,
weighted_color_mean, Colors, parse, comp1, comp2, comp3, comp4


using MechanicalUnits
import MechanicalUnits.Unitfu: Power, oneunit, numtype, AbstractQuantity
@import_expand kW # Don't use ~ since that would also import WI, which we use elsewhere.
import Latexify, LaTeXStrings, NodeJS
using Latexify: @latexify, latexify, @latexrecipe
using LaTeXStrings: LaTeXString, @L_str
"""
Rotations given with units occur around the positive z axis, when y is up and x is to the right.
We don't dispatch on the dimension of angles, because the dimension is NonDims (for good reason).
In the context of this package, defining Angle is considered harmless:
"""
const Angle = Union{typeof(1.0°), typeof(1°), typeof(1.0f0°), typeof(1.0rad), typeof(1rad), typeof(1.0f0*rad)}
# TODO move Angle to numeric types...
import ColorSchemes
using ColorSchemes: getinverse, get
using ColorSchemes: RGB, RGBA
using ColorSchemes: HSV, HSVA, HSL, HSLA, LCHab, LCHabA, LCHuv, LCHuvA # Cylindrical hue colorspaces
using ColorSchemes: isoluminant_cgo_70_c39_n256, leonardo, PuOr_8, Greys_9 # We also define ColSchemeNoMiddle in 'colors.jl'
import Base: -, +, *, /, hypot, product, show
using Colors: @colorant_str
using FileIO: @format_str, File, save
#import ForwardDiff
import StaticArrays
using StaticArrays: SA, SVector
#import Interpolations:   interpolate, Linear, Flat, extrapolate, Extrapolation, Gridded
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
WI is the pixel width of the figure. See HE and origo, O.

We want to make quality figures for A4 with 5 cm total margin. Width and height are
    a4_w_72dpi, _ = Luxor.paper_sizes["A4"]
    marginfrac = 50 / 210
    w_300f = a4_w_72dpi * (1 - marginfrac) * 300 / 72
    WI = Int(round(w_300f))
    HE = Int(round(w_300f * 2 / 3))

"""
global WI = 1889
"HE is the pixel height of the figure. See WI and orgo, O"
global HE = 1259
const SCALE = Dict{Symbol, Quantity{Float64}}()

Point(x::Quantity{T, D}, y::Quantity{S, D}) where {T, S, D} = Point(scale_to_pt(x), -scale_to_pt(y))

include("numeric_types.jl")


# Vector subtraction and division using QuantityTuples which don't need to have the exact same type.
+(tup1::QuantityTuple, tup2::QuantityTuple) = .+(tup1, tup2)
-(tup1::QuantityTuple, tup2::QuantityTuple) = .-(tup1, tup2)

# QuantityTuples and scalar operations

*(x::Number, tup::QuantityTuple) = .*(x, tup)
*(tup::QuantityTuple, x::Number) = .*(tup, x)
/(x::Number, tup::QuantityTuple) = ./(x, tup)
/(tup::QuantityTuple, x::Number) = ./(tup, x)
-(tup::QuantityTuple) = .-(tup)

# extending points with quantity tuples - will work for e.g. 3.0m/mm = 3000.0
+(p1::Point, shift::QuantityTuple) = p1 + Point(shift[1], shift[2])
-(p1::Point, shift::QuantityTuple) = p1 - Point(shift[1], shift[2])
*(p1::Point, shift::QuantityTuple) = p1 * Point(shift[1], shift[2])
/(p1::Point, shift::QuantityTuple) = p1 / Point(shift[1], shift[2])

# extending points with complex quantities
+(p1::Point, shift::ComplexQuantity) = p1 + QuantityTuple(shift)

# extend function in base with Point
hypot(p::Point) = hypot(p.x, p.y)
hypot(p::QuantityTuple) = hypot(p[1], p[2])

"""
    empty_figure(filename = "HiThere.png";
    backgroundcolor = color_with_lumin(PALETTE[8], 10),
    hue = PALETTE[8], height = missing, width = missing)

Establish a drawing sized for A4 300 dpi figures (WI, HE),
black on white figure, line width 3 pt  default.

Initial scale is set with set_scale_sketch()
    pt height = 20m
    pt height = 70m/s
    pt height = 20kN
"""
function empty_figure(;filename = :rec,
        backgroundcolor = color_with_lumin(PALETTE[8], 10),
        hue = PALETTE[8], height = missing, width = missing)
    fig = Drawing(WI, HE, filename)
    configure_mechanical(;backgroundcolor, hue, height, width)
    fig
end
"""
configure_mechanical(;
        backgroundcolor = color_with_lumin(PALETTE[8], 10),
        hue = PALETTE[8], height = missing, width = missing)

Establish a drawing sized for A4 300 dpi figures (WI, HE),
black on white figure, line width 3 pt  default.

Initial scale is set with set_scale_sketch()
pt height = 20m
pt height = 70m/s
pt height = 20kN
"""
function configure_mechanical(;
    backgroundcolor = color_with_lumin(PALETTE[8], 10),
    hue = PALETTE[8], height = missing, width = missing)
    # Font for the 'toy' text interface
    # (use e.g. JuliaMono for unicode symbols like ∈. There are no nice fonts for text AND math.
    fontface("Calibri")
    # 1 pt font size = 12/72 inch - by the book.
    # Letter spacing works differently here than in Word, so we adjust a little.
    fontsize(FS)
    setfont("Calibri", FS)
    background(backgroundcolor)
    sethue(hue)
    setline(0.5PT)
    setdash("solid")
    # Origo at centre
    origin()
    # Scale and rotation in pixels - x right, y up ('z' is in.). And rotations
    # are clockwise. Just deal with it. Or stick to using quantities. Functions taking
    # e.g. angles convert to ccw rotations.
    setmatrix([1, 0, 0, 1, WI / 2, HE / 2])
    @assert !ismissing(width) + !ismissing(height) < 2 "Width or height can be specified here."
    if ismissing(width) && ismissing(height)
        set_scale_sketch()
    elseif ismissing(width)
        set_scale_sketch(height, HE)
    else
        set_scale_sketch(width, WI)
    end
end

"""
    text(t, pt::Point, angle::T; kwargs) where {T <: Angle}
For angles with unit, use rotation around z axis.
"""
text(t, pt::Point, angle::T) where {T <: Angle} = text(t, pt; angle = - ustrip( angle |> rad))

polyrotate!(f, ang::Angle) = polyrotate!(f, - ustrip( ang |> rad))


include("lenient_num_analogue.jl")
include("scale.jl")
set_scale_sketch()
include("colors.jl")
include("dimension_aligned.jl")
include("foil.jl")
include("arrow.jl")
include("cart.jl")
include("rope.jl")
include("power.jl")
include("table.jl")
include("curves.jl")
include("labels.jl")
include("flow.jl")
include("runge_kutta.jl")
include("autodiff_unitfu.jl")
include("matrix_interpolation.jl")
include("streamline_convolution.jl")
include("matrix_drawing.jl")
include("colorlegends.jl")
include("colorlegends_vector.jl")
include("place_image.jl")
include("latex.jl")
include("chart.jl")
include("macros.jl")
end # module
