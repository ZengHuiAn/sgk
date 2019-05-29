local equipmentModule = {}

local NetworkService = require "utils.NetworkService"
local EventManager = require 'utils.EventManager'
local equipCofig = require "config.equipmentConfig"
local playerModule = require "module.playerModule"
local HeroScroll = require "hero.HeroScroll"


local _allPlayerEquipMentTab = {}


local equipManage = { _pid = 0}
local equipBagIndx = {}

function equipManage:init()
	self._pid = 0
	self.snTab = {}
end

--发消息获取玩家自己的装备列表
local function sendSelfEquip()
	NetworkService.Send(33, {nil})
end

--发送升级
local function sendLevelMsg(uuid, count,exp)
	NetworkService.Send(35, {nil, uuid, count,exp})
end

--发送装备道具消息
--转二进制取哪一位是1就表示哪一位可以装备
local function sendEquipmentItems(uuid, heroid, place, suits)
    suits = suits or 0
    if equipCofig.GetEquipOpenLevel(suits, place) then
	    NetworkService.Send(39, {nil, uuid, heroid, place | (suits << 8)})
    else
        --showDlgError(nil, "未开放")
    end
end

--分解装备
local function decompose(uuid)
    NetworkService.Send(88, {nil, uuid})
end

--淬炼
local function quenching(uuid, count)
    NetworkService.Send(90, {nil, uuid, count})
end

--装备进阶
local function sendAdvanced(destUuid, srcUuid)
	ERROR_LOG("srcUuid",tostring(destUuid),sprinttb(srcUuid))
	local _sn = NetworkService.Send(37, {nil, destUuid, srcUuid})
	if #srcUuid < 1 then
		equipManage.snTab[_sn] = true 	--进阶
	else
		equipManage.snTab[_sn] = false 	--吞噬
	end
end

--吃装备升级
local function sendAdvLevelMsg(destUuid, needTab)
	-- print("srcUuid",tostring(destUuid),sprinttb(needTab))
	NetworkService.Send(43, {nil, destUuid, needTab})
end

--获取所有玩家装备铭文列表
local function allPlayerEquipTab()
	return _allPlayerEquipMentTab
end

local function oneselfEquipMentTab(pid)
	pid = pid or equipManage._pid
	if _allPlayerEquipMentTab[pid] == nil then
		_allPlayerEquipMentTab[pid] = {}
	end
	return _allPlayerEquipMentTab[pid]
end

local _selectSubTypeTab = {} --按玩家按subType存放装备
local function judgeSelectSubType(pid, v)
	if _selectSubTypeTab[pid] == nil then
		_selectSubTypeTab[pid] = {}
	end
	local _subType = equipCofig.EquipmentTab()[v.id].sub_type
	if _selectSubTypeTab[pid][_subType] == nil then
		_selectSubTypeTab[pid][_subType] = {}
	end
	_selectSubTypeTab[pid][_subType][v.uuid] = v
end

--根据英雄穿戴分类
local _allHeroEquip = {}
local _indexHeroEquip = {}
local function classifyHeroEquip(pid, v)
	if _indexHeroEquip[pid] == nil then
		_indexHeroEquip[pid] = {}
	end
	if v.heroid ~= 0 then
		if _allHeroEquip[pid] == nil then
			_allHeroEquip[pid] = {}
		end
		if _allHeroEquip[pid][v.heroid] == nil then
			_allHeroEquip[pid][v.heroid] = {}
		end
		if _indexHeroEquip[pid][v.uuid] then
			local _index = _indexHeroEquip[pid][v.uuid]
            if _allHeroEquip[pid][_index[1]][_index[2]].uuid == v.uuid then
			    _allHeroEquip[pid][_index[1]][_index[2]] = nil
                _indexHeroEquip[pid][v.uuid] = nil
            end
		end
		_indexHeroEquip[pid][v.uuid] = {v.heroid, v.placeholder}
		_allHeroEquip[pid][v.heroid][v.placeholder] = v
	end
