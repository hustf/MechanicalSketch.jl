import MechanicalSketch: @import_expand, empty_figure, WI, HE, EM, O, PT, finish
import MechanicalSketch: settext, place_image, PALETTE, color_with_lumin, snapshot
import MechanicalSketch: circle, ∙, arrow_nofill, Point, @layer, sethue, draw_expr
import MechanicalSketch: latexify, arrow, generate_complex_potential_vortex
import MechanicalSketch: generate_complex_potential_source, ∇, color_matrix
import MechanicalSketch: fontsize, draw_legend, draw_streamlines, ∇_rectangle
import MechanicalSketch: @eq_draw, @ev_draw, x_y_iterators_at_pixels
import MechanicalSketch: matrix_to_function, SA
import ColorSchemes:     isoluminant_cgo_80_c38_n256

@import_expand(~m, s, N, °)
include("test_functions_33.jl")
ϕ = ϕ_33
include("test_functions_39.jl")

# Scaling and placement
physwidth = 10.0m
physheight = 4.0m
framedheight = physheight * 1.2
totheight = framedheight * 4
totwidth = totheight * WI / HE
Δx = totwidth / 4
Δy = framedheight / 2
Oadj = O + (-3EM, EM /3)
cent1 = Oadj + ( Δx, 3Δy)
cent2 = Oadj + ( Δx, Δy)
cent3 = Oadj + ( Δx, -Δy)
cent4 = Oadj + ( Δx, -3Δy)

empty_figure( backgroundcolor = color_with_lumin(PALETTE[5], 90),
      hue = "black", height = totheight);
@eq_draw "Potential field, defined previously:" :(ϕ(𝐫))  init= true
@eq_draw "Steady flow velocity field at <b>r</b>:" :( 𝐕(𝐫) = 𝐢∙u(𝐫) + 𝐣∙v(𝐫) = ∇ϕ(𝐫))
Δx, Δy = physwidth / 2, physheight / 2
rng = string([(-Δx, -Δy), (Δx, Δy)])
@ev_draw "We evaluate <b>r</b> <span font='Sans'>∈</span> rectangle $rng" :(𝐕 = ∇(ϕ))

@eq_draw("Local acceleration, steady flow is", quote
    𝐚 = d𝐕 / dt = d( 𝐢∙u(𝐫) + 𝐣∙v(𝐫)) / dt
end)
@eq_draw("A particle moves, so <b>r</b> = <b>r</b>(x, y, t)", quote
    𝐚 = δ𝐕 / δt ∙ dt / dt + δ𝐕 / δx ∙ dx / dt + δ𝐕 / δy ∙ dy / dt
end)
@eq_draw("This field is steady over time, so the first term is zero, and dx / dt = u", quote
    𝐚 = δ𝐕 / δx ∙ u + δ𝐕 / δy ∙ v = ∇𝐕∙(u, v)
end)

@eq_draw("The last step is valid because the axes are orthogonal", quote
    𝐚 = δu / δx ∙ u +  δv / δx ∙ v = ∇(u)∙ u + ∇(v)∙ v
end)

#= To speed up the calculations, we'll strip and reapply interpolation information
xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
u_c = matrix_to_function([𝐕(x, y)[1] for y in ys, x in xs])
u(r) = u_c(real(r), imag(r))
v_c = matrix_to_function([𝐕(x, y)[2] for y in ys, x in xs])
v(r) = u_c(real(r), imag(r))
∇_rectangle(v; physwidth, physheight)
∇_rectangle(v; physwidth, physheight)
∇(ϕ; physwidth, physheight)
=#
cpt = O + ( EM, -HE / 2 + 2EM)
@eq_draw("Defining functions", quote
    u(r) = 𝐕(real(r), imag(r))[1]
    v(r) = 𝐕(real(r), imag(r))[2]
    ∇u(r) = ∇(u)(real(r), imag(r))
    ∇v(r) = ∇(v)(real(r), imag(r))
#    𝐚(r) = ∇u(r).∙u(r) + ∇v(r).∙v(r)
#    𝐚(x, y) = 𝐚(complex(x, y))
end)

r₀ = complex(0.0m, 0.0m)
#a₀ , u₀, v₀ = 𝐚(r₀), u(r₀), v(r₀)
#@show(a₀ , u₀, v₀);
#u₀, v₀ = u(r₀), v(r₀)
#@show(u₀, v₀);




xs, ys = x_y_iterators_at_pixels(;physwidth, physheight)
import MechanicalSketch.MechanicalUnits.Length
xss = SA[collect(xs)[1:2]]
yss = SA[collect(ys)[1:2]]

