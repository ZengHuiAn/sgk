local HeroLevelup = require "hero.HeroLevelup"
local View={}

function View:Start()
	self.view = SGK.UIReference.Setup(self.gameObject);
end

local function loadStarDesc(key, value1, value2)
    local _value1 = value1
    local _value2 = value2
    if key == 6 then    ---技能
        if value1 ~= 0 then
            _value1 = module.fightModule.GetDecCfgType(tonumber(value1))
        end
    elseif key == 7 or key == 8 then ---怪物
        if value1 ~= 0 then
            _value1 = battle_config.LoadNPC(_value1).name
        end
        if key ~= 8 then
            if value2 ~= 0 then
                _value2 = battle_config.LoadNPC(value2).name
            end
        end
    end
    return string.format(module.fightModule.GetStarDec(key) or "星星条件 " .. tostring(key)  .. " 不存在", _value1, _value2)
end



local function GetExpInfo(hero)
	local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
	local Level_exp = hero_level_up_config[hero.level]
	local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1] or hero_level_up_config[hero.level]
	local ExpDesc = hero and (hero.exp - Level_exp) .."/".. (Next_hero_level_up - Level_exp) or "0/0"
	return hero_level_up_config,Level_exp,Next_hero_level_up,ExpDesc
end

-- local function UpdateCharacterIcon(slot,hero,v)
-- 	slot:SetActive(true);
-- 	local icon = slot.scaler.CharacterIcon[SGK.CharacterIcon]
-- 	icon.icon = hero.icon
-- 	icon.level = v.role.level
-- 	icon.stage = hero.role_stage
-- 	icon.star = v.role.grow_star
-- 	return icon
-- end

local function UpdateCharacterIcon(slot,hero)
	slot:SetActive(true);
	local icon = slot.scaler.CharacterIcon[SGK.CharacterIcon]
	icon.icon = hero.mode
	icon.level = hero.level
	icon.stage = hero.role_stage
	icon.star = hero.grow_star
	return icon
end

local function GetHeroList(manager,partners)
	local list = {};
	if not partners or next(partners)==nil then
		ERROR_LOG(" partners is nil or {}")
		return
	end
	--[[
		for _, v in pairs(partners) do
			local hero = manager:Get(v.role.id)
			if hero and hero.uuid ~= v.role.server_uuid then
				return;
			end

			if v.role.pos < 100 then
				table.insert(list, v);
			end
		end

		table.sort(list, function(a,b)
			return a.role.pos < b.role.pos;
		end)
	--]]
	---[[--临时版本
	for _, v in pairs(partners) do
		local hero = manager:Get(v.id)
		if v.pos < 100 then
			table.insert(list, setmetatable({pos =v.pos},{__index = hero}));
		end
	end
	table.sort(list, function(a,b)
		return a.pos < b.pos;
	end)
	--]]


	return list
end

function View:Init(data)
	local starStatus = data[1]
	local starInfo = data[2]
	local rewards = data[3]
	local partners = data[4]
	local HeroExpInfoList = data[5]

    for _, v in ipairs(self.saved_rewards or {}) do
        if v[1] == 90 and v[2] == 90000 or v[2] == 90001 then
            have_exp = true;
            break;
        end
    end
    if starStatus and starInfo then
	    self:updateStarShow(starStatus,starInfo)
	end
	if rewards and partners and HeroExpInfoList then
	    self:updatePartnersShow(rewards,partners,HeroExpInfoList)
	end
end

function View:updateStarShow(starStatus,starInfo)
	local Stars = self.view.top.starsConditions.Stars
	local Conditions = self.view.top.starsConditions.conditions

	Stars[1].Image:SetActive(true)
	Conditions[1].Text[UI.Text]:TextFormat("战斗胜利");
	Conditions[1].Image[CS.UGUISelector].index = starStatus[1] and 1 or 0;
	Conditions[1].bg:SetActive(true)
	Conditions[1].bgFail:SetActive(false)

	for k,v in pairs(starInfo) do
		Stars[k+1].Image:SetActive(starStatus[k+1])
		Conditions[k+1].Image[CS.UGUISelector].index = starStatus[k+1] and 1 or 0;
		Conditions[k+1].Text[UI.Text]:TextFormat("{0}", loadStarDesc(v.type, v.v1, v.v2));
		Conditions[k+1].Text[UI.Text].color = starStatus[k+1] and {r = 0, g = 0, b = 0, a = 128/255} or UnityEngine.Color.black
		Conditions[k+1].bg:SetActive(starStatus[1])
		Conditions[k+1].bgFail:SetActive(not starStatus[1])
	end
