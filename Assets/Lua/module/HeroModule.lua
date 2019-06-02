local class = require "utils.class"
local Property = require "utils.Property"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local playerModule = require "module.playerModule";
local battleConfig = require "config.battle"

local HeroLevelup = require "hero.HeroLevelup"
local HeroEvo = require "hero.HeroEvo"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local HeroStar = require "hero.HeroStar"
local HeroWeaponLevelup = require "hero.HeroWeaponLevelup"
local TalentModule = require "module.TalentModule"
local EquipModule = require "module.equipmentModule"
local UserDefault = require "utils.UserDefault";
local HeroScroll = require "hero.HeroScroll"
local equipmentConfig = require "config.equipmentConfig"
local HeroWeaponStar = require "hero.HeroWeaponStar"
local InscModule = require "module.InscModule"
local HeroBuffModule = require "hero.HeroBuffModule"

local hero_raw_config = nil;
local hero_config = nil;
local hero_config_by_weapon = nil;
local hero_ext_property = nil;
local function GetHeroExtProeprty(id)
	if hero_ext_property then
		return hero_ext_property[id] or {}
	end

	hero_ext_property = {}

	DATABASE.ForEach("role_property_extension", function(row)
		local row = data_raw[i];

		local gid,type, value = row.gid, row.type, row.value;
		local property = hero_ext_property[gid];
		if property == nil then
			property = {}
			hero_ext_property[gid] = property
		end

		property[type] = (property[type] or 0) + value;
	end)

	return hero_ext_property[id] or {}
end

local function NewHeroConfig(id, cfg)
	return setmetatable({__cfg = cfg, id = id}, {__index=function(t, key)
		local value = nil;
		if key == "property" then
			value = {};

			for i = 0, 100 do
				local pk, pv = t.__cfg["type" .. i], t.__cfg["value" .. i]
				if pk == nil then
					break;
				end
				value[pk] = (value[pk] or 0) + pv;
			end

			local ext = GetHeroExtProeprty(t.id)
			for pk, pv in pairs(ext) do
				v[pk] = (v[pk] or 0) + pv;
			end
		else
			value = t.__cfg[key];
		end

		rawset(t, key, value);

		return value;
	end})
end

local function fillAllHeroConfig()
	print("!!!!!!!! fillAllHeroConfig !!!!!!")
	for id, cfg in pairs(hero_raw_config) do
		local hero = NewHeroConfig(id, cfg);
		hero_config[id] = hero;
		hero_config_by_weapon[cfg.weapon] = hero;
	end

	setmetatable(hero_config, nil);
	setmetatable(hero_config_by_weapon, nil);
end

local function LoadHeroConfig()
	hero_raw_config = hero_raw_config or LoadDatabaseWithKey("role", "id");

	hero_config = setmetatable({}, {__index = function(t, id)
		local cfg = hero_raw_config[id]
		if not cfg then
			return;
		end

		local hero = NewHeroConfig(id, cfg);
		rawset(hero_config, id, hero);
		rawset(hero_config_by_weapon, cfg.weapon, hero);
		return hero;
	end, __pairs=function(t, key)
		fillAllHeroConfig();
		return next, t, nil
	end});

	hero_config_by_weapon = setmetatable({}, {__index=function(t, key)
		fillAllHeroConfig();
		return hero_config_by_weapon[key];
	end, __pairs=function(t)
		fillAllHeroConfig();
		return next, t, nil
	end});
end

local function GetConfig(id)
	if hero_config == nil then
		LoadHeroConfig();
	end

	if id == nil then
		return hero_config;
	end

	return hero_config[id];
end

local HeroInfoConf = nil
local function GetInfoConfig(id)
	HeroInfoConf = HeroInfoConf or LoadDatabaseWithKey("role_info", "id");

	if id then
		return HeroInfoConf[id]
	end
	return HeroInfoConf;
end

local lineup_talk = nil;
local function GetLineupTalk(id)
    if lineup_talk == nil then
        lineup_talk = {};
        DATABASE.ForEach("lineup_talking", function(row)
			lineup_talk[row.role_id] = {};
			for i=1,3 do
				lineup_talk[row.role_id][i] = {type = row["talking_frametype"..i], des = row["talking_des"..i]}
			end
        end)
    end
    return lineup_talk[id];
end

local function GetConfigByWeapon(id)
	if hero_config == nil then
		LoadHeroConfig();
	end

	if id == nil then
		return hero_config_by_weapon;
	end

	return hero_config_by_weapon[id];
end

local function GetWeaponConfig(id)
	local wcfg = HeroWeaponLevelup.LoadWeapon();
	return wcfg and wcfg[id].cfg
end

local function GetWeaponConfigByHeroID(id)
	local cfg = GetConfig(id)
	if cfg then
		local wcfg = HeroWeaponLevelup.LoadWeapon();
		return wcfg and wcfg[cfg.weapon] and wcfg[cfg.weapon].cfg
	end
end

------------------------------
local Hero = class()
function Hero:_init_(id,pid)
	self.cfg = GetConfig(id)
	self.id = id
	self.pid = pid
	self.props = {};
	self._server_data_ = {}
	self.prop_change = true;
	self.curCapacity = 0;
	self.items = {};

	self.showMode=module.HeroHelper.GetDefaultMode(id)

	Hero.Update(self, {id}, true)
end

local HeroBase = {
	CaclProperty = function (hero)
		return GetConfig(hero.id).property;
	end
}

