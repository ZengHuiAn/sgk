local battle_config = require "config/battle";
local playerModule  = require "module.playerModule"
local BuffSystem    = require "battlefield2.system.Buff"
local Role          = require "battlefield2.system.Role"
local EventManager  = require "utils.EventManager"
local eventManager  = EventManager.getInstance()
local targetSelectorManager = root.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];

local roles = {};

local player_side = 1;

local Thread = require "utils.Thread"
local preload = nil

local enemySlot = {
    [1] = root.view.battle.enemyStage.slot21,
    [2] = root.view.battle.enemyStage.slot32,
    [3] = root.view.battle.enemyStage.slot22,
    [4] = root.view.battle.enemyStage.slot33,
    [5] = root.view.battle.enemyStage.slot23,

    [11] =root.view.battle.enemyStage.slot11,

    [21] =root.view.battle.enemyStage.slot21,
    [22] =root.view.battle.enemyStage.slot22,
    [23] =root.view.battle.enemyStage.slot23,

    [31] =root.view.battle.enemyStage.slot31,
    [32] =root.view.battle.enemyStage.slot32,
    [33] =root.view.battle.enemyStage.slot33,
    [34] =root.view.battle.enemyStage.slot34,
}

local enemyPrefab = {
    [0] = "prefabs/battlefield/enemy.prefab",

    [31] = "prefabs/battlefield/enemy2.prefab",
    [32] = "prefabs/battlefield/enemy2.prefab",
    [33] = "prefabs/battlefield/enemy2.prefab",
    [34] = "prefabs/battlefield/enemy2.prefab",

    [11] = "prefabs/battlefield/enemyBoss.prefab",
}


local pvp_enemy_offset = {
    [1] = {0,0,0},
    [2] = {0,0,0},
    [3] = {0,0,0},
    [4] = {0,0,0},
    [5] = {0,0,0},
}

local function getRolePostionOffset(side, pos, x, y, z)
    if side ~= 1 then
        local value = pvp_enemy_offset[pos] or {0, 0, 0}
        return Vector3(value[1] + x,value[2] + y,value[3] + z)
    end
    return Vector3(x,y,z);
end

local role_master_list = {
    {master = "airMaster",   index = 3, desc = "风系", colorindex = 0},
    {master = "dirtMaster",  index = 2, desc = "土系", colorindex = 1},
    {master = "waterMaster", index = 0, desc = "水系", colorindex = 2},
    {master = "fireMaster",  index = 1, desc = "火系", colorindex = 3},
    {master = "lightMaster", index = 4, desc = "光系", colorindex = 4},
    {master = "darkMaster",  index = 5, desc = "暗系", colorindex = 5},
}

local function GetMasterIcon(role, other_info)
    table.sort(role_master_list, function (a, b)
        if role[a.master] ~= role[b.master] then
            return role[a.master] > role[b.master]
        end
		return a.master > b.master
    end)
    
    if other_info and role[role_master_list[1].master] == role[role_master_list[2].master] then
        return {desc = "全系",  colorindex = 6}
    elseif other_info then
        return {desc = role_master_list[1].desc,  colorindex = role_master_list[1].colorindex}
    end

    if role[role_master_list[1].master] == role[role_master_list[2].master] then
        return 6
    else
        return role_master_list[1].index
    end
end

local function ActionTimeActive(uuid, show)
    local entity = game:GetEntity(uuid)
    if not entity or not entity.Timeout then
        return
    end

    if entity.Force.side == 1 then
        return
    end

    if not roles[uuid] then
        return
    end

    local ui = roles[uuid].ui
    if not ui.ActionTime then
        return
    end 

    ui.ActionTime:SetActive(show)
end

local target_ring_menu = nil
local target_ring_menu_start = nil
local Focus_Effect_Map = {}

