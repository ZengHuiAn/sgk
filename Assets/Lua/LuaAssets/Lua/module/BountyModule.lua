local BOUNTY_MIN_TEAM_MEMBER_COUNT = 1
local BOUNTY_NORMAL_COUNT = 100
local BOUNTY_DOUBLE_COUNT = 10
local BOUNTY_ROUND_COUNT = 10

local questConfig = nil;
local questReward = nil
local function loadQuestConfig(id)
    if questConfig == nil then
        questConfig = {}
        questReward = {}

        DATABASE.ForEach("bounty_quest", function(data)
            local qid = data.quest_id;

            questConfig[qid] = data;
            -- map_id
            -- weight
            -- times
            -- name
            -- desc

            local _rewardTab = {}
            for i = 1, 3 do
                local _tab = {}
                if data["reward_type"..i] then
                    _tab.type = data["reward_type"..i]
                    _tab.id = data["reward_id"..i]
                    _tab.value = data["reward_value"..i]
                    table.insert(_rewardTab, _tab)
                end
            end
            questReward[qid] = _rewardTab
        end)
    end
    return questConfig[id];
end

local function getReward(id)
    if not questReward then
        loadQuestConfig(id)
    end
    return questReward[id]
end

local bounty_data = {
    {
        quest = nil,
        count = 0,
        next_fight_time = 0,

        normal_count = 0,
        double_count = 0,
    }
}

local function updateBountyPlayerData(data)
    -- print("<color=red> updateBountyPlayerData", data[1], data[2], data[3], "</color>")
    local a_id = data[3] or 1;

    bounty_data[a_id] = bounty_data[a_id] or {};

    bounty_data[a_id].normal_count = data[1]
    bounty_data[a_id].double_count = data[2]

    utils.EventManager.getInstance():dispatch("BOUNTY_PLAYER_CHANGE")
end

local function tryFight(a_id)
    print('bounty fight', a_id)
    a_id = a_id or 1;

    local team = module.TeamModule.GetTeamInfo();
    -- if team.id <= 0 then
    --     print('  no in team')
    --     return false;
    -- end

    -- if #team.members < BOUNTY_MIN_TEAM_MEMBER_COUNT then
    --     print('  no enough members')
    --     return false;
    -- end

    if not bounty_data[a_id] or not bounty_data[a_id].quest then
        print('  no quest')
        return false;
    end

    if team.id > 0 and team.leader.pid ~= module.playerModule.GetSelfID() then
        print('  not team leader')
        return false;
    end

    if module.Time.now() < bounty_data[a_id].next_fight_time then
        print('  no in time')
        return false;
    end

    return utils.NetworkService.Send(16096, {nil, a_id})
end

local function updateBountyTeamData(data, isNotify)
    print("<color=blue> updateBountyTeamData </color>", data[1], data[2], data[3], data[4])

    local a_id = data[4] or 1;

    local info = bounty_data[a_id];
    if not info then
        info = {normal_count = 0, double_count = 0}
        bounty_data[a_id] = info;
    end
    info.quest = loadQuestConfig(data[1]);

    -- print("--", info.quest);

    info.count = data[2]
    info.next_fight_time = data[3] or info.next_fight_time

    if info.quest_uuid and ( (not info.quest) or (info.count >= info.quest.times)) then
        module.EncounterFightModule.RemoveFightDataByType("bounty_" ..  info.quest_uuid);

        module.QuestModule.RemoveQuest(info.quest_uuid)
        info.quest_uuid = nil;
        info.quest_info = nil;
        info.quest = nil;
    end

    if info.quest and (info.count < info.quest.times) then
        if not info.quest_info then
            info.quest_info = setmetatable({number = info.count + 1, status = 0}, {__index=info.quest});
        end

        info.quest_info.name = info.quest.name .. "(" ..  (info.count) .."/" .. info.quest.times .. ")"
        info.quest_info.number = info.count + 1
        info.quest_info.desc = info.quest.desc;
        info.quest_info.reward = getReward(data[1]) or {}
        info.quest_info.bountyId = info.quest.quest_id
        info.quest_info.bountyType = info.quest.activity_id
        info.quest_info.icon = info.quest.icon
        info.quest_info.mapId = info.quest.map_id

        local team = module.TeamModule.GetTeamInfo()

        local rng = WELLRNG512a(info.next_fight_time + team.id);
        info.quest_info.random_hit = rng();

        info.quest_uuid = module.QuestModule.RegisterQuest(info.quest_info)

        if (team.id == 0 or utils.SGKTools.isTeamLeader()) and isNotify and info.count < info.quest.times then
            module.QuestModule.StartQuestGuideScript(info.quest_info, true)
        end
        if info.count >= info.quest.times then
            utils.SGKTools.Stop()
        end
        if  info.count < info.quest.times and info.quest.mode_id == 0 then
            module.EncounterFightModule.SetFightData({type = "bounty_" .. info.quest_uuid, map_id = info.quest.map_id,depend_level = info.quest.depend_level,fun = function()
                tryFight(a_id);
            end});
        end
    else
        info.quest = nil;
    end

    utils.EventManager.getInstance():dispatch("BOUNTY_TEAM_CHANGE")
