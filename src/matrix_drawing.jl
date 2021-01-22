
"""
    bresenhams_line_algorithm(maxx, maxy, x1, y1, x2, y2)

maxx, maxy: Integer max values

Assuming x1 and x2 are coordinates > 0.5, return integer coordinates between the two coordinates.

x1 to y2 may be floats, but this is intended to be 'floating point indexes' in a matrix.

Based on
https://stackoverflow.com/questions/40273880/draw-a-line-between-two-pixels-on-a-grayscale-image-in-julia

Adapted for float input arguments and limit checks.
"""
function bresenhams_line_algorithm(maxx::T, maxy::T, x1, y1, x2, y2) where {T<:Int}
    @assert round(Int, x1) <= maxx
    @assert round(Int, y1) <= maxy
    @assert round(Int, x1) >= 1
    @assert round(Int, y1) >= 1
    @assert round(Int, x2) <= maxx
    @assert round(Int, y2) <= maxy
    @assert round(Int, x2) >= 1
    @assert round(Int, y2) >= 1

    # Calculate distances
    dx = x2 - x1
    dy = y2 - y1

    # Determine how steep the line is
    is_steep = abs(dy) > abs(dx)

    # Rotate line
    if is_steep
        x1, y1 = y1, x1
        x2, y2 = y2, x2
        maxy, maxx = maxx, maxy
    end

    # Swap start and end points if necessary and store swap state
    swapped = if x1 > x2
        x1, x2 = x2, x1
        y1, y2 = y2, y1
        true
    else
        false
    end

    # Recalculate differentials
    dx = x2 - x1
    dy = y2 - y1

    # Calculate error
    error = round(Int, dx / 2.0)

    ystep = if y1 < y2
        1
    else
        -1
    end

    vy = Vector{Int}()

    # Iterate while generating points between start and end
    y = round(Int, y1)
    xiter = round(Int, x1):(round(Int, x2))
    for x in xiter
        push!(vy, y)
        error -= abs(dy)
        if error < 0
            y += ystep
            # edge case, a subpixel line might cover two pixels due to rounding.
            # However, if that happens to be on the edge, don't bleed over and don't cause an
            # error throw.
            if y > maxy || y < 1
                y -= ystep
                error -= dx
            end
            error += dx
        end
    end
    # Reverse the list if the coordinates were swapped
    if swapped
        if is_steep
            zip(reverse(vy), reverse(xiter))
        else
            zip(reverse(xiter), reverse(vy))
        end
    else
        if is_steep
            zip(vy, xiter)
        else
            zip(xiter, vy)
        end
    end
end

"""
    crossing_line_algorithm(maxx, maxy, cx, cy)

maxx, maxy: Integer max values

Return indices for pixels in a 10x10 to 11x11 cross centered at cx, cy

cx, cy may be floats, but this is intended to be 'floating point indexes' in a matrix.
"""

function crossing_line_algorithm(maxx::T, maxy::T, cx, cy) where T<:Int
    indices = Set{Tuple{Int64, Int64}}()
    d = 5
    xb = clamp(cx - d, 1, maxx)
    xt = clamp(cx + d, 1, maxx)
    yb = clamp(cy - d, 1, maxy)
    yt = clamp(cy + d, 1, maxy)
    lineindices = bresenhams_line_algorithm( maxx, maxy, xt, yb, xb, yt)
    push!(indices, lineindices...)
    lineindices = bresenhams_line_algorithm( maxx, maxy, xb, yb, xt, yt)
    push!(indices, lineindices...)
    indices
end

"""
    box_line_algorithm(maxx, maxy, cx, cy)

maxx, maxy: Integer max values

Return indices for pixels in a 10x10 to 11x11 cross centered at cx, cy

cx, cy may be floats, but this is intended to be 'floating point indexes' in a matrix.
"""

function box_line_algorithm(maxx::T, maxy::T, cx, cy) where T<:Int
    indices = Set{Tuple{Int64, Int64}}()
    d = 5
    xb = clamp(cx - d, 1, maxx)
    xt = clamp(cx + d, 1, maxx)
    yb = clamp(cy - d, 1, maxy)
    yt = clamp(cy + d, 1, maxy)
    lineindices = bresenhams_line_algorithm( maxx, maxy, xt, yb, xb, yb)
    push!(indices, lineindices...)
    lineindices = bresenhams_line_algorithm( maxx, maxy, xt, yt, xb, yt)
    push!(indices, lineindices...)
    lineindices = bresenhams_line_algorithm( maxx, maxy, xt, yb, xt, yt)
    push!(indices, lineindices...)
    lineindices = bresenhams_line_algorithm( maxx, maxy, xb, yb, xb, yt)
    push!(indices, lineindices...)
    indices
end


"""
    circle_algorithm(maxx, maxy, cx, cy)

maxx, maxy: Integer max values

Return indices for pixels in a 10 pixel diameter circle centered at cx, cy

cx, cy may be floats, but this is intended to be 'floating point indexes' in a matrix.
"""
function circle_algorithm(maxx::T, maxy::T, cx, cy) where T<:Int
    indices = Set{Tuple{Int64, Int64}}()
    d = 10
    pts = 2 * round(Int, π * d)
    for ϕ in range(0.0, 2π, length = pts)
        x = clamp(round(Int, cx + d * cos(ϕ) / 2), 1, maxx)
        y = clamp(round(Int, cy + d * cos(ϕ) / 2), 1, maxy)
        push!(indices, (x, y))
    end
    indices
end