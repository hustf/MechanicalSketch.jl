"
ColorLegend is an abstract type. For subtypes, define functions:
    (l::legendtype)(invalue) -> color
    constructor with keyword arguments
    show
    binbounds
    draw_legend


"
abstract type ColorLegend end
struct ColorLegendIsoBins{T<:Number} <: ColorLegend
    maxlegend::T
    binwidth::T
    minlegend::T
    colorscheme::ColorSchemes.ColorScheme
    nan_color::ColorSchemes.Colorant
    name::Symbol
    function ColorLegendIsoBins(maxlegend::T, binwidth::T, minlegend::T, colorscheme, nan_color, name) where {T<:Number}
        @assert minlegend < maxlegend "Need minlegend < maxlegend. maxlegend = $maxlegend; minlegend = $minlegend"
        @assert Int(fld(maxlegend - minlegend, binwidth)) > 1 "Need more than one bin. maxlegend = $maxlegend; minlegend = $minlegend; binwidth = $(round(T, binwidth, digits =3))"
        new{T}(maxlegend, binwidth, minlegend, colorscheme, nan_color, name)
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
    @assert binno > 0
    # scale values in min:max to interval [0, 1]
    normalizedbin = (binno - 1) / (noofbins - 1)
    if normalizedbin > 1
        l.nan_color
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
                            nan_color = color_with_lumin(rotate_hue(last(colorscheme.colors), 170°), 90),
                            name = :Legend)

Call an object of type ColorLegendIsoBins to convert a quantity or other number to the appropriate color.
If called with values outside the defined range, 'nan_color' is returned.

Required input:    maxlegend         top of last color bin - values above will take 'nan_color'
    'One of' keyword argument
    binwidth       width of each color bin, e.g. (10N - 0N) / 3 = 3.33N. Use the same number type as in input!
    'Or' keyword argument
    noofbins     Integer value. Bins are sized equally in the closed interval minlengend, maxlegend.

Other input:
        minlegend         keyword argument, bottom of first bin. Default is zero. Values below are 'nan_color'
        colorscheme,      e.g. MechanicalSketch.ColorSchemes.Paired_6 (ref. github for ColorSchemes)
        nan_color         keyword argument. Output from values outside 'minlegend':'maxlegend'. Default
                          is nearly white. Use the same color type as 'colorscheme'!
        name              keyword argument, must be a Symbol. Default is :Legend. This is used by 'draw_legend'.

"""
function ColorLegendIsoBins(;maxlegend,
                            binwidth = missing,
                            noofbins = missing,
                            minlegend = 0 * maxlegend,
                            colorscheme = isoluminant_cgo_70_c39_n256,
                            nan_color = color_with_lumin(rotate_hue(last(colorscheme.colors), 170°), 90),
                            name = :Legend)
    @assert ismissing(binwidth) + ismissing(noofbins) == 1
    if ismissing(binwidth)
        binwidth = (maxlegend - minlegend) / noofbins
    end
    ColorLegendIsoBins(maxlegend, binwidth, minlegend, colorscheme, nan_color, name)
end

# Show the defined color bins, starting and ending with nan_color
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
    include_nan_color keyword argument. Default is 'true', which draws half-height boxes for values
                     outside l.maxlegend and l.minlegend

The legend is vertically aligned.
"""
function draw_legend(p::Point, l::ColorLegend; include_nan_color = true)
    gsave()
    # [MAXIMUM MAX BIN, minimum of max bin, ...miniumum min bin]
    legendvalues = reverse(binbounds(l))
    nancol = l(1.01 * first(legendvalues))
    boxtop = p  - (0.0, -1.15 * row_height())
    if include_nan_color
        # Draw nan_color above, half height
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
    if include_nan_color
        # Draw nan_color below, half height
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

