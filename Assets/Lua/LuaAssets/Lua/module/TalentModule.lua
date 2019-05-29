local playerModule = require "module.playerModule";
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local SkillConfig = require "config.skill"
local talentConfig = nil;
local talentConfigByGroup = nil;

local function AddTalentConfig(data)
	local talent_id, group, sub_group = data.weapon_id, data.group, data.sub_group;

	talentConfig[talent_id] = talentConfig[talent_id] or {};

	talentConfigByGroup[talent_id]                   = talentConfigByGroup[talent_id] or {}
	talentConfigByGroup[talent_id][group]            = talentConfigByGroup[talent_id][group] or {}
	talentConfigByGroup[talent_id][group][sub_group] = talentConfigByGroup[talent_id][group][sub_group] or {}

	local talent = setmetatable({ effects = {} }, {__index = data});
	if data.effect_type1 ~= 0 then
		table.insert(talent.effects, {type=data.effect_type1, init = data.init_value1, incr = data.incr_value1})
	end


	if data.effect_type2 ~= 0 then
		table.insert(talent.effects, {type=data.effect_type2, init = data.init_value2, incr = data.incr_value2})
	end

	if data.effect_type3 ~= 0 then
		table.insert(talent.effects, {type=data.effect_type3, init = data.init_value3, incr = data.incr_value3})
	end
	if data.effect_type4 ~= 0 then
		table.insert(talent.effects, {type=data.effect_type4, init = data.init_value4, incr = data.incr_value4})
	end

	talent.depends = {}
	if data.depend_id1 ~= 0 then table.insert(talent.depends, data.depend_id1) end
	if data.depend_id2 ~= 0 then table.insert(talent.depends, data.depend_id2) end
	if data.depend_id3 ~= 0 then table.insert(talent.depends, data.depend_id3) end

	talentConfig[talent_id][talent.id] = talent;
	table.insert(talentConfigByGroup[talent_id][group][sub_group], talent);
end

local function GetTalentConfig(id)
	if talentConfig == nil then
		talentConfig = {}
		talentConfigByGroup = {};
		for _, cfg in ipairs({"talent", "skill_tree", "roletitle"}) do
			DATABASE.ForEach(cfg, function(row)
				AddTalentConfig(row)
			end)
		end
	end
	return talentConfig[id];
end

local function GetTalentConfigByGroup(id, group, sub_group)
	GetTalentConfig(id);

	if sub_group then
		return talentConfigByGroup[id]
			and talentConfigByGroup[id][group]
			and talentConfigByGroup[id][group][sub_group]
	elseif group then
		return talentConfigByGroup[id]
			and talentConfigByGroup[id][group]
	else
		return talentConfigByGroup[id];
	end
end

local sn2pid = {};

local player_talent_info = {};
local function GetTalentData(uuid, type, pid)
	pid = pid or playerModule.GetSelfID();

	if pid == playerModule.GetSelfID() then
		if player_talent_info[pid] == nil then
			local sn = NetworkService.Send(21,{nil});
			sn2pid[sn] = pid;
		end
		player_talent_info[pid] = player_talent_info[pid] or {};
	elseif player_talent_info[pid] == nil
		or player_talent_info[pid][type] == nil
		or player_talent_info[pid][type][uuid] == nil then

		player_talent_info[pid] = player_talent_info[pid] or {};
		player_talent_info[pid][type] = player_talent_info[pid][type] or {};
		player_talent_info[pid][type][uuid] = player_talent_info[pid][type][uuid] or {};

		local sn = NetworkService.Send(21,{nil, pid, 0, type, uuid});
		sn2pid[sn] = pid;
	end
	return player_talent_info[pid][type] and player_talent_info[pid][type][uuid] or {}
end

local function UpdateCharacterTalentData(pid, talenttype, refid, data, uuid)
	pid  = math.floor(pid);
	-- assert(type(uuid) == "number", debug.traceback());
	uuid = math.floor(uuid);

	player_talent_info[pid] = player_talent_info[pid] or {};
	player_talent_info[pid][talenttype] = player_talent_info[pid][talenttype] or {};

	local talentdata = {}
	for i=1,string.len(data) do
		table.insert(talentdata, string.byte(data,i) - string.byte('0', 1))
	end

	player_talent_info[pid][talenttype][uuid] = talentdata;
