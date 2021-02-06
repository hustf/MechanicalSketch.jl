
"""
pngimage(quantities; normalize_data_range = true)

Convert a matrix to a png image suitable for ´placeimage´.
One pixel per element.
"""
function pngimage(quantities; normalize_data_range = true)
    tempfilename = joinpath(@__DIR__, "tempsketch.png")
    colmat = color_matrix(quantities,
        normalize_data_range = normalize_data_range)
    save(File(format"PNG", tempfilename), colmat)
    img = readpng(tempfilename);
    rm(tempfilename)
    img
end




"""
    pngimage(colmat::Matrix{RGB{Float64}})

Convert a matrix to a png image suitable for ´placeimage´.
One pixel per element.
"""
function pngimage(colmat::Matrix{RGB{Float64}}; normalize_data_range = false)
    if normalize_data_range
        @warn "Can't normalize values of type $(eltype(colmat)), use keyword argument normalize_data_range = false"
    end
    tempfilename = joinpath(@__DIR__, "tempsketch.png")
    save(File(format"PNG", tempfilename), colmat)
    img = readpng(tempfilename);
    rm(tempfilename)
    img
end




"""
    draw_color_map(p::Point, data::Matrix;
                        normalize_data_range = true, centered = true)
    -> (upper left point, lower right point)

The color map is centered on p by default, one pixel per value in the matrix
"""
function draw_color_map(p::Point, data::Matrix;
                        normalize_data_range = true, centered = true)
    img = pngimage(data, normalize_data_range = normalize_data_range)
    # Put the png format picture on screen
    gsave() # Possible bug in placeimage, guard against it.
    placeimage(img, p; centered = centered)
    grestore()
    # TODO fix this, may not work with 'centered'
    # Also check if the overloaded functions here are necessary with Luxor last version.
    ny, nx = size(data)
    Δp = centered * Point(nx / 2, ny / 2)
    (p - Δp, p - Δp + (nx, ny))
end

