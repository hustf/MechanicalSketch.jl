function prerender_mathjax(formula::String, display_mode::Bool)
    mathjaxfile = realpath(joinpath(dirname(pathof(DocumenterEpub)), "..", "res", "mathjax","node-main.js"))
    @assert isfile(mathjaxfile)
    rf = escape_string(replace(formula, '\'' => "\\prime"))
    @show mathjaxfile
    svg_code = nothing
    cd(dirname(mathjaxfile)) do
        println(" ")
        @show readdir()
        js_argument = """
        require('$(escape_string(mathjaxfile))').init({
            loader: {load: ['input/tex', 'output/svg']}, svg: {
                fontCache: 'none',
                'localID':$(rand(1:100000))}
        }).then((mathjaxfile) => {
            const svg = MathJax.tex2svg('$rf', {display: $(display_mode)});
            console.log(MathJax.startup.adaptor.innerHTML(svg));
        }).catch((err) => console.log("|||||||||||" + err.message));
        """
        println(" ")
        @show js_argument
        fullcmd = `$(NodeJS.nodejs_cmd()) -e $js_argument`

        println(" ")
        prepcmd = `whoami`
        prepres = String(read(prepcmd))
        println(prepcmd, " output: ", prepres)

#        prepcmd = `groups`
#        prepres = String(read(prepcmd))
#        println(prepcmd, " output: ", prepres)
#=
groups: cannot find name for group ID 197121
←[33m←[1mERROR: ←[22m←[39mLoadError: failed process: Process(`←[4mgroups←[24m`, ProcessExited(1)) [1]
=#

        prepcmd = `id`
        prepres = String(read(prepcmd))
        println(prepcmd, " output: ", prepres)


        res = String(read(fullcmd))
        println(" ")
        @show res
        println("  ")
        String(res)
#=        svg_code= String(read(`$(NodeJS.nodejs_cmd()) -e """
            require('$(escape_string(mathjaxfile))').init({
                loader: {load: ['input/tex', 'output/svg']}, svg: {
                    fontCache: 'none',
                    'localID':$(rand(1:100000))}
            }).then((mathjaxfile) => {
                const svg = MathJax.tex2svg('$rf', {display: $(display_mode)});
                console.log(MathJax.startup.adaptor.innerHTML(svg));
            }).catch((err) => console.log(err.message));
            """`))
=#
    end
    return svg_code
end

"""
Takes a html string that may contain `<pre><code ... </code></pre>` blocks and use node and
highlight.js to pre-render them to HTML.
"""
function prerender_highlightjs(hs::String, lang::String)::String
    # select highlight js script (julia one stems from https://fredrikekre.se/posts/highlight-julia/)
    hljsfile = occursin("julia", lang) ? "julia.highlight.min.js" : "highlight.pack.js"
    hljsfile = abspath(joinpath(@__DIR__, "..", "res", hljsfile))

    # buffer to write the JS script
    inbuffer = IOBuffer()
    write(inbuffer, """const hljs = require('$(escape_string(hljsfile))');""")

    # un-escape code string
    cs = escape_string(html_unescape(hs))
    # add to content of jsbuffer
    write(inbuffer, """console.log("<pre><code class=\\"hljs\\">" + hljs.highlight("$lang", "$cs").value + "</code></pre>");""")

    outbuffer = IOBuffer()
    run(pipeline(`$(NodeJS.nodejs_cmd()) -e "$(String(take!(inbuffer)))"`, stdout=outbuffer))
    return String(take!(outbuffer))
end