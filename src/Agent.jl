module Agent

using ..Msg: TerminatedMsg, Pid, resolveDo

struct Terminate end
struct NoTerminate end

struct SupervisorInfo
    pid
    childId
end

struct TerminateMsg    
end

SupervisorInfo(childId)=SupervisorInfo(self(),childId)

function dispatch_work(m, x::TerminateMsg, state)    
    return state, false
end

function dispatch_work(m, event, state)
    state, terminateStatus = m.behaviour().dispatch_work(m, event, state)
    return  state,  terminateStatus === NoTerminate()
end

function informeSupervisor(supervisor::Nothing)    
end 

function informeSupervisor(x::SupervisorInfo)
    informeSupervisor(x.childId, x.pid)
end
function informeSupervisor(childId, pid::Pid)    
    put!(pid.channel, TerminatedMsg(childId, self().channel))
    return pid
end

function init_state(m, args)
    try
        m.behaviour().init(m, args)    
    catch(e)
        println("ERROR ::: init_state $m = $e")
    end    
end

function worker_loop( name,
                      m,
                      args,                     
                      ch,
                      registryService,
                      supervisorInfo,
                      initialized)
    pid =  Pid(name, current_task(), ch)
    if isnothing(supervisorInfo)
        bind(ch, current_task())
    end    
    task_local_storage(:registryService, registryService)
    task_local_storage(:channel, ch)
    task_local_storage(:self, pid)
    
    state = init_state(m, args)
    Base.notify(initialized)
    goOn = true
    ExitReason = nothing
    try
        while goOn
            value = take!(ch)
            state, goOn = dispatch_work(m, value, state)            
        end
    catch(e)
        println("ERROR ::: worker_loop in $m = $e")
    finally        
        ExitReason = m.behaviour().terminate(m, ExitReason, state)        
        informeSupervisor(supervisorInfo)      
    end
end

function restart( ch
                  , name
                  , m
                  , args                                   
                  , supervisorInfo)    
    registryService = get(task_local_storage(), :registryService, nothing)    
    initialized = Base.Condition()
    task = @async worker_loop( name,
                               m,
                               args,
                               ch,
                               registryService,
                               supervisorInfo,
                               initialized)
    Base.wait(initialized)
    if !isnothing(name) && !isnothing(registryService)
        pid =  Pid(name, task, ch)
        registryService.mod.register(pid, registryService.pid)        
    end
    
    return Pid(name, task, ch)
end



################# Public


function terminate(agent::Channel)
    put!(agent, TerminateMsg())
end
function terminate(agent)
    resolveDo(x->terminate(x), agent)
end

function start( m::Module
                , args
                , supervisorInfo=nothing
                , size=64)
    return start( nothing
                  , m
                  , args
                  , supervisorInfo
                  , size)
end

function start( name
                , m::Module
                , args
                , supervisorInfo=nothing
                , size=64)    
    ch = Channel(size)        
    return restart( ch
                    , name
                    , m
                    , args                    
                    , supervisorInfo)    
end


function self()
    task_local_storage(:self)
end

end
