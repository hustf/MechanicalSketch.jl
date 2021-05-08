"""
    place_image(p::Point, colmat::VecOrMat; centered = true, alpha = missing)
    -> (upper left point, lower right point)

The color map is centered on p by default, one pixel per value in the matrix or vector.

Width and height is determined by the size of the matrix.

'alpha' mayhave no effect, but is passed on to 
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


"""
    place_image(pos::Point, image::SVGimage, 
                  width = missing, height = missing, scalefactor = missing,
                  centered = false)
    place_image(pos::Point, formula::LaTeXString; modifylatex = true, modifysvgcolor = true,
                  width = missing, height = missing, scalefactor = missing,
                  centered = false)
    place_image(pos::Point, data::Luxor.Cairo.CairoSurfaceBase; centered = true, alpha = missing,
                  width = missing, height = missing, scalefactor = missing)
    -> (upper left point, lower right point, scalefactor)

Return the upper left, lower right corners, also the calculated scaling factor from original to placed image.

'image::SVGimage' can be made using MechanicalSketch.readsvg (from Luxor, as usual). It takes files or string input.
'formula::LaTeXString' can be made using MechanicalSketch.@latexify and other methods, see Latexify. 
                       Reuse output 'scalefactor' as input for following formula images.
'data::Luxor.Cairo.CairoSurfaceBase' can be made using MechanicalSketch.readpng (from Luxor). 

'height', 'width' and 'scalefactor': Uniform scaling should work with quantities or numbers (i.e. pixels or points).

'modifylatex' = true: Calls 'modify_latex', which subscripts bracketed indexes and a number of other adaptions.
'modifysvgcolor' = true: Replace currentColor with the last color and opacity from 'setcolor', 'setopacity' or 'sethue'.
'alpha' = 0.0 - 1.0 : 0.0 is completely translucent, 1.0 is opaque. The effect vary depending on input type.
"""
function place_image(pos::Point, formula::LaTeXString; modifylatex = true, modifysvgcolor = true,
    width = missing, height = missing, scalefactor = missing,
    centered = false)
    svim = readsvg(tex2svg_string(formula; modifylatex, modifysvgcolor))
    place_image(pos, svim ; width, height, scalefactor, centered)
end
function place_image(pos::Point, image::SVGimage; 
                      width = missing, height = missing, scalefactor = missing,
                      centered = false)
    scalefac, original_width, original_height = scalingfactor(image, width, height, scalefactor)
    # Destination size
    dest_width_pix, dest_height_pix = scale_to_pt.(scalefac .* (original_width, original_height))
    # Destination upper left corner
    ptupleft = centered ?  pos - 0.5 .* (dest_width_pix, dest_height_pix) : pos
    @layer begin
        translate(ptupleft)
        scale(scalefac)
        placeimage(image, Point(0, 0); centered = false) 
    end
    ptupleft, ptupleft + (dest_width_pix, dest_height_pix), scalefac
end

function place_image(pos::Point, data::Luxor.Cairo.CairoSurfaceBase; centered = true, alpha = missing,
                     width = missing, height = missing, scalefactor = missing)
    scalefac, original_width, original_height = scalingfactor(data, width, height, scalefactor)
    # Destination size
    dest_width_pix, dest_height_pix = scale_to_pt.(scalefac .* (original_width, original_height))
    # Destination upper left corner (we'll place the image non-centered afterwards)
    ptupleft = centered ?  pos - 0.5 .* (dest_width_pix, dest_height_pix) : pos
    @layer begin
        translate(ptupleft) 
        scale(scalefac)
        ismissing(alpha) ? placeimage(data, Point(0, 0); centered = false) : placeimage(data, Point(0, 0), alpha; centered = false)
    end
    ptupleft, ptupleft + (dest_width_pix, dest_height_pix), scalefac
end
"""
    scalingfactor(image, width, height, scalefactor)
    -> (scalefac, original_width, original_height)
"""
function scalingfactor(image, width, height, scalefactor::Union{Float64, Missing})
    @assert !ismissing(width) + !ismissing(height) + !ismissing(scalefactor) < 2 "Only one of width, height and scalefactor can be specified."
    original_width, original_height = get_width_height(image)
    # Find scaling from input to output
    scalefac = if ismissing(scalefactor)
        if ismissing(width) && ismissing(height)
            1.0
        elseif ismissing(height)
            scale_to_pt(width) / scale_to_pt(original_width)
        elseif ismissing(width)
            scale_to_pt(height) / scale_to_pt(original_height)
        end
    else
        scalefactor
    end
    scalefac, original_width, original_height
end

"""
get_width_height(image)
--> (w, h)::Quantity{Length}

'image' can be of types 
- SVGimage (output from 'readsvg'),
- CairoSurfaceBase{UInt32} (output from 'readpng')
- matrix  - it is assumed that matrices follow the image convention: A column represent horizontal pixels.

The width and height of image based on scale_to_pt(m).
Note that the width can be inaccurate, as this is ambiguous for svg input.
"""
get_width_height(image) =  scale_pt_to_unit(m) .* (image.width, image.height)
get_width_height(image::Matrix) =  scale_pt_to_unit(m) .* reverse(size(matrix))



"""
    _CairoSurfaceBase(colmat::VecOrMat{T}) where T

Convert a matrix or vector to a cairo surface suitable for ´placeimage´.
One pixel per element. Relies on ImageIO / ImageMagick because it seems 
to work more easily.
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