end

--根据穿戴部位判断
local _placeTypeTab = {}
local function getSelfPlaceTypeTab()
	if _placeTypeTab[equipManage._pid] == nil then
		_placeTypeTab[equipManage._pid] = {}
		print("_placeTypeTab nil")
	end
	return _placeTypeTab[equipManage._pid]
end

local function judgePlaceType(pid, v, inscrip)
	if _placeTypeTab[pid] == nil then _placeTypeTab[pid] = {} end
	local _placeType = {}
	if inscrip == nil then
		_placeType = equipCofig.EquipmentTab()[v.id].type
	else
		_placeType = equipCofig.InscriptionCfgTab()[v.id].type
	end
	if _placeTypeTab[pid][_placeType] == nil then
		_placeTypeTab[pid][_placeType] = {}
	end
	_placeTypeTab[pid][_placeType][v.uuid] = v
end

--0装备 1铭文 -1其他
local _inscriptionTab = {}
local _allEquipTab = {}
local function judgeType(pid, v)
	if _inscriptionTab[pid] == nil then
		_inscriptionTab[pid] = {}
	end
	if _allEquipTab[pid] == nil then
		_allEquipTab[pid] = {}
	end

	if equipCofig.InscriptionCfgTab()[v.id] ~= nil then
		_inscriptionTab[pid][v.uuid] = v
		judgePlaceType(pid, v, true)
		classifyHeroEquip(pid, v)
		return
	elseif equipCofig.EquipmentTab()[v.id] ~= nil then
		_allEquipTab[pid][v.uuid] = v
		judgeSelectSubType(pid, v)
		judgePlaceType(pid, v)
		classifyHeroEquip(pid, v)
		return
	end
	-- print("unclassified uuid", v.id, equipCofig.EquipmentTab()[v.id])
end

--0装备
--1铭文
--2其他
local function getEquipType(id)
	if equipCofig.EquipmentTab(id) ~= nil then
		return 0
	elseif equipCofig.InscriptionCfgTab(id) ~= nil then
		return 1
	else
		return 2
	end
end

local function pushAttribute(dst, id, value, grow, level, type)
	local cfg = HeroScroll.GetScrollConfig(id);
	if not cfg then
		if CS.UnityEngine.Application.isEditor then
			-- print(string.format('config of scroll %d not exists', id));
		end
		return;
	end

    local _allVal = 0
    _allVal = value + math.floor(value * (level - 1) * cfg.property_lev_per / 10000) + grow


	local att = {
		scrollId = id,
		key   = cfg.type,
		value = value,
		grow  = grow,
        allValue = _allVal,
        cfg   = cfg,
	}

	table.insert(dst, att);
end

---铭文基础属性
local function GetIncBaseAtt(uuid, pid)
    local attTab = {}
    local _cfg = oneselfEquipMentTab(pid)[uuid]
    if not _cfg then
        ERROR_LOG("not find uuid", uuid, pid, debug.traceback())
        return attTab
    end
    for i = 0, 3 do
        local _type = _cfg.cfg["type"..i]
        local _value = _cfg.cfg["value"..i]
        if _type and _type ~= 0 then
            local _levTab = equipCofig.EquipmentLevTab()[_cfg.id]
            if _levTab then
                table.insert(attTab, {key = _type, value = _value, allValue = (_levTab.propertys[_type] or 0) * _cfg.level + _value, addValue = _levTab.propertys[_type] or 0})
            else
                ERROR_LOG("id", _cfg.id, "level cfg error")
            end
        end
    end
    return attTab
end

local function GetAttribute(uuid, pid)
	pid = pid or equipManage._pid
	if not _allPlayerEquipMentTab[pid] then return {} end
	if not _allPlayerEquipMentTab[pid][uuid] then return {} end

	return _allPlayerEquipMentTab[pid][uuid].attribute
end

