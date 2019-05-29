local Game = require "battlefield2.Game"

local t = 0

local delay = false;

local delay_queue = {}

local message_queue = {}
if not delay then
    message_queue = root.message_queue
end

local prepare_co = nil;
local cached_commands = nil;

local T = {
    FIGHT_START           = 1,
    MONSTER_ENTER         = 2,
    MONSTER_DEAD          = 3,
    PLAYER_READY          = 4,
    CHARACTER_DEAD        = 5,
    PLAYER_FINISHED       = 6,
    FIGHT_FINISHED        = 7,
    PLAYER_COMMAND        = 8,
    KILL_COMMAND          = 9,
    PLAYER_BACK           = 10,
    VOTE_TO_EXIT          = 11,
}

function Preload()
    game:AddSystem("SyncClient").SetReader(game, function()
        local msg = message_queue[1]
        if msg then
            table.remove(message_queue, 1)
            return msg.tick, msg.event, msg.data;
        end
    end)

    root.game.client = true

    if not root.args.remote_server then
        -- [[
        root.server = Game('server');
        -- root.server:AddSystem("Timeout").SetTimeout(root.server, 30, 0)
        root.server:AddSystem("SyncServer").SetWriter(root.server, function(tick, event, data)
            table.insert(root.message_queue, {tick=tick, event=event, data=data});
        end)
        --]]

        local game = root.server or root.game;

        game:AddSystem("Round");  -- work as server
        game:AddSystem("RNG");

        local decoder = game:AddSystem("Decoder")
        decoder.SetFightData(game, root.fight_data);

        game:SetAutoInput(true, root.fight_data.defender.pid)

        if root.args.worldBoss or root.args.rankJJC then
            game:SetAutoInput(true)
        end

        for i = 1, 3 do  game:Tick();  end
        return
    end

    module.TeamModule.SyncFightData(T.PLAYER_READY, 1); -- 请求战斗数据
    cached_commands = {};

    prepare_co = coroutine.running();
    coroutine.yield();
end

function Start()
    if not root.args.remote_server then
        LoadingProgress(0.5, "准备战斗");
        if root.server then
            root.server:Start();
        end

        local main_game = root.server or root.game;

        while main_game.round_info == nil or main_game.round_info.wave <= 0 do
            if root.server then 
                root.server:Update(0.1);
            end
            root.game:Update(0.1);
            root.eventManager:Tick();
        end
        return;
    end

    print('send PLAYER_READY', 2, root:GetPlayerSettings().auto_input)
    module.TeamModule.SyncFightData(T.PLAYER_READY, 2); -- 战斗已经准备好
    if root:GetPlayerSettings().auto then
        ERROR_LOG("SENT AUTO INPUT")
        SendPlayerCommand(0, 99036, 1);
    end

    for _, v in ipairs(cached_commands) do
        table.insert(message_queue, v);
    end

    cached_commands = nil;
end

local sync_target_maps = {
    enemy   = 100,
    partner = 101,
}

function SendPlayerCommand(uuid, skill, target)
    print('SendPlayerCommand', uuid, skill, target);
    -- TODO: send input to server

    local cmd = {
        type    = "INPUT",
        sync_id = uuid,
        skill   = skill,
        target  = sync_target_maps[target] or target;
    }
    module.TeamModule.SyncFightData(T.PLAYER_COMMAND, {ProtobufEncode({commands={cmd}}, "com.agame.protocol.FightCommand")})
end

function VoteToExit(vote)
    module.TeamModule.SyncFightData(T.VOTE_TO_EXIT, {vote or 1});
end

vote_end_time = nil
local function StartVoteToExit(pids, pid, end_time)
    vote_end_time = end_time;
    local player = module.playerModule.Get(pid);

    DialogStack.PushPref("PlayerVote", {
        EndTime = end_time,
        list = pids,
        oneselfVote = function(status)
            module.TeamModule.SyncFightData(T.VOTE_TO_EXIT, {status});
        end,
        --title = (player and player.name or "") .. "申请结束战斗",
        title = "<size=44>申</size>请投降",
    });
end

function EVENT.FIGHT_DATA_SYNC(_, cmd, data)
    if cmd == T.PLAYER_COMMAND then
        if #data > 0 and #message_queue == 0 and not cached_commands then
            local tick = data[1][1];
            for k = root.game.tick, tick - 1 do
                root.game:Update(0.1)
            end
        end

        for k, v in ipairs(data) do
            -- print('PLAYER_COMMAND', v[1], v[2], v[3])
            if cached_commands then
                table.insert(cached_commands, {tick = v[1], event = v[2], data = v[3]})
            else
                table.insert(message_queue, {tick = v[1], event = v[2], data = v[3]})
            end
        end
    elseif cmd == T.PLAYER_READY then
        print('PLAYER_READY respond')
        root.game:Decode(data);
        coroutine.resume(prepare_co);
    elseif cmd == T.FIGHT_FINISHED then
        print('FIGHT_FINISHED', data[1]);
        DispatchGlobalEvent("PlayerVoteFinish");
        ShowResultPanel(data[1]);
        -- self:Notify(Command.NOTIFY_FIGHT_SYNC, {T.FIGHT_FINISHED, {winner or 0, amfScore} });
    elseif cmd == T.VOTE_TO_EXIT then
        -- TODO:
        local status = data[1];
        ERROR_LOG("VOTE_TO_EXIT", unpack(data));
        if status == 3 then
            StartVoteToExit(data[2], data[3], data[4]);
        elseif status == 0 then
            DispatchGlobalEvent("PlayerVoteRef", {{data[2], 0}} );
            DispatchGlobalEvent("PlayerVoteFinish");
        elseif status == 1 then
            DispatchGlobalEvent("PlayerVoteRef", {{data[2], 1}} );
        end
    end
end

if not delay then return end
-- delay test
function Update(dt)
    t = t + dt;

    while true do
        local msg = root.message_queue[1];
        if not msg then
            break;
        end

        table.remove(root.message_queue, 1)

        table.insert(delay_queue, {t = t + math.random(1, 300) / 100, msg = msg})
    end


    while true do
        local info = delay_queue[1];
        if not info  or  t <= info.t then
            break;
        end

        table.remove(delay_queue, 1)
        table.insert(message_queue, info.msg);
    end
end