local function setFocusTagView(uuid)
    local entity = game:GetEntity(uuid)
    if not entity then return end

    if Focus_Effect_Map[uuid] and Focus_Effect_Map[uuid].obj_loading then
        return
    end

    local type = entity.Property[8005]
    if not entity:Alive() or type == 0 then
        if Focus_Effect_Map[uuid] then
            UnityEngine.GameObject.Destroy(Focus_Effect_Map[uuid].obj);
            Focus_Effect_Map[uuid] = nil
        end
        return
    end 

    if Focus_Effect_Map[uuid] and type == Focus_Effect_Map[uuid].type then
        return
    end

    local effect_list = {
        [1] = "UI/fx_jihuo_kongzhi",
        [2] = "UI/fx_jihuo_tingshou",
        [3] = "UI/fx_jihuo_jihuo",
    }

    if Focus_Effect_Map[uuid] then
        UnityEngine.GameObject.Destroy(Focus_Effect_Map[uuid].obj);
        Focus_Effect_Map[uuid] = nil
    end

    Focus_Effect_Map[uuid] = {};
    Focus_Effect_Map[uuid].type = type;
    Focus_Effect_Map[uuid].obj_loading = true;

    UnitAddEffect(entity, effect_list[type], {hitpoint = "head", duration = -1}, function(o)
        Focus_Effect_Map[uuid].obj = o;
        Focus_Effect_Map[uuid].obj_loading = false;
    end);
end

local current_RingMenu_Role = nil
local TargetRingMenu_loading = nil
local function SetTargetRingMenuActive(active, uuid, pos)
    if not target_ring_menu and active then
        if TargetRingMenu_loading then return end
        TargetRingMenu_loading = true
        SGK.ResourcesManager.LoadAsync("prefabs/battlefield/BattlefieldTargetRingMenu.prefab", function(o)
            TargetRingMenu_loading = false;
            if o then
                target_ring_menu = SGK.UIReference.Instantiate(o);
                target_ring_menu.transform:SetParent(root.view.battle.PersistenceCanvas.transform, false);
                target_ring_menu:SetActive(false);              
            end  
        end)
    end

    if target_ring_menu then
        if active then
            if pos then
                targetSelectorManager:SetUIPosition(target_ring_menu.FillImage.transform, pos);
            end

            target_ring_menu.FillImage[CS.UIRingMenuFillImage]:StartFill()
            local role = game:GetEntity(uuid)
            target_ring_menu.Menu.Menu1:SetActive(role.side ~= 1)
            target_ring_menu.Menu.Menu2:SetActive(role.side ~= 1)
            target_ring_menu.Menu.Menu3:SetActive(role.side ~= 1)

            target_ring_menu.Menu[CS.UIRingMenu].onClick = function(n)
                SetTargetRingMenuActive(false);

                local role = game:GetEntity(uuid)
                if role == nil then
                    return;
                end

                local t = { [0] = 1, 2, 3, 0};

                if t[n] == 0 then
                    return ShowRoleDetail(uuid);
                end

                local type = t[n]
                if root.args.romote_server then
                    local team_info = module.TeamModule.GetTeamInfo()
                    if team_info.leader then
                        local pid = playerModule.GetSelfID()
                        local leader_id = team_info.leader.pid
                        if pid ~= leader_id then
                            showErrorInfo(8)
                        else
                            SendPlayerCommand(role.uuid, 98002, role.Property[8005] ~= type and type or 0)
                        end
                    end  
                else
                    Role.SetFocusTag(root.server or game, role.uuid, role.Property[8005] ~= type and type or 0)
                end
            end
        end

        current_RingMenu_Role = uuid
        target_ring_menu:SetActive(active);
    end
end

local function onEnemyTouchBegan(uuid, pos)
    local role = game:GetEntity(uuid)
    if not role then return end
    target_ring_menu_start = CS.UnityEngine.Time.realtimeSinceStartup;
    SetTargetRingMenuActive(true, uuid, roles[uuid].script:GetPosition("hitpoint")) --  pos);
end

local function onEnemyTouchEnd(uuid, pos)
    local role = game:GetEntity(uuid)
    if not role then return end
    if CS.UnityEngine.Time.realtimeSinceStartup - target_ring_menu_start < 0.5 then
        SetTargetRingMenuActive(false);
    end

    if target_ring_menu then
        -- self.target_ring_menu.FillImage[CS.UIRingMenuFillImage]:TouchEnd()
    end
    -- ERROR_LOG("onEnemyTouchEnd", role.id, role.name)
