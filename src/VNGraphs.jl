module VNGraphs

export VNGraph

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
# Graphs.edges # TODO
Graphs.edgetype(g::VNGraph) = Graphs.SimpleGraphs.SimpleEdge{eltype(g)}
Graphs.has_edge(g::VNGraph,s,d) = graph_has_edge(g,s,d)
Graphs.has_vertex(g::VNGraph,n::Integer) = 1≤n≤nnodes(g)
# Graphs.inneighbors # TODO
Graphs.is_directed(::Type{VNGraph}) = false
Graphs.ne(g::VNGraph) = nedges(g)
Graphs.nv(g::VNGraph) = nnodes(g)
# Graphs.outneighbors # TODO
Graphs.vertices(g::VNGraph) = 1:nnodes(g)

Graphs.add_edge!(g::VNGraph, e::Graphs.SimpleGraphEdge) = graph_add_edge(g,e.src-1,e.dst-1)

end
