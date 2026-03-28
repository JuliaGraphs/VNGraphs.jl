@testitem "Interface Checker" begin
    using VNGraphs
    using GraphsInterfaceChecker
    using Interfaces
    import Graphs

    # Define some test graphs
    test_graphs = [
        VNGraph(0),
        VNGraph(1),
        VNGraph(5),
        begin
            g = VNGraph(5)
            Graphs.add_edge!(g, 1, 2)
            Graphs.add_edge!(g, 2, 3)
            Graphs.add_edge!(g, 3, 4)
            Graphs.add_edge!(g, 4, 1)
            g
        end,
        begin
            g = VNGraph(10)
            for i in 1:9
                Graphs.add_edge!(g, i, i+1)
            end
            g
        end
    ]

    # Declare implementation
    Interfaces.@implements AbstractGraphInterface VNGraph test_graphs

    # Run tests
    @test Interfaces.test(AbstractGraphInterface, VNGraph)
end
