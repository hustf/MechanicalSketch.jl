abstract type ColorLegend end
struct ColorLegendIsoBins{T<:Number} <: ColorLegend
    maxlegend::T
    binwidth::T
    minlegend::T
    colorscheme::ColorSchemes.ColorScheme
    nancolor::ColorSchemes.Colorant
    name::Symbol
    function ColorLegendIsoBins(maxlegend::T, binwidth::T, minlegend::T, colorscheme, nancolor, name) where {T<:Number}
        @assert minlegend < maxlegend "Need minlegend < maxlegend. maxlegend = $maxlegend; minlegend = $minlegend"
        @assert Int(fld(maxlegend - minlegend, binwidth)) > 1 "Need more than one bin. maxlegend = $maxlegend; minlegend = $minlegend; binwidth = $(round(T, binwidth, digits =3))"
        new{T}(maxlegend, binwidth, minlegend, colorscheme, nancolor, name)
    end
end
"""
    (l::ColorLegendIsoBins{T})(q::T) where {T<:Number}

Call a defined legend with a number or quantity to return a color
"""
function (l::ColorLegendIsoBins{T})(q::T) where {T<:Number}
    noofbins = Int(fld(l.maxlegend - l.minlegend, l.binwidth))
    binno = if q < l.minlegend || q > l.maxlegend
        noofbins + 1
    else
        Int(fld(q - l.minlegend, l.binwidth))
    end
    # scale values in min:max to interval [0, 1]
    normalizedbin = (binno - 1) / (noofbins - 1)
    if normalizedbin > 1
        l.nancolor
    else
        get(l.colorscheme, normalizedbin)
    end
end

"""
    ColorLegendIsoBins(;maxlegend,
                            binwidth = missing,
                            noofbins = missing,
                            minlegend = 0 * maxlegend,
                            colorscheme = isoluminant_cgo_70_c39_n256,
                            nancolor = color_with_lumin(rotate_hue(last(colorscheme.colors), 170°), 90),
                            name = :Legend)

Call an object of type ColorLegendIsoBinds to convert a quantity or other number to the appropriate color.
If called with values outside the defined range, 'nancolor' is returned.

Required input:    maxlegend         top of last color bin - above and below values will take 'nancolor'
    'One of' keyword argument
    binwidth       width of each color bin, e.g. (10N - 0N) / 3 = 3.33N. Use the same number type as in input!
    'Or' keyword argument
    noofbins     Integer value. Bins are sized equally in the closed interval minlengend, maxlegend.

Other input:
        minlegend         keyword argument, bottom of first bin. Default is zero.
        colorscheme,      e.g. MechanicalSketch.ColorSchemes.Paired_6 (ref. github for ColorSchemes)
        nancolor          keyword argument. Output from values outside 'minlegend':'maxlegend'. Default
                          is nearly white. Use the same color type as 'colorscheme'!
        name              keyword argument, must be a Symbol. Default is :Legend. This is used by 'draw_legend'.

"""
function ColorLegendIsoBins(;maxlegend,
                            binwidth = missing,
                            noofbins = missing,
                            minlegend = 0 * maxlegend,
                            colorscheme = isoluminant_cgo_70_c39_n256,
                            nancolor = color_with_lumin(rotate_hue(last(colorscheme.colors), 170°), 90),
                            name = :Legend)
    @assert ismissing(binwidth) + ismissing(noofbins) == 1
    if ismissing(binwidth)
        binwidth = (maxlegend - minlegend) / noofbins
    end
    ColorLegendIsoBins(maxlegend, binwidth, minlegend, colorscheme, nancolor, name)
end

# Show the defined color bins, starting and ending with nancolor
function show(io::IO, m::MIME"image/svg+xml", l::ColorLegendIsoBins)
    cols = [l(x) for x = range(l.minlegend - 0.5*l.binwidth, l.maxlegend + 0.5 * l.binwidth, step = l.binwidth)]
    show(io, m, cols)
end
"""
    binbounds(l:ColorLegendIsoBins)

[minimum of minimum bin, minimum of second bind, ..., miniumum max bin, MAXIMUM MAX BIN]

The lowest values in each legend bin, increasing bin values, and lastly the upper bound of the top bin.
"""
function binbounds(l::ColorLegendIsoBins{T}) where T
    noofbins = Int(fld(l.maxlegend - l.minlegend, l.binwidth))
    vals = repeat([l.minlegend], noofbins)
    vals[1] = l.minlegend
    curval = zero(T)
    for i = 2:(noofbins - 1)
        curval += l.binwidth
        vals[i] = curval
    end
    vals[noofbins] = l.maxlegend
    vals
end