end

local function UpdatePlayerTalentData(pid, data)
	player_talent_info[pid] = {}
	for _, v in ipairs(data) do
		UpdateCharacterTalentData(pid, v[1], v[2], v[3], v[4]);
	end
end

local titleFightConfig=nil;
local function loadTitleFightConfig(fight_id)
	if titleFightConfig== nil then
       titleFightConfig= LoadDatabaseWithKey("title_fight", "fight_id");
    end
   return titleFightConfig[fight_id] or {}
end

local skillSwitchConfig = nil;
local function loadSkillSwitchConfig(role_id)
	if skillSwitchConfig == nil then
		skillSwitchConfig = {};
		local data_raw = DATABASE.Load("chief");
		for _, data in ipairs(data_raw) do
			if skillSwitchConfig[data.role_id] == nil then
				skillSwitchConfig[data.role_id] = {};
			end
			skillSwitchConfig[data.role_id][data.property_value] = data;
			if data.property_value == 1 then
				skillSwitchConfig[data.role_id][0] = data;
			end
		end
	end
	return skillSwitchConfig[role_id];
end

local skillShowConfig = nil;
local function loadSkillShowConfig(id)
	if skillShowConfig == nil then
		skillShowConfig = {};

		DATABASE.ForEach("skillshow", function(data)
			skillShowConfig[data.skillID] = skillShowConfig[data.skillID] or {}
			table.insert(skillShowConfig[data.skillID],data)
		end)
	end
	return skillShowConfig[id] or {};
end

local skillShowValue = nil;
local function loadSkillShowValue(id)
	if skillShowValue == nil then
		skillShowValue = {};

		DATABASE.ForEach("skillshowvalue", function(data)
			if skillShowValue[data.skill_id] == nil then
				skillShowValue[data.skill_id] = {};
			end
			for i=1,4 do
				if data["show_id"..i] and data["show_id"..i] ~= 0 then
					table.insert(skillShowValue[data.skill_id], data["show_id"..i])
				end
			end
		end)
	end
	return skillShowValue[id];
end

local function getSkillID(weaponID)
	if skillTreeConfigByGroup == nil then
		loadSkillTreeConfig();
	end
	local skillID = {};
	for k,v in pairs(skillTreeConfigByGroup[weaponID]) do
		table.insert(skillID,k);
	end
	table.sort(skillID);
	return skillID;
end

local talentData = {};
local SnData = {};
local talent_querying = {};
local function getTalentFromServer(gid,pid,type,dispatch)
	pid = pid or playerModule.GetSelfID();

	do
		local cfg = module.HeroModule.GetConfig(gid) or module.HeroModule.GetConfigByWeapon(gid)
		local hero = module.HeroModule.GetManager(pid):Get(cfg.gid);
		if hero then
			return GetTalentData(pid, hero.uuid, type);
		else
			print("!!!!!!!!!!!!", pid, gid, "not exists", debug.traceback());
		end
	end
end

local Sn2ProductTitle={}
local function saveTalentData(uuid,type,data)
	print("保存天赋", uuid, type, sprinttb(data))
	local sn =NetworkService.Send(25,{nil, 0, data, type, uuid});
	if sn~=nil then
		Sn2ProductTitle[sn]={uuid=uuid,type=type}
	end
end

local function getProperty(hero, talent_type)
	local property = {};

	local talents = {};

	local cfg  = module.HeroModule.GetConfig(hero.id);
	local wCfg = module.HeroModule.GetWeaponConfigByHeroID(hero.id);

	local function add_talent_list(type, id)
		if talent_type == nil or talent_type == type then
			talents[type] = id;
		end
	end

	add_talent_list(1, cfg.talent_id);
	add_talent_list(4, cfg.roletalent_id1);
	add_talent_list(5, cfg.roletalent_id2);
	add_talent_list(2, wCfg and wCfg.talent_id);

	local skillGroups = loadSkillSwitchConfig(hero.id);
	for _, v in pairs(skillGroups or {}) do
		add_talent_list(v.type, v.skill_tree)
	end

	for type, talent_id in pairs(talents) do
		local talentData = GetTalentData(hero.uuid, type)
		local talentCfg  = GetTalentConfig(talent_id);
		if not talentCfg then
			-- print("talent config", talent_id, "not exists");
		else
			for _, talent in pairs(talentCfg) do
				local level = talentData[talent.id] or 0;
				if  level > 0 then
					for _, v in ipairs(talent.effects) do
						property[v.type] = (property[v.type] or 0) + v.init + v.incr * (level - 1);
					end
				end
			end
		end
	end
	return property;
