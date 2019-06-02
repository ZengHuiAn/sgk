local singbar_list = {}

local function addEntity(entity)
    if not entity.SingSkill then return end
    if not GetBattlefiledObject(entity.SingSkill.creator) then return end
    local Sing_Bar = GetAllBattlefiledObject()[entity.SingSkill.creator].ui.Sing_Bar
    if not Sing_Bar then return end

    Sing_Bar:SetActive(true)
    local script = Sing_Bar[SGK.LuaBehaviour]
    script:Call("CreateSingBar", entity.SingSkill.type, entity.SingSkill.total, entity.SingSkill.current, entity.SingSkill.certainly_increase, entity.SingSkill.beat_back)
    singbar_list[entity.uuid] = {}
    singbar_list[entity.uuid].script = script
    singbar_list[entity.uuid].type = entity.SingSkill.type
    singbar_list[entity.uuid].total = entity.SingSkill.total
    singbar_list[entity.uuid].current = entity.SingSkill.current
    singbar_list[entity.uuid].beat_back = entity.SingSkill.beat_back
    singbar_list[entity.uuid].certainly_increase = entity.SingSkill.certainly_increase
end

local function removeEntity(entity)
    if not entity.SingSkill then return end
    if not GetBattlefiledObject(entity.SingSkill.creator) then return end
    local Sing_Bar = GetAllBattlefiledObject()[entity.SingSkill.creator].ui.Sing_Bar
    if not Sing_Bar then return end

    Sing_Bar:SetActive(false)
    local script = Sing_Bar[SGK.LuaBehaviour]
    script:Call("CleanSingBar")
    singbar_list[entity.uuid] = nil
end

function Update()
    for uuid, singbar in pairs(singbar_list) do
        local entity = game:GetEntity(uuid)
        if entity then
            if entity.current ~= singbar.current 
            or entity.beat_back ~= singbar.beat_back 
            or entity.certainly_increase ~= singbar.certainly_increase 
            then
                singbar.script:Call("SetSingBar", entity.SingSkill.current, entity.SingSkill.certainly_increase, entity.SingSkill.beat_back)
                singbar.current = entity.SingSkill.current
                singbar.beat_back = entity.SingSkill.beat_back
                singbar.certainly_increase = entity.SingSkill.certainly_increase
            end
        end
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "ENTITY_REMOVED" then
        if root.speedUp then return end
        local uuid, entity = ...
        removeEntity(entity)
    end
end