end

local function onEnemyTouchMove(uuid, pos)
    -- local role = self.roles[uuid].role;
    -- ERROR_LOG("onEnemyTouchMove", role.id, role.name)
end

local function onEnemyTouchCancel(uuid)
    local role = game:GetEntity(uuid)
    if not role then return end
    -- ERROR_LOG("onEnemyTouchCancel", role.id, role.name)
    if CS.UnityEngine.Time.realtimeSinceStartup - target_ring_menu_start < 0.5 then
        SetTargetRingMenuActive(false);
    end

    if target_ring_menu then
        -- self.target_ring_menu.FillImage[CS.UIRingMenuFillImage]:TouchEnd()
    end
end

local preloading = true;

local function createEnemy(entity, sync)
    local cfg = entity.Config;
    if not cfg then return; end

    local pos = entity.Position.pos;
    local x = entity.Position.x;
    local y = entity.Position.y;
    local z = entity.Position.z;

    local slot = enemySlot[pos]
    if not slot then
        print('unknown role slot', pos);
        return;
    end

    
    roles[entity.uuid] = {}
    -- ERROR_LOG("createEnemmy", entity.uuid, roles[entity.uuid])

    local function CreatObject(entity)
        local o = SGK.ResourcesManager.Load(enemyPrefab[pos] or enemyPrefab[0])
        if not o then return end;
    
        local enemy = SGK.UIReference.Instantiate(o, slot.transform)
        enemy.gameObject.name = cfg.id .. "_" .. pos;
        enemy.transform.localPosition = getRolePostionOffset(2, pos, x, y, z)
        enemy.transform.localScale = Vector3.one;
    
        local script = enemy[SGK.BattlefieldObject];

        local __enter_played = roles[entity.uuid].__enter_played;
        roles[entity.uuid].org_position = script.gameObject.transform.localPosition;
        if entity.Round.invisible == 1 then
            if not __enter_played then
                script.gameObject.transform.localPosition = UnityEngine.Vector3(0, 20, 0); -- :SetActive(false);
                roles[entity.uuid].hide = true;
            end
        end

        if preloading then
            local asset = SGK.ResourcesManager.Load(string.format("roles/%s/%s_SkeletonData.asset", cfg.mode, cfg.mode));
            script:ChangeMode(tostring(cfg.mode), asset);
        else
            script:ChangeMode(tostring(cfg.mode));
        end

        local name = cfg.name
        --[[
        if name == "陆水银" and pos == 1 then
            local player = playerModule.Get(entity.Force.pid)
            name = player and player.name or name
        end
        --]]
        script:SetName(name);
        script:UpdateProperty(entity.Property.hp, entity.Property.hpp, 100, 100, 0);
        script:ShowUI(true);
    
        local flip, enemy_scale = battle_config.GetModeFlip(cfg.mode, 2, pos);
        script.flip = flip;
    
        if enemy_scale then
            script:SetModeScale(Vector3(enemy_scale, enemy_scale, enemy_scale));
        end
    
        local energyBar
        if pos == 11 and enemy.UIBoss then
            energyBar = enemy.UIBoss.EnergyBar[CS.BattleEnergyBar]
            enemy.UIBoss.transform:SetParent(root.view.battle.EnemyBossCanvas.EnemyBossUISlot.gameObject.transform, false);
            enemy.UIBoss[CS.FollowSpineBone].enabled = false;
            enemy.UIBoss.transform.localScale = Vector3.one;
            enemy.UIBoss.element[CS.UGUISpriteSelector].index = GetMasterIcon(entity.Property)
    
            local listener = CS.UGUIPointerEventListener.Get(enemy.UIBoss.BuffDetailClick.gameObject);
            local EnemyBuffList = root.view.battle.Canvas.EnemyBuffList
            if listener.isLongPress ~= nil then
                listener.isLongPress = true;
            end
            listener.onPointerDown = function()
                local buffs = BuffSystem.API.UnitBuffList(nil, entity);
                UpDateRoleBuffDesc(entity)
                EnemyBuffList[SGK.LuaBehaviour]:Call("ShowView", buffs)
            end
        
            listener.onPointerUp = function()
                EnemyBuffList[SGK.LuaBehaviour]:Call("CloseView")
                eventManager:dispatch("BATTLE_GUIDE_END_CLICK")
            end
        else
            energyBar = enemy.UIEnemy.EnergyBar[CS.BattleEnergyBar]
            enemy.UIEnemy.element[CS.UGUISpriteSelector].index = GetMasterIcon(entity.Property)
            
            local listener = CS.ModelTouchEventListener.Get(enemy.UIEnemy.BuffDetailClick.gameObject)
            local EnemyBuffList = root.view.battle.Canvas.EnemyBuffList
            
            listener.onTouchBegan = function()
                local buffs = BuffSystem.API.UnitBuffList(nil, entity);
                UpDateRoleBuffDesc(entity)
                EnemyBuffList[SGK.LuaBehaviour]:Call("ShowView", buffs)
            end

            listener.onTouchEnd = function()
                EnemyBuffList[SGK.LuaBehaviour]:Call("CloseView")
                eventManager:dispatch("BATTLE_GUIDE_END_CLICK")
            end
        
            listener.onTouchCancel = function()
                EnemyBuffList[SGK.LuaBehaviour]:Call("CloseView")
                eventManager:dispatch("BATTLE_GUIDE_END_CLICK")
            end        
        end
    
        script.onTouchBegan = function(...) onEnemyTouchBegan(entity.uuid, ...) end
        script.onTouchEnd = function(...) onEnemyTouchEnd(entity.uuid, ...) end
        script.onTouchMove = function(...) onEnemyTouchMove(entity.uuid, ...) end
        script.onTouchCancel = function() onEnemyTouchCancel(entity.uuid) end
    
    
        roles[entity.uuid].script = script;
        roles[entity.uuid].energyBar = energyBar;
        roles[entity.uuid].side = 2;
        roles[entity.uuid].ui = enemy.UIEnemy or enemy.UIBoss

        local __enter_played = roles[entity.uuid].__enter_played;
        if __enter_played then
            script.gameObject.transform.localPosition = roles[entity.uuid].org_position
            roles[entity.uuid].hide = true;
        end
    end
    
    if not sync and not preloading then
        local thread
        thread = Thread.Create(function ()
            while true do
                local func = thread:read_message()
                if func then
                    func()
                end
            end
        end)

        roles[entity.uuid].thread = thread
        thread:send_message(function() 
            CreatObject(entity)
        end)
        thread:Start()
    else
        CreatObject(entity)
    end
