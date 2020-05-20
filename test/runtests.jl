using PAP
using Test

include("PongServer.jl")

include("PongSup.jl")
using .PongSup

include("PongApp.jl")
using .PongApp

@testset "call" begin
    ch=PAP.Agent.start(:PongServer, PongServer, nothing, 10)    
    result = PAP.Worker.call(PongServer.Ping(), ch)
    @test result==PongServer.Pong()
end

@testset "call + state modif" begin
    ch=PAP.Agent.start(PongServer,nothing,10)
    PAP.Worker.call(PongServer.Ping(), ch)
    PAP.Worker.call(PongServer.Ping(), ch)
    PAP.Worker.call(PongServer.Ping(), ch)
    result = PAP.Worker.call(PongServer.Count(), ch)
    @test result==3
end

@testset "cast" begin
    ch1=PAP.Agent.start(PongServer,nothing, 10)        
    ag=PAP.Worker.cast(PongServer.Pong(), ch1)
    PAP.Worker.cast(PongServer.Pong(), ag)
    result=PAP.Worker.call(PongServer.Count(), ch1)
    @test true
end

@testset "call with sub + state modif" begin
    ch1=PAP.Agent.start(PongServer,nothing, 100)
    ch2=PAP.Agent.start(PongServer,nothing, 100)
    r=PAP.Msg.subscribe(ch2,ch1)    
    r=PAP.Worker.call(PongServer.Ping(), ch1)
    
    result = PAP.Worker.call(PongServer.Count(), ch2)    
    @test result==1
end

@testset "register successfully in RegistryService" begin
    rs = PAP.Application.start_registry()
    
    ch=PAP.Agent.start("helloService", PongServer,nothing, 100)
    PAP.RegistryService.register(ch, rs)    
    result = PAP.RegistryService.whereis("helloService", rs) |> (x)->PAP.Msg.withDefault(x,nothing)    
    @test result == ch
end

@testset "whereis failure RegistryService" begin
    rs = PAP.Application.start_registry()
    
    result = PAP.RegistryService.whereis("helloService", rs)
    @test PAP.Msg.isError(result)
end

@testset "register and unregister successfully in RegistryService" begin
    rs = PAP.Application.start_registry()
    
    ch=PAP.Agent.start("helloService", PongServer, nothing)
    PAP.RegistryService.register(ch, rs)
    PAP.RegistryService.unregister("helloService", rs)
    result = PAP.RegistryService.whereis("helloService", rs) |> (x)->PAP.Msg.withDefault(x,nothing)    
    @test result == nothing
end

@testset "whereis success registering in agent construct" begin
    rs = PAP.Application.start_registry()
    
    ch=PAP.Agent.start(:PongServer, PongServer, nothing, 100)    
    result = PAP.RegistryService.whereis(:PongServer, rs) |> (x)->PAP.Msg.withDefault(x,nothing)    
    @test result === ch
end

@testset "call success registering in agent construct" begin
    rs = PAP.Application.start_registry()    
    
    ch=PAP.Agent.start(:PongServer, PongServer, nothing, 100)
    PAP.Worker.call(PongServer.Ping(), :PongServer)
    result = PAP.Worker.call(PongServer.Count(), :PongServer)
    @test result==1
end

@testset "call with sub + state modif registering in agent construct" begin
    rs = PAP.Application.start_registry()    
    
    PAP.Agent.start(:PongServer1, PongServer, nothing, 100)
    PAP.Agent.start(:PongServer2, PongServer, nothing, 100)
    PAP.Msg.subscribe(:PongServer2, :PongServer1)
    PAP.Worker.call(PongServer.Ping(), :PongServer1)
    
    result = PAP.Worker.call(PongServer.Count(), :PongServer2)   
    @test result==1
end

@testset "start worker with supervisor" begin
    rs = PAP.Application.start_registry()
    
    ch=PAP.Agent.start(:TestSup, PongSup, "PongServer")
    result = PAP.Worker.call(PongServer.Ping(), "PongServer")
    @test result==PongServer.Pong()
end

@testset "start worker in application" begin
    app = PAP.Application.start(:PongApp, PongApp, (:with_server_only_mode
                                                    , "PongServer"))
    result = PAP.Worker.call(PongServer.Ping(), "PongServer")
    @test result==PongServer.Pong()
end

@testset "start supervisor in application" begin
    app = PAP.Application.start(:PongApp, PongApp, (:with_supervisor_mode
                                                    , "PongSup"
                                                    , "PongServer"))
    result = PAP.Worker.call(PongServer.Ping(), "PongServer")        
    @test result==PongServer.Pong()
    
    PAP.Agent.terminate("PongServer")
    
    result = PAP.Worker.call(PongServer.Ping(), "PongServer")
    @test result==PongServer.Pong()
end

