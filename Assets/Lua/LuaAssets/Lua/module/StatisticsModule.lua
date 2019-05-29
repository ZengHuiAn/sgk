local _server_id;
local _server_name;

local function SetServerInfo(id, name)
    print("SetServerInfo", id, name);
    _server_id = id;
    _server_name = name;
end

utils.EventManager.getInstance():addListener("server_respond_4", function(event, cmd, data)
    _server_id = nil;
    _server_name = nil;
end);

local last_level = 0;
utils.EventManager.getInstance():addListener("PLAYER_INFO_CHANGE", function(event, pid)
    -- print("!! PLAYER_INFO_CHANGE !!", pid, module.playerModule.GetSelfID())

    if not _server_id then
        return;
    end

    if not CS.SDKScript.Call then
        return;
    end

    if pid ~= module.playerModule.GetSelfID() then
        -- print("!!! not self")
        return;
    end

    local player = module.playerModule.Get();

    if last_level == player.level then
        -- print("!!! not level change")
        return;
    end

    last_level = player.level;

    local union = module.unionModule.Manage:GetSelfUnion() or {}

    CS.SDKScript.Call("submitGameData", {
        tostring(player.id);
        player.name,
        "0",                          -- 当前登录玩家的职业 ID  -int
        "",                           -- 当前登录玩家的职业名称  -String
        "无",                         -- 玩家的性别 -String
        tostring(player.level),
        tostring(_server_id),
        _server_name,
        tostring(player.create_time),
        tostring(os.time()),                    -- 角色等级变化的时间 - String
        "0", -- 战斗值 - int
        tostring(player.vip or 0),    -- 当前用户 vip
        "",
        tostring(union.unionId or 0),            -- 玩家所在工会 ID - int
        union.unionName or "",                    -- 玩家所在工会名称 - String
        tostring(union.unionLevel or "0"),                   -- 玩家所在工会等级 - int
        tostring(module.unionModule.Manage:GetSelfTitle()),     -- 玩家所在工会的玩家称号 
        tostring(union.leaderId or "0"),           -- 玩家所在工会会长的账号
    })
end);


return {
    SetServerInfo = SetServerInfo,
}
