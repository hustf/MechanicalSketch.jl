"""
    _CairoSurfaceBase(colmat::VecOrMat{T}) where T

Convert a matrix or vector to a cairo surface suitable for ´placeimage´.
One pixel per element.

"""
function _CairoSurfaceBase(colmat::VecOrMat{T}) where T
    msg = "Can't display matrices of eltype($(eltype(colmat))). \n\tConsider defining a subtypes(AbstractColorLegend) to convert."
    @assert T <: Union{RGB, RGBA, Luxor.Cairo.ARGB32, HSV, HSVA,  HSL, HSLA,LCHab, LCHabA, LCHuv, LCHuvA}  msg
    tempfilename = joinpath(tempname(), "temp_sketch.png")
    # write to a file using ImageIO. Results for transparent colours seem to differ.
    save(File(format"PNG", tempfilename), colmat)
    # Read this image using Cairo's interface to get the right format for placing into other cairo surfaces.
    png = readpng(tempfilename);
    rm(tempfilename)
    png
end

"""
    place_image(p::Point, colmat::VecOrMat; centered = true, alpha = missing)
    -> (upper left point, lower right point)

The color map is centered on p by default, one pixel per value in the matrix or vector.

'alpha' seems to have no effect, but is passed on to 
   https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-paint-with-alpha

post an issue here if it does in any case.
"""
function place_image(p::Point, colmat::VecOrMat; centered = true, alpha = missing)
    place_image(p, _CairoSurfaceBase(colmat); centered)
end

function place_image(p::Point, colmat::VecOrMat{T}; centered = true, alpha = missing) where T<:Union{Luxor.ARGB32, UInt32}
    # layer to overcome a bug where Luxor would not draw the following strokes
    @layer placeimage(data, p; centered = centered)
    Δp = centered * Point(nx / 2, ny / 2)
    (p - Δp, p - Δp + (nx, ny))
end
function place_image(p::Point, data::Luxor.Cairo.CairoSurfaceBase; centered = true, alpha = missing)
    # Layer to overcome a bug where Luxor would not draw the following strokes
    @layer ismissing(alpha) ? placeimage(data, p; centered = centered) : placeimage(data, p, alpha; centered = centered)
    ny, nx = data.height, data.width
    Δp = centered * Point(nx / 2, ny / 2)
    (p - Δp, p - Δp + (nx, ny))
end
