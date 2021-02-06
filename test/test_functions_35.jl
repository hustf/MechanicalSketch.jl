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
    placeimage_35(image, pos; height = get_width_height_35(image)[2]::Length, centered=false)
    -> (upper left point, lower right point)

'image' can be of types 
    - SVGimage (output from 'readsvg'),
    - CairoSurfaceBase{UInt32} (output from 'readpng')

Return the upper left and bottom right Points of the placed image.
"""
function placeimage_35(image, pos; 
                       height = missing,
                       width = missing,
                       centered = false)

    original_width, original_height = get_width_height_35(image)
    if ismissing(width) && ismissing(height)
        width, height = get_width_height_35(image)
    elseif ismissing(height)
        # User specified width
        scalefac = upreferred(width / original_width)
        height = original_height * scalefac
    elseif ismissing(width)
        # User specified height
        scalefac = upreferred(height / original_height)
        width = original_height * scalefac
    end
    if centered == true
        pos -= (width / 2, -height) / 2)
    end
    @layer begin
        translate(pos)
        @layer begin
            scale(scalefac)
            Rsvg.handle_render_cairo(Luxor.get_current_cr(), image.im)
        end
    end
    pos, pos + (width, height)
end

# TODO alpha when possible?
"""
placeimage_35(image::Matrix, pos; centered=false)
-> (upper left point, lower right point)

Input:
'image' c
- matrix  - it is assumed that matrices follow the image convention: A column represent horizontal pixels.
- CairoSurfaceBase{UInt32} (output from 'readpng')

Return the upper left and bottom right points of the placed image.

"""
function placeimage_35(image::Matrix, pos; centered = true, normalize_data_range = true)
    draw_color_map(pos, image; centered, normalize_data_range)
end