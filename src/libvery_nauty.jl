module Lib

using very_nauty_jll: libvn_graph

# Layout and signatures from very_nauty's vn_graph.h.
struct graph
    a::Ptr{Ptr{Cuint}}
    d::Ptr{Cuint}
    b::Ptr{Csize_t}
    v::Ptr{Cchar}
    c::Ptr{Cint}
    l::Ptr{Cint}
    nnodes::Cuint
    nedges::Cuint
end

const graph_t = Ptr{graph}
const clock_t = Sys.isapple() ? Culong : Sys.isfreebsd() ? Cint : Clong

graph_new(n) = ccall((:graph_new, libvn_graph), graph_t, (Cuint,), n)
graph_clear(g) = ccall((:graph_clear, libvn_graph), Cvoid, (graph_t,), g)
graph_empty(g) = ccall((:graph_empty, libvn_graph), Cvoid, (graph_t,), g)
graph_add_edge(g, i, j) = ccall((:graph_add_edge, libvn_graph), Cvoid, (graph_t, Cuint, Cuint), g, i, j)
graph_del_edge(g, i, j) = ccall((:graph_del_edge, libvn_graph), Cint, (graph_t, Cuint, Cuint), g, i, j)
graph_has_edge(g, i, j) = ccall((:graph_has_edge, libvn_graph), Cint, (graph_t, Cuint, Cuint), g, i, j)
graph_add_node(g) = ccall((:graph_add_node, libvn_graph), Cvoid, (graph_t,), g)
graph_node_degree(g, i) = ccall((:graph_node_degree, libvn_graph), Cint, (graph_t, Cuint), g, i)
graph_min_degree(g) = ccall((:graph_min_degree, libvn_graph), Cint, (graph_t,), g)
graph_max_degree(g) = ccall((:graph_max_degree, libvn_graph), Cint, (graph_t,), g)
graph_mean_degree(g) = ccall((:graph_mean_degree, libvn_graph), Cdouble, (graph_t,), g)
graph_show(g) = ccall((:graph_show, libvn_graph), Cvoid, (graph_t,), g)
graph_nclusters(g) = ccall((:graph_nclusters, libvn_graph), Cint, (graph_t,), g)
graph_connected(g) = ccall((:graph_connected, libvn_graph), Cint, (graph_t,), g)
graph_cluster_sizes(g) = ccall((:graph_cluster_sizes, libvn_graph), Ptr{Cint}, (graph_t,), g)
graph_max_cluster(g) = ccall((:graph_max_cluster, libvn_graph), Cint, (graph_t,), g)
graph_gnp(g, p) = ccall((:graph_gnp, libvn_graph), Cvoid, (graph_t, Cdouble), g, p)
graph_gnm(g, m) = ccall((:graph_gnm, libvn_graph), Cvoid, (graph_t, Culong), g, m)
graph_grg(g, r) = ccall((:graph_grg, libvn_graph), Cvoid, (graph_t, Cdouble), g, r)
graph_grg_torus(g, r) = ccall((:graph_grg_torus, libvn_graph), Cvoid, (graph_t, Cdouble), g, r)
graph_lognormal_grg_torus(g, r, alpha) = ccall((:graph_lognormal_grg_torus, libvn_graph), Cvoid, (graph_t, Cdouble, Cdouble), g, r, alpha)
graph_clique_number(g) = ccall((:graph_clique_number, libvn_graph), Cint, (graph_t,), g)
graph_local_complement(g, i) = ccall((:graph_local_complement, libvn_graph), Cvoid, (graph_t, Cuint), g, i)
graph_sequential_color_repeat(g, n) = ccall((:graph_sequential_color_repeat, libvn_graph), Cint, (graph_t, Cint), g, n)
graph_chromatic_number(g, timeout) = ccall((:graph_chromatic_number, libvn_graph), Cint, (graph_t, clock_t), g, timeout)
graph_edge_chromatic_number(g, timeout) = ccall((:graph_edge_chromatic_number, libvn_graph), Cint, (graph_t, clock_t), g, timeout)
graph_ncolors(g) = ccall((:graph_ncolors, libvn_graph), Cint, (graph_t,), g)
graph_check_coloring(g) = ccall((:graph_check_coloring, libvn_graph), Cint, (graph_t,), g)

end
