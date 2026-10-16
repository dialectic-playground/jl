# Toolchain image for dialectic-playground/jl: Julia (container-first; see tools/dp-run).
#
# Julia 1.13; build and package tool: Pkg.
# Official base image pinned by multi-architecture index digest, plus make and python3 (for the
# curriculum's black-box runner). Dependabot (docker) refreshes the digest; moving to a new
# release line is a deliberate change (keep `make toolchain` and the native CI in step).
FROM docker.io/library/julia:1.13-trixie@sha256:0002771531bbae894f2532a5ae02ea71c30685440ca3bdaea0a43d17e65571e0

# Debian keeps only the current version of each package, so apt versions cannot be pinned
# reproducibly; the base image is pinned by digest instead.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends make python3 \
    && rm -rf /var/lib/apt/lists/*

# The trailing colon keeps the bundled standard-library depot.
ENV JULIA_DEPOT_PATH=/dp-cache/julia: \
    DP_IN_CONTAINER=1
