# MechanicalSketch
This package is for making sketches using Luxor and MechanicalUnits.

The sketch format is intended for rougly 1/3 of an A4 page, a typical figure for a technical report.

The quantity dimensions (length, velocity, power, force, etc.) combines well with multiple dispatch. An example is the 'arrow' function,  which shows 2d vectors with visual hints to the type of quantity.

The package is developed progressively by writing scripts in the test folder, and putting the most useful pieces of script into functions.

There's no intention to make this very general, rather to add functionality as the need arise.

Sketches should look good and be in a consistent pallette, though. The test images are in .png format, but .svg is better for zooming. For post-editing figures, not all svg editors handle fonts. 'Inkscape' seems to work well. You might need to install additional fonts for some test images.

# Installation
pkg> registry add github.com/hustf/M8
pgk> add MechanicalSketch

You probably want to install the direct dependency MechanicalUnits for REPL calculations. It uses a variant of Unitful for more covenient parsing of units.