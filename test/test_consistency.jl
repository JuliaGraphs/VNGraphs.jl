@testitem "Consistency checks" begin

import Graphs
using VNGraphs
using Interfaces
using GraphsInterfaceChecker

for i in 1:100
    g = Graphs.random_regular_graph(5, 4)
    vng = VNGraph(g)
    g2 = Graphs.Graph(vng)
    @test g2 == g
end

g = VNGraph(5); for i in 2:5 Graphs.add_edge!(g,1,i) end; Graphs.add_edge!(g,2,5)
@test VNGraphs.graph_chromatic_number(g,0)==3

@testset "Graphs.jl Interface Check for VNGraph" begin
    vngs = [VNGraph(12), VNGraph(20), VNGraph(5)]
    Interfaces.@implements GraphsInterfaceChecker.AbstractGraphInterface VNGraph vngs
    @test Interfaces.test(GraphsInterfaceChecker.AbstractGraphInterface, VNGraph)
end

end
