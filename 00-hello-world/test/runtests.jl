# Unit tests for DpHello (Test standard library). Run with `make test-unit`.
using DpHello
using Test

const D = DpHello

"Parse `args` and return the recorded (name, count) values, or `nothing` when absent."
function parsed_values(args...)
    parsed = D.parse_args(collect(String, args))
    value(option) = option === nothing ? nothing : option.value
    return (value(parsed.name), value(parsed.count))
end

"The diagnostic first line produced by parsing `args`."
parse_error(args...) =
    try
        D.parse_args(collect(String, args))
        nothing
    catch err
        err isa D.UsageError ? err.message : rethrow()
    end

"Run the pure core on `args`."
outcome(args...) = D.execute(collect(String, args))

usage(message) = "dp-hello: $message\nTry 'dp-hello --help' for more information.\n"

include("options_tests.jl")
include("validation_tests.jl")
include("greeting_tests.jl")
include("app_tests.jl")
include("launcher_tests.jl")
