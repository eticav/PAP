module RegistryService

using ..Worker
using ..Agent
using ..Msg: OkMsg, ErrorMsg, Pid


struct State
    registry    
    State()=new(Dict())
end

struct RegisterMsg
    pid
end

struct UnregisterMsg
    name
end

struct WhereisMsg
    name
end

function behaviour()
    return Worker
end

function init(args)    
    return State()
end

function handle_call(event::RegisterMsg, state)    
    if get(state.registry, event.pid.name, nothing) === nothing        
        setindex!(state.registry, event.pid, event.pid.name)#side-effect
        println("ehllo $event")
        return Worker.reply(OkMsg(),state)
    else
        return Worker.reply(ErrorMsg("key $(event.pid.name) already exists"), state)
    end
end

function handle_call(event::UnregisterMsg, state)
    delete!(state.registry, event.name) #side-effect
    return Worker.reply(OkMsg(), state)
end

function handle_call(event::WhereisMsg, state)
    resp = get(state.registry, event.name, nothing)    
    if resp === nothing
        return Worker.reply(ErrorMsg("process $(event.name) not found"), state)
    else
        return Worker.reply(OkMsg(resp), state)
    end
    
end

function handle_call(event, state)
    println("unknown event $event")
end

function register(pid::Pid, rs)    
    return Worker.call(RegisterMsg(pid), rs)
end

function unregister(pid::Pid,rs)
    return unregister(pid.name,rs)
end
function unregister(name,rs)
    return Worker.call(UnregisterMsg(name), rs)
end

function whereis(name,rs)
    return Worker.call(WhereisMsg(name), rs)
end

end

