"""
    bin_bounds(minx::T, binwidth::T, maxx::T) where T<:Number
    ->  NTuple(minx, minx + i∙binwidth, maxx) where i = 1:(no_of_bins + 1)
"""
function bin_bounds(minx::T, binwidth::T, maxx::T) where T<:Number
    nbins = Int(round((maxx - minx) / binwidth))
    bounds = [minx + i * binwidth for i = 0:nbins]
    bounds[end] = maxx
    NTuple{length(bounds), eltype(bounds)}(bounds)
end
"""
    normalize_binwise(no_of_binbounds, binbounds, x)
    --> Float64 ∈ [0, 1], in steps
"""
function normalize_binwise(no_of_binbounds, binbounds, x)::Float64
    if x < first(binbounds)|| x > last(binbounds) || isnan(x) || isinf(x)
        NaN
    else
        bin = min(searchsortedlast(binbounds, x), no_of_binbounds - 1)
        (bin - 1)/ (no_of_binbounds - 2)
    end
end

_nancolor(colorscheme::ColorSchemes.ColorScheme) = _nancolor(colorscheme.colors)
_nancolor(colorscheme) = color_with_lumin(rotate_hue(last(colorscheme), 170°), 3 * lumin(last(colorscheme)))

"""
AbstractColorLegend. For subtypes, define functions:
    constructor including keyword arguments
    (l::legendtype)(invalue) -> color
    show
    bin_bounds
    draw_legend
"""
abstract type AbstractColorLegend end

"""
    show(io::IO, m::MIME"image/svg+xml", l<:AbstractColorLegend)
"""
show

"""
    bin_bounds(l<:AbstractColorLegend )
    ->  NTuple(minx, minx + i∙binwidth, maxx) where i = 1:(no_of_bins + 1)
"""
bin_bounds

"""
    draw_legend(p::Point, l<:AbstractColorLegend; include_nan_color = true, max_vert_height = 7EM)
        -> text values (the function also draws the legend)

Input:
    p                is the upper left position for the legend
    l                is the legend definition, which might include a .name field other than :Legend
    include_nan_color keyword argument. Default is 'true', which draws half-height boxes for values
                     outside l.maxlegend and l.minlegend
    max_vert_height  The legend will be truncated at the middle if the stack of boxes is taller. Typical figure height

The legend is vertically aligned.
"""
draw_legend







# Below: BinLegend. Other legend types in separate files, similar structure.

