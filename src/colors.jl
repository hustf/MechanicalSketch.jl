"""
    color_from_palette(colordescription::String) -> RGB

Pick a similar color to str from within PALETTE. Use for sethue, setbackground
Look for color descriptions in http://juliagraphics.github.io/Colors.jl/stable/namedcolors/#
"""
color_from_palette(colordescription::String) = get(PALETTE, getinverse(PALETTE, parse(RGB, colordescription)))


"The L in HSL is not a good indicator for distinguishing between perceived lightness.
This may provide a better parameter for finding contrasting colors"
function lumin2(colo)
    @warn "lumin2 deprecated"
    c = RGB(colo)
    r, g, b = c.r, c.g, c.b
    γ = 2.2
    0.2126 * r^γ + 0.7152 * g^γ + 0.0722 * b^γ
end

#=
luminance(colo) = begin
    @warn "luminance deprecated"
    HSL(colo).l
end

"""
color_with_luminance(color::T, luminance::Float64) where T
        -> T
"""
function color_with_luminance(color::T, luminance::Float64) where T
    @warn "color_with_luminance deprecated"
    c = HSLA(color)
    T( HSLA(c.h, c.s, luminance, c.alpha)  )
end
=#


get_current_RGB() = RGB(get_current_redvalue(), get_current_greenvalue(), get_current_bluevalue())
get_current_RGBA() = RGBA(get_current_redvalue(), get_current_greenvalue(), get_current_bluevalue(), get_current_alpha())

get_current_lumin2() = begin
    @warn "lumin2 deprecated"
    lumin2(get_current_RGB())
end
get_current_lumin() = lumin(get_current_RGB())


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
    color_with_lumin(col, lumin)
Convert the color to have 'luminosity' or similar term, depending on the type of color.
"""
function color_with_lumin(c::C, lumin) where C<:Union{LCHab, LCHuv}
    C(lumin, comp2(c), comp3(c))
end
function color_with_lumin(c::C, lumin) where C<:Union{HSV, HSL}
    C(comp1(c), comp2(c), lumin)
end
function color_with_lumin(c::C, lumin) where C<:Union{LCHabA, LCHuvA}
    C(lumin, comp2(c), comp3(c), comp4(c))
end
function color_with_lumin(c::C, lumin) where C<:Union{HSVA, HSLA}
    C(comp1(c), comp2(c), lumin, comp4(c))
end
function color_with_lumin(c::RGB, lumin)
    convert(RGB, color_with_lumin(convert(LCHuv ,c), lumin))
end
function color_with_lumin(c::RGBA, lumin)
    convert(RGBA, color_with_lumin(convert(LCHuvA ,c), lumin))
end
"""
    lumin(c)

Return luminosity or similar term, depending on color type
"""
function lumin(c::C) where C<:Union{LCHab, LCHuv, LCHabA, LCHuvA}
    comp1(c)
end
function lumin(c::C) where C<:Union{HSV, HSL, HSVA, HSLA}
    comp3(c)
end
function lumin(c::RGB)
    lumin(convert(LCHuv, c))
end
function lumin(c::RGBA)
    lumin(convert(LCHuvA, c))
end




"""
    color_with_hue(col, hue::Angle)
Convert the color to have cylindrical hue.
"""
function color_with_hue(c::C, hue::Angle) where C<:Union{LCHab, LCHuv}
    C(comp1(c), comp2(c), typeof(comp1(c))(hue / °))
end
function color_with_hue(c::C, hue::Angle) where C<:Union{LCHabA, LCHuvA}
    C(comp1(c), comp2(c), typeof(comp1(c))(hue / °), comp4(c))
end

function color_with_hue(c::C, hue::Angle) where C<:Union{HSV, HSL}
    C(typeof(comp1(c))(hue / °), comp2(c), comp3(c))
end
function color_with_hue(c::C, hue::Angle) where C<:Union{HSVA, HSLA}
    C(typeof(comp1(c))(hue / °), comp2(c), comp3(c),  comp4(c))
end

function color_with_hue(c::RGB, hue::Angle)
    convert(RGB, color_with_hue(convert(LCHuv, c), hue ))
end
function color_with_hue(c::RGBA, hue::Angle)
    convert(RGBA, color_with_hue(convert(LCHuvA, c), hue ))
end

"""
    hue(c)
    
