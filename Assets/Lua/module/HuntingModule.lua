
local map_list = nil

local function GetMapList()
    if map_list == nil then
        map_list = LoadDatabaseWithKey("shoulie", "map_id");
    end
    return map_list;  
end

local function GetMapInfo(id)
    local list = GetMapList()
    return list[id]
end


-- 1300 十倍
-- 1301 十倍已领取   
-- 2300 单倍
-- 开双  8号商店  1080001
-- 关双  8号商店  1080002

local function GetCount() -- 单倍次数, 已领取多倍次数，锁定多倍次数
    return module.ItemModule.GetItemCount(2300), module.ItemModule.GetItemCount(1301), module.ItemModule.GetItemCount(1300);
end

local function LockPoint(n)  -- 锁定多倍点数
    if module.ItemModule.GetItemCount(1301) < n then
        return false;
    end
    module.ShopModule.Buy(8, 1080002, n); 
end

local function UnlockPoint(n) -- 使用多倍点数
    if module.ItemModule.GetItemCount(1300) < n then
        return false;
    end
    module.ShopModule.Buy(8, 1080001, n);
end

local function BuyPoint(n)  
    module.ShopModule.Buy(8, 1080003, n);
end

local isHunting = false;
local needCheck = {status = true, time = 0}
local function IsHunting(give_up)
    if needCheck.status or (module.Time.now() - needCheck.time) > 60 or (give_up and isHunting) then
        needCheck.status = false;
        needCheck.time = module.Time.now();
        local list = GetMapList()
        local cur_map = SceneStack.MapId();
        if list[cur_map] then
            local quest_list = module.QuestModule.GetList()
            for k,v in pairs(quest_list) do
                if v.status == 0 and v.bountyType and v.bountyType == list[cur_map].quest_id then
                    if give_up then
                        local teamInfo = module.TeamModule.GetTeamInfo();
                        if teamInfo.id == 0 or teamInfo.leader.pid == module.playerModule.GetSelfID() then
                            ERROR_LOG("放弃挂机")
                            module.QuestModule.RemoveQuest(v.id);
                        end
                    end
                    isHunting = true;
                    return true;
                end
            end
        end
        isHunting = false;
        return false;
    else
        return isHunting;
    end
end

local function Start(id)
    local list = GetMapList()
    if list[id] then
        module.BountyModule.Start(list[id].quest_id, true);
    end
end

local function CheckPlayerHuntingStatus()
    local pid = module.playerModule.GetSelfID();
    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.id ~= 0 then
        pid = teamInfo.leader.pid;
    end
    local mapPlayerStatus = module.TeamModule.GetmapPlayStatus(pid);
    print("<color=blue> 检查狩猎状态 </color>", IsHunting(), sprinttb(mapPlayerStatus))
    if IsHunting() then
        local one, have_ten, all_ten = GetCount();
        local status = have_ten > 0 and "hunting_ten" or "hunting"
        if mapPlayerStatus and mapPlayerStatus[1] == 1 and mapPlayerStatus[3] ~= status then
            utils.SGKTools.SynchronousPlayStatus({5,{0,module.playerModule.GetSelfID(), mapPlayerStatus[3]}})
            utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(), status}})
        else
            utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(), status}})
        end
    else
        if mapPlayerStatus and mapPlayerStatus[1] == 1 then
            utils.SGKTools.SynchronousPlayStatus({5,{0,module.playerModule.GetSelfID(), mapPlayerStatus[3]}})
        end
    end
end
utils.EventManager.getInstance():addListener("BOUNTY_TEAM_CHANGE", function(event, cmd, data)
    needCheck.status = true;
    CheckPlayerHuntingStatus();
end)


-- utils.EventManager.getInstance():addListener("START_BOUNTY_QUEST", function(event, cmd, data)
--     needCheck.status = true;
-- end)

-- utils.EventManager.getInstance():addListener("CANCEL_BOUNTY_QUEST", function(event, cmd, data)
--     needCheck.status = true;
-- end)

return {
    GetMapList = GetMapList,
    GetMapInfo = GetMapInfo,
    GetCount   = GetCount,
    LockPoint  = LockPoint,
    UnlockPoint = UnlockPoint,
    BuyPoint = BuyPoint,
    Start = Start,
    IsHunting = IsHunting,
    CheckPlayerStatus = CheckPlayerHuntingStatus,
}