local function GetEquipBaseAtt(uuid, pid)
    local attTab = {}
    local _cfg = oneselfEquipMentTab(pid)[uuid]
    if not _cfg then
        ERROR_LOG("not find uuid", uuid)
        return attTab
    end
    local _config = equipCofig.GetConfig(_cfg.id)
    local _baseAtt = {}
    for k,v in pairs(_config and _config.propertys or {}) do
        _baseAtt[k] = {key = k, value = v}
    end
    local _levelUpAtt = {}
    local _levelCfg = equipCofig.EquipmentLevTab()[_cfg.id]
    for i = 0, 3 do
        local _type = _config["type"..i]
        local _value = _config["value"..i]
        if _type and _type ~= 0 then
            table.insert(attTab, {key = _type, value = _value, allValue = _value, addValue = _value})
        end
    end
    for k,v in pairs(_levelCfg and _levelCfg.propertys or {}) do
        if k ~= 0 then
            table.insert(attTab, {key = k, value = v, allValue = v * _cfg.level, addValue = v})
        end
    end
    if _cfg.pool5 then
        for i,v in ipairs(_cfg.pool5) do
            table.insert(attTab, {key = v.key, value = v.value, allValue = v.allValue, addValue = v.value})
        end
    end
    if _cfg.pool6 then
        for i,v in ipairs(_cfg.pool6) do
            table.insert(attTab, {key = v.key, value = v.value, allValue = v.allValue, addValue = v.value})
        end
    end
    return attTab
end

local commonCfg = require "config.commonConfig"
local _equipScrollCfg = {
    [1] = 400,
    [2] = 401,
    [3] = 402,
    [4] = 403,
}
local function checEquipScroll(idx, uuid, level, id)
    local cfg = HeroScroll.GetScrollConfig(id)
    if not cfg then
        return
    end
    if cfg.type ~= 0 then
        return
    end
    if not _equipScrollCfg[idx] then
        return
    end
    local _comm = commonCfg.Get(_equipScrollCfg[idx])
    if not _comm then
        return
    end
    if level < _comm.para1 then
        return
    end
    utils.NetworkService.Send(72, {nil, uuid, idx, 3})
end

--装备鉴定(更换 装备 卷轴)
local localSnTab = {}
local function ChangeEquipScroll(uuid,idx)
	local sn = utils.NetworkService.Send(72, {nil, uuid,idx,3})
	localSnTab[sn] = uuid
end

local function upPlayEquipmentInfo(pid, v)
	local id = v[1];
	local _uuid = math.ceil(v[3])
	local cfg = equipCofig.GetConfig(id)
    if not cfg then
        -- print(id, "not find cfg")
        cfg = {icon = 0, ssrType = 0, quality = 1}
    end
	local equip = {
		uuid        = _uuid,
		id          = v[1],
		heroid      = v[2],
		level       = v[4],
        showLevel   = cfg and cfg.equip_level or 1,
		hero_uuid   = v[5],
		placeholder = v[6],
        suits       = (v[6] >> 8),                           --套装id
        localPlace  = v[6] & ((v[6] >> 8) | 0xff),           --相对位置
		quality     = cfg and cfg.quality or 0,
		type        = getEquipType(id),
		attribute   = {},
        icon        = cfg.icon,
        ssrType     = (cfg.quality or 1) - 1,
        isLock      = equipCofig.GetOtherSuitsCfg().EqSuits < (v[6] >> 8),
        cfg         = cfg,
		time 		= v[8] or 0,
		otherConsume= v[9] or {},                            --装备分解额外返还的资源(服务器存)
        exp         = v[10],                                 --装备经验

		stage_exp = 9999999,
	}

	for _, att in ipairs(v[7] or {}) do
        if _ == 5 then
            equip.pool5 = {}
            pushAttribute(equip.pool5, att[1], att[2], att[3], equip.level, equip.type);
        elseif _ == 6 then
            equip.pool6 = {}
            pushAttribute(equip.pool6, att[1], att[2], att[3], equip.level, equip.type);   
        else
            pushAttribute(equip.attribute, att[1], att[2], att[3], equip.level, equip.type);
        end
        checEquipScroll(_, _uuid, v[4], att[1]) ---检查前缀卷轴
	end

	equip.pre_property1_key = equip.attribute[1] and equip.attribute[1].scrollId or 0;

	_allPlayerEquipMentTab = _allPlayerEquipMentTab or {};
	_allPlayerEquipMentTab[pid] = _allPlayerEquipMentTab[pid] or {}
	_allPlayerEquipMentTab[pid][_uuid] = equip;

	--按照装备铭文分类
	judgeType(pid, equip)
