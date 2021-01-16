"""
    rk4_step(f_xy, h, x, y)
    -> (x1, y1)
Returns coordinates (x1, y1) after one Runge-Kutta 4th order step.
        f is a tuple-valued gradient in two dimensions
        (x, y) is the starting point
        h is a step-size quantity. If the integration variable is time,
        it defines the length of time betweeen points. It can be negative.
"""
function rk4_step(f_xy, h, x, y)
    fx0, fy0 = f_xy(x, y)
    x1 = x + fx0 * h * 0.5
    y1 = y + fy0 * h * 0.5
    fx1, fy1 = f_xy(x1, y1)
    x2 = x + fx1 * h * 0.5
    y2 = y + fy1 * h * 0.5
    fx2, fy2  = f_xy(x2, y2)
    x3 = x + fx2 * h
    y3 = y + fy2 * h
    fx3, fy3 = f_xy(x3, y3)
    x +=  h * ( fx0  + 2∙fx1 + 2∙fx2 + fx3 ) / 6
    y +=  h * ( fy0  + 2∙fy1 + 2∙fy2 + fy3 ) / 6
    x, y
end
"""
    rk4_step!(f, vx, vy, h, n)

Coordinates (vx[n + 1], vy[n + 1]) are updated with the estimated position,
along function f.
        f is a tuple-valued gradient in two dimensions
        vx and vy are vectors representing coordinates like (vx[n], vy[n])
        h is a step-size quantity. If the integration variable is time,
        it defines the length of time betweeen points. It can be negative.
"""
function rk4_step!(f, vx, vy, h, n)
    fx0, fy0 = f(vx[n], vy[n])
    x1 = vx[n] + fx0 * h * 0.5
    y1 = vy[n] + fy0 * h * 0.5
    fx1, fy1 = f(x1, y1)
    x2 = vx[n] + fx1 * h * 0.5
    y2 = vy[n] + fy1 * h * 0.5
    fx2, fy2  = f(x2, y2)
    x3 = vx[n] + fx2 * h
    y3 = vy[n] + fy2 * h
    fx3, fy3 = f(x3, y3)
    vx[n + 1] = vx[n] + 1/6 * h * ( fx0  + 2∙fx1 + 2∙fx2 + fx3 )
    vy[n + 1] = vy[n] + 1/6 * h * ( fy0  + 2∙fy1 + 2∙fy2 + fy3 )
end

"""
    rk4_steps!(f, vx, vy, h)

Coordinates (vx[n > 1], vy[n > 1]) are updated with the estimated positions,
along function f.
     f(x,y) returns a tuple-valued gradient in two dimensions
     vx and vy are vectors representing coordinates like (vx[n], vy[n])
     h is a step-size quantity. If the integration variable is time,
     it defines the length of time betweeen points. It can be negative
"""
function rk4_steps!(f, vx, vy, h)
    @assert length(vx) == length(vy)
    if !isnan(f(vx[1], vy[1])[1])
        for n in 1:(length(vx) - 1)
            rk4_step!(f, vx, vy, h, n)
        end
    else
        fill!(vx, NaN * vx[1])
        fill!(vy, NaN * vy[1])
    end
    nothing
end