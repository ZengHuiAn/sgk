local partner_list = {}
local show = nil;
local Pannel = root.view.battle.Canvas.Characters

local _force_hide = false;
function PartnerPanelForceHide()
    _force_hide = true;
    Pannel:SetActive(false);
end

function PartnerPanelSetActive(active)
    Pannel:SetActive(active and not _force_hide)
end

local function showAllPartners()
    if show then
        return
    end

    local list = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');
    local entities = {}
    for _, v in ipairs(list) do
        if v.Force.side == 1 and v.Force.pid == root.pid then
            table.insert(entities, v);
        end
    end

    table.sort(entities, function(a,b)
        if a.Position.pos ~= b.Position.pos then
            return a.Position.pos < b.Position.pos
        end
        return a.uuid < b.uuid
    end)
    
    for i = 1,5,1 do
        if entities[i] then
            partner_list[i] = {entity = entities[i], perfab = Pannel["newCharacterIcon"..i]}
            Pannel["newCharacterIcon"..i].Icon[UI.Image]:LoadSprite("icon/"..entities[i].Config.icon)
            Pannel["newCharacterIcon"..i]:SetActive(true)
        end
    end

    Pannel:SetActive(GetSkillPannelstatus() and not _force_hide)

    show = true
end

function Start()
  --  showAllPartners()
end

local function updatePartnerPannel(uuid)
    local entity = game:GetEntity(uuid);
    if entity.Force.side == 2 then
        Pannel:SetActive(false)
        return
    end

    Pannel:SetActive(not _force_hide)

    for k, v in ipairs(partner_list) do
        v.perfab.HP[CS.BattlefieldProgressBar]:SetValue(math.floor(v.entity.Property.hp), math.floor(v.entity.Property.hpp), math.floor(v.entity.Property.shield))
        v.perfab.MP[CS.BattlefieldProgressBar]:SetValue(math.floor(v.entity.Property.ep), math.floor(v.entity.Property.epp), 0)
        v.perfab.selector:SetActive(uuid == v.entity.uuid)
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "WAVE_ALL_ENTER" then
        if root.speedUp then return end
    --    showAllPartners()
    elseif event == "UNIT_BEFORE_ACTION" then
        if root.speedUp then return end
        local uuid = ...
        if filterPartnerEvent(uuid) then return end
    --    updatePartnerPannel(uuid)
    end
end
