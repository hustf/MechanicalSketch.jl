"""
    foil_points_local(;l = CHORD_LENGTH_DEFAULT,
                                 t = THICKNESS_DEFAULT,
                                 c = CAMBER_DEFAULT)
    -> Vector{Points}

2d foil coordinates centered on 0.3·chord length from leading edge.
Default values produce output in units of length.
"""
function foil_points_local(;l = CHORD_LENGTH_DEFAULT,
                                 t = THICKNESS_DEFAULT,
                                 c = CAMBER_DEFAULT)
    # Positions along chord, one way
    px = l * (-CHORD_ZERO .+ FOIL_CHORD_POS)
    # Offset centre line
    Δy_0 = c * FOIL_CAMBER
    # Half thickness
    halft = t * FOIL_HALF_T
    # Suction side, starting at the trailing edge (useful for making a spline)
    px_s = reverse(px)
    py_s = reverse( Δy_0 + halft)
    # Pressure side, starting at the leading edge
    # (useful for making a spline which is sharp at the trailing edge)
    px_p = px
    py_p = Δy_0 - halft
    px_both = vcat(px_s, px_p)
    py_both = vcat(py_s, py_p)
    map(px_both .|> upreferred, py_both .|> upreferred) do x, y
        Point(x, y)
    end
end
"""
    foil_spline_local(;l = CHORD_LENGTH_DEFAULT,
                                 t = THICKNESS_DEFAULT,
                                 c = CAMBER_DEFAULT)
    -> 872-length Vector{Points}

2d foil spline centered on 0.3·chord length from leading edge.
Default values produce output in units of length.
"""
function foil_spline_local(;l = CHORD_LENGTH_DEFAULT,
                                 t = THICKNESS_DEFAULT,
                                 c = CAMBER_DEFAULT)
    polyfit(foil_points_local(;l = l, t = t, c = c))
end


"""
    foil_draw(p::Point ;
        α = 0°,
        rel_scale = 1,
        l = CHORD_LENGTH_DEFAULT,
        t = THICKNESS_DEFAULT,
        c = CAMBER_DEFAULT,
        backgroundcolor = colorant"white")
    -> a large array of points.
Draw an airfoil with the given parameters.

p is the position of the foil, cooresponding to the rough pressure centre and
centre of rotaion, at 0.3·chord from the leading edge.
"""
function foil_draw(p::Point ;
    α = 0°,
    rel_scale = 1,
    l = CHORD_LENGTH_DEFAULT,
    t = THICKNESS_DEFAULT,
    c = CAMBER_DEFAULT,
    backgroundcolor = colorant"white")
    f = foil_spline_local(l = rel_scale * l, t = rel_scale * t, c = rel_scale * c)
    polyrotate!(f, α)
    polymove!(f,  O, p)
    poly(f, :fill)
    luminback = luminance(backgroundcolor)
    luminfront = get_current_luminance()
    avglumin = (luminback + luminfront) / 2
    contrastcol = color_with_luminance(get_current_RGB(), avglumin)
    gsave()
    sethue(contrastcol)
    poly(f, :stroke)
    grestore()
    f
end
