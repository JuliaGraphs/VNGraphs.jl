# VNGraphs.jl

A thin wrapper around the C graphs library [`very_nauty`](https://github.com/JuliaGraphs/very_nauty/), providing high-performance graph algorithms for the `Graphs.jl` ecosystem.

## Features

- **High Performance**: Direct C-bindings for core graph operations.
- **Graphs.jl Integration**: Fully implements the `AbstractGraph` interface.
- **Specialized Dispatch**: Use `VNAlgorithm()` to dispatch existing `Graphs.jl` functions to the `very_nauty` implementation.

## Usage

```julia
using Graphs, VNGraphs

# Create a VNGraph
g = VNGraph(5)
add_edge!(g, 1, 2)

# Use standard Graphs.jl algorithms
c = chromatic_number(g) 

# Dispatch explicitly using VNAlgorithm
c = chromatic_number(g, VNAlgorithm())
```

## Installation

```julia
import Pkg; Pkg.add("VNGraphs")
```
