function samplepoints(streamlinelength, λ_min , λ_max, n)
    x0 = rand() * 1000.0m
    xs = range(x0, x0 + streamlinelength, length = n)
    no = noise_between_wavelengths(λ_min, λ_max, xs, normalize = false)
end



"""
    z_transform_contributions(vs::T, z::Complex)
        -> Complex
Unilateral z-transform
where
    vs are the samples
    z is a point in the complex plane

"""
function z_transform_contributions(vs::T, z::Complex) where {T<:Union{AbstractRange, Vector}}
    halfn = div(length(vs), 2)
    [s * z^-(i - halfn) for (i, s) in enumerate(vs)]
end
z_transform_contributions_points(vs, z) = [EM * Point(real(ŝ), imag(ŝ)) for ŝ in z_transform_contributions(vs, z)]