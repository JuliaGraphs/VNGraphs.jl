module VNGraphs

export VNGraph

import Graphs
import Graphs: clique_number, chromatic_number, edge_chromatic_number

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
nnodes(g::VNGraph) = Int(unsafe_load(reinterpret(Ptr{Cuint}, Base.unsafe_convert(Ptr{Cvoid}, g.ptr)), 13)) # Offset 48
nedges(g::VNGraph) = Int(unsafe_load(reinterpret(Ptr{Cuint}, Base.unsafe_convert(Ptr{Cvoid}, g.ptr)), 14)) # Offset 52

# Robust field accessors for pointers (8-byte aligned)
function get_d_ptr(g::VNGraph)
    return unsafe_load(reinterpret(Ptr{Ptr{Cuint}}, Base.unsafe_convert(Ptr{Cvoid}, g.ptr)), 2) # Offset 8
end

function get_a_ptr(g::VNGraph)
    return unsafe_load(reinterpret(Ptr{Ptr{Ptr{Cuint}}}, Base.unsafe_convert(Ptr{Cvoid}, g.ptr)), 1) # Offset 0
end

function get_c_ptr(g::VNGraph)
    return unsafe_load(reinterpret(Ptr{Ptr{Cint}}, Base.unsafe_convert(Ptr{Cvoid}, g.ptr)), 5) # Offset 32
end

function get_l_ptr(g::VNGraph)
    return unsafe_load(reinterpret(Ptr{Ptr{Cint}}, Base.unsafe_convert(Ptr{Cvoid}, g.ptr)), 6) # Offset 40
end

graph_node_degree(g::VNGraph, i::Integer) = c"graph_node_degree"(g.ptr, i)
graph_min_degree(g::VNGraph) = c"graph_min_degree"(g.ptr)
graph_max_degree(g::VNGraph) = c"graph_max_degree"(g.ptr)
graph_mean_degree(g::VNGraph) = c"graph_mean_degree"(g.ptr)

graph_show(g::VNGraph) = c"graph_show"(g.ptr)

graph_nclusters(g::VNGraph) = Int(c"graph_nclusters"(g.ptr))
graph_connected(g::VNGraph) = c"graph_connected"(g.ptr) != 0

cluster(g::VNGraph,i::Integer) = unsafe_load(get_l_ptr(g), i+1)
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
color(g::VNGraph,i) = unsafe_load(get_c_ptr(g), i+1)
graph_ncolors(g::VNGraph) = c"graph_ncolors"(g.ptr)
graph_check_coloring(g::VNGraph) = c"graph_check_coloring"(g.ptr)


function Graphs.SimpleGraphs.SimpleGraph(vng::VNGraph)
    n = nnodes(vng)
    # Build fadjlist directly for speed
    d_ptr = get_d_ptr(vng)
    a_ptr = get_a_ptr(vng)
    fadjlist = [Vector{Int}(undef, unsafe_load(d_ptr, i)) for i in 1:n]
    for i in 1:n
        d = unsafe_load(d_ptr, i)
        a_i_ptr = unsafe_load(a_ptr, i)
        for k in 1:d
            fadjlist[i][k] = unsafe_load(a_i_ptr, k) + 1
        end
        sort!(fadjlist[i])
    end
    return Graphs.SimpleGraphs.SimpleGraph{Int}(Int(nedges(vng)), fadjlist)
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

struct VNEdgeIterator
    g::VNGraph
end
Base.eltype(::Type{VNEdgeIterator}) = Graphs.SimpleGraphs.SimpleEdge{Cuint}
Base.length(it::VNEdgeIterator) = Int(nedges(it.g))

function Base.iterate(it::VNEdgeIterator, state=(1, 1))
    g = it.g
    i, k = state
    n = nnodes(g)
    
    d_ptr = get_d_ptr(g)
    a_ptr = get_a_ptr(g)
    while i <= n
        d = unsafe_load(d_ptr, i)
        while k <= d
            a_i_ptr = unsafe_load(a_ptr, i)
            j = unsafe_load(a_i_ptr, k) + 1
            if i < j
                return (Graphs.SimpleGraphs.SimpleEdge{Cuint}(i, j), (i, k + 1))
            end
            k += 1
        end
        i += 1
        k = 1
    end
    return nothing
