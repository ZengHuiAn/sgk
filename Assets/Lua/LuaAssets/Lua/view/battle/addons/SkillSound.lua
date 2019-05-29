local skill_config = require "config/skill";
local audioSource = nil

local function PlaySound(sound) 
    if audioSource == nil then
        audioSource = root.view.battle.partnerStage[SGK.AudioSourceVolumeController]
    end
    audioSource:Play("sound/" .. sound)
end

function PlayRandomSound(role_id, skill, type)
    local sounds = skill_config.GetSoundConfig(role_id, skill, type);
    if sounds and #sounds > 0 then
        PlaySound(sounds[math.random(1, #sounds)]);
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "UNIT_CAST_SKILL" then
        if root.speedUp then return end
        local info = ...
        if filterPartnerEvent(info.uuid) then return end
        local entity = game:GetEntity(info.uuid)
        if not entity then return end
        local skill_id = entity.Skill.ids[info.skill]
        PlayRandomSound(entity.Config.id, skill_id, 5)
    elseif event == "Unit_Dead" then
        if root.speedUp then return end
        local uuid = ...
        if filterPartnerEvent(uuid) then return end
        local entity = game:GetEntity(uuid)
        if not entity then return end
        PlayRandomSound(entity.Config.id, 0, 6)
    end
end
 
