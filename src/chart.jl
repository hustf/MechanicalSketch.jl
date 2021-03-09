"_sample_bar_points(samples, maxwidth; first_sample_no = 1)"
function _sample_bar_points(samples, maxwidth; first_sample_no = 1)
    pts = Vector{Point}()
    for (i, val) in enumerate(samples)
        x = maxwidth * (i + first_sample_no - 1) / length(samples)
        y = - val
        push!(pts,  Point(x, 0*x))
        push!(pts,  Point(x, 0*x) + Point(0y, y))
    end
    pts
end

"""
    _draw_bars(origo, samples, maxwidth; 
                   rotatehue_degrees_total = 0°, first_sample_no = 1,
                   top_circle_radius = 0.04EM)))
"""
function _draw_bars(origo, samples, maxwidth; 
                   rotatehue_degrees_total = 0°, first_sample_no = 1, top_circle_radius = 0.04EM)
    startcolo = get_current_RGB()
    samplepoints = _sample_bar_points(samples,  maxwidth; first_sample_no)
    function foovertex(n, pt)
        rotatedeg = (n - 1) * rotatehue_degrees_total / length(samplepoints)
        sethue(rotate_hue(startcolo, rotatedeg))
        circle(pt, top_circle_radius, :stroke)
    end
    @layer begin
        for i in range(1, length(samplepoints) - 1, step = 2)
            pt = origo + samplepoints[i]
            npt = origo + samplepoints[i + 1]
            line(pt, npt, :stroke)
            foovertex(i, npt)
        end
    end
end


"""
    draw_barplot(origo, samples, width; 
                first_sample_no = 1, 
                rotatehue_degrees_total = 270°, firstcolor = PALETTE[3],
                height = 2EM, top_circle_radius = 0.04EM)

    - origo is a Point.
    - samples is the vector to plot as bars
    - width is the horizontal distance over which to distribute bar

Draw a bar plot without decorations; arrows and the first sample in the same colour.

"""
function draw_barplot(origo, samples, width; 
                      first_sample_no = 1, 
                      rotatehue_degrees_total = 270°, firstcolor = PALETTE[3],
                      height = 2EM, top_circle_radius = 0.04EM)
    @layer begin
        sethue(firstcolor)
        arrow(origo, origo + (0height,  -height))
        wplus = width * (length(samples) + first_sample_no - 1) / length(samples)
        arrow(origo, origo + (wplus, 0wplus) + (0.5EM, 0.0))
        sethue(color_from_palette("red"))
        _draw_bars(origo, samples, width; rotatehue_degrees_total, first_sample_no, top_circle_radius)
    end
end

"""
    color_matrix(f_xy; physwidth = 10.0m, physheight = 4.0m, centered = true,
                 legend = missing, kwargs...) 
    -> (color_matrix, legend)

Return a matrix of colors suitable for display with 'place_image'. Colors 
are found by calling 'legend' with single values out of function f_xy.

'legend' can be input as a keyword argument. If not, a legend is generated
internally, as modified by keyword arguments relevant to the proposed legend type. 
See: BinLegend or BinLegendVector.

The legend is also returned. Internally generated legends are of type 'AbstractColorLegend',
and can be displayed with 'draw_legend'.
"""
function color_matrix(f_xy; physwidth = 10.0m, physheight = 4.0m, centered = true,
    legend = missing, kwargs...) 

    xs, ys = x_y_iterators_at_pixels(;physwidth, physheight, centered)
    valmat = [f_xy(x, y) for y in ys, x in xs];
    _color_matrix(valmat, f_xy;  legend, kwargs...)
end
function _color_matrix(valmat::Matrix{T}, f_xy;  legend = missing, centered = true, kwargs...) where T<:Tuple
    magnitude_matrix = hypot.(valmat)
    if ismissing(legend)
        legend = propose_legend(magnitude_matrix; kwargs...)
    end
    streamlinepixels = falses(size(valmat))
    streamlines_matrix!(streamlinepixels, f_xy)
    complex_convolution_matrix = convolution_matrix(f_xy, streamlinepixels)
    curmat = lic_matrix_current(complex_convolution_matrix, 0, zeroval = -0.0)
    colmat = map(legend.(magnitude_matrix), curmat) do col, lu
        color_with_lumin(col, 50 + 50 * lu)
    end
    colmat, legend
end
function _color_matrix(valmat::Matrix, f_xy;  legend = missing, centered = true, kwargs...)
    @error "Not implemented"
end

"""
    propose_legend(scalmat::Matrix{T}, kwargs...) where T <: Number
    -> AbstractColorLegend

Return a proposed legend based on the unit and values of magmat.
Keyword arguments set here overrule proposed arguments. See:
BinLegend or BinLegendVector. Possible values include 'missing',
which will also overrule proposals from this function.
"""
function propose_legend(mat::Matrix{T}; kwargs...) where T <: Number
    lum = 50
    mi, ma = lenient_min_max(mat)
    maxlegend = ma  # kwargs overrule if present
    noofbins = if !haskey(kwargs, :binwidth) && !haskey(kwargs, :noofbins) && !haskey(kwargs, :binbounds)
        # None of three present
        7
    else
        # Sufficient arguments are present.
        # IF noofbins is actually contained in kwargs, it will be placed after in the call, and thus overrule:
        missing
    end
    if T <: Velocity
        name = :Speed # kwargs overrule if present
        colorscheme = ColorSchemes.isoluminant_cgo_80_c38_n256.colors .|> co -> color_with_lumin(co, lum)
        BinLegend(;maxlegend, noofbins, colorscheme, name, kwargs...)
    else
        @error "$T scalar quantity not implemented."
    end
end
