function blackman_20(n)
    N = 20
    @assert n > 0
    @assert n < N + 1
    a0 = 0.42659
    a1 = 0.49656
    a2 = 0.076849
    a0 - a1∙cos(2π*n / N) + a2∙cos(4π*n / N) + a2∙cos(4π∙n / N)
end

function samplepoints(streamlinelength, λ_min , λ_max, n)
    x0 = rand() * 1000.0m
    xs = range(x0, x0 + streamlinelength, length = n)
    no = noise_between_wavelengths(λ_min, λ_max, xs, normalize = false)
end

function samplebars_31(samples, maxwidth)
    pts = Vector{Point}()
    maxx = length(samples)
    for (i, a) in enumerate(samples)
        x = maxwidth * i / maxx
        y = - a
        push!(pts,  Point(x, 0y))
        push!(pts,  Point(x, y))
    end
    pts
end

function draw_samplebars_31(origo, samples, maxwidth; rotatehue_degrees_total = 0°)
    startcolo = get_current_RGB()
    samplepoints = samplebars_31(samples,  maxwidth)
    function foovertex(n)
        if mod(n, 3) == 2
            rotatedeg = (n - 1) * rotatehue_degrees_total / length(samplepoints)
            sethue(rotate_hue(startcolo, rotatedeg))
            circle(O, 0.006m, :stroke)
        end
    end
    @layer begin
        for i in range(1, length(samplepoints) - 1, step = 2)
            line(origo + samplepoints[i], origo + samplepoints[i + 1], :stroke)
            foovertex(i)
        end
    end
end

function draw_sampleplot_31(origo, samples, maxwidth)
    @layer begin
        sethue(PALETTE[3])
        arrow(origo, origo + (0.0,  -2EM))
        arrow(origo, origo + (maxwidth + 0.5EM, 0.0))
        sethue(color_from_palette("red"))
        draw_samplebars_31(origo, samples, maxwidth, rotatehue_degrees_total = 270°)
    end
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
    [s * z^-(i - 1) for (i, s) in enumerate(vs)]
end
z_transform_contributions_points(vs, z) = [EM * Point(real(ŝ), imag(ŝ)) for ŝ in z_transform_contributions(vs, z)]