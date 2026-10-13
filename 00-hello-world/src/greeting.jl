# Greeting construction: pure functions, no I/O (NFR-05).

"""
    greeting(name) -> String

The greeting line `Hello, NAME!` followed by LF (SRS §1.3). `name` is used verbatim.
"""
greeting(name::AbstractString)::String = string("Hello, ", name, "!\n")

"""
    greetings(config::Config) -> String

The complete standard output for a validated request: `config.count` greeting lines (FR-04).
"""
greetings(config::Config)::String = repeat(greeting(config.name), config.count)
