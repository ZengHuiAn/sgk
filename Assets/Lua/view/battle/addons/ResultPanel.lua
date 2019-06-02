local Statistics = require 'battlefield2.system.Statistics'

local resultFrame = nil;
local resultFrame_args = nil;

local resultWinner = nil
local saved_rewards = {}

local result_panel_game_object = nil;

local star_status = {}
local star_info = {}

local player_side = GetPlayerSide()
local heroExpInfoList = {}
local roles = {}

local ShowExtraSpoilsData
local ShowRollData = false

local function showResult(winner, rewards)
    root.view.battle.partnerStage:SetActive(false);
    root.view.battle.Canvas.timelinePanel:SetActive(false)
    root.view.battle.Canvas.TopRight:SetActive(false);
    root.view.battle.EnemyBossCanvas:SetActive(false);
    root.view.battle.Canvas.RoundInfo:SetActive(false);
    root.view.battle.Canvas.UIRootTop:SetActive(false);

    resultFrame_args = {winner, rewards}

    if resultFrame == nil then
        resultFrame = "loading"
        LoadAsync("prefabs/fightResult/FightResultFrame.prefab", function(o)
            resultFrame = SGK.UIReference.Instantiate(o, root.view.battle.Canvas.UIRoot.transform)
            showResult(resultFrame_args[1], resultFrame_args[2])
        end)
    end

    if resultFrame == "loading" then
        return;
    end

    SGK.BackgroundMusicService.Pause()

    local playerCount = 0
    for k,v in pairs(roles) do
        playerCount = playerCount+1
    end

    panel = resultFrame;
    panel.transform:SetParent(root.view.battle.Canvas.UIRoot.transform, false);

    panel[SGK.LuaBehaviour]:Call("Init",{winner,root.args})

    if rewards and next(rewards) then
        resultFrame[SGK.LuaBehaviour]:Call("UpdateReward",rewards)
    end

    --统计界面信息
    local _fightValue = {}
    if playerCount>0 then
        local valueTab = game.statistics.partners
        for k,v in pairs(roles) do
            local pid = k
            for _k,_v in pairs(v) do
                local pos = _v.pos
                local health = valueTab[pos] and valueTab[pos].health or 0
                local hurt = valueTab[pos] and valueTab[pos].hurt or 0
                local damage = valueTab[pos] and valueTab[pos].damage or 0
                _fightValue[pid] = _fightValue[pid] or {}
                table.insert(_fightValue[pid],setmetatable({
                    health = health,
                    hurt = hurt,
                    damage = damage,
                },{__index =_v}))
            end
        end
        panel[SGK.LuaBehaviour]:Call("SetStatisticsValue",{_fightValue,root.args.remote_server})
    end

    if root.args.remote_server then--多人战斗
        local teamFightRewards = rewards

        local syncFightFlag = module.TeamModule.GetSyncFightFlag()
        if syncFightFlag == 0 then
            --多人副本
            -- ERROR_LOG("winner",winner)
            local anim_type = winner == 1 and 2 or 4
            panel[SGK.LuaBehaviour]:Call("SetResultType",{{_fightValue,teamFightRewards},anim_type,true})
        elseif syncFightFlag == 1 then
            print("特殊的单人战斗")
            local anim_type = winner == 1 and 3 or 4
            panel[SGK.LuaBehaviour]:Call("SetResultType",{{},anim_type,true})
        end
        --多人战斗奖励
        panel[SGK.LuaBehaviour]:Call("UpdateReward",teamFightRewards)
        if ShowExtraSpoilsData or ShowRollData then
            panel[SGK.LuaBehaviour]:Call("UpdatePubRewardData",{ShowExtraSpoilsData,ShowRollData})
        end
    else
        if star_status and next(star_status) and playerCount < 2 then--单人战斗副本
            local partners = roles[module.playerModule.GetSelfID()]
            local anim_type = winner == 1 and 1 or 4
            panel[SGK.LuaBehaviour]:Call("SetResultType",{{star_status,star_info,rewards,partners,heroExpInfoList},anim_type})
        else
            local anim_type = winner == 1 and 3 or 4
            panel[SGK.LuaBehaviour]:Call("SetResultType",{{},anim_type})
        end
        --单人战斗奖励
        panel[SGK.LuaBehaviour]:Call("UpdateReward",rewards)
    end
    --root.args.remote_server true 为 多人战斗
    --TeamModule.GetFightReward 获取 多人 战斗 奖励
    if result_panel_game_object then
        panel[SGK.LuaBehaviour]:Call("AddResultObject",result_panel_game_object)
    end
end

function ShowResultPanel(winner, rewards)
    -- ERROR_LOG("winner",winner)
    resultWinner = winner
    showResult(winner, rewards);
end

