using PAP
using Application
using Agent
using RegistryService
using Msg
using Test
using Worker
using Supervisor

include("PongServer.jl")

include("PongSup.jl")
using .PongSup

include("PongApp.jl")
using .PongApp


# @testset "call" begin
#     ch=Agent.start(:PongServer, PongServer, nothing, 10)    
#     result = Worker.call(PongServer.Ping(), ch)
#     @test result==PongServer.Pong()
# end

# @testset "call + state modif" begin
#     ch=Agent.start(PongServer,nothing,10)
#     Worker.call(PongServer.Ping(), ch)
#     Worker.call(PongServer.Ping(), ch)
#     Worker.call(PongServer.Ping(), ch)
#     result = Worker.call(PongServer.Count(), ch)
#     @test result==3
# end

# @testset "cast" begin
#     ch1=Agent.start(PongServer,nothing, 10)        
#     ag=Worker.cast(PongServer.Pong(), ch1)
#     Worker.cast(PongServer.Pong(), ag)
#     result=Worker.call(PongServer.Count(), ch1)
#     @test true
# end

# @testset "call with sub + state modif" begin
#     ch1=Agent.start(PongServer,nothing, 100)
#     ch2=Agent.start(PongServer,nothing, 100)
#     r=Msg.subscribe(ch2,ch1)    
#     r=Worker.call(PongServer.Ping(), ch1)
    
#     result = Worker.call(PongServer.Count(), ch2)    
#     @test result==1
# end

# @testset "register successfully in RegistryService" begin
#     rs = Application.start_registry()
    
#     ch=Agent.start("helloService", PongServer,nothing, 100)
#     RegistryService.register(ch, rs)    
#     result = RegistryService.whereis("helloService", rs) |> (x)->Msg.withDefault(x,nothing)    
#     @test result == ch
# end

# @testset "whereis failure RegistryService" begin
#     rs = Application.start_registry()
    
#     result = RegistryService.whereis("helloService", rs)
#     @test Msg.isError(result)
# end

# @testset "register and unregister successfully in RegistryService" begin
#     rs = Application.start_registry()
    
#     ch=Agent.start("helloService", PongServer, nothing)
#     RegistryService.register(ch, rs)
#     RegistryService.unregister("helloService", rs)
#     result = RegistryService.whereis("helloService", rs) |> (x)->Msg.withDefault(x,nothing)    
#     @test result == nothing
# end

# @testset "whereis success registering in agent construct" begin
#     rs = Application.start_registry()
    
#     ch=Agent.start(:PongServer, PongServer, nothing, 100)    
#     result = RegistryService.whereis(:PongServer, rs) |> (x)->Msg.withDefault(x,nothing)    
#     @test result === ch
# end

# @testset "call success registering in agent construct" begin
#     rs = Application.start_registry()    
    
#     ch=Agent.start(:PongServer, PongServer, nothing, 100)
#     Worker.call(PongServer.Ping(), :PongServer)
#     result = Worker.call(PongServer.Count(), :PongServer)
#     @test result==1
# end

# @testset "call with sub + state modif registering in agent construct" begin
#     rs = Application.start_registry()    
    
#     Agent.start(:PongServer1, PongServer, nothing, 100)
#     Agent.start(:PongServer2, PongServer, nothing, 100)
#     Msg.subscribe(:PongServer2, :PongServer1)
#     Worker.call(PongServer.Ping(), :PongServer1)
    
#     result = Worker.call(PongServer.Count(), :PongServer2)   
#     @test result==1
# end

# @testset "start worker with supervisor" begin
#     rs = Application.start_registry()
    
#     ch=Agent.start(:TestSup, PongSup, "PongServer")
#     result = Worker.call(PongServer.Ping(), "PongServer")
#     @test result==PongServer.Pong()
# end

# @testset "start worker in application" begin
#     app = Application.start(:PongApp, PongApp, (:with_server_only_mode
#                                                 , "PongServer"))
#     result = Worker.call(PongServer.Ping(), "PongServer")
#     @test result==PongServer.Pong()
# end

@testset "start supervisor in application" begin
    app = Application.start(:PongApp, PongApp, (:with_supervisor_mode
                                                , "PongSup"
                                                , "PongServer"))
    result = Worker.call(PongServer.Ping(), "PongServer")        
    @test result==PongServer.Pong()
    
    Agent.terminate("PongServer")
    
    result = Worker.call(PongServer.Ping(), "PongServer")
    @test result==PongServer.Pong()
end