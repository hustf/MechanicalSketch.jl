import MechanicalSketch
import MechanicalSketch: empty_figure, sethue, O, WI, HE, EM, FS, finish,
       PALETTE, setfont, settext
import MechanicalSketch: dimension_aligned, noise
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity, @layer
import MechanicalSketch: draw_color_map, draw_real_legend, setscale_dist
import MechanicalSketch: lenient_min_max, normalize_datarange
import MechanicalSketch: ∙, ∇_rectangle, SA, SVector, rk4_steps!, convolute_pixel, draw_streamlines

let
empty_figure(joinpath(@__DIR__, "test_26.png"))


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
        cutoff = 0.5m/s);

setfont("DejaVu Sans", FS)
str = "Limiting the length of vectors rather than setting them to NaN is an improvement"
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)
setfont("Calibri", FS)


# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
using Interpolations
xs = range(-physwidth/2, stop = physwidth / 2, length = size(A)[2]);
ys = range(-height_relative_width * physwidth/2, stop = height_relative_width * physwidth / 2, length = size(A)[1]);
fxy_inter = interpolate((xs, ys), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());


# Cutoff
global const CUTOFF_26 = 0.5m/s
# Duration to trace the streamlines forward and back
global const DU_1 = 1.0s

# Upper figure centre coordinate
global const OU = O + (0.0, -0.25HE + EM)
include("test_functions_26.jl")

NO_2 = noisepic_2(A, physwidth, physheight)

# Show the noise image at the top figure
upleftpoint, lowrightpoint = draw_color_map(OU, NO_2)
ma = maximum(NO_2)
mi = minimum(NO_2)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)

draw_real_legend(legendpos, mi, ma, legendvalues)

# And make a function that interpolates between pixels:
nxy_inter = interpolate((xs, ys), transpose(NO_2)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)


# Centre of the bottom figure
OB = O + (0.0, + 0.25HE + 0.5EM )

# Number of sampling points along our streamline in each direction (effectively one less than this)
global const NS_2 = 10



# Step length (duration)
h = DU_1 / (NS_2 -1 ) * 2


@time M = convolute_image_2(xs, ys, fxy, nxy, h, CUTOFF_26) # 36.019 s (10 allocations: 4.85 MiB)
                                                  # 27.331 s (50803210 allocations: 2.64 GiB)
                                                  # 29.189352 seconds (30.08 M allocations: 642.345 MiB, 0.39% gc time)
                                                  # 30.222620 seconds (24.06 M allocations: 389.484 MiB, 0.19% gc time)
# Normalize colors to 0..1
M .-= minimum(M);
M ./= maximum(M);
upleftpoint, lowrightpoint = draw_color_map(OB, M )
mi, ma = lenient_min_max(A)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)
draw_real_legend(legendpos, mi, ma, legendvalues)

@layer begin
    sethue(PALETTE[1])
    draw_streamlines(OB, xs, ys, fxy, h)
end

dimension_aligned(OB + (-physwidth / 2, physheight / 2), OB + (physwidth / 2, physheight / 2))
dimension_aligned(OB, OB + p_vortex)
dimension_aligned(OB + (-physwidth / 2, - physheight / 2 ),  OB +  (-physwidth / 2, physheight / 2 ))

setfont("DejaVu Sans", FS)
str = "We adapt the noise's max wavelength to $CUTOFF_26 · $DU_1 = $(CUTOFF_26 * DU_1)."
settext(str, O + (-WI/2 + EM, EM) , markup = true)
str = "Next improvement will be a simple FIR filter."
settext(str, O + (-WI/2 + EM, 2 * EM) , markup = true)

setfont("Calibri", FS)

finish()
end