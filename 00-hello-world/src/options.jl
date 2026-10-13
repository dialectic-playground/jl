# Option parsing: the left-to-right scan of CONV-07 ... CONV-12. It records values and
# collects operands; values and operands are validated afterwards (validation.jl).

"What the scan decided to do."
@enum Action GREET SHOW_HELP SHOW_VERSION

"""
    OptionValue(value, spelled)

A recorded option value and the option as the user wrote it (`-n` or `--name`), which
diagnostics quote (CONV-13).
"""
struct OptionValue
    value::String
    spelled::String
end

"""
    ParsedArgs

Result of the scan: the action, the last `--name` and `--count` values (`nothing` when
absent; last occurrence wins, CONV-11), and the operands in order.
"""
struct ParsedArgs
    action::Action
    name::Union{Nothing,OptionValue}
    count::Union{Nothing,OptionValue}
    operands::Vector{String}
end

"Long options that take a value, mapped to the short letter that shares their slot."
const VALUE_OPTIONS = Dict("name" => 'n', "count" => 'c')

"Short options; both take a value."
const SHORT_OPTIONS = ('n', 'c')

"""
    parse_args(args) -> ParsedArgs

Scan `args` from left to right. Returns as soon as `--help` or `--version` is reached
(CONV-12). Throws [`UsageError`](@ref) for option syntax errors only: an unknown option, a
missing option argument, or `=value` on `--help`/`--version` (CONV-13).
"""
function parse_args(args::AbstractVector{<:AbstractString})::ParsedArgs
    values = Dict{Char,OptionValue}()
    operands = String[]
    index = 1
    only_operands = false
    while index <= length(args)
        token = String(args[index])
        index += 1
        if only_operands || token == "-" || !startswith(token, '-')
            push!(operands, token)                      # CONV-10
        elseif token == "--"
            only_operands = true                        # CONV-09
        elseif startswith(token, "--")
            action, index = parse_long!(values, token, args, index)
            action == GREET || return ParsedArgs(action, nothing, nothing, operands)
        else
            index = parse_short!(values, token, args, index)
        end
    end
    return ParsedArgs(GREET, get(values, 'n', nothing), get(values, 'c', nothing), operands)
end

"""
    parse_long!(values, token, args, index) -> (Action, next_index)

Handle one `--long[=value]` token (CONV-08): no abbreviations, `--name=value` or
`--name value`.
"""
function parse_long!(values::Dict{Char,OptionValue}, token::String, args, index::Int)
    body = SubString(token, 3)                          # bytes 1-2 are "--"
    split_at = findfirst('=', body)
    key = if split_at === nothing
        String(body)
    else
        String(SubString(body, 1, prevind(body, split_at)))
    end
    if key == "help" || key == "version"
        split_at === nothing || throw(UsageError("option '--$key' doesn't allow an argument"))
        return (key == "help" ? SHOW_HELP : SHOW_VERSION), index
    end
    letter = get(VALUE_OPTIONS, key, nothing)
    letter === nothing && throw(UsageError("unrecognized option '$token'"))
    if split_at !== nothing
        value = String(SubString(body, nextind(body, split_at)))
    elseif index <= length(args)
        value = String(args[index])
        index += 1
    else
        throw(UsageError("option '--$key' requires an argument"))
    end
    values[letter] = OptionValue(value, "--" * key)
    return GREET, index
end

"""
    parse_short!(values, token, args, index) -> next_index

Handle one short-option token (CONV-07). Both short options take a value, so the first
letter decides: `-n`/`-c` consume the rest of the token (`-nAda`, `-c2`), or the next token
when the rest is empty. A bundle therefore never continues past `-n` or `-c`.
"""
function parse_short!(values::Dict{Char,OptionValue}, token::String, args, index::Int)
    letter = token[2]                                   # byte 1 is "-"
    letter in SHORT_OPTIONS || throw(UsageError(string("invalid option -- '", letter, "'")))
    rest = SubString(token, nextind(token, 2))
    if !isempty(rest)
        value = String(rest)
    elseif index <= length(args)
        value = String(args[index])
        index += 1
    else
        throw(UsageError(string("option requires an argument -- '", letter, "'")))
    end
    values[letter] = OptionValue(value, string('-', letter))
    return index
end
