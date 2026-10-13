# Requirements Traceability Matrix (RTM) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Author | dialectic-playground/jl maintainers |
| Version / date | 1.0 — 2026-10-13 |

Unit tests are cited as `<file>: <testset>` (files under `test/`); black-box tests as P01–P10.
Code paths are relative to `00-hello-world/`.

## 1. User requirements to system requirements

| User requirement (URD) | Derived system requirements (SRS) |
| :-- | :-- |
| UR-01 | FR-01 |
| UR-02 | FR-02 |
| UR-03 | FR-04 |
| UR-04 | FR-07 |
| UR-05 | FR-08 |
| UR-06 | FR-03, FR-05, FR-09, FR-10, FR-11 |
| UR-07 | FR-01, SRS §3.7 |
| UR-08 | NFR-01, CONV-03 |
| UR-09 | FR-02, CONV-05 |
| UR-10 | FR-06, FR-10, CONV-07 … CONV-15 |
| UR-11 | NFR-02 |
| UR-12 | NFR-06 |

## 2. Forward traceability

| Req. ID | Summary | Design (HLD/LLD) | Code (file::function) | Verification (unit / black-box) | Status |
| :-- | :-- | :-- | :-- | :-- | :-- |
| UR-01 … UR-12 | User needs | HLD §2 | via the FR/NFR rows below | via the FR/NFR rows below | Verified |
| FR-01 | Default greeting | HLD §3.3; LLD §3.4 | `src/validation.jl::validate_name`, `src/greeting.jl::greeting` | `app_tests.jl: execute`; P01 | Verified |
| FR-02 | Named greeting, verbatim UTF-8 | LLD §3.2, §3.4 | `src/options.jl::parse_long!`, `parse_short!`; `src/greeting.jl::greeting` | `options_tests.jl: value syntax`, `values that start with '-'`; `greeting_tests.jl`; `launcher_tests.jl` (Zoë); P02–P04 | Verified |
| FR-03 | Empty name rejected | LLD §3.3 | `src/validation.jl::validate_name` | `validation_tests.jl: name (FR-03)`; `app_tests.jl: execute` | Verified |
| FR-04 | Repetition 1–1000, leading zeros | LLD §3.3, §3.4 | `src/validation.jl::parse_count`, `is_count`; `src/greeting.jl::greetings` | `validation_tests.jl: count boundaries`; `greeting_tests.jl`; P05, P06 | Verified |
| FR-05 | Invalid count rejected | LLD §3.3 | `src/validation.jl::is_count` | `validation_tests.jl: count boundaries`, `count syntax`; `app_tests.jl: execute` | Verified |
| FR-06 | Last occurrence wins | LLD §3.2, §3.3 | `src/options.jl::parse_args` (`values` dictionary) | `options_tests.jl: last occurrence wins`; `validation_tests.jl: validate order` | Verified |
| FR-07 | Help text, scan order | HLD §4 D4; LLD §3.1, §3.5 | `src/messages.jl::HELP_TEXT`; `src/options.jl::parse_long!`; `src/app.jl::execute` | `options_tests.jl: --help and --version in scan order`; `app_tests.jl: execute`, `help text matches the user manual`; P07 | Verified |
| FR-08 | Version line | LLD §3.5 | `src/messages.jl::VERSION_TEXT`; `src/app.jl::execute` | `app_tests.jl: execute`; P08 | Verified |
| FR-09 | Operands rejected | LLD §3.3 | `src/options.jl::parse_args`; `src/validation.jl::validate` | `options_tests.jl: operands and terminator`; `app_tests.jl: execute`; P10 | Verified |
| FR-10 | Unknown/malformed options | LLD §3.2, §2.4 | `src/options.jl::parse_long!`, `parse_short!` | `options_tests.jl: syntax errors (CONV-13)`; `launcher_tests.jl`; P09 | Verified |
| FR-11 | No stdout on error | HLD §4 D1, D2 | `src/app.jl::execute`, `emit` | `app_tests.jl: execute`, `emit (binary output)`; P09, P10 | Verified |
| NFR-01 | Byte-identical, LF only | HLD §5; LLD §5 | `src/app.jl::emit` | `emit (binary output)`; `greeting_tests.jl` (no CR); P01–P10 on 3 OSes in CI | Verified |
| NFR-02 | < 300 ms (interpreted); < 32 MiB above baseline | HLD §4 D5, §7, §8 | `bin/dp-hello` (`--compile=min -O0`) | Measurement, MTP §4.4 | Verified (time); memory see §5 |
| NFR-03 | No crash or stack trace | HLD §6; LLD §3.6 | `src/app.jl::execute`, `emit`, `main` | `emit (binary output)` (closed stream); `validation_tests.jl` (huge count); `options_tests.jl` (invalid characters) | Verified |
| NFR-04 | Separate units | HLD §3.2 | `src/options.jl`, `validation.jl`, `greeting.jl`, `app.jl` | Design review (LLD §8) | Verified |
| NFR-05 | Pure, unit-tested greeting | LLD §3.4 | `src/greeting.jl::greeting`, `greetings` | `greeting_tests.jl: greeting (NFR-05)` | Verified |
| NFR-06 | Every Makefile target works | HLD §2 | `Makefile` (DP_* hooks) | CI: `make check roundtrip` (container, Linux, macOS, Windows) | Verified |
| NFR-07 | No files, environment, subprocesses | HLD §1.1, §7 | all of `src/` (Base string functions only) | Inspection | Verified |
| CONV-01 | Canonical name | LLD §2.4 | `src/messages.jl::TOOL` | P07–P10 | Verified |
| CONV-02 | Version format | LLD §3.5 | `src/messages.jl::VERSION_TEXT` | P08 | Verified |
| CONV-03 | LF only, binary mode | HLD §5 | `src/app.jl::emit` | `emit (binary output)`; P01–P10 | Verified |
| CONV-05 | UTF-8 arguments (Windows: UTF-16 → UTF-8) | HLD §5; LLD §5 | `src/app.jl::main` (`ARGS`) | `launcher_tests.jl` (Zoë, run on 3 OSes); `greeting_tests.jl` | Verified |
| CONV-06 | Locale-independent | HLD §5 | all of `src/` (no locale use) | Inspection; CI black-box runs with a minimal environment | Verified |
| CONV-07 | Short options, attached values | LLD §3.2 | `src/options.jl::parse_short!` | `options_tests.jl: value syntax`; P03, P06 | Verified |
| CONV-08 | Long options, no abbreviation | LLD §3.2 | `src/options.jl::parse_long!` | `options_tests.jl: value syntax`, `syntax errors`; P02, P04 | Verified |
| CONV-09 | `--` terminator | LLD §3.1 | `src/options.jl::parse_args` | `options_tests.jl: operands and terminator`; `app_tests.jl: execute` | Verified |
| CONV-10 | Operands, `-` | LLD §3.1 | `src/options.jl::parse_args` | `options_tests.jl: operands and terminator`; P10 | Verified |
| CONV-11 | Repetition | LLD §3.1 | `src/options.jl::parse_args` | `options_tests.jl: last occurrence wins` | Verified |
| CONV-12 | Scan order (v1.4.0) | HLD §4 D4 | `src/options.jl::parse_args`; `src/validation.jl::validate` | `options_tests.jl: --help and --version in scan order`; `app_tests.jl: execute` | Verified |
| CONV-13 | Exact usage messages | LLD §2.4 | `src/options.jl`, `src/validation.jl`, `src/messages.jl::invalid_argument` | `options_tests.jl: syntax errors`; `validation_tests.jl`; P09, P10 | Verified |
| CONV-14 | Try line, exit 2 | HLD §6 | `src/messages.jl::usage_text`; `src/app.jl::execute` | `app_tests.jl: execute`; P09, P10 | Verified |
| CONV-15 | Values verbatim, `''` | LLD §3.3 | `src/messages.jl::invalid_argument` | `validation_tests.jl: name (FR-03)`, `count syntax` | Verified |
| CONV-18 | Exit statuses | SRS §3.7; HLD §6 | `src/app.jl::execute`, `main` | `app_tests.jl`; P01–P10 | Verified |
| CONV-22, CONV-23 | `--help`/`--version`, verbatim help | LLD §3.5 | `src/messages.jl::HELP_TEXT`; `src/options.jl::parse_long!` | `app_tests.jl: help text matches the user manual`; P07, P08 | Verified |
| CONV-24 | No crash/stack trace | HLD §6 | `src/app.jl::main` | as NFR-03 | Verified |
| CONV-25 | EPIPE ends silently | HLD §6 | `src/app.jl::emit` | `emit (binary output)` (closed stream) | Verified |
| CONV-26 | stdin not read | HLD §3.1 | (no stdin access anywhere) | Inspection; P01–P10 run with null stdin | Verified |
| CONV-27 … CONV-30 | Harness conditions | HLD §4 D5 | `bin/dp-hello` (no depot or environment needed) | P01–P10 via `run-tests.py` | Verified |
| CONV-31 | Memory above runtime baseline | HLD §8 | `bin/dp-hello` | Measurement, MTP §4.4 | See §5 |
| CONV-04, CONV-16, CONV-17, CONV-19 … CONV-21 | Input copying, file errors, paths | — | Not applicable: the tool reads no input and touches no files | — | N/A |

