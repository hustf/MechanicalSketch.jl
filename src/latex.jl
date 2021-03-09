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
    svgs = cd(dirname(mathjaxfile)) do
        js_command = """
        require('$(mathjaxfile)').init({
            loader: {load: ['input/tex', 'output/svg', '[tex]/boldsymbol']}, svg: {
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
    end
    @assert !startswith(svgs, "NodeJS was ran and output") svgs
    svgs
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
    - drop ∙ used within units: N∙m => Nm
    - drop {\\vysmblkcircle}, which is used within units
    - fix display of unit superscripts
    - remove underscore escaping
    - reorder √ function to square root
    - reorder dot multiplication function
    - replace bold font unicode with
    - replace square bracket with contents in subscript
"""
function modify_latex(formula::String)::String
    st = String(formula)
    if startswith(st, "\$") && endswith(st, "\$")
        # get rid of latex outer enclosing dollar and paranthesises.
        modify_latex(st[nextind(st, begin, 1):prevind(st, end, 1)])
    elseif startswith(st, "\\left(") && endswith(st, "\\right)")
        # get rid of latex outer enclosing paranthesises.
        output = st[nextind(st, begin, 6):prevind(st, end, 7)]
        #println("1")
        #@show st
        #@show output
        modify_latex(output)
    #elseif occursin('∙', st)
    #    # drop ∙ used within units: N∙m => Nm
    #    modify_latex(replace(st, '∙' => ""))
    elseif occursin("{\\vysmblkcircle}", st)
        # drop {\\vysmblkcircle} used within units (no space)
        output = replace(st, "{\\vysmblkcircle}" => "")
        #println("2")
        #@show st
        #@show output
        modify_latex(output)
    elseif occursin("\\^-{^", st)
        # fix display of unit superscripts
        output = replace(st, "\\^-{^" => "{^-}{^")
        #println("3")
        #@show st
        #@show output
        modify_latex(output)
    elseif occursin("\\_", st)
        # remove underscore escaping
        regex = r"\\_(\w+)"
        ma = match(regex, st)
        if !isnothing(ma)
            captured = ma.captures[1]
            matched = ma.match
            replacement = "_{" * captured * "}"
            output = replace(st, matched => replacement; count = 1)
            #println("4")
            #@show st
            #@show output
            @assert st != output
            modify_latex(output)
        else
            @error "Bad regex"
        end
    elseif occursin("\\sqrt\\left( ", st)
        # reorder √ function to square root
        #"\\sqrt\\left( capture \\right)"
        # => \\sqrt{capture}
        regex = r"\\sqrt\\left\( (.*?) \\right\)"
        ma = match(regex, st)
        if !isnothing(ma)
            captured = ma.captures[1]
            matched = ma.match
            replacement = "\\sqrt{" * captured * "} "
            output = replace(st, matched => replacement; count = 1)
            #println("5")
            #@show st
            #@show output
            modify_latex(output)
        else
            @error "Bad regex"
        end
    elseif occursin("\\vysmblkcircle\\left( ", st)
        # reorder dot multiplication function:
        # \\vysmblkcircle\\left(factor1, factor2 \\right)
        # =>  factor1 \\cdot factor2
        # A more solid approach is probably defining: #@latexrecipe ∙
        regex = r"\\vysmblkcircle\\left\( (.*?), (.*?) \\right\)"
        ma = match(regex, st)
        if !isnothing(ma)
            captured1 = ma.captures[1]
            captured2 = ma.captures[2]
            matched = ma.match
            replacement = captured1 * " \\cdot " * captured2
            output = replace(st, matched => replacement; count = 1)
            #println("6")
            #@show st
            #@show output
            modify_latex(output)
        else
            @error "Bad regex"
        end
    elseif occursin(r"\\bf([a-zA-Z])", st)
        # Replace bold font unicode
        # \\bfX
        # =>  \\\boldsymbol{X}
        # A more solid approach is probably defining: #@latexrecipe ∙
        regex = r"\\bf([a-zA-Z])"
        ma = match(regex, st)
        if !isnothing(ma)
            captured = ma.captures[1]
            matched = ma.match
            replacement = "\\boldsymbol{" * captured * "}"
            output = replace(st, matched => replacement; count = 1)
            #println("7")
            #@show st
            #@show output
            modify_latex(output)
        else
            @error "Bad regex"
        end
    else
        # replace square bracket with contents in subscript
        # Also: The only exit point from this iterative function.
        regex = r"\\left\[(.*?)\\right\]"
        ma = match(regex, st)
        if !isnothing(ma)
            captured = ma.captures[1]
            matched = ma.match
            replacement = "_{" * captured * "}"
            output = replace(st, matched => replacement; count = 1)
            #println("8")
            #@show st
            #@show output
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
Primarily for svgs output by MathJax via NodeJS.
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