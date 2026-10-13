# Master Test Plan (MTP) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Implementation language | Julia 1.13 (package `DpHello`) |
| Author | dialectic-playground/jl maintainers |
| Version / date | 1.0 — 2026-10-13 |
| Standard | Structure adapted from IEEE 829 / ISO/IEC/IEEE 29119-3 |

## 1. Introduction and scope

### 1.1 Objectives
"Tested enough" means: every SRS acceptance criterion (FR-01 … FR-11) is exercised by a unit
test of the pure core and by a black-box test where one exists; every CONV-13 message is
asserted byte-for-byte; the public and hidden suites pass on Linux, macOS, and Windows; and
the NFR-02 timing and memory are measured and recorded.

### 1.2 In scope / out of scope
| In scope | Out of scope |
| :-- | :-- |
| Every FR/NFR in the SRS and the applicable CONV rules, on Linux, macOS, and Windows | File, path, and stdin behavior (the tool has none); terminals' rendering of UTF-8 |
| Install/uninstall round trip | Performance on hardware other than CI and the development machine |

## 2. Test items

| Item | Version / location |
| :-- | :-- |
| dp-hello | `00-hello-world/src/`, `bin/dp-hello` on branch `feat/00-hello-world` |
| Unit tests | `00-hello-world/test/` (`Test` standard library) |
| Public black-box suite | `tests/public/` (10 tests) |
| Hidden black-box suite | `tests/private/` (10 tests, run by CI) |

## 3. Test levels and approach

| Level | Purpose | Technique(s) | Tooling | Owner |
| :-- | :-- | :-- | :-- | :-- |
| Unit | Parser, validation, greeting in isolation | Equivalence partitioning, boundary values | `Test` via `make test-unit` | Implementer |
| Integration | `execute` from arguments to `Outcome`; `emit` into `IOBuffer`s (binary capture) | Specification-based | `Test` | Implementer |
| Process | The launcher as a child process: real `ARGS` decoding and byte output on each OS | Specification-based | `Test` (`launcher_tests.jl`) | Implementer |
| System (black-box) | The specified CLI behavior, byte-exact | Specification-based | `make test` → `run-tests.py` | Implementer |
| Acceptance | Hidden suite passes on all OSes | — | CI `make test-hidden` | CI |
| Static analysis | Formatting, package hygiene | — | `make lint` (JuliaFormatter check, Aqua) | Implementer / CI |

## 4. Test design

### 4.1 Equivalence partitions and boundaries

| Input | Valid partitions | Invalid partitions | Boundaries |
| :-- | :-- | :-- | :-- |
| NAME | ASCII, spaces, punctuation, non-ASCII (`Zoë`), leading `-` | empty | `''` |
| COUNT | digits with value 1–1000, leading zeros | empty, non-digits, signs, spaces, non-ASCII digits, 0, > 1000 | `0`, `1`, `1000`, `1001`, `000`, `0001000`, 23-digit value |
| Option syntax | `-nX`, `-n X`, `--name=X`, `--name X`, repeats | unknown short/long, abbreviation, missing value, `=value` on flags | last token missing its value |
| Operands | none | any word, `-`, anything after `--` | first operand reported |
| Scan order | `--help`/`--version` before any syntax error | syntax error before them | `extra --help`, `--count 0 --help`, `-x --help` |

### 4.2 Additional test cases (beyond the supplied suite)

| ID | Requirement(s) | Preconditions | Steps / command | Expected result | Level |
| :-- | :-- | :-- | :-- | :-- | :-- |
| T-01 | FR-04 | — | `-c 1000`, `-c 0001000` | 1000 lines | unit |
| T-02 | FR-05 | — | `-c 1001`, `-c 0`, `-c 000`, 23-digit count | `invalid argument '…' for '-c'`, no overflow | unit |
| T-03 | FR-05 | — | `-c abc`, `-c -1`, `-c +1`, `-c ' 1'`, `-c 1.0`, `-c ١` | invalid argument | unit |
| T-04 | FR-03 | — | `--name ''`, `-n ''` | `invalid argument '' for '--name'` / `'-n'` | unit |
| T-05 | FR-06 | — | `-c 0 -c 2 -n '' -n B` | `Config("B", 2)` (only winners validated) | unit |
| T-06 | CONV-12 | — | `extra --help`, `--count 0 --help`, `-x --help` | help, help, invalid option | unit |
| T-07 | FR-09, CONV-09 | — | `-- -n`, `-- --` | `extra operand '-n'` / `'--'` | unit |
| T-08 | FR-10, CONV-08 | — | `--nam`, `--names=x`, `--=x`, `--help=`, `--version=1` | exact CONV-13 messages | unit |
| T-09 | FR-02 | — | `--name -x`, `-n-x`, `-n --help` | name `-x`, `-x`, `--help` | unit |
| T-10 | CONV-05, NFR-01 | — | launcher `-n Zoë -c 2` as a child process | `Hello, Zo\xc3\xab!\n` ×2, no CR | process |
| T-11 | CONV-25 | closed output stream | `emit` into a closed `IOBuffer` | status 1, nothing on stderr | unit |
| T-12 | CONV-13 | — | `-é` | `invalid option -- 'é'` | unit |
| T-13 | NFR-06 | temporary PREFIX | `make roundtrip` | install then uninstall leave nothing behind | CI |

