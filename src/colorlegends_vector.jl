
"""
BinLegendVector(;operand_example = missing,
                        max_magn_legend = missing,
                        bin_magn_width = missing,
                        noof_magn_bins = missing,
                        bin_magn_bounds = NTuple{0, Missing}()::NTuple,
                        min_magn_legend = 0 * max_magn_legend,
                        max_ang_legend = 180.0°,
                        bin_ang_width = missing,
                        noof_ang_bins = missing,
                        bin_ang_bounds = NTuple{0, Missing}()::NTuple,
                        min_ang_legend = -max_ang_legend,
                        nominal_color = HSVA(0.0f0,1.0f0,1.0f0,1.0f0),
                        nan_color = color_with_alpha(nominal_color, 0.1f0),
                        name = :BinLegendVector::Symbol,
                        max_lumin = lumin(nominal_color)::Float32,
                        min_lumin = max_lumin / 6)

Subtype of AbstractColorLegend. For 2d quantities, i.e. complex or 2-tuple quantities or numbers.

Call an object of this type to convert a 2d quantity or number to a color (angle) and luminance (magnitude).

If called with values outside the defined range, 'nan_color' is returned.

Required input, all keyword arguments:
operand_example   E.g. 'complex(1.0, 1.0)m/s' or '(1.0, 1.0)'.
One of these three, both for XXX = magn or XXX = ang:
1) bin_XXX_width       Width of each hue or lumininance bin, e.g. (10N - 0N) / 3 = 3.33N. Use the same number type as in input!
2) noof_XXX_bins       Bins are sized equally in the closed interval minlengend, maxlegend.
3) bin_XXX_bounds      Sorted from small to large. You can get a propsal by calling 'bin_bounds'.

Other input:
nan_color         Output for input ∉ [minlegend, maxlegend] or ∈{inf, NaN, missing}. Default is nearly transparent.
name              keyword argument, must be a Symbol. Default is :Legend. This is used by 'draw_legend'.
"""
struct BinLegendVector{T, N, M, U} <: AbstractColorLegend
    bin_magn_bounds::SVector{N, U}
    bin_ang_bounds::SVector{M, Angle}
    nominal_color::ColorSchemes.Colorant
    nan_color::ColorSchemes.Colorant
    name::Symbol
    max_lumin::Float32
    min_lumin::Float32
    function BinLegendVector(::Val{N}, ::Val{M}, ::T, bin_magn_bounds::NTuple{N, U},
                            bin_ang_bounds::NTuple{M, Angle}, nominal_color, nan_color, name, max_lumin, min_lumin) where {T, N, M, U}
         sa_magn = SVector{N, U}(bin_magn_bounds)
         sa_ang = SVector{M, Angle}(bin_ang_bounds)
         new{T, N, M, U}(sa_magn, sa_ang, nominal_color, nan_color, name, max_lumin, min_lumin)
    end
 end
# Outer constructor (don't use directly)
function BinLegendVector(operand_example::T, bin_magn_bounds::NTuple{N, U},
    bin_ang_bounds::NTuple{M, Angle},
    nominal_color, nan_color, name,
    max_lumin, min_lumin) where {T, N, M, U}
    @assert length(bin_magn_bounds) == N
    @assert length(bin_ang_bounds) == M
    @assert isbitstype(U)
    @assert issorted(bin_magn_bounds)
    @assert issorted(bin_ang_bounds)
    @assert typeof(nan_color) == typeof(nominal_color)
    @assert 0 <= max_lumin <= 100
    @assert 0 <= min_lumin <= 100
    lu = lumin(nominal_color)
    if lu isa Int 
        if lumin(nominal_color) < 10 
            s = "lumin(nominal_color) = $lu < 10, typeof(..) = $(typeof(nominal_color))"
            @warn s
        end
    else
        if lumin(nominal_color) < 0.1
            s = "lumin(nominal_color) = $lu < 0.1, typeof(..) = $(typeof(nominal_color))"
            @warn s
        end
    end
    kathete = first(bin_magn_bounds)
    hypotenuse1 = complex(kathete, kathete)
    hypotenuse2 = sqrt(kathete^2 + kathete^2)
    @assert T == typeof(hypotenuse1) || T == typeof(hypotenuse2) "T is $T and not \n\t$(typeof(hypotenuse1))  or   $(typeof(hypotenuse2))"
    BinLegendVector(Val{N}(), Val{M}(), operand_example, bin_magn_bounds, bin_ang_bounds, nominal_color, nan_color, name, max_lumin, min_lumin)
