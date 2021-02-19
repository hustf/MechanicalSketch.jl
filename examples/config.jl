using Markdown
using InteractiveUtils
using Pkg
#Pkg.add(url = "https://github.com/hustf/Unitfu.jl")
#Pkg.add(url = "https://github.com/hustf/MechanicalUnits.jl")
#Pkg.add(url = "https://github.com/hustf/MechanicalSketch.jl")
#Pkg.develop("MechanicalSketch")
#Pkg.add("Latexify")
#Pkg.add("PlutoUI")
#Pkg.status()

Pkg.instantiate()
push!(LOAD_PATH, Base.find_package("MechanicalSketch"))
#VERSION >= v"1.5" && using Revise
import MechanicalSketch: 
    text, circle, Turtle, Pencolor, Penwidth, Forward, Turn,
    HueShift, O, sethue, finish, EM, WI, m, background,
    empty_figure, preview, @svg, setline, Point, placeimage, @draw,
    @imagematrix
import Latexify: @latexify
using PlutoUI