Return angular hue or similar term, depending on color type
"""
function hue(c::C) where C<:Union{LCHab, LCHuv, LCHabA, LCHuvA}
    comp3(c)°
end
function hue(c::C) where C<:Union{HSV, HSL, HSVA, HSLA}
    comp1(c)°
end
function hue(c::RGB)
    hue(convert(LCHuv, c))
end
function hue(c::RGBA)
    hue(convert(LCHuvA, c))
end


"""
    rotate_hue(c, angle::Angle)

In cylindrical colorspace, rotation of hue gives
continuous variation while not chaninging chroma (or similar term) 
or perceptual luminance (or similar term).
"""
function rotate_hue(c, ang::Angle)
    modhue = mod(hue(c) + ang , 360°)
    color_with_hue(c, modhue)
end

"""
    color_with_alpha(col, alpha)

Convert col to a color with transparency alpha.
"""
color_with_alpha(col, alpha) = Luxor.coloralpha(col, alpha)

"""
    color_without_alpha(c)

Convert col to a color type without transparency.
"""
color_without_alpha(c::HSVA) = convert(HSV, c)
color_without_alpha(c::HSV) = c

color_without_alpha(c::HSLA) = convert(HSL, c)
color_without_alpha(c::HSL) = c

color_without_alpha(c::LCHabA) = convert(LCHab, c)
color_without_alpha(c::LCHab) = c

color_without_alpha(c::LCHuvA) = convert(LCHuv, c)
color_without_alpha(c::LCHuv) = c

color_without_alpha(c::RGBA) = convert(RGB, c)
color_without_alpha(c::RGB) = c

"""
    chroma(c)
    
Return chroma or similar term, depending on color type
"""
function chroma(c::C) where C<:Union{LCHab, LCHuv, LCHabA, LCHuvA}
    comp2(c)
end
function chroma(c::C) where C<:Union{HSV, HSL, HSVA, HSLA, RGB, RGBA}
    chroma(convert(LCHuv, c))
end

"""
    saturation(c)
    
Return chroma or similar term, depending on color type
"""
function saturation(c::C) where C<:Union{LCHab, LCHuv, LCHabA, LCHuvA, RGB, RGBA}
    saturation(convert(HSV, c))
end
function saturation(c::C) where C<:Union{HSV, HSL, HSVA, HSLA}
    comp2(c)
end

"""
    color_with_saturation(col, saturation)
Modify saturation.
"""
function color_with_saturation(c::C, saturation) where C<:Union{LCHab, LCHuv, RGB}
    convert(C, color_with_saturation(convert(HSV, c), saturation ))
end
function color_with_saturation(c::C, saturation) where C<:Union{LCHabA, LCHuvA, RGBA}
    convert(C, color_with_saturation(convert(HSVA, c), saturation ))
end
function color_with_saturation(c::C, saturation) where C<:Union{HSV, HSL}
    C(comp1(c), saturation, comp3(c))
end
function color_with_saturation(c::C, saturation) where C<:Union{HSVA, HSLA}
    C(comp1(c), saturation, comp3(c), comp4(c))
end


# This definition don't really belong anywhere. ColorSchemes is mostly a complete library, but this is useful and missing.
const ColSchemeNoMiddle = ColorSchemes.ColorScheme(SVector([[get(PuOr_8, x, :clamp) for x in range(0, 0.3, length = 10)];
    [get(PuOr_8, 1 - x, :clamp) for x in range(0.3, 0, length = 11)]]...), "MechanicalSketch", "emphasize plus / minus")