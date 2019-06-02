local RAND = RAND or math.random
local print = function( ... )
	print( ... )
end

--选择目标
function Common_ShowErrorInfo(attacker, id , manual)
	-- print("                                     ", attacker, id , manual)
	if attacker.side == 1 then
		if manual and manual ~= "simple" then
			ShowErrorInfo(id)
		end
	end
end

--读表播放攻击动作
function Common_UnitPlayAttack(attacker, id)
	local sleep_time = 0.3

	local cfg = GetSkillEffectCfg(id)
	if not cfg then return end

	if cfg.attack_time < 0  then
		Common_Sleep(attacker, 0)
		return
	else
		sleep_time = cfg.attack_time
	end

	UnitPlay(attacker, "attack1", {speed = 1});
	Common_Sleep(attacker, sleep_time)
end

function Common_Skill_Check(attacker, skill, manual)
	if manual == "simple" or manual == "SingSkill" then
		return true
	end

	if attacker[7003] > 0 and skill[8001] > 0 then
		Common_ShowErrorInfo(attacker, 5, manual)
		return false
	end

	--[[
	if skill.current_cd > 0 then
		Common_ShowErrorInfo(attacker, 1, manual)
		return false
	end
	--]]

	if attacker.ep < skill.skill_consume_ep then
		Common_ShowErrorInfo(attacker, 2, manual)
		return false
	end

	if skill and skill.cfg.property_list[30021] then
		local consume_hp = attacker.hpp * skill.cfg.property_list[30021] / 10000 
		if attacker.hp <= consume_hp then
			Common_ShowErrorInfo(attacker, 3, manual)
			return false
		end
	end

	return true
end

--返回可被单体技能选为目标的所有目标
function Target_list(_attacker, enemies, type, skill, count)
	local attacker =  _attacker or attacker
	local enemies = enemies or FindAllEnemy()
	local count = count or 1

	if attacker.order_target ~= 0 then
		return {attacker.order_target}
	end

	local function seek_rank(role)
		local v = role[7013]
		if skill and skill.cfg.property_list[7013] then
			v = v + skill.cfg.property_list[7013]
		end

		return v
	end

	local chaofeng_list = {}
	local normal_list = {}
	local yinshen_list = {}
	local high_chaofeng_list = {}

	local type = type or "normal"

	local all_targets = {}
	for _, role in ipairs(enemies) do
		if role.hp > 0 then
			local def_1 = {}
			local def_0 = {}
			local def__ = {}

			for _, pet in ipairs(UnitPetList(role)) do		
				if pet.def_order == 0 then
					table.insert(def_0, pet)
				elseif pet.def_order > 0 then
					table.insert(def_1, pet)
				else
					table.insert(def__, pet)
				end
			end

			if #def_1 > 0 then
				for _ , v in ipairs(def_1) do
					table.insert(all_targets, v)
				end
			elseif #def_0 > 0 then
				for _ , v in ipairs(def_0) do
					table.insert(all_targets, v)
				end
				table.insert(all_targets, role)
			else
				table.insert(all_targets, role)
			end
		end
	end

	for _, v in ipairs(all_targets) do
		if v[7000] >= 10 then
			table.insert(high_chaofeng_list, v)
		end

		if v[7000] > seek_rank(attacker) and type ~= "fanchaofeng" then
			table.insert(chaofeng_list, v)
		elseif v[7000] < 0 and type ~= "fanyin" then
			table.insert(yinshen_list, v)
		else
			table.insert(normal_list, v)
		end
	end
	
	local choose_list = {}
	if #high_chaofeng_list > 0 then
		choose_list = high_chaofeng_list
	elseif type == "not_chaofeng" then
		choose_list = normal_list
	elseif #chaofeng_list > 0 then
		choose_list = chaofeng_list
	else
		choose_list = normal_list
	end
	
	return choose_list
	
end

function CalcAllShield(target)
	local buff_list = {}
	local buffs = UnitBuffList(target)
	local total_shield = 0
	for _, v in ipairs(buffs) do
		if v.script_id == 93 then
			total_shield = total_shield + v[7096]
		end
	end
	target[7095] = total_shield
end

--返回被aoe技能攻击到的所有目标
function All_target_list(enemies, skill_see_id)
	local enemies = enemies or FindAllEnemy();
	local all_targets = {}
	local high_chaofeng_list = {}

	for _, role in ipairs(enemies) do
		if role.hp > 0 then
			if role[7000] >= 10 then
				table.insert(high_chaofeng_list, role)
			end

			table.insert(all_targets, role)
			for _, pet in ipairs(UnitPetList(role)) do		
				table.insert(all_targets, pet)
			end
		end
	end

	if #high_chaofeng_list > 0 then
		return high_chaofeng_list
	end

	return all_targets
end

--护盾计算
function Shield_calc(buff, bullet)
	if bullet.hurt_disabled == 1 then
		return
	end

	local target = buff.target

	if buff[7096] > 0 then
		if buff[7096] > (bullet.ShieldHurt + bullet.hurt_final_value) then
			buff[7096] = buff[7096] - bullet.ShieldHurt - bullet.hurt_final_value;	
			if math.floor(bullet.ShieldHurt + bullet.hurt_final_value) ~= 0 then
				UnitShowNumber(bullet.target, math.floor(bullet.ShieldHurt + bullet.hurt_final_value), 3, "吸收")
			end
			bullet.ShieldHurt = 0
			bullet.hurt_final_value = 0
		else	
			if math.floor(buff[7096]) ~= 0 then
				UnitShowNumber(bullet.target, math.floor(buff[7096]), 3, "吸收")
			end
			buff[7096] = 0
			UnitRemoveBuff(buff)

			if bullet.ShieldHurt >= buff[7096] then
				bullet.ShieldHurt = bullet.ShieldHurt - buff[7096]
			else
				bullet.hurt_final_value = bullet.hurt_final_value - (buff[7096] - bullet.ShieldHurt)
			end
		end
	else
		UnitRemoveBuff(buff)
	end

	CalcAllShield(target)
end

--[[
	宠物选择目标
]]
function Pet_targets()
    local partners = FindAllPartner()
	local allTargets = Target_list(attacker)

	return allTargets or {}
end

local script_data = nil