--时装属性
local HeroSuit = {
	CaclProperty = function (hero)
		local _suitProperty={}
		if hero.uuid~=0 and hero.items and next(hero.items) then
			local suitCfg= module.HeroHelper.GetCfgByShowMode(hero.id,hero.showMode)
			if suitCfg then
				if tonumber(suitCfg.effect_type) ~=0 then
                    _suitProperty={[tonumber(suitCfg.effect_type)]=tonumber(suitCfg.effect_value)}
				end
			else
				ERROR_LOG(hero.id,hero.showMode)
			end
		end
		return _suitProperty;
	end
}

local function ReloadProperty(server_data)
	local modules = {
		HeroBase,
		HeroSuit,
		HeroLevelup,
		HeroEvo,
		HeroWeaponStage,
		HeroStar,
		HeroWeaponStar,
		HeroWeaponLevelup,
		EquipModule,
		InscModule,
		TalentModule,
		HeroBuffModule,
	};

	local property_list = {};
	-- merge property
	for xx, m in ipairs(modules) do
		local property = m.CaclProperty(server_data);
		for k, v in pairs(property) do
			property_list[k] = (property_list[k] or 0) + v;
		end
	end

	if server_data.id == 11000 then
		local diamond_index = server_data.property_value
		if diamond_index == nil or diamond_index == 0 then
			diamond_index = 1
		end
		property_list[21000] = diamond_index;
	end

	return Property(property_list), property_list;
end

function Hero:_getter_(k)
	if k == "capacity" then
		local _capacity = 0;
		-- ERROR_LOG(self.cfg.name, "战力变化",  self.prop_change);
		if self.prop_change then
			_capacity = self.props[k];
			self.curCapacity = _capacity;
			-- ERROR_LOG(self.cfg.name, "重新计算战力", _capacity);
			self.prop_change = false;
		else
			_capacity = self.curCapacity;
		end
		return _capacity;
	elseif k == "icon" then--hero 时装对应的icon
		return module.HeroHelper.GetShowIcon(self.id) or self.cfg.icon
	elseif k == "mode" then
		return self.showMode
	end
	return self._server_data_[k] or self.cfg[k] or self.props[k];
end

function Hero:_setter_(k, v)
	if k == "props" then
		assert("can't set peops of player'")
	end

	if self._server_data_[k] ~= nil then
		assert(self._server_data_[k] == nil, "can't change _server_data_ of hero " .. k .. " " .. debug.traceback())
	elseif self.props[k] ~= nil then
		assert(self.props[k] == nil, "can't change property of hero")
	else
		rawset(self, k, v);
	end
end

function Hero:ReCalcProperty(init)
	local last_capacity = self.capacity or 0;
	self.props, self.property_list = ReloadProperty(self);
	self.curCapacity = self.props.capacity;
	if last_capacity ~= 0 and init ~= nil and not init and last_capacity ~= self.capacity and self.pid == playerModule.GetSelfID() then
		-- print("变化", debug.traceback())
		showCapacityChange(last_capacity, self.capacity);
	end
end

function Hero:Update(data, init)
	local id         = data[1]
	local level      = data[2] or 1
	local stage_slot = BIT(data[3] or 0)
	local stage      = data[4] or 0
	local star       = data[5] or 0
	local exp        = data[6] or 0

	local weapon_star = data[7] or 0;
	local weapon_stage = data[8] or 0
	local weapon_stage_slot = BIT(data[9] or 0)
	local weapon_level = data[10] or 1;
	local weapon_exp = data[11] or 0;
	local placeholder = data[12] or 0;
	local weapon_id = self.cfg.weapon;
	local uuid = data[13] or 0;
--[[
	local skill1 = data[14]
	local skill2 = data[15]
	local skill3 = data[16]
	local skill4 = data[17]

	local property_type = data[18]
--]]

	local property_value = data[19] or 0-- 1,2,3,4,5,6,7
	local time = data[20] or 0;
	self.property_list = {}

	self._server_data_ = {
		id = id,
		placeholder= placeholder,
		level = level,
		stage_slot = stage_slot,
		stage = stage,
		star = star,
		exp = exp,

		weapon_id = weapon_id,
		weapon_star = weapon_star,
		weapon_stage = weapon_stage,
		weapon_stage_slot = weapon_stage_slot,
		weapon_level = weapon_level,
		weapon_exp = weapon_exp,
		uuid = uuid,
		property_value = property_value,
		time = time,
	};

	local last_capacity = self.capacity or 0;
	self.props, self.property_list = ReloadProperty(self._server_data_);
	self.curCapacity = self.props.capacity;
	if last_capacity ~= 0 and not init and  last_capacity ~= self.capacity and self.pid == playerModule.GetSelfID() then
		-- print("变化", debug.traceback())
		showCapacityChange(last_capacity, self.capacity);
	end
end

function Hero:EnhanceProperty(level, stage, star, stage_slot, wplevel, wpstage, wpstar ,weapon_stage_slot)
	level = level or 0;
	stage = stage or 0;
	star = star or 0;
	wplevel = wplevel or 0;
	wpstage = wpstage or 0;
	wpstar = wpstar or 0;

	local property_list = {}

	local server_data_ = {
		id = self.id,
		level = self.level + level,
		stage_slot = stage_slot or self.stage_slot,
		stage = self.stage + stage,
		star = self.star + star,
		weapon_level = self.weapon_level + wplevel;
		weapon_star = self.weapon_star + wpstar;
		weapon_stage = self.weapon_stage + wpstage,
		weapon_stage_slot = weapon_stage_slot or self.weapon_stage_slot,
		weapon_id = self.weapon;
		uuid = self.uuid,
		items = self.items,
		showMode = self.showMode,
	}

	local property = {};
	property.props, property.property_list = ReloadProperty(server_data_);
	return property;
