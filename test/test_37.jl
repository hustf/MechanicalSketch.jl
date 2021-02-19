import MechanicalSketch: PALETTE, color_with_lumin, empty_figure, @import_expand
# We only need this one function, but the package may be installed anyway, and contains
# the Mathjax js code.
import DocumenterEpub #: prerender_mathjax
import DocumenterEpub.NodeJS
#import DocumenterEpub.Documenter.Utilities.DOM.Node
import Latexify: @L_str, @latexify
import MechanicalSketch: PALETTE, color_with_lumin, empty_figure, @import_expand
import Latexify: @L_str, @latexify
#using NodeJS
#let

if !@isdefined m²
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end
empty_figure(joinpath(@__DIR__, "test_37.png"),
    backgroundcolor = color_with_lumin(PALETTE[4], 80));
include("test_functions_37.jl")
#l = @latexify f(x) = x^2
l = L"$f\left( x \right) = x^{2}$"
sl = String(l)
sv = prerender_mathjax(sl, true)
#sv = prerender_mathjax(sl, false)
#sv = prerender_mathjax(sd, false)
#sv = prerender_mathjax(sd, true)

#end # let

#finish()
