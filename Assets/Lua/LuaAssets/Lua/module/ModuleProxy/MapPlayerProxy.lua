local MapPlayerModule = require "module.moduleData.MapPlayerModule"
local class = require "utils.class"
local MapPlayerProxy = class()
function MapPlayerProxy:_init_()
	self.data = {}
	self.sn = {}
end

function MapPlayerProxy:Reset()
	self.data = {}
end

function MapPlayerProxy:GetData()
	return self.data
end

function MapPlayerProxy:AddOrUpdateDatas(data)
	if data then
		for i = 1,#data do
			self:AddOrUpdateSimpleData(data[i])
		end
	end
end

function MapPlayerProxy:AddOrUpdateSimpleData(data)
	self.data[data.pid] = MapPlayerModule(data)
end

function MapPlayerProxy:test()
	ERROR_LOG(sprinttb(self.data))
end
function MapPlayerProxy:Remove(pid)
	--ERROR_LOG("Remove",debug.traceback())
	self.data[pid] = nil
end
return MapPlayerProxy