local function addEntity(entity)
    if not entity.Input then return end
    if not entity.Round then return end;
    if not entity.Force then return end;

    if roles[entity.Force.pid] and roles[entity.Force.pid][entity.uuid] then
        return
    end

    if entity.Force.side == player_side then
        roles[entity.Force.pid] = roles[entity.Force.pid] or {}
        roles[entity.Force.pid][entity.uuid] = setmetatable({pos = entity.uuid},{__index = entity.Config})
    end
end

local function loadStoryBeforeResult(winner, rewards)
    local cfg = module.fightModule.GetPveConfig(root.args.fight_id)
    if cfg and cfg._data and cfg._data.after_fight_story_id and cfg._data.after_fight_story_id ~= 0 and not root.remote_server then
        LoadAsync("prefabs/battlefield/storyloading.prefab", function(o)
            if not o then return end
            loading = SGK.UIReference.Instantiate(o)
            loading.transform:SetParent(root.view.battle.Canvas.UIRoot.transform, false);
        end)

        LoadStory(cfg._data.after_fight_story_id, nil, nil, function()
            showResult(winner, rewards);
        end)
    else
        showResult(winner, rewards);
    end
end

local function onFightFinish(winner)
    --星星状态 和星星条件
    star_status,star_info = Statistics.CheckStar(game); 
    
    local do_not_exist = false;

    if root.args and root.args.callback then
        local record_list = {};

        local real_game = root.server or game;
        for k, v in pairs(real_game.statistics.event_records[root.pid] or {}) do
            if v ~= 0 then
                table.insert(record_list, {k, v})
            end
        end
        local code = ProtobufEncode({commands = game.statistics.input_records}, "com.agame.protocol.FightCommand")
        local input_heros = {}
        do_not_exist = root.args.callback(
                winner == 1, 
                input_heros,           -- TODO: input heros
                GetFightData().id or 0,
                star_status,
                code,                  -- TODO: input queue
                { record = record_list }       -- TODO: event record
        ); 
        root.args.callback = nil;
    end

    if do_not_exist then
        print('do_not_exist');
        return;
    end

    if root.args.remote_server then
        utils.NetworkService.Send(16072);--查询幸运币是否可使用
    end
    showResult(winner, saved_rewards);
end

local show_result_delay = nil
function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "FIGHT_FINISHED" then
        -- print('FIGHT_FINISHED', ...)
        local winner = resultWinner or select(1, ...);
        if not winner then return; end
        if game.round_info and game.round_info.fight_id == 11010100 then
            SceneStack.Pop()
            return
        end
        if root.speedUp then 
            show_result_delay = {delay = 0.5, fun = function() onFightFinish(winner) end}
            return 
        end
    
        onFightFinish(winner)
    elseif event == "ENTITY_ADD" then
        local uuid, entity = ...
        addEntity(entity)
    end
end

function EVENT.FIGHT_CHECK_RESULT(_, winner, rewards)
    if root.speedUp then 
        show_result_delay = {delay = 0.5, fun = function() loadStoryBeforeResult(winner, rewards) end}
        return 
    end

    saved_rewards = rewards
    loadStoryBeforeResult(winner, rewards)
    -- TODO: append reward
end

function Update()
    if not show_result_delay then return end
    show_result_delay.delay = show_result_delay.delay - UnityEngine.Time.deltaTime
    if show_result_delay.delay < 0 then
        show_result_delay.fun()  
        show_result_delay = nil
    end
end

function EVENT.HeroExpInfoChange(_, ...)
    local expData = ...
    heroExpInfoList = heroExpInfoList or {}
    heroExpInfoList[expData[1]] = expData[2]
end

function EVENT.TEAM_QUERY_NPC_REWARD_REQUEST(event,data)
    ShowExtraSpoilsData = #data.reward_content > 0
end

function EVENT.Roll_Query_Respond(event,data)
    ShowRollData = true
end

function EVENT.ADD_OBJECT_TO_FIGHT_RESULT(event,...)
    local obj = select(1, ...)
    result_panel_game_object = obj;
    if resultFrame and not utils.SGKTools.GameObject_null(resultFrame) then
        DispatchEvent("AddResultObject",result_panel_game_object)
    end
end

function EVENT.server_notify_16009(event,cmd,data)
    if data and data[1] and next(data[1]) then
        saved_rewards = data[1]
        if resultFrame then
            if resultFrame == "loading" then
                showResult(resultWinner, saved_rewards);
            elseif utils.SGKTools.GameObject_null(resultFrame)~=true then
                resultFrame[SGK.LuaBehaviour]:Call("UpdateReward",saved_rewards)
            end
        end
    end
end

function EVENT.server_notify_60(event,cmd,data)
    if data and data[2] and next(data[2]) then
        saved_rewards = data[2]
        if resultFrame then
            if resultFrame == "loading" then
                showResult(resultWinner, saved_rewards);
            elseif utils.SGKTools.GameObject_null(resultFrame)~=true then
                resultFrame[SGK.LuaBehaviour]:Call("UpdateReward",saved_rewards)
            end
        end
    end
end