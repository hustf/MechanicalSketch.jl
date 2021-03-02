"""
get_width_height_35(image)
--> (w, h)::Quantity{Length}

'image' can be of types 
- SVGimage (output from 'readsvg'),
- CairoSurfaceBase{UInt32} (output from 'readpng')
- matrix  - it is assumed that matrices follow the image convention: A column represent horizontal pixels.

The width and height of image based on scale_to_pt(m).
Note that the width can be inaccurate, as this is ambiguous for svg input.
"""
get_width_height_35(image) =  (scale_pt_to_unit(m)) .* (image.width, image.height)
get_width_height_35(image::Matrix) =  (scale_pt_to_unit(m)) .* reverse(size(matrix))

"""
    place_image_35(image::SVGimage, pos::Point;
                  width = missing, height = missing,
                  centered = false)
    -> (upper left point, lower right point)

Return the upper left and bottom right points of the placed and scaled image.
"""
function place_image_35(pos::Point, image::SVGimage; 
                      width = missing, height = missing,
                      centered = false)
    @assert !ismissing(width) + !ismissing(height) < 2 "Width and height can not be specified simultaneously."
    original_width, original_height = get_width_height_35(image)
    # Find scaling from input to output
    scalefac = if ismissing(width) && ismissing(height)
        1.0
    elseif ismissing(height)
        scale_to_pt(width) / scale_to_pt(original_width)
    elseif ismissing(width)
        scale_to_pt(height) / scale_to_pt(original_height)
    end
    # Destination size
    dest_width_pix, dest_height_pix = scale_to_pt.(scalefac .* (original_width, original_height))
    # Destination upper left corner
    ptupleft = centered ?  pos - 0.5 .* (dest_width_pix, dest_height_pix) : pos
    @layer begin
        translate(ptupleft)
        scale(scalefac)
        placeimage(image, Point(0, 0); centered = false) 
    end
    ptupleft, ptupleft + (dest_width_pix, dest_height_pix)
end