end

function Hero:GetWeaponProp(level, stage, star, stage_slot, wplevel, wpstage, wpstar ,weapon_stage_slot)
	level = level or 0;
	stage = stage or 0;
	star = star or 0;
	wplevel = wplevel or 0;
	wpstage = wpstage or 0;
	wpstar = wpstar or 0;

	local property_list = {}

	local server_data = {
		id = self.id,
		level = self.level + level,
		stage_slot = stage_slot or self.stage_slot,
		stage = self.stage + stage,
		star = self.star + star,
		weapon_level = self.weapon_level + wplevel;
		weapon_star = self.weapon_star + wpstar;
		weapon_stage = self.weapon_stage + wpstage,
		weapon_stage_slot = weapon_stage_slot or self.weapon_stage_slot,
		weapon_id = self.weapon;
	}

	local property = {};
	local modules = {
		HeroWeaponStage,
		HeroWeaponStar,
		HeroWeaponLevelup,
		InscModule,
		TalentModule,
	};


	local property_list = {};
	-- merge property
	for xx, m in ipairs(modules) do
		local prop = m.CaclProperty(server_data,true);
		for k, v in pairs(prop) do
			property_list[k] = (property_list[k] or 0) + v;
		end
	end

	property.props = Property(property_list);
	property.property_list = property_list;

	return property;
end

-- function Hero:CanOperate()
-- 	local modules = {
-- 		HeroLevelup,
-- 	};
-- 	for i,v in ipairs(modules) do
-- 		local canOperate = v.CanOperate(self);
-- 		if canOperate then
-- 			return true;
-- 		end
-- 	end
-- 	return false;
-- end

local coroutineList = {}
local sn2pid = {};
local function GetHeroListFromServer(pid)
	local sn = NetworkService.Send(9,{nil, pid});
	if sn ~= nil then
		sn2pid[sn] = pid;
	end
    if coroutine.isyieldable() then
        coroutineList[sn] = { time = os.time(), co = coroutine.running() }
        return coroutine.yield()
    end
end

local function GetHeroItemFromServer()
	NetworkService.Send(74);
end

local HeroManager = class()

function HeroManager:_init_(pid)
	self.heros = {};
	self.pid = pid;
	self.online = {}
	self.herosByUuid = {};
	self.heroFashionSuit = {};

	GetHeroListFromServer(self.pid);

	if pid == playerModule.GetSelfID() then
		GetHeroItemFromServer(self.pid);
	end
end

function HeroManager:UpdateHeroInfo(data, init)
	local id = data[1];

	local cfg = GetConfig(id);
	if not cfg then
		return
	end
	local NewHero = false
	local hero = self.heros[id];
	if hero == nil then
		NewHero = true
		hero = Hero(id,self.pid);
		self.heros[id] = hero;
		if not init then
			GetItemTips(id,1,42);
			--获得hero提示
			module.ChatModule.SystemChat(module.playerModule.Get().id,42,id,1)
		end
	end

	local old_placeholder = self.heros[id].placeholder;
	if old_placeholder > 0 and self.online[old_placeholder] == id then
		self.online[old_placeholder] = 0;
	end

	local oldExp = self.heros[id].exp
	local oldLv = self.heros[id].level

	self.heros[id].prop_change = true;
	hero:Update(data, init);

	if self.heros[id].exp > oldExp then
		DispatchEvent("HeroExpInfoChange",{id,oldExp})
	end

    if not init and self.pid == module.playerModule.GetSelfID() and old_placeholder ~= self.heros[id].placeholder then
        DispatchEvent("LOCAL_PLACEHOLDER_CHANGE", {id = id})
    end

	if  id == 11000 and self.pid == module.playerModule.GetSelfID() then
		DispatchEvent("PLAYER_INFO_CHANGE", self.pid)

		if NewHero == false and self.heros[id].exp > oldExp then
			-- showDlgError(nil,"主角增加经验："..(math.ceil(self.heros[id].exp-oldExp)))
			if self.heros[id].level > oldLv then
				GetActorLvUpData(oldLv,self.heros[id].level,oldExp,self.heros[id].exp)
				
				DispatchEvent("PLAYER_LEVEL_UP",self.heros[id].level,oldLv)

				module.playerModule.updatePlayerLevel(module.playerModule.GetSelfID(),self.heros[id].level)
				if module.TeamModule.GetTeamInfo().id > 0 then
					module.TeamModule.SyncTeamData(108, self.heros[id].level);
				end
			end
		end
	
		if not init and self.heros[id].exp>oldExp then--进入游戏时刷新经验不显示
			GetActorExpChangeData(oldExp,self.heros[id].exp)
			--获得主角经验通知
			module.ChatModule.SystemChat(module.playerModule.Get().id,utils.ItemHelper.TYPE.ITEM,90000,self.heros[id].exp-oldExp)
		end
	end

	if hero.placeholder > 0 then
		self.online[hero.placeholder] = id;
	end

	self.herosByUuid[hero.uuid] = hero;

	return self.heros[id];
end

function HeroManager:Add(gid)
	NetworkService.Send(19, {nil, tonumber(gid)});
end

function HeroManager:Get(id)
	if not id then
		return self.heros;
	end
	return self.heros[id];
end

