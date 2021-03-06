module Application

using ..Msg: TerminatedMsg, Pid
using ..Supervisor
using ..Agent
using ..RegistryService

struct AppConfig
    name
    mod
    args                        
    size    
end

struct State
    appliConfig::AppConfig
    pid::Pid
end


function start(name, mod, args, registryConfig=nothing)
    reg = start_registry(registryConfig)    
    return Agent.start( name
                        , mod
                        , args
                        , nothing
                        , 8)
end

function start_registry()
    return start_registry(nothing)
end
function start_registry(appConfig)
    serviceMod = RegistryService
    serviceArgs = nothing

    if !isnothing(appConfig)
        serviceMod = appConfig.mod
        serviceArgs = appConfig.args
    end


    reg = Agent.start( :RegistryService
                       , serviceMod
                       , serviceArgs
                       , nothing
                       , 64)
    task_local_storage(:registryService, (mod=serviceMod,pid=reg))
    return reg
end

function init(m, args)
    appConfig = m.init(args)
    return start_service(appConfig)
end

function loop(m, event, state)    
    return state, Agent.NoTerminate()
end



function start_service(appConfig)    
    pid = Agent.start( appConfig.name
                       , appConfig.mod
                       , appConfig.args                    
                       , nothing
                       , appConfig.size)
    return State(appConfig, pid)
end


end
