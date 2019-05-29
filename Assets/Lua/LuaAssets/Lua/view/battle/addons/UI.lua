local OpenLevelConfig = require "config.openLevel"
local autoButton_effect = nil

local auto_button_status = false;
local function getAutoButtonStatus()
    return auto_button_status
end

local waiting_round_info = {}
function Update()
    if not waiting_round_info[1] or not game.round_info then return end
    waiting_round_info[1]()
    table.remove(waiting_round_info, 1)
end

local function setAutoButton(auto)
    auto_button_status = auto;

    if auto then
        root.view.battle.Canvas.TopRight.autoButton.Image:SetActive(false)
        root.view.battle.Canvas.TopRight.autoButton.Image2:SetActive(true)
        
        if not autoButton_effect then
            LoadAsync("prefabs/effect/UI/fx_battle_act.prefab", function(o)
                if not o then return; end;
        
                autoButton_effect = SGK.UIReference.Instantiate(o)
                autoButton_effect.transform:SetParent(root.view.battle.Canvas.TopRight.autoButton.transform, false)
                autoButton_effect:SetActive(true);
            end)
        else
            autoButton_effect:SetActive(true)
        end

        local game = root.server or root.game;
        if game:GetAutoInput() and not root.args.worldBoss then
            root.view.battle.Canvas.autoAnimate:SetActive(true)
        end
    
        SkillPanelHideAllEffect();
    else
        root.view.battle.Canvas.TopRight.autoButton.Image:SetActive(true)
        root.view.battle.Canvas.TopRight.autoButton.Image2:SetActive(false)
        root.view.battle.Canvas.autoAnimate:SetActive(false)

        if autoButton_effect then
            autoButton_effect:SetActive(false)
        end
    end
end

local function setWinner(winner)
    local game = root.server or root.game
    game.round_info.final_winner = winner
end

function Start()
    -- root.view.battle
    root.view.battle[UnityEngine.Animator]:SetBool("enter", true);
    root.view.battle.Canvas.SkillPanel.SkillIdle:SetActive(false);
    
    root.view.battle.Canvas.TopRight.autoButton:SetActive(OpenLevelConfig.GetStatus(3001))
    root.view.battle.Canvas.TopRight.assitButton:SetActive(OpenLevelConfig.GetStatus(3002))
    if UnityEngine.Application.isEditor then
        root.view.battle.Canvas.TopRight.recordButton:SetActive(true or OpenLevelConfig.GetStatus(3003))
    else
        root.view.battle.Canvas.TopRight.recordButton:SetActive(false)
    end
    root.view.battle.Canvas.TopRight.nextButton:SetActive(OpenLevelConfig.GetStatus(3004))
    root.view.battle.Canvas.TopRight.FightingBtn:SetActive(OpenLevelConfig.GetStatus(3005))

    local game = root.server or root.game;

    local player_settings = root:GetPlayerSettings()
    if player_settings.auto then
        if root.args.remote_server then
            root.auto_input = true
            setAutoButton(root.auto_input)
        else
            game:SetAutoInput(0.1, root.pid)
            setAutoButton(true)
        end
    end

    if not root.args.remote_server or root.args.worldBoss or root.args.rankJJC then
        local TopRight = root.view.battle.Canvas.TopRight;
        TopRight.assitButton:SetActive(false)
        TopRight.skipButton:SetActive(OpenLevelConfig.GetStatus(3008))
    end


    table.insert(waiting_round_info, function ()
        --新手战斗 引导战斗
        if game.round_info.fight_id == 11010100 then
            game:SetAutoInput(0.1, root.pid)
            root.view.battle.partnerStage.TeamSlot:SetActive(false)
            root.view.battle.Canvas.TopRight.nextButton:SetActive(false)
        elseif game.round_info.fight_id == 11010101 then
            root.view.battle.partnerStage.TeamSlot:SetActive(false)
        elseif game.round_info.fight_id == 11701 then
            root.view.battle.Canvas.TopRight.skipButton:SetActive(false)
            root.view.battle.Canvas.TopRight.assitButton:SetActive(true)
            root.view.battle.Canvas.TopRight.autoButton:SetActive(false)
        end
    end)

    CS.UGUIClickEventListener.Get(root.view.battle.Canvas.ChatNode.gameObject).onClick = function()
        DialogStack.Push("NewChatFrame");
    end
end

local autoButton_effect_2 = nil

local function setAllAutoButton(auto)
    if auto then
        root.view.battle.Canvas.allautoButton.Image:SetActive(false)
        root.view.battle.Canvas.allautoButton.Image2:SetActive(true)
        
        if not autoButton_effect_2 then
            LoadAsync("prefabs/effect/UI/fx_battle_act.prefab", function(o)
                if not o then return; end;
        
                autoButton_effect_2 = SGK.UIReference.Instantiate(o)
                autoButton_effect_2.transform:SetParent(root.view.battle.Canvas.allautoButton.transform, false)
                autoButton_effect_2:SetActive(true);
            end)
        else
            autoButton_effect_2:SetActive(true)
        end

        SkillPanelHideAllEffect();
    else
        root.view.battle.Canvas.allautoButton.Image:SetActive(true)
        root.view.battle.Canvas.allautoButton.Image2:SetActive(false)

        if autoButton_effect_2 then
            autoButton_effect_2:SetActive(false)
        end
    end

end

