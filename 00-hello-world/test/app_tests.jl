@testset "execute (end to end, pure)" begin
    @test outcome() == D.Outcome("Hello, World!\n", "", 0)
    @test outcome("--name", "Ada") == D.Outcome("Hello, Ada!\n", "", 0)
    @test outcome("-c2", "-n", "Ken") == D.Outcome("Hello, Ken!\nHello, Ken!\n", "", 0)
    @test outcome("--help") == D.Outcome(D.HELP_TEXT, "", 0)
    @test outcome("--version") == D.Outcome("dp-hello (dialectic-playground) 1.0.0\n", "", 0)
    @test outcome("extra", "--help").stdout == D.HELP_TEXT
    @test outcome("--count", "0", "--help").stdout == D.HELP_TEXT
    @test outcome("-x", "--help") == D.Outcome("", usage("invalid option -- 'x'"), 2)
    @test outcome("extra") == D.Outcome("", usage("extra operand 'extra'"), 2)
    @test outcome("--", "-n") == D.Outcome("", usage("extra operand '-n'"), 2)
    @test outcome("--name", "") == D.Outcome("", usage("invalid argument '' for '--name'"), 2)
    @test outcome("-c", "abc") == D.Outcome("", usage("invalid argument 'abc' for '-c'"), 2)
    @test outcome("--version=1").status == 2

    @testset "help text matches the user manual" begin
        @test startswith(D.HELP_TEXT, "Usage: dp-hello [OPTION]...\n")
        @test endswith(D.HELP_TEXT, "output version information and exit\n")
        @test count(==('\n'), D.HELP_TEXT) == 8
    end
end

@testset "emit (binary output)" begin
    out, err = IOBuffer(), IOBuffer()
    @test D.emit(out, err, outcome("-n", "Zoë", "-c", "2")) == 0
    @test take!(out) == b"Hello, Zo\xc3\xab!\nHello, Zo\xc3\xab!\n"
    @test isempty(take!(err))

    @test D.emit(out, err, outcome("-x")) == 2
    @test isempty(take!(out))
    @test take!(err) == codeunits(usage("invalid option -- 'x'"))

    closed = IOBuffer()
    close(closed)
    @test D.emit(closed, err, outcome()) == 1           # write failure: silent (CONV-25)
    @test isempty(take!(err))
end