function HeroManager:GetByUuid(uuid)
	return self.herosByUuid[uuid];
end

function HeroManager:SetHeroChange(id,value)
	if self.heros[id] then
		self.heros[id].prop_change = value;
	end
end

function HeroManager:GetCapacity()
	local value = 0;
	for i = 1, 5 do
		local id = self.online[i];
		local hero = self:Get(id or 0);
		if hero then
			value = value + hero.capacity;
		end
	end
	return math.floor(value);
end

function HeroManager:GetHeroFashionSuit(uuid, refresh)
	if refresh or self.heroFashionSuit[uuid] == nil then
		local sn = NetworkService.Send(96, {nil, self.pid, uuid});
		sn2pid[sn] = {pid = self.pid, uuid = uuid};
	else
		return self.heroFashionSuit[uuid]
	end
end

-- function HeroManager:LevelUp(gid,count)
-- 	if self.heros[gid] == nil then
-- 		print("hero not exists");
-- 		return nil;
-- 	end
-- 	NetworkService.Send(70,{nil, tonumber(gid), tonumber(count)});
-- end
function HeroManager:SwitchDiamond(gid, index)
	if self.heros[gid] == nil then
		print("hero not exists");
		return nil;
	end
	print("切换钻石",gid, index)
	local sn = NetworkService.Send(86,{nil, self.heros[gid].uuid, index});
	sn2pid[sn] = {uuid = self.heros[gid].uuid, index = index};
end

function HeroManager:AddExp(gid, exp, exptype)
	exptype = exptype or 0
	print("添加经验",gid, exp, exptype);
	if self.heros[gid] == nil then
		print("hero not exists");
		return nil;
	end

	local sn = NetworkService.Send(11,{nil, tonumber(gid), tonumber(exp), exptype});
	sn2pid[sn] = {uuid = self.heros[gid].uuid, id = gid};
end

function HeroManager:AddRoleStar(gid, idx)
	if not self.heros[gid] then
		print("hero not exists");
		return nil;
	end

	local sn = NetworkService.Send(13,{nil, tonumber(gid), idx});
	sn2pid[sn] = {uuid = self.heros[gid].uuid, id = gid};
end

function HeroManager:AddRoleStage(gid,idx)
	if not self.heros[gid] or idx == nil then
		print("hero not exists");
		return nil;
	end

	local sn = NetworkService.Send(15,{nil, tonumber(gid),idx});
	sn2pid[sn] = {uuid = self.heros[gid].uuid, id = gid};
end

function HeroManager:AddRoleSlot(gid,idx)
	if not self.heros[gid] or idx == nil then
		print("hero not exists");
		return nil;
	end

	local index = {0,0,0};
	local sn = NetworkService.Send(17,{nil, tonumber(gid),0,idx});
	sn2pid[sn] = {uuid = self.heros[gid].uuid, id = gid};
end

function HeroManager:MoveDEBUG(id, pos)
    local hero = self.heros[id]
    if not hero then
        return;
    end

    if hero.placeholder == pos then
        return;
    end

    local o = hero.placeholder;
    local target = self.online[pos];

    hero._server_data_.placeholder = pos;
    if pos ~= 0 then
        self.online[pos] = hero.id;
    end

    if target then -- exchange target
        target._server_data_.placeholder = o;
        if o ~= 0 then
            self.online[o] = target.id;
        end
    end

    DispatchEvent("HERO_INFO_CHANGE", hero.id)

    if target then
        DispatchEvent("HERO_INFO_CHANGE", target.id)
    end
end

function HeroManager:GetByPos(pos)
	if #self.online == 0 then
		--TODO: remove
		for pos, id in ipairs({11001, 11003, 11004, 11005, 11006}) do
			self.heros[id] = self.heros[id] or Hero(id);
			self:MoveDEBUG(id, pos);
		end
	end
	return self.heros[ self.online[pos] ];
end

function HeroManager:GetFormation()
	local online = {}
	for i =  1, 5 do
		if i == 1 then
			online[i] = self.online[i] or 11000;
		else
			online[i] = self.online[i] or 0;
		end
	end
	return online;
end

function HeroManager:SetFormation(gids)
	local info = {};

	print("HeroManager:ChangeFormation")
	print("old", table.unpack(self.online))
	print("new", table.unpack(gids))

	local maps = {};
	for i, gid in pairs(gids) do
		if gid ~= 0 then
			maps[gid] = {0, i};
		end
	end
	for i, gid in pairs(self.online) do
		if gid ~= 0 then
			maps[gid] = maps[gid] or {i, 0};
			maps[gid][1] = i;
		end
	end
	for gid, v in pairs(maps) do
		if  v[1] ~= v[2] then
			table.insert(info, {gid, v[2]});
		end
	end
	if #info == 0 then
		print("formation info not change");
		return;
	end

	local sn = NetworkService.Send(31, {nil, info});
	sn2pid[sn] = {online = gids};
end

function HeroManager:GetAll(isRefresh)
	if isRefresh then
		GetHeroListFromServer(self.pid);
		if self.pid == playerModule.GetSelfID() then
			GetHeroItemFromServer(self.pid);
		end
	end
	return self.heros;
end

