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
# TODO add scaling functionality, as with svgimage?
function place_image(p::Point, data::Luxor.Cairo.CairoSurfaceBase; centered = true, alpha = missing)
    # Layer to overcome a bug where Luxor would not draw the following strokes
    @layer ismissing(alpha) ? placeimage(data, p; centered = centered) : placeimage(data, p, alpha; centered = centered)
    ny, nx = data.height, data.width
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
    -> (upper left point, lower right point, scalefac)

Return the upper left, lower right corners, also the calculated scaling factor from original to placed image.
Formulas can be made using MechanicalSketch.@latexify and other methods, see Latexify.

modifylatex = true: Calls 'modify_latex', which subscripts bracketed indexes and other things.
modifysvgcolor = true: Calls Replace currentColor with the last color and opacity from 'setcolor', 'setopacity' or 'sethue'.
Scaling can be specified using one of 'height', 'width' and 'scalefactor'.
"""
function place_image(pos::Point, image::SVGimage; 
                      width = missing, height = missing, scalefactor = missing,
                      centered = false)
    scalefac, original_width, original_height = scalingfactor(image, width, height, scalefactor)
    # Destination size
    dest_width_pix, dest_height_pix = get_scale_sketch.(scalefac .* (original_width, original_height))
    # Destination upper left corner
    ptupleft = centered ?  pos - 0.5 .* (dest_width_pix, dest_height_pix) : pos
    @layer begin
        translate(ptupleft)
        scale(scalefac)
        placeimage(image, Point(0, 0); centered = false) 
    end
    ptupleft, ptupleft + (dest_width_pix, dest_height_pix), scalefac
end
function place_image(pos::Point, formula::LaTeXString; modifylatex = true, modifysvgcolor = true,
                      width = missing, height = missing, scalefactor = missing,
                      centered = false)
    svim = readsvg(tex2svg_string(formula; modifylatex, modifysvgcolor))
    place_image(pos, svim ; width, height, scalefactor, centered)
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
            get_scale_sketch(width) / get_scale_sketch(original_width)
        elseif ismissing(width)
            get_scale_sketch(height) / get_scale_sketch(original_height)
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

The width and height of image based on get_scale_sketch(m).
Note that the width can be inaccurate, as this is ambiguous for svg input.
"""
get_width_height(image) =  (1m / get_scale_sketch(m)) .* (image.width, image.height)
get_width_height(image::Matrix) =  (1m / get_scale_sketch(m)) .* reverse(size(matrix))

"""
    tex2svg_string(formula::String)
    tex2svg_string(formula::LaTeXString; modifylatex = true, modifysvgcolor = true)
    --> string

Relies on NodeJS to call the package matjax, tex2svg. Based off DocumenterEpub 'prerender_mathjax'.
You may need elevated privileges to spawn NodeJS.

modifylatex = true: Calls 'modify_latex', which subscripts bracketed indexes and other things.
modifysvgcolor = true: Calls Replace currentColor with the last color and opacity from 'setcolor', 'setopacity' or 'sethue'.
"""
function tex2svg_string(formula::String)
    mathjaxfile = escape_string(realpath(joinpath(@__DIR__, "..", "mathjax", "node-main.js")))
    @assert isfile(mathjaxfile)
    adapted_formula = escape_string(replace(formula, '\'' => "\\prime"))
    cd(dirname(mathjaxfile)) do
        js_command = """
        require('$(mathjaxfile)').init({
            loader: {load: ['input/tex', 'output/svg']}, svg: {
                fontCache: 'none',
                'localID':$(rand(1:100000))}
        }).then((mathjaxfile) => {
            const svg = MathJax.tex2svg('$adapted_formula');
            console.log(MathJax.startup.adaptor.innerHTML(svg));
        }).catch((err) => console.log("NodeJS was ran and output: " + err.message));
        """
        fullcmd = `$(NodeJS.nodejs_cmd()) -e $js_command`
        try String(read(fullcmd))
        catch err
            @warn "If on windows, you may need to run your editor or julia with some administrator privileges."
            @warn "Program: $(NodeJS.nodejs_cmd())"
            @warn "Option: -e"
            @warn "js_command: $js_command"
            @error err
        end
    end # -> resulting svg string
end
function tex2svg_string(formula::LaTeXString; modifylatex = true, modifysvgcolor = true)
    bw = modifylatex ? modify_latex(formula) : String(formula)
    sv = tex2svg_string(bw)
    modifysvgcolor ? modify_svg_color(sv) : sv
end

"""
    modify_latex(formula)
    --> string
Iteratively 
    - get rid of latex outer enclosing dollar and paranthesises.
    - get rid of latex outer enclosing paranthesises.
    - drop {\\vysmblkcircle}, which is used within units
    - fix display of unit superscripts
    - remove underscore escaping
    - replace square bracket with contents in subscript
"""
function modify_latex(formula::String)::String
    st = String(formula)
    if startswith(st, "\$") && endswith(st, "\$")
        modify_latex(st[nextind(st, begin, 1):prevind(st, end, 1)])
    elseif startswith(formula, "\\left(") && endswith(formula, "\\right)")
        modify_latex(st[nextind(st, begin, 6):prevind(st, end, 7)])
    elseif occursin('∙', st)
        modify_latex(replace(st, '∙' => ""))
    elseif occursin("{\\vysmblkcircle}", st)
        modify_latex(replace(st, "{\\vysmblkcircle}" => ""))
    elseif occursin("\\^-{^", st)
        modify_latex(replace(st, "\\^-{^" => "{^-}{^"))
    elseif occursin("\\_", st)
        regex = r"\\_(\w+)"
        ma = match(regex, st)
        if !isnothing(ma)
            captured = ma.captures[1]
            matched = ma.match
            replacement = "_{" * captured * "}"
            output = replace(st, matched => replacement; count = 1)
            @assert st != output
            modify_latex(output)
        else
            @error "Bad regex"
        end
    else
        regex = r"\\left\[(.*?)\\right\]"
        ma = match(regex, st)
        if !isnothing(ma)
            captured = ma.captures[1]
            matched = ma.match
            replacement = "_{" * captured * "}"
            output = replace(st, matched => replacement; count = 1)
            @assert st != output
            modify_latex(output)
        else
            st
        end
    end
end
modify_latex(formula::LaTeXString) = modify_latex(String(formula))
"""
    modify_svg_color(svgstring::String)::String

Remove local color definitions (normally defined by style sheet) with
an extended style definition.
Both 'stroke' and 'fill' styles equal the last color and opacity from 'setcolor', 'setopacity' or 'sethue'
"""
function modify_svg_color(svgstring::String)::String
    c = get_current_RGBA()
    r = Int(round(c.r * 255))
    g = Int(round(c.g * 255))
    b = Int(round(c.b * 255))
    a = c.alpha
    removes = "stroke=\"currentColor\" fill=\"currentColor\" "
    step1 = replace(svgstring, removes => "")
    olds = "style=\""
    cols = "rgb($r, $g, $b)"
    opacs = "-opacity: $a"
    sfills = "fill: " * cols * "; " * "fill" * opacs * "; "
    sstrokes = "stroke: " * cols * "; " * "stroke" * opacs * "; "
    styles = sfills * sstrokes
    news = olds * styles
    replace(step1, olds  => news)
end