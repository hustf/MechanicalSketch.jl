import MechanicalSketch
import MechanicalSketch: color_with_luminance, empty_figure, background, sethue, O, W, H, EM, FS, finish, Point,
       ColorSchemes.coolwarm, color_from_palette, setopacity
import MechanicalSketch: SCALEDIST,  dimension_aligned, settext, arrow, placeimage, readpng, setfont
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, @import_expand

if !@isdefined m²
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
end
import FileIO: @format_str, File, save

let
BACKCOLOR = color_with_luminance(coolwarm[50], 0.7);
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

# Plot size on screen
width_relative_screen = 2 / 3
height_relative_width = 1 / 3
# Physical dimension
physwidth = 20m
physheight = physwidth * height_relative_width

# Discretize per pixel
nx = round(Int, W * width_relative_screen)
ny = round(Int, nx * height_relative_width)

# Iterators for each pixel relative to the center, O
pixiterx = (1:nx) .- (nx + 1)  / 2
pixitery = (1:ny) .- (ny + 1) / 2

# Iterators for each pixel mapped to physical dimension
iterx = pixiterx * SCALEDIST
itery = pixitery * -SCALEDIST

# Matrix of physical position, one per pixel
plane_coordinates = [(ix, iy) for iy = itery, ix = iterx]

# Matrix of plot quantity, one per pixel
function_values = map(qt -> ϕ_source(ComplexQuantity(qt)), plane_coordinates)

# Scale plot quantity to [0,1>
minimum_value = minimum(function_values)
maximum_value = maximum(function_values)
range_value = maximum_value - minimum_value
normalized_values = (function_values.- minimum_value) / range_value

# Map normalized values to color, convert to png format
color_values = get(coolwarm, normalized_values);
tempfilename = joinpath(@__DIR__, "tempsketch.png")
save(File(format"PNG", tempfilename), color_values)
img = readpng(tempfilename);
rm(tempfilename)

# Put the png format picture on screen
placeimage(img, O; centered = true)

# Now add some decoration
sethue(color_with_luminance(coolwarm[8], 0.3))
dimension_aligned(O + (-physwidth / 2, physheight / 2), O + (physwidth / 2, physheight / 2))
dimension_aligned(O + p_source, O + (-7.5 + 1.0im)m)


begin
    p0 = (-7.5 + 1.0im)m
    p0text =  "Velocity potential ϕ<sub>source</sub> at " * string(p0)  * " is "
    value = ϕ_source(p0)
    p0text *= string(round(typeof(value ), value , digits = 3))
    arrow(O + p0 + (3EM, -EM), O + p0)
    settext(p0text, O + p0 + (3EM, -EM), markup=true)
end
begin
    p0 = (-3.0 - 2.0im)m
    p0text =  "ϕ<sub>source</sub>( " * string(p0)  * " ) = "
    value = ϕ_source(p0)
    p0text *= string(round(typeof(value), value , digits = 3))
    arrow(O + p0 + (3EM, -EM), O + p0)
    settext(p0text, O + p0 + (3EM, -EM), markup=true)
end

# Rendering latex from within Julia is cumbersome with installation.
# Using screen capture from other programs is easier.
formulafilename = joinpath(@__DIR__, "..", "resource", "source.png")
img = readpng(formulafilename);
placeimage(img, O + (4.0, -5.3)m)
sethue("black")
str = "q = $q_source"
setfont("Calibri", FS * 1.4)
settext(str, O + (4.0, -5.3)m + (3.3EM, 4.5EM), markup = true)
setfont("Calibri", FS)


finish()
end