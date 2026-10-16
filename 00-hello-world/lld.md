<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [Low-Level Design (LLD) — Standard Terminal Hello World](#low-level-design-lld--standard-terminal-hello-world)
  - [1. Source layout](#1-source-layout)
  - [2. Data types](#2-data-types)
    - [2.1 `ParsedArgs` (options.jl)](#21-parsedargs-optionsjl)
    - [2.2 `Config` (validation.jl)](#22-config-validationjl)
    - [2.3 `Outcome` (app.jl)](#23-outcome-appjl)
    - [2.4 Error type](#24-error-type)
  - [3. Module and function specifications](#3-module-and-function-specifications)
    - [3.1 `parse_args`](#31-parse_args)
    - [3.2 `parse_long!` / `parse_short!`](#32-parse_long--parse_short)
    - [3.3 `validate`, `validate_name`, `parse_count`, `is_count`](#33-validate-validate_name-parse_count-is_count)
    - [3.4 `greeting`, `greetings`](#34-greeting-greetings)
    - [3.5 `execute`](#35-execute)
    - [3.6 `emit`, `main`](#36-emit-main)
  - [4. Algorithms](#4-algorithms)
  - [5. Platform-specific details](#5-platform-specific-details)
  - [6. Resource management](#6-resource-management)
  - [7. Sequence of one invocation](#7-sequence-of-one-invocation)
  - [8. Design-to-code checklist](#8-design-to-code-checklist)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Low-Level Design (LLD) — Standard Terminal Hello World

| Field                   | Value                                                 |
| :---------------------- | :---------------------------------------------------- |
| Project                 | `00-hello-world`                                      |
| Tools                   | dp-hello                                              |
| Implementation language | Julia 1.13 (package `DpHello`)                        |
| Author                  | dialectic-playground/jl maintainers                   |
| Version / date          | 1.0 — 2026-10-13                                      |
| Status                  | Approved                                              |
| Inputs                  | `hld.md`, `specs/SRS.md`, `shared/CLI-CONVENTIONS.md` |

## 1. Source layout

```text
00-hello-world/
├── Project.toml          # package DpHello (UUID, version 1.0.0, julia compat); Pkg workspace root
├── Manifest.toml         # one lockfile for the package, test/, and dev/ environments
├── .JuliaFormatter.toml  # Blue style, margin 96
├── bin/dp-hello          # BIN_DIR launcher (#!/usr/bin/env -S julia …), includes ../src/DpHello.jl
├── src/
│   ├── DpHello.jl        # module definition; includes the files below in dependency order
│   ├── messages.jl       # TOOL, HELP_TEXT, VERSION_TEXT, UsageError, usage_text, invalid_argument
│   ├── options.jl        # Action, OptionValue, ParsedArgs, parse_args, parse_long!, parse_short!
│   ├── validation.jl     # Config, validate, validate_name, parse_count, is_count
│   ├── greeting.jl       # greeting, greetings (pure)
│   └── app.jl            # Outcome, execute, emit, main
├── test/
│   ├── Project.toml      # Test + DpHello
│   ├── runtests.jl       # helpers; includes the five files below
│   └── options_tests.jl, validation_tests.jl, greeting_tests.jl, app_tests.jl, launcher_tests.jl
└── dev/
    ├── Project.toml      # JuliaFormatter, Aqua, DpHello
    └── style.jl          # `format` and `lint` (format check + Aqua.test_all)
```

## 2. Data types

### 2.1 `ParsedArgs` (options.jl)

| Field      | Type                                            | Default   | Constraint / invariant                       | SRS          |
| :--------- | :---------------------------------------------- | :-------- | :------------------------------------------- | :----------- |
| `action`   | `Action` (`GREET`, `SHOW_HELP`, `SHOW_VERSION`) | `GREET`   | Not `GREET` ⇒ the scan stopped at that token | FR-07, FR-08 |
| `name`     | `Union{Nothing,OptionValue}`                    | `nothing` | Last `-n`/`--name` occurrence                | FR-02, FR-06 |
| `count`    | `Union{Nothing,OptionValue}`                    | `nothing` | Last `-c`/`--count` occurrence               | FR-04, FR-06 |
| `operands` | `Vector{String}`                                | `[]`      | In command-line order                        | FR-09        |

`OptionValue(value::String, spelled::String)`: the raw value and the option as written
(`-n`, `--name`, `-c`, `--count`) for CONV-13 messages.

### 2.2 `Config` (validation.jl)

| Field   | Type     | Default   | Constraint / invariant         | SRS           |
| :------ | :------- | :-------- | :----------------------------- | :------------ |
| `name`  | `String` | `"World"` | Non-empty                      | FR-01 … FR-03 |
| `count` | `Int`    | `1`       | `1 ≤ count ≤ MAX_COUNT (1000)` | FR-04, FR-05  |

### 2.3 `Outcome` (app.jl)

`Outcome(stdout::String, stderr::String, status::Int)`: at most one stream is non-empty.

### 2.4 Error type

`UsageError(message::String) <: Exception`; `message` is the CONV-13 text without prefix.

| Variant (message)                                                      | Diagnostic (stderr)                                                             | Exit status |
| :--------------------------------------------------------------------- | :------------------------------------------------------------------------------ | :---------- |
| `invalid option -- 'x'`                                                | `dp-hello: <message>` + LF + `Try 'dp-hello --help' for more information.` + LF | 2           |
| `unrecognized option '<token>'`                                        | same form                                                                       | 2           |
| `option requires an argument -- 'n'` / `'c'`                           | same form                                                                       | 2           |
| `option '--name'` / `'--count' requires an argument`                   | same form                                                                       | 2           |
| `option '--help'` / `'--version' doesn't allow an argument`            | same form                                                                       | 2           |
| `invalid argument '<value>' for '<option>'`                            | same form                                                                       | 2           |
| `extra operand '<operand>'`                                            | same form                                                                       | 2           |
| Output failure (`Base.IOError`, or `ArgumentError` on a closed stream) | none                                                                            | 1 (CONV-25) |

## 3. Module and function specifications

### 3.1 `parse_args`

- **Signature:** `parse_args(args::AbstractVector{<:AbstractString})::ParsedArgs`
- **Responsibility:** the CONV-12 scan.
- **Postconditions:** returns at the first `--help`/`--version` (with no values); otherwise
  every token has been consumed.
- **Errors:** syntax `UsageError`s only (from `parse_long!`/`parse_short!`).
- **Algorithm:** for each token: after `--`, or if it is `-` or does not start with `-` →
  operand; `--` → switch to operands-only; `--…` → `parse_long!`; else `parse_short!`.
- **Complexity:** O(total argument bytes) time and memory.
- **Satisfies:** CONV-07 … CONV-12, FR-06, FR-07, FR-08, FR-10.
- **Unit tests:** the `parse_args` testsets in `test/options_tests.jl`.

### 3.2 `parse_long!` / `parse_short!`

- **Signatures:** `parse_long!(values, token, args, index) -> (Action, next_index)`;
  `parse_short!(values, token, args, index) -> next_index`
- **Long:** split the body after `--` at the first `=`. `help`/`version`: error if `=` is
  present, else return the action. `name`/`count`: the value is the text after `=`, else the
  next token (even if it starts with `-`), else "requires an argument". Anything else
  (including abbreviations and `--=x`): `unrecognized option '<whole token>'` (CONV-08).
- **Short:** the character after `-` must be `n` or `c`, else `invalid option -- '<char>'`
  (the full UTF-8 character). The rest of the token is the value; if it is empty, the next
  token; else "requires an argument". Both short options take values, so a bundle ends there.
- **Satisfies:** CONV-07, CONV-08, CONV-11, CONV-13, FR-02, FR-10.
- **Unit tests:** `value syntax`, `values that start with '-'`, `syntax errors`.

### 3.3 `validate`, `validate_name`, `parse_count`, `is_count`

- **Signatures:** `validate(::ParsedArgs)::Config`; `validate_name(::Union{Nothing,OptionValue})::String`;
  `parse_count(::OptionValue)::Int`; `is_count(::AbstractString)::Bool`
- **Order:** first operand → `extra operand`; then NAME (empty → `invalid argument '' for
'<spelled>'`); then COUNT. Only the winning values are recorded, so FR-06 holds.
- **`is_count`:** every byte is `0x30`–`0x39`; a non-`0` byte must exist (rejects empty and
  zero); at most `ndigits(1000)` = 4 significant digits (no overflow for long inputs); then
  `parse(Int, text) ≤ 1000`.
- **Satisfies:** FR-03, FR-04, FR-05, FR-09, CONV-12, CONV-15.
- **Unit tests:** the `validation` testsets in `test/validation_tests.jl`.

### 3.4 `greeting`, `greetings`

- **Signatures:** `greeting(name::AbstractString)::String`; `greetings(config::Config)::String`
- **Responsibility:** pure construction of `"Hello, " * name * "!\n"`, repeated `count` times.
- **Complexity:** O(count × length(name)).
- **Satisfies:** FR-01, FR-02, FR-04, NFR-05. **Unit tests:** `greeting (NFR-05)`.

### 3.5 `execute`

- **Signature:** `execute(args)::Outcome`
- **Algorithm:** `parse_args`; help/version → fixed text, status 0; else
  `greetings(validate(parsed))`, status 0; `catch UsageError` → `Outcome("", usage_text(err), 2)`.
  Other exceptions are rethrown (they would be defects).
- **Satisfies:** FR-01 … FR-11, CONV-12 … CONV-14. **Unit tests:** `execute (end to end, pure)`.

### 3.6 `emit`, `main`

- **`emit(out::IO, err::IO, outcome)::Int`:** write the non-empty stdout bytes and flush,
  then stderr; return `outcome.status`; on `Base.IOError`/`ArgumentError` return 1 silently.
- **`main(args = ARGS)::Int`:** `emit(stdout, stderr, execute(args))`; on
  `InterruptException` return 130; any other exception → one line
  `dp-hello: internal error: …` on stderr and status 1 (CONV-24).
- **Unit tests:** `emit (binary output)`, `launcher`.

## 4. Algorithms

The only algorithm is the scan (§3.1–3.2): a single pass with an index that `parse_long!` and
`parse_short!` advance when they consume the next token. Strings are indexed by byte
position (`SubString(token, 3)`, `nextind`), which is safe because the prefix bytes are ASCII
`-`, and keeps invalid UTF-8 intact. COUNT is checked byte-wise before `parse`, so `parse`
can neither throw nor overflow.

## 5. Platform-specific details

| Concern                      | Linux                  | macOS                  | Windows                                                      | Abstraction                       |
| :--------------------------- | :--------------------- | :--------------------- | :----------------------------------------------------------- | :-------------------------------- |
| Argument encoding            | bytes as UTF-8         | bytes as UTF-8         | UTF-16 command line → UTF-8 by the Julia runtime             | `ARGS`                            |
| Newline translation          | none                   | none                   | none (libuv streams have no text mode)                       | `write(::IO, ::String)` in `emit` |
| Starting the launcher        | kernel `#!` + `env -S` | kernel `#!` + `env -S` | the runner / Git Bash reads the `#!` line and starts `julia` | `bin/dp-hello`                    |
| Install path in the launcher | absolute path          | absolute path          | may contain `\`; written as a Julia `raw"…"` string          | `DP_INSTALL`                      |

## 6. Resource management

No files, handles, or processes are acquired. Output is one `String` of at most
1000 × (9 + length(NAME)) bytes, written once and flushed. The launcher's runtime flags
`--startup-file=no --compile=min -O0` skip `~/.julia/config/startup.jl` and limit JIT
compilation.

## 7. Sequence of one invocation

`dp-hello -c2 -n Ken` (public test P06): `julia --startup-file=no --compile=min -O0
bin/dp-hello -c2 -n Ken` → `include(src/DpHello.jl)` → `main(["-c2", "-n", "Ken"])` →
`execute` → `parse_args`: `-c2` → `parse_short!` records `OptionValue("2", "-c")`; `-n` →
`parse_short!` takes the next token, `OptionValue("Ken", "-n")` → `ParsedArgs(GREET, …, [])`
→ `validate` → `Config("Ken", 2)` → `greetings` → `"Hello, Ken!\nHello, Ken!\n"` →
`Outcome(…, "", 0)` → `emit` writes 24 bytes → `exit(0)`.

## 8. Design-to-code checklist

| HLD component | LLD section | Source file(s)      | Unit-test file(s)          |
| :------------ | :---------- | :------------------ | :------------------------- |
| options       | §3.1, §3.2  | `src/options.jl`    | `test/options_tests.jl`    |
| validation    | §3.3        | `src/validation.jl` | `test/validation_tests.jl` |
| greeting      | §3.4        | `src/greeting.jl`   | `test/greeting_tests.jl`   |
| messages      | §2.4        | `src/messages.jl`   | `test/app_tests.jl`        |
| app           | §3.5, §3.6  | `src/app.jl`        | `test/app_tests.jl`        |
| launcher      | §5, §7      | `bin/dp-hello`      | `test/launcher_tests.jl`   |