end

local function CaclProperty(hero,onlyWeapon)
	if onlyWeapon then
		return getProperty(hero, 2);
	else
		return getProperty(hero);
	end
end

local function GetSkillDetailDes(skillid, props)
	local _skillShowConfig = loadSkillShowConfig(skillid);
	local skillConfig = SkillConfig.GetConfig(skillid);
	local des = {};
	for i,v in ipairs(_skillShowConfig) do
		local str = "";
		for i=1,6 do
			if v["change"..i] == 1 then
				if v["valueID"..i.."_1"] ~= 0 then
					-- print("属性ID1",v["valueID"..i.."_1"],"人物属性",props[v["valueID"..i.."_1"]],"技能表",skillConfig.property_list[v["valueID"..i.."_1"]],"描述",v["des"..i], v["type"..i.."_1"]);
					if v["type"..i.."_1"] ~= 2 then
						local num1,num2 = 0,0;
						if props[v["valueID"..i.."_1"]] ~= nil and props[v["valueID"..i.."_1"]] ~= 0 then
							if v["type"..i.."_1"] == 1 then
								num1 = props[v["valueID"..i.."_1"]];
							elseif v["type"..i.."_1"] == 10000 then
								num1 = props[v["valueID"..i.."_1"]]/100;
							end
						end
						if skillConfig.property_list[v["valueID"..i.."_1"]] ~= nil and skillConfig.property_list[v["valueID"..i.."_1"]] ~= 0 then
							if v["type"..i.."_1"] == 1 then
								num2 = skillConfig.property_list[v["valueID"..i.."_1"]];
							elseif v["type"..i.."_1"] == 10000 then
								num2 = skillConfig.property_list[v["valueID"..i.."_1"]]/100;
							end
						end
						if (num1 + num2) ~= 0 then
							local NUM = 0;
							if (num1 + num2)%1 == 0 then
								NUM = math.floor(num1 + num2);
							else
								NUM = string.format("%.2f", num1 + num2);
							end
							str = str..string.format(v["des"..i],NUM);
						end
					else
						if (props[v["valueID"..i.."_1"]] ~= nil and props[v["valueID"..i.."_1"]] ~= 0) or (skillConfig.property_list[v["valueID"..i.."_1"]] ~= nil and skillConfig.property_list[v["valueID"..i.."_1"]] ~= 0) then
							str = str..v["des"..i];
						else
							--print("英雄没有", v["valueID"..i.."_1"].."属性");
						end
					end
				end
			elseif v["change"..i] == 2 then
				if v["valueID"..i.."_1"] ~= 0  and v["valueID"..i.."_2"] ~= 0 then
					local num1,num2,num3,num4 = 0,0,0,0;
					-- print("属性ID1", v["valueID"..i.."_1"], "人物属性1", props[v["valueID"..i.."_1"]], "属性ID2", v["valueID"..i.."_2"], "人物属性2", props[v["valueID"..i.."_2"]],
					-- "技能表1", skillConfig.property_list[v["valueID"..i.."_1"]], "技能表2",skillConfig.property_list[v["valueID"..i.."_2"]], "描述", v["des"..i]);
					if props[v["valueID"..i.."_1"]] ~= nil and props[v["valueID"..i.."_1"]] ~= 0 then --人物属性
						if v["type"..i.."_1"] == 1 then
							num1 = props[v["valueID"..i.."_1"]];
						elseif v["type"..i.."_1"] == 10000 then
							num1 = props[v["valueID"..i.."_1"]]/100;
						end
					end
					if skillConfig.property_list[v["valueID"..i.."_1"]] ~= nil and skillConfig.property_list[v["valueID"..i.."_1"]] ~= 0 then--技能表
						if v["type"..i.."_1"] == 1 then
							num2 = skillConfig.property_list[v["valueID"..i.."_1"]];
						elseif v["type"..i.."_1"] == 10000 then
							num2 = skillConfig.property_list[v["valueID"..i.."_1"]]/100;
						end
					end

					if props[v["valueID"..i.."_2"]] ~= nil and props[v["valueID"..i.."_2"]] ~= 0 then
						if v["type"..i.."_2"] == 1 then
							num3 = props[v["valueID"..i.."_2"]];
						elseif v["type"..i.."_2"] == 10000 then
							num3 = props[v["valueID"..i.."_2"]]/100;
						end
					end
					if skillConfig.property_list[v["valueID"..i.."_2"]] ~= nil and skillConfig.property_list[v["valueID"..i.."_2"]] ~= 0 then
						if v["type"..i.."_2"] == 1 then
							num4 = skillConfig.property_list[v["valueID"..i.."_2"]];
						elseif v["type"..i.."_2"] == 10000 then
							num4 = skillConfig.property_list[v["valueID"..i.."_2"]]/100;
						end
					end

					if (num1 + num2) ~= 0 or (num3 + num4) ~= 0 then
						local NUM1,NUM2 = 0,0;
						if (num1 + num2)%1 == 0 then
							NUM1 = math.floor(num1 + num2);
						else
							NUM1 = string.format("%.2f", num1 + num2);
						end
						if (num3 + num4)%1 == 0 then
							NUM2 = math.floor(num3 + num4);
						else
							NUM2 = string.format("%.2f", num3 + num4);
						end

						str = str..string.format(v["des"..i], NUM1, NUM2);
					end
				end
			end
		end
		--print("组合："..str);
		if str ~= "" then
			str = str.."。";
		end
		table.insert(des,str);
	end
	return des;
