module Msg

struct Pid
    name::Any
    id::Task
    channel::Channel    
end
Pid(id,channel)=Pid(nothing,id,channel)


struct SubscribeMsg
    pid::Pid
end
struct UnsubscribeMsg
    pid::Pid
end

struct OkMsg
    value
end
OkMsg()=OkMsg(nothing)

struct ErrorMsg
    error
end

ReplyMsg = Union{OkMsg,ErrorMsg}

## Registry Service

struct TerminatedMsg
    childId::Int64
    channel
end

withDefault(x::OkMsg, default)=x.value
withDefault(x::ErrorMsg, default)=default

isError(x::ErrorMsg)=true
isError(x::OkMsg)=false

# public

function resolveDo(f, pid::Pid)
    f(pid.channel)
end
function resolveDo(f, to)
    registryMod, registryPid = get(task_local_storage(), :registryService, (nothing, nothing))
    if isnothing(registryMod)
        return ErrorMsg("No registry service")
    end
    result = registryMod.whereis(to,registryPid)
    if isError(result)
        return result
    end
    println("is closed : $((isopen(result.value.channel)))")
    return f(result.value)
end

function subscribe(agent::Pid, publisher::Channel)
    put!(publisher, SubscribeMsg(agent))
end
function subscribe(agent::Pid, publisher)
    resolveDo(x->subscribe(agent,x), publisher)
end
function subscribe(agent, publisher)
    resolveDo(x->subscribe(x,publisher), agent)
end

function unsubscribe(agent::Pid, publisher::Channel)
    put!(publisher, UnsubscribeMsg(agent))
end
function unsubscribe(agent::Pid, publisher)
    resolveDo(x->unsubscribe(agent,x), publisher)
end
function unsubscribe(agent, publisher)
    resolveDo(x->unsubscribe(x,publisher), agent)
end

end # module
