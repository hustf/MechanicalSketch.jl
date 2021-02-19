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