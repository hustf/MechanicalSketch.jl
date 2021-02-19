### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 3cd880f0-6856-11eb-187f-e7fe0238d041
include("config.jl")

# ╔═╡ 78625b00-6856-11eb-0e08-bf8915eb2f5e
md"# A most **basic** test and headline"

# ╔═╡ 9f489670-6857-11eb-16f7-53ecb28dc3a5
md"A paragraph containing a link to [Julia](http://www.julialang.org)."

# ╔═╡ 71383360-6890-11eb-14eb-e39ac006624e
stri = "Da jeg var på vei til kiirken ∈ dag morges så kom jeg forbi en liten sjømann. En frisk og hyggelig liten sjømann som hilste meg."

# ╔═╡ fcdff590-686a-11eb-10ad-0f67e129deda
l1 = text(stri, -0.45 * WI, 0)

# ╔═╡ 240c9390-6892-11eb-3ba7-e95f27ba7e5a
l2 = sethue("yellow")

# ╔═╡ 32b3cc10-6892-11eb-38d2-99a597b4b53c
   l3 = text("1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890",
        -WI / 2, EM)

# ╔═╡ e3ca9330-6892-11eb-2b65-2f98c90f0c9f


# ╔═╡ 5b66cdae-6892-11eb-0a16-91fdc7e0c19e
l4 = circle(O, 20, :stroke)

# ╔═╡ 9796abbe-6892-11eb-2faa-a326479b3b7c
t = Turtle()

# ╔═╡ 9c961ed2-6892-11eb-1fdc-9d379272db73
l5 = Pencolor(t, "cyan")

# ╔═╡ a1d7f210-6892-11eb-1b33-5958ade28f77
l6 = Penwidth(t, 1.5)

# ╔═╡ b5048ba0-6892-11eb-1225-f32767f28867
n = 4

# ╔═╡ bbe038c0-6892-11eb-1333-a70977b4d71c
l7 = for i in 1:200
        Forward(t, n)
        Turn(t, 89.5)
        HueShift(t)
        n += 0.75
    end

# ╔═╡ 53105580-6894-11eb-3af3-3feadd3c43bf
begin
	l1, l2, l3, l4, l5, l6, l7
	this_fig = empty_figure(joinpath(@__DIR__, "pluto_1.png"))
	background("green")
end

# ╔═╡ cad199a0-6892-11eb-2e31-316dc6c8e541
begin
	l1, l2, l3, l4, l5, l6, l7
	finish()
end

# ╔═╡ c4ab80e0-6892-11eb-19a5-cf50d9dc0bdb


# ╔═╡ Cell order:
# ╠═3cd880f0-6856-11eb-187f-e7fe0238d041
# ╟─78625b00-6856-11eb-0e08-bf8915eb2f5e
# ╠═9f489670-6857-11eb-16f7-53ecb28dc3a5
# ╠═53105580-6894-11eb-3af3-3feadd3c43bf
# ╠═71383360-6890-11eb-14eb-e39ac006624e
# ╠═fcdff590-686a-11eb-10ad-0f67e129deda
# ╠═240c9390-6892-11eb-3ba7-e95f27ba7e5a
# ╠═32b3cc10-6892-11eb-38d2-99a597b4b53c
# ╠═e3ca9330-6892-11eb-2b65-2f98c90f0c9f
# ╠═5b66cdae-6892-11eb-0a16-91fdc7e0c19e
# ╠═9796abbe-6892-11eb-2faa-a326479b3b7c
# ╠═9c961ed2-6892-11eb-1fdc-9d379272db73
# ╠═a1d7f210-6892-11eb-1b33-5958ade28f77
# ╠═b5048ba0-6892-11eb-1225-f32767f28867
# ╠═bbe038c0-6892-11eb-1333-a70977b4d71c
# ╠═cad199a0-6892-11eb-2e31-316dc6c8e541
# ╠═c4ab80e0-6892-11eb-19a5-cf50d9dc0bdb
