using MechanicalSketch
import MechanicalSketch: sethue, background, O, EM, m, color_with_lumin, settext
import MechanicalSketch: mm, arrow, HE, @layer, setdash, line, setopacity
import MechanicalSketch: empty_figure, PALETTE, dimension_aligned

let
empty_figure(joinpath(@__DIR__, "test_5.png"))
background(color_with_lumin(PALETTE[6], 30))
@layer begin
  sethue("black")
  setopacity(0.5)
  dimension_aligned(O + (15.0, 0.0)m, O + (15.0, 10.0)m )
  setdash("longdashed")
  for y in range(-7.0m, 7.0m, step = 1.0m)
    line(O + (0.0m, y), O + (7.5m, y), :stroke)
    if iseven(round(Int,  y / 1.0m))
        settext("<sub>$y</sub>", O + (0.0m, y), markup = true)
    end
  end
  for x in range(0.0m, 7.0m, step = 1.0m)
    line(O + (x, -7.5m), O + (x, 7.5m), :stroke)
  end
  setdash("solid")
  setopacity(1.0)
  arrow(O, O + (1.0, 0.0)m)
  arrow(O, O + (0.0, 1.0)m)
end
sethue(PALETTE[3])


Δx, Δy = 5.0m, 0.0m
textoffset = (-14.5m, 0.0m )

from = (0.0m, 6.0m)
to = from + (Δx, Δy)
dimension_aligned(O + from, O + to)
str = "dimension_aligned(O + $from, O + $to )"
settext("<small>" * str  * "</small>", O + from + textoffset, markup = true)


from += (0.0m, -1.0m)
to = from + (Δx, Δy)
dimension_aligned(O + from, O + to, offset = 0)
str = "dimension_aligned(O + $from, O + $to , offset = 0)"
settext("<small>" * str  * "</small>", O + from + textoffset, markup = true)

from += (0.0m, -3.0m)
to = from + (Δx, Δy)
dimension_aligned(O + from, O + to, offset = -EM)
str = "dimension_aligned(O + $from, O + $to , offset = -EM)"
settext("<small>" * str  * "</small>", O + from + textoffset, markup = true)

from += (0.0m, -3.0m)
Δy = -1.0m
to = from + (Δx, Δy)
dimension_aligned(O + from, O + to, offset = -EM)
str = "dimension_aligned(O + $from, O + $to , offset = -EM)"
settext("<small>" * str  * "</small>", O + from + textoffset, markup = true)

from += (0.0m, -4.0m)
Δy = -1.0m
to = from + (Δx, Δy)
dimension_aligned(O + from, O + to, offset = -EM,
       fromextension = (0.0, 1EM), toextension = (2EM, 3EM),
       unit = mm, digits = 0)
str = "dimension_aligned(O + $from, O + $to , offset = -EM)
    fromextension = (0.0, 1EM), toextension = (2EM, 3EM),
    unit = mm, digits = 0)"
settext("<small>" * str  * "</small>", O + from + textoffset, markup = true)


MechanicalSketch.finish()
end