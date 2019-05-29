local weapon_evo_Config = nil
local function GetEvoConfig(id)
	if weapon_evo_Config == nil then
		weapon_evo_Config = {}
		DATABASE.ForEach("weapon_evo", function(row)
			weapon_evo_Config[row.id] = weapon_evo_Config[row.id] or {}
			weapon_evo_Config[row.id][row.evo_lev] = row
		end)
	end
	return weapon_evo_Config[id] or {}
end

local hero_Weapon_config = nil
local function GetWeaponConfig(id)
	hero_Weapon_config = hero_Weapon_config or LoadDatabaseWithKey("weapon", "id");
	return hero_Weapon_config[id]
end

local hero_Weapon_lev_config = nil
local function GetWeaponLevConfig(id)
	hero_Weapon_lev_config = hero_Weapon_lev_config or LoadDatabaseWithKey("weapon_lev", "id")
	return hero_Weapon_lev_config[id]
end

local hero_WeaponSkill_config = nil
local function GetWeaponSkillConfig(id)
	hero_WeaponSkill_config = hero_WeaponSkill_config or LoadDatabaseWithKey("skill", "id");
	return hero_WeaponSkill_config[id]
end

local function CaclProperty(hero)
	--print("Weapon->>>>"..hero.id.."!!!"..hero.weapon_stage)
	local HeroValueArr = {}
	local role = module.HeroModule.GetConfig(hero.id);
	local WeaponID = role and role.weapon or 0;

	if not GetEvoConfig(WeaponID) then
		return {}
	end

	if WeaponID then
		--ERROR_LOG(hero.id.."weapon_stage", hero.weapon_stage);
		for i = 0,hero.weapon_stage do
			local NowStageHeroConf = GetEvoConfig(WeaponID)[i]
			if NowStageHeroConf then
				if i < hero.weapon_stage or hero.weapon_stage_slot[1] == 1 then
					HeroValueArr[NowStageHeroConf.effect1_type] = (HeroValueArr[NowStageHeroConf.effect1_type] and HeroValueArr[NowStageHeroConf.effect1_type] or 0) + NowStageHeroConf.effect1_value
				end
				if i < hero.weapon_stage or hero.weapon_stage_slot[2] == 1 then
					HeroValueArr[NowStageHeroConf.effect2_type] = (HeroValueArr[NowStageHeroConf.effect2_type] and HeroValueArr[NowStageHeroConf.effect2_type] or 0) + NowStageHeroConf.effect2_value
				end
				if i < hero.weapon_stage or hero.weapon_stage_slot[3] == 1 then
					HeroValueArr[NowStageHeroConf.effect3_type] = (HeroValueArr[NowStageHeroConf.effect3_type] and HeroValueArr[NowStageHeroConf.effect3_type] or 0) + NowStageHeroConf.effect3_value
				end
				if i < hero.weapon_stage or hero.weapon_stage_slot[4] == 1 then
					HeroValueArr[NowStageHeroConf.effect4_type] = (HeroValueArr[NowStageHeroConf.effect4_type] and HeroValueArr[NowStageHeroConf.effect4_type] or 0) + NowStageHeroConf.effect4_value
				end
				if i < hero.weapon_stage or hero.weapon_stage_slot[5] == 1 then
					HeroValueArr[NowStageHeroConf.effect5_type] = (HeroValueArr[NowStageHeroConf.effect5_type] and HeroValueArr[NowStageHeroConf.effect5_type] or 0) + NowStageHeroConf.effect5_value
				end
				if i < hero.weapon_stage or hero.weapon_stage_slot[6] == 1 then
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
			--ERROR_LOG(i.."->"..sprinttb(HeroValueArr))
			-- if HeroValueArr[1501] then
			-- 	print("[1501]->"..HeroValueArr[1501])
			-- end
		end

		 return HeroValueArr
		-- return {
		-- 	[1001] = 100,
		-- }
	end
end

return {
	CaclProperty = CaclProperty,
	GetConfig = GetEvoConfig,
	GetWeaponConfig = GetWeaponConfig,
	GetWeaponSkillConfig = GetWeaponSkillConfig,
	GetWeaponLevConfig = GetWeaponLevConfig,
}
