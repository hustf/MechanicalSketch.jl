
"""
@ev_draw msg eq init=false

1) If optional argument init = true, set default layout parameters (see below)
2) Place the text 'msg' on the current drawing at global variable cpt.
3) Latexify expression(s) eq and place it as an svg below the text
4) Evaluate eq in the calling context
5) Update layout parameter cpt - current point, based on layout parameters.

Macro for cutting down on boilerplate code. This is not sufficient for
all cases. When this does not produce expected results,
use @macroexpand to see what occurs, and copy / modify that code.

Also, modifying line spacing (Δcpy) and (scalelatex) and of course
the current point (CP) may increase the
usefulness of this macro.

Note that 'msg' accepts pango-style html-like markup for text formatting.

Additional input: locally defined variables
cpt     Point   Mutating current position, bottom left of displayed first line
Δcpy    Float64  Line spacing after text lines, typically 2 (points)
scalelatex = 3.143

## Example:
```julia
cpt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
Δcpy = 2
scalelatex = 3.143
pt += @ev_draw  "Unit stripping function:" :(ul(x) = x / oneunit(x))
```
"""
macro ev_draw(msg, eq, init = false)
    # Check macro input in this module's context
    @assert typeof(eq) <: Expr   "Second argument not an expression, at \n\t$__source__"
    expr = draw_init(init)
    assertions!(expr, __source__)
    place_msg!(expr, msg)
    place_eqs!(expr, eq)

    # Evaluate the equation / expression / block in the calling context - main scope.
    push!(expr.args, esc(quote
        eval($eq)
    end))

    # If the current drawing is a recording surface, return a snapshot
    push!(expr.args, quote
        if currentdrawing().surfacetype == :rec
            snapshot()
        end
    end)
    expr
end

"""
    eq_draw(msg, eq, init = false)
Skips the evaluation, otherwise same as @ev_draw
"""
macro eq_draw(msg, eq, init = false)
    # Check macro input in this module's context
    @assert typeof(eq) <: Expr   "Second argument not an expression, at \n\t$__source__"
    expr = draw_init(init)
    assertions!(expr, __source__)
    place_msg!(expr, msg)
    place_eqs!(expr, eq)
    # If the current drawing is a recording surface, return a snapshot
    push!(expr.args, quote
        if currentdrawing().surfacetype == :rec
            snapshot()
        end
    end)
    expr
end







"""
    draw_init(init)

Create an expression skeleton for macros `@ev_draw`.
init is an expression which is evaluated in the calling context.
If 'init = true', layout parameters are defined globally
in the calling context:
    cpt Current point
    Δcpy Verttical spacing
    scalelatex

For better control, define these prior to the first call.
"""
function draw_init(init)
    expr = Expr(:block)
    push!(expr.args, esc(quote
        if eval($init) == true
            cpt = O + (-WI / 2 + EM, -HE / 2 + 2EM)
            Δcpy = 2
            scalelatex = 3.143
        end
    end))
    expr
end

"""
    assertions!(expr, __source__)

Check that global variables and functions exist in the calling context, for
macro `@ev_draw`.
"""
function assertions!(expr, __source__)

    booleancheck = Expr(:escape, Expr(:isdefined, :cpt))
    assertion = Expr(:(macrocall), Symbol("@assert"), __source__, booleancheck, "Global 'cpt' (current Point) not defined, at \n\t$__source__")
    push!(expr.args, assertion)

    booleancheck = Expr(:escape, Expr(:isdefined, :Δcpy))
    assertion = Expr(:(macrocall), Symbol("@assert"), __source__, booleancheck, "Global 'Δcpy' (additional line spacing, a unitless number) not defined, at \n\t$__source__")
    push!(expr.args, assertion)

    booleancheck = Expr(:escape, Expr(:isdefined, :scalelatex))
    assertion = Expr(:(macrocall), Symbol("@assert"), __source__, booleancheck, "Global 'scalelatex' (e.g. 3.142, normally based on output from place_img with defined height) not defined, at \n\t$__source__")
    push!(expr.args, assertion)

#    booleancheck = Expr(:escape, Expr(:isdefined, :currentdrawing))
#    assertion = Expr(:(macrocall), Symbol("@assert"), __source__, booleancheck, "Global 'currentdrawing()' not defined, at \n\t$__source__")
#    push!(expr.args, assertion)
    expr
end

"""
    place_msg!(expr, msg)

Place the text (no latex) on drawing, update layout parameters in the calling context
of macro `@ev_draw`.
"""
function place_msg!(expr, msg)
    # Evaluate string(msg) in the calling context to get a string for sure.
    push!(expr.args, esc(quote
        local st = eval(string($msg))
    end))

    # Unfortunately, the 'Text API' does not provide easily interpretable feedback on
    # how much vertical space 'msg' occupies. We rely on constant EM and line counting.
    push!(expr.args, esc(quote
        local textlinebreaks = count(c -> c == '\n' || c == '\r', collect(st))
    end))

    # 'Settext' will displace multi-line output upwards. But 'cpt' keeps track of
    # the next line's baseline. So we move 'cpt' down by 'textlinebreaks' * (EM + Δcpy) .
    push!(expr.args, esc(quote
        local Δy = ($EM + Δcpy) * textlinebreaks
        local Δpt =  Point(0, Δy)
    end))
    push!(expr.args, esc(Expr(:+=, :cpt, :Δpt)))

    # Draw string in the modified position
    push!(expr.args, esc(quote
        settext(st, cpt, markup = true)
    end))
    # Move current point to next base line, as if we were drawing more text.
    push!(expr.args, esc(quote
        Δy = ($EM + Δcpy)
        Δpt =  Point(0, Δy)
    end))
    push!(expr.args, esc(Expr(:+=, :cpt, :Δpt)))
    expr
end

"""
    place_eqs!(expr, eq)

Draw the equation(s). The reference point here is not baseline of text,
but the upper left corner of the svg image. Compensate for that.
Uupdate layout parameters in the calling context of macro `@ev_draw`.
"""
function place_eqs!(expr, eq)
    # Draw the equation(s). The reference point here is not baseline of text,
    # but the upper left corner of the svg image. Compensate for that.
    push!(expr.args, esc(quote
        local ptul, ptbr = draw_expr(cpt + Point(0, -EM), scalelatex, $eq)
        # circle(cpt; r = 40mm) # For debugging of layout parameters.
        # circle(ptul; r = 50mm)
        # circle(ptbr; r = 50mm)
    end))

    # Move to next line. Assume the next line will be text, so add the 'EM' that we skipped before the equation
    push!(expr.args, esc(quote
        Δy = ptbr.y - ptul.y
        Δpt =  Point(0, Δy)
    end))
    push!(expr.args, esc(Expr(:+=, :cpt, :Δpt)))
    expr
end