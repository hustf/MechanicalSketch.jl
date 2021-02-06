PS C:\Users\F\.julia\dev\MechanicalSketch\examples> julia --project=.
begin
   push!(LOAD_PATH, Base.find_package("MechanicalSketch"))
   import Pluto
   @async Pluto.run()
end