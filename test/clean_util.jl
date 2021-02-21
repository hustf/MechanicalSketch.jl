#fi = "test_22.jl"
read_all_lines(fi) = readlines(fi)
function read_all_lines(fis::Vector)
    lins = String[]
    for fi in fis
        push!(lins, readlines(fi)...)
    end
    lins
end

function line_no(fi, no)
    read_all_lines(fi)[no]
end
function words(fi)
    wd = String[]
    for line in read_all_lines(fi)
        for w in split(line, r"\W")
            push!(wd, w)
        end
    end
    wd
end
#words(fi)
function word_lastline(fi)
    wdi = Dict{String, Int}()
    for (n, line) in enumerate(read_all_lines(fi))
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
    lins = readlines(fi)
    n = length(lins)
    crite(l) = startswith(strip(l), "let") || startswith(strip(l), "#let")
    findfirst(crite, lins)
end
function referred_files(fi)
    reffis = String[]
    for (no, line) in enumerate(readlines(fi))
        if startswith(strip(line), "include(")
            sp, lp = findall("\"", line)
            push!(reffis, line[sp[1] + 1:lp[1] - 1])
        end
    end
    reffis
end

"""
    loopfiles(;mustinclude = "")

For each file, print a list of candidates for unecessary import, ie occuring in the first ten lines of each file and only once"
"""
function loopfiles(;mustinclude = "")
    excludelist = ["MechanicalSketch", "__DIR__", "using", "import", "Test"]
    for fi in filter(s->endswith(s, ".jl"), readdir())
        if contains(fi, mustinclude)
            referredfiles = referred_files(fi)
            fis = [fi; referredfiles...]
            letatline = first_let_line(fi)
            printstyled(stdout, "\n", fi, ":\n"; color=:yellow)
            wd_li = filter(singlewords_whichline(fis)) do (wd, lin)
                lin < letatline &&
                    length(wd) > 1 &&
                        !isnumeric(first(wd)) &&
                            !isdefined(Base, Symbol(wd)) &&
                                wd ∉ excludelist
            end
            byline = collect(keys(sort(wd_li, byvalue= true)))
            w_ll = word_lastline(fis)
            println("Single occurence words:")
            plno = 0
            lstr = ""
            for wd in byline
                lno = wd_li[wd]
                if lno > plno || wd == last(byline)
                    rstr = " at line $plno"
                    plno > 0 && println(lpad(lstr, 70), rstr)
                    lstr = wd
                    plno = lno
                else
                    lstr *= ", " * wd
                end
            end
        end
    end
end
println("""Example: loopfiles(mustinclude = "22")""")

