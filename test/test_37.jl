import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, finish
import MechanicalSketch: readsvg, place_image, settext, Quantity, ustrip, unit
import MechanicalSketch: Point, julialogo, PALETTE, color_with_lumin, @svg
import MechanicalSketch: background, color_with_alpha, scale, @layer, setopacity
import MechanicalSketch: rotate, translate
import Plots
import Plots: plot, plot!
using RecipesBase
if !@isdefined N
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand N
    @import_expand °
end
include("test_functions_37.jl")
empty_figure(joinpath(@__DIR__, "test_37.png"); 
      backgroundcolor = color_with_lumin(PALETTE[5], 90),
      hue = "black");
@layer begin
    scale(4)
    rotate(30°)
    translate(-WI /10, -HE / 8)
    background(color_with_alpha(PALETTE[5], 0))
    julialogo(;bodycolor = color_with_alpha(PALETTE[1], 0.1) )
end;
pt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
settext("<b>Plot recipe with svg style modifications</b>", pt, markup = true)
pt += (0, EM)

@warn "Plots is a heavy depencency, and conflicts with Luxor identifiers: 'text', 'brush', 'translate'. You may not want to install all these artifacts."
x = 0.0s:1.0s:5.0s
y = x .* N ./ s
unit_formatter(T, num) = string(eltype(T)(num))
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    u = unit(eltype(x))
    relevantkey = if RecipesBase.is_explicit(plotattributes, :letter)
        letter = plotattributes[:letter]
        Symbol(letter, :guide)
    else
        :guide
    end
    preguide = string(get(plotattributes, relevantkey, nothing))
    if preguide == "nothing"
        guide --> "[" * string(u) * "]"
    else
        letter = plotattributes[:letter]
        Symbol(letter, :formatter) --> x->unit_formatter(T,x)
    end
    return ustrip(x ./ u)
end

settext("Add units as guide label:", pt)
pl1 = plot(x, y);
ptul, ptlr = place_image_37(pt, pl1, height = 0.25HE)
pt += (0, 2EM + ptlr[2] - ptul[2])

settext("When guides are specified, use tick units:", pt)
pl2 = plot(x, y, xguide = "Time", yguide = "Force");
ptul, ptlr = place_image_37(pt, pl2, height = 0.25HE)
pt += (0, 2EM + ptlr[2] - ptul[2])

settext("This recipe treats axes independently:", pt)
pl2 = plot(x, y, xguide = "Time");
ptul, ptlr = place_image_37(pt, pl2, height = 0.25HE)
pt += (0, 2EM + ptlr[2] - ptul[2])

pt = O + (0, -HE / 4 + EM)
settext("No recipe change required for 3d:", pt)
n = 100
ts = range(0, stop = 8π, length = n)
x = ts * N .* map(cos, ts)
y = (0.1ts) * N .* map(sin, ts) .|> N
z = (1:n)s
pl3 = plot(x, y, z, zcolor = reverse(z./s), 
      m = (10, 0.8, :blues, Plots.stroke(0)), 
      leg = false, cbar = true, w = 5,
      zguide = "Time");
plot!(pl3, zeros(n), zeros(n), 1:n, w = 10);
ptul, ptlr = place_image_37(pt, pl3; width = 0.45WI)

finish()
