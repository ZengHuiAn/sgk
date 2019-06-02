local heroModule = require "module.HeroModule"
local equipModule = require "module.equipmentModule"
local RedDotModule = require "module.RedDotModule"
local equipmentConfig = require "config.equipmentConfig"
local equiptCfg = require "config.equipmentConfig"
local UserDefault = require "utils.UserDefault"
local OpenLevel = require "config.openLevel"
local HeroScroll = require "hero.HeroScroll"

---suits 套装
---typeId 装备 or 铭文 不传代表全部

---卸载套装
local function UnloadSuits(heroId, suits, typeId)
    for i = 1, 12 do
        local _cfg = equipModule.GetHeroEquip(heroId, i, suits)
        if _cfg and _cfg.uuid then
            if typeId == nil or typeId == _cfg.type then
                equipModule.UnloadEquipment(_cfg.uuid)
            end
        end
    end
end

local function getFirstQuenching(_equipList)
    table.sort(_equipList, function(a, b)
        local _a = tonumber(string.sub(tostring(a.cfg.id), 4, 4))
        local _b = tonumber(string.sub(tostring(b.cfg.id), 4, 4))
        if _a == b then
            return _a.localPlace > b.localPlace
        end
        return _a < _b
    end)
end

local function QuickEquipQuenching(heroId, suits)
    local _equipList = {}
    for i = 7, 12 do
        local _cfg = equipModule.GetHeroEquip(heroId, i, suits)
        if _cfg and _cfg.uuid then
            if _cfg.cfg.evo_id ~= 0 then
                table.insert(_equipList, {cfg = _cfg.cfg, uuid = _cfg.uuid})
            end
        end
    end
    local _haveCount = module.ItemModule.GetItemCount(90016)
    local _quenchingList = {}
    while true do
        getFirstQuenching(_equipList)
        local v = _equipList[1]
        if not v then
            break
        end
        if v.cfg.evo_id == 0 or v.cfg.swallow > _haveCount then
            break
        end
        if not _quenchingList[v.uuid] then
            _quenchingList[v.uuid] = {}
        end
        local _getCount = _quenchingList[v.uuid].count or 0
        _quenchingList[v.uuid] = {uuid = v.uuid, count = _getCount + 1}
        _haveCount = _haveCount - v.cfg.swallow
        _equipList[1].cfg = equiptCfg.GetConfig(v.cfg.evo_id)
    end
    local _item = {}
    _item[1] = {type = 41, id = 90016, value = module.ItemModule.GetItemCount(90016) - _haveCount}
    DialogStack.PushPrefStact("mapSceneUI/Strongerdialog", {item = _item, func = function()
        for k,v in pairs(_quenchingList) do
            for i = 1, v.count do
                equipModule.Advanced(v.uuid, {})
            end
        end
    end})
end

local function getFirstEquip(_equipList)
    table.sort(_equipList, function(a, b)
        if a.level == b.level then
            return a.localPlace > b.localPlace
        end
        return a.level < b.level
    end)
end

