local reward_flags = {};
local function GetFlag(id)
    local rid  = math.floor(id / 50)
    local pos = id % 50

    local value = reward_flags[rid] or 0;
    return (value & (1<<pos)) ~= 0;
end

utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
    -- reward_flags = {}
    utils.NetworkService.Send(80, {});
end);

utils.EventManager.getInstance():addListener("server_respond_81", function(event, cmd, data)
    if data[2] ~= 0 then
        print("query one time reward failed");
        return;
    end

    -- print("query one time reward success")

    reward_flags = {}
    for _, v in ipairs(data[3]) do
        reward_flags[v[1]] = v[2];
    end
    utils.EventManager.getInstance():dispatch("ONE_TIME_REWARD_INFO_CHANGE");
end)

utils.EventManager.getInstance():addListener("server_notify_57", function(event, cmd, data)
    reward_flags[data[1]] = data[2];
    utils.EventManager.getInstance():dispatch("ONE_TIME_REWARD_INFO_CHANGE");
end)

local function GatherRewardSyn(id, func)
    if GetFlag(id) then
        if func then
            func()
        end
        return false;
    end

    coroutine.resume(coroutine.create(function()
        utils.NetworkService.SyncRequest(82, {nil, id})
        if func then
            func()
        end
    end))
end

local function GatherReward(id)
    if GetFlag(id) then
        print("reward recved")
        return false;
    end
    return utils.NetworkService.Send(82, {nil, id});
end

utils.EventManager.getInstance():addListener("server_respond_83", function(event, cmd, data)
    if data[2] ~= 0 then
        print("recv one time reward faield");
        return;
    end
    print("recv one time reward success");
end)


local one_time_reward_list_by_id = nil;
local one_time_reward_list_by_type = nil;

local function GetConfig(id)
    if one_time_reward_list_by_id == nil then
        one_time_reward_list_by_id = {}
        one_time_reward_list_by_type = {}

        DATABASE.ForEach("one_time_reward", function(cfg)
            local _tempTab = {}
            _tempTab.reward = {}
            _tempTab.id = cfg.id
            _tempTab.condition_type = cfg.condition_type
            _tempTab.condition_value = cfg.condition_value
            _tempTab.condition_id = cfg.condition_id
            _tempTab.consume_value = cfg.consume_value
            _tempTab.consume_id = cfg.consume_id
            _tempTab.consume_type = cfg.consume_type
            for i = 1, 4 do
                local _temp = {}
                _temp.id = cfg["reward"..i.."_id"]
                _temp.type = cfg["reward"..i.."_type"]
                _temp.value = cfg["reward"..i.."_value"]
                table.insert(_tempTab.reward, _temp)
            end
            one_time_reward_list_by_id[cfg.id] = _tempTab

            one_time_reward_list_by_type[cfg.condition_type] = one_time_reward_list_by_type[cfg.condition_type] or {}
            one_time_reward_list_by_type[cfg.condition_type][cfg.condition_id] = one_time_reward_list_by_type[cfg.condition_type][cfg.condition_id] or {}
            table.insert(one_time_reward_list_by_type[cfg.condition_type][cfg.condition_id], _tempTab);
        end)
    end
    return one_time_reward_list_by_id[id];
end

local function GetConfigByType(type, id)
    GetConfig(0);
    return one_time_reward_list_by_type[type] and one_time_reward_list_by_type[type][id];
end

local STATUS = {
    ERROR = 'ERROR',  -- 错误
    WAIT  = 'WAIT',   -- 未达成
    READY = 'READY',   -- 已达成
    DONE  = 'DONE',   -- 已领取
}

local function Check(id)
    local cfg = GetConfig(id);
    if not cfg then
        return STATUS.ERROR;
    end

    local function calcBattleStarCount(battle)
        local count = 0;
        for _, v in pairs(battle.pveConfig) do
            local fight = module.fightModule.GetFightInfo(v.gid);
            if fight then
                for i = 1, 3 do
                     if module.fightModule.GetOpenStar(fight.star, i) ~= 0 then
                        count = count + 1;
                     end
                end
            end
        end
        return count;
    end

    if cfg.condition_type == 1 then
        local chapter = module.fightModule.GetConfig(cfg.condition_id);
        if chapter == nil then
            return STATUS.ERROR;
        end

        local count = 0;
        for _, v in pairs(chapter.battleConfig) do
            count = count + calcBattleStarCount(v);
        end

        if count < cfg.condition_value then
            return STATUS.WAIT;
        end
    elseif cfg.condition_type == 2 then
        local battle = module.fightModule.GetConfig(nil, cfg.condition_id)
        if battle == nil then
            return STATUS.ERROR;
        end;

        if calcBattleStarCount(battle) < cfg.condition_value then
            return STATUS.WAIT;
        end
    elseif cfg.condition_type == 4 then

    else
        return STATUS.ERROR;
    end

    if GetFlag(id)then
        return STATUS.DONE;
    else
        return STATUS.READY;
    end
end

return {
    GetFlag = GetFlag,
    Check = Check,
    Gather = GatherReward,
    GatherSyn = GatherRewardSyn, 

    GetConfig = GetConfig,
    GetConfigByType = GetConfigByType,

    STATUS = STATUS,
}