end

local partner_count = 0;
local function createPartner(entity, sync_load_asset)
    game:LOG('createPartner', entity.uuid, entity.Config.refid, entity.Config.name, entity.Force.pid);

    if root.pid and entity.Force.pid ~= root.pid and not root.args.worldBoss then
        print('SKIP PARTNER', entity.Force.pid, entity.Config.name, 'speed', entity.Property.speed)
        return;
    end

    local cfg = entity.Config;
    if not cfg then return; end

    local pos = entity.Position.pos;

    local slot = root.view.battle.partnerStage.slotCard[pos]
    if not slot then
        print('unknown role slot', pos);
        return;
    end

    local script = slot.partner[SGK.BattlefieldObject];

    if preloading then
        local asset = SGK.ResourcesManager.Load(string.format("roles/%s/%s_SkeletonData.asset", cfg.mode, cfg.mode));
        script:ChangeMode(tostring(cfg.mode), asset);
    else
        script:ChangeMode(tostring(cfg.mode));
    end
    script:SetName(cfg.name);
    script:UpdateProperty(entity.Property.hp, entity.Property.hpp, 100, 100, 0);
    script:ShowUI(true);

    local flip = battle_config.GetModeFlip(cfg.mode, 1, pos);
    script.flip = flip;

    slot.partner.UIPartner.element[CS.UGUISpriteSelector].index = GetMasterIcon(entity.Property)
    local energyBar = slot.partner.UIPartner.ResourceBar[CS.BattleEnergyBar];

    -- print('createPartner', entity.Config.name, energyBar);
    slot.partner:SetActive(true);

    roles[entity.uuid] = {script = script, energyBar = energyBar, side = 1, ui = slot.partner.UIPartner}
    partner_count = partner_count + 1;

    if partner_count == 4 then
        for _, v in pairs(roles) do
            if v.side == 1 then
                v.script:ShowMask(true)
            end
        end
    elseif partner_count > 4 then
        script:ShowMask(true);
    else
        script:ShowMask(false)
    end
