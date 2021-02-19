import MechanicalSketch
import MechanicalSketch: color_with_lumin, empty_figure, background, sethue
import MechanicalSketch: PALETTE, O, EM, FS, finish, x_y_iterators_at_pixels
import MechanicalSketch: dimension_aligned, settext, arrow, placeimage, readpng, setfont, gsave, grestore
import MechanicalSketch: ComplexQuantity, generate_complex_potential_source, @import_expand, string_polar_form
import MechanicalSketch: place_image, normalize_binwise, ∙, fontface, fontsize, @layer, text_table, rect
import MechanicalSketch: bin_bounds, draw_barplot, BinLegend, draw_legend, StaticArrays, ColorSchemes
import ColorSchemes:     PuOr_8, ColorScheme
import StaticArrays:     SVector

using Test

let
if !@isdefined s
    @import_expand m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
end

BACKCOLOR = color_with_lumin(PALETTE[8], 80)
function restart()
    empty_figure(joinpath(@__DIR__, "test_20.png"))
    background(BACKCOLOR)
    sethue(PALETTE[5])
end
restart()

"Source position"
p_source = (-7.5, 0.0)m |> ComplexQuantity

"Flow rate, 2d flow"
q_source = 1.0m²/s

"2d velocity potential function. Complex quantity domain, real quantity range."
ϕ_source = generate_complex_potential_source(; pos = p_source, massflowout = q_source)

physwidth = 20m
physheight = physwidth / 3
xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
A = [ϕ_source(complex(x, y)) for y in ys, x in xs] # 0.189560 seconds (1.17 M allocations: 34.138 MiB, 64.04% compilation time)

# Prepare a plot
ma = maximum(A)
mi = minimum(A)
binwidth3 = (ma - mi) / 3
legend3 = BinLegend(;maxlegend = ma, minlegend = mi, binwidth = binwidth3)
tfoo(x) = normalize_binwise(length(bin_bounds(legend3)), bin_bounds(legend3), x)

@test tfoo(mi) == 0
@test tfoo(ma) == 1
@test tfoo(mi + binwidth3) == 1 / 2
@test tfoo(mi + 2binwidth3) == 1
@test tfoo(ma) == 1
@test tfoo(mi + 0.5 * binwidth3) == 0
@test tfoo(mi + 1.5 * binwidth3) == 1 / 2
@test tfoo(mi + 2.5 * binwidth3) == 1

@test tfoo(mi + 0.6 * binwidth3) == 0.0
@test isnan(tfoo( mi + 3.001 * binwidth3))
@test isnan(tfoo(mi - 0.001 * binwidth3))
bibo = bin_bounds(legend3)
@test bibo[1] == mi
@test bibo[2] == mi + binwidth3
@test bibo[4] == ma
@test legend3(mi) != legend3.nan_color
@test legend3(ma) != legend3.nan_color
legend3.(bibo)
#=
begin # Visual test of bins
    restart()
    values = mi:binwidth3:ma
    samples = tfoo.(values)
    draw_barplot(O + (-12m, 3m), samples * 2EM, 6EM, firstcolor = PALETTE[1])
    text_table(O + (-6m, 4m), values = values, samples = samples) 
    values = mi:(binwidth3 / 10):ma
    samples = tfoo.(values)
    draw_barplot(O + (6m, 0m), samples * 2EM, 6EM , firstcolor = PALETTE[1])
    text_table(O + (0m, 9m), values = values, samples = samples)
    ul, br = draw_legend(O + (-6, -4)m, legend3)
    rect(ul, (br - ul)[1], (br - ul)[2], :stroke)
    finish()
end
=#
# Since we have values on both sides of zero, create a legend including zero.
binwidth = 0.1m²∙s⁻¹
binbounds = Tuple((-5:5)binwidth)
# Distinguishing between positive and negative is often important. We 
# truncate a colorscheme to make our own.
cv(x) = get(PuOr_8, x, :clamp)
nomiddle = [[cv(x) for x in range(0, 0.3, length = 10)];
        [cv(1 - x) for x in range(0.3, 0, length = 11)]]
nomiddlescheme = ColorScheme(SVector(nomiddle...), "testschemes", "emphasize plus / minus")
legend = BinLegend(;binbounds, colorscheme = nomiddlescheme, name = :Potential)

colormat = legend.(A);
ulp, lrp = place_image(O, colormat);

# Top left of legend
legendpos = O + ((lrp[1] - ulp[1]) / 2 + EM, (ulp[2] - lrp[2]) / 2)
@layer begin
    # Font for the 'toy' text interface
    fontface("Calibri")
    # 1 pt font size = 12/72 inch - by the book.
    # Letter spacing works differently here than in Word, so we adjust a little.
    fontsize(FS)
    draw_legend(legendpos, legend)
end


# Add some decoration to the plot
sethue(color_with_lumin(PALETTE[5], 30))
dimension_aligned(O + (-physwidth / 2, physheight / 2), O + (physwidth / 2, physheight / 2))
dimension_aligned(O + p_source, O + (-7.5 + 1.0im)m)
dimension_aligned(O + (-physwidth / 2, - physheight / 2 ),  O +  (-physwidth / 2, physheight / 2 ))

begin # Leader for a value
    p0 = (-7.5 + 1.0im)m
    arrow(O + p0 + (2EM, -EM), O + p0)
    fvalue = ϕ_source(p0)
    strvalue = string(round(typeof(fvalue ), fvalue , digits = 3))
    strargument = string(p0)
    txt =  "ϕ<sub>source</sub>(" * strargument * ") = " * strvalue
    settext(txt, O + p0 + (3EM, -EM), markup=true)
end
begin # Leader for another value
    p0 = (-4.0 - 2.0im)m
    arrow(O + p0 + (2EM, -EM), O + p0)
    fvalue = ϕ_source(p0)
    strargument = string_polar_form(p0)
    strvalue = string(round(typeof(fvalue), fvalue , digits = 3))
    txt =  "ϕ<sub>source</sub>( " * strargument * " ) = " * strvalue
    settext(txt, O + p0 + (3EM, -EM), markup=true)
end
setfont("DejaVu Sans", FS)
str = "ϕ: Z ↣ R   is the <b>velocity potential</b>. \r            It exists for irrotational flows only. This source is an example."
settext(str, O + (-0.7 * physwidth, -6.3m), markup = true)
setfont("Calibri", FS)

# Add an image of the source formula, and source strength value
formulafilename = joinpath(@__DIR__, "..", "resource", "source.png")
img = readpng(formulafilename);
gsave()
placeimage(img, O + (4.0, -6.3)m)
grestore()
str = "q = $q_source"
settext(str, O + (4.0, -6.3)m + (3.3EM, 4.5EM), markup = true)

finish()
end # let
