local EventManager = require 'utils.EventManager';
EventManager.getInstance():addListener("server_respond_000", function(event, cmd, data)
	local sn = data[1]
	ERROR_LOG(sprinttb(data))
end)