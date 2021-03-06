module Worker

using ..Msg:  SubscribeMsg, UnsubscribeMsg, Pid, resolveDo
using ..Agent

struct CallMsg
    from::Channel
    value::Any
    CallMsg(from,value)=new(from,value)
end

struct CastMsg    
    value::Any
end

function cast(value, signal::Channel)
    put!(signal, CastMsg(value))
    return signal
end
function cast(value, to)
    resolveDo(x->cast(value, x), to)
end

function call(value, signal::Channel)
    try
        respCh = Channel()        
        put!(signal, CallMsg(respCh,value))
        result = take!(respCh)    
        close(respCh)
        return result
    catch(e)
        println("call in worker $value error $e")
        throw(e)
    end
end
function call(value, to)
    resolveDo(x->call(value, x), to)
end

function reply(reply, state)
    Result(reply, nothing, Agent.NoTerminate(), state)
end

function reply(reply, fw, state)
    Result(reply, fw, Agent.NoTerminate(), state)
end

function fwd(fw, state)
    Result(nothing, fw, Agent.NoTerminate(), state)
end

struct State
    state
    subscribers
end

struct Result
    reply
    fwd
    next
    state
end

function terminate(R::Result)
    R.next=Agent.Terminate()
end

function init(m, args)
    return State(m.init(args), Set{Pid}([]))
end

handle_call_default(request, state) = (state, Agent.NoTerminate())
handle_cast_default(request, state) = (state, Agent.NoTerminate())
handle_terminate_default(state) = nothing
error_default(err, state) = (state, Terminate())

function fwdToSubscribers(fwd, subscribers)    
    if !isnothing(fwd)        
        for sub in subscribers            
            cast(fwd, sub)
        end        
    end
end

function dispatch_work(m, x::SubscribeMsg, state)    
    union!(state.subscribers,[x.pid])    
    return state, Agent.NoTerminate()
end
function dispatch_work(m, x::UnsubscribeMsg, state)
    setdiff!(state.subscribers,[x.pid])
    return state, Agent.NoTerminate()        
end
function dispatch_work(m, event::CallMsg, state)    
    try
        result = m.handle_call(event.value, state.state)                
        fwdToSubscribers(result.fwd, state.subscribers)
        put!(event.from, result.reply)
        return State(result.state, state.subscribers), result.next
    catch(err)
        if  isa(err, UndefVarError)
            println("error dispacth_work call in worker --------> $err")
            return handle_call_default(event.value, state)
        else
            println("error dispacth_work call in worker --------> $err")
            throw(err)
        end
    end
end

function dispatch_work(m, event::CastMsg, state)
    try
        result = m.handle_cast(event.value, state.state)
        
        fwdToSubscribers(result.fwd, state.subscribers)
        return  State(result.state, state.subscribers), result.next
    catch(err)
        if  isa(err, UndefVarError)
            println("error dispacth_work call cast--------> $err")
            return handle_cast_default(event.value, state)
        else
            println("error dispacth_work call cast --------> $err")
            throw(err) 
        end
    end
end

function dispatch_work(m, event, state)
    throw("no found match for $event in worker") 
    return  state, Agent.NoTerminate()   
end

function terminate(m, reason, state)
    try
        m.terminate(reason,state)
        return reason
    catch(err)
        return reason
    end
end


end


