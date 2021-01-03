"""
Combine Runge-Kutta 4th order and convolution. The result is
phase = arg(ŝ) and magnitude = hypot(ŝ)
"""
function z_transform_32_hann(f_xy, n_xy, x_mid, y_mid, f_s, f_0, wave_per_streamline)
    x, y = x_mid, y_mid
    # Unitless, normalized circular frequency of interest
    ω_0n = 2π ∙ f_0 / f_s
    # Frequency of interest position on the complex unit circle
    z = exp(-im * ω_0n)
    # z-transform aggregator, complex, start at mid point
    ŝ = n_xy(x, y) * z^0
    # Step length (time), negative for backwards.
    h = -1 / f_s
    for nn in -1:-1:-9
        fx0, fy0 = f_xy(x, y)
        x1 = x + fx0 * h * 0.5
        y1 = y + fy0 * h * 0.5
        fx1, fy1 = f_xy(x1, y1)
        x2 = x + fx1 * h * 0.5
        y2 = y + fy1 * h * 0.5
        fx2, fy2  = f_xy(x2, y2)
        x3 = x + fx2 * h
        y3 = y + fy2 * h
        fx3, fy3 = f_xy(x3, y3)
        x +=  h * ( fx0  + 2∙fx1 + 2∙fx2 + fx3 ) / 6
        y +=  h * ( fy0  + 2∙fy1 + 2∙fy2 + fy3 ) / 6
        ŝ += (n_xy(x, y)) * z^-nn * (cos(π * nn / 20)^2)
    end
    # Jump back to start
    x = x_mid
    y = y_mid
    # Switch to walking forwards
    h = -h
    for nn in 1:10
        fx0, fy0 = f_xy(x, y)
        x1 = x + fx0 * h * 0.5
        y1 = y + fy0 * h * 0.5
        fx1, fy1 = f_xy(x1, y1)
        x2 = x + fx1 * h * 0.5
        y2 = y + fy1 * h * 0.5
        fx2, fy2  = f_xy(x2, y2)
        x3 = x + fx2 * h
        y3 = y + fy2 * h
        fx3, fy3 = f_xy(x3, y3)
        x +=  h * ( fx0  + 2∙fx1 + 2∙fx2 + fx3 ) / 6
        y +=  h * ( fy0  + 2∙fy1 + 2∙fy2 + fy3 ) / 6
        ŝ += n_xy(x, y) * z^-nn * (cos(π * nn / 20)^2)
    end
    if wave_per_streamline == 1 
        ŝ
    else
        θ = sawtooth(angle(ŝ), π / wave_per_streamline)
        hypot(ŝ) * exp(θ*im)
    end
end


import MechanicalSketch.Drawing
import MechanicalSketch.origin
import MechanicalSketch.Luxor.AnimatedGif

function run_ffmpeg(framerate, outdirectory, tempdirectory, movietitle; usenewffmpeg = true)
    @assert isdir(tempdir)
    shortoutname = movietitle * (occursin(movietitle, ".gif") ? "" : ".gif")
    longfilenameout = joinpath(tempdirectory, shortoutname)
    feedbackfile = joinpath(tempdirectory, "ffmpegerr.log")
    strarg = "[0:v] split [a][b]; [a] palettegen=stats_mode=full:reserve_transparent=on:transparency_color=FFFFFF [p]; [b][p] paletteuse=new=1:alpha_threshold=128"
    cmd_exe = "ffmpeg" # Command, assuming its path is part of environment variable PATH
    cmd_args = ["-loglevel info",
              "-framerate $(framerate)",
              "-f image2",
              """-i $(joinpath(tempdirectory, "%10d.png"))""",
              "-filter_complex \"$strarg\"",
              "-y $longfilenameout"]
    cmd_arr = [cmd_exe, join(cmd_args, ' ')]
    cmd_optless = Cmd(cmd_arr)
    cmd = Cmd(cmd_optless, 
        ignorestatus=true, detach=false, windows_verbatim = true, windows_hide = false)
    processoutcome = run(cmd)
    if processoutcome.exitcode != 0
        @error """
        Command $cmd_exe was found, but the process exited with an error:
        $processoutcome
        You may get more detailed feedback from running as a Powershell command:
            Start-Process $(join(cmd_args, ' '))
        Installing ffmpeg libraries on Windows may require running an installer.
        """
    end
end


function phase_histog(v, n_bins)
    binwidth = 2π / n_bins
    binends = range(binwidth - π, π, length = n_bins)
    binno(θ) = 1 + round(Int, (θ + π)/ (binwidth ), RoundDown)
    bincounts = [0 for bin in binends]
    for x in v
        θ = angle(x)
        bincounts[binno(θ)] += 1
    end
    binends, binwidth, normalize_datarange(bincounts / sum(bincounts))
end
function convolute_image_32(xs, ys, f_xy, n_xy, f_s, f_0, cutoff, wave_per_streamline)
    M = Array{Complex{Float64}}(undef, length(ys), length(xs)) # Image processing convention: a column has a horizontal line of pixels
    @assert eltype(xs) <: Quantity{Float64}
    @assert eltype(ys) <: Quantity{Float64}
    @assert n_xy(xs[1], ys[1]) isa Float64
    rowsy = length(ys)
    for (i::Int64, x::Quantity{Float64}) in enumerate(xs), (j::Int64, y::Quantity{Float64}) in enumerate(ys)
        # Find the complex intensity for our one pixel.
        pv  = z_transform_32_hann(f_xy, n_xy, x, y, f_s, f_0, wave_per_streamline)
        # Find the original indexes and update the image matrix
        M[rowsy + 1 - j, i] = pv
    end
    M
end

"
Return x for the interval >-maxabs, x, maxabs>
"
sawtooth(x, maxabs ) = rem(x, 2maxabs, RoundNearest)