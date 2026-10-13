count_of(text, spelled="-c") = D.parse_count(D.OptionValue(text, spelled))
count_error(text, spelled="-c") =
    try
        count_of(text, spelled)
        nothing
    catch err
        err.message
    end

@testset "validation" begin
    @testset "count boundaries (FR-04, FR-05)" begin
        @test count_of("1") == 1
        @test count_of("1000") == 1000
        @test count_of("007") == 7
        @test count_of("0001000") == 1000
        @test count_error("0") == "invalid argument '0' for '-c'"
        @test count_error("000") == "invalid argument '000' for '-c'"
        @test count_error("1001") == "invalid argument '1001' for '-c'"
        @test count_error("99999999999999999999999", "--count") ==
            "invalid argument '99999999999999999999999' for '--count'"
    end

    @testset "count syntax (FR-05)" begin
        for bad in ["", "abc", "-1", "+1", " 1", "1 ", "1.0", "1e3", "0x10", "١"]
            @test count_error(bad) == "invalid argument '$bad' for '-c'"
        end
    end

    @testset "name (FR-03)" begin
        @test D.validate_name(nothing) == "World"
        @test D.validate_name(D.OptionValue("Zoë", "-n")) == "Zoë"
        @test_throws D.UsageError D.validate_name(D.OptionValue("", "-n"))
        err = try
            D.validate_name(D.OptionValue("", "--name"))
        catch e
            e
        end
        @test err.message == "invalid argument '' for '--name'"
    end

    @testset "validate order: operands, name, count" begin
        parsed(args...) = D.parse_args(collect(String, args))
        @test D.validate(parsed()) == D.Config("World", 1)
        @test D.validate(parsed("-n", "Ada", "-c", "3")) == D.Config("Ada", 3)
        @test_throws D.UsageError("extra operand 'x'") D.validate(parsed("x", "-n", ""))
        @test_throws D.UsageError("invalid argument '' for '-n'") D.validate(
            parsed("-n", "", "-c0")
        )
        @test_throws D.UsageError("invalid argument '0' for '-c'") D.validate(parsed("-c0"))
        # Only the winning value is validated (FR-06).
        @test D.validate(parsed("-c", "0", "-c", "2", "-n", "", "-n", "B")) == D.Config("B", 2)
    end
end