## 3. Backward traceability (test → requirement)

| Test | Type | Requirement(s) verified |
| :-- | :-- | :-- |
| P01 | black-box, public | FR-01, NFR-01, CONV-03 |
| P02, P03, P04 | black-box, public | FR-02, CONV-07, CONV-08 |
| P05, P06 | black-box, public | FR-04, CONV-07 |
| P07 | black-box, public | FR-07, CONV-23 |
| P08 | black-box, public | FR-08, CONV-02 |
| P09 | black-box, public | FR-10, FR-11, CONV-13, CONV-14 |
| P10 | black-box, public | FR-09, FR-11, CONV-10, CONV-13 |
| `options_tests.jl: value syntax` | unit | FR-02, FR-04, CONV-07, CONV-08 |
| `options_tests.jl: values that start with '-'` | unit | FR-02 |
| `options_tests.jl: spelling is recorded for diagnostics` | unit | CONV-13 |
| `options_tests.jl: last occurrence wins` | unit | FR-06, CONV-11 |
| `options_tests.jl: operands and terminator` | unit | FR-09, CONV-09, CONV-10 |
| `options_tests.jl: --help and --version in scan order` | unit | FR-07, FR-08, CONV-12 |
| `options_tests.jl: syntax errors (CONV-13)` | unit | FR-10, CONV-08, CONV-13 |
| `validation_tests.jl: count boundaries`, `count syntax` | unit | FR-04, FR-05, CONV-15 |
| `validation_tests.jl: name (FR-03)` | unit | FR-03, CONV-15 |
| `validation_tests.jl: validate order` | unit | FR-06, FR-09, CONV-12 |
| `greeting_tests.jl: greeting (NFR-05)` | unit | FR-01, FR-02, FR-04, NFR-05, CONV-05 |
| `app_tests.jl: execute (end to end, pure)` | unit (integration) | FR-01 … FR-11, CONV-12, CONV-14 |
| `app_tests.jl: emit (binary output)` | unit | NFR-01, NFR-03, CONV-03, CONV-25 |
| `launcher_tests.jl: launcher` | unit (process) | CONV-05, FR-02, FR-10 |

