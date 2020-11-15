"""
    matchinglines(lfina, at_time::Vector, namestart::Vector{String})
        --> Vector{String}

lfina      String file name, csv tabulated columns custom format
at_time    Vector of quantities, e.g. [1s, 2s] Criterion matching the second column in csv file
namestart  Vector of strings, initial letters for match. E.g. ["a", "ba"] matches "a1", "bac", not "c2".

To match, the first column matches one of the 'namestart' elements AND one of 'at_time'.
"""
function matchinglines(lfina, at_time::Vector, namestart::Vector{String})
    lines = readlines(lfina)
    filter(lines) do line
        vecstr = split(line, "\t")
        linename = vecstr[1]
        for ns in namestart
            if lastindex(linename) >= lastindex(ns)
                if linename[1:lastindex(ns)] == ns
                    curtime = parse(Quantity{Float64}, replace(vecstr[2], "sec" => "s"))
                    if curtime in at_time
                        return true
                    end
                end
            end
        end
        false
    end
end


"""
drawforces(origo, strPlane, at_time::Vector, namestart::String)

origo      Point, typically equals O
lfina       String file name, csv tabulated columns custom format
strplane    Projection plane string: Can be
                "xy", "yx", "xz", "zx", "yz" or "zy"
at_time    Vector of quantities, e.g. [1s, 2s] Criterion matching the second column in csv file
namestart  Vector of strings, initial letters for match. E.g. ["a", "ba"] matches "a1", "bac", not "c2".
"""
function drawforces(origo, lfina, strplane, at_time::Vector, namestart::Vector{String}; labellength = false, components = false, kwargs...)
    @assert strplane ∈ ["xy", "yx", "xz", "zx", "yz", "zy"]
    abscissa = strplane[1]
    ordinat = strplane[2]
    matchlines = matchinglines(lfina, at_time, namestart);
    @assert lastindex(matchlines) > 0
    maxF = 0.0kN
    xmax, ymax, fxmax, fymax = 0.0mm, 0.0mm, 0.0N, 0.0N
    for lin in matchlines
        vs = split(lin, '\t')
        vs = map(s-> replace(s, "|" => "0.0 mm"), vs)
        name = vs[1]
        Fx, Fy, Fz = parse.(Quantity{Float64}, vs[3:5])
        px, py, pz = parse.(Quantity{Float64}, vs[9:11])
        fx, x = if abscissa == 'x'
            Fx, px
        elseif abscissa == 'y'
            Fy, py
        elseif abscissa == 'z'
            Fz, pz
        end
        fy, y = if ordinat == 'x'
            Fx, px
        elseif ordinat == 'y'
            Fy, py
        elseif ordinat == 'z'
            Fz, pz
        end
        if labellength
            F = hypot(Fx, Fy)
            maxF = max(F, maxF)
            if F == maxF
                xmax, ymax, fxmax, fymax =  x, y, fx, fy
            end
        end
        arrow(origo + (x, y), (fx, fy); kwargs..., labellength = false, components = components )
    end
    if labellength
        # Redraw the max arrow with label
        arrow(origo + (xmax, ymax), (fxmax |> kN, fymax |> kN) ; kwargs..., labellength = true, components = false)
    end
end