function EVENT.allautoButton_click()
    local game = root.server or root.game;
    local auto = game:GetAutoInput()
    SendPlayerCommand(0, 99036, auto and 2 or 3);
    setAllAutoButton(not auto)
end

local FightingBtn_loading = nil
local FightingBtn = nil
function EVENT.fightingBtn_click()
    if FightingBtn_loading then
        return
    end
    FightingBtn_loading = true
    LoadAsync("prefabs/base/FightingBtn.prefab", function (o)
        FightingBtn_loading = false
        if o then
            FightingBtn = CS.UnityEngine.GameObject.Instantiate(o, root.view.battle.PersistenceCanvas.transform) 
        end    
    end)

    local team_info = module.TeamModule.GetTeamInfo()
    if #team_info.members > 0 then
        local script = FightingBtn.transform:GetComponent(typeof(SGK.LuaBehaviour))
        script:Call("setLeaveTeamBtn", function()
            showDlg(nil, "确认退出队伍？确认将在战斗后生效", function()
                module.TeamModule.KickTeamMember(root.pid)
                script:Call("closeLeaveTeamBtn")
            end, function() end)        
        end)
    end
end

local function hideAllObjects()
    root.view.battle.StageEffectSlot:SetActive(false)
    root.view.battle.StageEffectSlot2:SetActive(false)
    root.view.battle.partnerStage:SetActive(false)
    root.view.battle.enemyStage:SetActive(false)
    root.view.battle.player.MainCamera.CameraEffectSlot:SetActive(false)
    root.view.battle.TargetCanvas[UnityEngine.CanvasGroup].alpha = 0
    root.view.battle.Canvas.SkillPanel:SetActive(false)
    PartnerPanelSetActive(false);
end

function EVENT.assitButton_click()
    local message = "确认退出战斗?"
    if root.view.battle.Canvas.TopRight.skipButton.activeSelf then
        root:SpeedUp(50)
        utils.MapHelper.ClearGuideCache(9999)
        return
    end

    showDlg(nil, message, function()
        if root.args.remote_server then
            VoteToExit(1);
        else
            module.EncounterFightModule.SetCombatTYPE(1)--保存玩家退出战斗的状态
            utils.MapHelper.ClearGuideCache(9999)

            --[[排位JJC跳过特殊处理
            if root.args.rankJJC then
                local winner,rewards = module.traditionalArenaModule.GetRankArenaFightResult()
                setWinner(winner)
                hideAllObjects()
                ShowResultPanel(winner,rewards)
            else
                SceneStack.Pop();
            end
            --]]
            SceneStack.Pop();
        end
    end, function() end)
end

function EVENT.recordButton_click()
    if root.args.remote_server then
        module.TeamModule.SyncFightData(9 --[[T.KILL_COMMAND]], {});
        return
    end

    local game = root.server or root.game;

    local list = game:FindAllEntityWithComponent("Force", "Input", "Config", "Health")
    for _, v in ipairs(list) do
        if v.Force.side == 2 and v:Alive() then
            v:Hurt(v.Property.hpp / 3);
            return;
        end
    end
end

function EVENT.autoButton_click()
    local game = root.server or root.game;
    if game:GetAutoInput() then   
        if not root.args.worldBoss then
            showErrorInfo(9)
        end
        return
    end
    local player_settings = root:GetPlayerSettings()
    if root.args.remote_server then
        root.auto_input = not root.auto_input;
        player_settings.auto = root.auto_input;
        setAutoButton(root.auto_input)
        SendPlayerCommand(0, 99036, root.auto_input and 1 or 0);
        return
    end

    if game:GetAutoInput(root.pid) then
        game:SetAutoInput(false, root.pid)
        player_settings.auto = false
        setAutoButton(false)
    else
        game:SetAutoInput(0.1, root.pid)
        player_settings.auto = true
        setAutoButton(true)
    end
end

local Player_count = 0
local function showAllAutoButton()
    if root.args.remote_server and not root.args.worldBoss then
        local team_info = module.TeamModule.GetTeamInfo()
        if team_info and team_info.leader then
            local leader_id = team_info.leader.pid
            if root.pid == leader_id then
                root.view.battle.Canvas.allautoButton:SetActive(true)
            end
        end  
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "AFTER_PRELOAD" then
        table.insert(waiting_round_info, function ()
            if game.round_info.fight_id == 11010100 then
                LoadAsync("prefabs/effect/UI/fx_lens.prefab", function(o)
                    if not o then return; end;
                    obj = SGK.UIReference.Instantiate(o)
                    obj.transform:SetParent(root.view.battle.PersistenceCanvas.transform, false)
                    obj:SetActive(true);
                end)     
            end 
        end)
    elseif event == "ENTITY_CHANGE" then
        local entity = select(2, ...)
        if entity and entity.AutoInput then
            local player_settings = root:GetPlayerSettings()
            root.auto_input = entity:GetAutoInput(root.pid)
            setAutoButton(root.auto_input);
        end
    elseif event == "ENTITY_ADD" then
        local uuid, entity = ...
        if not entity.Player then return end
        Player_count = Player_count + 1 
        if Player_count == 2 then
            showAllAutoButton()
        end
    end
end

function EVENT.ADD_BASE_COUNTDOWN(...)
    local event, uuid = ...;
    DialogStack.PushPref("activity/ProtectBaseCountdown",{uuid = uuid}, root.view.battle.Canvas.RoundInfo);
end

function EVENT.FIGHT_FIALED(...)
    module.TeamModule.SyncFightData(11, {1});
end
