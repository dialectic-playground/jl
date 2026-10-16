<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [High-Level Design (HLD) — Standard Terminal Hello World](#high-level-design-hld--standard-terminal-hello-world)
  - [1. Introduction](#1-introduction)
    - [1.1 Scope](#11-scope)
    - [1.2 Definitions and acronyms](#12-definitions-and-acronyms)
    - [1.3 References](#13-references)
  - [2. Requirements summary](#2-requirements-summary)
  - [3. Architectural overview](#3-architectural-overview)
    - [3.1 Context diagram](#31-context-diagram)
    - [3.2 Component (module) decomposition](#32-component-module-decomposition)
    - [3.3 Data flow](#33-data-flow)
  - [4. Key design decisions](#4-key-design-decisions)
  - [5. Cross-platform strategy](#5-cross-platform-strategy)
  - [6. Error handling and diagnostics](#6-error-handling-and-diagnostics)
  - [7. Non-functional design](#7-non-functional-design)
  - [8. Risks and open issues](#8-risks-and-open-issues)
  - [9. Approval](#9-approval)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# High-Level Design (HLD) — Standard Terminal Hello World

| Field                   | Value                                                                                                   |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| Project                 | `00-hello-world`                                                                                        |
| Tools                   | dp-hello                                                                                                |
| Implementation language | Julia 1.13 (package `DpHello`)                                                                          |
| Author                  | dialectic-playground/jl maintainers                                                                     |
| Version / date          | 1.0 — 2026-10-13                                                                                        |
| Status                  | Approved                                                                                                |
| Inputs                  | `specs/URD.md`, `specs/SRS.md`, `specs/user-manual.md`, `shared/CLI-CONVENTIONS.md` (curriculum v1.4.0) |

## 1. Introduction

### 1.1 Scope

`dp-hello` writes `Hello, NAME!` + LF to standard output COUNT times (NAME defaults to
`World`, COUNT to 1, range 1–1000), prints the specified help and version texts, and reports
usage errors with the exact CONV-13/CONV-14 diagnostics and exit status 2. It reads no input,
takes no operands, touches no files, reads no environment variables, and starts no processes
(SRS §1.2, NFR-07).

### 1.2 Definitions and acronyms

| Term         | Meaning                                                                                                |
| :----------- | :----------------------------------------------------------------------------------------------------- |
| Scan         | The single left-to-right pass over the arguments defined by CONV-12                                    |
| Syntax error | Unknown option, missing option argument, or `=value` on `--help`/`--version`; reported during the scan |
| Value error  | Empty NAME, invalid COUNT, or an operand; reported after the scan                                      |
| Outcome      | The complete result of one invocation: stdout bytes, stderr bytes, exit status                         |
| Launcher     | The extensionless `#!` Julia script `bin/dp-hello` that loads the sources and calls `main`             |

### 1.3 References

- SRS §3 (interfaces), §4 (FR-01 … FR-11), §5 (NFR-01 … NFR-07), §6 (diagnostics)
- CLI-CONV §3 (CONV-07 … CONV-12), §4.1 (CONV-13 … CONV-15), CONV-03, CONV-05, CONV-24, CONV-25, CONV-31

## 2. Requirements summary

| Area                     | SRS requirements                                     | Architectural impact                                                                                     |
| :----------------------- | :--------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| Option parsing           | FR-02, FR-06, FR-07, FR-08, FR-10; CONV-07 … CONV-12 | A hand-written scanner that only records values and collects operands, and stops at `--help`/`--version` |
| Validation               | FR-03, FR-04, FR-05, FR-09                           | A separate pass after the scan, so value and operand errors never beat `--help` (CONV-12)                |
| Greeting                 | FR-01, FR-02, FR-04; NFR-05                          | A pure function from a validated `Config` to the output text                                             |
| Diagnostics, exit status | FR-11, §3.7, §6; CONV-13, CONV-14                    | One error type, mapped to text and status in exactly one place                                           |
| Output                   | NFR-01; CONV-03, CONV-25                             | All output built in memory first, then written as raw bytes in one place                                 |
| Start-up                 | NFR-02, CONV-31                                      | Launcher includes the sources and runs with `--compile=min -O0`; no package loading or depot needed      |

## 3. Architectural overview

### 3.1 Context diagram

```text
   ARGS (UTF-8) ──▶ ┌────────────────────────────────┐ ──▶ stdout (greeting / help / version)
                    │ julia ─ bin/dp-hello ─ DpHello │ ──▶ stderr (CONV-13/14 diagnostic)
                    └────────────────────────────────┘ ──▶ exit status 0 / 2
   (no stdin, files, environment, network, or child processes)
```

### 3.2 Component (module) decomposition

| Component  | File                | Responsibility                                                                  | Depends on            |
| :--------- | :------------------ | :------------------------------------------------------------------------------ | :-------------------- |
| messages   | `src/messages.jl`   | Canonical name, help and version texts, `UsageError`, diagnostic formatting     | —                     |
| options    | `src/options.jl`    | The CONV-12 scan: turn `ARGS` into `ParsedArgs` or throw a syntax `UsageError`  | messages              |
| validation | `src/validation.jl` | Turn `ParsedArgs` into a validated `Config` or throw a value `UsageError`       | messages, options     |
| greeting   | `src/greeting.jl`   | Pure construction of the greeting text                                          | validation (`Config`) |
| app        | `src/app.jl`        | `execute` (pure core → `Outcome`), `emit` (byte output), `main` (entry point)   | all of the above      |
| launcher   | `bin/dp-hello`      | Locate and include the sources, call `DpHello.main(ARGS)`, exit with its status | app                   |

### 3.3 Data flow

`julia` starts the launcher, which includes `src/DpHello.jl` and calls `main(ARGS)`.
`main` calls `execute(ARGS)`: `parse_args` scans the arguments and returns a `ParsedArgs`
(action, recorded values, operands). For `SHOW_HELP`/`SHOW_VERSION`, `execute` returns the
fixed text. Otherwise `validate` produces a `Config`, and `greetings(config)` builds the
output text. Any `UsageError` becomes an `Outcome` with empty stdout, the two diagnostic lines
on stderr, and status 2. `emit` writes the outcome's bytes and returns the status, which the
launcher passes to `exit`.

## 4. Key design decisions

| #   | Decision                                                                  | Alternatives considered          | Rationale                                                                                                                                                                                 |
| :-- | :------------------------------------------------------------------------ | :------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | Pure core `execute(args) -> Outcome`, thin I/O shell `emit`/`main`        | Writing from inside the parser   | Whole-program behavior is unit-testable without processes; FR-11 holds by construction because nothing is written before the outcome is complete                                          |
| D2  | Buffer the whole output, then one write                                   | Stream line by line              | At most 1000 lines of a command-line-sized name; one write keeps output atomic and EPIPE handling in one place                                                                            |
| D3  | Usage errors as an exception type (`UsageError`) caught only in `execute` | Result/`Union` return values     | Idiomatic Julia; the single `catch` is the single mapping point to text and status (§6)                                                                                                   |
| D4  | Scan records, validation decides (two passes)                             | Validate values during the scan  | Required by CONV-12 (v1.4.0): `--count 0 --help` must print the help                                                                                                                      |
| D5  | Launcher `include`s the sources; no `using DpHello`                       | Load a precompiled package image | The black-box runner passes only `PATH` (CONV-29), so the depot holding precompiled images is unknown; `include` with `--compile=min -O0` starts in about 0.2 s and needs no depot at all |
| D6  | No third-party runtime dependencies                                       | Argument-parsing packages        | Required by the curriculum; Base suffices                                                                                                                                                 |

## 5. Cross-platform strategy

- **Line endings (CONV-03):** every generated line ends in `"\n"`. Julia's I/O (libuv) never
  translates LF to CRLF on any OS, so stdout and stderr are effectively binary on Windows.
  `emit` writes `String` bytes with `write`.
- **UTF-8 arguments (CONV-05):** Julia's `ARGS` are `String`s holding UTF-8; on Windows the
  runtime converts the UTF-16 command line to UTF-8 before `ARGS` is built. Names are copied
  byte for byte (even invalid UTF-8 on POSIX).
- **Launcher:** `#!/usr/bin/env -S julia …` on Linux and macOS; on Windows the black-box
  runner (and Git Bash/MSYS2 for users) starts `julia` with the same options. The launcher
  finds the sources with `@__DIR__`, which works with either path separator.
- **Paths (CONV-19 … CONV-21):** not applicable; the tool touches no files.
- Platform differences are fully absorbed by the Julia runtime; no module needs OS checks.

## 6. Error handling and diagnostics

Syntax errors are thrown by `options.jl`, value and operand errors by `validation.jl`, all as
`UsageError(message)` with the CONV-13 text. `execute` (`src/app.jl`) is the only place that
catches them and turns them into `dp-hello: <message>` + `Try 'dp-hello --help' for more
information.` with status 2 (`usage_text`, `USAGE_STATUS`). Output failures (EPIPE, CONV-25)
are caught in `emit` and end the run silently with status 1. Any unexpected exception is
caught in `main` and reported as a one-line internal error, never a stack trace (CONV-24).

## 7. Non-functional design

| Quality attribute           | SRS reference   | How the design achieves it                                                                                                                                                                                           |
| :-------------------------- | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Performance / memory        | NFR-02, CONV-31 | Base only, sources included without package loading, `--compile=min -O0` (about 0.2 s instead of 1.1 s with full JIT); output of at most 1000 short lines held once in memory. Measured in the master test plan §4.4 |
| Portability                 | NFR-01          | Julia runtime handles UTF-8 `ARGS` and untranslated byte output on all OSes (§5)                                                                                                                                     |
| Robustness                  | NFR-03          | Every exception path ends in a diagnostic or a silent exit; no stack trace                                                                                                                                           |
| Security / input validation | NFR-07          | No file, environment, or process access; COUNT is validated byte-wise before `parse`                                                                                                                                 |
| Maintainability             | NFR-04, NFR-05  | One file per unit (§3.2); greeting construction is pure                                                                                                                                                              |

## 8. Risks and open issues

| Risk / issue                                                                                                                                           | Likelihood | Impact | Mitigation                                                                                                |
| :----------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- | :----- | :-------------------------------------------------------------------------------------------------------- |
| Julia start-up exceeds the 300 ms interpreted-runtime budget on slow CI runners                                                                        | M          | L      | `--compile=min -O0`; measured locally at 0.17–0.26 s; the runner timeout is 10 s                          |
| Peak RSS above the empty-program baseline is about 40 MiB, mostly runtime code pages faulted in by parsing and lowering (private memory about +10 MiB) | H          | L      | Recorded in the test plan §4.4 and the RTM gaps; a precompiled package image measured no better (+33 MiB) |
| Formatter/Aqua versions drift between environments                                                                                                     | L          | M      | Locked in the committed `Manifest.toml` for the container and native CI alike                             |

## 9. Approval

| Role     | Name                                | Date       | Decision  |
| :------- | :---------------------------------- | :--------- | :-------- |
| Author   | dialectic-playground/jl maintainers | 2026-10-13 | Submitted |
| Reviewer | Pull-request review                 | 2026-10-13 | Pending   |
