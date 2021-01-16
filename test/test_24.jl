import MechanicalSketch
import MechanicalSketch: color_with_luminance, sethue, O, WI, EM, FS, HE, finish, background,
       PALETTE, setfont, settext
import MechanicalSketch: dimension_aligned,line, circle, move, do_action
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand
import MechanicalSketch: draw_color_map, draw_complex_legend, set_scale_sketch, lenient_min_max
import MechanicalSketch: ∙, ∇_rectangle, empty_figure
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
# using BenchmarkTools

let
# This file is tested line by line using BenchmarkTools. Tests are commented out.

BACKCOLOR = color_with_luminance(PALETTE[8], 0.1);
include("test_functions_24.jl")
restart(BACKCOLOR)

# Plot the top figure, flow field from test_23.jl visualized with color for direction.
A = flowfield_23();
set_scale_sketch(PHYSWIDTH_23, round(Int, SCREEN_WIDTH_FRAC_23 * WI))
upleftpoint, lowrightpoint = draw_color_map(O + (0.0, -0.25HE + EM), A)
legendpos = lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23)
mi, ma = lenient_min_max(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
draw_complex_legend(legendpos, mi, ma, legendvalues)
    setfont("DejaVu Sans", FS)
    str = "Streamlines - 10 steps of 1.5 s with RK4 method, compared with Euler"
    settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)
setfont("Calibri", FS)

# Centre of the bottom figure
OB = O + (0.0, + 0.25HE + 0.5EM )

# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values.
# We start by defining increasing iterators for coordinates
xs = range(-PHYSWIDTH_23 / 2, stop = PHYSWIDTH_23 / 2, length = size(A)[2])
ys = range(-HEIGHT_RELATIVE_WIDTH_23 * PHYSWIDTH_23 / 2, stop = HEIGHT_RELATIVE_WIDTH_23 * PHYSWIDTH_23 / 2, length = size(A)[1])
# Note that the image matrix has maximum y in the first index, minimum in the last first index.
# Example image, small scale:
# (x, y ) ∈ ({-2, 0.1, 2}, { -1, 1})
# ... the coordinates would be stored as
# M_xy = [(-2,  1)m  ( 0.1,  1)m (2,  1)m;
#         (-2, -1)m  ( 0.1, -1)m (2, -1)m]
#
# ...but 'interpolations' expect coordinates on this form:
#  M_xy_i =  [ (-2,   -1)m   (-2,   1)m ;
#              (0.1,  -1)m   ( 0.1, 1)m ;
#              ( 2,   -1)m   ( 2,   1)m ]
#
# Let's say the values corresponding to M_xy were x * y / m²:
#    M = [ -2        0.1      2;
#           2       -0.1     -2]
#
#  Then 'interpolations' would expect
#     [  2     -2 ;
#       -0.1    0.1 ;
#       -2      2 ]
#  but we would actually want to [row, col] index into M in this way:
#
#     [ [ 2  , 1]   [ 1 , 1];
#       [ 2  , 2]   [ 1 , 2];
#       [ 2  , 3]   [ 1,  3]]
#  if we instead index into transpose(M):
#     [ [ 1  , 2]   [ 1 , 1];
#       [ 2  , 2]   [ 2 , 1];
#       [ 3  , 2]   [ 3,  1]]
#
# and generally
#  M_xy_test[ii, jj] == M_xy[i, j]
#  ii = end + 1 - j
#  jj = i
fxy_inter = interpolate((xs, ys), transpose(A)[ : , end:-1:1], Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());
fxy(0.0m, 0.0m)
fxy(0.0m, 0.0001m)
fxy(100.0m, 0.0001m)



circle(OB, 0.999m, :stroke) # origo
dimension_aligned(OB + (-PHYSWIDTH_23 / 2, PHYSHEIGHT_23 / 2), OB + (PHYSWIDTH_23 / 2, PHYSHEIGHT_23 / 2))
dimension_aligned(OB, OB + (0.0, 1.0)m)
dimension_aligned(OB + (-PHYSWIDTH_23 / 2, - PHYSHEIGHT_23 / 2 ),  OB +  (-PHYSWIDTH_23 / 2, PHYSHEIGHT_23 / 2 ))


setfont("DejaVu Sans", FS)
str = "RK4: 10.4μs vs Euler: 2.7μs"
settext(str, OB + (-WI/3 + EM, + 4EM), markup = true)
setfont("Calibri", FS)


# println("\nStarting point:")

sethue(PALETTE[1])
vx = collect(range(-0.0m, 0.0m, length = 10))
vy = collect(range(0.5m, 0.0m, length = 10))
# @btime
euler_forwardsteps_1!(fxy, vx, vy, 1.5s) # 2.800 μs (0 allocations: 0 bytes)

ex, ey = vx[end], vy[end]
prline_1(OB, vx, vy)
sethue(PALETTE[3])
vx = collect(range(-0.0m, 0.0m, length = 10))
vy = collect(range(0.5m, 0.0m, length = 10))
# @btime
rrk4_forwardsteps_1!(fxy, vx, vy, 1.5s) #10.899 μs (0 allocations: 0 bytes)

exrk, eyrk = vx[end], vy[end]
dimension_aligned(OB + (ex, ey),  OB + (exrk, eyrk))
prline_1(OB, vx, vy)


# println("\nInlining hint, inner functions:")
# @btime
euler_forwardsteps_2!(fxy, vx, vy, 1.5s) # 2.667 μs (0 allocations: 0 bytes)
# @btime
rrk4_forwardsteps_2!(fxy, vx, vy, 1.5s) #  10.300 μs (0 allocations: 0 bytes)


# println("\nNo assertions, inner functions:")
# @btime
euler_forwardsteps_3!(fxy, vx, vy, 1.5s) # 2.644 μs (0 allocations: 0 bytes)
# @btime
rrk4_forwardsteps_3!(fxy, vx, vy, 1.5s) # 10.399 μs (0 allocations: 0 bytes)


# println("\nNo outer function assertions:")

# @btime
euler_forwardsteps_4!(fxy, vx, vy, 1.5s) # 2.745 μs (0 allocations: 0 bytes)
# @btime
rrk4_forwardsteps_4!(fxy, vx, vy, 1.5s) # 11.4 μs (0 allocations: 0 bytes)

# println("Fastmath:")

# @btime
euler_forwardsteps_5!(fxy, vx, vy, 1.5s) # 2.745 μs (0 allocations: 0 bytes)
# @btime
rrk4_forwardsteps_5!(fxy, vx, vy, 1.5s) # 10.4 μs (0 allocations: 0 bytes)


# Neither fastmath nor inlining has any worthwhile effect.

setfont("DejaVu Sans", FS)
str = """
    Flowfield clamped at $CUTOFF_23.\n
    RK4 is four times slower than\nEuler for the same number of\nsteps.\n
    However, the Euler streamlines\n are visually inaccurate here.
    """
settext(str, O + (1.5m, -3.5m), markup = true)
setfont("Calibri", FS)


end # Let
finish()
set_scale_sketch()