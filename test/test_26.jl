import MechanicalSketch
import MechanicalSketch: empty_figure, sethue, O, WI, HE, EM, FS, finish,
       PALETTE, setfont, settext, setline
import MechanicalSketch: dimension_aligned, noise, rk4_steps!
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer
import MechanicalSketch: draw_color_map, draw_real_legend, set_scale_sketch
import MechanicalSketch: lenient_min_max, normalize_datarange, x_y_iterators_at_pixels
import MechanicalSketch: ∙, ∇_rectangle, SA, SVector, draw_streamlines
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
let
empty_figure(joinpath(@__DIR__, "test_26.png"));
include("test_functions_24.jl")
include("test_functions_26.jl")
# Reuse the flow field from test_23.jl, a matrix of complex velocities with an element per pixel.
A = flowfield_23();
set_scale_sketch(PHYSWIDTH_23, round(Int, SCREEN_WIDTH_FRAC_23 * WI))


setfont("DejaVu Sans", FS)
str = "The grain size or spectrum is important to Line Integral Convolution (LIC) visualization"
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)
setfont("Calibri", FS)


# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
xs, ys = x_y_iterators_at_pixels(;physwidth = PHYSWIDTH_23, physheight = PHYSHEIGHT_23)
fxy_inter = interpolate((xs, reverse(ys)), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());

# Duration to trace the streamlines forward and back
global const DU_26 = 2.0s

# Upper figure centre coordinate
global const OU_26 = O + (0.0, -0.25HE + EM)

NO_2 = noisepic_2(A, PHYSWIDTH_23, PHYSHEIGHT_23)

# Show the noise image at the top figure
upleftpoint, lowrightpoint = draw_color_map(OU_26, NO_2)
ma = maximum(NO_2)
mi = minimum(NO_2)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23)

draw_real_legend(legendpos, mi, ma, legendvalues)

# And make a function that interpolates between pixels:
nxy_inter = interpolate((xs, reverse(ys)), transpose(NO_2)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)


# Centre of the bottom figure
global const OB_26 = O + (0.0, + 0.25HE + 0.5EM )

# Number of sampling points along our streamline in each direction (effectively one less than this)
global const NS_2 = 10



# Step length (duration)
h = DU_26 / (NS_2 -1 )


@time M = convolute_image_2(xs, reverse(ys), fxy, nxy, h, CUTOFF_23) # 36.019 s (10 allocations: 4.85 MiB)
                                                  # 27.331 s (50803210 allocations: 2.64 GiB)
                                                  # 29.189352 seconds (30.08 M allocations: 642.345 MiB, 0.39% gc time)
                                                  # 30.222620 seconds (24.06 M allocations: 389.484 MiB, 0.19% gc time)
                                                  # 29.965055 seconds (561.78 k allocations: 31.034 MiB, 0.05% gc time)
# Normalize colors to 0..1
upleftpoint, lowrightpoint = draw_color_map(OB_26, M )
mi, ma = lenient_min_max(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23)
draw_real_legend(legendpos, mi, ma, legendvalues)


@layer begin
    sethue(PALETTE[1])
    setline(8)
    draw_streamlines(OB_26, xs, ys, fxy, h)
    setline(1)
end

dimension_aligned(OB_26 + (-PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2), OB_26 + (PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2))
dimension_aligned(OB_26, OB_26 + complex(0.0, 1.0)m)
dimension_aligned(OB_26 + (-PHYSWIDTH_23  / 2, - PHYSHEIGHT_23  / 2 ),  OB_26 +  (-PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2 ))

setfont("DejaVu Sans", FS)
str = "The longest noise wavelength above is $CUTOFF_23 · $DU_26 = $(CUTOFF_23 * DU_26)"
settext(str, O + (-WI/2 + EM, EM) , markup = true)
str = "Shorter wavelength amplitudes vary. We still need to improve:"
settext(str, O + (-WI/2 + EM, 2 * EM) , markup = true)

setfont("Calibri", FS)

finish()
set_scale_sketch()
end