struct LegendVectorLike{T} <: ColorLegend
    max_magn_legend # Same type as one component in T
    bin_magn_width
    min_magn_legend
    max_ang_legend::Angle
    bin_ang_width::Angle
    min_ang_legend::Angle
    nominal_color::ColorSchemes.Colorant
    nan_color::ColorSchemes.Colorant
    name::Symbol
    function LegendVectorLike(max_magn_legend::Q, bin_magn_width::Q, min_magn_legend::Q, 
                               max_ang_legend::Angle, bin_ang_width::Angle, min_ang_legend::Angle,
                               nominal_color, nan_color, name) where Q
        @assert min_magn_legend < max_magn_legend "Need min_magn_legend < max_magn_legend. max_magn_legend = $max_magn_legend; min_magn_legend = $min_magn_legend"
        @assert min_ang_legend < max_ang_legend "Need min_ang_legend < max_ang_legend. max_ang_legend = $max_ang_legend; min_ang_legend = $min_ang_legend"
        @assert Int(fld(max_magn_legend - min_magn_legend, bin_magn_width)) > 1 "Need more than one bin. max_magn_legend = $max_magn_legend; min_magn_legend = $min_magn_legend; bin_magn_width = $(round(T, bin_magn_width, digits =3))"
        @assert Int(fld(max_ang_legend - min_ang_legend, bin_ang_width)) > 1 "Need more than one bin. max_ang_legend = $max_ang_legend; min_ang_legend = $min_ang_legend; bin_ang_width = $(round(T, bin_ang_width, digits =3))"
        typicalComplex = complex(max_magn_legend, max_magn_legend)
        typicalTuple = (max_magn_legend, max_magn_legend)
        Tco = typeof(typicalComplex)
        Ttu = typeof(typicalTuple)
        T = Union{Tco, Ttu}
        new{T}(max_magn_legend, bin_magn_width, min_magn_legend,
               max_ang_legend, bin_ang_width, min_ang_legend,
               nominal_color, nan_color, name)
    end
end

"""
    LegendVectorLike(;max_magn_legend,
                        bin_magn_width = missing,
                        noof_magn_bins = missing,
                        min_magn_legend = 0 * max_magn_legend,
                        max_ang_legend = 180°,
                        bin_ang_width = missing,
                        noof_ang_bins = missing,
                        min_ang_legend = -max_ang_legend,
                        nominal_color = RGBA(ColorSchemes.linear_ternary_red_0_50_c52_n256[256]),
                        nan_color = RGBA(0.0, 0.0, 0.0, 0.0),
                        name = :Legend)

Call an object of type LegendVectorLike to convert a complex quantity or a 2-tuple quanty (vector) to the appropriate color.

The angular direction of the complex quantity or vector deterimines hue.

The magnitude of the complex number or vector deterimines luminance.

If called with values outside the defined range, 'nan_color' is returned.

Required input:
    max_magn_legend         The longest expected vector magnitude, typically 1.0 with some unit
                            Defines the top of last color bin - values below will take 'nan_color'
                            This is the only strictly required input. To leave out all other options,
                            call LegendVectorLike(max_magn_legend) without keyword arguments.

'One of' keyword arguments:
    bin_magn_width       width of each luminance bin, e.g. (10N - 0N) / 3 = 3.33N. 
    'Or' keyword argument
    noof_magn_bins       Integer value. Bins are sized equally in the closed interval min_magn_legend, max_magn_legend.

    bin_ang_width       Angular width of each color hue bin, e.g. 30°.
    'Or' keyword argument
    noof_ang_bins       Integer value. Bins are sized equally in the closed interval min_ang_legend, max_ang_legend.


Other keyword arguments:
    min_ang_legend         keyword argument, bottom of first bin. Default is zero.
    min_magn_legend        keyword argument, bottom of first bin. Default is zero.
    nominal_color          A color with hue typical for the direction 'min_ang_legend'. 
    nan_color              keyword argument. Output from vectors outside the defined direction and magnitude bins.
    name                   A Symbol. Default is :Legend, a better name might be :Wind or Symbol("Local field"). 
                           This is used by 'draw_legend'.

"""
function LegendVectorLike(;max_magn_legend,
    bin_magn_width = missing,
    noof_magn_bins = missing,
    min_magn_legend = 0 * max_magn_legend,
    max_ang_legend = 180°,
    bin_ang_width = missing,
    noof_ang_bins = missing,
    min_ang_legend = -max_ang_legend,
    nominal_color = RGBA(ColorSchemes.linear_ternary_red_0_50_c52_n256[256]),
    nan_color = RGBA(0.0, 0.0, 0.0, 0.0),
    name = :Legend)
    @assert ismissing(bin_magn_width) + ismissing(noof_magn_bins) == 1
    @assert ismissing(bin_ang_width) + ismissing(noof_ang_bins) == 1

    if ismissing(bin_magn_width)
        bin_magn_width = (max_magn_legend - min_magn_legend) / noof_magn_bins
    end
    if ismissing(bin_ang_width)
        bin_ang_width = (max_ang_legend - min_ang_legend) / noof_ang_bins
    end

    LegendVectorLike(max_magn_legend, bin_magn_width, min_magn_legend, 
                     max_ang_legend, bin_ang_width, min_ang_legend,
                     nominal_color, nan_color, name)
