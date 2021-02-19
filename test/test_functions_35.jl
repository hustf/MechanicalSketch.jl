"""
get_width_height_35(image)
--> (w, h)::Quantity{Length}

'image' can be of types 
- SVGimage (output from 'readsvg'),
- CairoSurfaceBase{UInt32} (output from 'readpng')
- matrix  - it is assumed that matrices follow the image convention: A column represent horizontal pixels.

The width and height of image based on get_scale_sketch(m).
Note that the width can be inaccurate, as this is ambiguous for svg input.
"""
get_width_height_35(image) =  (1m / get_scale_sketch(m)) .* (image.width, image.height)
get_width_height_35(image::Matrix) =  (1m / get_scale_sketch(m)) .* reverse(size(matrix))

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
    original_width, original_height = get_width_height_35(image)
    # Find scaling from input to output
    scalefac = if ismissing(width) && ismissing(height)
        1.0
    elseif ismissing(height)
        get_scale_sketch(width) / get_scale_sketch(original_width)
    elseif ismissing(width)
        get_scale_sketch(height) / get_scale_sketch(original_height)
    end
    # Destination size
    dest_width_pix, dest_height_pix = get_scale_sketch.(scalefac .* (original_width, original_height))
    # Destination upper left corner
    ptupleft = centered ?  pos - 0.5 .* (dest_width_pix, dest_height_pix) : pos
    @layer begin
        translate(ptupleft)
        scale(scalefac)
        placeimage(image, Point(0, 0); centered = false) 
    end
    ptupleft, ptupleft + (dest_width_pix, dest_height_pix)
end