end 

local function selectSubTypeTab(st)
	if _selectSubTypeTab[equipManage._pid] == nil then
		_selectSubTypeTab[equipManage._pid] = {}
		print("_selectSubTypeTab nil")
	end
	return st and _selectSubTypeTab[equipManage._pid][st] or _selectSubTypeTab[equipManage._pid];
end

local function inscriptionTab()
	if _inscriptionTab[equipManage._pid] == nil then
		_inscriptionTab[equipManage._pid] = {}
		print("_inscriptionTab nil")
	end
	return _inscriptionTab[equipManage._pid]
end

local function selfAllHeroEquipTab(heroid, placeholder, suits)
    suits = suits or 0
	if _allHeroEquip[equipManage._pid] == nil then
		_allHeroEquip[equipManage._pid] = {}
	end
	if heroid == nil and placeholder == nil then
		return _allHeroEquip[equipManage._pid]
	end
	if _allHeroEquip[equipManage._pid][heroid] == nil then
		_allHeroEquip[equipManage._pid][heroid] = {}
	end
	if heroid ~= nil and placeholder == nil then
		return _allHeroEquip[equipManage._pid][heroid]
	end
    placeholder = placeholder | (suits << 8)
	if _allHeroEquip[equipManage._pid][heroid][placeholder] == nil then
		_allHeroEquip[equipManage._pid][heroid][placeholder] = nil
	end
	return _allHeroEquip[equipManage._pid][heroid][placeholder]
end

local function selfEquipTab()
	if _allEquipTab[equipManage._pid] == nil then
		_allEquipTab[equipManage._pid] = {}
		print("_allEquipTab nil")
	end
	return _allEquipTab[equipManage._pid]
end

--移除装备从所有的表中
local function removeEquipFromTab(pid, uuid, id)
	if not _allPlayerEquipMentTab[equipManage._pid][uuid] then return end
	local _id = _allPlayerEquipMentTab[equipManage._pid][uuid].id
	_allEquipTab[pid][uuid] = nil
	_allPlayerEquipMentTab[pid][uuid] = nil
	_inscriptionTab[pid][uuid] = nil


	if equipCofig.EquipmentTab(_id) then
		local _subType = equipCofig.EquipmentTab(_id).sub_type
		_selectSubTypeTab[pid][_subType][uuid] = nil
	end


	local _placeType = equipCofig.GetConfig(_id).type
	_placeTypeTab[pid][_placeType][uuid] = nil
end

local function QueryEquipInfoFromServer(pid, uuid, func)
	local _equip = nil;
	if _allPlayerEquipMentTab[pid] then
		_equip = _allPlayerEquipMentTab[pid][uuid];
	end
	if _equip then
		if func then
			func(_equip);
		end
		return _equip;
	else
		print("查询", pid, uuid)
		local _sn = NetworkService.Send(110, {nil, pid, uuid});
		equipManage.snTab[_sn] = {func = func, uuid = uuid, pid = pid};
	end
end

