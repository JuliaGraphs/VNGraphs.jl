module VNGraphs

export VNGraph, VNAlgorithm, chromatic_number, edge_chromatic_number, clique_number

import Graphs

import very_nauty_jll
using CBinding: @c_cmd, @c_str
let
    incdir = joinpath(very_nauty_jll.artifact_dir, "include")
    libdir = dirname(very_nauty_jll.libvn_graph_path)

    SYSROOT = Sys.isapple() ? ["-isysroot", joinpath(strip(String(read(`xcrun xcode-select --print-path`))), "Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk")] : []

    c`$([SYSROOT..., "-I$(incdir)", "-L$(libdir)", "-lvn_graph"])`
end

# TODO document why these consts have to be included manually
const c"size_t" = Csize_t
const c"clock_t" = Cuint # TODO this is not safe, but it is too much of a hassle to get the correct clock_t on windows as a bunch of internal types start getting parsed
const c"FILE" = Cvoid # fine as long as we do not use it

c"""
#include "vn_graph.h"
"""

"""Thin wrapper around the graph structure provided by the `very_nauty` C graph library."""
mutable struct VNGraph <: Graphs.SimpleGraphs.AbstractSimpleGraph{Cuint}
    ptr::c"graph_t"
    function VNGraph(ptr::c"graph_t")
        x = new(ptr)
        finalizer(x) do x
            c"graph_clear"(x.ptr)
            x
        end
    end
end

VNGraph(n::Integer) = VNGraph(c"graph_new"(n))

graph_add_edge(g::VNGraph,i::Integer,j::Integer) = c"graph_add_edge"(g.ptr,i,j)
graph_del_edge(g::VNGraph,i::Integer,j::Integer) = c"graph_del_edge"(g.ptr,i,j)
graph_has_edge(g::VNGraph,i::Integer,j::Integer) = c"graph_has_edge"(g.ptr,i,j)
graph_add_node(g::VNGraph) = c"graph_add_node"(g.ptr)
nnodes(g::VNGraph) = g.ptr.nnodes[] # c"nnodes"(g.ptr)
nedges(g::VNGraph) = g.ptr.nedges[] # c"nedges"(g.ptr)

graph_node_degree(g::VNGraph, i::Integer) = c"graph_node_degree"(g.ptr, i)
graph_min_degree(g::VNGraph) = c"graph_min_degree"(g.ptr)
graph_max_degree(g::VNGraph) = c"graph_max_degree"(g.ptr)
graph_mean_degree(g::VNGraph) = c"graph_mean_degree"(g.ptr)

graph_show(g::VNGraph) = c"graph_show"(g.ptr)

graph_nclusters(g::VNGraph) = c"graph_nclusters"(g.ptr)
graph_connected(g::VNGraph) = c"graph_connected"(g.ptr)

cluster(g::VNGraph,i::Integer) = g.ptr.l[][i]
graph_cluster_sizes(g::VNGraph) = c"graph_cluster_sizes"(g.ptr)
graph_max_cluster(g::VNGraph) = c"graph_max_cluster"(g.ptr)

graph_gnp(g::VNGraph, p) = c"graph_gnp"(g.ptr, p)
graph_gnm(g::VNGraph, m) = c"graph_gnm"(g.ptr, m)
graph_grg(g::VNGraph, r) = c"graph_grg"(g.ptr, r)
graph_grg_torus(g::VNGraph, r) = c"graph_grg_torus"(g.ptr, r)
graph_lognormal_grg_torus(g::VNGraph, r, alpha) = c"graph_lognormal_grg_torus"(g.ptr, r, alpha)

# TODO random iterators

graph_clique_number(g::VNGraph) = c"graph_clique_number"(g.ptr)

graph_local_complement(g::VNGraph, i::Integer) = c"graph_local_complement"(g.ptr,i)

