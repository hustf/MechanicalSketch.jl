"""
    runno(iter)

runno(1:3) runs
   julia "test_1.jl"   and waits for finish
   julia "test_2.jl"  and does not wait but starts:
   julia "test_3.jl"

NOTE: All process output goes to the same file, and can be overwritten by
    following processes. Check the output of the function for failed processes,
    and run those separately.
"""
function runno(iter)
    #procs = [run(pipeline(`julia -E include("test_$(first(iter)).jl")`; stderr = "stderr.txt", stdout="stdout.txt"))]
    #procs = [run(`julia -E include\(\"test_$(first(iter)).jl\"\)`)]
    procs = [run(pipeline(`julia -E include\(\"test_$(first(iter)).jl\"\)`; stderr = "stderr_$(first(iter)).txt", stdout="stdout_$(first(iter)).txt"); wait = false)]
    for i in iter[2:end]
        #push!(procs, run(pipeline(`julia -E include("test_$i.jl")`; stderr = "stderr.txt", stdout="stdout.txt"); wait = false))
        push!(procs, run(pipeline(
                                  `julia -E include\(\"test_$i.jl\"\)`;
                                  stderr = "stderr_$i.txt", stdout="stdout_$i.txt")
               ; wait = false))
    end
    procs
end
runno