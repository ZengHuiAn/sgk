local weaponConfig = nil;
local function LoadWeaponConfig()
	if weaponConfig == nil then
		weaponConfig = {};
		
		DATABASE.ForEach("weapon", function(row)
			local property = {};
			for j=0,6 do
				local pk, pv = row["type" .. j], row["value" .. j]
				property[pk] = pv;
			end
			weaponConfig[row.id] = {};
			weaponConfig[row.id].cfg = row;
			weaponConfig[row.id].property = property;
		end)
	end
	return weaponConfig;
end


local lvlupConfig = nil;
local function LoadLevelupConfig()
	if lvlupConfig == nil then
		lvlupConfig = {};
		DATABASE.ForEach("weapon_lev", function(row)
			local property = {};
			for i=0,6 do
				local pk, pv = row["type" .. i], row["value" .. i]
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
		return {}
	end

	local property = {};
	for k,v in pairs(lvlupConfig[id]) do
		if k ~= 0 and v ~= 0 then
			property[v.key] = v.value * level;
		end
	end

	local Config = LoadWeaponConfig();
	if Config and Config[id] then
		for k,v in pairs(Config[id].property) do
			if k ~= 0 and v ~= 0 then
				property[k] = (property[k] or 0) + v;
			end
		end
	end

	return property;
end


local function CaclProperty(hero)

	return getProperty(hero.weapon_id, hero.weapon_level);
end


return {
	Load = LoadLevelupConfig,
	CaclProperty = CaclProperty,
	LoadWeapon = LoadWeaponConfig,
}