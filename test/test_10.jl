using MechanicalSketch
import MechanicalSketch: background, background, sethue, O, EM, finish,
    lumin, get_current_lumin, get_current_RGB, color_with_lumin,
    sethue, fontface, textpath, textextents, PT, fontsize, gsave, grestore,
    newpath, translate, m, text, fillpreserve, clip, rect, clipreset,
    setline
let
BACKCOLOR = color_with_lumin(PALETTE[2], 70);
function restart()
    empty_figure(joinpath(@__DIR__, "test_10.png"))
    background(BACKCOLOR)
    sethue(PALETTE[2])
end


# Electric power symbol, implemented in 'power.jl' `showpower`

# parameters
power = 3.0kW
maxpower = 5kW |> typeof(power)
fractionpower = power / maxpower
rounded = round(typeof(power), power, digits = 1)
fs = 4EM
symbsize = 1.5fs


restart()



begin
    # Prepare color selection
    luminback = lumin(BACKCOLOR)
    luminfront = get_current_lumin()
    deltalumin = luminback - luminfront
    avglumin = luminfront + 0.5deltalumin
    curcol = get_current_RGB()
    avgcol = color_with_lumin(curcol, luminfront + 0.5 * deltalumin)
    contrastcol = color_with_lumin(curcol, luminfront + 2 * deltalumin);
end;

gsave()
fontsize(symbsize)
fontface("DejaVu Sans")
str = "⚡"
WI, HE = textextents(str)[3:4]
p = O + (-11m, 6m)
begin
    # Outline symbol
    sethue(avgcol)
    fontface("DejaVu Sans Bold")
    fontsize(1.0989010989010988 * symbsize)
    text(str, p - fs.*(0.03, -0.04))
    # Shadow text
    fontface("DejaVu Sans")
    fontsize(fs)
    text(string(rounded), p + (1.5WI, 0) - fs.*(0.03, -0.04))
    # Inside symbol
    sethue(color_with_lumin(color_from_palette("red"), luminback))
    fontsize(symbsize)
    text(str, p)
    # Front text
    fontsize(fs)
    text(string(rounded), p + (1.5WI, 0))
end

# Make a mask
begin
    clipreset()
    newpath()
    translate(p)
    fontsize(symbsize)
    textpath(str)
    fillpreserve()
    clip()
    translate(-p)
end

sethue(curcol)
rect(p, WI , -fractionpower * HE, :fill)
sethue(contrastcol)
setline(PT)
rect(p, WI , -fractionpower * HE, :stroke)
clipreset()
grestore()
finish()
nothing
end