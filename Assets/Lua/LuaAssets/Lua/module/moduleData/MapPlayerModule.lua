local class = require "utils.class"
local MapPlayerModule = class()
function MapPlayerModule:_init_(data)
	self.pid = data.pid
	self.character = data.character
	-- self.teamid = data.teamid or 0
	-- self.teamLeaderid = data.teamLeaderid or 0
end
return MapPlayerModule