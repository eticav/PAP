module PongServer
using Worker

struct Ping
    Ping()=new()
end

struct Pong
    Pong()=new()
end

struct Count end

behaviour()=Worker

function init(args)
    println("----------- PONG SRV------------------------------------")
    return 0
end

function handle_call(event::Ping, acc)    
    return Worker.reply(Pong(), Pong(), acc+1)
end
function handle_call(event::Pong, acc)    
    return Worker.reply(Ping(), Ping(), acc+1)
end
function handle_call(event::Count, acc)    
    return Worker.reply(acc, acc)
end

function handle_cast(event::Ping, acc)    
    return Worker.fwd(Pong(), acc+1)
end
function handle_cast(event::Pong, acc)    
    return Worker.fwd(Ping(), acc+1)
end
function handle_cast(event, acc)    
    return Worker.fwd(nothing, acc)
end

end
