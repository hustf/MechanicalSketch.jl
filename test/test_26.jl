#= ForwardDiff is removed from dependencies in this version.
import MechanicalSketch
import MechanicalSketch: empty_figure, finish
import MechanicalSketch: PALETTE, settext, setline, WI, EM, HE, O
import MechanicalSketch: dimension_aligned, noise, rk4_steps!
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer, sethue
import MechanicalSketch: place_image, draw_legend, set_scale_sketch, BinLegend
import MechanicalSketch: normalize_datarange, x_y_iterators_at_pixels
import MechanicalSketch: ∙, ∇_rectangle, SVector, draw_streamlines
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
import MechanicalSketch: Greys_9
let
empty_figure(filename = joinpath(@__DIR__, "test_26.png"));
include("test_functions_24.jl")
include("test_functions_26.jl")
# Reuse the flow field from test_23.jl, a matrix of complex velocities with an element per pixel.
A = flowfield_23();
set_scale_sketch(PHYSWIDTH_23, round(Int, SCREEN_WIDTH_FRAC_23 * WI))


str = "The grain size or spectrum is important to Line Integral Convolution (LIC) visualization"
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)

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
legend = BinLegend(;maxlegend = 1.0, noofbins = 128,
                       colorscheme = reverse(Greys_9), name = Symbol("Value{Float64}"))
upleftpoint, lowrightpoint = place_image(OU_26, legend.(NO_2))
draw_legend(lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23), legend)

# And make a function that interpolates noise between pixels:
nxy_inter = interpolate((xs, reverse(ys)), transpose(NO_2)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)

# Centre of the bottom figure
global const OB_26 = O + (0.0, + 0.25HE + 0.5EM )

# Number of sampling points along our streamline in each direction (effectively one less than this)
global const NS_2 = 10

# Step length (duration)
h = DU_26 / (NS_2 -1 )

M = convolute_image_2(xs, reverse(ys), fxy, nxy, h, CUTOFF_23) # 36.019 s (10 allocations: 4.85 MiB)
                                                  # 27.331 s (50803210 allocations: 2.64 GiB)
                                                  # 29.189352 seconds (30.08 M allocations: 642.345 MiB, 0.39% gc time)
                                                  # 30.222620 seconds (24.06 M allocations: 389.484 MiB, 0.19% gc time)
                                                  # 29.965055 seconds (561.78 k allocations: 31.034 MiB, 0.05% gc time)

upleftpoint, lowrightpoint = place_image(OB_26, legend.(M) )
draw_legend(lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23), legend)


@layer begin
    sethue(PALETTE[1])
    setline(8)
    draw_streamlines(OB_26, fxy; h)
    setline(1)
end

@layer begin
    sethue(PALETTE[1])
    dimension_aligned(OB_26 + (-PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2), OB_26 + (PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2))
    dimension_aligned(OB_26, OB_26 + complex(0.0, 1.0)m)
    dimension_aligned(OB_26 + (-PHYSWIDTH_23  / 2, - PHYSHEIGHT_23  / 2 ),  OB_26 +  (-PHYSWIDTH_23  / 2, PHYSHEIGHT_23  / 2 ))
end
str = "The longest noise wavelength above is $CUTOFF_23 · $DU_26 = $(CUTOFF_23 * DU_26)"
settext(str, O + (-WI/2 + EM, EM) , markup = true)
str = "Shorter wavelength amplitudes vary. We still need to improve:"
settext(str, O + (-WI/2 + EM, 2 * EM) , markup = true)

finish()
set_scale_sketch()
end
=#