end

local function GetSkillMultipleDetailDes(skillid, props)
	local _skillShowValue = loadSkillShowValue(skillid);
	if _skillShowValue then
		local mainSkill = GetSkillDetailDes(skillid, props);
		assert(mainSkill[1], "技能"..skillid.."主要描述异常")
		for i,v in ipairs(_skillShowValue) do
			local nextSkill = GetSkillDetailDes(v, props);
			mainSkill[1] = mainSkill[1].."\n"..nextSkill[1];
		end
		return mainSkill;
	else
		return GetSkillDetailDes(skillid, props);
	end
end

--type 1 英雄 2武器 4战斗称号 5 生产称号 --	id 人物id --condition 查天赋传人物等级 查技能树传武器星级
local function CanOperate(type,id,condition)
	condition = condition or 0;

	local hero = module.HeroModule.GetManager():Get(id);
	if not hero then
		return false;
	end
	
	local switchConfig = loadSkillSwitchConfig(id);
	if type == 2 and switchConfig then
		local diamIndex = hero.property_value == 0 and 1 or hero.property_value;
		type = switchConfig[diamIndex].type;
	end

	local data = GetTalentData(hero.uuid, type);
	local all_addPoint = 0;
	for i,v in pairs(data) do
		all_addPoint = all_addPoint + v;
	end
	if type == 1 then
		return math.floor(condition/5) > all_addPoint;
	elseif type == 2 then
		return math.floor(condition/5) > all_addPoint;
	elseif type == 4 or type == 5 then
		local _hero=condition
		local talentId   = type==4 and _hero.roletalent_id1 or _hero.roletalent_id2


		local config=GetTalentConfig(talentId)

		local talentdata =GetTalentData(_hero.uuid, type);
		local Cfg=nil
		local point =0
		for i=#talentdata,1,-1 do
			if talentdata[i]~=0 then
				Cfg=config[i]
				point =talentdata[i]
				break
			end
		end

		if Cfg then--加过点
			local limit=Cfg.point_limit
			local cfg_row =Cfg and GetTalentConfigByGroup(talentId,Cfg.group,Cfg.sub_group+1)
			--达到最大级取下一级
			local id=point<limit and Cfg.id or (cfg_row and cfg_row[1].id)
			local consume_value_1=point<limit and Cfg.consume_value_1 or (cfg_row and cfg_row[1].consume_value_1)
			local consume_inc_1=Cfg.consume_inc_1
			local nextCosume=point<limit and consume_value_1+consume_inc_1*point or consume_value_1

			local ItemCount=_hero.items[Cfg.consume_id_1] and _hero.items[Cfg.consume_id_1] or 0
			if point<limit then
				return ItemCount>=nextCosume and Cfg.depend_level<=_hero.level
			else
				return cfg_row and ItemCount>=nextCosume and cfg_row[1].depend_level<=_hero.level
			end
		else
			local nextCosume=config[1].consume_value_1
			local ItemCount=_hero.items[config[1].consume_id_1] and _hero.items[config[1].consume_id_1] or 0
			return ItemCount>=nextCosume and config[1].depend_level<=_hero.level
		end 
	end
	return false;