#xss = SA{typeof(0.0)}[collect(1.0:1.1:10.0)[1:2]]

um = SA{typeof(u₀)}[𝐕(x, y)[1] for y in ys, x in xs]
vm = [𝐕(x, y)[1] for y in ys, x in xs]
xss = SA[xs[1:2]]
yss = SA[ys[1:2]]
foom() = [∇(u)(x, y)[1] for y in yss, x in xss]
∇um = foom()
#ERROR: MethodError: no method matching
#zero(::Type{Tuple{Quantity{Float64,  ᵀ⁻¹, FreeUnits{(s⁻¹,),  ᵀ⁻¹, nothing}}, Quantity{Float64,  ᵀ⁻¹, FreeUnits{(s⁻¹,),  ᵀ⁻¹, nothing}}}})
# The above can work, but is incredibly slow. Maybe we can improve by defining the missing method?
import MechanicalSketch.MechanicalUnits.Unitfu
import MechanicalSketch.MechanicalUnits.FreeUnits
import MechanicalSketch.MechanicalUnits.dimension
import MechanicalSketch.MechanicalUnits.Time
import MechanicalSketch.MechanicalUnits.Dimensions
import MechanicalSketch.MechanicalUnits.Dimension
import MechanicalSketch.MechanicalUnits.Level
import MechanicalSketch.Quantity
TD = dimension(1.0s)
ITD = dimension(1.0/s)
typeof(InvTime)


typeof(Time)
InvTime isa Time^-1

#It seems we havent defined zero(T), where T =
# Tuple{Unitfu.Quantity{Float64,  ᵀ⁻¹, Unitfu.FreeUnits{(s⁻¹,),  ᵀ⁻¹, nothing}}, Unitfu.Quantity{Float64,  ᵀ⁻¹, Unitfu.FreeUnits{(s⁻¹,),  ᵀ⁻¹, nothing}}}
# Tuple{Quantity{Float64,  ᵀ⁻¹, FreeUnits{(s⁻¹,),  ᵀ⁻¹, nothing}}, Quantity{Float64,  ᵀ⁻¹, FreeUnits{(s⁻¹,),  ᵀ⁻¹, nothing}}}
# Tuple{Quantity{Float64,  ITD, FreeUnits{(s⁻¹,),  ITD, nothing}}, Quantity{Float64,  ITD, FreeUnits{(s⁻¹,),  ITD, nothing}}}
# Tuple{Quantity{Float64,  ITD, U}, Quantity{Float64,  ITD, U}} where U
typeof(1.0s) <: Quantity{T,  TD, U} where {T, U}
typeof(1.0s) <: Quantity{Float64,  TD, U} where {U}
typeof((1.0s, 1.0s)) <: Tuple{Quantity{Float64,  TD, U}, Quantity{Float64,  TD, U}} where {U}
typeof((1.0/s, 1.0/s)) <: Tuple{Quantity{Float64,  ITD, U}, Quantity{Float64,  ITD, U}} where {U}


# But zero is not defined for Tuples anywhere.... We have 44 methods.

zero((1.0s, 1.0s))
zero(typeof((1.0, 1.0)))
∇vm

zero(1.0m)
zero(typeof(1.0m))



fooam() = [𝐚(x, y) for y in ys, x in xs]
am = @time fooam()
# Show velocity field

colmat1, legend1 = color_matrix(𝐕; centered = true, maxlegend = 1.0m/s, name = Symbol("‖V‖"));
ulp, lrp = place_image(cpt, colmat1; centered = false)
@layer begin
    fontsize(25)
    draw_legend(ulp + (0.5EM, 0.5EM) + (physwidth, 0.0m), legend1)
    # To better indicate positive direction for this static image:
    sethue(PALETTE[8])
    draw_streamlines(cent2, 𝐕, probability = 0.001)
end
snapshot()


# Show acceleration field
cpt = O + (ulp[1], lrp[2] - EM)

@time colmat2, legend2 = color_matrix(𝐚; centered = true, noofbins = 7, name = Symbol("‖a‖"));
println("The calculation is done?")
ulp, lrp = place_image(cpt, colmat2; centered = false)
@layer begin
    fontsize(25)
    draw_legend(ulp + (0.5EM, 0.5EM) + (physwidth, 0.0m), legend2)
    # To better indicate positive direction for this static image:
    sethue(PALETTE[8])
    draw_streamlines(cent2, 𝐚, probability = 0.001)
end


snapshot(fname = joinpath(@__DIR__, "test_38.png"))