local function QuickLevelUp(heroId, suits, typeId)
    local _equipList = {}
    for i = 1, 12 do
        local _cfg = equipModule.GetHeroEquip(heroId, i, suits)
        if _cfg and _cfg.uuid then
            if typeId == nil or typeId == _cfg.type then
                table.insert(_equipList, {level = _cfg.level, uuid = _cfg.uuid, localPlace = _cfg.localPlace, type = _cfg.type})
            end
        end
    end
    table.sort(_equipList, function(a, b)
        if a.level == b.level then
            return a.localPlace > b.localPlace
        end
        return a.level < b.level
    end)
    local _levelList = {}
    local _inscCount = module.ItemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id)
    local _equipCount = module.ItemModule.GetItemCount(90002)
    local _heroLevel = heroModule.GetManager():Get(11000).level
    local _max = 200
    local _needEquipCount = 0
    local _needInscCount = 0

    while true do
        getFirstEquip(_equipList)
        local v = _equipList[1]
        if not v then
            break
        end
        if v.type == 0 then
            local _need = 0
            if equiptCfg.UpLevelCoin()[v.level+1] and equiptCfg.UpLevelCoin()[v.level] then
                _need = equiptCfg.UpLevelCoin()[v.level+1].value - equiptCfg.UpLevelCoin()[v.level].value
            end
            if v.level >= _heroLevel or v.level >= _max or _need > _equipCount then
                break
            end
            _equipCount = _equipCount - _need
            _needEquipCount = _needEquipCount + _need
            v.level = v.level + 1
        elseif v.type == 1 then
            local _need = 0
            if equiptCfg.EquipLeveUpTab(v.level+1) and equiptCfg.EquipLeveUpTab(v.level) then
                _need = equiptCfg.EquipLeveUpTab(v.level+1).value - equiptCfg.EquipLeveUpTab(v.level).value
            end
            if v.level >= _heroLevel or v.level >= _max or _need > _inscCount then
                break
            end
            _inscCount = _inscCount - _need
            _needInscCount = _needInscCount + _need
            v.level = v.level + 1
        else
            break
        end
        if not _levelList[v.uuid] then
            _levelList[v.uuid] = {}
        end
        local _getCount = _levelList[v.uuid].count or 0
        _levelList[v.uuid] = {uuid = v.uuid, count = _getCount + 1}
    end
    local _item = {}
    if typeId == 0 then
        _item[1] = {type = 41, id = 90002, value = _needEquipCount}
    else
        _item[1] = {type = 41, id = equiptCfg.EquipLeveUpTab(1).id, value = _needInscCount}
    end
    if _needInscCount > 0 or _needEquipCount > 0 then
        DialogStack.PushPrefStact("mapSceneUI/Strongerdialog", {item = _item, func = function()
            local _addCount = 0
            local _levelCount = 0
            for i,v in pairs(_levelList) do
                if v.count ~= 0 then
                    equipModule.LevelUp(v.uuid, v.count)
                else
                    _addCount = _addCount + 1
                end
                _levelCount = _levelCount + 1
            end
            if _addCount == _levelCount then
                DispatchEvent("LOCAL_EQUIP_QUICKLEVEL_ERROR")
            end
        end})
    else
        DispatchEvent("LOCAL_EQUIP_QUICKLEVEL_ERROR")
    end
end

local function GetSkillIndex(heroId, equip)
    local _hero = module.HeroModule.GetManager():Get(heroId.id)
    local _skill = module.EquipRecommend.SortSkill(_hero)
    for i,v in ipairs(_skill) do
        if v.suitId == equip.cfg.suit_id then
            return i
        end
    end
    return 255
end

local function GetRoleRecomIndex(heroId, equip)
    local _class = module.EquipRecommend.GetClass(heroId)
    local _suitGroupCfg = HeroScroll.GetSuitConfig(equip.cfg.suit_id)
    local _suitCfg = _suitGroupCfg[2] and _suitGroupCfg[2][equip.quality]
    if _suitCfg and _suitCfg.class then
        for i,v in ipairs(_class) do
            if v.class == _suitCfg.class then
                return i
            end
        end
    end
    return 255
end

