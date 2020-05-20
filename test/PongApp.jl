module PongApp
using Application

using ..PongServer
using ..PongSup

behaviour()=Application

function init(args)
    (mode, ) = args
    if mode == :with_server_only_mode
        (mode, ServerName) = args
        return Application.AppConfig( ServerName
                                      , PongServer
                                      , nothing                        
                                      , 16 )
    end
    if mode == :with_supervisor_mode
        (mode, supName, ServerName) = args
        return Application.AppConfig( supName
                                      , PongSup
                                      , ServerName
                                      , 16 )
    end
    return nothing
end

end
