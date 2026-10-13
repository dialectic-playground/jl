# The application core and its thin I/O shell.

"""
    Outcome(stdout, stderr, status)

Everything one invocation produces: the bytes for standard output and standard error, and
the exit status. Exactly one of the streams is non-empty.
"""
struct Outcome
    stdout::String
    stderr::String
    status::Int
end

"""
    execute(args) -> Outcome

Pure core: parse (CONV-12), handle `--help`/`--version`, validate, and build the greeting.
Usage errors become a CONV-13/CONV-14 diagnostic with status 2 and no standard output
(FR-11). This is the only place where errors are mapped to messages and exit statuses.
"""
function execute(args::AbstractVector{<:AbstractString})::Outcome
    try
        parsed = parse_args(args)
        parsed.action == SHOW_HELP && return Outcome(HELP_TEXT, "", 0)
        parsed.action == SHOW_VERSION && return Outcome(VERSION_TEXT, "", 0)
        return Outcome(greetings(validate(parsed)), "", 0)
    catch err
        err isa UsageError || rethrow()
        return Outcome("", usage_text(err), USAGE_STATUS)
    end
end

"""
    emit(out::IO, err::IO, outcome::Outcome) -> Int

Write the outcome's bytes unchanged (Julia never translates LF to CRLF, CONV-03) and return
its exit status. A failed write, such as a closed pipe (CONV-25), ends the output silently
with status 1.
"""
function emit(out::IO, err::IO, outcome::Outcome)::Int
    try
        isempty(outcome.stdout) || (write(out, outcome.stdout); flush(out))
        isempty(outcome.stderr) || (write(err, outcome.stderr); flush(err))
    catch failure
        failure isa Base.IOError || failure isa ArgumentError || rethrow()
        return 1
    end
    return outcome.status
end

"""
    main(args = ARGS) -> Int

Entry point used by the `dp-hello` launcher: execute, write, and return the exit status. Julia's
`ARGS` are UTF-8 on every OS (on Windows, converted from the UTF-16 command line, CONV-05).
No error escapes as a stack trace (CONV-24).
"""
function main(args::AbstractVector{<:AbstractString}=ARGS)::Int
    try
        return emit(stdout, stderr, execute(args))
    catch failure
        failure isa InterruptException && return 130
        try
            write(stderr, string(TOOL, ": internal error: ", sprint(showerror, failure), "\n"))
        catch
        end
        return 1
    end
end