"""
    BinLegend(;maxlegend = missing,
                    binwidth = missing,
                    noofbins = missing,
                    binbounds = NTuple{0, Missing}()::NTuple,
                    minlegend = 0 * maxlegend,
                    colorscheme = leonardo,
                    nan_color = color_with_lumin(rotate_hue(last(colorscheme.colors), 170°), 3 * lumin(last(colorscheme.colors))),
                    name = :BinLegend::Symbol)

Subtype of AbstractColorLegend, suitable for 2 < bins < 100, but can take more. For scalar quantities or numbers, not vectors.

Call an object of this type to convert a quantity or other number to a color. More than ~6 bins look pretty but is not easy to read.

If called with values outside the defined range, 'nan_color' is returned.

Required input, all keyword arguments:
    maxlegend         top of last color bin - values above will take 'nan_color'
    One of these three:
    1) binwidth       Width of each color bin, e.g. (10N - 0N) / 3 = 3.33N. Use the same number type as in input!
    2) noofbins       Bins are sized equally in the closed interval minlengend, maxlegend.
    3) binbounds      Sorted from small to large. You can get a propsal by calling 'bin_bounds'.

Other input:
    minlegend         Bottom of first bin. Default is zero. Values below are 'nan_color'
    colorscheme,      Example: MechanicalSketch.ColorSchemes.Paired_6 (ref. github ColorSchemes.jl)
    nan_color         Output for input ∉ [minlegend, maxlegend] or ∈{inf, NaN, missing}. Default is nearly white,
                      but a transparent color can be useful
    name              keyword argument, must be a Symbol. Default is :Legend. This is used by 'draw_legend'.
"""
struct BinLegend{T, N} <: AbstractColorLegend
    binbounds::SVector{N, T}
    colorscheme::ColorSchemes.ColorScheme
    nan_color::ColorSchemes.Colorant
    name::Symbol
    function BinLegend(::Val{N}, binbounds::NTuple{N, T}, colorscheme, nan_color, name) where {T, N}
         sabibo = SVector{N, T}(binbounds)
         new{T, N}(sabibo, colorscheme, nan_color, name)
    end
 end
 # Outer constructor (don't use directly)
 function BinLegend(binbounds::NTuple{N, T}, colorscheme, nan_color, name) where {T, N}
    @assert length(binbounds) == N
    @assert isbitstype(T)
    @assert issorted(binbounds)
    @assert typeof(nan_color) == typeof(get(colorscheme, 0.5, :clamp))
    BinLegend(Val{N}(), binbounds, colorscheme, nan_color, name)
 end
 # Main, easygoing constructor
 function BinLegend(;maxlegend = missing,
                    binwidth = missing,
                    noofbins = missing,
                    binbounds = NTuple{0, Missing}()::NTuple,
                    minlegend = 0 * maxlegend,
                    colorscheme = ColSchemeNoMiddle,
                    nan_color = _nancolor(colorscheme),
                    name = :BinLegend::Symbol)
    # Check that one of three is missing
    @assert ismissing(maxlegend) + isempty(binbounds) == 1 "Provide either 'maxlegend' or 'binbounds'"
    @assert ismissing(binwidth) + ismissing(noofbins) + isempty(binbounds) == 2 "Provide one of 'binwidth', 'noofbins' or 'binbounds'"
    @assert typeof(maxlegend) == typeof(minlegend)
    bibo = if isempty(binbounds)
               if ismissing(binwidth)
                   binwidth = (maxlegend - minlegend) / noofbins
                end
                @assert typeof(binwidth) == typeof(minlegend)
                bin_bounds(minlegend, binwidth, maxlegend)
            else
                binbounds
            end
    # Pack colors as a ColorScheme
    colscheme = if colorscheme isa ColorSchemes.ColorScheme
        colorscheme
    else
        ColorSchemes.ColorScheme(colorscheme, "Na", "Unknown")
    end
    BinLegend(bibo, colscheme, nan_color, name)
end
# Innermost call of BinLegend type, don't use directly, trait dispatch below.
function (l::BinLegend{T, N})(::Val{N}, q::T) where {T <: Number, N}
    # scale values in defined legend range to defined steps in interval [0, 1]
    normalizedbin = normalize_binwise(N, bin_bounds(l), q)
    # return color
    if isnan(normalizedbin)
        l.nan_color
    else
        get(l.colorscheme, normalizedbin, :clamp)
    end
end
"""
Call the BinLegend type with a number or quantity, just like you would call a function, return a color
"""
(l::BinLegend{T, N})(q::T) where {T, N} = l(Val{N}(), q)



# Obligatory extended functions for this legend type
"""
    bin_bounds(l::BinLegend)
    ->  NTuple(minx, minx + i∙binwidth, maxx) where i = 1:(no_of_bins + 1)
"""
bin_bounds(l::BinLegend) = l.binbounds


function show(io::IO, mime::MIME"image/svg+xml", l::BinLegend)
    cols = [l.nan_color, l.(l.binbounds)[1:(end - 1)]..., l.nan_color]
    colnoalpha = color_without_alpha.(cols)
    buf = IOBuffer()
    show(buf, mime, colnoalpha)
    svgdocstr = String(take!(buf))
    invalid = """<svg xmlns="http://www.w3.org/2000/svg" version="1.1"""
    valid = "<svg "
    svgelem  = valid * split(svgdocstr, invalid)[2]
    htmlstart = "<!DOCTYPE html><html><body>"
    vmin = first(l.binbounds)
    vmax = last(l.binbounds)
    htmlpara = """
        <p>$(l.name)</p>
        <p>Out-of-bounds , $(vmin) to $(vmax) in $(length(l.binbounds) - 1) bins, Out-of-bounds</p>
        """
    htmlend = "</body></html>"
    htmldoc = htmlstart * htmlpara * svgelem * htmlend
    write(io, htmldoc)
    flush(io) 