### 4.3 Negative and robustness testing
Every CONV-13 diagnostic is asserted exactly (`options_tests.jl`, `validation_tests.jl`,
`app_tests.jl`). Robustness: invalid UTF-8 names pass through byte for byte
(`greeting_tests.jl`); a 23-digit COUNT cannot overflow (`validation_tests.jl`); a closed
stream is handled silently (`app_tests.jl`); `main` converts any unexpected exception into a
one-line diagnostic. Missing files, permissions, and large input do not apply (no input).

### 4.4 Performance and resource testing
Measured in the toolchain container (Julia 1.13.1, Linux x86-64, 8 CPUs), best of 10 runs,
peak RSS from `getrusage(RUSAGE_CHILDREN)` and `/proc/self/status`:

| Command | Wall time | Peak RSS | Above baseline |
| :-- | :-- | :-- | :-- |
| Baseline: `julia --startup-file=no --compile=min -O0 -e ''` | 131–156 ms | 159.7 MiB | — |
| `dp-hello -n Zoë -c 1000` (launcher flags `--compile=min -O0`) | 170–263 ms | 203 MiB | 43 MiB (anonymous +10 MiB, file-backed runtime pages +30 MiB) |
| `dp-hello -x` | 226 ms | 202.7 MiB | 43 MiB |
| Same without `--compile=min -O0` | 1014–1131 ms | 257.6 MiB | 98 MiB |
| Precompiled package image instead of `include` | 154 ms | 192.4 MiB | 33 MiB |

The time limit for interpreted runtimes (300 ms) is met. The 32 MiB memory limit (CONV-31)
is met for private memory but not for total RSS; see RTM §5.

## 5. Test environments

| Environment | OS / version | Toolchain | How provisioned |
| :-- | :-- | :-- | :-- |
| Local | Fedora 44 host, Debian trixie container | Julia 1.13.1, Python 3 | `make` (Podman, `Containerfile`) |
| CI | ubuntu-latest, macos-latest, windows-latest (Git Bash) | Julia 1.13 (julia-actions/setup-julia), Python 3.12 | `.github/workflows/ci.yml` |

## 6. Entry and exit criteria

- **Entry:** HLD and LLD written; `make all` succeeds; `make lint` is clean.
- **Exit:** all unit tests pass; all public and hidden black-box tests pass on all three OSes;
  `make roundtrip` passes natively; the RTM shows every applicable requirement as Verified or
  lists it under gaps.
- **Suspension / resumption:** suspend on a toolchain or CI infrastructure failure; resume
  after the cause is fixed and the full `make check` is rerun.

## 7. Defect management
Defects are GitHub issues in `dialectic-playground/jl` with the failing command, expected
and actual bytes, and OS. Every fix adds a unit test that fails before the fix, and the full
`make check` runs in CI before merging.

| Severity | Definition |
| :-- | :-- |
| 1 — Critical | Crash, stack trace, or wrong output on a mainline path |
| 2 — Major | Wrong diagnostic, exit status, or bytes on one OS |
| 3 — Minor | Documentation, style, or performance outside the NFR budget |

## 8. Schedule and deliverables

| Milestone | Deliverable | Target date |
| :-- | :-- | :-- |
| Design complete | `hld.md`, `lld.md` | 2026-10-13 |
| Implementation complete | `src/`, `test/`, `bin/dp-hello` | 2026-10-13 |
| Verification complete | RTM, CI green on all jobs | 2026-10-13 |

## 9. Risks and contingencies

| Risk | Mitigation |
| :-- | :-- |
| Windows-only failure discovered late | Native CI on all three OSes from the first push; the launcher test runs on each |
| Julia start-up near the 300 ms budget on slower runners | `--compile=min -O0`; keep Base-only code |
| Package downloads unavailable in CI | Pinned `Manifest.toml`; failures are infrastructure, rerun |

## 10. Test summary

| Metric | Value |
| :-- | :-- |
| Unit tests (pass / total) | 112 / 112 assertions in 6 top-level testsets |
| Coverage (line / branch) | Not measured; every function in `src/` is exercised by `app_tests.jl` and its own testset |
| Public black-box (pass / 10) | 10 / 10 (container) |
| Hidden black-box (pass / 10, from CI) | 10 / 10 (container) |
| Open defects by severity | None |