---快速装备
local function QuickToHero(uuid)
    local _cfg = equipModule.GetByUUID(uuid)
    if not _cfg then
        ERROR_LOG(uuid, "quick to hero not find")
        return
    end
    if _cfg.heroid ~= 0 and not _cfg.cfg then
        --ERROR_LOG(uuid, "quick to heroid", _cfg.heroid)
        return
    end
    local _heroTab = {}
    for i,v in ipairs(module.HeroModule.GetManager():GetFormation()) do
        if v ~= 0 and v ~= 11000 then
            local _hero = module.HeroModule.GetManager():Get(v)
            if _hero and _hero.level >= _cfg.showLevel then
                table.insert(_heroTab, {id = v, score = _hero.capacity})
            end
        end
    end
    table.sort(_heroTab, function(a, b)
        if a.score == b.score then
            return a.id > b.id
        end
        return a.score > b.score
    end)
    if module.HeroModule.GetManager():Get(11000).level >= _cfg.showLevel then
        table.insert(_heroTab, 1, {id = 11000})
    end
    if (not _cfg.cfg) or (not _cfg.cfg.type) then
        return
    end
    
    ---[===[--09.20根据角色推荐套装分组 比较装备，先比较分组 然后比品质
    for j,k in ipairs(BIT(_cfg.cfg.type)) do
        if k ~= 0 then
            if not equipmentConfig.GetEquipOpenLevel(0, j) then
                return
            end
            local _equipList = {}
            for i,v in ipairs(_heroTab) do
                if v.id ~= 0 then
                    local _equip = equipModule.GetHeroEquip(v.id, j)
                    local _oldUUid = nil
                    if _equip then
                        _oldUUid = _equip.uuid
                    end
                    table.insert(_equipList, {
                        heroId = v.id,
                        newUuid = uuid,
                        oldUuid = _oldUUid,
                        placeholder = j,
                        score = utils.EquipFormula.GetScore({heroId = v.id, uuid = uuid}),
                        suitIndex = GetRoleRecomIndex(v.id, _cfg),
                        heroScore = v.scorehero,
                        quality = _equip and _equip.quality or 0,
                        cfg = _cfg.cfg,
                    })
                end
            end
            table.sort(_equipList, function(a, b)
                if a.suitIndex ~= b.suitIndex then
                    return a.suitIndex < b.suitIndex
                end
                if a.quality ~= b.quality then
                    return a.quality > b.quality
                end
                return a.newUuid > b.newUuid
            end)
            
            for i,vc in ipairs(_equipList) do
                local _oldEquip = equipModule.GetHeroEquip(vc.heroId, vc.placeholder)
                if _oldEquip then
                    local _oldSuitIndex = GetRoleRecomIndex(vc.heroId, _oldEquip)
                    if vc.suitIndex==_oldSuitIndex then
                        if vc.quality>_oldEquip.quality then
                            return vc
                        end
                    elseif vc.suitIndex<_oldSuitIndex then
                        return vc
                    end
                else
                    return vc
                end
            end
        end
    end
    --]===]
    --[==[
    for j,k in ipairs(BIT(_cfg.cfg.type)) do
        if k ~= 0 then
            if not equipmentConfig.GetEquipOpenLevel(0, j) then
                return
            end
            for i,v in ipairs(_heroTab) do
                local _equip = equipModule.GetHeroEquip(v.id, j)
                if not _equip then
                    return {
                        heroId = v.id,
                        newUuid = uuid,
                        cfg = _cfg.cfg,
                        placeholder = j,
                    }
                else
                    --新需求
                    ---[[_0726
                    if _cfg.quality > _equip.quality then
                        return {
                            heroId = v.id,
                            newUuid = uuid,
                            cfg = _cfg.cfg,
                            placeholder = j,
                            oldUuid = _equip.uuid,
                        }
                    end
                    --]]
                    --[[candy_0726
                    local _new = module.EquipHelp.GetInscAddScore(v.id, uuid, j)
                    local _old = module.EquipHelp.GetInscAddScore(v.id, _equip.uuid, j)
                    if _new > _old then
                        return {
                            heroId = v.id,
                            newUuid = uuid,
                            cfg = _cfg.cfg,
                            placeholder = j,
                            oldUuid = _equip.uuid,
                        }
                    end
                    --]]
                end
            end
        end
    end
    --]==]
    --[[
    for j,k in ipairs(BIT(_cfg.cfg.type)) do
        if k ~= 0 then
            if not equipmentConfig.GetEquipOpenLevel(0, j) then
                return
            end
            local _equipList = {}
            for i,v in ipairs(_heroTab) do
                if v.id ~= 0 then
                    local _equip = equipModule.GetHeroEquip(v.id, j)
                    local _oldUUid = nil
                    if _equip then
                        _oldUUid = _equip.uuid
                    end
                    table.insert(_equipList, {
                        heroId = v.id,
                        newUuid = uuid,
                        oldUuid = _oldUUid,
                        placeholder = j,
                        score = utils.EquipFormula.GetScore({heroId = v.id, uuid = uuid}),
                        skillIndex = GetSkillIndex(v, _cfg),
                        heroScore = v.scorehero,
                        quality = v.quality,
                        cfg = _cfg.cfg,
                    })
                end
            end
            table.sort(_equipList, function(a, b)
                if a.skillIndex ~= b.skillIndex then
                    return a.skillIndex < b.skillIndex
                end
                if a.score ~= b.score then
                    return a.score > b.score
                end
                if a.quality ~= b.quality then
                    return a.quality > b.quality
                end
                return a.newUuid > b.newUuid
            end)
            for i,vc in ipairs(_equipList) do
                local _oldEquip = equipModule.GetHeroEquip(vc.heroId, vc.placeholder)
                if _oldEquip then
                    if vc.cfg.suit_id == _oldEquip.cfg.suit_id then
                        local _oldScore = utils.EquipFormula.GetScore({heroId = vc.heroId, uuid = vc.oldUuid})
                        if vc.score > _oldScore then
                            return vc
                        end
                    end
                else
                    return vc
                end
            end
        end
    end
    --]]