function Add_Halo_Buff(target, id, _round, content, icon)
	script_data = script_data or GetBattleData()
	script_data.Halo_Buff_List = script_data.Halo_Buff_List or {}
	local buff = Common_UnitAddBuff(attacker, target, id, _round, content, icon)
	table.insert(script_data.Halo_Buff_List , buff)
	return buff
end

function Set_Current_Halo(skill ,value)
	script_data = script_data or GetBattleData()

	if not script_data.current_Halo and not skill then
		return
	end
	
	script_data.current_Halo = nil
	if script_data.Halo_Buff_List then
		for k ,v in pairs(script_data.Halo_Buff_List) do
			UnitRemoveBuff(v)
		end
	end
	script_data.Halo_Buff_List = nil

	if skill then
		ShowBattleHalo(skill)
		script_data.current_Halo = {
			id = skill.id,
			side = skill.owner.side,
			value = value or 5000,
			icon = skill.icon,
			element = skill.skill_element
		}
	else
		ShowBattleHalo()
	end
end
--[[
光环对抗
传入 value_id ，表示光环成功率加成的属性id ,默认0
对抗失败时，返还 1 ，并移除原有得光环
队友的光环必定对抗成功
]]
--[[
function Halo_confrontation(attacker, skill, value)

	script_data = script_data or GetBattleData()
	if not script_data.current_Halo then
		Set_Current_Halo(skill, value)
		return 0
	end
	if script_data.current_Halo and script_data.current_Halo.side == attacker.side then
		Set_Current_Halo(skill, value)
		return 0
	end

	if script_data.current_Halo.value == "max" then
		Common_AddStageEffect("UI/fx_ghj_lost", {duration = 3, scale= 1, rotation = 0, offset = {0.42, 0, 0}, Halo_icon = {skill.icon, script_data.current_Halo.icon}});
		Common_Sleep(attacker, 2)
		return 1
	end

	if RAND(1, script_data.current_Halo.value + value) <= value then
		Common_AddStageEffect("UI/fx_ghj_win", {duration = 3, scale= 1, rotation = 0, offset = {0.42, 0, 0}, Halo_icon = {skill.icon, script_data.current_Halo.icon}});
		Common_Sleep(attacker, 2)
		Set_Current_Halo(skill, value)
		return 0
	end

	Common_AddStageEffect("UI/fx_ghj_lost", {duration = 3, scale= 1, rotation = 0, offset = {0.42, 0, 0}, Halo_icon = {skill.icon, script_data.current_Halo.icon}});
	Common_Sleep(attacker, 2)
	return 1
end
]]

--移除某个id的buff若干次
function RepeatReomveBuff(target, buff_id, change_num)
	local buffs = UnitBuffList(target)
	local remove_count = 0
	if change_num > 0 then
		for k, v in ipairs(buffs) do
			if v.id == buff_id  then
				UnitRemoveBuff(v)
				change_num = change_num - 1
				remove_count = remove_count + 1
				if change_num == 0 then
					break
				end
			end
		end	
	end
	return remove_count
end 

