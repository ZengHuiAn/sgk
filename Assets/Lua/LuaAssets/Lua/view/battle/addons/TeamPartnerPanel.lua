local HeroEvoConfig = require "hero.HeroEvo"

local TeamMembersView = nil;
local SmallSkillPanel = false;

local FORCE_SHOW_TEAM_PANEL = true;
local FORCE_SHOW_TEAM_PANEL = true;

local panel_is_active = false;
local partner_status = {}

local function buildRoleInfo(entity)
    local stageCfg = HeroEvoConfig.GetConfig(entity.Config.id);
    local cfg = stageCfg and stageCfg[entity.Config.grow_stage];
    local quaity = cfg and cfg.quality or 1;
    local Player_list = game:FindAllEntityWithComponent("Player")
    
    local player_name = ""
    local player_level = 1

    for _, v in ipairs(Player_list) do
        if v.Player.pid == entity.Force.pid then
            player_name  = utils.SGKTools.matchingName(v.Player.name)
            player_level = v.Player.level
        end
    end

    return {
        uuid    = entity.uuid,

        pid     = entity.Force.pid,
        pos     = entity.Position.pos,

        player_name    = player_name,
        player_level   = player_level,

        icon    = entity.Config.mode,
        level   = entity.Config.level,
        star    = entity.Config.grow_star,
        quality = quaity,
    }
end

local command_list = {}
local function DOCommand( ... )
    if TeamMembersView == "loading" then
        table.insert(command_list, table.pack(...))
    elseif TeamMembersView then
        TeamMembersView[SGK.LuaBehaviour]:Call(...);
    end
end

local function OPTCommand(...)
    if TeamMembersView and TeamMembersView ~= "loading" then
        TeamMembersView[SGK.LuaBehaviour]:Call(...);
    end
end

function TeamPartnerPanelSetActive(active)
    if TeamMembersView and TeamMembersView ~= "loading" then
        TeamMembersView[UnityEngine.CanvasGroup].alpha = active and 1 or 0
    else
        panel_is_active = active;
    end
end

local function UseSmallSkillPanel()
    SmallSkillPanel = true;
    root.view.battle.partnerStage.slotCard[UnityEngine.Animator]:SetBool("half", true);
    root.view.battle.partnerStage.slotCard[1].partner[SGK.BattlefieldObjectPartner].half = true;
    root.view.battle.partnerStage.slotCard[2].partner[SGK.BattlefieldObjectPartner].half = true;
    root.view.battle.partnerStage.slotCard[3].partner[SGK.BattlefieldObjectPartner].half = true;
    root.view.battle.partnerStage.slotCard[4].partner[SGK.BattlefieldObjectPartner].half = true;
    root.view.battle.partnerStage.slotCard[5].partner[SGK.BattlefieldObjectPartner].half = true;
end

local function loadTeamMemberView()
    if TeamMembersView == "loading" then
        return;
    end

    if TeamMembersView then
        return;
    end

    TeamMembersView = "loading";
    LoadAsync("prefabs/battlefield/TeamMembers.prefab", function(prefab)
        local TeamMembers = SGK.UIReference.Instantiate(prefab)
        TeamMembers.transform:SetParent(root.view.battle.partnerStage.TeamSlot.Canvas.transform, false);

        while command_list[1] do
            local v = command_list[1];
            table.remove(command_list, 1)

            TeamMembers[SGK.LuaBehaviour]:Call(table.unpack(v));
        end
        
        TeamMembersView = TeamMembers;

        TeamMembersView[UnityEngine.CanvasGroup].alpha = 1

        if panel_is_active then
            TeamMembers.transform:DOLocalMoveY(5000, 0.5):From()
        end
    end);

    PartnerPanelForceHide();
end

local watching_entities = {}
root.team_partner_count = 0;
local team_pids = {};
local function createPartner(entity)
    if entity.Force.side ~= 1 then
        return;
    end

    if (FORCE_SHOW_TEAM_PANEL or entity.Force.pid ~= root.pid) and TeamMembersView == nil then
        loadTeamMemberView();
    end

    watching_entities[entity.uuid] = {
        pid = entity.Force.pid,
        status = 1,
    };
    if not team_pids[entity.Force.pid] then
        team_pids[entity.Force.pid] = true;
        root.team_partner_count = root.team_partner_count + 1;
        if root.team_partner_count == 3 then
            UseSmallSkillPanel();
        end
    end

    DOCommand("AddMember", buildRoleInfo(entity))
end

