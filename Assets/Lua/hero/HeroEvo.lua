local role_evo_Config = nil
local function GetEvoConfig(id)
	if role_evo_Config == nil then
		role_evo_Config = {}
		DATABASE.ForEach("role_evo", function(row)
			role_evo_Config[row.id] = role_evo_Config[row.id] or {}
			role_evo_Config[row.id][row.evo_lev] = row
		end)
	end
	return role_evo_Config[id]
end

local roleAdvCfg = nil
local function GetRoleAdvCfg(id)
    if not roleAdvCfg then
        roleAdvCfg = {}
        DATABASE.ForEach("role_evo", function(row)
            roleAdvCfg[row.id] = roleAdvCfg[row.id] or {}
            local _tab = {}
            _tab.consume = {}
            for i = 1, 4 do
                table.insert(_tab.consume,{type = row["cost0_type"..i], id = row["cost0_id"..i], value = row["cost0_value"..i]})
            end
            _tab.consumeProperty = {}
            for i = 1, 3 do
                if row["effect0_type"..i] ~= 0 and row["effect0_id"..i] ~= 0 then
                    table.insert(_tab.consumeProperty, {type = row["effect0_type"..i], value = row["effect0_value"..i]})
                end
            end
            _tab.littleConsume = {}
            _tab.littleConsumeProperty = {}
            for i = 1, 6 do
                table.insert(_tab.littleConsume, {type = row["cost"..i.."_type"], id = row["cost"..i.."_id"], value = row["cost"..i.."_value"]})
                table.insert(_tab.littleConsumeProperty, {type = row["effect"..i.."_type"], value = row["effect"..i.."_value"]})
            end
			roleAdvCfg[row.id][row.evo_lev] = _tab
		end)
    end
    if id then
        return roleAdvCfg[id]
    end
    return roleAdvCfg
end


local function CaclProperty(hero)
	if GetEvoConfig(hero.id) == nil then
		ERROR_LOG("hero evo config not exist", hero.id);
		return {};
	end

	local HeroValueArr = {}
	for i = 0,hero.stage do
		local NowStageHeroConf = GetEvoConfig(hero.id)[i]
		if NowStageHeroConf then
			if i < hero.stage or hero.stage_slot[1] == 1 then
				HeroValueArr[NowStageHeroConf.effect1_type] = (HeroValueArr[NowStageHeroConf.effect1_type] and HeroValueArr[NowStageHeroConf.effect1_type] or 0) + NowStageHeroConf.effect1_value
			end
			if i < hero.stage or hero.stage_slot[2] == 1 then
				HeroValueArr[NowStageHeroConf.effect2_type] = (HeroValueArr[NowStageHeroConf.effect2_type] and HeroValueArr[NowStageHeroConf.effect2_type] or 0) + NowStageHeroConf.effect2_value
			end
			if i < hero.stage or hero.stage_slot[3] == 1 then
				HeroValueArr[NowStageHeroConf.effect3_type] = (HeroValueArr[NowStageHeroConf.effect3_type] and HeroValueArr[NowStageHeroConf.effect3_type] or 0) + NowStageHeroConf.effect3_value
			end
			if i < hero.stage or hero.stage_slot[4] == 1 then
				HeroValueArr[NowStageHeroConf.effect4_type] = (HeroValueArr[NowStageHeroConf.effect4_type] and HeroValueArr[NowStageHeroConf.effect4_type] or 0) + NowStageHeroConf.effect4_value
			end
			if i < hero.stage or hero.stage_slot[5] == 1 then
				HeroValueArr[NowStageHeroConf.effect5_type] = (HeroValueArr[NowStageHeroConf.effect5_type] and HeroValueArr[NowStageHeroConf.effect5_type] or 0) + NowStageHeroConf.effect5_value
			end
			if i < hero.stage or hero.stage_slot[6] == 1 then
				HeroValueArr[NowStageHeroConf.effect6_type] = (HeroValueArr[NowStageHeroConf.effect6_type] and HeroValueArr[NowStageHeroConf.effect6_type] or 0) + NowStageHeroConf.effect6_value
			end

			if NowStageHeroConf.effect0_value1 then
				HeroValueArr[NowStageHeroConf.effect0_type1] = (HeroValueArr[NowStageHeroConf.effect0_type1] and HeroValueArr[NowStageHeroConf.effect0_type1] or 0) + NowStageHeroConf.effect0_value1
			end
			if NowStageHeroConf.effect0_value2 then
				HeroValueArr[NowStageHeroConf.effect0_type2] = (HeroValueArr[NowStageHeroConf.effect0_type2] and HeroValueArr[NowStageHeroConf.effect0_type2] or 0) + NowStageHeroConf.effect0_value2
			end
			if NowStageHeroConf.effect0_value3 then
				HeroValueArr[NowStageHeroConf.effect0_type3] = (HeroValueArr[NowStageHeroConf.effect0_type3] and HeroValueArr[NowStageHeroConf.effect0_type3] or 0) + NowStageHeroConf.effect0_value3
			end
		end
		-- if HeroValueArr[1501] then
		-- 	print("[1501]->"..HeroValueArr[1501])
		-- end
	end
	return HeroValueArr
	-- return {
	-- 	[1001] = 100,
	-- }
end

return {
	CaclProperty = CaclProperty,
	GetConfig = GetEvoConfig,
    GetRoleAdvCfg = GetRoleAdvCfg,
}
