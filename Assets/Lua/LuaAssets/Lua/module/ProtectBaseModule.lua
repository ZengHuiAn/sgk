local ActivityInfo = {};

local function GetInfo()
    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.group ~= 0 then
        if ActivityInfo[teamInfo.id] == nil then
            ActivityInfo[teamInfo.id] = {};
            ActivityInfo[teamInfo.id].npc_uuid = 0;
        end
        return ActivityInfo[teamInfo.id];
    end
end

local function SetCurFightUUID(uuid)
    local info = GetInfo();
    if info then
        info.npc_uuid = uuid;
    end
end

local function CleanData()
    ActivityInfo = {};
end

local RandomIndex = {};
local WaveCount = {10, 11, 12, 13};
local function GetRandomPos(seed, positions)
    if RandomIndex[seed] == nil then
        RandomIndex[seed] = {};
        math.randomseed(seed);
        for _,v in ipairs(WaveCount) do
            local _positions = {};
            for i,k in ipairs(positions) do
                _positions[i] = k;
            end
            for j=1,v do
                local index = math.random(1, #_positions);
                table.insert(RandomIndex[seed], {_positions[index][1], _positions[index][2], _positions[index][3], 0});
                table.remove(_positions, index);
            end
        end
    end
    return RandomIndex[seed];
end

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, data)
    print("场景变换", data)
    if data == "battle" then
        -- local teamInfo = module.TeamModule.GetTeamInfo();
        -- print("测试", teamInfo)
        -- if teamInfo and teamInfo.group ~= 0 and ActivityInfo[teamInfo.id].npc_uuid ~= 0 then
        --     DispatchEvent("ADD_BASE_COUNTDOWN", ActivityInfo[teamInfo.id].npc_uuid);
        --     ActivityInfo[teamInfo.id].npc_uuid = 0;
        -- end
    elseif data ~= "map_jiayuan_defend" then
        CleanData();
    end
end)

utils.EventManager.getInstance():addListener("BATTLE_SCENE_READY", function(event, data)
    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo and teamInfo.group ~= 0 and ActivityInfo[teamInfo.id].npc_uuid ~= 0 then
        DispatchEvent("ADD_BASE_COUNTDOWN", ActivityInfo[teamInfo.id].npc_uuid);
        ActivityInfo[teamInfo.id].npc_uuid = 0;
    end
end)


return {
    GetInfo = GetInfo,
    SetCurFightUUID = SetCurFightUUID,
    GetRandomPos = GetRandomPos,
}