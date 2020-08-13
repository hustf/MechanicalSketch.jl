import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, EM, finish, Point,
       ColorSchemes.coolwarm, color_from_palette, setopacity
import MechanicalSketch: SCALEDIST,  scale, dimension_aligned, label, arrow
import MechanicalSketch: ComplexQuantity, QuantityTuple, generate_complex_potential_source, @import_expand,
    placeimage, readpng
if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end
import FileIO: @format_str, File, save

let
BACKCOLOR = color_with_luminance(coolwarm[8], 0.7);
function restart()
    empty_figure(joinpath(@__DIR__, "test_20.png"))
    background(BACKCOLOR)
    sethue(coolwarm[1])
end
restart()

"Source position"
p_source = (-7.5, 0.0)m |> ComplexQuantity

"Flow rate, 2d flow"
q_source = 1.0m²/s

"2d velocity potential as a function of complex position"
ϕ_source = generate_complex_potential_source(; pos = p_source, massflowout = q_source)

# Check for a position p0
p0 = (-5, 0)m |> ComplexQuantity
p0text =  "Velocity potiential ϕ_source at " * string(p0)  * " is "
p0text *= string(round(typeof(ϕ_source(p0)), ϕ_source(p0), digits = 3))



# Plot size on screen
screenrelwidth = 2 / 3
screenrelheight = (3 / 4) * screenrelwidth
# Physical dimension
physwidth = 20m
physheight = physwidth * screenrelheight / screenrelwidth

# Discretize per pixel
nx = round(Int, W * screenrelwidth)
ny = round(Int, H * screenrelheight)
# Iterators for each pixel relative to the center, O
pixiterx = (1:nx) .- (nx + 1)  / 2
pixitery = (1:ny) .- (ny + 1) / 2
# Iterators for each physical position
iterx = pixiterx * SCALEDIST
itery = pixitery * -SCALEDIST
# Matrix of physical position, one per pixel
posmat = [(ix, iy) for iy = itery, ix = iterx]
# Matrix of plot quantity, one per pixel
potential = map(qt -> ϕ_source(ComplexQuantity(qt)), posmat)
# Scale plot quantity to [0,1>
potential1 = minimum(potential)
potential0 = maximum(potential)
potentialrange = potential1- potential0
plotmat = (potential .- potential0) / potentialrange
matrgb = get(coolwarm, plotmat);
tempfilename = joinpath(@__DIR__, "tempsketch.png")
save(File(format"PNG", tempfilename), matrgb)
img = readpng(tempfilename);
rm(tempfilename)
placeimage(img, O; centered = true)
dimension_aligned(O, O + (1m,0m))
# Now add some labels
sethue(color_with_luminance(coolwarm[8], 0.3))
begin
    p0 = (-7.5 + 1.0im)m
    p0text =  "Velocity potiential ϕ_source at " * string(p0)  * " is "
    value = ϕ_source(p0)
    p0text *= string(round(typeof(value ), value , digits = 3))
    arrow(O + p0 + (3EM, -EM), O + p0)
    label(p0text, :NE, O + p0 + (3EM, -EM))
end
begin
    p0 = (-3.0 - 2.0im)m
    p0text =  "Velocity potiential ϕ_source at " * string(p0)  * " is "
    value = ϕ_source(p0)
    p0text *= string(round(typeof(value ), value , digits = 3))
    arrow(O + p0 + (3EM, -EM), O + p0)
    label(p0text, :NE, O + p0 + (3EM, -EM))
end
finish()
end