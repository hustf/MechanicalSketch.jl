"y is up, same scale as x"
scaledisty() = -SCALEDIST
"y is up, same scale as x"
scalevelocityy() = -SCALEVELOCITY
"y is up, same scale as x"
scaleforcey() = -SCALEFORCE


"""
    setscale_dist(s::L) where {L <: Length}

To reset default 20m per screen height H:
    setscale_dist()
"""
function setscale_dist(s::L) where {L <: Length}
    global SCALEDIST = s
end
setscale_dist() = setscale_dist(20m / H)

"""
    setscale_velocity(s::V) where {V <: Velocity}

To reset default 70 m/s per screen height H
    setscale_velocity()
"""
function setscale_velocity(s::V) where {V <: Velocity}
    global SCALEVELOCITY = s
end
setscale_velocity() = setscale_velocity(70m/s / H)

"""
    setscale_force(s::F) where {F <: Force}

To reset default 20kN per screen height H:
    setscale_force()
"""
function setscale_force(s::F) where {F <: Force}
    global SCALEFORCE = s
end
setscale_force() = setscale_force(20kN / H)

scale(q::Length) = q / SCALEDIST
scale(q::Velocity) = q/ SCALVELOCITY
scale(q::Force) = q/ SCALEFORCE