local function NewLine(str, len)
    local final_str = ""
    for i = 1, math.ceil(#str / 3 / len) do
        local offset = (i - 1) * len * 3
        local sub_str = string.sub(str ,offset + 1 , offset + 3 * len)
        final_str = final_str .. sub_str .. "\n"
    end
    return final_str
end

function Show_Dialogue(target, text, duration, effect, pass_random, cfg)	
	local pass_random = pass_random or 0.3
	local cfg = cfg or {offset = {0, -1, 0}, scale = 0.8}

	if target.side == 1 then
		cfg.scale = 0.2
	end

	if RAND(1,100) <= pass_random * 100 then
		text = NewLine(text, 9)
		ShowDialog(target, text, duration, effect, cfg)
	end	
end

function common_enter(attacker)
	attacker.BuffID_99999 = Common_UnitAddBuff(attacker, attacker, 99999)
	attacker.BuffID_99998 = Common_UnitAddBuff(attacker, attacker, 99998)
	attacker.BuffID_99997 = Common_UnitAddBuff(attacker, attacker, 99997)
	attacker.BuffID_99995 = Common_UnitAddBuff(attacker, attacker, 99995)

	Common_UnitAddBuff(attacker, attacker, attacker.mode)

	for k, v in pairs(attacker.property_keys) do
		-- print("________________________________2",attacker.name, attacker.id, k, v)
		if v > 0 then
			if k >= 4000000 and k < 5000000 then
				--其他系统
				Common_UnitAddBuff(attacker, attacker, k)
			elseif k >= 5000000 and k < 6000000 then
				--战场交互
				Common_UnitAddBuff(attacker, attacker, k)
			elseif k >= 3000000 and k < 4000000 then
				--被动
				Common_UnitAddBuff(attacker, attacker, k)
			elseif k >= 1200000 and k < 1300000 then
				--套装
				Common_UnitAddBuff(attacker, attacker, k)
			end
		end
	end

	Common_ChangeEp(attacker, 0)
end

function Common_AddStageEffect(id, index, duration, role, pet_id, cfg)
	AddStageEffect(id, index, duration, role, pet_id, cfg)
end

function Common_UnitAddEffect(role, effect_name, cfg)
	local cfg = cfg or {}
	cfg.scale = cfg.scale or 1

	if role.side == 1 then
		cfg.scale =  cfg.scale * 1
	else
		cfg.scale =  cfg.scale * 1.6
	end

	UnitAddEffect(role, effect_name, cfg)
end

local function removeSingBuff(target)
	local buffs = UnitBuffList(target)
	for k, v in ipairs(buffs) do
		if v.script_id == 95 and v.Is_Break == 1 then
			UnitRemoveBuff(v)
			break
		end
	end
end

--[[
	处理韧性相关的状态包含：眩晕、沉默的控制效果，流血、灼烧等数值效果
]]
local _debuff_list = {
	[7000] = {},
	[7001] = {resist_id = 7201},
	[7002] = {resist_id = 7202},
	[7003] = {resist_id = 7203},
	[7004] = {resist_id = 7204},
	[7005] = {resist_id = 7205},
	[7006] = {resist_id = 7206},
	[7007] = {resist_id = 7207},
	[7008] = {resist_id = 7208},
	[7009] = {resist_id = 7209},
	[7010] = {resist_id = 7210},
	[7011] = {resist_id = 7211},
	[7012] = {},
	[7013] = {},
	[7097] = {},
	[7098] = {},
	[7099] = {},
}

local shield_calc = {
    [1] = function (v, ad, hpp, target)
        return ad * v / 10000
    end,
	[2] = function (v, ad, hpp, target)
        return hpp * v / 10000
    end,
	[3] = function (v, ad, hpp, target)
        return target.hpp * v /10000
    end,
} 

function Common_UnitAddBuff(attacker, target, id, debuff_value, content)
	if target == nil then
		return
	end

	if debuff_value and not _debuff_list[id] then
		if debuff_value ~= 1 and RAND(1, 10000) > debuff_value * 10000 then
			return false
		end
	end

	local cfg = LoadBuffCfg(id)

	content = content or {}
	content.attacker = content.attacker or attacker

	if cfg and cfg.script_id == 93 then
		content.shield = content.shield or 0
		for i = 1,3,1 do
			local k = cfg["parameter_"..i]
			if shield_calc[k] then
				local v = cfg["value_"..i]
				if v == 0 and content.parameter_99 then
					v = content.parameter_99.v
				end

				local shield_up = shield_calc[k](v, attacker.ad, attacker.hpp, target)

				local final_shield_up = shield_up * (1 + attacker.shieldPromote)

				if attacker[300155] > 0 and target.hp/target.hpp <= 0.6 then
					final_shield_up = final_shield_up + shield_up * attacker[300155]/10000
				end

				if attacker[300157] > 0 and target.hp/target.hpp <= 0.4 then
					final_shield_up = final_shield_up + shield_up * attacker[300157]/10000
				end

				content.shield = content.shield + final_shield_up
			end
		end
	end

	if content.shield and content.shield ~= 0 then
		content.shield = content.shield * (1 + attacker.bless) 
		if content.shield_name then
			UnitShowNumber(target, math.floor(content.shield), 1, content.shield_name)
		end
	end

	if content.shield then
		local buffs = UnitBuffList(target)
		for i, v in ipairs(buffs) do
			if v.id == id then
				v[7096] = content.shield or 0
			end
		end
	end

	local round = content.round or - 1
	if cfg then
		round = content.round or cfg.round
		content.isDebuff = content.isDebuff or cfg.isDebuff
		content.isRemove = content.isRemove or cfg.isRemove
		if content.isDebuff == 3 and target.Aciton_Sing == 1 then
			removeSingBuff(target)
		end

		if cfg.type >= 2 then
			local buffs = UnitBuffList(target)
			for i, v in ipairs(buffs) do
				if v.id == id then
					if cfg.type == 2 then 
						v.remaining_round = round 
						v[7096] = v[7096] + (content.shield or 0)
						return v 
					end
					if cfg.type == 3 then v.remaining_round = round end
					if cfg.type == 4 then v[7096] = v[7096] + (content.shield or 0) return v end
				end
			end
		end
	end

	if cfg and _debuff_list[id] then
		local debuff_type = id
		local debuff_value = debuff_value or 1
		local returnPer = debuff_value * (1 - target.tenacity)

		if _debuff_list[id].resist_id and target[_debuff_list[id].resist_id] > 0 then
			UnitShowNumber(target, "", 3, "抵抗")
			return false
		end

		if RAND(1, 10000) <= returnPer * 10000 then
			--移除蓄力
			if debuff_type == 7008 or debuff_type == 7009 then
				local buffs = UnitBuffList(target)	
				for _, v  in ipairs(buffs) do
					if v.Is_Break == 1 then
						UnitRemoveBuff(v)
					end
				end		
			end
		else
			-- UnitShowNumber(target, "", 3, "抵抗")
			return false
		end

		if _debuff_list[id].cfg then
			for k, v in pairs(_debuff_list[id].cfg) do
				content[k] = v
			end
		end

	end

	if content.effect then
		if target.side == 1 then
			content.effect_scale = 0.6
		else
			content.effect_scale = 1
		end
	end 

	local shield = content.shield or 0
	content.shield = nil;

	if target.buff_reflect > 0 
		and content.isRemove == 1 
		and (content.isDebuff == 1 or content.isDebuff == 3)
		and RAND(1,10000) <= target.buff_reflect 
	then
		local partners = FindAllPartner()
		local _target = partners[RAND(1,#partners)]
		UnitAddBuff(_target, id, 0, {[7096] = shield}, content)
		UnitShowNumber(target, "", 3, "反射")
		return
	end

	local speed = content.speed
	local buff = UnitAddBuff(target, id, 0, {[7096] = shield, [1211] = speed}, content)

	if round > 0 then
		buff.remaining_round = round
	else
		content.not_go_round = 1
	end

	if content.attacker and content.attacker.uuid == target.uuid and round >= 0 and target.Round.action then
		buff.remaining_round = buff.remaining_round + 1
	end

	return buff
end	

function PlayEffectsInBuff(buff)
	Common_ShowCfgFlagEffect({id = buff.id, owner = buff.target})
	Common_UnitPlayAttack(buff.target, buff.id);
	Common_ShowCfgStageEffect({id = buff.id, owner = buff.target})
end

function Common_Sleep(attacker, sleep)
	Sleep(sleep)
end

function Common_UnitConsumeActPoint(attacker, count)
	if attacker and attacker[30061] > 0 then
		return
	end

	UnitConsumeActPoint(count)
end

-- 1.物理 2.法术 3.治愈 4.护盾 5.召唤 6.削弱 7.强化
function Check_Button_All(skill_type)
	local button_list = {
		[1] = "UI/fx_butten_all",
		[2] = "UI/fx_butten_all",
		[3] = "UI/fx_butten_all_xue",
		[4] = "UI/fx_butten_dun",
		[5] = "UI/fx_pet_fz_run",
		[6] = "UI/fx_butten_ruo",
		[7] = "UI/fx_butten_qiang"
	}

	return button_list[skill_type] or "UI/fx_butten_all"
end

function GetRoleMaster(role)	
	if role._Max_Master ~= 0 then
		return role._Max_Master
	end

	local master_list = {
		"airMaster",
		"dirtMaster",
		"waterMaster",
		"fireMaster",
		"lightMaster",
		"darkMaster"
	}

    table.sort(master_list, function (a, b)
        if role[a] ~= role[b] then
            return role[a] > role[b]
        end
        return a > b
	end)

	local role_master = master_list[1]
	if role[master_list[1]] == role[master_list[2]] then
		role_master = "All_Master"
	end
	role._Max_Master = role_master
	return role._Max_Master
end

local function Kezhi_button(attacker, target)
	local master_kezhi_list = {
		airMaster   = {kezhi = "dirtMaster",  beikezhi = "fireMaster"},
		dirtMaster  = {kezhi = "waterMaster", beikezhi = "airMaster"},
		waterMaster = {kezhi = "fireMaster",  beikezhi = "dirtMaster"},
		fireMaster  = {kezhi = "airMaster",   beikezhi = "waterMaster"},
		lightMaster = {kezhi = "darkMaster",  beikezhi = "darkMaster"},
		darkMaster  = {kezhi = "lightMaster", beikezhi = "lightMaster"},
	}

	local attacker_master = GetRoleMaster(attacker)
	local target_master = GetRoleMaster(target)

	local is_chaofen = target[7002] > 0 and "_cf" or "" 

	if master_kezhi_list[attacker_master] and master_kezhi_list[attacker_master].kezhi == target_master then
		return "UI/fx_butten_you"..is_chaofen
	elseif master_kezhi_list[attacker_master] and master_kezhi_list[attacker_master].beikezhi == target_master then
		return "UI/fx_butten_lie"..is_chaofen
	else
		return "UI/fx_butten"..is_chaofen
	end

end

-- 1.物理 2.法术 3.治愈 4.护盾 5.召唤 6.削弱 7.强化
function Check_Button(attacker, target, skill_type)
	if attacker.side ~= 1 or attacker.pos >= 100 then
		return ""
	end

	local button_list = {
		[1] = Kezhi_button(attacker, target),
		[2] = Kezhi_button(attacker, target),
		[3] = "UI/fx_butten_xue",
		[4] = "UI/fx_butten_dun",
		[5] = "UI/fx_pet_fz_run",
		[6] = "UI/fx_butten_ruo",
		[7] = "UI/fx_butten_qiang"
	}

	return button_list[skill_type] or "UI/fx_butten"
end

--以某种属性排列
function SortWithParameter(target_list, parameter, opposite)
	table.sort(target_list, function(a,b)
		if not opposite then
			if a[parameter] ~= b[parameter] then
				return a[parameter] < b[parameter]
			end
			return a.uuid < b.uuid
		else
			if a[parameter] ~= b[parameter] then
				return a[parameter] > b[parameter]
			end
			return a.uuid > b.uuid
		end
	end)
	return target_list
end

--以生命比例排列
function SortWithHpPer(target_list, opposite)
	table.sort(target_list, function(a,b)
		if not opposite then
			if a.hp/a.hpp ~= b.hp/b.hpp then
				return a.hp/a.hpp < b.hp/b.hpp
			end
			return a.uuid < b.uuid
		else
			if a.hp/a.hpp ~= b.hp/b.hpp then
				return a.hp/a.hpp > b.hp/b.hpp
			end
			return a.uuid > b.uuid
		end
	end)
	return target_list
end

--找到角色身上某个id的buff
function Common_FindBuff(target, id)
	if not target then
		return
	end

	local buff_list = {}
	local buffs = UnitBuffList(target)
	for _, buff in ipairs(buffs) do
		if buff.id == id then
			table.insert(buff_list, buff)
		end
	end
	
	return buff_list
end

function add_buff_parameter(target, buff, reverse)
	--额外改变属性
	local add_value = 0
	if buff.parameter_99 and buff.parameter_99 ~= 0 then
		local k = buff.parameter_99.k
		if k then
			local v = buff.parameter_99.v or 0 
			target[k] = target[k] + v * reverse	
			add_value =  v	
		end
	end

	if buff.cfg and buff.cfg ~= 0 then
		buff.cfg_property = {}  --用来处理1-30每个脚本专属的属性
		for i = 1, 3, 1 do
			local k = buff.cfg["parameter_"..i]
			local v = buff.cfg["value_"..i]

			if v == 0 and add_value ~= 0 then
				v = add_value
			elseif v == 0 then
				v = target[buff.id]
			end

			if k >= 30 then
				target[k] = target[k] + v * reverse
			elseif k ~= 0 then
				buff.cfg_property[k] = v
			end
		end
	end

	target["BuffID_"..buff.id] = target["BuffID_"..buff.id] + reverse
end

--[[
function evade_judge(role, bullet, per)
	if bullet.heal_enable == 1 
	or bullet.hurt_disabled == 1 
	or bullet.skilltype >= 5
	or bullet.skilltype == 0
	then
		return false
	end

	if RAND(1, 10000) < per * 10000 then
		return true
	else
		return false
	end
end
]]

--[[子弹类型定义！！
	1	普攻
	2	单体攻击
	3	群体攻击
	4	召唤物攻击
	5	dot伤害
	6	反弹伤害
	7	反击伤害
	8	其他伤害来源,溅射,穿刺,链接 
	9	链接伤害 
	20	技能治疗
	21  持续治疗
	22  宠物治疗
	23  其他治疗
	24  真实治疗
	30  其他效果---
]]

function Common_OriHurt(attacker, skill)
	local value_1 = (attacker[30000]/10000 + attacker[30000 + skill.sort_index * 1000]/10000) * attacker.ad
	local value_2 = (attacker[30001]/10000 + attacker[30001 + skill.sort_index * 1000]/10000) * attacker.armor
	local value_3 = (attacker[30002]/10000 + attacker[30002 + skill.sort_index * 1000]/10000) * attacker.hpp

	return value_1 + value_2 + value_3
end

--[[
CreateBullet2 = CreateBullet2 or function(id, attacker, target, Duration, property_list, bullet_effect)
	local bullet = CreateBullet()
	bullet.effect = bullet_effect
	bullet.from = attacker
	for k, v in pairs(property_list) do
		bullet[k] = v;
	end
	BulletFire(bullet, target, Duration)
	return bullet
end
--]]

local master_list_2 = {
	airMaster = 4,
	dirtMaster = 3,
	waterMaster = 1,
	fireMaster = 2,
	lightMaster = 5,
	darkMaster = 6
}

function Common_FireWithoutAttacker(id, targets, content)
	local content = content or {}
	local cfg = GetSkillEffectCfg(id)
	local Duration = 0.15

	if cfg then
		Duration = cfg.flight_time 
	end

	Hurt = content.Hurt or 0
	TrueHurt = content.TrueHurt or Hurt
	Type = content.Type or 0
	Attacks_Total = content.Attacks_Total or 1
	Element = content.Element or 0
	Duration = content.Duration or Duration


	local function StrValid(str)
		return str ~= nil and str ~= "0" and str ~= 0 and str ~= "";
	end

	for i = 1, Attacks_Total, 1 do 
		for k, target in ipairs(targets) do
			local bullet_skin_id = id;
			local bullet = CreateBullet2(bullet_skin_id, target, target, Duration, {})
			
			bullet.trueHurt = Hurt

			if Type >= 20 and Type < 30 then
				bullet.healValue = Hurt
				bullet.hurt_disabled = 1	
				bullet.heal_enable = 1
			elseif Type == 30 then
				bullet.hurt_disabled = 1
			end

			bullet.Type = Type			
			bullet.Element = Element

			bullet.Attacks_Total = Attacks_Total
			bullet.Attacks_Count = content.Attacks_Count or i
			bullet.name_id = content.name_id or 0

			if content.parameter then
				for k, v in pairs(content.parameter) do
					bullet[k] = (bullet[k] or 0) + v
				end
			end
		end
	end
end

local function calcAttacks(attacker, skill)
	local rate = attacker[30010] + attacker[30010 + skill.sort_index * 1000]
	local attacks = math.floor(rate/10000) + 1
	local extra = rate - math.floor(rate/10000) * 10000

	if extra > 0 and RAND(1, 10000) < extra then
		return 1 + attacks
	end
	return attacks
end

--发射技能的主要子弹
function Common_FireBullet(id, attacker, targets, skill, content)
	if not attacker then
		Common_FireWithoutAttacker(id, targets, content)
		return
	end

	local content = content or {}
	local cfg = skill and GetSkillEffectCfg(skill.id) or GetSkillEffectCfg(id)
	local Duration = 0.15
	local Interval = 0.17

	if cfg then
		Duration = cfg.flight_time 
		Interval = Duration + 0.02
	end

	local Hurt = (skill and skill.skill_type ~= 8) and Common_OriHurt(attacker, skill) or 0
	local TrueHurt = (skill and skill.skill_type == 8) and Common_OriHurt(attacker, skill) or 0
	local Type = skill and skill.skill_place_type or 0

	local Attacks_Total = skill and calcAttacks(attacker, skill) or 1
	local Element = skill and skill.skill_element or 0

	Hurt = content.Hurt or Hurt
	TrueHurt = content.TrueHurt or TrueHurt
	Type = content.Type or Type
	Attacks_Total = content.Attacks_Total or Attacks_Total
	Element = content.Element or Element
	Duration = content.Duration or Duration
	Interval = content.Interval or (Duration + 0.02)

	local property_list = {}
	if Type ~= 21 then
		for k, v in pairs(attacker.property_keys) do
			-- print("___________________________________________________",k,v)
			if k >= 300000 and k <= 309999 then
				property_list[k] = (property_list[k] or 0) + v
			elseif skill then
				local new_k = k - skill.sort_index * 10000
				if new_k >= 300000 and new_k <= 309999 then
					property_list[new_k] = (property_list[new_k] or 0) + v
				end
			end
		end

		if skill then
			for k, v in pairs(skill.cfg.property_list) do
				if k >= 300000 and k <= 309999 then
					property_list[k] = (property_list[k] or 0) + v
				end
			end			
		end
	end

	local function StrValid(str)
		return str ~= nil and str ~= "0" and str ~= 0 and str ~= "";
	end

	for i = 1, Attacks_Total, 1 do 
		for k, target in ipairs(targets) do
			if target.hp and target.hp > 0 then
				local from = content.From or attacker

				local bullet_skin_id = id;
				if cfg and ( StrValid(cfg.bullet_effect) or StrValid(cfg.hit_effect)) then
					bullet_skin_id = cfg.id;
				end

				if i ~= 1 and cfg and cfg.show_once_only == 1 then
					bullet_skin_id = 0
				end

				local bullet = CreateBullet2(bullet_skin_id, from, target, Duration, property_list)

				if Hurt == 0 and TrueHurt == 0 then
					Type = 30
					bullet.hurt_disabled = 1	
				end

				bullet.hurt = Hurt
				bullet.trueHurt = TrueHurt

				if Type >= 20 and Type < 30 then
					bullet.healValue = Hurt
					bullet.hurt_disabled = 1	
					bullet.heal_enable = 1
				elseif Type == 30 then
					bullet.hurt_disabled = 1
				end

				bullet.attacker = attacker
				bullet.Type = Type			
				if Element == 7 then
					bullet.Element = master_list_2[GetRoleMaster(attacker)]
				else
					bullet.Element = Element
				end

				bullet.Attacks_Total = Attacks_Total
				bullet.Attacks_Count = content.Attacks_Count or i
				bullet.name_id = content.name_id or (skill and skill.id) or id
				bullet.not_show_num = content.not_show_num and 1 or 0
				bullet.Fire_Skill = skill

				if content.parameter then
					for k, v in pairs(content.parameter) do
						bullet[k] = (bullet[k] or 0) + v
					end
				end
			end
		end
	
		if Interval ~= 0 then
			Common_Sleep(attacker, Interval)
		end
	end
end

local function ParaAddUp(attacker, parameter_id, skill)
	return attacker[parameter_id] + attacker[skill.sort_index * 1000 + parameter_id]
end

function OtherEffectInCfg(attacker, targets, skill)
	if ParaAddUp(attacker, 30101, skill) > 0 then
		AddRandomBuff(attacker, ParaAddUp(attacker, 30101, skill))
		print("__________________________AddRandomBuff_________________!!!!!!!!", buff.id)
	end
	
	if ParaAddUp(attacker, 30091, skill) > 0 then
		local list_2 = {}
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			list_2[v.Position.pos] = true
			if v.Position.pos == 31 then
				list_2[32] = true
			elseif v.Position.pos == 32 then
				list_2[31] = true
			elseif v.Position.pos == 33 then
				list_2[34] = true
			elseif v.Position.pos == 34 then
				list_2[33] = true
			end
		end

		local pos
		if ParaAddUp(attacker, 30092, skill) <= 0 then
			local list = {31, 32, 33, 34, 21, 22, 23}
			for i = 1, #list do
				local index = RAND(1, #list)
				local _pos = list[index]
				if not list_2[_pos] then
					pos = _pos
					break
				end
				table.remove(list, index)
			end
		else
			pos = ParaAddUp(attacker, 30092, skill)
		end

		if pos then
			UnitPlay(target, "attack1", {speed = 1});
			Sleep(0.3)
			AddEnemyInWave(ParaAddUp(attacker, 30091, skill), pos)
		end
	end

	if ParaAddUp(attacker, 30041, skill) > 0 then
		local round = (ParaAddUp(attacker, 30044, skill) ~= 0) and ParaAddUp(attacker, 30044, skill)
		local hp_per = (ParaAddUp(attacker, 30043, skill) ~= 0) and ParaAddUp(attacker, 30043, skill)/10000
		local pro_per = (ParaAddUp(attacker, 30042, skill) ~= 0) and ParaAddUp(attacker, 30042, skill)/10000

		local pet = Common_SummonPet(attacker, ParaAddUp(attacker, 30041, skill), 1, round, pro_per, hp_per)
		local cfg = skill and GetSkillEffectCfg(skill.id)
		if cfg.stage_effect_1 == "0" or cfg.stage_effect_1 == 0 or cfg.stage_effect_2 == "0" or cfg.stage_effect_2 == 0 then
			Common_AddStageEffect(30041, 1, 2, skill.owner, pet.mode)
			Common_Sleep(nil, 1.2)		
		end
	end

	if ParaAddUp(attacker, 30051, skill) > 0 or ParaAddUp(attacker, 30052, skill) > 0 then
		for _, v in ipairs(targets) do
			Common_Relive(attacker, v, 1 + ParaAddUp(attacker, 30052, skill)/10000 * v.hpp)
		end
		Common_Sleep(attacker, 0.5)
	end

	if ParaAddUp(attacker, 30071, skill) > 0 then
		for _, v in ipairs(targets) do
			Common_ChangeEp(v, ParaAddUp(attacker, 30071, skill), true)
		end
		Common_Sleep(attacker, 0.5)
	end

	if ParaAddUp(attacker, 30056, skill) > 0 then
		local hp_average_per = (targets[1].hp + attacker.hp) / (targets[1].hpp + attacker.hpp)
		Common_ChangeHp(attacker, hp_average_per * attacker.hpp  - attacker.hp)
		Common_ChangeHp(targets[1], hp_average_per * targets[1].hpp - targets[1].hp)
	end

	if ParaAddUp(attacker, 30057, skill) > 0 then
		local partners = FindAllPartner()
		local hp_total = 0
		local hpp_total = 0
		for _, v in ipairs(partners) do
			hp_total = hp_total + v.hp
			hpp_total = hpp_total + v.hpp
		end

		local hp_average_per = hp_total / hpp_total
		for _, v in ipairs(partners) do
			Common_ChangeHp(v, hp_average_per * v.hpp - v.hp)
		end
	end

	Common_ChangeHp(attacker, -math.floor(attacker.hpp * attacker[30021] / 10000) )
	Common_ChangeHp(attacker, -math.floor(attacker[30022] / 10000 * attacker.hp))
end

function AddConfigBuff(attacker, targets, skill)
	if ParaAddUp(attacker, 30030, skill) > 0 then
		for _, v in ipairs(targets) do
			local range = (ParaAddUp(attacker, 30034, skill) > 0) and ParaAddUp(attacker, 30034, skill) or 10000
			Common_UnitAddBuff(attacker, v, ParaAddUp(attacker, 30030, skill), range/10000, {
				parameter_99 = {k= ParaAddUp(attacker, 30030, skill), v = ParaAddUp(attacker, 30024, skill)}
			})     
		end
		Common_Sleep(attacker, 1)
	end

	if ParaAddUp(attacker, 30031, skill) > 0 then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do 
			local range = (ParaAddUp(attacker, 30035, skill) > 0) and ParaAddUp(attacker, 30035, skill) or 10000
			Common_UnitAddBuff(attacker, v, ParaAddUp(attacker, 30031, skill), range/10000, {
				parameter_99 = {k= ParaAddUp(attacker, 30031, skill), v = ParaAddUp(attacker, 30025, skill)}
			})      
		end
		Common_Sleep(attacker, 1)
	end

	if ParaAddUp(attacker, 30032, skill) > 0 then
		for _, v in ipairs(All_target_list()) do 
			local range = (ParaAddUp(attacker, 30036, skill) > 0) and ParaAddUp(attacker, 30036, skill) or 10000
			Common_UnitAddBuff(attacker, v, ParaAddUp(attacker, 30032, skill), range/10000, {
				parameter_99 = {k= ParaAddUp(attacker, 30032, skill), v = ParaAddUp(attacker, 30026, skill)}
			})       
		end
		Common_Sleep(attacker, 1)
	end

    if ParaAddUp(attacker, 30033, skill) > 0 then
		local range = (ParaAddUp(attacker, 30037, skill) > 0) and ParaAddUp(attacker, 30037, skill) or 10000
		Common_UnitAddBuff(attacker, attacker, ParaAddUp(attacker, 30033, skill), range/10000, {
			parameter_99 = {k= ParaAddUp(attacker, 30033, skill), v = ParaAddUp(attacker, 30027, skill)}
		})        
		Common_Sleep(attacker, 1)
	end
end

--每次对随机目标发射子弹
function FireRandomTarget(id, attacker, targets, skill, content)
	local content = content or {}
	local random_times = skill and calcAttacks(attacker, skill) or 1 
	random_times = content.Attacks_Total or random_times
	content.Attacks_Total = 1

	if content.Duration and content.Duration > 0 then
		content.Interval = content.Duration + 0.01
	end

	for i = 1, random_times, 1 do
		local correct_list = {}
		for k, v in ipairs(targets) do 
			if v.hp > 0 then
				table.insert(correct_list, v)
			end
		end

		if not next(correct_list) then
			break
		end

		local target = correct_list[RAND(1, #correct_list)]
		Common_FireBullet(id, attacker, {target}, skill, content)
	end
end

function Common_Hurt(attacker, targets, element, value, content)
	if value <= 0 then
		return
	end

	Common_FireBullet(content.effect_id or 0, attacker, targets, nil, {
		Duration = 0,
		Interval = 0,
		name_id = content.name_id or 0,
		Type = content.Type or 5,
		TrueHurt = value,
		Element = element,
		parameter = {
			critPer = -10000,
		}
	})
end

function Common_Heal(attacker, targets, element, value ,content)
	if value <= 0 then
		return
	end

	local content = content or {}
	Common_FireBullet(0, attacker, targets, nil, {
		Duration = 0,
		Interval = 0,
		name_id = content.name_id or 0,
		Type = content.Type or 21,
		Hurt = value,
		Element = element,
		parameter = {
			critPer = -10000,
		}
	})
end

--终止技能判断
function Common_Break_Skill(attacker, skill)
	if attacker.Break_Skill > 0 and skill.skill_consume_ep > 0 then
		RepeatReomveBuff(attacker, 2903430, 1)
		print("")
		Common_UnitAddBuff(attacker, attacker, 7009, 1)   
		ShowErrorInfo(7)
		return true
	end

	return false
end

--伤害子弹触发事件判断
function Hurt_Effect_judge(bullet, per)
	if bullet.Type == 0 or bullet.Type > 4 then
		return false
	end

	if per then
		return RAND(1, 10000) <= per * 10000
	end

	return true
end

--治疗子弹触发事件判断
function Heal_Effect_judge(bullet, per)
	if bullet.Type ~= 20 then
		return false
	end

	if per then
		return RAND(1, 10000) <= per * 10000
	end

	return true
end

--消耗
--目标， 值 ，是否显示
function Common_ChangeEp(role, value, show)
	if not value or not role then
		return
	end

	if role[7002] > 0 and value > 0 then
		return
	end

	UnitChangeMP(role, math.floor(value), "ep")
	if show and value ~= 0 then
		local str = type(show) == "string" and show or "能量改变"
		UnitShowNumber(role, math.floor(value), 3, str, value > 0 and 1 or 2)
	end
end

--前置特效
function Common_ShowCfgFlagEffect(skill)
	if not skill then
		return
	end

	local cfg = GetSkillEffectCfg(skill.id)
	if not cfg then
		return
	end

	Common_AddStageEffect(skill.id, 1, 7, skill.owner)
	Common_Sleep(nil, cfg.sleep_1)
end

--场景特效
function Common_ShowCfgStageEffect(skill)
	local cfg = GetSkillEffectCfg(skill.id)
	if not cfg then
		return
	end

	Common_AddStageEffect(skill.id, 2, 7, skill.owner)
	Common_Sleep(nil, cfg.sleep_2)
end

function Common_SplitTargetsByPid(focus)
	local enemies = FindAllEnemy()
	local new_list = {}
	for k, v in ipairs(enemies) do
		local pid = v.Force.pid 
		if not focus or attacker.focus_pid == pid then
			if not new_list[pid] then
				new_list[pid] = {}
			end
			table.insert(new_list[pid], v)
		end
	end
	return new_list
end

local function multiple_choose(ignore_hide_rank, count, focus)
	local count = count or 1
	local new_list = Common_SplitTargetsByPid(focus)
	local final_list = {}

	for _, v in pairs(new_list) do
		if ignore_hide_rank then
			local list = Target_list(nil,v,"fanchaofeng")
			for i = 1,count,1 do
				if #list <= 0 then break end

				local index = RAND(1, #list)
				table.insert(final_list, list[index])
				table.remove(list, index)
			end
		else
			local list = Target_list(nil,v)
			local role = list[RAND(1, #list)]
			table.insert(final_list, role)
			local fit_list = Common_GetOtherTargets(role, Target_list(nil,v,"fanchaofeng"))

			for i = 1, count - 1, 1 do
				if #fit_list < 0 then break end
				local index = RAND(1, #fit_list)
				table.insert(final_list, fit_list[index])
				table.remove(fit_list, index)
			end
		end
	end

	return final_list
end

function Commom_MultipleChoose(attacker, ignore_hide_rank, count)
	if attacker.side == 1 then
		return
	end

	if not attacker.game.attacker_player_count or attacker.game.attacker_player_count < 0 then
		return
	end
	
	return multiple_choose(ignore_hide_rank, count)
end

--目标选择
function Common_GetTargets(...)
	local info = select(1, ...)
	local target = info.target
	local target_list = {}

	if not info.multiple_choose then
		if target == "enemy" and info.value ~= "pet" then
			target_list = All_target_list()
		elseif target == "partner" and info.type ~= "dead_partners" then
			target_list = FindAllPartner()
		elseif info.type == "partner_pets" then
			local partners = FindAllPartner()
			for _, v in ipairs(partners) do
				for k, pet in ipairs(UnitPetList(v)) do
					table.insert(target_list, pet)
				end
			end
		elseif info.type == "dead_partners" then
			return info.value
		else
			target_list = {target}
		end

		if info.random then
			target_list = RandomInTargets(target_list, info.random)
		end

		if info.extra then
			local other_targets = Common_GetOtherTargets(target, All_target_list())
			target_list = RandomInTargets(other_targets, info.extra)	
			table.insert(target_list, target)	
		end
	else
		if info.extra then
			target_list = multiple_choose(nil, 1 + info.extra, info.focus)
		elseif info.random then
			target_list = multiple_choose(true, info.random, info.focus)
		else
			target_list = multiple_choose(nil, nil, info.focus)
		end
	end

	return target_list, All_target_list()
end

function Common_GetOtherTargets(target, all_targets)
	local other_targets = {}

	for _, v in ipairs(all_targets) do
		if v.uuid ~= target.uuid then
			table.insert(other_targets, v)
		end
	end

	return other_targets
end

--从多个目标中 随机选x个
function RandomInTargets(target_list, num)
	local new_list = {}
	local former_list = {}
	for _, v in ipairs(target_list) do
		table.insert(former_list, v)
	end

	for i = 1, num, 1 do
		if not next(former_list) then
			break
		end
		local index = RAND(1, #former_list)
		table.insert(new_list, former_list[index])
		table.remove(former_list, index)
	end

	return new_list
end

--弹射
function BallBulletFire(id, attacker, first_target, all_targets, attacks, skill, content)
	local last_target = nil
	if type(target) == "table" then
		last_target = first_target[1]
	else
		last_target = first_target
	end

	Common_FireBullet(id, attacker, {last_target}, skill, content)

	for i = 1,attacks - 1,1 do
		local new_list = {}
		for _, v in ipairs(all_targets) do 
			if v.uuid ~= last_target.uuid and v.hp > 0 then
				table.insert(new_list, v)
			end
		end

		local content = content or {}
		local new_target = {}

		if #new_list > 0 then
			new_target =  new_list[RAND(1, #new_list)]
			content.From = last_target
			last_target = new_target
		else
			break
		end

		Common_FireBullet(id, attacker, {new_target}, skill, content)
	end
end

function Common_SummonPet(attacker, id, count, round, property_per, hp_per)
	local id = id or 1
	local count = count or 1
	local round = round or 1
	local property_per = property_per or 0.3
	local hp_per = hp_per or 0.3

	local pet = SummonPet(id, count, round, {
		[1001] = attacker[1001] * property_per,                          --基础攻击
		[1002] = attacker[1002] * property_per,                          --装备攻击
		[1011] = attacker[1011] + attacker[1243],         --基础攻击加成（来自进阶、升星）
		[1012] = attacker[1012],                          --装备攻击加成
		[1013] = attacker[1013],						  --基础攻击加成2（来自装备全局）
		[1022] = attacker[1022] + attacker[1241],	 	  --伤害加成
		[1031] = attacker[1031],						  --无视防御（在穿透前计算）
		[1032] = attacker[1032],							--攻击穿透
		[1201] = attacker[1201],							--暴击率
		[1202] = attacker[1202],							--暴击伤害
		[1203] = attacker[1203],							--免暴率
		[1204] = attacker[1204],							--暴伤减免
		[1211] = attacker[1211],							--速度
		[1221] = attacker[1221],							--治疗效果提升
		[1222] = attacker[1222],							--受到治疗效果提升
		[1231] = attacker[1231],							--护盾效果提升
		[1246] = attacker[1246],							--正值为降低，负值为提升
		[1301] = attacker[1301] * property_per,							--基础防御
		[1302] = attacker[1302] * property_per,							--装备防御
		[1311] = attacker[1311] + attacker[1243], 			--基础防御加成
		[1312] = attacker[1312],							--装备防御加成
		[1321] = attacker[1321],							--伤害吸收（在减免后计算）
		[1322] = attacker[1322] + attacker[1242],		    --伤害减免
		[1501] = attacker[1501] * hp_per,					--基础生命
		[1502] = attacker[1502] * hp_per,					--装备生命
		[1503] = attacker[1503] * hp_per,					--其他生命
		[1511] = attacker[1511] + attacker[1245], 			--基础生命加成
		[1512] = attacker[1512],							--装备生命加成
		[1513] = attacker[1513],							--装备生命加成
		[1514] = attacker[1514],							--装备生命加成
		[1515] = attacker[1515],							--装备生命加成
		[1521] = attacker[1521],							--生命回复
		[1522] = attacker[1522],							--生命回复提升
		[1801] = attacker[1801],							--角色的元素类型
		[1802] = attacker[1802],							--角色的元素类型
		[1803] = attacker[1803],							--角色的元素类型
		[1804] = attacker[1804],							--角色的元素类型
		[1805] = attacker[1805],							--角色的元素类型
		[1806] = attacker[1806],							--角色的元素类型
		[1807] = attacker[1807],							--角色的元素类型
		[1871] = attacker[1871],							--受到风系伤害时回血
		[1872] = attacker[1872],							--受到土系伤害时回血
		[1873] = attacker[1873],							--受到水系伤害时回血
		[1874] = attacker[1874],							--受到火系伤害时回血
		[1875] = attacker[1875],							--受到光系伤害时回血
		[1876] = attacker[1876],							--受到暗系伤害时回血
		[1877] = attacker[1877],							--受到伤害时时回血
		[1881] = attacker[1881],							--风系伤害提升
		[1882] = attacker[1882],							--土系伤害提升
		[1883] = attacker[1883],							--水系伤害提升
		[1884] = attacker[1884],							--火系伤害提升
		[1885] = attacker[1885],							--光系伤害提升
		[1886] = attacker[1886],							--暗系伤害提升
		[1887] = attacker[1887],							--伤害提升
		[1891] = attacker[1891],							--受到的风系伤害降低
		[1892] = attacker[1892],							--受到的土系伤害降低
		[1893] = attacker[1893],							--受到的水系伤害降低
		[1894] = attacker[1894],							--受到的火系伤害降低
		[1895] = attacker[1895],							--受到的光系伤害降低
		[1896] = attacker[1896],							--受到的暗系伤害降低
		[1897] = attacker[1897],							--受到的伤害降低		
	})

	pet.owner = attacker
	pet.BuffID_99996 = Common_UnitAddBuff(attacker, pet, 99996)

	return pet
end

--随机移除满足条件的buff
function Common_RemoveBuffRandom(target, isDebuff, num)
	local buff_list = UnitBuffList(target)
	local fit_list = {}
	for _, buff in ipairs(buff_list) do
		if buff.isRemove == 1 and isDebuff[buff.isDebuff] then
			table.insert(fit_list, buff)
		end
	end

	local remove_count = 0
	for i = 1, num, 1 do
		if #fit_list == 0 then
			break
		end

		remove_count = remove_count + 1
		local index = RAND(1, #fit_list)
		UnitRemoveBuff(fit_list[index])
		table.remove(fit_list, index)
	end

	return remove_count
end

function Common_ChangeHp(role, value)
	role:ChangeHP(value)
end

function Common_ChangeHpp(role, value)
	role.hpp = role.hpp + value
	role.hp = math.min(role.hpp, role.hp)
end

function Common_BeatBack(attacker, target, Hurt, name_id)
	local Element = master_list_2[GetRoleMaster(attacker)]
	UnitPlay(attacker, "attack1", {speed = 1});

	local skill = SkillGetInfo(attacker, 1)
	for k, v in ipairs(skill.cfg.property_list) do
		target[k] = target[k] + v
	end	

	Common_FireBullet(0, attacker, target, nil, {
		Duration = 0,
		Interval = 0,
		Hurt = Hurt,
		Type = 1,
		name_id = name_id or 0,
		Element = Element,
	})

	for k, v in ipairs(skill.cfg.property_list) do
		target[k] = target[k] - v
	end	
end

function Common_Relive(attacker, role, hp)
	role.hp = hp + 1
	ShowBuffEffect(role, "buff/buff_05", "复活", true)
end

function Add_Effect(id, attacker, targets, interval)
    Common_FireBullet(id, attacker, targets, nil, {Type = 30, Interval = interval})
end
