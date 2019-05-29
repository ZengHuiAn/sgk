local InputSystem = require "battlefield2.system.Input"
local BuffSystem  = require "battlefield2.system.Buff"
local battle = require "config/battle";
local heroStar = require"hero.HeroStar"
local EventManager = require "utils.EventManager"
local eventManager = EventManager.getInstance()

local current_entity = nil;

local ROOT_UI = root.view.battle.Canvas.SkillPanel;
local SkillInfoPannel = root.view.battle.Canvas.SkillInfo
local fade_delay = 0
local skillinfo_show = false
local skill_pannel_show = false

local buttons = {
    ROOT_UI.Skill1.Button.transform,
    ROOT_UI.Skill4.Button.transform,
    ROOT_UI.Skill3.Button.transform,
    ROOT_UI.Skill2.Button.transform,
}


local current_press_skill_button_idx = nil;
local current_press_skill_button_time = nil;
local skill_button_press_timeout = 0.2;

local skill_select_effect;
local skill_cast_effect;

local input_data = {};

local targetSelectorManager = root.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];

local target_maps = {
    [-1] = { "partner", "enemy"},
    [-2] = { "enemy", "partner"},
}

local uuid_map = {
    enemy  = {-2, -1},
    partner = {-1, -2},
}

local function hideSkillEffect(info)
    if info and not GetBattlefiledObject(info.uuid) then
        return;
    end

    if skill_cast_effect then skill_cast_effect:SetActive(false) end
    if skill_select_effect then skill_select_effect:SetActive(false) end
end

local function onTargetSelected(target)
    root.view.battle.TargetCanvas.btnCancel:SetActive(false);

    input_data.target = target;

    if root.args.remote_server then
        SendPlayerCommand(current_entity.uuid, input_data.skill, input_data.target);
    else
        -- print('onTargetSelected', input_data.skill, input_data.target);
        if root.server then
            local entity = root.server:GetEntity(current_entity.uuid);
            assert(entity.Input);
            InputSystem.Push(entity.Input, input_data, 'SKILL')
        else
            InputSystem.Push(current_entity.Input, input_data, 'SKILL')
        end
    end

    input_data = {}
    -- current_entity = nil;
end

local function showHero(pos)
    pos = pos or 0
    local slots = root.view.battle.partnerStage.slotCard;
    local show_petbg
    for i = 1, 5 do
        local script = slots[i].partner[SGK.BattlefieldObject];
        if pos < 1 or pos > 5 then
            script:Active(false);
            -- script.gameObject:SetActive(true);
       elseif i == pos then
            skillinfo_show = true;
            script:Active(true);
            show_petbg = true
            -- script.gameObject:SetActive(true);
        else
            local offset = (i < pos) and -pos or (4 - pos);
            script:Active(false, offset + 1);
            -- script.gameObject:SetActive(false);
        end
    end
    root.view.battle.partnerStage.PetBg:SetActive(show_petbg)
end

function hideSkillPanel()
    ROOT_UI[CS.BattlefieldSkillManager2]:Hide();

    -- targetSelectorManager:Hide();
    skill_pannel_show = false
    root.skill_pannel_show = false
    showHero();
    hideSkillEffect();
    PartnerPanelSetActive(false);
end

local exchange_partner_enemy = false;
local function showTargetSelector(script, simple)
    if GetPlayerSide() ~= 1 and not exchange_partner_enemy then
        exchange_partner_enemy = true;
        target_maps[-1], target_maps[-2] = target_maps[-2],target_maps[-1] 
        uuid_map.enemy, uuid_map.partner = uuid_map.partner, uuid_map.enemy
    end

    targetSelectorManager:Hide();
    local list = script.check:Call(simple or "manual") or {};

    local have_enemy = false;
    local have_other_partner = false;

    local targets = {}
    for k, v in ipairs(list) do
        local uuid, side, pos;
        -- print(v.target, uuid_map[v.target]);
        if uuid_map[v.target] then
            uuid = uuid_map[v.target][current_entity.Force.side]
            if v.target == "enemy" then
                have_enemy = true;
            elseif v.target == "partner" then
                have_other_partner = true;
            end
        else
            uuid = v.target.uuid;
            side = v.target.Force.side;
            pos = v.target.Position and v.target.Position ~= 0 and v.target.Position.pos or 0;

            if v.target.Force.side ~= GetPlayerSide() then
                have_enemy = true;
            elseif uuid ~= current_entity.uuid then
                have_other_partner = true;
            end
        end
        local obj = GetBattlefiledObject(uuid) or GetBattlefiledPetsObject(uuid);
        local type = 1

        if side == 1 and root.team_partner_count >= 3 and (pos == 2 or pos == 4)  then
            type = 3; -- 按钮位置向下偏移
        end
        targetSelectorManager:Show(uuid, obj, type, v.button, "UI/fx_butten_start");
    end

    if not have_enemy and have_other_partner then
        showHero();
        root.view.battle.TargetCanvas.btnCancel:SetActive(not simple);
        hideSkillPanel();
    end