end

local function addEntity(entity)
    if not entity.Input then return end
    if not entity.Round then return end;
    if not entity.Force then return end;

    if preloading then
        return;
    end

    if roles[entity.uuid] then
        print('repeat addEntity', entity.uuid);
        return;
    end

    if entity.Force.side == player_side then
        createPartner(entity);
    else
        createEnemy(entity);
    end
end

local function removeEntity(uuid, entity)
    if roles[uuid] and entity.Force.side ~= player_side then
        if roles[uuid] and roles[uuid].script then
            roles[uuid].script.gameObject:SetActive(false);
            roles[uuid].script:ShowUI(false);
            -- TODO: remove ??
        else
            roles[uuid] = nil;
        end
    end
end

function GetPlayerSide()
    return player_side;
end

function Preload()
    local list = game:FindAllEntityWithComponent("Force", "Input", "Config")
    for _, v in ipairs(list) do
        if root.args.worldBoss and v.Force.side == 1 or v.Force.pid == root.pid then
            player_side = v.Force.side;
        end
    end

    local _roles = game:FindAllEntityWithComponent("Force", "Input", "Config", "Health")
    for _, entity in ipairs(_roles) do
        if entity.Force.side == player_side then
            createPartner(entity);
        else
            createEnemy(entity);
        end
    end

    preloading = false
end

function Start()

end

local function UnitRelive(uuid)
    local entity = game:GetEntity(uuid);
    local info = roles[uuid]

    if not info or not entity then
        return
    end

    if info.script.icon then
        info.script.icon.image.gameObject:GetComponent(typeof(CS.ImageMaterial)).active = false;
        info.script.icon.hpBar.gameObject:SetActive(true);
    end

    local SkeletonAnimation = info.script.spineObject.gameObject:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
    if SkeletonAnimation then 
        SkeletonAnimation.timeScale = 1
    end

    info.script:SetExposure(0);
    info.script:ShowWarning(0);
    info.script:SetQualityColor(UnityEngine.Color.white);
    if info.side == 1 then
        PlayAciton2(info.script, "idle")
    end

    if entity.Force.side ~= player_side then
        info.script:ChangeMode(tostring(entity.Config.mode));
        info.script:Play("idle", "idle");
        info.script:ShowUI(true);
    
        local Collider = info.script.spineObject:GetComponent(typeof(UnityEngine.BoxCollider))
        if not string.find(tostring(Collider), "null:") then
            Collider.enabled = true
        end
    end
end

local function updateEntityProperty(entity, info)
    info.last_value = info.last_value or {}
    local hp, hpp, shield = entity.Property.hp,
            entity.Property.hpp,
            entity.Property.shield

    if info.dead then
        info.dead = false;
        info.script:SetExposure(0);
        info.script:ShowWarning(0);
        info.script:SetQualityColor(UnityEngine.Color.white);
        UnitRelive(entity.uuid)
    end
 
    if info.last_value.hp ~= hp
        or info.last_value.hpp ~= hpp
        or info.last_value.shield ~= shield then
        if info.script then
            info.script:UpdateProperty(entity.Property.hp, entity.Property.hpp,
                        100, 100,
                        entity.Property.shield);
        end
        info.last_value.hp = hp
        info.last_value.hpp = hpp
        info.last_value.shield = shield
    end

    -- print('SET EP', entity.Config.name, entity.Config.id, entity.Property.ep, info.last_value.ep, info.energyBar);
    if info.energyBar then
        local ep, epp = entity.Property.ep, entity.Property.epp;
        if info.last_value.ep ~= ep
            or info.last_value.epp ~= epp then
            info.energyBar:SetValue(entity.Property.ep, entity.Force.side);
            info.last_value.ep  = ep
            info.last_value.epp = epp
        end
    end
