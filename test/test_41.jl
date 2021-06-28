#= ForwardDiff is removed as a dependency from this version
using Revise
import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, PT, FS, finish
import MechanicalSketch: settext, place_image, PALETTE, color_with_lumin, circle, line
import MechanicalSketch: circle, ∙, arrow_nofill, Point, @layer, sethue, draw_expr
import MechanicalSketch: latexify, arrow, Quantity, readsvg, unit, ustrip
import MechanicalSketch: ForwardDiff, box_fill_outline, brush, setopacity
import MechanicalSketch: @ev_draw, rotate_hue, setline
import MechanicalSketch: Drawing, configure_mechanical, preview
import MechanicalSketch: Luxor
import Luxor:            CairoContext, CairoRecordingSurface, flush, set_source
import Luxor:            paint, getmatrix, setmatrix, currentpoint, get_current_cr
import Luxor:            current_surface_type, CURRENTDRAWING
import Luxor.Cairo:      device_get_type, flush

if !@isdefined N
    @import_expand(~m, ~s, °, N)
end

"""
    make_recording_surface_drawing()
    --> Luxor.Drawing

This makes, then mutates a Luxor drawing to allow
a special type of Cairo surface.
"""
function make_recording_surface_drawing()
    d = Drawing(WI, HE, :svg)
    s1 = CairoRecordingSurface()
    c1 = CairoContext(s1)
    d.surface = s1
    d.cr = c1
    configure_mechanical()
    d
end

"""
    snapshot_of_working_surface(fnam)

Takes a snapshot and saves to file with 'fnam' name and suffix.
One could continue drawing, or do the other things.
"""
function snapshot_of_working_surface(fnam)
    drec = currentdrawing()
    @assert typeof(drec.surface)
    flush(drec.surface)
    d = empty_figure(fnam)
    d.width = drec.width
    d.height = drec.height
    d.redvalue = drec.redvalue
    d.greenvalue = drec.greenvalue
    d.bluevalue = drec.bluevalue
    d.alpha = drec.alpha
    set_source(d.cr, drec.surface, -WI / 2, -HE / 2)
    paint()
    finish()
    CURRENTDRAWING[1] = drec
end

make_recording_surface_drawing()

for r = 1m:0.2m:60m
   α = 360.0° * (r / 20m)
   circle(O + 100 .* (cos(α), sin(α)); r)
   setline(8)
   sethue(rotate_hue(PALETTE[5], α))
   settext(string(r), Point(0m, r))
end
snapshotrecordingsurface("snap1.png")
for r = 1m:0.2m:60m
    α = 360.0° * (r / 20m)
    circle(O + 100 .* (cos(-α), sin(α)); r)
    setline(8)
    sethue(rotate_hue(PALETTE[3], α))
    settext(string(r), Point(0m, r))
 end
 snap2 = snapshotrecordingsurface(drec)
#snap1 = snapshotrecordingsurface(drec)
#circle(O + (3m, 0m), r = 5m)
#snap2 = snapshotrecordingsurface(drec)


=#
