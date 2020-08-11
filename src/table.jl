

function header_strings(; kwargs...)
    vs = String[]
    for arg in kwargs
        symbol = arg[1]
        value = arg[2]
        str = string(symbol)
        str *= " ["
        
        str *= if value isa AbstractArray
            string(unit(value[1]))
        else
            string(unit(value))
        end
        str *= "]"
        push!(vs, str)
    end
    vs
end
function rounded_stripped(quantity, digits)
    rounded = round(typeof(quantity), quantity, digits = digits)
    ustrip(rounded)
end
function value_strings(rws, cls; kwargs...)
    ms = Matrix{Union{Missing, String}}(missing, rws, cls)
    for col in 1:cls
        ve = kwargs[col]
        for row in 1:rws
            q = ve[row]
            v = rounded_stripped(q, 2)
            ms[row, col] = string(v)
        end
    end
    ms
end

function column_widths(;kwargs...)
    hstr = header_strings(;kwargs...)
    map(hstr) do str
        x_bearing, y_bearing, twidth, theight, x_advance, y_advance = textextents(str * "   ")
        twidth
    end
end
function row_height()
    _, _, _, rowheight, _, _ = textextents("|")
    rowheight
end

function t_rows(;kwargs...) 
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


t_cols(;kwargs...) = length(header_strings(; kwargs...))
function draw_header(pos::Point, widths, hdrs)
    p = pos
    for (i, hdr) in enumerate(hdrs)
        text(hdr, p)
        p += (widths[i], 0.0)
    end
    p
end


function draw_values(pos, v_rows, widths; kwargs...)
    ms = value_strings(v_rows, length(widths); kwargs...)
    p = pos
    cp = 0.0
    @show ms, p, cp
    for col in 1:length(widths)
        rp = 0.0
        for row in 1:v_rows
            rp += row_height()
            p = pos + (cp, rp)
            s = ms[row, col]
            text(s, p)
        end
        cp += widths[col]
    end
    ms
end
function text_table(pos::Point; kwargs...)
    widths = column_widths(;kwargs...)
    v_rows = t_rows(;kwargs...)
    cols = t_cols(;kwargs...)
    hdrs = header_strings(;kwargs...)
    draw_header(pos, widths, hdrs)
    pos += row_height()
    draw_values(pos, v_rows, widths; kwargs...)
end
