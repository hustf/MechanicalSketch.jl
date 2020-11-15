function labelelledtri()
    p1 = O + (10EM, 0)
    line(O, p1, :stroke)
    label(string(p1), :SE, p1)

    p2 = p1 + (0, 10EM)
    line(p1, p2, :stroke)
    label(string(p2), :SE, p2)

    setdash("longdashed")
    line(p2, O, :stroke)
    setdash("solid")
    label("longdashed", :NE, midpoint(p2, O))

    fontface("Calibri-bold")
    fontsize(FS * 1.2)
    label("Rotation " * string(round(getrotation()*180/π)) * "°", :N, midpoint(O, p1))
    fontsize(FS)
end