# TODO greedy and sequential color
#graph_greedy_color(graph_t g, int perm[])
#graph_sequential_color(graph_t g,int perm[], int ub)
graph_sequential_color_repeat(g::VNGraph, n::Integer) = c"graph_sequential_color_repeat"(g.ptr, n)
graph_chromatic_number(g::VNGraph, timeout) = c"graph_chromatic_number"(g.ptr, timeout)
graph_edge_chromatic_number(g::VNGraph, timeout) = c"graph_edge_chromatic_number"(g.ptr, timeout)
color(g::VNGraph,i) = g.ptr.c[][i]
graph_ncolors(g::VNGraph) = c"graph_ncolors"(g.ptr)
graph_check_coloring(g::VNGraph) = c"graph_check_coloring"(g.ptr)


function Graphs.SimpleGraphs.SimpleGraph(vng::VNGraph)
    n = nnodes(vng)
    g = Graphs.SimpleGraphs.SimpleGraph{Int}(n)
    for i in 1:nnodes(vng)
        for k in 1:vng.ptr.d[][i]
            j = vng.ptr.a[][i][k]+1
            i<j && Graphs.add_edge!(g,i,j)
        end
    end
    return g
end

function VNGraph(g::Graphs.AbstractSimpleGraph)
    n = Graphs.nv(g)
    vng = VNGraph(n)
    for (;src,dst) in Graphs.edges(g)
        graph_add_edge(vng, src-1, dst-1)
    end
    return vng
end

Base.eltype(::VNGraph) = Cuint
Base.zero(::Type{VNGraph}) = VNGraph(0)
Graphs.edgetype(::VNGraph) = Graphs.SimpleGraphs.SimpleEdge{Cuint}
Graphs.is_directed(::Type{VNGraph}) = false
Graphs.ne(g::VNGraph) = nedges(g)
Graphs.nv(g::VNGraph) = nnodes(g)
Graphs.vertices(g::VNGraph)::UnitRange{Cuint} = Cuint(1):Cuint(nnodes(g))

# Fix: convert 1-based Julia indices to 0-based C indices
Graphs.has_edge(g::VNGraph, s, d)::Bool = graph_has_edge(g, s-1, d-1)
Graphs.has_vertex(g::VNGraph, n::Integer) = 1 ≤ n ≤ nnodes(g)

function Graphs.outneighbors(g::VNGraph, v::Integer)
    (1 ≤ v ≤ nnodes(g)) || return Cuint[]
    deg = g.ptr.d[][v]
    neighbors = Vector{Cuint}(undef, deg)
    adj = g.ptr.a[][v]
    for k in 1:deg
        neighbors[k] = adj[k][] + Cuint(1)  # 0-based C → 1-based Julia
    end
    sort!(neighbors)
    return neighbors
end

Graphs.inneighbors(g::VNGraph, v::Integer) = Graphs.outneighbors(g, v)

"""Iterator over edges of a VNGraph, yielding SimpleEdge{Cuint}."""
struct VNGraphEdgeIterator
    graph::VNGraph
end

Base.length(it::VNGraphEdgeIterator) = nedges(it.graph)
Base.eltype(::Type{VNGraphEdgeIterator}) = Graphs.SimpleGraphs.SimpleEdge{Cuint}

function Base.iterate(it::VNGraphEdgeIterator, state=(Cuint(1), 1))
    g = it.graph
    n = nnodes(g)
    v, kidx = state
    while v ≤ n
        deg = g.ptr.d[][v]
        adj = g.ptr.a[][v]
        while kidx ≤ deg
            w = adj[kidx][] + Cuint(1)
            kidx += 1
            if v < w  # undirected: emit each edge once (lower index first)
                return (Graphs.SimpleGraphs.SimpleEdge{Cuint}(v, w), (v, kidx))
            end
        end
        v += Cuint(1)
        kidx = 1
    end
    return nothing
end

Graphs.edges(g::VNGraph) = VNGraphEdgeIterator(g)

