local ScrollConfig = nil
local function GetScrollConfig(id)
	ScrollConfig = ScrollConfig or LoadDatabaseWithKey("scroll", "scroll") or {}

	return ScrollConfig[id]
end

local SuitConfig = nil
local function GetSuitConfig(id)
	if SuitConfig == nil then
		SuitConfig = {}
		DATABASE.ForEach("suit", function(row)
			SuitConfig[row.suit_id] = SuitConfig[row.suit_id] or {}
			SuitConfig[row.suit_id][row.count] = SuitConfig[row.suit_id][row.count] or {}
			SuitConfig[row.suit_id][row.count][row.quality] = SuitConfig[row.suit_id][row.count][row.quality] or {}
			SuitConfig[row.suit_id][row.count][row.quality] = row
		end)
	end
	if id then
		return SuitConfig[id]
	else
		return SuitConfig
	end
end

local suitCfg = nil
local function GetSuitCfg(id)
	if suitCfg == nil then
		suitCfg = {}
		DATABASE.ForEach("suit", function(row)
			suitCfg[row.suit_id] = suitCfg[row.suit_id] or {
										suit_id = row.suit_id,
										icon    = row.icon,
										name    = row.name,
										quality = row.quality,
										class   = row.class,
									} 
			suitCfg[row.suit_id].effect = suitCfg[row.suit_id].effect or {}
			suitCfg[row.suit_id].effect[row.count] = suitCfg[row.suit_id].effect[row.count] or {
														count  = row.count,
														type1  = row.type1,
														value1 = row.value1,
														type2  = row.type2,
														value2 = row.value2,
														desc = row.desc}
		end)
	end
	if id then
		return suitCfg[id]
	else
		return suitCfg
	end
end

local suitsList = nil
local function GetSuitsList()
	if not suitsList then
		suitsList = {}
		local _suitsList = GetSuitConfig()
		for k,v in pairs(_suitsList) do
			local _quality = 0
			local _icon = "zd_icon_13"
			local _name = "未知套装"
			if v[2] and next(v[2]) then
				for _k,_v in pairs(v[2]) do
					if _k >= _quality then
						_quality = _k
						_icon = _v.icon
						_name = _v.name
					end
				end
			else
				ERROR_LOG("suitCfgTab[2] is nil,suitId",k)
			end
			table.insert(suitsList,{suit_id = k,quality = _quality,name = _name,icon = _icon})
		end

		table.sort(suitsList,function (a,b)
			if a.quality ~= b.quality then
				return a.quality > b.quality
			end
			return a.suit_id < b.suit_id
		end)
	end
	return suitsList
end

return {
	GetSuitConfig = GetSuitConfig,
	GetScrollConfig = GetScrollConfig,

	GetSuitsList = GetSuitsList,
	GetSuitCfg = GetSuitCfg,

}