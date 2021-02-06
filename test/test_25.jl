import MechanicalSketch
import MechanicalSketch: color_with_luminance, O, WI, HE, EM, FS, finish,
       PALETTE, setfont, settext, background, empty_figure, sethue, move, do_action
import MechanicalSketch: dimension_aligned, noise, line
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, x_y_iterators_at_pixels
import MechanicalSketch: draw_color_map, draw_real_legend, set_scale_sketch
import MechanicalSketch: ∙, ∇_rectangle, SVector, normalize_datarange
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
#using BenchmarkTools

let
BACKCOLOR = color_with_luminance(PALETTE[7], 0.1)

include("test_functions_25.jl")
restart_25(BACKCOLOR)
include("test_functions_24.jl")

# Reuse the flow field from test_23.jl, a matrix of complex velocities with an element per pixel.
A = flowfield_23();
set_scale_sketch(PHYSWIDTH_23, round(Int, SCREEN_WIDTH_FRAC_23 * WI))

setfont("DejaVu Sans", FS)
str = "This noise image has three different spectra.\nA noise frequency along a line is 1 / (wavelength [m])."
settext(str, O + (-WI/2 + 1.25EM, -0.5HE + 2EM), markup = true)
setfont("Calibri", FS)

# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
xs, ys = x_y_iterators_at_pixels(;physwidth = PHYSWIDTH_23, physheight = PHYSHEIGHT_23)
fxy_inter = interpolate((xs, reverse(ys)), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());

# Generate a noise image for experimentation. Display it at the top of the figure.
NO_1 = noisepic_1(A);
# Upper figure centre coordinate
OU_25 = O + (0.0, -0.25HE + EM)
# Show the noise image
upleftpoint, lowrightpoint = draw_color_map(OU_25, NO_1)
ma = maximum(NO_1)
mi = minimum(NO_1)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23 )

draw_real_legend(legendpos, mi, ma, legendvalues)

# And make a function that interpolates between pixels:
nxy_inter = interpolate((xs, reverse(ys)), transpose(NO_1)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)



# Centre of the bottom figure
OB_25 = O + (0.0, + 0.25HE + 0.75EM )


# Duration to trace the streamlines forward and back
DU_25 = 2.0s

# Number of sampling points along our streamline in each direction (the number of steps is one less )
global const NS_1 = 10


# Step length (duration)
h = DU_25 / (NS_1 -1 )

@time M = convolute_image_1(xs, reverse(ys), fxy, nxy, h, CUTOFF_23) # 29.268005 seconds (1.28 M allocations: 71.975 MiB, 1.78% compilation time)

# Normalize to 0..1
M = normalize_datarange(M)
upleftpoint, lowrightpoint = draw_color_map(OB_25, M )
draw_streamlines_1(OB_25, xs, ys, fxy, h) # include coordinates for center in call

dimension_aligned(OB_25 + (-PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2), OB_25 + (PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2))
dimension_aligned(OB_25, OB_25 + complex(0.0, 1.0)m)
dimension_aligned(OB_25 + (-PHYSWIDTH_23  / 2, - PHYSHEIGHT_23  / 2 ),  OB_25 +  (-PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2 ))


setfont("DejaVu Sans", FS)
str = "The grey image below is a first attempt at LIC  flow visualization.\nStreamlines cover $DU_25 forward (blue) and back."
settext(str, O + (-WI / 2 + EM, + 1.8EM ), markup = true)
setfont("Calibri", FS)

finish()
end # begin