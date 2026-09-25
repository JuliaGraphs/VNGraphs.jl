@testitem "Native bindings" begin

import Graphs
using VNGraphs

# A triangle with a tail, a separate edge, and an isolated vertex.
reference = Graphs.Graph(7)
for (i, j) in [(1, 2), (2, 3), (3, 1), (3, 4), (5, 6)]
    Graphs.add_edge!(reference, i, j)
end
g = VNGraph(reference)
GC.gc()
@test Graphs.Graph(g) == reference
@test Graphs.nv(g) == Graphs.nv(reference)
@test Graphs.ne(g) == Graphs.ne(reference)
@test [VNGraphs.graph_node_degree(g, i-1) for i in Graphs.vertices(reference)] == Graphs.degree(reference)
@test VNGraphs.graph_min_degree(g) == minimum(Graphs.degree(reference))
@test VNGraphs.graph_max_degree(g) == maximum(Graphs.degree(reference))
@test VNGraphs.graph_mean_degree(g) ≈ 2 * Graphs.ne(reference) / Graphs.nv(reference)

components = Graphs.connected_components(reference)
@test VNGraphs.graph_nclusters(g) == length(components)
@test VNGraphs.graph_connected(g) == Graphs.is_connected(reference)
@test VNGraphs.graph_max_cluster(g) == maximum(length, components)
labels = [VNGraphs.cluster(g, i) for i in Graphs.vertices(reference)]
@test sort([count(==(label), labels) for label in unique(labels)]) == sort(length.(components))

@test VNGraphs.graph_clique_number(g) == 3
@test VNGraphs.graph_chromatic_number(g, 0) == 3
@test VNGraphs.graph_sequential_color_repeat(g, 3) == 3
@test VNGraphs.graph_ncolors(g) == 3
@test VNGraphs.graph_check_coloring(g) == 1
@test all(VNGraphs.color(g, e.src) != VNGraphs.color(g, e.dst) for e in Graphs.edges(reference))
@test VNGraphs.graph_edge_chromatic_number(VNGraph(Graphs.cycle_graph(3)), 0) == 3

# The thin C wrappers use zero-based vertex indices.
VNGraphs.graph_add_edge(g, 3, 4)
Graphs.add_edge!(reference, 4, 5)
@test VNGraphs.graph_has_edge(g, 3, 4) == 1
@test Graphs.Graph(g) == reference
@test VNGraphs.graph_del_edge(g, 3, 4) == Graphs.rem_edge!(reference, 4, 5)
VNGraphs.graph_add_node(g)
Graphs.add_vertex!(reference)
@test Graphs.Graph(g) == reference
VNGraphs.graph_local_complement(g, 2)
VNGraphs.graph_local_complement(g, 2)
@test Graphs.Graph(g) == reference

VNGraphs.graph_gnp(g, 1.0)
@test Graphs.Graph(g) == Graphs.complete_graph(Graphs.nv(g))
VNGraphs.graph_gnp(g, 0.0)
@test Graphs.Graph(g) == Graphs.Graph(Graphs.nv(g))
VNGraphs.graph_gnm(g, 5)
@test Graphs.ne(g) == Graphs.ne(Graphs.Graph(g)) == 5

end