end

local function showSkillCastEffect(info)
    local caster = game:GetEntity(info.uuid)
    if caster.Force.side ~= 1 then
        return
    end

    if info.target and type(info.target) == "number" then
        local entity = game:GetEntity(info.target)
        if entity and entity.Force.side == 1 then
            local script = current_entity.Skill.script[info.skill]
            showTargetSelector(script, "simple")
        end
    elseif info.target and info.target == "partner" then
        local script = current_entity.Skill.script[info.skill]
        showTargetSelector(script, "simple")
    end
    
    if not GetBattlefiledObject(info.uuid) then
        return;
    end

    targetSelectorManager:Hide();

    if skill_select_effect then
        skill_select_effect:SetActive(false);
    end

    if skill_cast_effect then
        skill_cast_effect:SetActive(true);
        CS.FollowTarget.Follow(skill_cast_effect.gameObject, 
                buttons[info.skill], -1, false, true)
    end
end

targetSelectorManager.selectedDelegate = function(uuid)
    local target = uuid;
    if target_maps[uuid] then
        target = target_maps[uuid][current_entity.Force.side]
    end
    onTargetSelected(target);
end

local function onSkillSelected(pos)
    if game:GetAutoInput(root.pid) or root.auto_input then
        return;
    end

    if not current_entity then
        print('no entity exists')
        return;
    end

    if not InputSystem.GetToken(current_entity.Input) then
        print('not reading')
        return;
    end

    local script = current_entity.Skill.script[pos]
    if script == nil then
        print('script not exists', pos);
        return;
    end

    input_data.skill = pos;

    if not script.check then
        return onTargetSelected(0);
    end

    showTargetSelector(script);
    -- TODO: show selector

    if skill_cast_effect then
        skill_cast_effect:SetActive(false);
    end

    if skill_select_effect then
        skill_select_effect:SetActive(true);
        CS.FollowTarget.Follow(skill_select_effect.gameObject, buttons[pos], -1, false, true)
    end
end

