"""
    lenient_min_max_complex(A::AbstractArray)

Returns (min, max) of hypot.(A)
"""
function lenient_min_max_complex(A::AbstractArray)
    magnitude = hypot.(A)
    extrema(filter(x -> !isnan(x) && !isinf(x), magnitude))
end

"""
    lenient_min_max(A)

Neglecting NaN and Inf values, return
- Minimum and maximum value out of real element arrays.
- Minimum and maximum magnitude out of complex element arrays.
- Minimum and maximum magnitude out of tuple element arrays.
"""
lenient_min_max(A::AbstractArray{<:RealQuantity}) = extrema(filter(x-> !isnan(x) && !isinf(x), A))
lenient_min_max(A::AbstractArray{<:Real}) = extrema(filter(x-> !isnan(x) && !isinf(x), A))
lenient_min_max(A) = lenient_min_max_complex(A)

""""
    lenient_min_max(f_xy, xs, ys)

    f_xy is a function with domain defined by iterators (xs, ys)
    Neglecting NaN and Inf values, return
- Minimum and maximum value out of real valued function f_xy
- Minimum and maximum magnitude out of complex valued function f_xy
- Minimum and maximum magnitude out of tuple valued functions
"""
function lenient_min_max(f_xy, xs, ys)
    bigiterator = product(xs, ys)
    default = hypot(f_xy(first(bigiterator)...)) * 0.0
    function g(x, y)
        valu = hypot(f_xy(x, y))
        !isnan(valu) && !isinf(valu) ? valu : default
    end
    extrema(tu -> g(tu...), bigiterator)
end

"""
    lenient_min(A)
    lenient_min(f_xy, xs, ys)

Neglecting NaN and Inf values, return
- Minimum value out of real element arrays.
- Minimum magnitude out of complex element arrays.
- Minimum magnitude out of tuple element arrays.
- Minimum value out of real valued function f_xy on all of xs, ys
- Minimum magnitude out of complex valued function f_xy
- Minimum magnitude out of tuple valued functions
"""
lenient_min(A) = lenient_min_max(A)[1]
lenient_min(f_xy, xs, ys) = lenient_min_max(f_xy, xs, ys)[1] 


"""
    lenient_max(A)
    lenient_max(f_xy, xs, ys)

Neglecting NaN and Inf values, return
- Maximum value out of real element arrays.
- Maximum magnitude out of complex element arrays.
- Maximum magnitude out of tuple element arrays.
- Maximum value out of real valued function f_xy
- Maximum magnitude out of complex valued function f_xy
- Maximum magnitude out of tuple valued functions
"""
lenient_max(A) = lenient_min_max(A)[2]
lenient_max(f_xy, xs, ys) = lenient_min_max(f_xy, xs, ys)[2] 




magnitude(x::Complex) = hypot(x)
magnitude(x::ComplexQuantity) = hypot(x)
magnitude(x::NTuple{2, T}) where T = hypot(x[1], x[2])

qangle(x::Complex) = °(angle(x))
qangle(x::ComplexQuantity) = °(angle(x))
qangle(x::NTuple{2, T}) where T = °(atan(x[1], x[2]))

