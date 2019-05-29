local ItemModule = require "module.ItemModule"
local CommonConfig = require "config.commonConfig"


local lvlupConfig = nil;
local function LoadLevelupConfig()
	if lvlupConfig == nil then
		lvlupConfig = {};		
		DATABASE.ForEach("role_lev", function(row)
			local property = {};
			for i=0,6 do
				local pk, pv = row["type" .. i], row["value" .. i];
				property[i + 1] = {};
				property[i + 1].key = pk;
				property[i + 1].value = pv;
			end
			lvlupConfig[row.id] = property;
		end)
	end
	return lvlupConfig;
end

local function getProperty(id,level)
	if lvlupConfig == nil then
		LoadLevelupConfig();
	end

	if not lvlupConfig[id] then
		return {};
	end

	local property = {};
	for k,v in ipairs(lvlupConfig[id]) do
		if v.key ~= 0 and v.value ~= 0 then
			property[v.key] = v.value * level;
		end
	end
	return property;
end

local expConfig = nil;
local function getExpConfig(t, hero)
	t = t or 1;
	if expConfig == nil then
		expConfig = {};
		DATABASE.ForEach("level_up", function(row)
			local type = row.column;
			expConfig[type] = expConfig[type] or { values = {}, cost = {} };
			

			local level = row.level;
			local exp   = row.value;

			expConfig[type].values[level] = exp;
			expConfig[type].cost[level] = { {type=row.type, id=row.id,value=row.value} }
		end)
	end	
	if t == 1 and hero then
		return setmetatable({}, {
			__index = function ( _,k )
				return expConfig[t].values[k] and expConfig[t].values[k] * (hero.exp_rate or 10000) / 10000
			end
		})
	end
	return expConfig[t].values;
end

local levelup_goto_config = nil;
local function GetLevelupGoto()
	if levelup_goto_config == nil then
		levelup_goto_config = {};
		DATABASE.ForEach("levelup_goto", function(row)
			local type = row.type;
			if levelup_goto_config[type] == nil then
				levelup_goto_config[type] = {};
			end
			table.insert(levelup_goto_config[type], row);
		end)
    end
	return levelup_goto_config;
end

local function CaclProperty(hero)
	return getProperty(hero.id, hero.level);
end

local function CanOperate(hero, master_level)
	local exp_value = {1000,5000,25000,100000};
	local expbookID = {90401,90402,90403,90404};
	local limit = master_level;
	if hero.level >= limit then
		return false;
	else
		local need_exp = getExpConfig(1, hero)[hero.level + 1] - hero.exp;
		local all_exp = 0;
		for i=1,4 do
			all_exp = all_exp + ItemModule.GetItemCount(expbookID[i]) * exp_value[i]
		end
		if all_exp >= need_exp then
			return true;
		else
			return false;
		end
	end
end

return {
	Load = LoadLevelupConfig,
	GetExpConfig = getExpConfig,
	CaclProperty = CaclProperty,
	CanOperate = CanOperate,
	GetLevelupGoto = GetLevelupGoto,
	GetProperty = getProperty,
}
