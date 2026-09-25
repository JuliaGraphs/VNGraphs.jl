@testitem "JET analysis" tags=[:jet] begin

using JET
using Test
using VNGraphs

JET.test_package(VNGraphs; target_modules=(VNGraphs, VNGraphs.Lib))

end
