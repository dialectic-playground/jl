# Validation after the scan (CONV-12): operands first, then NAME, then COUNT.

"Largest accepted COUNT (FR-04)."
const MAX_COUNT = 1000

"""
    Config(name, count)

A validated request: a non-empty `name` and a `count` in `1:MAX_COUNT`.
"""
struct Config
    name::String
    count::Int
end

"""
    validate(parsed::ParsedArgs) -> Config

Check operands (FR-09), NAME (FR-03), and COUNT (FR-04, FR-05) in that order and return the
validated [`Config`](@ref). Throws [`UsageError`](@ref) for the first problem found.
"""
function validate(parsed::ParsedArgs)::Config
    isempty(parsed.operands) ||
        throw(UsageError(string("extra operand '", first(parsed.operands), "'")))
    name = validate_name(parsed.name)
    count = parsed.count === nothing ? 1 : parse_count(parsed.count)
    return Config(name, count)
end

"""
    validate_name(option) -> String

`"World"` when `--name` was not given; otherwise the value, which must not be empty (FR-03).
"""
function validate_name(option::Union{Nothing,OptionValue})::String
    option === nothing && return "World"
    isempty(option.value) && throw(invalid_argument(option.value, option.spelled))
    return option.value
end

"""
    parse_count(option::OptionValue) -> Int

The value of COUNT, which must pass [`is_count`](@ref) (FR-04, FR-05).
"""
function parse_count(option::OptionValue)::Int
    is_count(option.value) || throw(invalid_argument(option.value, option.spelled))
    return parse(Int, option.value)
end

"""
    is_count(text) -> Bool

`true` when `text` is ASCII decimal digits only (leading zeros allowed) with a value in
`1:MAX_COUNT`. Arbitrarily long digit strings are judged without overflow.
"""
function is_count(text::AbstractString)::Bool
    digits = codeunits(text)
    all(b -> UInt8('0') <= b <= UInt8('9'), digits) || return false
    significant = findfirst(!=(UInt8('0')), digits)
    significant === nothing && return false             # empty, or zero
    length(digits) - significant + 1 <= ndigits(MAX_COUNT) || return false
    return parse(Int, text) <= MAX_COUNT
end
