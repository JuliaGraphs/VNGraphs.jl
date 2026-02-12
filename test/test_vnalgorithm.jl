@testitem "VNAlgorithm dispatch - is_connected" begin

import Graphs
using VNGraphs

alg = VNAlgorithm()

# Connected graph
g = Graphs.cycle_graph(5)
@test Graphs.is_connected(g, alg) == true

# Disconnected graph
g2 = Graphs.SimpleGraph(6)
Graphs.add_edge!(g2, 1, 2)
Graphs.add_edge!(g2, 3, 4)
@test Graphs.is_connected(g2, alg) == false

# Single vertex
g3 = Graphs.SimpleGraph(1)
@test Graphs.is_connected(g3, alg) == true

# Works on VNGraph directly too
vng = VNGraph(Graphs.path_graph(4))
@test Graphs.is_connected(vng, alg) == true

end

@testitem "VNAlgorithm dispatch - connected_components" begin

import Graphs
using VNGraphs

alg = VNAlgorithm()

# Single component
g = Graphs.cycle_graph(5)
cc = Graphs.connected_components(g, alg)
@test length(cc) == 1
@test sort(cc[1]) == [1, 2, 3, 4, 5]

# Two components
g2 = Graphs.SimpleGraph(6)
Graphs.add_edge!(g2, 1, 2)
Graphs.add_edge!(g2, 1, 3)
Graphs.add_edge!(g2, 4, 5)
Graphs.add_edge!(g2, 5, 6)
cc2 = Graphs.connected_components(g2, alg)
@test length(cc2) == 2
sorted_cc = sort(cc2, by=minimum)
@test sort(sorted_cc[1]) == [1, 2, 3]
@test sort(sorted_cc[2]) == [4, 5, 6]

# All isolated vertices
g3 = Graphs.SimpleGraph(4)
cc3 = Graphs.connected_components(g3, alg)
@test length(cc3) == 4
for c in cc3
    @test length(c) == 1
end

# Works on VNGraph directly
vng = VNGraph(g2)
cc4 = Graphs.connected_components(vng, alg)
@test length(cc4) == 2

end

@testitem "VNAlgorithm dispatch - chromatic_number" begin

import Graphs
using VNGraphs

alg = VNAlgorithm()

# Complete graph K4 has chromatic number 4
g = Graphs.complete_graph(4)
@test chromatic_number(g, alg) == 4

# Cycle of even length is 2-colorable
g2 = Graphs.cycle_graph(6)
@test chromatic_number(g2, alg) == 2

# Cycle of odd length needs 3 colors
g3 = Graphs.cycle_graph(5)
@test chromatic_number(g3, alg) == 3

# Path graph is 2-colorable (bipartite)
g4 = Graphs.path_graph(5)
@test chromatic_number(g4, alg) == 2

# Single vertex
g5 = Graphs.SimpleGraph(1)
@test chromatic_number(g5, alg) == 1

# Star graph is 2-colorable
g6 = Graphs.star_graph(5)
@test chromatic_number(g6, alg) == 2

# Works on VNGraph directly
vng = VNGraph(Graphs.complete_graph(3))
@test chromatic_number(vng, alg) == 3

end

@testitem "VNAlgorithm dispatch - edge_chromatic_number" begin

import Graphs
using VNGraphs

alg = VNAlgorithm()

# Complete graph K4: edge chromatic number = 3 (by Vizing's theorem, max_degree = 3)
g = Graphs.complete_graph(4)
@test edge_chromatic_number(g, alg) == 3

# Cycle of even length: edge chromatic number = 2
g2 = Graphs.cycle_graph(6)
@test edge_chromatic_number(g2, alg) == 2

# Cycle of odd length: edge chromatic number = 3
g3 = Graphs.cycle_graph(5)
@test edge_chromatic_number(g3, alg) == 3

# Path graph: edge chromatic number = 1 for P2, 2 for longer
g4 = Graphs.path_graph(2)
@test edge_chromatic_number(g4, alg) == 1

g5 = Graphs.path_graph(4)
@test edge_chromatic_number(g5, alg) == 2

end

@testitem "VNAlgorithm dispatch - clique_number" begin

import Graphs
using VNGraphs

alg = VNAlgorithm()

# Complete graph K5 has clique number 5
g = Graphs.complete_graph(5)
@test clique_number(g, alg) == 5

# Cycle graph has clique number 2
g2 = Graphs.cycle_graph(6)
@test clique_number(g2, alg) == 2

# Graph with a triangle
g3 = Graphs.SimpleGraph(4)
Graphs.add_edge!(g3, 1, 2)
Graphs.add_edge!(g3, 2, 3)
Graphs.add_edge!(g3, 1, 3)
Graphs.add_edge!(g3, 3, 4)
@test clique_number(g3, alg) == 3

# Path graph has clique number 2
g4 = Graphs.path_graph(5)
@test clique_number(g4, alg) == 2

# Single vertex has clique number 1
g5 = Graphs.SimpleGraph(1)
@test clique_number(g5, alg) == 1

# Edge-less graph: each vertex is a clique of size 1
g6 = Graphs.SimpleGraph(5)
@test clique_number(g6, alg) == 1

# Works on VNGraph directly
vng = VNGraph(Graphs.complete_graph(4))
@test clique_number(vng, alg) == 4

end

@testitem "VNAlgorithm auto-conversion from SimpleGraph" begin

import Graphs
using VNGraphs

alg = VNAlgorithm()

# All dispatch methods should accept SimpleGraph and auto-convert
g = Graphs.random_regular_graph(10, 4)

# Should not throw
@test Graphs.is_connected(g, alg) isa Bool
cc = Graphs.connected_components(g, alg)
@test cc isa Vector
@test chromatic_number(g, alg) isa Int
@test clique_number(g, alg) isa Int
@test edge_chromatic_number(g, alg) isa Int

# Verify consistency with Graphs.jl's own implementations
@test Graphs.is_connected(g, alg) == Graphs.is_connected(g)
cc_graphs = Graphs.connected_components(g)
cc_vn = Graphs.connected_components(g, alg)
@test length(cc_graphs) == length(cc_vn)

end
