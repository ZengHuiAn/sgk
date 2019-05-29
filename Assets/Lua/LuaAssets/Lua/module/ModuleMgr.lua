local MapPlayerModule = require "module.ModuleProxy.MapPlayerProxy"

local class = require "utils.class"
local ModuleMgr = class()
function ModuleMgr:_init_()
	self.data = {}
	self.data.MapPlayerModule = MapPlayerModule()
end
function ModuleMgr:get()
	if self.data then
		return self.data
	end
	return nil
end
local _instance = nil;
local function Get()
	if not _instance then
		_instance = ModuleMgr();
	end
	return _instance:get();
end
return {
	Get = Get,
}