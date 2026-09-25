module VNGraphs

export VNGraph

import Graphs

include("libvery_nauty.jl")

"""Thin wrapper around the graph structure provided by the `very_nauty` C graph library."""
mutable struct VNGraph <: Graphs.SimpleGraphs.AbstractSimpleGraph{Cuint}
    ptr::Lib.graph_t
    function VNGraph(ptr::Lib.graph_t)
        x = new(ptr)
        finalizer(x) do x
            Lib.graph_clear(x.ptr)
            x
        end
    end
end

# Keep the owning graph alive while a C function uses its pointer.
Base.cconvert(::Type{Lib.graph_t}, g::VNGraph) = g
Base.unsafe_convert(::Type{Lib.graph_t}, g::VNGraph) = g.ptr

VNGraph(n::Integer) = VNGraph(Lib.graph_new(n))

graph_add_edge(g::VNGraph,i::Integer,j::Integer) = Lib.graph_add_edge(g,i,j)
graph_del_edge(g::VNGraph,i::Integer,j::Integer) = Lib.graph_del_edge(g,i,j)
graph_has_edge(g::VNGraph,i::Integer,j::Integer) = Lib.graph_has_edge(g,i,j)
graph_add_node(g::VNGraph) = Lib.graph_add_node(g)
nnodes(g::VNGraph) = GC.@preserve g unsafe_load(g.ptr).nnodes
nedges(g::VNGraph) = GC.@preserve g unsafe_load(g.ptr).nedges

graph_node_degree(g::VNGraph, i::Integer) = Lib.graph_node_degree(g, i)
graph_min_degree(g::VNGraph) = Lib.graph_min_degree(g)
graph_max_degree(g::VNGraph) = Lib.graph_max_degree(g)
graph_mean_degree(g::VNGraph) = Lib.graph_mean_degree(g)

graph_show(g::VNGraph) = Lib.graph_show(g)

graph_nclusters(g::VNGraph) = Lib.graph_nclusters(g)
graph_connected(g::VNGraph) = Lib.graph_connected(g)

cluster(g::VNGraph,i::Integer) = GC.@preserve g unsafe_load(unsafe_load(g.ptr).l, i)
graph_cluster_sizes(g::VNGraph) = Lib.graph_cluster_sizes(g)
graph_max_cluster(g::VNGraph) = Lib.graph_max_cluster(g)

graph_gnp(g::VNGraph, p) = iszero(p) ? Lib.graph_empty(g) : Lib.graph_gnp(g, p)
graph_gnm(g::VNGraph, m) = Lib.graph_gnm(g, m)
graph_grg(g::VNGraph, r) = Lib.graph_grg(g, r)
graph_grg_torus(g::VNGraph, r) = Lib.graph_grg_torus(g, r)
graph_lognormal_grg_torus(g::VNGraph, r, alpha) = Lib.graph_lognormal_grg_torus(g, r, alpha)

# TODO random iterators

graph_clique_number(g::VNGraph) = Lib.graph_clique_number(g)

graph_local_complement(g::VNGraph, i::Integer) = Lib.graph_local_complement(g,i)

# TODO greedy and sequential color
#graph_greedy_color(graph_t g, int perm[])
#graph_sequential_color(graph_t g,int perm[], int ub)
graph_sequential_color_repeat(g::VNGraph, n::Integer) = Lib.graph_sequential_color_repeat(g, n)
graph_chromatic_number(g::VNGraph, timeout) = Lib.graph_chromatic_number(g, timeout)
graph_edge_chromatic_number(g::VNGraph, timeout) = Lib.graph_edge_chromatic_number(g, timeout)
color(g::VNGraph,i) = GC.@preserve g unsafe_load(unsafe_load(g.ptr).c, i)
graph_ncolors(g::VNGraph) = Lib.graph_ncolors(g)
graph_check_coloring(g::VNGraph) = Lib.graph_check_coloring(g)


function Graphs.SimpleGraphs.SimpleGraph(vng::VNGraph)
    n = nnodes(vng)
    g = Graphs.SimpleGraphs.SimpleGraph{Int}(n)
    GC.@preserve vng begin
        data = unsafe_load(vng.ptr)
        for i in 1:n
            for k in 1:unsafe_load(data.d, i)
                j = unsafe_load(unsafe_load(data.a, i), k)+1
                i<j && Graphs.add_edge!(g,i,j)
            end
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
