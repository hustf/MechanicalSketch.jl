#fi = "test_20.jl"
function words(fi)
    wd = String[]
    for line in readlines(fi)
        for w in split(line, r"\W")
            push!(wd, w)
        end
    end
    wd
end
#words(fi)

function word_lastline(fi)
    wdi = Dict{String, Int}()
    for (n, line) in enumerate(readlines(fi))
        words = split(line, r"\W")
        for w in words
            push!(wdi, w => n)
        end
    end
    wdi
end
#word_lastline(fi)

function word_count(fi)
    wdi = Dict{String, Int}()
    for word in keys(word_lastline(fi))
        push!(wdi, word => get(wdi, word, 0) + 1)
    end
    wdi
end
#word_count(fi)

function singlewords_whichline(fi)
    wdi = Dict{String, Int}()
    w_ll = word_lastline(fi)
    for (wd, co) in word_count(fi)
        if co == 1
            push!(wdi, wd => w_ll[wd])
        end
    end
    wdi
end
#singlewords_whichline(fi)
function first_let_line(fi)
    local no = 0
    for (no, line) in enumerate(readlines(fi))
        startswith(strip(line), "let") && return no
    end
    10
end

"For each file, print a list of candidates for unecessary import, ie occuring in the first ten lines of each file and only once"
function loopfiles()
    excludelist = ["MechanicalSketch", "__DIR__", "using", "import"]
    for fi in filter(s->endswith(s, ".jl"), readdir())
        letatline = first_let_line(fi)
        println()
        println(fi, ":")
        wd_li = filter(singlewords_whichline(fi)) do (wd, lin)
            lin < letatline &&
                length(wd) > 1 &&
                    !isnumeric(first(wd)) &&
                        !isdefined(Base, Symbol(wd)) &&
                            wd ∉ excludelist
        end
        byalpha = sort(collect(keys(sort(wd_li, byvalue= true))))
        byline = collect(keys(sort(wd_li, byvalue= true)))
        w_ll = word_lastline(fi)
        for wd in byline
            println(wd, "\t", w_ll[wd])
        end
    end
end
loopfiles()