end
# Main, easygoing constructor
function BinLegendVector(;operand_example = missing,
                        max_magn_legend = missing,
                        bin_magn_width = missing,
                        noof_magn_bins = missing,
                        bin_magn_bounds = NTuple{0, Missing}()::NTuple,
                        min_magn_legend = 0 * max_magn_legend,
                        max_ang_legend = 180.0°,
                        bin_ang_width = missing,
                        noof_ang_bins = missing,
                        bin_ang_bounds = NTuple{0, Missing}()::NTuple,
                        min_ang_legend = -max_ang_legend,
                        nominal_color = HSVA(0.0f0,1.0f0,1.0f0,1.0f0),
                        nan_color = color_with_alpha(rotate_hue(nominal_color, 180°), 0.1f0),
                        name = :BinLegendVector::Symbol,
                        max_lumin = lumin(nominal_color)::Float32,
                        min_lumin = max_lumin / 6)
    @assert !ismissing(operand_example) "ismissing(operand_example): Keyword argument - only the type is used."
    # Check that one of three is missing
    @assert ismissing(bin_magn_width) + ismissing(noof_magn_bins) + isempty(bin_magn_bounds) == 2 "Provide one of 'bin_magn_width', 'noof_magn_bins' or 'bin_magn_bounds'"
    @assert ismissing(max_magn_legend) + isempty(bin_magn_bounds) == 1 "Provide either 'max_magn_legend' or 'bin_magn_bounds'"
    @assert typeof(max_magn_legend) == typeof(min_magn_legend)
    bin_magn_bo = if isempty(bin_magn_bounds)
        if ismissing(bin_magn_width)
            bin_magn_width = (max_magn_legend - min_magn_legend) / noof_magn_bins
        end
        @assert typeof(bin_magn_width) == typeof(min_magn_legend)
        bin_bounds(min_magn_legend, bin_magn_width, max_magn_legend)
    else
        bin_magn_bounds
    end
    # Same as above, but for vector direction (angle from abscissa)
    @assert ismissing(bin_ang_width) + ismissing(noof_ang_bins) + isempty(bin_ang_bounds) == 2 "Provide one of 'bin_ang_width', 'noof_ang_bins' or 'bin_ang_bounds'"
    @assert ismissing(max_ang_legend) + isempty(bin_ang_bounds) == 1 "Provide either 'max_ang_legend' or 'bin_ang_bounds'"
    @assert typeof(max_ang_legend) == typeof(min_ang_legend)

    bin_ang_bo = if isempty(bin_ang_bounds)
        if ismissing(bin_ang_width)
            bin_ang_width = (max_ang_legend - min_ang_legend) / noof_ang_bins
        end
        @assert typeof(bin_ang_width) == typeof(min_ang_legend)
        bin_bounds(min_ang_legend, bin_ang_width, max_ang_legend)
    else
        bin_ang_bounds
    end
    BinLegendVector(operand_example, bin_magn_bo, bin_ang_bo, nominal_color, nan_color, name, max_lumin, min_lumin)
end

# Innermost call of BinLegendVector type, don't use directly, trait dispatch below.
function _adapt_color(nomc, nanc, max_lumin, min_lumin, magn, ang::Angle)
    if isnan(magn) || isnan(ang)
        nanc
    else
        rotate_hue(color_with_lumin(nomc, min_lumin + magn * (max_lumin - min_lumin)), ang)
    end
end
function (l::BinLegendVector{T, N, M, U})(::Val{N}, ::Val{M}, q::T) where {T <: Union{ComplexQuantity, Complex}, N, M, U}
    bin_magn_bounds, bin_ang_bounds = bin_bounds(l)
    magn = magnitude(q)
    norm_magn_bin = normalize_binwise(N, bin_magn_bounds, magn)
    if isnan(norm_magn_bin)
        l.nan_color
    else
        ang = qangle(q)
        # TODO improve logic by excluding an interval based on min and max. 
        # Otherwise accept multiples of 360°
        if ang < first(bin_ang_bounds) || ang > last(bin_ang_bounds)
            l.nan_color
        else
            bin = min(searchsortedlast(bin_ang_bounds, ang), M - 1)
            binned_ang = bin_ang_bounds[bin]
            _adapt_color(l.nominal_color, l.nan_color, l.max_lumin, l.min_lumin, norm_magn_bin, binned_ang)
        end
    end
end

(l::BinLegendVector{T, N, M, U})(q::T) where {T, N, M, U} = l(Val{N}(), Val{M}(), q)

# Obligatory extended functions for this legend type
"""
    bin_bounds(l::BinLegendVector)
    ->  (bin_magn_bounds, bin_ang_bounds)
"""
bin_bounds(l::BinLegendVector) = l.bin_magn_bounds, l.bin_ang_bounds