end

Graphs.edges(g::VNGraph) = VNEdgeIterator(g)
Graphs.edgetype(g::VNGraph) = Graphs.SimpleGraphs.SimpleEdge{eltype(g)}

function Graphs.has_edge(g::VNGraph, s::Integer, d::Integer)
    (s < 1 || s > nnodes(g) || d < 1 || d > nnodes(g)) && return false
    return graph_has_edge(g, s-1, d-1) != 0
end

Graphs.has_vertex(g::VNGraph, n::Integer) = 1≤n≤nnodes(g)

function Graphs.outneighbors(g::VNGraph, v::Integer)
    (v < 1 || v > nnodes(g)) && return Cuint[]
    d = unsafe_load(get_d_ptr(g), v)
    a_v_ptr = unsafe_load(get_a_ptr(g), v)
    return [unsafe_load(a_v_ptr, k) + 1 for k in 1:d]
end

Graphs.inneighbors(g::VNGraph, v::Integer) = Graphs.outneighbors(g, v)
Graphs.neighbors(g::VNGraph, v::Integer) = Graphs.outneighbors(g, v)

Graphs.is_directed(::Type{VNGraph}) = false
Graphs.ne(g::VNGraph) = nedges(g)
Graphs.nv(g::VNGraph) = nnodes(g)
Graphs.vertices(g::VNGraph) = UnitRange{Cuint}(1, nnodes(g))

function Graphs.add_edge!(g::VNGraph, s::Integer, d::Integer)
    (s < 1 || s > nnodes(g) || d < 1 || d > nnodes(g)) && return false
    graph_has_edge(g, s-1, d-1) != 0 && return false
    graph_add_edge(g, s-1, d-1)
    return true
end

Graphs.add_edge!(g::VNGraph, e::Graphs.SimpleGraphEdge) = Graphs.add_edge!(g, e.src, e.dst)

function Graphs.add_vertex!(g::VNGraph)
    graph_add_node(g)
    return true
end

function Graphs.rem_edge!(g::VNGraph, s::Integer, d::Integer)
    (s < 1 || s > nnodes(g) || d < 1 || d > nnodes(g)) && return false
    graph_has_edge(g, s-1, d-1) == 0 && return false
    graph_del_edge(g, s-1, d-1)
    return true
end

function Graphs.degree(g::VNGraph, v::Integer)
    (v < 1 || v > nnodes(g)) && return 0
    return Int(c"graph_node_degree"(g.ptr, v-1))
end

# Algorithm dispatch
struct VNAlgorithm end
export VNAlgorithm

clique_number(g::VNGraph) = graph_clique_number(g)
clique_number(g::VNGraph, ::VNAlgorithm) = clique_number(g)
clique_number(g::Graphs.AbstractGraph, ::VNAlgorithm) = graph_clique_number(VNGraph(g))

function chromatic_number(g::VNGraph; timeout=0)
    return graph_chromatic_number(g, timeout)
end
chromatic_number(g::VNGraph, ::VNAlgorithm; timeout=0) = chromatic_number(g; timeout=timeout)
chromatic_number(g::Graphs.AbstractGraph, ::VNAlgorithm; timeout=0) = chromatic_number(VNGraph(g); timeout=timeout)

function edge_chromatic_number(g::VNGraph; timeout=0)
    return graph_edge_chromatic_number(g, timeout)
end
edge_chromatic_number(g::VNGraph, ::VNAlgorithm; timeout=0) = edge_chromatic_number(g; timeout=timeout)
edge_chromatic_number(g::Graphs.AbstractGraph, ::VNAlgorithm; timeout=0) = edge_chromatic_number(VNGraph(g); timeout=timeout)

function Graphs.connected_components(g::VNGraph)
    n = nnodes(g)
    n_clusters = graph_nclusters(g)
    comps = [Int[] for _ in 1:n_clusters]
    for i in 1:n
        c = cluster(g, i-1)
        push!(comps[c+1], i)
    end
    return comps
end
Graphs.connected_components(g::Graphs.AbstractGraph, ::VNAlgorithm) = Graphs.connected_components(VNGraph(g))

# Export VNAlgorithm for user convenience
export VNAlgorithm

end
