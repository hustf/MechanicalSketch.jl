#= ForwardDiff is removed from dependencies in this version.
import MechanicalSketch
import MechanicalSketch: empty_figure, background, sethue, O, WI, HE, EM, FS, finish
import MechanicalSketch: PALETTE, settext, setline
import MechanicalSketch: dimension_aligned, move, do_action, noise, rk4_steps!
import MechanicalSketch: generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer, x_y_iterators_at_pixels
import MechanicalSketch: place_image, draw_legend, set_scale_sketch
import MechanicalSketch: ∙, ∇_rectangle, SVector, normalize_datarange, draw_streamlines
import Interpolations: interpolate, Gridded, Linear, Flat, extrapolate
import MechanicalSketch: Greys_9, BinLegend, circle

let
empty_figure(filename = joinpath(@__DIR__, "test_27.png"));

if !@isdefined m²
    @import_expand(m, s)
end

include("test_functions_24.jl")
# Reuse the flow field from test_23.jl, a matrix of complex velocities with an element per pixel.
A = flowfield_23();


# Duration to trace the streamlines forward and back
global const DU_2 = 2.0s
include("test_functions_27.jl")
# Make a matrix containing one complex quantity per pixel.
# In test_23 we displayed this using colour for direction
# and luminosity for magnitude.
physwidth = 10.0m
height_relative_width = 0.4
physheight = physwidth * height_relative_width
screen_width_frac = 2 / 3
set_scale_sketch(physwidth, round(Int, screen_width_frac * WI))

str = "Noise has maximum wavelength $CUTOFF_23 · $DU_2 = $(CUTOFF_23 * DU_2). Experiments with noise spectrum."
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)

# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
fxy_inter = interpolate((xs, reverse(ys)), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());

global const OU_27 = O + (0.0, -0.25HE + EM)
global const NO_3 = noisepic_3(A, physheight, physwidth)
legend = BinLegend(;maxlegend = 1.0, noofbins = 128,
                       colorscheme = reverse(Greys_9), name = Symbol("Value{Float64}"))
upleftpoint, lowrightpoint = place_image(OU_27, legend.(NO_3))
draw_legend(lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23), legend)

# And make a function that interpolates between pixels:
nxy_inter = interpolate((xs, reverse(ys)), transpose(NO_3)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)


# Centre of the bottom figure
OB = O + (0.0, + 0.25HE + 0.5EM )

# Number of sampling points along our streamline in each direction (effectively one less than this)
global const NS_3 = 20

# Step length (duration)
h = DU_2 / (NS_3 -1 )

@time M = convolute_image_3(xs, reverse(ys), fxy, nxy, h, CUTOFF_23) # 36.019 s (10 allocations: 4.85 MiB)
                                                  # 58.803552 seconds (62.34 M allocations: 2.247 GiB, 0.56% gc time)
                                                  # 57.021068 seconds (62.33 M allocations: 2.247 GiB, 0.59% gc time)
                                                  # 59.596110 seconds (59.04 M allocations: 2.002 GiB, 0.58% gc time)

botlegend = BinLegend(;maxlegend = maximum(M), noofbins = 128,
                       colorscheme = reverse(Greys_9), name = Symbol("Value{Float64}"))
upleftpoint, lowrightpoint = place_image(OB, botlegend.(M) )
draw_legend(lowrightpoint + (EM, 0) + (0.0m, PHYSHEIGHT_23), botlegend)


@layer begin
    sethue(PALETTE[1])
    setline(8)
    draw_streamlines(OB, fxy)
    setline(1)
end

dimension_aligned(OB + (-physwidth / 2, physheight / 2), OB + (physwidth / 2, physheight / 2))
dimension_aligned(OB + (-physwidth / 2, - physheight / 2 ),  OB +  (-physwidth / 2, physheight / 2 ))


str = " "
settext(str, O + (-WI/2 + EM, EM) , markup = true)
str = "First implementation Finite Impulse Response filter, Blackman window."
settext(str, O + (-WI/2 + EM, 2 * EM) , markup = true)

finish()
set_scale_sketch()
nothing
end
=#