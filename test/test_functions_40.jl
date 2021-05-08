# For debugging
function markit(pcpt, cpt)
    circle(pcpt, r = 10mm)
    line(pcpt, cpt + (-0.2EM, 0), :stroke)
    circle(cpt + (-0.2EM, 0), r = 20mm)
end

# Plots default
default(titlefont = (20, "times"), legendfontsize = 26, 
        guidefont = (30, :darkgreen), tickfont = (24, :orange), 
        framestyle = :origin, minorgrid = true,
        legend = :topleft, linewidth = 4,
        bottom_margin = 18px, left_margin = 18px)