EventManager.getInstance():addListener("server_respond_111", function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
	local info = data[3];
	print("查询装备返回", sprinttb(data))
	if info then
		upPlayEquipmentInfo(equipManage.snTab[sn].pid, info)

		if equipManage.snTab[sn].func then
			equipManage.snTab[sn].func(_allPlayerEquipMentTab[equipManage.snTab[sn].pid][equipManage.snTab[sn].uuid])
		end
	end
end)

EventManager.getInstance():addListener("server_respond_34", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local list = data[3];

	_allPlayerEquipMentTab = {};
	_selectSubTypeTab = {}

	if err == 0 then
		-- print("装备列表返回",sprinttb(list))
		for i = 1,#list do
			upPlayEquipmentInfo(equipManage._pid, list[i])
		end
	else
		print("err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_36", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
        DispatchEvent("LOCAL_EQUIP_LEVEL_UP_OK")
		--showDlgError(nil, "升级成功")
	else
        DispatchEvent("LOCAL_EQUIP_LEVEL_UP_ERROR")
		--showDlgError(nil, "升级失败")
		print("装备升级失败err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_89", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		--showDlgError(nil, "分解成功")
        DispatchEvent("LOCAL_DECOMPOSE_OK")
	else
		showDlgError(nil, "分解失败")
		print("装备升级失败err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_38", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	-- print("server_respond_38", sprinttb(data))
	if err == 0 then
		if equipManage.snTab[sn] then
			--showDlgError(nil, "进阶成功")
			DispatchEvent("LOCAL_ADV_MAX")
		else
			showDlgError(nil, "吞噬成功")
			DispatchEvent("LOCAL_ADV_UP")
		end
		equipManage.snTab[sn] = nil
	else
		if equipManage.snTab[sn] then
			showDlgError(nil, "进阶失败")
		else
			showDlgError(nil, "吞噬失败")
		end
		equipManage.snTab[sn] = nil
	end
end)

EventManager.getInstance():addListener("server_respond_44", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	-- print("server_respond_44", print(sprinttb(data)))
	if err == 0 then
		--showDlgError(nil, "强化成功")
		DispatchEvent("ADVANCED_OVER")
	else
		showDlgError(nil, "强化失败")
		DispatchEvent("ADVANCED_OVER")
		print("铭文进阶err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_40", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		DispatchEvent("LOCAL_EQUIP_CHANGE")
		-- print("装备道具成功")
	else
        if err == 8 then
            --showDlgError(nil, "钻石不足")
        end
		print("装备道具失败err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_42", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		print("装备前缀修改成功")
		DispatchEvent("Scroll_Info_Change")
		DialogStack.Pop()
	else
		print("装备前缀修改失败err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_91", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
        DispatchEvent("LOCAL_EQUIP_QUENCHING_OK")
		print("洗练成功")
	else
		print("洗练失败err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_73", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		DispatchEvent("Scroll_CHANGE_Ref",{id = data[3],value = data[4]})
		DispatchEvent("Scroll_Info_Change")
		if localSnTab[sn] then
			DispatchEvent("LOCAL _SCROLL_CHANGE")
			--showDlgError(nil,"鉴定成功")
			localSnTab[sn] = nil
		end
	else
		print("装备前缀刷新失败err", err);
	end
end)

local function GetByUUID(uuid, pid)
	return oneselfEquipMentTab(pid)[uuid];
end
--获取新装备或者脱下装备
local tempToBagList={}
--刷新用户自己的装备道具表
EventManager.getInstance():addListener("server_notify_53", function(event, cmd, data)
	--print("server_notify_53"..sprinttb(data))
	--20为4时 delet
    if _allPlayerEquipMentTab[equipManage._pid] == nil then _allPlayerEquipMentTab[equipManage._pid] = {} end

    local uuidd = math.ceil(data[3])
	local old_heroid = 0
	if _allPlayerEquipMentTab[equipManage._pid][uuidd] then
		old_heroid = _allPlayerEquipMentTab[equipManage._pid][uuidd].heroid;
	end

	tempToBagList[getEquipType(data[1])]=tempToBagList[getEquipType(data[1])] or {}

	if not _allPlayerEquipMentTab[equipManage._pid][uuidd] then
		DispatchEvent("LOCAL_EQUIP_INFO_BEFORE", uuidd)
        --获取新装备
       	--table.insert(tempToBagList,uuidd)
       	tempToBagList[getEquipType(data[1])][uuidd]=uuidd
       	DispatchEvent("EQUIP_INFO_CHANGE_BEFORE", getEquipType(data[1]))
       	--获取装备Tip
		if data[1]~=0 then
			local _type=getEquipType(data[1])==0 and 43 or 45
			GetItemTips(data[1],1, _type,uuidd)
			--获得武器系统通知
			module.ChatModule.SystemChat(module.playerModule.Get().id,_type,data[1],1)
		end
    else
        if _allPlayerEquipMentTab[equipManage._pid][uuidd].heroid ~= 0 and data[2] == 0 then
        	--DispatchEvent("EQUIP_INFO_CHANGE_BEFORE", getEquipType(data[1]))
            DispatchEvent("LOCAL_EQUIP_INFO_BEFORE", uuidd)
            --脱下装备
            --table.insert(tempToBagList,uuidd)
        else
    		--ERROR_LOG("==穿上的装备移除获得列表装备 或者摧毁",uuidd)
    		if tempToBagList[getEquipType(data[1])][uuidd] then
    			tempToBagList[getEquipType(data[1])][uuidd]=nil
    			DispatchEvent("EQUIP_INFO_CHANGE_BEFORE", getEquipType(data[1]))
    		--摧毁
    		elseif (tempToBagList[0] and tempToBagList[0][uuidd]) or (tempToBagList[1] and tempToBagList[1][uuidd]) then
    			local  _localtype=tempToBagList[0] and tempToBagList[0][uuidd] and 0 or 1
    			tempToBagList[ _localtype][uuidd]=nil
    			DispatchEvent("EQUIP_INFO_CHANGE_BEFORE", _localtype)
    		end
        end
	end

	if _indexHeroEquip[equipManage._pid] == nil then _indexHeroEquip[equipManage._pid] = {} end
	local _index = _indexHeroEquip[equipManage._pid][uuidd]
	if data[1] == 0 then
        if _index then
            _allHeroEquip[equipManage._pid][_index[1]][_index[2]] = nil
    		_indexHeroEquip[equipManage._pid][uuidd] = nil
        end
		removeEquipFromTab(equipManage._pid, uuidd, data[1])
	elseif data[2] == 0 and _index ~= nil then
		_allHeroEquip[equipManage._pid][_index[1]][_index[2]] = nil
		_indexHeroEquip[equipManage._pid][uuidd] = nil
		upPlayEquipmentInfo(equipManage._pid, data)
	else
		upPlayEquipmentInfo(equipManage._pid, data)
	end
	local new_heroid = 0;
	if _allPlayerEquipMentTab[equipManage._pid][uuidd] and _allPlayerEquipMentTab[equipManage._pid][uuidd].heroid then
		new_heroid = _allPlayerEquipMentTab[equipManage._pid][uuidd].heroid;
	end
	if new_heroid ~= old_heroid then
		if old_heroid ~= 0 then
			DispatchEvent("HERO_CAPACITY_CHANGE", old_heroid)
		end
		if new_heroid ~= 0 then
			DispatchEvent("HERO_CAPACITY_CHANGE", new_heroid)
		end
	elseif old_heroid ~= 0 then
		DispatchEvent("HERO_CAPACITY_CHANGE", old_heroid)
	end
	DispatchEvent("EQUIPMENT_INFO_CHANGE", uuidd)
end)

local hashBinary = {
	[1] = 9,
	[2] = 18,
	[3] = 36,
	[4] = 9,
	[5] = 18,
	[6] = 36,
	[7] = 64,
	[8] = 128,
	[9] = 256,
	[10] = 512,
	[11] = 1024,
	[12] = 2048
}

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)
	equipManage:init()
	equipManage._pid = pid
	sendSelfEquip()
end)

local function addSuitProperty(keyTab, valueTab, propertyTab)
	for j,p in pairs(keyTab) do
		if p and p ~= 0 and valueTab[j] and valueTab[j] ~= 0 then
			propertyTab[p] = (propertyTab[p] or 0) + valueTab[j]
		end
	end
end

local function SuitProperty(tab, propertyTab)
	if tab and next(tab)~=nil then
		for k,v in pairs(tab) do
            if #v.IdxList >= 6 then
                addSuitProperty(v.Type[3], v.Value[3], propertyTab)
            end

			if #v.IdxList >= 4 then
				addSuitProperty(v.Type[2], v.Value[2], propertyTab)
			end

			if #v.IdxList >= 2 then
				addSuitProperty(v.Type[1], v.Value[1], propertyTab)
			end
		end
	end
end

local HeroModule = nil

local function CaclPropertyByEq(equip,pid)
    local _propertyTab = {}
    if not equip then
        return _propertyTab
    end
    for i,p in ipairs(GetEquipBaseAtt(equip.uuid,pid)) do
        _propertyTab[p.key] = (_propertyTab[p.key] or 0) +  p.allValue;
    end
    for i,j in pairs(equip.attribute) do
        _propertyTab[j.key] = (_propertyTab[j.key] or 0) + j.allValue;
    end
    return _propertyTab
end

local function CaclProperty(hero,showSuitProperty)--showSuitProperty是否显示套装效果  ，默认显示
	if not HeroModule then
		HeroModule = require "module.HeroModule".GetManager()
	end

	local propertyTab = {}
	local heroEquip = selfAllHeroEquipTab(hero.id)
	for k,v in pairs(heroEquip) do
		if v.type == 0 then
			---装备上的基础属性
            for i,p in ipairs(GetEquipBaseAtt(v.uuid)) do
                local _value = p.allValue
                if v.suits ~= 0 then
                    _value = _value * equipCofig.GetOtherSuitsCfg().Eq
                end
                propertyTab[p.key] = (propertyTab[p.key] or 0) + _value;
            end

			for i,j in pairs(v.attribute) do
                if equipCofig.GetOtherSuitsCfg().EqSuits >= v.suits then
    				local _key = j.key
    	            local _tValue = j.allValue
    	            if v.suits ~= 0 then
    	                _tValue = _tValue * equipCofig.GetOtherSuitsCfg().Eq
    	            end
    				propertyTab[_key] = (propertyTab[_key] or 0) + _tValue;
                end
			end
		end
	end
	if not showSuitProperty then
		---前缀套装属性
		SuitProperty(HeroModule:GetPrefixSuit(hero.id)[0], propertyTab)
		---装备套装属性
		SuitProperty(HeroModule:GetEquipSuit(hero.id)[0], propertyTab)
	end
	return propertyTab
end

local function IsOwnEquipOnIndex(Index,status)
	local _placeHolder=status and  hashBinary[Index+6] or  hashBinary[Index]
	local _equipTab=getSelfPlaceTypeTab()[_placeHolder]
	return _equipTab and true or false
end


local function EquipCount(time, quality)
	local i = 0
	time = time or 4102416000;
	quality = quality or 0;
	for k,v in pairs(selfEquipTab()) do
		if v.time < time and v.quality >= quality then
			i = i + 1
		end
	end
    return i
end

local function EquipLevelCount(time, level)
	local i = 0
	time = time or 4102416000;
	level = level or 1;
	for k,v in pairs(selfEquipTab()) do
		if v.time < time and v.level >= level then
			i = i + 1
		end
	end
    return i
end

local function InscripCount(time, quality)
	local i = 0
	time = time or 4102416000;
	quality = quality or 0;
	for k,v in pairs(inscriptionTab()) do
		if v.time < time and v.quality >= quality then
			i = i + 1
		end
	end
    return i
end

local function GetTempToBagList(type)
	return tempToBagList and tempToBagList[type] or {}
end
local function ClearTempToBagList(type)
	tempToBagList[type]={}
end

local function GetPosEquip(pos)
    for k,v in pairs(oneselfEquipMentTab()) do
        if hashBinary[pos] == v.cfg.type then
            return v
        end
    end
    return nil
end
--卸下装备
local unLoadequipList = {}
local function sendUnloadEquipment(uuid)
	--储存卸下的装备
    unLoadequipList[uuid] = true

    local _equip = GetByUUID(uuid)
    if _equip then
        if _equip.isLock then
            NetworkService.Send(39, {nil, uuid, 0, 0})
            return
        else
            local _itemPrice = equipCofig.ChangePrice(_equip.type, _equip.quality)
            if _itemPrice and _itemPrice.value > 0 and _equip.localPlace ~= 0 then
                coroutine.resume(coroutine.create(function()
                    local _suits = 100
                    while(true) do
                        local _tab = selfAllHeroEquipTab(_equip.heroid, _equip.localPlace, _suits)
                        if _tab == nil or _tab == {} then
                            break
                        end
                        _suits = _suits + 1
                    end
                    local _data = NetworkService.SyncRequest(39, {nil, uuid, _equip.heroid, _equip.localPlace | (_suits << 8)})
                end))
                return
            end
        end
    else
        ERROR_LOG(uuid, "not Find")
    end
	NetworkService.Send(39, {nil, uuid, 0, 0})
end
--过滤卸下装备(不推荐卸下装备)
local function GetUnLoadEquipList()
	return unLoadequipList
end
return {
	LevelUp = sendLevelMsg,	        	    	--发送升级
	EquipmentItems = sendEquipmentItems,	    --发送装备装备
	UnloadEquipment = sendUnloadEquipment,	    --发送卸下装备
	Advanced = sendAdvanced,				    --发送装备升阶
	AdvLevelMsg = sendAdvLevelMsg,			    --发送铭文升阶
	AllPlayerEquipTab = allPlayerEquipTab,		--获取所有玩家装备信息pid索引
	OneselfEquipMentTab = oneselfEquipMentTab,	--获取玩家自身所有的装备和铭文
	SelectSubTypeTab = selectSubTypeTab, 		--获取玩家自身装备按subtype
	InscriptionTab = inscriptionTab,	 		--获取玩家自身所有铭文
	GetHeroEquip = selfAllHeroEquipTab,  		--获取玩家英雄身上的装备[heroId][placeholder]
	GetEquip = selfEquipTab, 	         		--获取自身所有的装备
	GetPlace = getSelfPlaceTypeTab,				--获取装备位置表
	HashBinary = hashBinary,					--获取穿戴对应的二进制码
	CaclProperty = CaclProperty,
	GetByUUID = GetByUUID,
	GetAttribute = GetAttribute,			    --铭文属性
    Decompose = decompose,
	IsOwnEquipOnIndex=IsOwnEquipOnIndex,--判断该位置是否有可用装备
    EquipCount = EquipCount,
    EquipLevelCount = EquipLevelCount,
    InscripCount = InscripCount,
    Quenching = quenching,              --淬炼
    GetIncBaseAtt = GetIncBaseAtt,
    CaclPropertyByEq = CaclPropertyByEq,
    GetEquipBaseAtt = GetEquipBaseAtt,

    GetTempToBagList=GetTempToBagList,--获取新获得装备
    ClearTempToBagList=ClearTempToBagList,--清空新获得装备
	GetPosEquip = GetPosEquip,
	QueryEquipInfoFromServer = QueryEquipInfoFromServer,	--从服务器查询装备

	ChangeEquipScroll = ChangeEquipScroll,--装备鉴定
	GetUnLoadEquipList = GetUnLoadEquipList,--装备推荐过滤
}