## 4. Coverage summary

| Category | Total | Designed | Implemented | Verified |
| :-- | :-- | :-- | :-- | :-- |
| User requirements (UR) | 12 | 12 | 12 | 12 |
| Functional (FR) | 11 | 11 | 11 | 11 |
| Non-functional (NFR) | 7 | 7 | 7 | 7 (NFR-02 memory: see §5) |
| Conventions (CONV, applicable) | 25 | 25 | 25 | 24 (CONV-31: see §5) |

## 5. Gaps and justifications
- **NFR-02 / CONV-31 memory.** Measured in the container (Julia 1.13.1, MTP §4.4): the
  empty-program baseline peaks at 159.7 MiB RSS; `dp-hello -n Zoë -c 1000` peaks at 203 MiB,
  that is about 43 MiB above the baseline. Of that, about 30 MiB are file-backed pages of the
  runtime's own code (sysimage and `libjulia`) that parsing and lowering the sources touch, and
  about 10 MiB is private (anonymous) memory. Private memory is within 32 MiB; total RSS is not.
  A precompiled package image (`using DpHello`) measured +33 MiB and needs a depot the
  black-box runner does not provide (CONV-29). Plan: raise with the curriculum whether the
  baseline for Julia should be a program that parses one expression (+4 MiB measured), or
  revisit with a future Julia that trims the parser's footprint.
- Wall time (NFR-02) is verified by local measurement only; CI does not time runs.