function HeroManager:GetPrefixSuit(Heroid)
	--前缀石头套装
	local PrefixSuitList = {}
	-- local equiplist = EquipModule.GetHeroEquip()[Heroid] or {};
	for suitIdx=0,5 do
		for i = 1,6 do
			local equip =EquipModule.GetHeroEquip(Heroid,i+6,suitIdx)
			if equip and equip.pre_property1_key ~= 87000 and equip.pre_property1_key ~=0 then
				local HeroScrollConf = HeroScroll.GetScrollConfig(equip.pre_property1_key)
				if HeroScrollConf then
					local suitCfg = HeroScroll.GetSuitConfig(HeroScrollConf.suit_id);
					if PrefixSuitList[suitIdx] and PrefixSuitList[suitIdx][HeroScrollConf.suit_id] then
						PrefixSuitList[suitIdx][HeroScrollConf.suit_id].IdxList[#PrefixSuitList[suitIdx][HeroScrollConf.suit_id].IdxList+1] = i

						table.insert(PrefixSuitList[suitIdx][HeroScrollConf.suit_id].qualityTab,HeroScrollConf.quality)
						table.sort(PrefixSuitList[suitIdx][HeroScrollConf.suit_id].qualityTab, function(a, b)
							return a < b
						end)

						local quality2=1
						local quality4=1
						if #PrefixSuitList[suitIdx][HeroScrollConf.suit_id].IdxList>=2 then
							quality2=PrefixSuitList[suitIdx][HeroScrollConf.suit_id].qualityTab[#PrefixSuitList[suitIdx][HeroScrollConf.suit_id].qualityTab-1]
							quality4=quality2
						end
						if #PrefixSuitList[suitIdx][HeroScrollConf.suit_id].IdxList>=4 then
							quality4=PrefixSuitList[suitIdx][HeroScrollConf.suit_id].qualityTab[#PrefixSuitList[suitIdx][HeroScrollConf.suit_id].qualityTab-3]
						end
						PrefixSuitList[suitIdx][HeroScrollConf.suit_id].quality={[2]=quality2,[4]=quality4}
						PrefixSuitList[suitIdx][HeroScrollConf.suit_id].Type = {{suitCfg[2][quality2].type1,suitCfg[2][quality2].type2},
																		{suitCfg[4][quality4].type1,suitCfg[4][quality4].type2},
																		}
						PrefixSuitList[suitIdx][HeroScrollConf.suit_id].Value = {{suitCfg[2][quality2].value1,suitCfg[2][quality2].value2},
																	{suitCfg[4][quality4].value1,suitCfg[4][quality4].value2}
																	}
						PrefixSuitList[suitIdx][HeroScrollConf.suit_id].Desc = {suitCfg[2][quality2].desc,suitCfg[4][quality4].desc}
					else
						if suitCfg then
							PrefixSuitList[suitIdx]=PrefixSuitList[suitIdx] or {}
							PrefixSuitList[suitIdx][HeroScrollConf.suit_id] = {
								EquipId = equip.pre_property1_key,
								IdxList = {i},
								name=suitCfg[2][HeroScrollConf.quality].name,
								icon=suitCfg[2][HeroScrollConf.quality].icon,

								qualityTab={HeroScrollConf.quality},
								quality={[2]=HeroScrollConf.quality,[4]=HeroScrollConf.quality},
								Type = {{suitCfg[2][HeroScrollConf.quality].type1,suitCfg[2][HeroScrollConf.quality].type2},
										{suitCfg[4][HeroScrollConf.quality].type1,suitCfg[4][HeroScrollConf.quality].type2}
										},
								Value = {{suitCfg[2][HeroScrollConf.quality].value1,suitCfg[2][HeroScrollConf.quality].value2},
										{suitCfg[4][HeroScrollConf.quality].value1,suitCfg[4][HeroScrollConf.quality].value2}
										},
								Desc = {suitCfg[2][HeroScrollConf.quality].desc,suitCfg[4][HeroScrollConf.quality].desc}
							}
						end
					end
				end
			end
		end
	end
	return PrefixSuitList
end

function HeroManager:GetEquipSuit(Heroid)
	--装备本身套装
	local EquipSuitList = {}
	for suitIdx=0,5 do--hero 身上的6套 装备
		for i = 1,6 do
			local equip =EquipModule.GetHeroEquip(Heroid,i+6,suitIdx)
			if equip then
				local cfg = equipmentConfig.EquipmentTab(equip.id)
				if cfg.suit_id~=0 then
					local suitCfg = HeroScroll.GetSuitConfig(cfg.suit_id);			
					if EquipSuitList[suitIdx] and EquipSuitList[suitIdx][cfg.suit_id] then
						EquipSuitList[suitIdx][cfg.suit_id].IdxList[#EquipSuitList[suitIdx][cfg.suit_id].IdxList +  1] = i

						table.insert(EquipSuitList[suitIdx][cfg.suit_id].qualityTab,cfg.quality)
						table.sort(EquipSuitList[suitIdx][cfg.suit_id].qualityTab, function(a, b)
							return a < b
						end)

						local quality2,quality4,quality6 = cfg.quality,cfg.quality,cfg.quality
						if #EquipSuitList[suitIdx][cfg.suit_id].IdxList>=2 then
							quality2 = EquipSuitList[suitIdx][cfg.suit_id].qualityTab[#EquipSuitList[suitIdx][cfg.suit_id].qualityTab-1]
						end
						if #EquipSuitList[suitIdx][cfg.suit_id].IdxList>=4 then
							quality4 = EquipSuitList[suitIdx][cfg.suit_id].qualityTab[#EquipSuitList[suitIdx][cfg.suit_id].qualityTab-3]
						end
						if #EquipSuitList[suitIdx][cfg.suit_id].IdxList>=6 then
							quality6 = EquipSuitList[suitIdx][cfg.suit_id].qualityTab[#EquipSuitList[suitIdx][cfg.suit_id].qualityTab-5]
						end
						
						EquipSuitList[suitIdx][cfg.suit_id].suitIcon = {[2]=suitCfg[2][quality2].icon,[4] = suitCfg[4] and suitCfg[4][quality4].icon,[6] = suitCfg[6] and suitCfg[6][quality6].icon}
						
						EquipSuitList[suitIdx][cfg.suit_id].quality = {[2]=quality2,[4]=quality4,[6]=quality6}
						
						EquipSuitList[suitIdx][cfg.suit_id].Type = {
														{suitCfg[2][quality2].type1,suitCfg[2][quality2].type2},
														{suitCfg[4] and suitCfg[4][quality4].type1 or 0,suitCfg[4] and suitCfg[4][quality4].type2 or 0},
														{suitCfg[6] and suitCfg[6][quality6].type1 or 0,suitCfg[6] and suitCfg[6][quality6].type2 or 0},}
						
						EquipSuitList[suitIdx][cfg.suit_id].Value = {
														{suitCfg[2][quality2].value1,suitCfg[2][quality2].value2},
														{suitCfg[4] and suitCfg[4][quality4].value1 or 0,suitCfg[4] and suitCfg[4][quality4].value2 or 0},
														{suitCfg[6] and suitCfg[6][quality6].value1 or 0,suitCfg[6] and suitCfg[6][quality6].value2 or 0},}

						EquipSuitList[suitIdx][cfg.suit_id].Desc = {suitCfg[2][quality2].desc,suitCfg[4] and suitCfg[4][quality4].desc,suitCfg[6] and suitCfg[6][quality6].desc}
					else
						if suitCfg and suitCfg[2] and suitCfg[2][cfg.quality] then
							EquipSuitList[suitIdx]=EquipSuitList[suitIdx] or {}
							EquipSuitList[suitIdx][cfg.suit_id] = {
								IdxList = {i},
								name = suitCfg[2][cfg.quality].name,
								icon = suitCfg[2][cfg.quality].icon,
								suitIcon = {[2]=suitCfg[2][cfg.quality].icon,[4]=suitCfg[4] and suitCfg[4][cfg.quality].icon,[6]= suitCfg[6] and suitCfg[6][cfg.quality].icon},
								qualityTab={cfg.quality},
								quality={[2]=cfg.quality,[4]=cfg.quality,[6]=cfg.quality},
								Type = {{suitCfg[2][cfg.quality].type1,suitCfg[2][cfg.quality].type2},
										{suitCfg[4] and suitCfg[4][cfg.quality].type1 or 0,suitCfg[4] and suitCfg[4][cfg.quality].type2 or 0},
										{suitCfg[6] and suitCfg[6][cfg.quality].type1 or 0,suitCfg[6] and suitCfg[6][cfg.quality].type2 or 0}
										},
								Value = {
											{suitCfg[2][cfg.quality].value1,suitCfg[2][cfg.quality].value2},
											{suitCfg[4] and suitCfg[4][cfg.quality].value1 or 0,suitCfg[4] and suitCfg[4][cfg.quality].value2 or 0},
											{suitCfg[6] and suitCfg[6][cfg.quality].value1 or 0,suitCfg[6] and suitCfg[6][cfg.quality].value2 or 0}
										},
								Desc = {suitCfg[2][cfg.quality].desc,suitCfg[4] and suitCfg[4][cfg.quality].desc,suitCfg[6] and suitCfg[6][cfg.quality].desc}
							}
						end
					end
				end
			end
		end
	end
	return EquipSuitList
end

local managers = {}
local function GetManager(pid)
	if pid == nil then
		if playerModule.GetSelfID() ~= nil then
			pid = playerModule.GetSelfID();
		else
			pid = 0;
		end
	end
	if managers[pid] == nil then
		managers[pid] = HeroManager(pid);
	end
	return managers[pid]
end

local function GetSortHeroList(type) --0 全部英雄 1 已拥有的英雄
	local type = type or 0;
	local pid = playerModule.Get().id;
	local manager = GetManager(pid);
	local cfg = GetConfig();
	local herolist = {};
	local state = {};
	for k,v in pairs(cfg) do
		local hero = manager:Get(v.id);
		if hero or type == 0 then
			if hero then
				state[v.id] = 1;
			else
				state[v.id] = 0;
			end
			table.insert(herolist, hero or v);
		end
	end

	local online = manager:GetFormation();
	for i,v in ipairs(online) do
		if state[v] ~= nil then
			state[v] = 10;
		end
	end
	state[11000] = 20;

	table.sort(herolist, function ( a,b )
		if state[a.id] ~= state[b.id] then
			return state[a.id] > state[b.id]
		end

		if a.capacity ~= nil and b.capacity ~= nil then
			return a.capacity >  b.capacity
		end

		return a.id <  b.id;
	end)

	return herolist;
end

local function GetAssistList()
	local list = GetManager():GetAll()
	local assist_list = {};
	for k, v in pairs(list) do
		if v.placeholder == 0 then
			table.insert(assist_list, v)
		end
	end

	table.sort(assist_list, function(a, b)
		if a.capacity ~= b.capacity then
			return a.capacity > b.capacity;
		end

		if a.id ~= b.id then
			return a.id < b.id;
		end

		return a.uuid < b.uuid;
	end)

	return table.move (assist_list, 1, 5, 1, {});
end

local function GetHeroCount(time, level)
    local list = GetManager():GetAll()
	local i = 0
	time = time or 4102416000;
	level = level or 0;
	for k,v in pairs(list) do
		if v.time < time and v.level >= level then
			i = i + 1
		end
	end

    return i
end

--添加角色返回
EventManager.getInstance():addListener("server_respond_20", function(event, cmd, data)
	local err = data[2];
	if err == 0 then
		print("添加角色成功");
	else
		print("添加角色err", err);
	end
end);


--请求角色列表返回
EventManager.getInstance():addListener("server_respond_10", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local list = data[3];

	local pid = sn2pid[sn];

	local manager = GetManager(pid);

	manager.heros = {};

	if err == 0 then
		-- ERROR_LOG("角色列表返回",pid,sprinttb(list));

		for i = 1,#list do
			local hero = manager:UpdateHeroInfo(list[i], true);
		end
		DispatchEvent("HERO_INFO_CHANGE", pid);
		if pid == playerModule.GetSelfID() then
			DispatchEvent("HERO_INFO_LOADED");
		end
	else
		print("角色列表返回错误", err);
	end
    if coroutineList[sn] and coroutineList[sn].co then
        coroutine.resume(coroutineList[sn].co)
        coroutineList[sn] = nil
    end
end);

--添加角色经验返回
EventManager.getInstance():addListener("server_respond_12", function(event, cmd, data)
	local sn  = data[1];
	local err = data[2];
	if err == 0 then
		print("添加角色经验");
		DispatchEvent("HERO_LEVEL_UP")
		DispatchEvent("WORKER_INFO_CHANGE",{uuid = sn2pid[sn].uuid});
	else
		print("添加角色经验err", err);
	end
end);

-- --角色升级返回
-- EventManager.getInstance():addListener("server_respond_71", function(event, cmd, data)
-- 	local err = data[2];
-- 	if err == 0 then
-- 		print("角色升级成功");
-- 	else
-- 		print("角色升级err", err);
-- 	end
-- end);

--添加角色星级返回
EventManager.getInstance():addListener("server_respond_14", function(event, cmd, data)
	local sn  = data[1];
	local err = data[2];
	if err == 0 then
		print("添加角色星级");
        if sn2pid[sn] then
            DispatchEvent("WORKER_INFO_CHANGE",{uuid = sn2pid[sn].uuid});
        end
	else
		print("添加角色星级err", err);
	end
end);

--添加角色进阶返回
EventManager.getInstance():addListener("server_respond_16", function(event, cmd, data)
	local sn  = data[1];
	local err = data[2];
	if err == 0 then
		DispatchEvent("HERO_Stage_Succeed");
		if sn2pid[sn] then
			DispatchEvent("WORKER_INFO_CHANGE",{uuid = sn2pid[sn].uuid});
		end
		print("添加角色进阶返回");
	else
		print("添加角色进阶返回err", err);
	end
end);

--插槽装备物品
EventManager.getInstance():addListener("server_respond_18", function(event, cmd, data)
	local sn  = data[1];
	local err = data[2];
	if err == 0 then
		DispatchEvent("HERO_Stage_Equip_CHANGE");
		print("插槽装备物品成功");
	else
		print("插槽装备物品err", err);
	end
end);

EventManager.getInstance():addListener("server_respond_32", function(event, cmd, data)
	local sn  = data[1];
	local err = data[2];
	if err == 0 then
		if sn2pid[sn] and sn2pid[sn].online then
			local pid = module.playerModule.Get().id;
			local manager = GetManager(pid);
			manager.online = sn2pid[sn].online;
			DispatchEvent("PLAYER_INFO_CHANGE", pid);
		end
	end
end);


--切换英雄钻石
EventManager.getInstance():addListener("server_respond_87", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		DispatchEvent("HERO_DIAMOND_CHANGE",sn2pid[sn].index);
		-- local hero = GetManager():GetByUuid(sn2pid[sn].uuid);
		-- if hero then
		-- 	hero:ReCalcProperty(false);
		-- end
		-- print("切换英雄钻石成功",sprinttb(data));
	else
		print("切换英雄钻石err", err);
	end
end);

--角色信息推送
EventManager.getInstance():addListener("server_notify_50", function(event, cmd, data)
	local pid = module.playerModule.Get().id;
	local manager = GetManager(pid);
	manager:UpdateHeroInfo(data, false);
	-- print("角色信息推送", sprinttb(data))
	DispatchEvent("HERO_INFO_CHANGE");
end);

local function UpFashionSuitId(hero,id,_special)
	if _special==1 then--如果道具是,穿上时装
		local _cfg=module.HeroHelper.GetCfgBySuitId(id)
		if _cfg then
			hero.showMode=_cfg.showMode
			hero:ReCalcProperty(true)
		end
	end
end
-- 查询角色专属道具返回
EventManager.getInstance():addListener("server_respond_75", function(event, cmd, data)
	-- ERROR_LOG("查询角色专属道具返回",sprinttb(data))
	local err = data[2];
	if err ~= 0 then
		print("查询角色专属道具失败");
		return;
	end

	for _, v in ipairs(data[3]) do
		local uuid, id, value,_special= v[1], v[2], v[3],v[4];
		local hero = GetManager():GetByUuid(uuid);
		if hero then
			hero.items[id] = value;
			UpFashionSuitId(hero,id,_special)
		end
	end
	DispatchEvent("HERO_ITEM_CHANGE");
end);

-- 角色专属道具通知
EventManager.getInstance():addListener("server_notify_55", function(event, cmd, data)
	-- ERROR_LOG("角色专属道具变化通知",sprinttb(data))
	local uuid, id, value,_special = data[1], data[2], data[3],data[4];
	local hero = GetManager():GetByUuid(uuid);
	if hero then
		hero.items[id] = value;
		DispatchEvent("HERO_ITEM_CHANGE");
	end
end);

--request[2] = uuid request[3] = id request[4] = value request[5] = 1/0， -- 1代表穿戴，0代表未穿戴
local changeFashionSuitTab={}
local function ChangeHeroItemSpecial(uuid,id,status)
	--ERROR_LOG("change Special",uuid,id,status and 1 or 0)
	local sn = NetworkService.Send(92,{nil,uuid,id,status and 1 or 0});
	changeFashionSuitTab[sn]={uuid=uuid,id=status and id or 0}
end
--修改Items.special 返回
EventManager.getInstance():addListener("server_respond_93", function(event, cmd, data)
	--ERROR_LOG(sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err ~= 0 then
		ERROR_LOG("更改角色专属道具失败err",err);
		return;
	end
	print("时装更换成功")
	if changeFashionSuitTab[sn] then
		local uuid=changeFashionSuitTab[sn].uuid
		local suitId=changeFashionSuitTab[sn].id
		local hero = GetManager():GetByUuid(uuid);
		if hero then
			local _cfg=module.HeroHelper.GetCfgBySuitId(suitId)
			if _cfg then
				hero.showMode=_cfg.showMode
			else
				hero.showMode=module.HeroHelper.GetDefaultMode(hero.id)
			end

			GetManager():SetHeroChange(hero.id, true);
			hero:ReCalcProperty(false)
			--[[--时装变了头像跟着改变
			local selfPid=module.playerModule.GetSelfID()
		    if module.playerModule.IsDataExist(selfPid) then
		        local player=module.playerModule.Get(selfPid);
		        if hero.showMode ~= player.head then
					module.PlayerModule.ChangeIcon(hero.showMode)
				end
		    else
		        module.playerModule.Get(selfPid,function ( ... )
		            local player=module.playerModule.Get(selfPid);
		            if hero.showMode ~= player.head then
						module.PlayerModule.ChangeIcon(hero.showMode)
					end
		        end)
		    end
			utils.PlayerInfoHelper.ChangeActorShow(hero.showMode)
			--]]
		end
		changeFashionSuitTab[sn]=nil
	end
	DispatchEvent("HERO_INFO_CHANGE");
end);

EventManager.getInstance():addListener("server_respond_97", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local suit_id = data[3];
	print("查询时装返回",sn2pid[sn].uuid, sprinttb(data))
	if sn2pid[sn] then
		GetManager(sn2pid[sn].pid).heroFashionSuit[sn2pid[sn].uuid] = suit_id;
		DispatchEvent("HERO_FASHION_CHANGE", sn2pid[sn].uuid);
	end
end);

EventManager.getInstance():addListener("GIFT_INFO_CHANGE", function(event, pid, uuid, type, init)
	local manager = GetManager(pid);
	local hero = manager:GetByUuid(uuid);
	if hero == nil then
		print("天赋对应角色不存在",uuid);
		return;
	end
	-- print("重新计算天赋属性")
	manager:SetHeroChange(hero.id, true);
	hero:ReCalcProperty(init);
	DispatchEvent("GIFT_PROP_CHANGE");
end);

EventManager.getInstance():addListener("HERO_CAPACITY_CHANGE", function(event, id)
	local pid = playerModule.Get().id;
	local manager = GetManager(pid);
	local hero = manager:Get(id);
	manager:SetHeroChange(id, true);
	hero:ReCalcProperty(false);
end);

EventManager.getInstance():addListener("HERO_BUFF_CHANGE", function(event, id)
	local pid = playerModule.Get().id;
	local manager = GetManager(pid);
	if id and id ~= 0 then
		local hero = manager:Get(id);
		manager:SetHeroChange(id, true);
		hero:ReCalcProperty(false);
	else
		local heros = manager:GetAll();
		for k,v in pairs(heros) do
			manager:SetHeroChange(k, true);
			v:ReCalcProperty(false);
		end
	end
end);

-- EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)
-- 	GetManager(pid);
-- end);

EventManager.getInstance():addListener("HERO_INFO_CHANGE", function ()
	-- SGK.ResourcesManager.ClearUnLoadAssets();
	for i=1,5 do
		local t = GetManager():GetByPos(i);
		if t then
			local path = string.format("roles/%d/%d_SkeletonData.asset", t.mode, t.mode);
			SGK.ResourcesManager.AddUnLoadAsset(path);
			SGK.ResourcesManager.LoadAsync(path)
		end
	end
end)

return {
	GetManager = GetManager,
	GetConfig = GetConfig,
	GetConfigByWeapon = GetConfigByWeapon,
	GetWeaponConfig = GetWeaponConfig,
	GetWeaponConfigByHeroID = GetWeaponConfigByHeroID,
	GetSortHeroList = GetSortHeroList;
	GetAssistList = GetAssistList,
    GetHeroCount = GetHeroCount,
	GetInfoConfig = GetInfoConfig,
	GetLineupTalk = GetLineupTalk,

	ChangeSpecialStatus=ChangeHeroItemSpecial,

}



-- #define C_HERO_SELECT_SKILL_REQUEST 86 // 角色选择技能
-- [sn, uuid, group]

-- #define C_HERO_SELECT_SKILL_RESPOND 87
