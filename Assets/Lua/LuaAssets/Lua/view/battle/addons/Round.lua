local Statistics = require 'battlefield2.system.Statistics'
local RoundInfo = root.view.battle.Canvas.RoundInfo
local fightModule = require "module.fightModule"
local EventManager = require "utils.EventManager"
local eventManager = EventManager.getInstance()

local function loadStarDesc(key, value1, value2)
    local _value1 = value1
    local _value2 = value2
    if key == 6 then    ---技能
        if value1 ~= 0 then
            _value1 = module.fightModule.GetDecCfgType(tonumber(value1))
        end
    elseif key == 7 or key == 8 then ---怪物
        if value1 ~= 0 then
            _value1 = battle_config.LoadNPC(_value1).name
        end
        if key ~= 8 then
            if value2 ~= 0 then
                _value2 = battle_config.LoadNPC(value2).name
            end
        end
    end
    return string.format(module.fightModule.GetStarDec(key) or "星星条件 " .. tostring(key)  .. " 不存在", _value1, _value2)
end


local show = nil

local last_round = 0
local last_wave = 0

local function updateRoundInfo()    
    local round_info = game:GetGlobalData();
    RoundInfo:SetActive(round_info.round > 0); 
    local current_round_view = nil
    local Round_Type = 0

    if round_info.win_round_limit and round_info.win_round_limit > 0 then
        Round_Type = 1
    else
        Round_Type = 0
    end

    if not show then
        root.view.battle.Canvas.RoundInfo:SetActive(true);
        root.view.battle.Canvas.RoundInfo.Image[CS.UGUISpriteSelector].index = Round_Type;
        show = true
    end

    if Round_Type == 1 then
        current_round_view = round_info.win_round_limit - round_info.round
        local win_round_limit = round_info.win_round_limit - 1
        local rest_round = round_info.win_round_limit - round_info.round
        local desc = string.format("坚持回合战斗，坚持<color=#ffd800>%s</color>回合后战斗胜利\n剩余回合：<color=#ffd800>%s</color>", win_round_limit, rest_round);
        RoundInfo.detail.text_bg.Text[UnityEngine.UI.Text].text = desc
    else
        current_round_view = round_info.round
        local round_limit = round_info.failed_round_limit or 20
        local current_round = round_info.round
        local desc = string.format("战斗共计<color=#ffd800>%s</color>回合，超过回合后战斗失败\n当前回合：<color=#ffd800>%s</color>", round_limit, current_round);
        RoundInfo.detail.text_bg.Text[UnityEngine.UI.Text].text = desc
        if round_limit - current_round <= 2 then
            RoundInfo.Image.warning:SetActive(true)
            RoundInfo.round.count[CS.UGUIColorSelector].index = 1
            RoundInfo.Image.warning[CS.DG.Tweening.DOTweenAnimation]:DOPlay()
            RoundInfo.round.count[CS.DG.Tweening.DOTweenAnimation]:DOPlay()
        end
    end

    if last_round == current_round_view then
        return
    else
        last_round = current_round_view
    end

    RoundInfo.round.count:TextFormat("{0}", current_round_view ~= 0 and current_round_view or 1)
    RoundInfo.round.transform:DOScale(1, 0.3):OnComplete(function()
        RoundInfo.round.transform:DOScale(0.5, 0.3)
    end)

    local listener = CS.UGUIPointerEventListener.Get(RoundInfo.ClickImage.gameObject);
    if listener.isLongPress ~= nil then
        listener.isLongPress = true;
    end
    CS.UGUIPointerEventListener.Get(RoundInfo.ClickImage.gameObject).onPointerDown = function()
        local detail = RoundInfo.detail
        
        if root.args.remote_server then
            detail:SetActive(true)
            detail.transform:DOScale(Vector3(1, 1, 1), 0.3)
            return;
        end
    
        local info = Statistics.CheckStar(game)

        if #info > 0 then
            detail.Stars.star_bg[CS.UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(detail.Stars.star_bg[CS.UnityEngine.RectTransform].sizeDelta.x, 4 + #info * 46)
            local sc = round_info.star;
            local fight_info = fightModule.GetFightInfo(round_info.fight_id)
            for i = 1, #info,1 do
                local star = detail.Stars["star"..i]
                if i == 1 then
                    star.text:TextFormat("战斗胜利");
                else
                    star.text:TextFormat("{0}", loadStarDesc(sc[i-1].type, sc[i-1].v1, sc[i-1].v2));
                end

                if fightModule.GetOpenStar(fight_info.star, i) ~= 0 then
                    star.text[CS.UGUISelector].index = 0;
                    star.icon[CS.UGUISpriteSelector].index = info[i] and 0 or 1;
                    star.checker[CS.UGUISelector].index = 1;
                else
                    star.text[CS.UGUISelector].index = info[i] and 0 or 1;
                    star.icon[CS.UGUISpriteSelector].index = info[i] and 0 or 1;
                    star.checker[CS.UGUISelector].index = 0;
                end
                star:SetActive(true);
            end
        end    

        detail.transform:DOScale(Vector3(1, 1, 1), 0.3)
        detail:SetActive(true)
    end

    CS.UGUIPointerEventListener.Get(RoundInfo.ClickImage.gameObject).onPointerUp = function()
        RoundInfo.detail:SetActive(false)
        RoundInfo.detail.transform:DOKill();
        eventManager:dispatch("BATTLE_GUIDE_END_CLICK")
        RoundInfo.detail.transform.localScale = Vector3.one * 0.1;
    end
end

local WaveInfo = root.view.battle.Canvas.WaveInfo
local WaveTips = root.view.battle.Canvas.waveTips

local function updateWaveInfo()
    local round_info = game:GetGlobalData();
    local currrent_wave = round_info.wave

    if last_wave == currrent_wave then
        return
    else
        last_wave = currrent_wave
    end

    WaveTips.gameObject:SetActive(true);
    -- roundTips.Image[CS.UGUISpriteSelector].index = self.game.timeline.wave - 1;
    WaveTips.text[UnityEngine.UI.Text].text = tostring(round_info.wave ~= 0 and round_info.wave or 1);

    WaveTips:SetActive(true)  
    WaveTips[UnityEngine.Animator]:Rebind()
    WaveTips[UnityEngine.Animator]:Play("round_ani")

    WaveInfo.Text[UnityEngine.UI.Text].text = string.format("第 %d/%d 波", round_info.wave ~= 0 and round_info.wave or 1, round_info.max_wave);
    WaveInfo.Text.transform:DOScale(1.6, 0.3):OnComplete(function()
        WaveInfo.Text.transform:DOScale(1, 0.3)
    end)
end


Timeline = root.view.battle.Canvas.timelinePanel[SGK.Battle.BattlefieldTimeline];

local function SortWithSpeed(target_list)
    if not next(target_list) then return {} end

    table.sort(target_list, function(a,b)
        if a.Property.speed ~= b.Property.speed then
            return a.Property.speed > b.Property.speed
        end
        return a.uuid < b.uuid
	end)
	return target_list
end

local function sortRoleOrder()
    local round_info = game:GetGlobalData()
    local not_action_list = {}
    local action_list = {}
    local show = nil

    for k, v in pairs(GetAllBattlefiledObject()) do
        local entity = game:GetEntity(k)
        if entity and entity:Alive() then
            if entity.Round.round == round_info.round then
                table.insert(not_action_list, entity)
            else
                table.insert(action_list, entity)
            end
            show = true
        end
    end
    root.view.battle.Canvas.timelinePanel:SetActive(show)

    local i = 0
    for k, v in ipairs(SortWithSpeed(not_action_list)) do
        i = i + 1 
        Timeline:Set(i, tostring(v.uuid), tostring(v.Config.icon), v.Force.side == 1)
    end

    i = i + 1 
    Timeline:SetRound(i, "round", (round_info and round_info.round or 0) + 1)

    for k, v in ipairs(SortWithSpeed(action_list)) do
        i = i + 1 
        Timeline:Set(i, tostring(v.uuid), tostring(v.Config.icon), v.Force.side == 1)
    end
end

local update_list = {}
local Interval = 0

function Start()
    updateRoundInfo()
end

function Update()
    if update_list[1] then
        for _, v in ipairs(update_list) do
            v.wait = v.wait - UnityEngine.Time.deltaTime
        end

        if update_list[1].wait < 0 then
            update_list[1].fun()
            table.remove(update_list, 1)
        end
    end

    Interval = Interval - UnityEngine.Time.deltaTime
    if Interval < 0 and not root.speedUp then
        sortRoleOrder()
        Interval = 1
    end
end

function Start()
    table.insert(update_list, {
        wait = 1,
        fun = updateWaveInfo,
    })

    table.insert(update_list, {
        wait = 1,
        fun = updateRoundInfo,
    })
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "WAVE_START" then
        if root.speedUp then 
            table.insert(update_list, {
                wait = 0.05,
                fun = updateWaveInfo,
            })    
            return 
        end
        table.insert(update_list, {
            wait = 1,
            fun = updateWaveInfo,
        })
    elseif event == "ROUND_START" then
        if root.speedUp then 
            table.insert(update_list, {
                wait = 0.05,
                fun = updateRoundInfo,
            })
             return 
        end
        table.insert(update_list, {
            wait = 1,
            fun = updateRoundInfo,
        })
    end
end
