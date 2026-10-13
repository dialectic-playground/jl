# Fixed texts and diagnostic formatting (CONV-01, CONV-02, CONV-13, CONV-14, CONV-23).

"Canonical tool name used in every message (CONV-01); never derived from the program path."
const TOOL = "dp-hello"

"The help text from the user manual, byte for byte (FR-07, CONV-23)."
const HELP_TEXT = """
Usage: dp-hello [OPTION]...
Print a greeting to standard output.

Options:
  -n, --name=NAME     greet NAME instead of World
  -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)
      --help          display this help and exit
      --version       output version information and exit
"""

"The version line (FR-08, CONV-02)."
const VERSION_TEXT = "dp-hello (dialectic-playground) 1.0.0\n"

"Exit status of a usage error (CONV-14)."
const USAGE_STATUS = 2

"""
    UsageError(message)

A command-line usage error. `message` is the CONV-13 text without the `dp-hello: ` prefix.
"""
struct UsageError <: Exception
    message::String
end

Base.showerror(io::IO, err::UsageError) = print(io, TOOL, ": ", err.message)

"""
    usage_text(err::UsageError) -> String

The two diagnostic lines for `err` (CONV-13 and CONV-14), each ending in LF.
"""
function usage_text(err::UsageError)
    return string(TOOL, ": ", err.message, "\nTry '", TOOL, " --help' for more information.\n")
end

"`invalid argument '<value>' for '<option>'` (CONV-13, CONV-15)."
function invalid_argument(value::AbstractString, option::AbstractString)
    return UsageError(string("invalid argument '", value, "' for '", option, "'"))
end
