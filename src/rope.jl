"""
    rope_pos_tension(dF,Ls, Ns, ds, diameter_rope, Cs, ρ_air, v, β₀)
                    -> Vector{PositionTuple} , Vector{Force}
Rope positions and tensions, starting at the unknown position anchor,
ending at the known position anchor. Should resemble a catenary.

TODO: Currently, rope mass is neglected. Make wind + inerta an input function df(ds, β) -> ForceTuple. Check against catenary.

Ls       scalar length of rope.
Ns       Number of rope sections (one less than rope nodes).
diameter_rope
Cs      shape coefficient, for wind in the section plane.
ρ_air   density of air at design temperature.
v       scalar velocity of relative wind referred to the rope, not reduced by projection
α_w_rel direction of relative wind referred to the rope section, measured from global x axis around z.
Fk      Force acting on start of rope, a ForceTuple like (10.0N, 100.0N) referred to the chord coordinate system
α_chord Angle from global x axis to the chord x axis, positive from leading edge to trailing edge
"""
function rope_pos_tension(Ls, Ns, diameter_rope, Cs, ρ_air, v, α_w_rel, Fk, α_chord)

    # Length of rope section
    ds = Ls / Ns
    # Most parameters are constant, make a short form function
    dFthis(β) = dF(ds, diameter_rope, Cs, ρ_air, v, α_w_rel, β)
    # Rope node positions, origo at start
    ps = Vector{PositionTuple{typeof(0.0m)}}()

    # Rope tension at nodes
    Ts = Vector{typeof(0.0N)}()

    # Initial values
    β₀  = α_chord + atan(Fk[2], Fk[1]) - π |> °
    x₀, y₀ = 0.0m, 0.0m
    β₋₁ = β₀
    Ts₀ = hypot(Fk) |> N
    curL = 0.0m
    while curL < Ls
        push!(ps, (x₀, y₀))
        push!(Ts, Ts₀)
        # Estimate outgoing angle
        βe =  β₀ + β₀ - β₋₁
        # External force vector on this piece
        df = 0.5dFthis(β₀) + 0.5dFthis(βe)
        # Force vector, kite end
        F₀ = -Ts₀ .* (cos(β₀), sin(β₀))
        # Force vector, buggy end, from force equilibrium
        F₁ = -(F₀ + df)
        # Check that this is actually tension
        @assert hypot(F₀ + F₁) < hypot(F₁)  "Failed simple tension check, hypot(F₀ + F₁) < hypot(F₁) at $curL"
        # Tension, buggy end
        Ts₁ = hypot(F₁)
        # Angle, buggy end
        β₁ = atan(F₁[2], F₁[1]) |> °
        # Averaged angle over span
        βm = (2β₀ + β₁) / 3
        # Position, buggy end (moment equilibrium would be more exact, tension could be considered)
        (x₁, y₁) = (x₀, y₀) + ds .* (cos(βm), sin(βm))
        # Prepare next iteration
        β₋₁ = β₀
        x₀, y₀ = x₁, y₁
        Ts₀ = Ts₁
        curL += ds
        β₀ = β₁
    end
    push!(ps, (x₀, y₀))
    push!(Ts, Ts₀)
    ps, Ts
end


"
projection(α_w_rel, β)

Wind projection factor for a straight section of rope. Covers
    1) Shorter projected length of section.
    2) Slower projected wind speed. This effect is squared, as in velocity normal to the projection is squared.

α_w_rel   direction of relative wind referred to the rope section, from x axis around z.
β         axial orientation of rope section, from x axis around z.
"
function projection(α_w_rel, β)
    angle = α_w_rel  - (β + 90°)
    (abs(cos(angle)))^3
end

"
    dq(diameter_rope, Cs, ρ_air, v, α_w_rel, β)
Scalar load per length due to wind acting normal to a straight rope section

diameter_rope
Cs      shape coefficient, for wind in the section plane
ρ_air   density of air at design temperature
v       scalar velocity of relative wind referret to the rope
α_w_rel direction of relative wind referred to the rope section, from x axis around z.
β       axial orientation of rope section, from x axis around z.
"
dq(diameter_rope, Cs, ρ_air, v, α_w_rel, β) =  0.5ρ_air * Cs * diameter_rope * v^2 * projection(α_w_rel, β) |> N*mm^-1


"
    dF(ds, diameter_rope, Cs, ρ_air, v, β)
    --> (force_x, force_y)::ForceTuple

Wind load, globally oriented force vector per length of straight rope section

ds scalar length of rope section
diameter_rope
Cs      shape coefficient, for wind in the section plane
ρ_air   density of air at design temperature
v       scalar velocity of relative wind referret to the rope
α_w_rel direction of relative wind referred to the rope section, from x axis around z.
β  axial orientation of rope section relative to x axis
"
function dF(ds, diameter_rope, Cs, ρ_air, v, α_w_rel, β)
    dQ = dq(diameter_rope, Cs, ρ_air, v, α_w_rel, β)
    ds * dQ  .* (cos(β + π / 2 ), sin(β+ π / 2)) .|> N
end

const ρ_SK75 = 0.975 * 0.001kg/(10mm)^3
const σ_TS_SK75 = 3600N/mm^2

"
Fill factors reduce the fibre area compared to the circumscribed circle, see 'test_17.jl'.
"
fill_factor(d) = (-0.003*d/mm + 0.853)

"""
Spin factors reduce the fibre breaking strength, see 'test_17.jl'.
"""
spin_factor(d) = 5*10^-5 * (d/mm)^2 + -0.0059*(d/mm) + 0.5504

"""
Circumscribed area as a function of diameter
"""
circle_area(d) = π / 4 * d^2

"""
Area filled with fibres as a function of diameter, see 'test17.jl'.
"""
area_filled(d) = fill_factor(d)* circle_area(d)

"""
Assuming no fibre breaking strenght reduction, but including the fibre fill factor
"""
ideal_spin_strength(d) = area_filled(d) * σ_TS_SK75 |> kN

"""
Rope breaking strength as a function of diameter, see 'test17.jl'
"""
rope_breaking_strength(d) = spin_factor(d) * ideal_spin_strength(d)

"""
Rope weight per length as a function of diameter, see 'test17.jl'
"""
rope_weight(d) = ρ_SK75 * area_filled(d) |> kg/m