end


local function showDeadEntity(entity, info)
    if info.dead then return end

    if entity and current_RingMenu_Role and current_RingMenu_Role == entity.uuid and target_ring_menu.activeSelf then
        target_ring_menu:SetActive(false)
    end

    if entity then
        game:DispatchEvent("Unit_Dead", entity.uuid);
    end

    info.dead = true;
    info.script:SetExposure(-1);
    info.script:ShowWarning(1);
    info.script:SetQualityColor(UnityEngine.Color.red);
    info.script:UpdateProperty(0, 100, 100, 100, 0);
    local Collider = info.script.spineObject:GetComponent(typeof(UnityEngine.BoxCollider))
    if not string.find(tostring(Collider), "null:") then
        Collider.enabled = false
    end

    if info.script.icon then
        info.script.icon.image.gameObject:GetComponent(typeof(CS.ImageMaterial)).active = true;
        info.script.icon.hpBar.gameObject:SetActive(false);
    end

    local SkeletonAnimation = info.script.spineObject.gameObject:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
    pcall(SkeletonAnimation.AnimationState.SetAnimation, SkeletonAnimation.AnimationState, 0, "idle", false)
    SkeletonAnimation.timeScale = 0

    if entity and entity.Force.side == player_side then
        return;
    end
    -- self:PlayRandomSound(role.id, 0, 6)
    LoadAsync("prefabs/effect/UI/fx_death.prefab", function(prefab)
        info.script:ChangeMode("");
        info.script:ShowUI(false);

        if not prefab then return end;

        local transform = info.script.gameObject.transform;
        local death = UnityEngine.GameObject.Instantiate(prefab, transform.parent);
        death.transform.localPosition = transform.localPosition;
        death.transform.localScale = Vector3.one;
        death.transform.localRotation = Quaternion.identity;

        game:CallAt(game:GetTick(3), function()
            UnityEngine.GameObject.Destroy(death.gameObject);
        end);        
    end)
end

local function upDateTimeoutView(uuid)
    local entity = game:GetEntity(uuid)
    if not entity or not entity.Timeout then
        return
    end

    if entity.Force.side == 1 then
        return
    end

    local ui = roles[uuid].ui
    if not ui.ActionTime then
        return
    end 

    local timeout_time = 0
    if entity.Timeout.timeout_tick and entity.Timeout.timeout_tick > game:GetTick() then
        timeout_time = game:GetTime(entity.Timeout.timeout_tick - game:GetTick()) - game:GetTime()
    end

    if timeout_time > 0 then
        ui.ActionTime.Text[UI.Text].text = "行动中   " .. string.format("%.1f", timeout_time)
    else
        ui.ActionTime.Text[UI.Text].text = "行动中   0"
    end
end

local interval = 0.2
function Update()
    interval = interval - UnityEngine.Time.deltaTime
    local show_focus_tag = interval < 0
    for uuid, info in pairs(roles) do
        local entity = game:GetEntity(uuid);
        if entity and entity:Alive() then
            updateEntityProperty(entity, info);
        elseif not root.speedUp then
            showDeadEntity(entity, info);
            ActionTimeActive(uuid, false)
        end

        if show_focus_tag then
            setFocusTagView(uuid);
        end
        
        upDateTimeoutView(uuid);
    end

    if show_focus_tag then
        interval = 0.2
    end

    -- if root.speedUp then return end
end

local function PlayAciton2(script, action)
    local SkeletonAnimation = script.spineObject.gameObject:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
    if SkeletonAnimation then
        SkeletonAnimation.AnimationState:SetAnimation(0, action, false)
        local success = pcall(SkeletonAnimation.AnimationState.AddAnimation, SkeletonAnimation.AnimationState, 0, "idle_talk", true, 0)
        if not success then
            SkeletonAnimation.AnimationState:AddAnimation(0 , "idle", true, 0)
        end
    end
