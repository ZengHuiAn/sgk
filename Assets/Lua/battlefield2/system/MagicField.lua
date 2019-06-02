local MagicField = require "battlefield2.component.MagicField"

local Entity    = require "battlefield2.Entity"

local M = {
    API = {}
}

function M.Start(game)
end

function M.Tick(game)

end

function M.Stop(game)
end

function M.CreateMagicField(game, id, index, duration, side, pet_id, pid)
    game:LOG('MagicField.Create', id, index, duration, side, pid)

    local entity = Entity();
    local mf = entity:AddComponent("MagicField", MagicField(id, index, game:GetTick(duration), side, pet_id, pid))

    if not id or id == 0 then
        entity:AddComponent('SERVER_ONLY', {});
    end

    game:AddEntity(entity);

    -- game:LOG('bullet fire', entity.uuid, from, to);

    game:CallAt(mf.duration, function(game, uuid)
        game:RemoveEntity(uuid);
    end, entity.uuid);

    return entity;
end

function M.API.AddStageEffect(skill, id, index, duration, role, pet_id)
    return M.CreateMagicField(skill.game, id, index, duration, role and role.Force.side, pet_id, role and role.Force.pid):Export();
end

return M;