end

local quickToHeroList = {}

local function GetQuickToHeroList()
    return quickToHeroList
end

local showQuickToHeroFlag = true
local function ShowQuickToHero()
    --SGK.Action.DelayTime.Create(1):OnComplete(function()
        if not showQuickToHeroFlag then
            return
        end
        if #quickToHeroList >= 1 then
            if module.EquipHelp.QuickToHero(quickToHeroList[1]) == nil then
                showQuickToHeroFlag = true
                table.remove(quickToHeroList, 1)
                ShowQuickToHero()
                return
            end
            DispatchEvent("LOCLA_MAPSCENE_SHOW_QUICKTOHERO", quickToHeroList[1])
            --showQuickToHeroFlag = false
            --table.remove(quickToHeroList, 1)
        end
    --end)
end

local function RemoveQuick()
    -- if #quickToHeroList >= 1 then
    --     table.remove(quickToHeroList, 1)
    -- end
    quickToHeroList = {}
end

local function OpenFlag()
    showQuickToHeroFlag = false
end

local function ResetFlag()
    showQuickToHeroFlag = true
end

local function GetInscAddScore(heroId, uuid, placeholder, suits)
    local _score = 0
    suits = suits or 0
    local _cfg = equipModule.GetByUUID(uuid)
    if not _cfg then
        return _score
    end
    local _oldInsc = equipModule.GetHeroEquip(heroId, placeholder, suits)
    if _oldInsc then
        local _heroCfg = module.HeroModule.GetManager():Get(heroId)
        local _heroProperty = {}
        if _heroCfg then
            for k,v in pairs(_heroCfg.property_list or {}) do
                _heroProperty[k] = v
            end
            local _oldTab = {}
            if _oldInsc.type == 0 then
                _oldTab = module.equipmentModule.CaclPropertyByEq(_oldInsc)
            elseif _oldInsc.type == 1 then
                _oldTab = module.InscModule.CaclPropertyByInsc(_oldInsc)
            end
            for k,v in pairs(_oldTab) do
                if _heroProperty[k] then
                    _heroProperty[k] = _heroProperty[k] - v
                end
            end
            local _nowTab = {}
            if _cfg.type == 0 then
                _nowTab = module.equipmentModule.CaclPropertyByEq(_cfg)
            elseif _cfg.type == 1 then
                _nowTab = module.InscModule.CaclPropertyByInsc(_cfg)
            end
            for k,v in pairs(_nowTab) do
                _heroProperty[k] = (_heroProperty[k] or 0) + v
            end
            _score = utils.Property(_heroProperty).capacity - _heroCfg.capacity
        end
    else
        local _nowTab = {}
        local _propertyTab = {}
        local _heroCfg = module.HeroModule.GetManager():Get(heroId)
        local _heroProperty = {}

        if _cfg.type == 0 then
            _nowTab = module.equipmentModule.CaclPropertyByEq(_cfg)
        elseif _cfg.type == 1 then
            _nowTab = module.InscModule.CaclPropertyByInsc(_cfg)
        end

        if _heroCfg then
            for k,v in pairs(_heroCfg.property_list or {}) do
                _heroProperty[k] = v
            end
            for k,v in pairs(_nowTab) do
                _heroProperty[k] = (_heroProperty[k] or 0) + v
            end
        end
        _score = utils.Property(_heroProperty).capacity - _heroCfg.capacity
    end
    return _score
end

utils.EventManager.getInstance():addListener("LOCAL_EQUIP_QUERY_QUICKTOHERO", function(event, data)
    showQuickToHeroFlag = true
    ShowQuickToHero()
end)