end

local function playLvUpEffect(parent)
	local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_icon_up.prefab");
	local o = prefab and UnityEngine.GameObject.Instantiate(prefab,parent.gameObject.transform);
	local _durtion=0
	if o then
		o.transform.localPosition =Vector3(0,-60,0);
		o.transform.localScale = Vector3.one
		o.transform.localRotation = Quaternion.identity;
		local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
		_obj:Play()
		_durtion = _obj.main.duration
		UnityEngine.Object.Destroy(o, _obj.main.duration)
	end
	return _durtion
end

function View:updatePartnersShow(rewards,partners,HeroExpInfoList)
	local have_exp = false
	for _,v in pairs(rewards or {}) do
		if v[1] == 90 and v[2] == 90000 or v[2] == 90001 then
			have_exp = true;
			break;
		end
	end
	if have_exp then
		local Slots = self.view.mid.Slots
		Slots:SetActive(true);

		-- hero list
		local manager = module.HeroModule.GetManager()
		local list = GetHeroList(manager,partners)
		for k, v in ipairs(list) do
			local hero = v--manager:Get(v.id)--manager:GetByUuid(v.role.server_uuid)
			if hero then
				local slot = Slots[k];
				if slot then
					--local icon = UpdateCharacterIcon(slot,hero,v)
					local icon = UpdateCharacterIcon(slot,v)
                    local hero_level_up_config,Level_exp,Next_hero_level_up,ExpDesc = GetExpInfo(hero)

					if HeroExpInfoList and HeroExpInfoList[hero.id] then
						local old_Exp = HeroExpInfoList[hero.id]
						local get_Exp = hero.exp-old_Exp or 0
						local level_AddExp = hero.exp - Level_exp
						if level_AddExp<get_Exp then
							--ERROR_LOG("升级了")
							icon.level = hero.level -1
							local Last_hero_level_up = hero_level_up_config[hero.level-1] and hero_level_up_config[hero.level-1] or hero_level_up_config[hero.level]
							slot.Exp[UnityEngine.UI.Image].fillAmount = (old_Exp- Last_hero_level_up) / (Level_exp-Last_hero_level_up);
							self.view.transform:DOScale(Vector3.one,1.5):OnComplete(function()
								slot.Exp[UnityEngine.UI.Image]:DOFillAmount(1,0.5):OnComplete(function ( ... )
								--print("特效")
									local _durtion = playLvUpEffect(slot.scaler)
									icon.level = hero.level--v.role.level+1
									self.view.transform:DOScale(Vector3.one,_durtion):OnComplete(function()
										slot.Exp[UnityEngine.UI.Image].fillAmount=0
										slot.Exp[UnityEngine.UI.Image]:DOFillAmount((hero.exp - Level_exp) / (Next_hero_level_up - Level_exp),0.5):OnComplete(function ( ... )
											slot.ExpValue[UnityEngine.UI.Text].text = hero and string.format("+%s",math.ceil(get_Exp)) or "";
										end)
									end)
								end)
							end)
						else
							slot.Exp[UnityEngine.UI.Image].fillAmount = (old_Exp- Level_exp) / (Next_hero_level_up - Level_exp);
							self.view.transform:DOScale(Vector3.one,2):OnComplete(function()
								slot.Exp[UnityEngine.UI.Image]:DOFillAmount((hero.exp - Level_exp) / (Next_hero_level_up - Level_exp),0.5):OnComplete(function ( ... )
									slot.ExpValue[UnityEngine.UI.Text].text = hero and string.format("+%s",math.ceil(get_Exp)) or "";
								end)
							end)
						end
					else
						slot.Exp[UnityEngine.UI.Image].fillAmount = (hero.exp - Level_exp) / (Next_hero_level_up - Level_exp);
						slot.ExpValue[UnityEngine.UI.Text].text = ""
					end
				end
			end
		end
	end
end

function View:listEvent()
	return {
		""
	}
end

function View:onEvent(event)
	if event == "" then
	
	end
end

return View;