end
# Minimal constructor form
LegendVectorLike(max_magn_legend) = LegendVectorLike(;max_magn_legend, 
                                                      noof_magn_bins = 255, 
                                                      noof_ang_bins = 255)

"""
    (l::LegendVectorLike{T})(q::T) where {T<:Number}

Call a defined legend with a number or quantity to return a color
"""
function (l::LegendVectorLike{T})(q::T) where T
    # Find the right hue

    aq = qangle(q)
    noof_ang_bins = Int(fld(l.max_ang_legend - l.min_ang_legend, l.bin_ang_width))
    bin_ang_no = if aq < l.min_ang_legend || aq > l.max_ang_legend
        noof_ang_bins + 1
    else
        max(1, Int(fld(aq - l.min_ang_legend, l.bin_ang_width)))
    end
    # scale values in min:max to interval [0, 1]
    @assert bin_ang_no > 0
    normalized_ang_bin = (bin_ang_no - 1) / (noof_ang_bins - 1)
    colo = if normalized_ang_bin > 1
        l.nan_color
    else
        rotate_hue(l.nominal_color, aq)
    end

    # Find the right luminosity

    mq = magnitude(q)
    noof_magn_bins = Int(fld(l.max_magn_legend - l.min_magn_legend, l.bin_magn_width))
    bin_magn_no = if mq < l.min_magn_legend || mq > l.max_magn_legend
        noof_magn_bins + 1
    else
        max(1, Int(fld(mq - l.min_magn_legend, l.bin_magn_width)))
    end
    # scale values in min:max to interval [0, 1]
    @assert bin_magn_no > 0
    normalized_magn_bin = (bin_magn_no - 1) / (noof_magn_bins - 1)
    if normalized_magn_bin > 1
        l.nan_color
    else
        color_with_lumin(colo, 100 * normalized_magn_bin)
    end
end
magnitude(x::Complex) = hypot(x)
magnitude(x::Quantity{<:Complex}) = hypot(x)
magnitude(x::NTuple{2, T}) where T = hypot(x[1], x[2])

qangle(x::Complex) = °(angle(x))
qangle(x::Quantity{<:Complex}) = °(angle(x))
qangle(x::NTuple{2, T}) where T = °(atan(x[1], x[2]))

"""
    normalize_binwise(minx, maxx, binwidth, x)

Scale values in min:max to interval [0, 1]

TODO Fix.
"""
function normalize_binwise(minx, maxx, binwidth, x)
    if x < minx || x > maxx || isnan(x) || isinf(x)
        NaN
    else
        nbins = Int(fld(maxx - minx, binwidth))
        binno = max(1, Int(fld(x - minx, binwidth)))
        @assert binno > 0
        (binno - 1) / (nbins - 1)
    end
end