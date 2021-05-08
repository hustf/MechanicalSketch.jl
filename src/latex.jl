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
    prepare_latexify!(eq::Expr)

Modify an expression in-place before passing to latexify
"""
function prepare_latexify!(ex::Expr; depth = 0)
    if ex.head == :call
        if ex.args[1] == :∙
            ex.args[1] = :*
        elseif ex.args[1] == :√
            # TODO
            #println("Found it")
        end
    end
    for a in ex.args
        if isa(a, Expr)
            prepare_latexify!(a; depth = depth + 1)
        else
        end
    end
    ex
end

"""
    show_expression(ex::Expr; depth = 0)

For debugging, show an expression tree recursively with indents.
"""
function show_expression(ex::Expr; depth = 0)
    inde = repeat(" ", depth * 4)
    println(inde, ex.head)
    for a in ex.args
        if isa(a, Expr)
            printstyled(inde, "->", "\n"; color= :black)
            show_expression(a; depth = depth + 1)
        else
            if isa(a, Symbol)
                if isdefined(Main, a)
                    printstyled(inde, a, "\n"; color=:green)
                else
                    printstyled(inde, a, "\n"; color=:red) 
                end
            else
                println(inde, a)
            end
        end
    end
    printstyled(inde, "<-", "\n"; color= :black)
    ex
end


"""
    modify_latex(formula)
    --> string
Iteratively 
    - get rid of latex outer enclosing dollar and paranthesises.
    - get rid of latex outer enclosing paranthesises.
    - fix display of unit superscripts
    - remove underscore escaping
    - reorder √ function to square root (see @warn)
    - replace bold font unicode with latex boldfont
    - replace square bracket with contents in subscript
"""
function modify_latex(formula::String)::String
    st = String(formula)
    if occursin("g\\left( t \\cdot", st)
        @error "---"
    else
        #@show "OK"
    end
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
            @warn """This replacement may mess up nested expression. Consider pipelining through prepare_latexify (e.g. @@ev_draw "text" expr)"""
            show_colorful_regex(st, ma)

            modify_latex(output)
        else
            @error "Bad regex"
        end
    elseif occursin(r"\\bf([a-zA-Z])", st)
        # Replace bold font unicode
        # \\bfX
        # =>  \\\boldsymbol{X}
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
    show_colorful_regex(st, ma::RegexMatch)

For debugging
"""
function show_colorful_regex(st, ma::RegexMatch)
    printstyled(st * "\n", color=:green)

    str = repeat('-', ma.offset - 1)
    str *= repeat('|', length(ma.match))
    str *= repeat('-', length(st) - length(ma.match) - ma.offset + 1)
    printstyled(str * "\n", color=:green)

    if length(ma.captures) > 0
        str = repeat('-', ma.offsets[1] - 1)
        str *= repeat('|', length(ma.captures[1]))
        printstyled(str * "\n", color=:green)
    end

    if length(ma.captures) > 1
        str = repeat('-', ma.offsets[2] - 1)
        str *= repeat('|', length(ma.captures[2]))
        printstyled(str * "\n", color=:green)
    end


    printstyled(st[1:(ma.offset - 1)], color=:red)
    printstyled(ma.match, color=:yellow)
    printstyled(st[(ma.offset + length(ma.match)):end] * "\n", color=:red)

    if length(ma.captures) > 0
        printstyled(st[1:(ma.offsets[1] - 1)], color=:red)
        printstyled(ma.captures[1], color=:yellow)
        printstyled(st[(ma.offsets[1] + length(ma.captures[1])):end] * "\n", color=:red)
    end

    if length(ma.captures) > 1
        printstyled(st[1:(ma.offsets[2] - 1)], color=:red)
        printstyled(ma.captures[2], color=:yellow)
        printstyled(st[(ma.offsets[2] + length(ma.captures[2])):end] * "\n", color=:red)
    end
end
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

"""
    draw_expr(pt, scalefactor, eq::Expr;
        abovedisplayskip = 6scalefactor, belowdisplayskip = 6scalefactor, indent = EM)
    -> (upper left point, lower right point, scalefactor)

Iterative, place each line in eq on the image below each other.

abovedisplayskip is applied before every equation.
belowdisplayskip is applied after every equation.
indent is offset to right
"""
function draw_expr(pt, scalefactor, eq::Expr; 
        abovedisplayskip = 6scalefactor, belowdisplayskip = 6scalefactor, indent = EM)
    ptorg = pt
    ptbr = pt
    ptul = pt
    # Replace dot multiplication by ordinary multiplication,
    # and √ with sqrt.
    prepare_latexify!(eq)
    # Consider replacing the expression walk below with MacroTools postwalk.
    # ...if that is clearer.
    if eq.head != :block
        draw_single_expr(pt, scalefactor, eq; abovedisplayskip, belowdisplayskip, indent)
    else
        # Multi-line - iterate and display below.
        geniter = (a for a in eq.args if typeof(a) != LineNumberNode)
        for a in geniter
            ptul, ptbr = draw_expr(pt, scalefactor, a)
            pt += (0, ptbr.y - ptul.y)
        end
        ptorg, ptbr
    end
end
draw_expr(pt, eq::Expr) = draw_expr(pt, 3.143, eq)


"""
    draw_single_expr(pt, scalefactor, eq::Expr;
        abovedisplayskip = 6scalefactor, belowdisplayskip = 6scalefactor, indent = EM)
    -> (upper left point, lower right point)

Iterative, place each line in eq on the image below each other.

abovedisplayskip is applied before every equation.
belowdisplayskip is applied after every equation.
indent is offset to right
"""
function draw_single_expr(pt, scalefactor, eq::Expr; 
                          abovedisplayskip = 6scalefactor, belowdisplayskip = 6scalefactor, indent = EM)
    @assert eq.head != :block
    ptorg = pt
    pt+= (0, abovedisplayskip)
    l = guard_latexify(eq)
    ptul, ptbr = place_image(pt + (indent, 0), l; scalefactor, centered = false)
    ptorg, ptbr + (0, belowdisplayskip), scalefactor
end


"""
    guard_latexify(eq::Expr)

If a line contains just a defined function call with literal arguments, 
show the. For example, string("Just show this comment") can be useful.
"""
function guard_latexify(eq::Expr)
    if eq.head == :call
        evalit = true
        for a in eq.args
            if typeof(a) <: Symbol
                if !isdefined(@__MODULE__, a)
                    evalit = false
                    break
                end
            end
        end
        if evalit
            latexify(LaTeXString(eval(eq)))
        else
            latexify(LaTeXString(string(eq)))
        end
    else
        # This would be an assignment. Show it!
        latexify(prepare_latexify!(eq))
    end
end