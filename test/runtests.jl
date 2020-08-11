using Test
@testset "1" begin
    include("test_1.jl")
end
@testset "2" begin
    include("test_2.jl")
end
@testset "3" begin let
    include("test_3.jl")
end end
@testset "4" begin let
    include("test_4.jl")
end end
@testset "5" begin let
    include("test_5.jl")
end end
@testset "6" begin let
    include("test_6.jl")
end end
@testset "7" begin let
    include("test_7.jl")
end end
@testset "8" begin let
    include("test_8.jl")
end end
@testset "9" begin let
    include("test_9.jl")
end end
@testset "10" begin let
    include("test_10.jl")
end end
@testset "11" begin let
    include("test_11.jl")
end end

@testset "12" begin let
    include("test_12.jl")
end end

@testset "13" begin let
    include("test_13.jl")
end end