# Show the defined color bins, ending with nan_color.
function show(io::IO, mime::MIME"image/svg+xml", l::BinLegendVector{T, N, M, U})  where {T, N, M, U}
    nomc = l.nominal_color
    nanc = l.nan_color
    bm = if iszero(first(l.bin_magn_bounds))
        # Do not include nan_color below.
        SVector{N, U}(l.bin_magn_bounds[1:(end - 1)]... , NaN * first(l.bin_magn_bounds))
    else
        # Include nan_color below.
        SVector{N + 1, U}(NaN * first(l.bin_magn_bounds)[1:(end - 1)] , l.bin_magn_bounds... , NaN * first(l.bin_magn_bounds))
    end
    norm_bm = map(magn -> normalize_binwise(N, l.bin_magn_bounds, magn), bm)
    # Angles
    ba = if mod(first(l.bin_ang_bounds), 360°) == mod(l.bin_ang_bounds[M], 360°)
        # All angles are covered, don't include NaN but include -180° and 180° although equal.
        SVector{M,  Angle}(l.bin_ang_bounds)
    else
        # Inlcude NaN
        SVector{M + 1, Angle}(NaN * first(l.bin_ang_bounds), l.bin_ang_bounds...)
    end
    curry(magn, ang) = _adapt_color(nomc, nanc, l.max_lumin, l.min_lumin, magn, ang)
    colmat = Matrix([curry(nmagn, ang) for nmagn in norm_bm, ang in ba])
    colnoalpha = color_without_alpha.(colmat)
    buf = IOBuffer()
    show(buf, mime, colnoalpha)
    svgdocstr = String(take!(buf))
    invalid = """<svg xmlns="http://www.w3.org/2000/svg" version="1.1"""
    valid = "<svg "
    svgelem  = valid * split(svgdocstr, invalid)[2]
    htmlstart = "<!DOCTYPE html><html><body>"
    vmin = first(l.bin_magn_bounds)
    vmax = last(l.bin_magn_bounds)
    amin = first(l.bin_ang_bounds)
    amax = last(l.bin_ang_bounds)
    htmlpara = """
        <p>$(l.name)</p>
        <p>( $(amin) to $(amax) ) in $(M - 1) bins, ( $(vmin) to $(vmax) ) in $(N - 1) bins, Out-of-Bounds</p>
        """
    htmlend = "</body></html>"
    htmldoc = htmlstart * htmlpara * svgelem * htmlend
    write(io, htmldoc)
    flush(io) 
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
function draw_legend(p::Point, l::BinLegendVector{T, N, M, U}; include_nan_color = true,
                     max_vert_height = 10EM,
                     background_hue = color_with_lumin(PALETTE[8], 0.1),
                     background_opacity = 0.2) where {T, N, M, U}
    bin_magn_bounds, bin_ang_bounds = bin_bounds(l)
    # Edge of bin values, magnitude
    binb_sinking = Vector{Any}(reverse(bin_magn_bounds))
    # In bin values
    vals_sinking = T.(reverse(bin_magn_bounds))[2:end]
    # Can we fit the entire legend, or is it too tall?
    max_vert_height_pix = get_scale_sketch(max_vert_height)
    estimate_full_height = 0.0
    while true
        estimate_full_height = (length(vals_sinking) + 2 + include_nan_color) * row_height()
        estimate_full_height < max_vert_height_pix && break
        # Truncate magnitude boxes at middle
        vals_sinking = [vals_sinking[1:div(end, 2) - 1 ] ; [NaN * vals_sinking[1]] ;vals_sinking[div(end, 2) + 2: end] ]
        binb_sinking = [binb_sinking[1:div(end, 2) - 1 ] ; [".."] ;binb_sinking[div(end, 2) + 2: end] ]
    end

    # Positions
    pos_table = p + Point(0, 1) * row_height()
    colwidth = max(6.0EM, column_widths(;l.name => binb_sinking)[1])
    fullwidth = pos_table[1] + colwidth +0.5EM - p[1]
    fullheight = pos_table[2] + estimate_full_height - p[2]

    draw_background(p, fullwidth, fullheight; background_hue, background_opacity)

    # Plot magnitude boxes
    
    box_tl  = pos_table + Point(0.5,  0.65    ) * row_height()
    ptul, ptbr = _draw_legend_boxes(box_tl, l, include_nan_color, vals_sinking)

    

    # Pick four colours representing angles
    TA = typeof(first(bin_ang_bounds))
    angs = [bin_ang_bounds[2div(M, 4) + 1], 
            bin_ang_bounds[3div(M, 4) + 1], 
            360° + bin_ang_bounds[1], 
            360° + bin_ang_bounds[div(M , 4) + 1]]
    angs = [TA.((45, 135, -135, -45)°)...]
    anglebins = map(angs) do ang
        round(1 + (M - 2) * normalize_binwise(M, bin_ang_bounds, ang))
    end
    binned_angles = bin_ang_bounds[Int.(anglebins)]
    colos = rotate_hue.(l.nominal_color, binned_angles)
    
    # Plot angle boxes
    pt_tl = p  + (5EM, 3.15 * row_height())
    for colo in colos
        pt_tl += (0.0, row_height())
        box_fill_outline(pt_tl, colo)
    end
    text("↗", p + (5.1EM, -0.1EM + 5.15 * row_height()))
    text("↖", p + (5.1EM, -0.1EM + 6.15 * row_height()))
    text("↙", p + (5.1EM, -0.1EM + 7.15 * row_height()))
    text("↘", p + (5.1EM, -0.1EM + 8.15 * row_height()))

    text_table_fixed_columns(pos_table, colwidth ; l.name => binb_sinking)
    p, p + Point(fullwidth, fullheight)
end
