using BenchmarkTools
using VNGraphs
using Graphs

const SUITE = BenchmarkGroup()

# Clique number benchmark
SUITE["clique"] = BenchmarkGroup()
for n in [10, 50, 100]
    g = complete_graph(n)
    vng = VNGraph(g)
    SUITE["clique"][n] = @benchmarkable clique_number($vng)
end

# Chromatic number benchmark
SUITE["chromatic"] = BenchmarkGroup()
for n in [5, 10, 15]
    g = cycle_graph(n)
    vng = VNGraph(g)
    SUITE["chromatic"][n] = @benchmarkable chromatic_number($vng)
end
