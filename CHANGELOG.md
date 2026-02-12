# Changelog

## Unreleased

- Complete `Graphs.jl` `AbstractGraph` interface for `VNGraph`: `edges`, `outneighbors`/`inneighbors`, `rem_edge!`, `add_vertex!`, `copy`.
- Fix 0-indexing bug in `has_edge` (was passing 1-based indices to 0-based C API).
- Add `GraphsInterfaceChecker.jl` compliance tests.
