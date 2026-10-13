# Formatting and static checks for the project (run from the dev environment):
#
#   julia --project=dev --startup-file=no dev/style.jl format   rewrite files in place
#   julia --project=dev --startup-file=no dev/style.jl lint     fail on unformatted files, then Aqua
using JuliaFormatter

const ROOT = dirname(@__DIR__)
# JuliaFormatter only picks up *.jl files; the extensionless launcher is listed explicitly.
const TARGETS = [
    joinpath(ROOT, "src"),
    joinpath(ROOT, "test"),
    joinpath(ROOT, "dev"),
    joinpath(ROOT, "bin", "dp-hello"),
]

function main(mode::String)::Int
    if mode == "format"
        foreach(target -> format(target), TARGETS)
        return 0
    elseif mode == "lint"
        unformatted = filter(target -> !format(target; overwrite=false), TARGETS)
        if !isempty(unformatted)
            println(stderr, "not formatted (run `make format`): ", join(unformatted, ", "))
            return 1
        end
        @eval using Aqua, DpHello
        @eval Aqua.test_all(DpHello)
        return 0
    end
    println(stderr, "usage: style.jl format|lint")
    return 2
end

exit(main(get(ARGS, 1, "")))