end

--查询天赋
EventManager.getInstance():addListener("server_respond_22", function(event, cmd, data)
	--[sn, result, type, id, data, uuid]
	-- print("server_respond_22"..sprinttb(data))
	local sn = data[1];
	local result = data[2];
	local talenttype = data[3];-- type  4  5 为称号
	local roleid = data[4];
	local talentdata = data[5];
	local uuid = data[6];

	local pid = sn2pid[sn];
	sn2pid[sn] = nil;

	if not pid then
		return;
	end

	if result == 0 then
		if talenttype == 0 then
			return UpdatePlayerTalentData(pid, data[4])
		end

		UpdateCharacterTalentData(pid, talenttype, roleid, talentdata, uuid);

		if (SnData[sn] and  SnData[sn].dispatch) or SnData[sn] == nil then
			DispatchEvent("GIFT_INFO_CHANGE",sn2pid[sn],uuid,talenttype,true);
		end
	else
		print("天赋查询失败result",roleid, result);
	end

end);

--更新天赋
local workManUuid={}
EventManager.getInstance():addListener("server_respond_26", function(event, cmd, data)
	local sn = data[1];
	local result = data[2];
	if result == 0 then
		print("更新成功",sprinttb(Sn2ProductTitle[sn]))
		local uuid =Sn2ProductTitle[sn].uuid
		local type=Sn2ProductTitle[sn].type

		Sn2ProductTitle[sn]=nil
		if uuid and type and type==5 then
			--print("改变生产称号11077=",uuid)
			local _sn=NetworkService.Send(11077,{nil,uuid});
			workManUuid[_sn]=uuid
		end
	else
		print("更新失败result", result);
	end
end);

--天赋信息推送
EventManager.getInstance():addListener("server_notify_52", function(event, cmd, data)
	--[id, uuid, type, data]
	-- print("===397=server_notify_52="..sprinttb(data))
	local roleid = data[1];
	local role_uuid = data[2];
	local talenttype = data[3];
	local talentdata = data[4];

	print("天赋信息推送", sprinttb(data))
	local pid = playerModule.GetSelfID();

	UpdateCharacterTalentData(pid, talenttype, roleid, talentdata, role_uuid);

	DispatchEvent("GIFT_INFO_CHANGE",pid,role_uuid,talenttype,false);
end);

EventManager.getInstance():addListener("server_respond_11078", function(event, cmd, data)
	print("respond_11078=",sprinttb(data))
	local sn = data[1];
	local result = data[2];
	if result == 0 then
		local uuid=workManUuid[sn]
		workManUuid[sn]=nil
		if uuid then
			DispatchEvent("WORKMAN_TITLE_CHANGE",uuid);
		end
	else
		print("C_MANOR_MANUFACTURE_WORKMAN_TITLE_CHANGE_RESPOND err",result)
	end
end)

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event)
	GetTalentData();
end)

