@testitem "Graphs.jl Interface" begin

import Graphs
using VNGraphs
using Interfaces
using GraphsInterfaceChecker

# Test with a variety of graph sizes and densities
vngs = [
    VNGraph(0),
    VNGraph(1),
    VNGraph(5),
    VNGraph(12),
    VNGraph(20),
    VNGraph(Graphs.random_regular_graph(6, 4)),
    VNGraph(Graphs.random_regular_graph(10, 3)),
    VNGraph(Graphs.random_regular_graph(12, 5)),
    VNGraph(Graphs.cycle_graph(8)),
    VNGraph(Graphs.path_graph(7)),
]
Interfaces.@implements GraphsInterfaceChecker.AbstractGraphInterface VNGraph vngs
@test Interfaces.test(GraphsInterfaceChecker.AbstractGraphInterface, VNGraph)

end

@testitem "Edge iteration" begin

import Graphs
using VNGraphs

# Empty graph
g = VNGraph(5)
@test Graphs.ne(g) == 0
@test collect(Graphs.edges(g)) == []

# Add edges and check iteration
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 2))
Graphs.add_edge!(g, Graphs.SimpleEdge(2, 3))
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 5))
@test Graphs.ne(g) == 3

edge_list = collect(Graphs.edges(g))
@test length(edge_list) == 3
@test Graphs.SimpleEdge{Cuint}(1, 2) in edge_list
@test Graphs.SimpleEdge{Cuint}(2, 3) in edge_list
@test Graphs.SimpleEdge{Cuint}(1, 5) in edge_list

# Round-trip: edges from VNGraph should reconstruct the same graph
g_orig = Graphs.random_regular_graph(10, 4)
vng = VNGraph(g_orig)
g_back = Graphs.SimpleGraph(vng)
@test g_back == g_orig

end

@testitem "Neighbor access" begin

import Graphs
using VNGraphs

g = VNGraph(5)
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 2))
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 3))
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 5))

# outneighbors returns sorted 1-based indices
@test Graphs.outneighbors(g, 1) == Cuint[2, 3, 5]
@test Graphs.outneighbors(g, 2) == Cuint[1]
@test Graphs.outneighbors(g, 4) == Cuint[]

# inneighbors == outneighbors for undirected graphs
@test Graphs.inneighbors(g, 1) == Graphs.outneighbors(g, 1)

# Out of range returns empty
@test Graphs.outneighbors(g, 0) == Cuint[]
@test Graphs.outneighbors(g, 6) == Cuint[]

end

@testitem "has_edge with 1-based indices" begin

import Graphs
using VNGraphs

g = VNGraph(5)
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 3))

# has_edge should use 1-based indices
@test Graphs.has_edge(g, 1, 3)
@test Graphs.has_edge(g, 3, 1)  # undirected
@test !Graphs.has_edge(g, 1, 2)
@test !Graphs.has_edge(g, 2, 3)

end

@testitem "Vertex and edge mutation" begin

import Graphs
using VNGraphs

g = VNGraph(3)
@test Graphs.nv(g) == 3
@test Graphs.ne(g) == 0

# Add edges
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 2))
Graphs.add_edge!(g, Graphs.SimpleEdge(2, 3))
@test Graphs.ne(g) == 2
@test Graphs.has_edge(g, 1, 2)

# Remove edge
@test Graphs.rem_edge!(g, Graphs.SimpleEdge(1, 2))
@test Graphs.ne(g) == 1
@test !Graphs.has_edge(g, 1, 2)
@test Graphs.has_edge(g, 2, 3)

# Remove non-existent edge
@test !Graphs.rem_edge!(g, Graphs.SimpleEdge(1, 5))

# Add vertex
Graphs.add_vertex!(g)
@test Graphs.nv(g) == 4
@test Graphs.has_vertex(g, 4)

# Add edge to new vertex
Graphs.add_edge!(g, Graphs.SimpleEdge(1, 4))
@test Graphs.has_edge(g, 1, 4)

end

@testitem "Copy" begin

import Graphs
using VNGraphs

g = VNGraph(Graphs.random_regular_graph(8, 4))
g2 = copy(g)

@test Graphs.nv(g2) == Graphs.nv(g)
@test Graphs.ne(g2) == Graphs.ne(g)

# Same edges
for e in Graphs.edges(g)
    @test Graphs.has_edge(g2, e.src, e.dst)
end

# Independent: mutating copy doesn't affect original
n = Graphs.nv(g2)
Graphs.add_edge!(g2, Graphs.SimpleEdge{Cuint}(Cuint(1), n))
ne_orig = Graphs.ne(g)
@test Graphs.ne(g) == ne_orig  # original unchanged

end

@testitem "Consistency checks (extended)" begin

import Graphs
using VNGraphs

# Round-trip consistency for various graph types
for _ in 1:50
    g = Graphs.random_regular_graph(8, 4)
    vng = VNGraph(g)
    g2 = Graphs.Graph(vng)
    @test g2 == g
end

# Cycle graph
for n in 3:10
    g = Graphs.cycle_graph(n)
    vng = VNGraph(g)
    @test Graphs.nv(vng) == n
    @test Graphs.ne(vng) == n
    g2 = Graphs.Graph(vng)
    @test g2 == g
end

# Path graph
for n in 2:10
    g = Graphs.path_graph(n)
    vng = VNGraph(g)
    @test Graphs.nv(vng) == n
    @test Graphs.ne(vng) == n - 1
    g2 = Graphs.Graph(vng)
    @test g2 == g
end

# Star graph
g = Graphs.star_graph(6)
vng = VNGraph(g)
@test Graphs.nv(vng) == 6
@test Graphs.ne(vng) == 5
@test length(Graphs.outneighbors(vng, 1)) == 5

end
