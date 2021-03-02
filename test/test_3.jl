using MechanicalSketch
import MechanicalSketch: Point, rect, arrow, line
import MechanicalSketch: EM, TXTOFFV, O, PT, Point, WI, HE
import MechanicalSketch: RGB, HSL, color_with_lumin, background, sethue, text, fontsize
import MechanicalSketch: settext, setfont, setopacity, FS, color_with_lumin, color_with_lumin2
import MechanicalSketch: empty_figure, PALETTE

let
    this_fig = empty_figure(joinpath(@__DIR__, "test_3.png"))
    typcol = MechanicalSketch.HSL(get(PALETTE, 0.9))
    bckcol = MechanicalSketch.RGB(MechanicalSketch.HSL(typcol.h, typcol.s, typcol.l * 0.5))
    background(bckcol)
    sethue("white")
    arrow(O, Point(0, -5EM) )
    arrow(O, Point(10EM, -2EM), arrowheadlength=EM, arrowheadangle = pi/12, linewidth = PT)
    arrow(O, Point(8EM, 0.5EM), arrowheadlength=EM, arrowheadangle = pi/12, linewidth = PT)

    # center, radius, start (cw), end(cw)
    setopacity(0.2)
    for (i, endang) in enumerate(-π:π/4:π)
    sethue(PALETTE[i])
    arrow(O, 8EM, π, endang, arrowheadlength = 2EM,   arrowheadangle=pi/12, linewidth = i *PT)
    end
    setopacity(1)
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

        text("lumin", Point(xs, 0))
        text("lumin2", Point(xs + dw /2, 0))
        for (j, lum) in enumerate(2:-0.1:0)
            curcol = PALETTE[i]
            # Left rectancle, simple luminance
            sethue(color_with_lumin(curcol, lum * 100))
            posy = j * 0.5 * EM
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
    MechanicalSketch.finish()
end