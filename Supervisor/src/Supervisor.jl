module Supervisor

using Msg: TerminatedMsg, Pid

using Agent
struct ChildSpec
    name
    mod
    args
    size
    pid
end
ChildSpec(name, mod, args, size) = ChildSpec(name, mod, args, size, nothing)
ChildSpec(cs::ChildSpec, pid::Pid) = ChildSpec( cs.name, cs.mod, cs.args, cs.size, pid)

struct ChildrenMsg
end
struct AddMsg
    childSpec::ChildSpec 
end
struct RemoveMsg
    id::Int64
end

struct State
    children
end
State()=State(Dict())

function init(m, args)
    state = State()
    childSpecs = m.init(args)
    for (childId, child) in enumerate(childSpecs)
        newChild = start_child(childId, child)
        setindex!(state.children, newChild, childId)
    end    
    return state
end

function dispatch_work(m, event::ChildrenMsg, state)    
    return state, Agent.NoTerminate()
end

function dispatch_work(m, event::AddMsg, state)
    childId = maximum(keys(state.children))+1
    start_child!(childId, event.childSpec, state)
    return state, Agent.NoTerminate()
end

function dispatch_work(m, event::RemoveMsg, state)
    child=get(state.children, event.id, nothing)    
    if child != nothing
        Agent.terminate(child.channel, state.channel)
        delete!(state.children, event.id)
    end            
    return state, Agent.NoTerminate()
end

function dispatch_work(m, event::TerminatedMsg, state)    
    child=get(state.children, event.childId, nothing)  
    if child != nothing
        newChild = restart_child(event.channel, event.childId, child)
        setindex!(state.children, newChild, event.childId)
    end
    #println("terminated $event")
    return state, Agent.NoTerminate()
end

function restart_child(ch, childId, childSpec)    
    childPid = Agent.restart( ch
                              , childSpec.name
                              , childSpec.mod
                              , childSpec.args                    
                              , Agent.SupervisorInfo(childId))    
    return ChildSpec(childSpec, childPid)
end
function start_child(childId, childSpec)    
    childPid = Agent.start( childSpec.name
                            , childSpec.mod
                            , childSpec.args                    
                            , Agent.SupervisorInfo(childId)
                            , childSpec.size)    
    return ChildSpec(childSpec, childPid)
end

end
