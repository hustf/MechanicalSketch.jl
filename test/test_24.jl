import MechanicalSketch
import MechanicalSketch: color_with_lumin, sethue, O, WI, EM, FS, HE, finish, background
import MechanicalSketch: PALETTE, setfont, settext
import MechanicalSketch: dimension_aligned,line, circle, move, do_action
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, x_y_iterators_at_pixels
import MechanicalSketch: place_image, set_scale_sketch, lenient_min_max
import MechanicalSketch: ∙, ∇_rectangle, empty_figure, BinLegendVector, draw_legend
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
# using BenchmarkTools

let
# This file is tested line by line using BenchmarkTools. Tests are commented out.

BACKCOLOR = color_with_lumin(PALETTE[8], 10);
include("test_functions_24.jl")
restart(BACKCOLOR)

# Plot the top figure, flow field from test_23.jl visualized with color for direction.
A = flowfield_23();
set_scale_sketch(PHYSWIDTH_23, round(Int, SCREEN_WIDTH_FRAC_23 * WI))
mi, ma = lenient_min_max(A)
toplegend = BinLegendVector(;operand_example = first(A),
        max_magn_legend = ma, noof_magn_bins = 30, noof_ang_bins = 36,
        name = :Velocity)
colmat = toplegend.(A)
upleftpoint, lowrightpoint = place_image(O + (-2EM, -0.25HE + EM), colmat)
legendpos = lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23)
draw_legend(legendpos, toplegend)


# Centre of the bottom figure
OB = O + (-2EM, + 0.25HE + 0.5EM )

# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values.
# We start by defining iterators for coordinates

xs, ys = x_y_iterators_at_pixels(;physwidth = PHYSWIDTH_23, physheight = PHYSHEIGHT_23)
# Note that the image matrix has maximum y in the first index, minimum in the last first index.
ys = reverse(ys)
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
# TODO fix this, used to work with earlier versions.
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

end # Let
finish()
set_scale_sketch()