"""
    draw_legend(p::Point, l::ColorLegend)
    -> text values (the function also draws the legend)

Input:
    p                is the upper left position for the legend
    l                is the legend definition, which might include a .name field other than :Legend
    include_nancolor keyword argument. Default is 'true', which draws half-height boxes for values
                     outside l.maxlegend and l.minlegend

The legend is vertically aligned.
"""
function draw_legend(p::Point, l::ColorLegend; include_nancolor = true)
    gsave()
    # [MAXIMUM MAX BIN, minimum of max bin, ...miniumum min bin]
    legendvalues = reverse(binbounds(l))
    nancol = l(1.01 * first(legendvalues))
    boxtop = p  - (0.0, -1.15 * row_height())
    if include_nancolor
        # Draw nancolor above, half height
        ul = boxtop + 1.0.*(0, row_height())
        br = boxtop + 1.0.*(EM, 0.5 * row_height())
        sethue(nancol)
        box(ul, br, :fill)
        lu = get_current_lumin()
        sethue(color_with_lumin(nancol, min(100, 2 * lu)))
        box(ul, br, :stroke)
    end

    for v in legendvalues[1:(end -1)]
        colo = l(v)
        boxtop += (0.0, row_height())
        sethue(colo)
        box(boxtop, boxtop + (EM, row_height() ), :fill)
        lu = get_current_lumin()
        sethue(color_with_lumin(colo, min(100, 2 * lu)))
        box(boxtop, boxtop + (EM, row_height() ), :stroke)
    end
    if include_nancolor
        # Draw nancolor below, half height
        boxtop += (0.0, row_height())
        bl = boxtop + 1.0.*(0, 0.5 * row_height())
        ur = boxtop + 1.0.*(EM, 0)
        sethue(nancol)
        box(bl, ur, :fill)
        lu = get_current_lumin()
        sethue(color_with_lumin(nancol, min(100, 2 * lu)))
        box(bl, ur, :stroke)
    end
    grestore()
    text_table(p + (-0.5 * row_height(), 0.5 * row_height()) ; l.name => legendvalues)
end


"""
    draw_real_legend(p::Point, min_quantity, max_quantity, legendvalues)
    -> text values (the function also draws the legend)

p is the upper left position for the legend
min_quantity and max_quantity is used for determining the color.
legendvalues is an iterable collection with the same units as min_quantity and max_quantity.

The legend is vertically aligned on the dots in legendvalues
"""
function draw_real_legend(p::Point, min_quantity, max_quantity, legendvalues)
    gsave()
    rowhe = row_height()
    for (i, v) in enumerate(legendvalues)
        dimless = (v - min_quantity) / (max_quantity - min_quantity)
        colo = get(absolute_scale(), dimless)
        sethue(colo)
        box(p + (0.0, i * rowhe), p + (EM, (i + 1 ) * rowhe ), :fillpreserve)
    end
    grestore()
    text_table(p, Legend = legendvalues)
end

"""
    draw_complex_legend(p::Point, min_abs_quantity, max_abs_quantity, legendvalues)
    -> text values (the function also draws the legend)

p is the upper left position for the legend
min_abs_quantity and max_abs_quantity is used for determining the color.
legendvalues is an iterable collection with the same units.

The legend is vertically aligned on the dots in legendvalues
"""
function draw_complex_legend(p::Point, min_abs_quantity::T, max_abs_quantity::T, legendvalues::AbstractArray{T}) where {T<:RealQuantity}
    gsave()
    rowhe = row_height()
    # Legend magnitude
    for (i, v) in enumerate(legendvalues)
        dimless = (v - min_abs_quantity) / (max_abs_quantity - min_abs_quantity)
        upleft = p + (0.0, i * rowhe)
        downright = p + (EM, (i + 1 ) * rowhe)
        realcolo = get(complex_arg0_scale(), dimless)
        n = EM
        for (j, x) in enumerate(range(upleft[1], downright[1], length=n))
            sethue(rotate_hue(realcolo, (j - 1) * 360° / n))
            box(Point(x, upleft[2]), downright, :fillpreserve)
        end
    end
    # Legend argument
    argumentwidth = 5EM
    upleft = p + (0.0, (length(legendvalues) + 3) * rowhe)
    downright = p + (argumentwidth, ((length(legendvalues) + 4)) * rowhe)
    realcolo = get(complex_arg0_scale(), 1.0)
    n =  argumentwidth
    for (j, x) in enumerate(range(upleft[1], downright[1], length=n))
        sethue(rotate_hue(realcolo, (j - 1) * 360° / n))
        box(Point(x, upleft[2]), downright, :fillpreserve)
    end
    grestore()
    strangles = "0°  120°  240°"
    draw_header(upleft + (0.0, - FS / 3 ), [pixelwidth(strangles)], [strangles])
    # Print magnitude text
    text_table(p, Legend = legendvalues)
end
