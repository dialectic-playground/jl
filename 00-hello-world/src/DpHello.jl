"""
    DpHello

`dp-hello` (curriculum project 00): print a greeting to standard output.

The units are kept separate (SRS NFR-04): option parsing (`options.jl`), validation
(`validation.jl`), greeting construction (`greeting.jl`), messages (`messages.jl`), and the
I/O shell (`app.jl`). [`execute`](@ref) is a pure function from arguments to an [`Outcome`](@ref);
[`main`](@ref) performs the only side effects.
"""
module DpHello

include("messages.jl")
include("options.jl")
include("validation.jl")
include("greeting.jl")
include("app.jl")

end # module DpHello
