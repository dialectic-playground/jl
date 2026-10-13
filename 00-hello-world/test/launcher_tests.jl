# The launcher in BIN_DIR, as a child process: real ARGS decoding and binary output.
const LAUNCHER = joinpath(@__DIR__, "..", "bin", "dp-hello")

function launch(args...)
    cmd = `$(Base.julia_cmd()) --startup-file=no --compile=min -O0 $LAUNCHER $(collect(args))`
    out, err = IOBuffer(), IOBuffer()
    process = Base.run(pipeline(ignorestatus(cmd); stdin=devnull, stdout=out, stderr=err))
    return (take!(out), take!(err), process.exitcode)
end

@testset "launcher" begin
    @test launch("-n", "Zoë", "-c", "2") ==
        (b"Hello, Zo\xc3\xab!\nHello, Zo\xc3\xab!\n", UInt8[], 0)
    @test launch("--name=Ada Lovelace") == (b"Hello, Ada Lovelace!\n", UInt8[], 0)
    out, err, status = launch("--nme", "Ada")
    @test (out, status) == (UInt8[], 2)
    @test err == codeunits(usage("unrecognized option '--nme'"))
end
