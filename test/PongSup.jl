module PongSup
using Supervisor

using ..PongServer

behaviour() = Supervisor

function init(args)
    name = args
    return [Supervisor.ChildSpec(name, PongServer, nothing, 10)]
end

end
