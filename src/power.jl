"""
    showpower(p::Point, power::P;
        maxpower = 10.0kW,
        fs = EM,
        symbsize = 1.5fs,
        backgroundcolor = colorant"white",
        labelpower::Bool = true) where {P <: Power}

p                   bottom left corner of indicator.
power               to be shown.
maxpower = 10.0kW   the symbol will be coloured to indicate power / maxpower
fs = EM             font size
symbsize = 1.5EM    lightning bolt size.
backgroundcolor     is used to pick a color for an outline.
labelpower = true   text or no text
"""
function showpower(p::Point, power::Power;
                   maxpower = 15.0kW,
                   fs = EM,
                   symbsize = 1.5fs,
                   backgroundcolor = colorant"white",
                   labelpower::Bool = true)

    fractionpower = power / ( maxpower|> typeof(power))
    rounded = round(unit(power), power, digits = 1)
    symbsize = 1.5fs
    # Prepare color selection
    luminback = lumin(backgroundcolor)
    luminfront = get_current_lumin()
    deltalumin = luminback - luminfront
    avglumin = luminfront + 0.5deltalumin
    curcol = get_current_RGB()
    avgcol = color_with_lumin(curcol, luminfront + 0.5 * deltalumin)
    contrastcol = color_with_lumin(curcol, luminfront + 2 * deltalumin)

    gsave()
    fontsize(symbsize)
    fontface("DejaVu Sans")
    str = "⚡"
    WI, HE = textextents(str)[3:4]
    # Outline symbol
    sethue(avgcol)
    fontface("DejaVu Sans Bold")
    fontsize(1.0989010989010988 * symbsize)
    text(str, p - fs.*(0.03, -0.04))
    # Shadow text
    fontface("DejaVu Sans")
    fontsize(fs)
    labelpower && text(string(rounded), p + (1.5WI, 0) - fs.*(0.03, -0.04))

    # Inside symbol
    sethue(color_with_lumin(color_from_palette("red"), luminback))
    fontsize(symbsize)
    text(str, p)
    # Front text
    fontsize(fs)
    labelpower && text(string(rounded), p + (1.5WI, 0))

    # Make a mask of the symbol
    clipreset()
    newpath()
    translate(p)
    fontsize(symbsize)
    textpath(str)
    fillpreserve()
    clip()
    translate(-p)

    # fill the symbol from bottom according to relative power
    sethue(curcol)
    rect(p, WI , -fractionpower * HE, :fill)
    sethue(contrastcol)
    setline(PT)
    rect(p, WI , -fractionpower * HE, :stroke)

    # Clean up
    clipreset()
    grestore()
    nothing
end