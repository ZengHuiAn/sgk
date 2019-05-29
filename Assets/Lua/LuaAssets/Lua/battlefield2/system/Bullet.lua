local Bullet   = require "battlefield2.component.Bullet"
local Property = require "battlefield2.component.Property"

local BuffSystem = require "battlefield2.system.Buff"
local AutoKill   = require "battlefield2.component.AutoKill"

local Entity    = require "battlefield2.Entity"

local M = {
    API = {}
}

function M.Start(game)
    local env = setmetatable({RAND=function(...)
        return game:CallAPI('RAND', {game = game}, ...)
    end}, {__index=_G});
    game.fight_hurt_calc = loadfile("battlefield/fight_hurt_calc.lua", 'bt', env)();
end

function M.Tick(game)

end

function M.Stop(game)
end


function M.Fire(game, from, to, duration, property, id)
    game:LOG('BulletSystem.Fire', from, to, duration, id)

    local entity = Entity();
    local bullet = entity:AddComponent("Bullet", Bullet(from, to, game:GetTick(duration), id));

    entity:AddComponent("AutoKill", AutoKill(game:GetTick(3)));

    if property then
        entity:AddComponent("Property", Property(property, true))
    end

    if not id or id == 0 then
        entity:AddComponent('SERVER_ONLY', {});
    end

    game:AddEntity(entity);

    -- game:LOG('bullet fire', entity.uuid, from, to);

    game:CallAt(bullet.duration, function(game, bullet)
        M.Hit(game, bullet);
    end, bullet);

    return bullet;
end

local function bulletExport(game, bullet)
    return setmetatable({__entity = bullet.entity:Export()}, {__index=function(t, k)
        if k == "target" then
            local entity = game:GetEntity(bullet.to)
            if not entity then game:LOG('bullet.to no found', bullet.to) end
            return entity and entity:Export();
        elseif bullet[k] ~= nil then
            return bullet[k];
        else
            return t.__entity[k]
        end
    end, {__newindex = function(t, k, v)
            t.__entity[k] = v;
    end}})
end


function M.Hit(game, bullet)
    game:LOG('BulletSystem.Hit', bullet.from, bullet.to, bullet.duration, bullet.id);

    local export = bulletExport(game, bullet); 

    local function filter(entity, action)
        if not entity then
            return
        end

        BuffSystem.DoAction(game, entity, action, export);
    end

    local attacker_uuid = bullet.attacker and bullet.attacker.uuid or 0;
    local attacker = game:GetEntity(attacker_uuid);
    local target = game:GetEntity(bullet.to);
    if target then
        filter(attacker, "BulletFilter_attackerBeforeHit");
        filter(target,   "BulletFilter_targetBeforeHit");

        filter(target,   "BulletFilter_targetFilter");
        if bullet.disabled then return end

        -- TODO: calc hurt and health
        local final_hurt,   final_hurt_type,    final_hurt_crit_type   = 20, 1, 4;
        local final_health, final_health_type , final_health_crit_type =  0, 2, 5;

        local final_hurt, hurt_crit, restrict = game.fight_hurt_calc.Hurt(export);
        local final_health, health_crit = game.fight_hurt_calc.Heal(export);

        export.hurt_final_value = final_hurt
        export.heal_final_value = final_health

        filter(attacker, "BulletFilter_attackerAfterCalc");
        filter(target,   "BulletFilter_targetAfterCalc");

        filter(attacker, "BulletFilter_attackerWillHit");
        filter(target,   "BulletFilter_targetWillHit");

        game:LOG('bullet hit', bullet.entity.uuid, final_hurt, final_health, attacker_uuid);

        local target_health = target:GetComponent('Health');
        if target_health then
            if export.hurt_final_value > 0 then
                target_health:Change(-export.hurt_final_value);
                game:DispatchEvent('UNIT_HURT', {
                    uuid = target.uuid, 
                    value = export.hurt_final_value, 
                    flag = hurt_crit and final_hurt_crit_type or final_hurt_type, 
                    name_id = export.name_id, 
                    attacker = attacker_uuid,
                    element = export.Element,
                    restrict = restrict,
                });
            elseif export.hurt_final_value < 0 then
                game:DispatchEvent('UNIT_HURT', {
                    uuid = target.uuid, 
                    value = 0, 
                    flag = hurt_crit, 
                    name_id = export.name_id, 
                    attacker = attacker_uuid,
                    element = export.Element,
                    restrict = restrict,
                });
            end

            if export.heal_final_value > 0 then
                target_health:Change(export.heal_final_value);
                game:DispatchEvent('UNIT_HEALTH', {
                    uuid = target.uuid, 
                    value = export.heal_final_value, 
                    flag = health_crit and final_health_crit_type or final_health_type, 
                    name_id = export.name_id, 
                    attacker = attacker_uuid,
                    element = export.Element,
                });
            end
        else
            game:LOG('target heave not heal component');
        end

        filter(attacker, "BulletFilter_attackerAfterHit");
        filter(target,   "BulletFilter_targetAfterHit");
    end

    game:RemoveEntity(bullet.entity.uuid);
end

function M.API.CreateBullet(skill,
    hurt, health,
    effect, cfg, 
    hitEffectName, hitEffectCfg)
    return setmetatable({
        hurt = hurt or 0, health = health or 0,
        effect = effect or {}, cfg = cfg or {},
        hit = { effect = hitEffectName, cfg = hitEffectCfg},
    }, {__index=function(t, k)
        return 0
    end, __newindex=function(t,k,v)
        rawset(t, k, v);
    end})
end

function M.API.BulletFire(skill, data, target, duration)
    local from = data.from and data.from.uuid or skill.entity.uuid;

    local bullet = M.Fire(skill.game, from, target.uuid, duration, {});
    for k, v in pairs(data) do
        if k ~= "from" and k ~= "to" then
            bullet[k] = v;
        end
    end
end

function M.API.CreateBullet2(skill, id, from, to, duration, property)
    -- duration = skill.game:TimeToTick(duration or 0);
    -- print('----. CreateBullet2', id);
    return M.Fire(skill.game, from.uuid, to.uuid, duration, property, id);
end

function M.API.BulletDisabled(skill, bullet)
    local entity = skill.game:GetEntity(bullet.uuid)
    if entity.Bullet then
        entity.Bullet.disabled = true
    end
end

return M;
