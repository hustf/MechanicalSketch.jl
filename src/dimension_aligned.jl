"""
dimension_aligned(p1::Point, p2::Point; fromextension = (0.3*EM, 2EM),
                         toextension = (0.3*EM, 2EM),
                         offset = -4EM,
                         unit = m,
                         digits = 1)

        -> (distance in canvas units, dimension text)

offset is perpendicular to line between points. The vertical axis for offset is positive downwards.
fromextension describes the p1 line in offset direction.
toextension describes the p2 line in offset direction.
units (m or mm) can be extended by importing types from MechanicalUnits
digits: e.g. 2 digits: 12.34m
"""
function dimension_aligned(p1::Point, p2::Point;
    offset = -4EM,
    fromextension = (0.3EM, 2EM),
    toextension = (0.3EM, 2EM),
    unit = m,
    digits = 1)
    # capture unit and digits, so we can pass a one-parameter function
    function distancestring(val)
        string(if digits == 0
                rounded =
                unit * Int(ustrip(round(unit, val * scale_pt_to_unit(m))))
            else
                round(unit, val * scale_pt_to_unit(m); digits = digits)
            end)
    end

    Luxor.dimension(
        p1,
        p2,
        format = distancestring,
        offset             = offset,
        fromextension      = fromextension,    # length of extensions lines left and right
        toextension        = toextension ,     #
        textverticaloffset = 0,                # actually horizontal, range 1.0 (right) to -1.0 (left)
        texthorizontaloffset = -0.7*EM ,       # actually vertical, normal units
        textgap            = 0.0,              # gap between start of each arrow (≈ fontsize?), can't be zero
        textrotation       = -π / 2,           # Default is vertical
        arrowlinewidth     = 0.5PT,
        arrowheadlength    = 0.5EM,
        arrowheadangle     = π/16)
end
