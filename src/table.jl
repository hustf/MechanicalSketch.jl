"""
    header_strings(; kwargs...)
        --> [ String(Tuple name [Value unit]]

Take kwarg names, add value units in brackets.
Strings don't contain colour codes around units.
"""
function header_strings(; kwargs...)
    vs = String[]
    for arg in kwargs
        symbol = arg[1]
        value = arg[2]
        str = string(symbol)
        if !isa(value,  Array{String})
            str *= " ["
            str *= if value isa AbstractArray
                string(unit(value[1]))
            else
                string(unit(value))
            end
            str *= "]"
        end
        push!(vs, str)
    end
    vs
end

"""
    rounded_stripped(quantity, digits)
        --> Value of same numeric type as quantity
"""
function rounded_stripped(quantity, digits)
    rounded = if quantity isa  Quantity
        round(typeof(quantity), quantity, digits = digits)
    else
         round(quantity, digits = digits)
    end
    ustrip(rounded)
end
rounded_stripped(quantity::String, digits) = quantity


"""
    value_strings(n_rows, n_columns, digits = 2; kwargs...)
    --> Matrix{Union{Missing, String}}

Integer values won't be affected by rounding to digits.
"""
function value_strings(n_rows, n_columns, digits = 2; kwargs...)
    ms = Matrix{Union{Missing, String}}(missing, n_rows, n_columns)
    for col in 1:n_columns
        ve = kwargs[col]
        for row in 1:n_rows
            q = ve[row]
            v = rounded_stripped(q, digits)
            ms[row, col] = string(v)
        end
    end
    ms
end

"Pixel width using current settings"
pixelwidth(s::String) = textextents(s)[3]

"""
    column_widths(;kwargs...)
    --> ['pixel width']
Based on header text widths with two spaces padding on both sides
"""
column_widths(;kwargs...) = map(pixelwidth, header_strings(;kwargs...) .* "   ")


"""
    row_height()
    --> 'Pixel' height of one row
"""
row_height() = textextents("|")[4]

"""
    value_rows(;kwargs...)
    --> number of value rows in table
"""
function value_rows(;kwargs...)
    vs = Int64[]
    for (_, value) in kwargs
        s = if value isa AbstractArray
            size(value)[1]
        else
            1
        end
        push!(vs, s)
    end
    maximum(vs)
end

"Number of columns"
t_cols(;kwargs...) = length(header_strings(; kwargs...))

"""
    draw_header(pos::Point, pixel_widths, hdrs)
    -> positions of potentially next column
Each header centered to corresponding pixel_widths
"""
function draw_header(pos::Point, pixel_widths, hdrs)
    p = pos
    for (i, hdr) in enumerate(hdrs)
        # Center header
        columnpixelwidth = pixel_widths[i]
        phdr = pixelwidth(hdr)
        Δpx =  (columnpixelwidth - phdr) /2
        #= debug line
        line(p, p + (0, -row_height()), :stroke)
        =#
        text(hdr, p + (Δpx, 0))
        p += (columnpixelwidth, 0.0)
    end
    p
end

"""
    draw_values(pos, rows, pixel_widths; kwargs...)
    -> Array{String}
"""
function draw_values(pos, rows, pixel_widths; kwargs...)
    strs_including_missing = value_strings(rows, length(pixel_widths); kwargs...)
    strs = map(s-> ismissing(s) ? "" : String(s), strs_including_missing)
    strs_before_dot = map(stupl-> stupl[1], splitext.(strs))
    colpos = 0.0
    for col in 1:length(pixel_widths)
        rowpos = 0.0
        columnpixelwidth = pixel_widths[col]
        maxpixelwidth = maximum(pixelwidth, strs[:, col])
        maxleadingpixelwidth = maximum(pixelwidth, strs_before_dot[:, col])
        maxtrailingpixelwidth = maxpixelwidth - maxleadingpixelwidth
        sumpixelwidth = maxleadingpixelwidth + maxtrailingpixelwidth
        # If there are no dots, reldotpos = 1.
        # If there are no digits before any of the values, reldotpos = 0,
        # but that would require no leading digits.
        reldotpos = maxleadingpixelwidth / sumpixelwidth
        Δpx_textbox = (columnpixelwidth - sumpixelwidth) / 2
        for row in 1:rows
            rowpos += row_height()
            p = pos + (colpos, rowpos)
            s = strs[row, col]
            # Find offset for centering within sumpixelwidth
            sleading = strs_before_dot[row, col]
            ps = pixelwidth(s)
            psleading = pixelwidth(sleading)
            Δpx_sumpixelwidth = sumpixelwidth * reldotpos - psleading
            # For the column contents, we don't use settext. Consider using Luxor's Table for text tables.
            text(s, p + (Δpx_textbox + 1.0* Δpx_sumpixelwidth, 0))
            #= debug lines
            line(p, p + (Δpx_textbox, -row_height()), :stroke)
            line(p + (columnpixelwidth, 0), p + (Δpx_textbox + sumpixelwidth, -row_height()), :stroke)
            =#
        end
        colpos += columnpixelwidth
    end
    strs
end

"""
    text_table(pos::Point; kwargs...)
    -> Array{String, 2}, text output without alignmnent
"""
function text_table(pos::Point; kwargs...)
    pixel_widths = column_widths(;kwargs...)
    valrows = value_rows(;kwargs...)
    cols = t_cols(;kwargs...)
    hdrs = header_strings(;kwargs...)
    draw_header(pos, pixel_widths, hdrs)
    pos += (0.0, row_height())
    vcat(reshape(hdrs,1,:), draw_values(pos, valrows, pixel_widths; kwargs...))
end
"""
   settext_centered_above_with_markup(str, pos::Point)

The string can include Pango-style mark-up. Line break: \r, otherwise html-like
"""
function settext_centered_above_with_markup(str, pos::Point)
    pixel_width = pixelwidth(str)
    settext(str, pos + (-pixelwidth(str) / 2, 0), markup = true)
end