function Graphs.add_edge!(g::VNGraph, e::Graphs.SimpleGraphEdge)
    s, d = e.src - 1, e.dst - 1
    graph_add_edge(g, s, d)
    return Graphs.has_edge(g, e.src, e.dst)
end

function Graphs.rem_edge!(g::VNGraph, e::Graphs.SimpleGraphEdge)
    s, d = e.src - 1, e.dst - 1
    result = graph_del_edge(g, s, d)
    return result != 0
end

function Graphs.add_vertex!(g::VNGraph)
    graph_add_node(g)
    return true
end

function Base.copy(g::VNGraph)
    n = nnodes(g)
    g2 = VNGraph(n)
    for i in Cuint(1):Cuint(n)
        deg = g.ptr.d[][i]
        adj = g.ptr.a[][i]
        for k in 1:deg
            j = adj[k][] + Cuint(1)
            if i < j
                graph_add_edge(g2, i - 1, j - 1)
            end
        end
    end
    return g2
end

# --- VNAlgorithm dispatch ---

"""
    VNAlgorithm

Algorithm dispatch type for very_nauty C library implementations.
Pass `VNAlgorithm()` as a second argument to dispatch graph algorithms
to the very_nauty C implementation. Non-VNGraph inputs are automatically
converted.

# Example
```julia
g = path_graph(5)
is_connected(g, VNAlgorithm())      # uses very_nauty C implementation
chromatic_number(g, VNAlgorithm())   # exact chromatic number via very_nauty
```
"""
struct VNAlgorithm end

# Helper: convert to VNGraph if needed
_to_vngraph(g::VNGraph) = g
_to_vngraph(g::Graphs.AbstractSimpleGraph) = VNGraph(g)

"""
    Graphs.is_connected(g::AbstractGraph, ::VNAlgorithm)

Test whether `g` is connected using the very_nauty C library.
"""
function Graphs.is_connected(g::Graphs.AbstractGraph, ::VNAlgorithm)
    vng = _to_vngraph(g)
    return graph_connected(vng) != 0
end

"""
    Graphs.connected_components(g::AbstractGraph, ::VNAlgorithm)

Return the connected components of `g` using the very_nauty C library.
Returns a vector of vectors, where each inner vector contains the 1-based
vertex indices of one component.
"""
function Graphs.connected_components(g::Graphs.AbstractGraph, ::VNAlgorithm)
    vng = _to_vngraph(g)
    nc = graph_nclusters(vng)
    n = nnodes(vng)
    components = [Int[] for _ in 1:nc]
    for i in Cuint(1):Cuint(n)
        label = cluster(vng, i) + 1  # 0-based C label → 1-based
        push!(components[label], Int(i))
    end
    return components
end

"""
    chromatic_number(g::AbstractGraph, ::VNAlgorithm; timeout=0)

Compute the exact chromatic number of `g` using the very_nauty C library.
`timeout` specifies CPU clock ticks before giving up (0 = no timeout).
"""
function chromatic_number(g::Graphs.AbstractGraph, ::VNAlgorithm; timeout=0)
    vng = _to_vngraph(g)
    return Int(graph_chromatic_number(vng, timeout))
end

"""
    edge_chromatic_number(g::AbstractGraph, ::VNAlgorithm; timeout=0)

Compute the exact edge chromatic number (chromatic index) of `g`
using the very_nauty C library.
`timeout` specifies CPU clock ticks before giving up (0 = no timeout).
"""
function edge_chromatic_number(g::Graphs.AbstractGraph, ::VNAlgorithm; timeout=0)
    vng = _to_vngraph(g)
    return Int(graph_edge_chromatic_number(vng, timeout))
end

"""
    clique_number(g::AbstractGraph, ::VNAlgorithm)

Compute the exact clique number (size of the maximum clique) of `g`
using the very_nauty C library.
"""
function clique_number(g::Graphs.AbstractGraph, ::VNAlgorithm)
    vng = _to_vngraph(g)
    return Int(graph_clique_number(vng))
end

end