local original_icon = nil
local function setEnterBuffsButton(role, node)
    if not node then
        return;
    end

    if not original_icon then
        original_icon = node.Button2[UnityEngine.UI.Image].sprite
    end

    local buffs = BuffSystem.API.UnitBuffList(nil, role);
    local EnterBuffs = {};
    for _, buff in ipairs(buffs) do
        if buff.id >= 3000000 and buff.id < 4000000 then
            table.insert(EnterBuffs, buff);
        end
    end

    if #EnterBuffs == 1 then
        SGK.ResourcesManager.LoadAsync("icon/" .. EnterBuffs[1].icon .. ".png", typeof(UnityEngine.Sprite), function(o)
            node.Button2[UnityEngine.UI.Image].sprite = o
        end)
    else
        node.Button2[UnityEngine.UI.Image].sprite = original_icon;
    end

    local count_object = node.Button2.count2 
    if #EnterBuffs >= 3 then
        count_object = node.Button2.count3
    end

    for i = 1, 3, 1 do
        if EnterBuffs[i] then
            SGK.ResourcesManager.LoadAsync("icon/" .. EnterBuffs[i].icon .. ".png", typeof(UnityEngine.Sprite), function (o)
                count_object['speciality'..i][UnityEngine.UI.Image].sprite = o;                
                node.Button2.count2:SetActive(#EnterBuffs == 2);
                node.Button2.count3:SetActive(#EnterBuffs >= 3);
            end);
        end
    end

    local listener = CS.UGUIPointerEventListener.Get(node.ClickImage.gameObject);
    local EnemyBuffList = root.view.battle.Canvas.EnemyBuffList
    if listener.isLongPress ~= nil then
        listener.isLongPress = true;
    end

    listener.onPointerDown = function()
        local buffs = BuffSystem.API.UnitBuffList(nil, role);
        UpDateRoleBuffDesc(role)
        EnemyBuffList[SGK.LuaBehaviour]:Call("ShowView", buffs)
        SkillInfoPannel[UnityEngine.CanvasGroup].alpha = 0
        SkillInfoPannel[UnityEngine.CanvasGroup].interactable = false
        SkillInfoPannel[UnityEngine.CanvasGroup].blocksRaycasts = false
        skillinfo_show = false
    end

    listener.onPointerUp = function()
        EnemyBuffList[SGK.LuaBehaviour]:Call("CloseView")
        eventManager:dispatch("BATTLE_GUIDE_END_CLICK")
    end
end

local function changeOneSkillIcon(skill, node, use_animate)
    if not node then
        return;
    end

    if not skill and node[UnityEngine.CanvasGroup] then
        node[UnityEngine.CanvasGroup].alpha = 0
        return
    else
        node[UnityEngine.CanvasGroup].alpha = 1
    end

    local cd = skill.skill_cooldown_cd - game:GetGlobalData().round

    if not node.Button then
        node.Name[UnityEngine.UI.Text].text = skill.cfg.name;
        node[CS.UGUIColorSelector].index = (cd > 0) and 1 or 0;
        return
    end

    SGK.ResourcesManager.LoadAsync("icon/" .. skill.cfg.icon .. ".png", typeof(UnityEngine.Sprite), function (o)
        if o then
            if not use_animate then
                node.Button[UnityEngine.UI.Image].sprite = o;
            end
            node.Button[CS.CardFlipImage].sprite = o;

            local hp_not_enough = nil
            if skill and skill.cfg.property_list[30021] then
                local consume_hp = skill.owner.hpp * skill.cfg.property_list[30021] / 10000 
                if skill.owner.hp <= consume_hp then hp_not_enough = true end
            end

            local list = skill.check:Call();
            if not list or #list == 0 then
                node.Button[CS.UGUIColorSelector].index = 1;
            else
                node.Button[CS.UGUIColorSelector].index = 0;
            end        
        end
    end);

    node.Name[UnityEngine.UI.Text].text = skill.cfg.name;            

    if node.Button.Cooldown then
        node.Button.Cooldown[UnityEngine.UI.Text].text = (cd > 0) and tostring(cd) or ""
    end
end

local entity_skill_need_update = nil;
local pannelHideDelay_info = nil

local function showSkillPanel(uuid)
    if not GetBattlefiledObject(uuid) then
        return;
    end
    
    local last_uuid = current_entity and current_entity.uuid;
    local entity = root.game:GetEntity(uuid)
    current_entity = entity;

    entity_skill_need_update = root.game:GetTick();

    pannelHideDelay_info = nil;

    targetSelectorManager:Hide();
    if entity.Force.side ~= GetPlayerSide() then
        showHero();
        hideSkillPanel();
        return;
    end

    showHero(entity.Position.pos);

    local scripts = entity.Skill.script or {};

    changeOneSkillIcon(scripts[1], ROOT_UI.Skill1, true)
    changeOneSkillIcon(scripts[2], ROOT_UI.Skill4, true)
    changeOneSkillIcon(scripts[3], ROOT_UI.Skill3, true)
    setEnterBuffsButton(entity, ROOT_UI.Skill2)

    local function Switch(more)
        if last_uuid and last_uuid ~= entity.uuid then
            ROOT_UI[CS.BattlefieldSkillManager2]:Switch(more);
        else
            ROOT_UI[CS.BattlefieldSkillManager2]:Show(more);
        end
    end

    if scripts[13] then
        ROOT_UI.SkillDiamon.Button[CS.UGUISpriteSelector].index = 
            entity.Property.diamond_index - 1
        Switch(true);
    else
        Switch(false);
    end

    skill_pannel_show = true
    root.skill_pannel_show = true
end

function GetSkillPannelstatus()
    return skill_pannel_show
end

root.view.battle.TargetCanvas.btnCancel[CS.UGUIClickEventListener].onClick = function()
    root.view.battle.TargetCanvas.btnCancel:SetActive(false);
    hideSkillEffect();
    showSkillPanel(current_entity.uuid)
    PartnerPanelSetActive(true);
end

function Preload()
    local parent = ROOT_UI.transform

    LoadAsync("prefabs/effect/UI/fx_btn_select.prefab", function(o)
        if not o then return; end;

        skill_select_effect = SGK.UIReference.Instantiate(o)
        skill_select_effect.transform:SetParent(parent, false)
        skill_select_effect:SetActive(false);
    end)

    LoadAsync("prefabs/effect/UI/fx_btn_auto.prefab", function(o)
        if not o then return; end;

        skill_cast_effect = SGK.UIReference.Instantiate(o)
        skill_cast_effect.transform:SetParent(parent, false)
        skill_select_effect:SetActive(false);
    end)
end

function Start()
    ROOT_UI[CS.BattlefieldSkillManager2].selectedDelegate = function(pos)
        onSkillSelected(pos);
    end

    for idx, btn in ipairs({"Skill1", "Skill4", "Skill3"}) do
        local listener = CS.UGUIPointerEventListener.Get(ROOT_UI[btn].Button.gameObject);

        local button_index = idx;
        listener.onPointerDown = function()
            current_press_skill_button_idx = button_index;
            current_press_skill_button_time = UnityEngine.Time.realtimeSinceStartup;
        end

        listener.onPointerUp = function()
            -- ShowSkillInfoByIndex();
            if current_press_skill_button_time and 
                UnityEngine.Time.realtimeSinceStartup - current_press_skill_button_time < skill_button_press_timeout then
                onSkillSelected(button_index, false);
            end
            current_press_skill_button_idx = nil;
            current_press_skill_button_time = nil;
        end

        listener.onPointerExit = function()
            current_press_skill_button_idx = nil;
            current_press_skill_button_time = nil;
            -- ShowSkillInfoByIndex();
        end
    end

    local list = game:FindAllEntityWithComponent("Input")
    for _, v in ipairs(list) do
        if v.Input.token then
            showSkillPanel(v.uuid)
        end
    end


    local listener = CS.UGUIPointerEventListener.Get(SkillInfoPannel.gameObject);
    listener.onPointerDown = function()
        fade_delay = -100
    end
end

function OnDestroy()
    targetSelectorManager.selectedDelegate = nil;
    targetSelectorManager = nil;
end

function SkillPanelHideAllEffect()
    targetSelectorManager:Hide();
    hideSkillEffect()
end

local function upDateAllSkillIcon(entity)
    if not GetBattlefiledObject(entity.uuid) then
        return;
    end

    if not current_entity or current_entity.Force.side ~= 1 then return end

    local scripts = entity.Skill.script or {};

    changeOneSkillIcon(scripts[1], ROOT_UI.Skill1, true)
    changeOneSkillIcon(scripts[2], ROOT_UI.Skill4, true)
    changeOneSkillIcon(scripts[3], ROOT_UI.Skill3, true)        
end

local chief = nil
local function getDocLevel(entity, cfg)
    local role_id = entity.Config.id

    local heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, role_id)
    local _count = 0
    local _desc = {}

    for _, v in ipairs(cfg.star_list or {}) do
        if v.level <= heroCfg.star then
            _count = _count + 1
        end
        table.insert(_desc, {desc = v.desc, star = v.level, active = (v.level <= heroCfg.star)})
    end

    return _desc, _count;
end

function GetSkillDesc(entity, index)
    local role_id = entity.Config.id
    local _cfg = heroStar.GetHeroStarSkillList(role_id)[index]
    if not _cfg then
        return ""
    end

    local _desc, _level = getDocLevel(entity, _cfg)

    if role_id == 11000 and entity.Property.diamond_index > 1 then
        if not chief then
            chief = {}
            DATABASE.ForEach("chief", function(data)
                chief[data.id] = data
            end)
        end

        role_id = chief[entity.Property.diamond_index].skill_star
        if not role_id then
            ERROR_LOG("____________diamond_index error")
        else
            _cfg = heroStar.GetHeroStarSkillList(role_id)[index]
            _desc = getDocLevel(entity, _cfg)
        end
    end

    local desc = ""
    for i = 1,_level,1 do
        if _desc[i] then
            desc =  desc .."\n·" .. _desc[i].desc
        end
    end
    return desc
end

local function ShowSkillInfoByIndex(index)
    if not current_entity then
        return
    end

    local skill_id = nil;
    if current_entity and index then
        skill_id = current_entity.Skill.script[index] and current_entity.Skill.script[index].id;
    end

    if not skill_id then
        SkillInfoPannel[UnityEngine.CanvasGroup].alpha =  0;
        SkillInfoPannel[UnityEngine.CanvasGroup].interactable = false;
        ROOTSkillInfoPannel_UI[UnityEngine.CanvasGroup].blocksRaycasts = false;
        return;
    end

    local cfg = battle.LoadSkill(skill_id)

    if not cfg then
        SkillInfoPannel[UnityEngine.CanvasGroup].alpha =  0;
        SkillInfoPannel[UnityEngine.CanvasGroup].interactable = false;
        SkillInfoPannel[UnityEngine.CanvasGroup].blocksRaycasts = false;
        return;
    end

    fade_delay = 2
    skillinfo_show = true

    local script = current_entity.Skill.script[index]
    local skill_desc = cfg.desc
    if script[8006] == 0 then
        skill_desc = skill_desc .. GetSkillDesc(current_entity, index)
    end

    SkillInfoPannel.NameText[UnityEngine.UI.Text].text    = cfg.name;
    SkillInfoPannel.Desc[UnityEngine.UI.Text].text        = skill_desc;
    SkillInfoPannel.CDText[UnityEngine.UI.Text]:TextFormat( (cfg.skill_cast_cd == 0) and "无" or "{0}回合", cfg.skill_cast_cd);
    local consume = cfg.consume_value;
    SkillInfoPannel.ConsumeText[UnityEngine.UI.Text]:TextFormat( (consume == 0) and "无消耗" or "{0}", consume);

    SkillInfoPannel[UnityEngine.CanvasGroup]:DOKill()
    SkillInfoPannel[UnityEngine.CanvasGroup].alpha = 1;
    SkillInfoPannel[UnityEngine.CanvasGroup].interactable = true;
    SkillInfoPannel[UnityEngine.CanvasGroup].blocksRaycasts = true;
end

local Warning_Time = 0
local last_timeout_time = nil;
local function upDateTimeoutView()
    local timeout_list = game:FindAllEntityWithComponent("Timeout");

    local timeout_time = nil;
    for _, v in ipairs(timeout_list) do
        if v.Player and v.Player.pid == root.pid then
            if timeout_time == nil or v.Timeout.timeout_tick < timeout_time then
                timeout_time = v.Timeout.timeout_tick;
            end
        elseif v.Force and v.Force.pid == root.pid and v.Round.round == game.round_info.round and v.Timeout.timeout_tick then
            if timeout_time == nil or v.Timeout.timeout_tick < timeout_time then
                timeout_time = v.Timeout.timeout_tick;
            end
        end
    end

    if timeout_time == nil then
        root.view.battle.Canvas.timeout[UI.Text].text = ""
        Warning_Time = 0
    else
        local final_time = game:GetTime(timeout_time - game:GetTick()) - game:GetTime();
        if last_timeout_time ~= timeout_time and final_time > 0 then
            root.view.battle.Canvas.timeout[SGK.BattlefieldTimeout]:StartWithTime(final_time)
        end

        if final_time < 10 and Warning_Time <= 0 then
            root.view.battle.Canvas.timeout[SGK.BattlefieldTimeout]:StartWithTime(final_time)
            Warning_Time = final_time
        end
    end
    last_timeout_time = timeout_time;
end

local timeout_update_time = 0;
function Update()
    if root.speedUp and root.speedUp > 1 then
        return;
    end

    local dt = UnityEngine.Time.deltaTime;

    if GetPartnerStatus(root.pid) and GetPartnerStatus(root.pid).not_all_action then
        root.view.battle.Canvas.timeout:SetActive(true)
    else
        root.view.battle.Canvas.timeout:SetActive(false)
    end

    if Warning_Time > 0 and GetPartnerStatus(root.pid) and GetPartnerStatus(root.pid).not_all_action then
        Warning_Time = Warning_Time - dt
        root.view.battle.Canvas.timeoutWarning[CS.UGUISpriteSelector].index = math.floor(Warning_Time)
        root.view.battle.Canvas.timeoutWarning:SetActive(true)
    else
        root.view.battle.Canvas.timeoutWarning:SetActive(false)
    end

    if current_entity and entity_skill_need_update and entity_skill_need_update <= root.game:GetTick() + 1 then
        entity_skill_need_update = nil;
        upDateAllSkillIcon(current_entity)
    end

    if pannelHideDelay_info then
        pannelHideDelay_info.delay = pannelHideDelay_info.delay - dt
        if pannelHideDelay_info.delay < 0 then
            pannelHideDelay_info = nil
            hideSkillPanel()
        end
    end

    if current_press_skill_button_time and UnityEngine.Time.realtimeSinceStartup - current_press_skill_button_time >= skill_button_press_timeout then
        ShowSkillInfoByIndex(current_press_skill_button_idx);
    end

    if skillinfo_show then
        fade_delay = fade_delay - dt
        if fade_delay < 0 then
            SkillInfoPannel[UnityEngine.CanvasGroup].alpha = SkillInfoPannel[UnityEngine.CanvasGroup].alpha - UnityEngine.Time.deltaTime;
            if SkillInfoPannel[UnityEngine.CanvasGroup].alpha == 0 or fade_delay <= -100 then
                SkillInfoPannel[UnityEngine.CanvasGroup].alpha = 0
                SkillInfoPannel[UnityEngine.CanvasGroup].interactable = false
                SkillInfoPannel[UnityEngine.CanvasGroup].blocksRaycasts = false
                skillinfo_show = false
            end
        end
    end

    timeout_update_time = timeout_update_time - dt;
    if timeout_update_time <= 0 then
        timeout_update_time = 0.5;
        upDateTimeoutView();
    end
end

function filterPartnerEvent(uuid)
    local entity = game:GetEntity(uuid)
    if entity and entity.Force and entity.Force.side == 1 and entity.Force.pid ~= root.pid then
        return true
    end
    return false
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "UNIT_BEFORE_ACTION" then
        if root.speedUp then return end
        if filterPartnerEvent(...) then return end
        targetSelectorManager:Hide();
        showSkillPanel(...)
    elseif event == "UNIT_AFTER_ACTION" then
        if root.speedUp then return end
        local uuid = ...
        if filterPartnerEvent(uuid) then return end

        if GetBattlefiledObject(uuid) then
            targetSelectorManager:Hide();
            local entity = game:GetEntity(uuid)
            pannelHideDelay_info = {
                uuid = uuid,
                delay = 0.3,
                round = entity.Round.round,
            }
        end
    elseif event == "UNIT_PREPARE_ACTION" then
        if root.speedUp then return end
        if filterPartnerEvent(...) then return end
        showSkillPanel(...);
    elseif event == "UNIT_CAST_SKILL" then
        if root.speedUp then return end
        local info = ...
        if filterPartnerEvent(info.uuid) then return end
        showSkillCastEffect(...);
    elseif event == "UNIT_SKILL_FINISHED" then
        if root.speedUp then return end
        local info = ...
        if filterPartnerEvent(info.uuid) then return end
        hideSkillEffect(...);
    elseif event == "ROUND_FINISHED" or event == "FIGHT_FINISHED" then
        if root.speedUp then return end
        hideSkillPanel();
        targetSelectorManager:Hide();
    elseif event == "ENTITY_CHANGE" then
        if root.speedUp then return end
        entity_skill_need_update = root.game:GetTick()
    elseif event == "BATTLE_SPEED_UP" then
        hideSkillPanel()
    elseif event == "SKILL_CHANGE_ID" then
        if root.speedUp then return end
        entity_skill_need_update = root.game:GetTick()
    end
end
 
