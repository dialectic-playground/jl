@testset "greeting (NFR-05)" begin
    @test D.greeting("World") == "Hello, World!\n"
    @test D.greeting("Ada Lovelace") == "Hello, Ada Lovelace!\n"
    @test D.greeting("Zoë") == "Hello, Zoë!\n"
    @test codeunits(D.greeting("Zoë")) == b"Hello, Zo\xc3\xab!\n"
    @test D.greeting("-x \$HOME 'q'") == "Hello, -x \$HOME 'q'!\n"
    invalid_utf8 = String(UInt8[0x66, 0xff])
    @test codeunits(D.greeting(invalid_utf8)) == b"Hello, f\xff!\n"   # bytes pass through
    @test D.greetings(D.Config("Ken", 2)) == "Hello, Ken!\nHello, Ken!\n"
    @test count(==('\n'), D.greetings(D.Config("A", 1000))) == 1000
    @test !occursin('\r', D.greetings(D.Config("A", 3)))
end
