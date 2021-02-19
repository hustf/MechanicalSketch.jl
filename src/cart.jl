Turn(t::Turtle, r::Angle) = Turn(t, upreferred(-r / 1°))
Orientation(t::Turtle, r::Angle) = Orientation(t, upreferred(-r / 1°))
Circle(t::Turtle, radius::Length) = Circle(t, get_scale_sketch(r))
Forward(t::Turtle, d::Length) = Forward(t, get_scale_sketch(d))


"""
    drawcart(p = O, α = 0°, l = 2m, w = 1m, d = 0.5m, tf = 0.2)

Using turtle graphics, draw the outline of a cart, centered on p
(default is origo) and rotated by α. The outline is symmetrical arond two axes.
"""
function drawcart(;p = O, α = 0°, l = 2m, w = 2m / 1.618034, d = 0.5m, tf = 0.2)
    t = Turtle()
    Pencolor(t, get_current_RGB())
    Reposition(t, p)
    Orientation(t, α)
    Penup(t)
    Forward(t, -l /2)
    Turn(t, -90°)
    Pendown(t)
    # Draw one side, then the next.
    for i = 1:2
        Forward(t, w / 2)
        # Turn back to axle
        Turn(t, 90°)
        Forward(t, d / 2)
        # Axle
        Turn(t, -90°)
        Forward(t, d * tf)
        Turn(t, -90°)
        #Wheel
        Forward(t, d /2)
        Turn(t, 90°)
        Forward(t, d * tf)
        Turn(t, 90°)
        Forward(t, d )
        Turn(t, 90°)
        Forward(t, d * tf )
        Turn(t, 90°)
        Forward(t, d / 2)
        # Axle again
        Turn(t, -90°)
        Forward(t, d * tf)
        Turn(t, -90°)
        # Side
        Forward(t, l / 2 - d / 2)
        # Now we should have been able to mirror, but we can't.
        Forward(t, l / 2 - d / 2)
        # Axle
        Turn(t, -90°)
        Forward(t, d * tf)
        Turn(t, -90°)
        #Wheel
        Forward(t, d /2)
        Turn(t, 90°)
        Forward(t, d * tf)
        Turn(t, 90°)
        Forward(t, d )
        Turn(t, 90°)
        Forward(t, d * tf )
        Turn(t, 90°)
        Forward(t, d / 2)
        # Axle again
        Turn(t, -90°)
        Forward(t, d * tf)
        Turn(t, -90°)
        # Side to rear
        Forward(t, d / 2)
        Turn(t, 90°)
        Forward(t, w / 2)
    end
end