end

local function cleanBountyTeamData()
    for k, v in pairs(bounty_data) do
        updateBountyTeamData({0, 0, 0, k})
    end
end

local function getBountyInfo(a_id)
    return bounty_data[a_id or 1] or {
        normal_count = 0,
        double_count = 0,
    };
end

local function startBounty(a_id, not_check_team)
    a_id = a_id or 1;
    print('bounty start', a_id)

    -- if not not_check_team then
    --     local team = module.TeamModule.GetTeamInfo();
    --     if team.id <= 0 then
    --         print('  no in team')
    --         return false;
    --     end
    --     if team.leader.pid ~= module.playerModule.GetSelfID() then
    --         print('  not team leader')
    --         return false;
    --     end

    --     if #team.members < BOUNTY_MIN_TEAM_MEMBER_COUNT then
    --         print('  no enough members')
    --         return false;
    --     end
    -- end

    if bounty_data[a_id] and bounty_data[a_id].quest then
        print('  already have quest')
        module.QuestModule.StartQuestGuideScript(bounty_data[a_id].quest_info, true)
        return false;
    end

    return utils.NetworkService.Send(16092, {nil, a_id})
end

local function cancelBounty(a_id)
    a_id = a_id or 1;

    print('bounty cancel', a_id)
    -- local team = module.TeamModule.GetTeamInfo();
    -- if team.id <= 0 then
    --     print('  no in team')
    --     return false;
    -- end
    
    -- if team.leader.pid ~= module.playerModule.GetSelfID() then
    --     print('  not team leader')
    --     return false;
    -- end

    if not bounty_data[a_id] or not bounty_data[a_id].quest then
        print('  no quest')
        return false;
    end

    return utils.NetworkService.Send(16094, {nil, a_id})
end

-- utils.EventManager.getInstance():addListener('server_respond_16093', function(event, cmd, data)
--     DispatchEvent("START_BOUNTY_QUEST");
-- end)
-- utils.EventManager.getInstance():addListener('server_respond_16095', function(event, cmd, data)
--     DispatchEvent("CANCEL_BOUNTY_QUEST");
-- end)

utils.EventManager.getInstance():addListener("server_notify_16090", function(event, cmd, data)
    print("<color=red> bounty team info received </color>", data[5], data[6])

    updateBountyTeamData(data, true);

    if data[5] then
        utils.EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", 1, data[5]);

        if true then return end--策划需求隐藏该 UI

        local texts = {
            [0] = "次数用完",
            [1] = "队员奖励",
            [2] = "队员双倍",
            [5] = "队长奖励",
            [6] = "队长双倍",
        }

        local text = texts[data[6] or 0]
        if not text then
            print("<color=red>", "reward type not exists", "</color>")
            return;
        end

        local prefab = SGK.ResourcesManager.Load("prefabs/battlefield/BountyRewardInfo.prefab")
        if not prefab then
            print("load prefab failed")
            return;
        end

        local o = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab));
        if not o then
            print("Instantiate faield")
            return
        end

        o.Text[UnityEngine.UI.Text].text = text;
        utils.EventManager.getInstance():dispatch("ADD_OBJECT_TO_FIGHT_RESULT", o.gameObject);
    end
end)

utils.EventManager.getInstance():addListener("server_notify_16091", function(event, cmd, data)
    updateBountyPlayerData(data);
end)


utils.EventManager.getInstance():addListener("TEAM_INFO_CHANGE", function(event, teamInfo)
    if teamInfo and teamInfo.id == 0 then
        cleanBountyTeamData();
    else
        utils.NetworkService.Send(16090)
    end
    -- local team = module.TeamModule.GetTeamInfo();
    -- if team.id <= 0 then
    --     cleanBountyTeamData();
    -- else
    --     utils.NetworkService.Send(16090)
    -- end
end)

utils.EventManager.getInstance():addListener('server_respond_16091', function(event, cmd, data)
    if data[2] ~= 0 then
        print('query bounty info failed', data[2])
        return
    end

    local n = #data;

    for _, v in ipairs(data[3] or {}) do
        updateBountyTeamData(v)
    end

    for _, v in ipairs(data[4] or {}) do
        updateBountyPlayerData(v);
    end
end);

return {
    Get     = getBountyInfo,
    Start   = startBounty,
    Cancel  = cancelBounty,
    Fight   = tryFight,
}

-- NOTIFY_BOUNTY_CHANGE   = 16090 -- {quest, record, next_fight_time}


-- TEAM_INFO_CHANGE
