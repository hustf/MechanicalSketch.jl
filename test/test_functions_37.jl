# This functionality could be moved to a separate package which carries the 
# Plots dependency. An alternative would be to use @require here, but we don't.
# Refer to https://github.com/JuliaLang/Pkg.jl/issues/1285 - the functionality
# might become part of Julia.
import Plots
import Plots: plot, plot!, default, px
using RecipesBase
"Similar to other 'place_image', but not included in MechanicalSketch
Consider moving to MechGlueCode, provided Plots and MechanicalSketch are loaded."
function place_image_37(pos::Point, plott::Plots.Plot; 
    width = missing, height = missing, scalefactor = missing,
    centered = false)
    ioc = IOContext(IOBuffer(), :color=>true)
    show(ioc, MIME("image/svg+xml"), plott)
    stsvg = String(take!(ioc.io))
    stsvg = replace(stsvg, "fill-opacity=\"1\"" => "fill-opacity=\"0.3\""; count = 2)
    place_image(pos, readsvg(stsvg); width, height, scalefactor, centered)
end