utils.EventManager.getInstance():addListener("LOCAL_DIALOGSTACK_POP", function(event, data)
    showQuickToHeroFlag = true
end)

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, data)
    showQuickToHeroFlag = true
end)


utils.EventManager.getInstance():addListener("LOCAL_EQUIP_INFO_BEFORE", function(event, data)
    --do return end
    if not OpenLevel.GetStatus(1321) then
        return
    end
    local System_Set_data=UserDefault.Load("System_Set_data");
    local EquipMentChangeNotify=System_Set_data.EquipMentChangeNotify==nil and true or System_Set_data.EquipMentChangeNotify
    if not EquipMentChangeNotify then
        return
    end
    for i,v in ipairs(quickToHeroList) do
        local _equip = equipModule.GetByUUID(v)
        if not _equip then
            table.remove(quickToHeroList, i)
        end
    end
    
    local unLoadEquipList = equipModule.GetUnLoadEquipList()
    --新获得的装备才推荐
    if not unLoadEquipList[data] then
        table.insert(quickToHeroList, data)
        table.sort(quickToHeroList, function(a, b)
            local _a = equipModule.GetByUUID(a)
            local _b = equipModule.GetByUUID(b)
            if _a.quality == _b.quality then
                if _a.level == _b.level then
                    return a > b
                else
                    return _a.level > _b.level
                end
            else
                return _a.quality > _b.quality
            end
        end)
    end

    if #quickToHeroList == 1 then
        SGK.Action.DelayTime.Create(1):OnComplete(function()
            ShowQuickToHero()
        end)
    end
end)

local function getQualityCount(heroId, typeId, quality)
    local _equipList = module.equipmentModule.GetHeroEquip(heroId)
    local _count = 0
    for k,v in pairs(_equipList) do
        if v.type == typeId then
            if quality == nil or v.quality >= quality then
                if v.suits == 0 then
                    _count = _count + 1
                end
            end
        end
    end
    return _count
end

local function  getSuitCount(heroId, typeId)
    local _equipList = module.equipmentModule.GetHeroEquip(heroId)
    local _countList = {}
    for k,v in pairs(_equipList) do
        if v.type == typeId then
            if not _countList[v.cfg.suit_id] then
                _countList[v.cfg.suit_id] = 0
            end
            _countList[v.cfg.suit_id] = _countList[v.cfg.suit_id] + 1
        end
    end
    return _countList
end

--X个芯片进阶至多少阶
local function getAdvCount(advId)
    local _count = 0
    local _equipList = module.equipmentModule.GetEquip()
    for k,v in pairs(_equipList) do
        local _advId = string.sub(tostring(v.cfg.id), -3, -3)
        if tonumber(_advId) >= advId then
            _count = _count + 1
        end
    end
    return _count
end

local showPropretyTab = nil
local function GetEquipShowProprety(id)
    if showPropretyTab == nil then
        showPropretyTab = {}
        DATABASE.ForEach("equipment_show", function(data)
            local _proprety = {}
            for i=1,5 do
                if data["type"..i]~=0 and data["value"..i]~=0 then
                    table.insert(_proprety,{key=data["type"..i],allValue = data["value"..i]})
                end
            end
            showPropretyTab[data.id] = {isRandom =data.israndom,proprety = _proprety}
        end)
    end
    if id then
        return showPropretyTab[id]
    end
end

--装备锁定功能
local User_Equip_data = nil
local lockedEquipList = nil
local function CheckEquipLockStatus(type,id,uuid)
    if not lockedEquipList then
        User_Equip_data = UserDefault.Load("User_Equip_data",true);
        lockedEquipList = User_Equip_data.lockedEquipTab or {}
    end
    if lockedEquipList[type] and lockedEquipList[type][id] and lockedEquipList[type][id][uuid] then
        return true
    end
    return false
end

