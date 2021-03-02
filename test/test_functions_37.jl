function place_image_37(pos::Point, plott::Plots.Plot; 
    width = missing, height = missing, scalefactor = missing,
    centered = false)
    ioc = IOContext(IOBuffer(), :color=>true)
    show(ioc, MIME("image/svg+xml"), plott)
    stsvg = String(take!(ioc.io))
    stsvg = replace(stsvg, "fill-opacity=\"1\"" => "fill-opacity=\"0.3\""; count = 2)
    place_image(pos, readsvg(stsvg); width, height, scalefactor, centered)
end
