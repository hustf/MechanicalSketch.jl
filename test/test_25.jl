import MechanicalSketch
import MechanicalSketch: color_with_luminance, O, WI, HE, EM, FS, finish,
       PALETTE, setfont, settext, background, empty_figure, sethue, move, do_action
import MechanicalSketch: dimension_aligned, noise, line
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, generate_complex_potential_vortex
import MechanicalSketch: @import_expand, Quantity
import MechanicalSketch: draw_color_map, draw_real_legend, setscale_dist
import MechanicalSketch: ∙, ∇_rectangle, SVector, normalize_datarange
#using BenchmarkTools

let
BACKCOLOR = color_with_luminance(PALETTE[7], 0.1)

include("test_functions_25.jl")
restart_25(BACKCOLOR)
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
cutoff = 0.5m/s
A = begin
    unclamped = ∇_rectangle(ϕ,
        physwidth = physwidth,
        height_relative_width = height_relative_width);
    map(unclamped) do u
        hypot(u) > cutoff ? NaN∙u : u
    end
end;

setfont("DejaVu Sans", FS)
str = "Line integral convolution - RK4 streamlines, nine points each direction"
settext(str, O + (-WI/2 + EM, -0.5HE + 2EM), markup = true)
setfont("Calibri", FS)


# We are going to use the velocity vector field in a lot of calculations,
# and interpolate between the calculated pixel values
using Interpolations
xs = range(-physwidth/2, stop = physwidth / 2, length = size(A)[2]);
ys = range(-height_relative_width * physwidth/2, stop = height_relative_width * physwidth / 2, length = size(A)[1]);
fxy_inter = interpolate((xs, ys), map( cmplx -> (real(cmplx), imag(cmplx)), transpose(A)[ : , end:-1:1]), Gridded(Linear()));
fxy = extrapolate(fxy_inter, Flat());
fxy(0.0m, 0.0m)
fxy(0.0m, 0.0001m)
fxy(100.0m, 0.0001m)


# Generate a noise image for experimentation. Display it at the top of the figure.
NO_1 = noisepic_1(A)
# Upper figure centre coordinate
OU_25 = O + (0.0, -0.25HE + EM)
# Show the noise image
upleftpoint, lowrightpoint = draw_color_map(OU_25, NO_1)
ma = maximum(NO_1)
mi = minimum(NO_1)
ze = zero(typeof(ma))
legendvalues = reverse(sort([ma, (ma + mi) / 2, ze]))
legendpos = lowrightpoint + (EM, 0) + (0.0m, physheight)

draw_real_legend(legendpos, mi, ma, legendvalues)

# And make a function that interpolates between pixels:
nxy_inter = interpolate((xs, ys), transpose(NO_1)[ : , end:-1:1], Gridded(Linear()));
nxy = extrapolate(nxy_inter, Flat());
nxy(0.1m, 0.02m)



# Centre of the bottom figure
OB_25 = O + (0.0, + 0.25HE + 0.5EM )


# Duration to trace the streamlines forward and back
DU_25 = 1.0s

# Number of sampling points along our streamline in each direction (effectively one less than this)
global const NS_1 = 10


# Step length (duration)
h = DU_25 / (NS_1 -1 ) * 2

@time M = convolute_image_1(xs, ys, fxy, nxy, h, cutoff) # 36.019 s (10 allocations: 4.85 MiB)
                                                  # 27.331 s (50803210 allocations: 2.64 GiB)
                                                  # 30.744958 seconds (51.99 M allocations: 2.674 GiB, 1.58% gc time)
                                                  # 28.804882 seconds (1.96 M allocations: 88.599 MiB, 0.04% gc time)
                                                  # 28.647661 seconds (1.46 M allocations: 63.838 MiB)
# Normalize colors to 0..1
M .-= minimum(M);
M ./= maximum(M);
upleftpoint, lowrightpoint = draw_color_map(OB_25, M )
draw_streamlines_1(OB_25, xs, ys, fxy, h) # include coordinates for center in call

dimension_aligned(OB_25 + (-physwidth / 2, physheight / 2), OB_25 + (physwidth / 2, physheight / 2))
dimension_aligned(OB_25, OB_25 + p_vortex)
dimension_aligned(OB_25 + (-physwidth / 2, - physheight / 2 ),  OB_25 +  (-physwidth / 2, physheight / 2 ))


setfont("DejaVu Sans", FS)
str = "Note the darkening effect at sources and sinks, due to NaN regions "
settext(str, upleftpoint, markup = true)
setfont("Calibri", FS)

finish()
end # begin