local function ChangeEquipLockStatus(type,id,uuid)
    if lockedEquipList[type] and lockedEquipList[type][id] and lockedEquipList[type][id][uuid] then
        lockedEquipList[type][id][uuid] = nil
        showDlgError(nil,SGK.Localize:getInstance():getValue("zhuangbeijiesuo_tip"))
    else
        lockedEquipList[type] = lockedEquipList[type] or {}
        lockedEquipList[type][id] = lockedEquipList[type][id] or {}
        lockedEquipList[type][id][uuid] = true
        showDlgError(nil,SGK.Localize:getInstance():getValue("zhuangbeisuoding_tip"))
    end
    User_Equip_data.lockedEquipTab = User_Equip_data.lockedEquipTab or {}
    User_Equip_data.lockedEquipTab[type] = User_Equip_data.lockedEquipTab[type] or {}
    User_Equip_data.lockedEquipTab[type][id] = User_Equip_data.lockedEquipTab[type][id] or {}
    User_Equip_data.lockedEquipTab[type][id][uuid] = lockedEquipList[type][id][uuid]
    UserDefault.Save()
end

--装备方案
local User_Equip_PlanList = nil
local localEquipPlanList = nil
local function GetPlan()
    if not localEquipPlanList then
        User_Equip_PlanList = UserDefault.Load("User_Equip_PlanList",true);
        localEquipPlanList = User_Equip_PlanList or {}
    end 
    table.sort(localEquipPlanList,function (a,b)
        if a.status ~= b.status then
            return a.status
        end
    end)
    return localEquipPlanList
end

local function ChangePlan(oldName,name,status,uuidTab)
    if not localEquipPlanList then
        GetEquipPlanList()
    end

    local _selectIdx = 0
    for i=1,#localEquipPlanList do
        if localEquipPlanList[i].name == oldName then
            _selectIdx = i
            break
        end
    end

    if localEquipPlanList[_selectIdx] then
        if uuidTab then
            localEquipPlanList[_selectIdx].EquipTab = uuidTab
        else
            if name then
                localEquipPlanList[_selectIdx].name = name
            else
                localEquipPlanList[_selectIdx].status = status
            end
        end
        DispatchEvent("LOCAL_EQUIPPLAN_CHANGE")
        User_Equip_PlanList = User_Equip_PlanList or {}
        User_Equip_PlanList[_selectIdx] = localEquipPlanList[_selectIdx]
        UserDefault.Save()
    end
end

local function RemovePlan(name)
    if not localEquipPlanList then
        GetEquipPlanList()
    end
    local _removeIdx = 0
    for i=1,#localEquipPlanList do
        if localEquipPlanList[i].name == name then
            _removeIdx = i
            break
        end
    end
    table.remove(localEquipPlanList,_removeIdx)
    DispatchEvent("LOCAL_EQUIPPLAN_CHANGE")
    User_Equip_PlanList = localEquipPlanList
    UserDefault.Save()
end

local function AddPlan(name,uuids)
    if not localEquipPlanList then
        GetEquipPlanList()
    end
    local planIdx = #localEquipPlanList+1

    localEquipPlanList[planIdx] = {}
    localEquipPlanList[planIdx].name = name
    localEquipPlanList[planIdx].EquipTab = {}
    for k,v in pairs(uuids) do
        localEquipPlanList[planIdx].EquipTab[k] = v
    end
   
    DispatchEvent("LOCAL_EQUIPPLAN_CHANGE")

    User_Equip_PlanList = User_Equip_PlanList or {}
    User_Equip_PlanList[planIdx] = localEquipPlanList[planIdx]
    UserDefault.Save()
end

return {
    UnloadSuits = UnloadSuits,
    QuickToHero = QuickToHero,
    GetToHeroList = GetQuickToHeroList,
    ShowQuickToHero = ShowQuickToHero,
    GetInscAddScore = GetInscAddScore,
    QuickLevelUp = QuickLevelUp,
    QuickEquipQuenching = QuickEquipQuenching,
    OpenFlag = OpenFlag,
    ResetFlag = ResetFlag,
    RemoveQuick = RemoveQuick,
    GetQualityCount = getQualityCount,
    GetSuitCount = getSuitCount,
    GetAdvCount = getAdvCount,

    GetEquipShowProprety = GetEquipShowProprety,--装备的 显示用属性

    CheckEquipLockStatus = CheckEquipLockStatus,--查看装备锁定状态
    ChangeEquipLockStatus = ChangeEquipLockStatus,--更改装备锁定状态

    GetPlan = GetPlan,--获取装备方案
    AddPlan = AddPlan,--保存方案
    RemovePlan = RemovePlan,--删除方案
    ChangePlan = ChangePlan,--修改方案
}