--称号挑战
-- self.hero,cfg.name,cfg.item_id,item_Count
local command_running=0
local function StartTitleFight(uuids,hero,cfg,UI)
	command_running = os.time() + 5;
	print("start request")
	coroutine.resume(coroutine.create( function()
		local data =NetworkService.SyncRequest(16001, {nil,cfg.fight_id,1,uuids});
		command_running =0
		print("finished request")
		local sn, result, fight_id, fight_data = data[1], data[2], data[3], data[4];
		
		SceneStack.Push('battle', 'view/battle.lua', {
		fight_id =fight_id, 
		fight_data =fight_data,
		ui=UI,
		callback = function(win, heros, fightid, starInfo, input_record)
			if win then
				command_running = os.time() + 5;
				print("start request_CHECK_RESULT")
				coroutine.resume(coroutine.create( function()
					local starValue = 0;
					for k, v in ipairs(starInfo or {}) do
						if v then
							starValue = starValue | (1 << ((k-1)*2));
						end
					end
					local data = NetworkService.SyncRequest(16005, {nil,cfg.fight_id,starValue,input_record})
					command_running = 0;
					print("check result", sprinttb(data));
					EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", data[3], data[4]);
				end));

				local prefab = SGK.ResourcesManager.Load("prefabs/base/Title_Fight_Result.prefab");
				local obj =UnityEngine.Object.Instantiate(prefab);
				EventManager.getInstance():dispatch("ADD_OBJECT_TO_FIGHT_RESULT", obj);
				CS.SGK.UIReference.Setup(obj.gameObject)[SGK.LuaBehaviour]:Call("UpdateResult",{hero,cfg,win})
			end
		end});
	end))
end

local function CalcTalentGroupPoint(talent_data, talent_id)
	local t = {};
	local cfg = GetTalentConfig(talent_id);
	for _, v in pairs(cfg) do
		t[v.group] = (t[v.group] or 0) + (talent_data[v.id] or 0)
	end
	return t;
end

local function GetCurrentTitleDesc(hero,talentType)--获取英雄当前称号描述 默认生产称号
	local talentType=talentType and talentType or 5
	local talentdata =GetTalentData(hero.uuid, talentType);
	local Cfg=nil
	local Idx=0

	local talentId   = talentType==4 and hero.roletalent_id1 or hero.roletalent_id2
	local config=GetTalentConfig(talentId)
	for i=#talentdata,1,-1 do
		if talentdata[i]~=0 then
			Cfg=config[i]
			Idx=talentdata[i]
			break
		end
	end
	local titleDesc={}
	if Cfg then
		local isperc = false
		if string.find(Cfg.desc, "%%%%") ~= nil then
			isperc = true;
		end
		local _value={}
		for i=1,4 do
			table.insert(_value,tostring(isperc and ((Cfg["init_value"..i]+Cfg["incr_value"..i]*(Idx-1))/100) or Cfg["init_value"..i]+Cfg["incr_value"..i]*(Idx-1)))
		end
		titleDesc={Cfg.name,string.format(Cfg.desc,_value[1],_value[2],_value[3],_value[4])}
	else
		titleDesc={"未转职","暂无生产增益"}
	end
	return titleDesc
end

local function GetSkillTreeData(uuid, weaponId, talentid)
	local talentdata = GetTalentData(uuid, talentid);
	if talentdata then
		return CalcTalentGroupPoint(talentdata, weaponId);
	end
	return {0,0,0};
end

return {
	Save = saveTalentData,

	CaclProperty = CaclProperty,
	CanOperate = CanOperate,

	GetTalentData    = GetTalentData,
	GetTalentConfig  = GetTalentConfig,
	GetTalentConfigByGroup = GetTalentConfigByGroup,

	GetTitleFightConfig = loadTitleFightConfig,

	LoadSkillShowConfig  = loadSkillShowConfig,
	GetSkillDetailDes    = GetSkillDetailDes,
	GetSkillMultipleDetailDes = GetSkillMultipleDetailDes,
	GetSkillSwitchConfig = loadSkillSwitchConfig,

	CalcTalentGroupPoint = CalcTalentGroupPoint,

	StartTitleFight=StartTitleFight,--称号挑战
	GetCurrentTitleDesc=GetCurrentTitleDesc,--获取英雄当前称号描述
    GetSkillTreeData = GetSkillTreeData,
}
