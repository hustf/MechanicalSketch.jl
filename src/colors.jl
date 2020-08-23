"""
    color_from_palette(colordescription::String) -> RGB

Pick a similar color to str from within PALETTE. Use for sethue, setbackground
Look for color descriptions in http://juliagraphics.github.io/Colors.jl/stable/namedcolors/#
"""
color_from_palette(colordescription::String) = get(PALETTE, getinverse(PALETTE, parse(RGB, colordescription)))


"The L in HSL is not a good indicator for distinguishing between perceived lightness.
This may provide a better parameter for finding contrasting colors"
function lumin2(colo)
    c = RGB(colo)
    r, g, b = c.r, c.g, c.b
    γ = 2.2
    0.2126 * r^γ + 0.7152 * g^γ + 0.0722 * b^γ
end

"The L in HSL."
luminance(colo) = HSL(colo).l

get_current_RGB() = RGB(get_current_redvalue(), get_current_greenvalue(), get_current_bluevalue())
get_current_lumin2() = lumin2(get_current_RGB())
get_current_luminance() = luminance(get_current_RGB())


"""
color_with_lumin2(color::T, luminance::Float64) where T
        -> T
The name of this function is somewhat illogical, consider removing. Generally
use the LCHuv colorspace to modify luminance of a color.
"""
function color_with_lumin2(color::T, lumin2::Float64) where T
    c = RGBA(color)
    r, g, b, a = c.r, c.g, c.b, c.alpha
    γ = 2.2
    lr, lg, lb = 0.2126 * r^γ , 0.7152 * g^γ , 0.0722 * b^γ
    l = lr + lg + lb
    lr1, lg1, lb1 = (lumin2 / l ) .* (lr, lg, lb)
    r1, g1, b1 = (0.2126 / lr1)^(-1/γ), (0.7152/lg1)^(-1/γ), (0.0722/lb1)^(-1/γ)
    T(RGBA(r1, g1, b1, a))
end

"""
color_with_luminance(color::T, luminance::Float64) where T
        -> T

"""
function color_with_luminance(color::T, luminance::Float64) where T
    c = HSLA(color)
    T( HSLA(c.h, c.s, luminance, c.alpha)  )
end

"""
    rotate_hue(colo::RGB, angle::Angle) -> RGB

In the luminance-chroma-hue cylindrical colorspace, rotation of hue gives
continuous variation while not chaninging chroma or perceptual luminance.
"""
function rotate_hue(col::RGB, ang::Angle)
    if col != RGB(0.0, 0.0, 0.0)
        lchuv = convert(Colors. LCHuv, col)
        modhue = mod(lchuv.h + ang / °, 360.0)
        lchuvmod = Colors.LCHuv(lchuv.l, lchuv.c, modhue)
        convert(Colors.RGB, lchuvmod)
    else
        col
    end
end