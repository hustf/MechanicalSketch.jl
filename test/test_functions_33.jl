ϕ_vortex_33 =  generate_complex_potential_vortex(; pos = complex(0.0, 1.0)m, vorticity = 1.0m²/s / 2π)
ϕ_source_33 = generate_complex_potential_source(; pos = complex(3.0, 0.0)m, massflowout = 1.0m²/s)
ϕ_sink_33 = generate_complex_potential_source(; pos = -complex(3.0, 0.0)m, massflowout = -1.0m²/s)
ϕ_33(p) = ϕ_vortex_33(p) + ϕ_source_33(p) + ϕ_sink_33(p)