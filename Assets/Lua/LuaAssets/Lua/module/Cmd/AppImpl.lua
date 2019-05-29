local NetworkService = require "utils.NetworkService"
local AppInterface = {}
function AppInterface.test(data)
	NetworkService.Send(000);
end
return AppInterface