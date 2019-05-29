local donationInfo = {}
local scienceInfo = {}
local refreshScienceList = {}
local scienceCfgList = nil
local function GetScienceCfg(id,type,lv)
    if not scienceCfgList then
        scienceCfgList = {}
        DATABASE.ForEach("guild_technology", function(row)
            local _cfg = row
            scienceCfgList[_cfg.type] = scienceCfgList[_cfg.type] or {}
            scienceCfgList[_cfg.type][_cfg.skill_level] = _cfg
            scienceCfgList[_cfg.type][_cfg.skill_level].consume = {}
            for i = 1, 2 do
                if _cfg["expend"..i.."_id"] ~= 0 and _cfg["expend"..i.."_value"] ~= 0 then
                    table.insert(scienceCfgList[_cfg.type][_cfg.skill_level].consume, {type = _cfg["expend"..i.."_type"], id = _cfg["expend"..i.."_id"], value = _cfg["expend"..i.."_value"]})
                end
            end
        end)
    end
    if id then
        return scienceCfgList[id]
    elseif type and lv then
        if scienceCfgList[type] and scienceCfgList[type][lv] then
            return scienceCfgList[type][lv]
        else
            return scienceCfgList
        end
    else
        return scienceCfgList
    end
end

local donationCfgList = nil
local function GetDonationCfg(id)
    if not donationCfgList then
        donationCfgList = {}
        DATABASE.ForEach("guildTech_donate", function(row)
            local _cfg = row
            donationCfgList[row.expend_id] = row
        end)
    end
    if id then
        return donationCfgList[id]
    end
    return donationCfgList
end

---查询捐献物资
local function queryItemInfo()

    ERROR_LOG("查询捐献物资");
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(3391, {nil})
    else
        utils.NetworkService.Send(3391, {nil})
    end
end

---捐献物资
local function AddItem(id)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(3393, {nil, id})
    else
        utils.NetworkService.Send(3393, {nil})
    end
end

---设置急需
local function SetUrgentItem(id)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(3411, {nil, id})
    else
        utils.NetworkService.Send(3411, {nil})
    end
end


---查询军团科技
local function queryScienceInfo()
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(3311, {nil})
    else
        utils.NetworkService.Send(3311, {nil})
    end
end

---提升军团科技
local function ScienceLevelUp(id)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(3313, {nil, id})
    else
        utils.NetworkService.Send(3313, {nil, id})
    end
end

local function QueryAll()
    queryItemInfo()
    queryScienceInfo()
end

local function upDonationInfo(data)
    donationInfo.itemList = {}
    for i,v in ipairs(data[3]) do
        donationInfo.itemList[v[4]] = {id = v[1], value = v[2], urgent = v[3] == 1, donate_id = v[4]}
    end
    donationInfo.setUrgentCount = data[4]
    donationInfo.donationCount = data[5]
end

local function refreshScienceData()
    for k,v in pairs(scienceInfo.scienceList or {}) do
        local _offTime = v.time - module.Time.now()
        if _offTime > 0 and (not refreshScienceList[k]) then
            refreshScienceList[k] = true
            SGK.Action.DelayTime.Create(_offTime + 1):OnComplete(function()
                queryScienceInfo()
                refreshScienceList[k] = nil
            end)
        end
    end
end

local function upScienceInfo(data)
    scienceInfo.scienceList = {}
    scienceInfo.material = {}
    for i,v in ipairs(data[3]) do
        scienceInfo.scienceList[v[1]] = {id = v[1], level = v[2], time = v[3]}
    end
    for i,v in ipairs(data[4]) do
        scienceInfo.material[v[1]] = {id = v[1], value = v[2]}
    end

    ERROR_LOG("军团科技信息查询",sprinttb(scienceInfo));
    refreshScienceData()
end

utils.EventManager.getInstance():addListener("server_respond_3392", function(event, cmd, data)

    ERROR_LOG("server_respond_3392",sprinttb(data))
    if data[2] == 0 then
        upDonationInfo(data)
        DispatchEvent("LOCAL_DONATION_CHANGE")
    end

end)

utils.EventManager.getInstance():addListener("server_respond_3312", function(event, cmd, data)
    print("server_respond_3312",sprinttb(data))
    if data[2] == 0 then
        upScienceInfo(data)
        DispatchEvent("LOCAL_SCIENCEINFO_CHANGE")
    end
end)

utils.EventManager.getInstance():addListener("server_respond_3412", function(event, cmd, data)
    print("server_respond_3412",sprinttb(data))
    if data[2] == 0 then
        donationInfo.setUrgentCount = 0
        DispatchEvent("LOCAL_DONATION_CHANGE")
    end
end)

utils.EventManager.getInstance():addListener("server_respond_3394", function(event, cmd, data)
    print("server_respond_3394",sprinttb(data))
    if data[2] == 0 then
        donationInfo.donationCount = donationInfo.donationCount + 1
        DispatchEvent("LOCAL_DONATION_CHANGE")
    end
end)

utils.EventManager.getInstance():addListener("server_notify_1143", function(event, cmd, data)
    if data[4] then
        donationInfo.itemList[data[4]] = {id = data[1], value = data[2], urgent = (data[3] == 1), donate_id = data[4]}
        DispatchEvent("LOCAL_DONATION_CHANGE")
    end
end)

utils.EventManager.getInstance():addListener("server_notify_1144", function(event, cmd, data)
    print("server_notify_1144")
    queryItemInfo()
    scienceInfo.scienceList[data[1]] = {id = data[1], level = data[2], time = data[3]}
    refreshScienceData()
    DispatchEvent("LOCAL_SCIENCEINFO_CHANGE")
    DispatchEvent("LOCAL_DONATION_CHANGE")
end)


local function GetScienceList()
    local _list = {}
    for i,v in pairs(scienceInfo.scienceList or {}) do
        if v.level then
            table.insert(_list, v)
        end
    end
    return _list
end

local function GetDonationInfo()
    return donationInfo or {}
end

local function GetScienceInfo(id)
    if not scienceInfo.scienceList then
        scienceInfo.scienceList = {}
    end
    return scienceInfo.scienceList[id]
end

local function IsResearching()
    for i,v in pairs(scienceInfo.scienceList or {}) do
        if v.time > module.Time.now() then
            return true
        end
    end
    return false
end

return {
    GetScienceCfg   = GetScienceCfg,
    GetDonationCfg  = GetDonationCfg,
    GetScienceList  = GetScienceList,
    GetScienceInfo  = GetScienceInfo,
    GetDonationInfo = GetDonationInfo,
    ScienceLevelUp  = ScienceLevelUp,
    SetUrgentItem   = SetUrgentItem,
    IsResearching   = IsResearching,
    AddItem         = AddItem,
    QueryAll        = QueryAll,
}