end

"""
draw_background(pt_upleft, width, height; 
                         background_hue = color_with_lumin(PALETTE[8], 0.1),
                         background_opacity = 0.2)
Background for legend
"""
function draw_background(pt_upleft, width::T, height::T; 
                         background_hue = color_with_lumin(PALETTE[8], 0.1),
                         background_opacity = 0.2) where T
    @layer begin
        sethue(background_hue)
        setopacity(background_opacity)
        if T <: Quantity
            rect(pt_upleft, width, height; action = :fill)
        else
            rect(pt_upleft, width, height, :fill)
        end
    end
end
"""
    draw_legend(p::Point, l::BinLegendVector{T, N, M, U}; include_nan_color = true,
        max_vert_height = 10EM,
        background_hue = color_with_lumin(PALETTE[8], 0.1),
        background_opacity = 0.5)
        -> (upper left point, lower right point)

Input:
    p                is the upper left position for the legend
    l                is the legend definition, which might include a .name field other than :Legend
    include_nan_color keyword argument. Default is 'true', which draws half-height boxes for values
                     outside l.maxlegend and l.minlegend
    max_vert_height  The legend will be truncated at the middle if the stack of boxes is taller. Typical figure height

The legend is vertically aligned.
"""
function draw_legend(p::Point, l::BinLegend; include_nan_color = true, 
                    max_vert_height = 10EM,
                    background_hue = color_with_lumin(PALETTE[8], 0.1),
                    background_opacity = 0.2)
    # Edge of bin values
    binb_sinking = Vector{Any}(reverse(bin_bounds(l)))
    # In bin values
    vals_sinking = reverse(bin_bounds(l))[2:end]
    # Can we fit the entire legend, or is it too tall?
    max_vert_height_pix = scale_to_pt(max_vert_height)
    estimate_full_height = 0.0
    while true
        estimate_full_height = (length(vals_sinking) + 2 + include_nan_color) * row_height()
        estimate_full_height < max_vert_height_pix && break
        # Truncate at middle
        vals_sinking = [vals_sinking[1:div(end, 2) - 1 ] ; [NaN * vals_sinking[1]] ;vals_sinking[div(end, 2) + 2: end] ]
        binb_sinking = [binb_sinking[1:div(end, 2) - 1 ] ; [".."] ;binb_sinking[div(end, 2) + 2: end] ]
    end

    # Positions
    pos_table = p + Point(0, 1) * row_height() 
    box_tl  = pos_table + Point(0.5,  0.65    ) * row_height()
    colwidth = max(5.0EM, column_widths(;l.name => binb_sinking)[1])
    fullwidth = pos_table[1] + colwidth - p[1]
    fullheight = pos_table[2] + estimate_full_height - p[2]
    draw_background(p, fullwidth, fullheight; background_hue, background_opacity)
    # Plot
    ptul, ptbr = _draw_legend_boxes(box_tl, l, include_nan_color, vals_sinking)
    text_table_fixed_columns(pos_table, colwidth ; l.name => binb_sinking)

    p, p + Point(fullwidth, fullheight)
end

"""
    _draw_legend_boxes(pt_tl::Point, legend, include_nan_color, vals_sinking)
    --> pt_topleft, pt_br
"""
function _draw_legend_boxes(pt_tl::Point, legend, include_nan_color, vals_sinking)
    gsave()
    pt_topleft = pt_tl + include_nan_color .* (0.0, 0.5 * row_height())
    nancol = legend.nan_color
    if include_nan_color
        # Draw nan_color above, half height
        box_fill_outline(pt_tl +(0.0, 0.5 * row_height()), nancol;
                          height = 0.5 * row_height())
    end
    for v in vals_sinking
        colo = legend(v)
        pt_tl += (0.0, row_height())
        box_fill_outline(pt_tl, colo)
    end
    if include_nan_color
        # Draw nan_color below, half height
        pt_tl += (0.0, 0.5 * row_height())
        box_fill_outline(pt_tl + (0.0, 0.5 * row_height()), nancol;
                          height = 0.5 * row_height())
    end
    pt_br = pt_tl + (EM, row_height())
    grestore()
    pt_topleft, pt_br
end


