local peropertyParameterConfig = nil;
local function merge_showType(t, a, b)
	if t then
		if tonumber(t.showType) then
            t.showType = tonumber(t.showType)
        end
	end
	return t;
end
local function GetPeropertyParameterConfig(id)
	if peropertyParameterConfig == nil then
        peropertyParameterConfig = {raw = LoadDatabaseWithKey("parameter", "id")}
        setmetatable(peropertyParameterConfig, {__index = function(t, k)
            local _cfg = t.raw[k]
            if _cfg then
                rawset(t, k, merge_showType(_cfg))
            end
            return _cfg
        end})
	end
	return peropertyParameterConfig[tostring(id)];
end

local peropertyShowConfig = nil;
local function GetHeroPeropertyConfig(id)
	if peropertyShowConfig == nil then
		peropertyShowConfig= LoadDatabaseWithKey("role_property", "id");
	end
	return peropertyShowConfig[id];
end

local function GetPeropertyShowValue(key,value)
	local cfg=GetPeropertyParameterConfig(key)
	local _showValue
	if cfg then
		if cfg.rate == 1 or cfg.rate == -1 then
			_showValue = math.floor(value/cfg.rate)
		elseif cfg.rate == 10000 or cfg.rate == -10000 then
			if type(key)=="string" then
				_showValue = string.format("%s%%",math.floor(value*100))
			else
				if math.abs(math.floor(value*100/cfg.rate)) < math.abs(math.floor(value)*100/cfg.rate) then
					_showValue = string.format("%s%%",math.floor(value)*100/cfg.rate)
				else
					_showValue = string.format("%s%%",math.floor(value*100/cfg.rate))
				end
			end
		end
	end
	return _showValue
end


return {
    Get = GetPeropertyParameterConfig,
  	GetHeroPeropertyCfg=GetHeroPeropertyConfig,
  	GetPeropertyShowValue=GetPeropertyShowValue,
}
