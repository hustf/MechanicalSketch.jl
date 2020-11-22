import MechanicalSketch
import MechanicalSketch: empty_figure, background, sethue, O, WI, HE, EM, FS, finish,
       PALETTE, setfont, settext, setline
import MechanicalSketch: dimension_aligned, move, do_action, noise
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer
import MechanicalSketch: quantities_at_pixels, draw_color_map, draw_real_legend, draw_complex_legend, setscale_dist, lenient_min_max
import MechanicalSketch: ∙, ∇_rectangle, SVector, diminishingtrace, convolute_pixel, rk4_steps!, normalize_datarange, draw_streamlines

let
empty_figure(joinpath(@__DIR__, "test_27.png"))


if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end

"Source position"
p_source = complex(3.0, 0.0)m
"Flow rate, 2d flow"
q_source = 1.0m²/s
"Vortex position"
p_vortex = complex(0.0, 1.0)m
"Vorticity, 2d flow"
K = 1.0m²/s / 2π

ϕ_vortex =  generate_complex_potential_vortex(; pos = p_vortex, vorticity = K)
ϕ_source = generate_complex_potential_source(; pos = p_source, massflowout = q_source)
ϕ_sink = generate_complex_potential_source(; pos = -p_source, massflowout = -q_source)

"""
    ϕ(p::ComplexQuantity)
    → Quantity
2d velocity potential function. Complex quantity domain, real quantity range.
"""
ϕ(p) = ϕ_vortex(p) + ϕ_source(p) + ϕ_sink(p)



# Cutoff
global const CUTOFF_27 = 0.5m/s
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
setscale_dist(physwidth / (screen_width_frac * WI))

A = ∇_rectangle(ϕ,
        physwidth = physwidth,
        height_relative_width = height_relative_width,
        cutoff = CUTOFF_27);

setfont("DejaVu Sans", FS)
str = "Noise has maximum wavelength $CUTOFF_27 · $DU_2 = $(CUTOFF_27 * DU_2). Experiments with noise spectrum."
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)
setfont("Calibri", FS)


# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
using Interpolations
xs = range(-physwidth/2, stop = physwidth / 2, length = size(A)[2]);
ys = range(-height_relative_width * physwidth/2, stop = height_relative_width * physwidth / 2, length = size(A)[1]);
fxy_inter = interpolate((xs, ys), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());



# Upper figure centre coordinate
global const OU_27 = O + (0.0, -0.25HE + EM)

global const NO_3 = noisepic_3(A, physheight, physwidth)
# Show the noise image at the top figure
upleftpoint, lowrightpoint = draw_color_map(OU_27, NO_3)
ma = maximum(NO_3)
mi = minimum(NO_3)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)

draw_real_legend(legendpos, mi, ma, legendvalues)

# And make a function that interpolates between pixels:
nxy_inter = interpolate((xs, ys), transpose(NO_3)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)


# Centre of the bottom figure
OB = O + (0.0, + 0.25HE + 0.5EM )

# Number of sampling points along our streamline in each direction (effectively one less than this)
global const NS_3 = 20

# Step length (duration)
h = DU_2 / (NS_3 -1 )


@time M = convolute_image_3(xs, ys, fxy, nxy, h, CUTOFF_27) # 36.019 s (10 allocations: 4.85 MiB)
                                                  # 58.803552 seconds (62.34 M allocations: 2.247 GiB, 0.56% gc time)
                                                  # 57.021068 seconds (62.33 M allocations: 2.247 GiB, 0.59% gc time)
                                                  # 59.596110 seconds (59.04 M allocations: 2.002 GiB, 0.58% gc time)
upleftpoint, lowrightpoint = draw_color_map(OB, M )
mi, ma = lenient_min_max(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)
draw_real_legend(legendpos, mi, ma, legendvalues)

@layer begin
    sethue(PALETTE[1])
    setline(8)
    draw_streamlines(OB, xs, ys, fxy, h)
    setline(1)
end

dimension_aligned(OB + (-physwidth / 2, physheight / 2), OB + (physwidth / 2, physheight / 2))
dimension_aligned(OB, OB + p_vortex)
dimension_aligned(OB + (-physwidth / 2, - physheight / 2 ),  OB +  (-physwidth / 2, physheight / 2 ))

setfont("DejaVu Sans", FS)
str = " "
settext(str, O + (-WI/2 + EM, EM) , markup = true)
str = "First implementation Finite Impulse Response filter, Blackman window."
settext(str, O + (-WI/2 + EM, 2 * EM) , markup = true)

setfont("Calibri", FS)

finish()
end