end

local function UnitPlay(uuid, action)
    -- local uuid, action = info.uuid, info.action;
    local role = roles[uuid]
    if role then
        if role.side == 1 then
            PlayAciton2(role.script, action)
        else
            if role.script then
                role.script:Play(action, "idle");
            end
        end

        role.__enter_played = true;

        if role.hide then
            role.script.gameObject.transform.localPosition = role.org_position;
            role.script:ShowUI(true);
            role.hide = nil;
            role.org_position = nil;
        end
    end
end

local cameraController = root.view.battle.cameraController[SGK.Battle.BattleCameraController]
local enemy_action_effect = nil
local function cameraMove(uuid)
    local role = game:GetEntity(uuid)
    if not role then return end

    if role.side == 1 and role.pos >= 1 and role.pos <= 5 then
        cameraController:CameraMoveReset(root.view.battle.CameraSlot[role.pos].transform, 0.3);
    else
        cameraController:CameraMoveReset(root.view.battle.CameraSlot[3].transform, 0.3);
        -- [[
        if role.side ~= 1 then
            if enemy_action_effect == nil then
                LoadAsync("prefabs/effect/UI/fx_jues_act.prefab", function(o)
                    if not o then return; end;
                    enemy_action_effect = SGK.UIReference.Instantiate(o)
                    enemy_action_effect.transform.position = roles[uuid].script.gameObject.transform.position;
                    enemy_action_effect:SetActive(true);    
                end)
            elseif enemy_action_effect then
                enemy_action_effect.transform.position = roles[uuid].script.gameObject.transform.position;
                enemy_action_effect:SetActive(true);
            end
        end
        --]]
    end
end

-- local last_hurt_list = {}
function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "ENTITY_REMOVED" then
        removeEntity(...)
    elseif event == "UNIT_PLAY_ACTION" then
        local uuid, action = ...
        if root.speedUp and action ~= "ruchang" then return end
        UnitPlay(uuid, action);
    elseif event == "WAVE_FINISHED" or event == "FIGHT_FINISHED" then
        if not root.speedUp then return end
        root.speedUp = 1
        for uuid, info in pairs(roles) do
            local entity = game:GetEntity(uuid);
            if entity and entity:Alive() then
                updateEntityProperty(entity, info);
                local hurt = math.floor(entity.Property.hpp - entity.Property.hp) -- (last_hurt_list[uuid] or 0)
                -- last_hurt_list[uuid] = hurt
                if hurt > 0 and event == "FIGHT_FINISHED" then
                    showNumber(entity.uuid, math.floor(entity.Property.hpp - entity.Property.hp), nil, 1)
                end
            else
                showDeadEntity(entity, info);
            end
        end

    elseif event == "UNIT_BEFORE_ACTION" then
        if root.speedUp then return end
        local uuid = ...
        if filterPartnerEvent(uuid) then return end
        ActionTimeActive(uuid, true)
        cameraMove(uuid)
    elseif event == "UNIT_AFTER_ACTION" then
        if root.speedUp then return end
        local uuid = ...
        if filterPartnerEvent(uuid) then return end
        ActionTimeActive(uuid, false)
        if enemy_action_effect then
            enemy_action_effect:SetActive(false);
        end
    elseif event == "ROUND_START" then
        cameraController:CameraMoveReset()
        cameraController:CameraLookReset()
    end
end

--[[
function API.UnitPlay(skill, role, action, ...)
    role = role or skill.entity
    local info = roles[role.uuid]
    if not info then return; end
    info.script:Play(action, "idle");
end
--]]

function API.UnitPlayLoopAction(skill, role, action, ...)
    role = role or skill.entity
    local info = roles[role.uuid]
    if not info then return; end

    info.script:Play(action, action);
end

function GetBattlefiledObject(uuid)
    return roles[uuid] and roles[uuid].script;
end

function GetAllBattlefiledObject()
    return roles
end