local function getEntityInfo(uuid)
    local entity = game:GetEntity(uuid)
    if not entity or not entity.Force then
        return;
    end

    return entity.Force.pid, entity.Force.side;
end

local function createBullet(entity)
    local from_uuid, to_uuid = entity.Bullet.from, entity.Bullet.to;

    local from_pid, from_side = getEntityInfo(from_uuid)
    if from_pid == root.pid then
        return;
    end

    local to_pid,   to_side = getEntityInfo(to_uuid)

    if from_side == 1 and to_side == 2 then
        local target = GetBattlefiledObject(to_uuid);
        if not target then return; end;

        local toPostion = target:GetPosition("hitpoint") or Vector3.zero;

        OPTCommand("CreateBullet", from_pid, from_uuid, toPostion);
    end
end

local function addEntity(uuid, entity)
    if entity.Input and entity.Config and entity.Force then
        createPartner(entity);
    elseif entity.Bullet then
        createBullet(entity);
    elseif entity.Player then
        partner_status[entity.Player.pid] = {}
    end
end

local function UNIT_BEFORE_ACTION(uuid)
    local entity = game:GetEntity(uuid)
    if not entity or entity.Force.side ~= 1 then return end;
    
    DOCommand("UNIT_BEFORE_ACTION", entity.Force.pid, uuid);
end

local function UNIT_AFTER_ACTION(uuid)
    local entity = game:GetEntity(uuid)
    if not entity or entity.Force.side ~= 1 then return end;

    DOCommand("UNIT_AFTER_ACTION", entity.Force.pid, uuid);
end

local function UNIT_PREPARE_ACTION(...)

end

local function UNIT_CAST_SKILL(info)
    local entity = game:GetEntity(info.uuid)
    if not entity or entity.Force.side ~= 1 then return end;

    local icon = nil;
    local script = entity.Skill.script[info.skill];
    icon = script and script.cfg and script.cfg.icon;

    OPTCommand("UNIT_CAST_SKILL", entity.Force.pid, info.uuid, icon);
end

local function UNIT_SKILL_FINISHED(info)
    local entity = game:GetEntity(info.uuid)
    if not entity or entity.Force.side ~= 1 then return end;
end

function GetPartnerStatus(pid)
    return partner_status[pid]
end

local next_update_time = 0;
function Update(dt)
    next_update_time = next_update_time - dt;
    if next_update_time > 0 then return end;

    next_update_time = 0.5;
    
    if not SmallSkillPanel then
        TeamPartnerPanelSetActive(GetSkillPannelstatus())
    end

    for _, v in pairs(partner_status) do
        v.not_all_action = false
        v.have_live = false
    end

    local round_info = game.round_info
    for uuid, info in pairs(watching_entities) do
        local entity = game:GetEntity(uuid);
        if entity and entity:Alive() then
            DOCommand("SetHP", info.pid, uuid, entity.Property.hp/entity.Property.hpp);
            if info.status ~= 1 then
                info.status = 1;
                DOCommand("HeroStatusChange", info.pid, uuid, 1);
            end
        
            partner_status[entity.Force.pid].have_live = true
            if entity.Round.round == round_info.round then
                partner_status[entity.Force.pid].not_all_action = true
            end
        else
            if info.status ~= 0 then
                info.status = 0;
                DOCommand("HeroStatusChange", info.pid, uuid, 0);
                DOCommand("SetHP", info.pid, uuid, 0);
            end
        end
    end 

    if root.team_partner_count > 1 then
        DOCommand("CheckMemberStatus", partner_status)
    end
end

local function ROUND_START()
    DOCommand("ROUND_START");
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        addEntity(...)
    elseif event == "UNIT_BEFORE_ACTION" then
        if root.speedUp then return end
        UNIT_BEFORE_ACTION(...);
    elseif event == "UNIT_AFTER_ACTION" then
        if root.speedUp then return end
        UNIT_AFTER_ACTION(...);
    elseif event == "UNIT_PREPARE_ACTION" then
        if root.speedUp then return end
        UNIT_PREPARE_ACTION(...)
    elseif event == "UNIT_CAST_SKILL" then
        if root.speedUp then return end
        UNIT_CAST_SKILL(...);
    elseif event == "ROUND_START" then
        if root.speedUp then return end
        ROUND_START()
    elseif event == "UNIT_SKILL_FINISHED" then
        -- UNIT_SKILL_FINISHED(...)
    elseif event == "BATTLE_SPEED_UP" then
        TeamPartnerPanelSetActive(false)
    end

end
