using MechanicalSketch
import MechanicalSketch: Point, rect, arrow, line
import MechanicalSketch: EM, TXTOFFV, O, PT, Point, WI, HE
import MechanicalSketch: RGB, HSL, color_with_lumin, background, sethue, text, fontsize
import MechanicalSketch: settext, setfont, setopacity, FS, color_with_lumin, color_with_lumin2
import MechanicalSketch: empty_figure, PALETTE, finish, paint, ∙
import MechanicalSketch: transform, @layer, do_action, getmatrix, grestore, gsave, scale
import MechanicalSketch: box_fill_outline, label, row_height, pixelwidth, @import_expand
import MechanicalSketch: scale_pt_to_unit, lumin, label_boxed
if !@isdefined °
    @import_expand ~m # Will error if m² already is in the namespace
    @import_expand s
    @import_expand °
    @import_expand rad
end
#let
    typcol = PALETTE[9];
    bckcol = color_with_lumin(typcol, 0.5 * lumin(typcol))
    empty_figure(joinpath(@__DIR__, "test_3.png");
        backgroundcolor = bckcol, hue = "white")

    # Straight arrow width
    pt = O + ( -6EM, 2EM)
    arrow(pt, pt + (0, -5EM) )
    arrow(pt, pt + (10EM, -2EM), arrowheadlength=EM, arrowheadangle = pi/12, linewidth = PT)
    arrow(pt, pt + (8EM, 0.5EM), arrowheadlength=EM, arrowheadangle = pi/12, linewidth = PT)

    # Palette
    ncol = length(PALETTE)
    dw =  WI / ncol
    for i = 1:ncol
        posy = -HE/2
        curcol = PALETTE[i]
        sethue(curcol)
        xs = -WI/2 + (i-1) * dw
        ps = Point(xs, posy)
        rect( ps, dw, EM, :fill)
        sethue("white")
        fontsize(FS)
        text("$i L= $(round(HSL(curcol).l, digits = 2))",
                    ps + (0, EM - TXTOFFV))
        fontsize(FS/2)
        setfont("Calibri", FS / 2)
        posy = HE / 2 - 22 * 0.5 * EM
        text("lumin", Point(xs, posy))
        text("lumin2", Point(xs + dw /2, posy))
        for (j, lum) in enumerate(2:-0.1:0)
            curcol = PALETTE[i]
            # Left rectancle, simple luminance
            sethue(color_with_lumin(curcol, lum * 100))
            posy += 0.5 * EM
            ps = Point(xs, posy)
            rect( ps , dw / 2 , EM / 2 , :fill)
            str = string(round(lum, digits = 2))
            sethue("black")
            text(str,  ps + (0, -TXTOFFV + 0.5 *EM) )
            sethue("white")
            text(str,  ps + (dw / 4, -TXTOFFV + 0.5 *EM) )
            # Right rectangle, lumin2
            sethue(color_with_lumin2(curcol, lum * 2))
            rect(ps + (dw/2, 0), dw / 2, EM /2, :fill)
            sethue("black")
            settext("<b>" * str * "</b>",
                    ps + (dw/2, -TXTOFFV + 0.6 *EM) , markup=true)
            sethue("white")
            settext("<b>" * str * "</b>",
                        ps + (dw/2 + dw/ 4, -TXTOFFV + 0.6 *EM) , markup=true)
        end
    end
    # Arc arrows, left screen
    sethue(PALETTE[3])
    y = -HE / 4 + 0EM
    x = - WI / 3
    cpl = O + (x, y)
    text("Unitless angles: Always clockwise", cpl + (0, EM), halign = :center)
    startangle = 0.0
    iter  = enumerate(range(-π , π, step = π / 4))
    for (i, endangle) in iter
        # center, radius, start (cw), end(cw)
        radius = (3 + i / 4 )EM
        arrow(cpl, radius, startangle, endangle;
               arrowheadlength = EM, arrowheadangle = pi / 12, linewidth = 2PT)
    end
    for (i, endangle) in iter
        radius = (3 + i / 4 )EM
        str = "$(round(startangle / π; digits = 2)) to $(round(endangle / π; digits = 2))∙π"
        endpoint = cpl + radius .* (cos(endangle), sin(endangle))
        label_boxed(endpoint, str)
    end

    # Arc arrows with units, mid-screen
    cpm = O + (0, y)
    text("Uniful angles, specified clockwise", cpm + (0, EM), halign = :center)
    startangle = 0.0∙rad
    iter  = enumerate(range(-π, π, step = π / 4)∙rad)
    rdeg(a) = round(°, a; digits = 0) |> typeof(1°)
    for (i, endangle) in iter
        radius = (3 + i / 4 )EM * scale_pt_to_unit(m)
        arrow(cpm, radius, startangle, endangle;
              arrowheadlength = EM, arrowheadangle = pi / 12, linewidth = 2PT, clockwise = true)
    end
    for (i, endangle) in iter
        radius = (3 + i / 4 )EM
        str = "$(rdeg(startangle)) to $(rdeg(endangle))"
        endpoint = cpm + radius .* (cos(endangle), -sin(endangle))
        label_boxed(endpoint, str)
    end

    # Arc arrows with units, right-screen
    cpr = O + (-x, y)
    text("Uniful angles, default counterclockwise", cpr + (0, EM), halign = :center)
    startangle = 0.0∙rad
    iter  = enumerate(range(-π, π, step = π / 4)∙rad)
    rdeg(a) = round(°, a; digits = 0) |> typeof(1°)
    for (i, endangle) in iter
        radius = (3 + i / 4 )EM * scale_pt_to_unit(m)
        arrow(cpr, radius, startangle, endangle;
              arrowheadlength = EM, arrowheadangle = pi / 12, linewidth = 2PT)
    end
    for (i, endangle) in iter
        radius = (3 + i / 4 )EM
        str = "$(rdeg(startangle)) to $(rdeg(endangle))"
        endpoint = cpr + radius .* (cos(endangle), -sin(endangle))
        label_boxed(endpoint, str)
    end


    finish()

#end