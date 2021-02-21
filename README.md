# MechanicalSketch
This package combines Luxor, MechanicalUnits, Latexify, NodeJS and MathJax. It's made on Windows (where latex is hard).

The sketch format is intended for rougly 1/3 of an A4 page, a typical figure for a technical report.

The quantity dimensions (length, velocity, power, force, area, potential, etc.) combines well with multiple dispatch. An example is the 'arrow' function,  which shows 2d vectors with visual hints to the type of quantity.

The package is developed by writing scripts with increasing complexity in the test folder, and putting the most useful pieces of script into functions. They can be used as templates.

There's no intention to make this very general, rather to add functionality as the need arise.

Sketches should look good and be in a consistent pallette. The test images are in .png format, but .svg is better for zooming. For post-editing figures, not all svg editors handle fonts. 'Inkscape' seems to work well. You might need to install additional fonts for some test images.

# Installation
pkg> registry add github.com/hustf/M8
pgk> add MechanicalSketch

Some examples in '/test' assume that ['DejaVu'](https://dejavu-fonts.github.io/Download.html) fonts are installed: . Also recommend is ['Juliamono'](https://cormullion.github.io/)pages/2020-07-26-JuliaMono/#download_and_install.

The direct dependency 'MechanicalUnits' is recommended for  for REPL calculations. It uses a variant of 'Unitfu.jl' for more covenient parsing of units than 'Unitfu'.
