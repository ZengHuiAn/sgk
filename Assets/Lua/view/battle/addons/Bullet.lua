local battle_config = require "config/battle";
local partner_effect_count = 0

local function addEntity(entity)
    if not entity.Bullet then return end

    if entity.Bullet.id == 0 then return end;

    local cfg = battle_config.LoadSkillEffectCfg(entity.Bullet.id);
    if not cfg then return end

    local duration = entity.Bullet.duration - math.floor(cfg.hit_ahead_time * game.FRAME_RATE)
    local from, to = entity.Bullet.from, entity.Bullet.to;

    local to_hitpoint = cfg.hitpoint ~= "" and cfg.hitpoint ~= "0" and cfg.hitpoint or "hitpoint"

    -- print(cfg.bullet_effect, cfg.hit_effect)

    local hit_time = game:GetTime(duration - game.tick);


    local from_entity = game:GetEntity(from)
    if from_entity and from_entity.Force.side == 1 and from_entity.Force.pid ~= root.pid then 
        return
    end 

    if duration > game.tick and cfg.bullet_effect ~= "0" then
        LoadAsync("prefabs/effect/" .. cfg.bullet_effect .. ".prefab", function(prefab)
            if not prefab then return; end

            local t = hit_time - game:GetTime();
            if t <= 0 then
                return;
            end

            local fromObject = GetBattlefiledObject(from) or GetBattlefiledPetsObject(from);
            local toObject   = GetBattlefiledObject(to) or GetBattlefiledPetsObject(to);
        
            local fromPosition = fromObject and fromObject:GetPosition("hitpoint") or Vector3.zero;
            local toPostion = toObject and toObject:GetPosition(to_hitpoint) or Vector3.zero;
        
            local bullet = UnityEngine.GameObject.Instantiate(prefab);
            bullet.transform.position = fromPosition;
            bullet.transform:LookAt(toPostion)
            bullet.transform.localEulerAngles = 
                Vector3(bullet.transform.localEulerAngles.x, 
                    bullet.transform.localEulerAngles.y, 0)
            bullet.transform:DOMove(toPostion, t):Play();
            UnityEngine.GameObject.Destroy(bullet, t);
        end);
    end

    if cfg.hit_effect ~= "0" then
        LoadAsync("prefabs/effect/" .. cfg.hit_effect .. ".prefab", function(prefab)
            if not prefab then return end

            local t = hit_time - game:GetTime();

            if t < 0 then t = 0; end

            assert(coroutine.resume(coroutine.create(function()
                if t > 0 then
                    WaitForSeconds(t);
                end

                local entity = game:GetEntity(to);
                if entity then
                    UnitAddEffect(entity, cfg.hit_effect,{
                        hitpoint = cfg.hitpoint ~= "" and cfg.hitpoint or "hitpoint",
                        scale = cfg.scale or 1,
                    });
                end
            end)))
        end)
    end

    -- TODO; team member
end

local function removeEntity(uuid, entity)

end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "ENTITY_REMOVED" then
        if root.speedUp then return end
        removeEntity(...)
    end
end
