# 00-hello-world: Standard Terminal Hello World
#
# Project Makefile template. It extends the universal build contract in
# shared/templates/BASE-MAKEFILE, which defines the standard targets:
#
#   make all | install | uninstall | test | check | lint | format | clean | distclean
#   make test-hidden | grade | help
#
# A language implementation repository copies this file next to its sources, sets BIN_DIR,
# fills in each DP_* hook with its toolchain's commands, and points CURRICULUM_ROOT at its
# checkout of sdlc-curriculum (for example a git submodule). Hooks that are left empty make
# their target fail with an explanation. `make help` shows which hooks are defined.
#
# Container-first: goals run in the toolchain container built from the repository's
# Containerfile (podman, then docker, then local; override with DP_RUNTIME). The image needs
# the language toolchain, make, and python3 >= 3.11. Use DP_RUNTIME=local for native builds.

PROJECT := 00-hello-world
TOOLS   := dp-hello

# Path to the sdlc-curriculum checkout (the specs, test suites, and runner live there).
CURRICULUM_ROOT ?= ../sdlc-curriculum

# Julia (dialectic-playground/jl). Package DpHello: Project.toml, src/, test/ (unit tests),
# dev/ (JuliaFormatter and Aqua); one workspace Manifest.toml locks all three environments.
# The tool itself needs only Base: the launcher bin/dp-hello includes src/DpHello.jl.
JULIA ?= julia
JL := $(JULIA) --startup-file=no
INSTANTIATE := $(JL) --project=. -e 'using Pkg; Pkg.instantiate(workspace=true)'
LAUNCHER_SHEBANG := \#!/usr/bin/env -S julia --startup-file=no --compile=min -O0
INSTALL_DIR = $(LIBDIR)/jl/$(PROJECT)

# Directory that contains the built executables after `make all`: the #! launcher dp-hello.
BIN_DIR := bin

define DP_BUILD
	chmod +x bin/dp-hello
	$(INSTANTIATE)
	$(JL) --project=. -e 'using Pkg; Pkg.precompile()'
endef

define DP_INSTALL
	mkdir -p "$(INSTALL_DIR)/src" "$(BINDIR)"
	cp src/*.jl "$(INSTALL_DIR)/src/"
	printf '%s\n# dp-hello launcher written by make install (dialectic-playground/jl).\ninclude(raw"%s")\nexit(DpHello.main(ARGS))\n' \
		'$(LAUNCHER_SHEBANG)' "$(INSTALL_DIR)/src/DpHello.jl" > "$(BINDIR)/dp-hello"
	chmod +x "$(BINDIR)/dp-hello"
endef

define DP_UNINSTALL
	rm -f "$(BINDIR)/dp-hello"
	rm -rf "$(INSTALL_DIR)"
	rmdir "$(LIBDIR)/jl" 2>/dev/null || true
endef

define DP_UNIT_TEST
	$(INSTANTIATE)
	$(JL) --project=test test/runtests.jl
endef

define DP_LINT
	$(INSTANTIATE)
	$(JL) --project=dev dev/style.jl lint
endef

define DP_FORMAT
	$(INSTANTIATE)
	$(JL) --project=dev dev/style.jl format
endef

# Julia keeps compiled caches in the depot (JULIA_DEPOT_PATH), not in the project: remove
# DpHello's precompiled images there. Nothing else is generated inside this directory.
define DP_CLEAN
	$(JL) -e 'foreach(d -> rm(joinpath(d, "compiled", "v$$(VERSION.major).$$(VERSION.minor)", "DpHello"); force = true, recursive = true), DEPOT_PATH)'
endef

# Registries and packages live in the depot (JULIA_DEPOT_PATH), outside the project. A
# depot can appear here only when Julia runs without HOME/JULIA_DEPOT_PATH while the project
# is the home directory (podman --userns=keep-id); remove it.
define DP_DISTCLEAN
	rm -rf .julia
endef

include $(CURRICULUM_ROOT)/shared/templates/BASE-MAKEFILE
