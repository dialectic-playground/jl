@testset "parse_args" begin
    @testset "value syntax (CONV-07, CONV-08)" begin
        @test parsed_values() == (nothing, nothing)
        @test parsed_values("-n", "Ada") == ("Ada", nothing)
        @test parsed_values("-nAda") == ("Ada", nothing)
        @test parsed_values("--name", "Ada") == ("Ada", nothing)
        @test parsed_values("--name=Ada") == ("Ada", nothing)
        @test parsed_values("--name=") == ("", nothing)
        @test parsed_values("--name=a=b") == ("a=b", nothing)
        @test parsed_values("-c", "3") == (nothing, "3")
        @test parsed_values("--count=3") == (nothing, "3")
        @test parsed_values("-c2", "-nKen") == ("Ken", "2")
    end

    @testset "values that start with '-' (FR-02)" begin
        @test parsed_values("--name", "-x") == ("-x", nothing)
        @test parsed_values("--name=-x") == ("-x", nothing)
        @test parsed_values("-n-x") == ("-x", nothing)
        @test parsed_values("-n", "--help") == ("--help", nothing)
        @test parsed_values("-cn") == (nothing, "n")       # -c consumes the rest of the bundle
    end

    @testset "spelling is recorded for diagnostics" begin
        @test D.parse_args(["-nA"]).name.spelled == "-n"
        @test D.parse_args(["--name=A"]).name.spelled == "--name"
        @test D.parse_args(["--count", "1"]).count.spelled == "--count"
    end

    @testset "last occurrence wins (CONV-11)" begin
        @test parsed_values("-n", "A", "-n", "B") == ("B", nothing)
        @test parsed_values("-n", "", "--name=B") == ("B", nothing)
        @test D.parse_args(["--name=A", "-nB"]).name.spelled == "-n"
    end

    @testset "operands and terminator (CONV-09, CONV-10)" begin
        @test D.parse_args(["extra"]).operands == ["extra"]
        @test D.parse_args(["-"]).operands == ["-"]
        @test D.parse_args(["a", "-n", "X", "b"]).operands == ["a", "b"]
        @test D.parse_args(["--", "-n", "--help"]).operands == ["-n", "--help"]
        @test D.parse_args(["--", "--"]).operands == ["--"]
    end

    @testset "--help and --version in scan order (CONV-12)" begin
        @test D.parse_args(["--help"]).action == D.SHOW_HELP
        @test D.parse_args(["--version"]).action == D.SHOW_VERSION
        @test D.parse_args(["--help", "-x"]).action == D.SHOW_HELP
        @test D.parse_args(["--version", "--help"]).action == D.SHOW_VERSION
        @test D.parse_args(["extra", "--help"]).action == D.SHOW_HELP
        @test D.parse_args(["--count", "0", "--help"]).action == D.SHOW_HELP
        @test parse_error("-x", "--help") == "invalid option -- 'x'"
        @test parse_error("--nam", "--version") == "unrecognized option '--nam'"
    end

    @testset "syntax errors (CONV-13)" begin
        @test parse_error("-x") == "invalid option -- 'x'"
        @test parse_error("-xn") == "invalid option -- 'x'"
        @test parse_error("-é") == "invalid option -- 'é'"
        @test parse_error("--nme", "Ada") == "unrecognized option '--nme'"
        @test parse_error("--nam") == "unrecognized option '--nam'"
        @test parse_error("--names=x") == "unrecognized option '--names=x'"
        @test parse_error("--=x") == "unrecognized option '--=x'"
        @test parse_error("-n") == "option requires an argument -- 'n'"
        @test parse_error("-c") == "option requires an argument -- 'c'"
        @test parse_error("--name") == "option '--name' requires an argument"
        @test parse_error("--count") == "option '--count' requires an argument"
        @test parse_error("--help=") == "option '--help' doesn't allow an argument"
        @test parse_error("--version=1") == "option '--version' doesn't allow an argument"
    end
end
