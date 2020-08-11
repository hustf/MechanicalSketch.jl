# MechanicalSketch
This package is for making sketches using Luxor and MechanicalUnits.

The sketch format is intended for rougly 1/3 of an A4 page, a typical figure for a technical report.

The quantity dimensions (length, velocity, power, force, etc.) combines well with multiple dispatch. 

An example is the 'arrow' function,  which represents 2d vectors.

The package is developed progressively by writing scripts in the test folder, and putting the most useful pieces of script into functions.

There's no intention to make this very general, and we would probably be better off reading all of Luxor's documentation.

Sketches should look good and be in a consistent pallette, though. The test images are in .png format, but .svg is better for zooming.
