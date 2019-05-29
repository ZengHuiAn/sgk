local M = {
    EVENT={}
}

function M.Init(game)
end

function M.Tick(game)
    local globalData = game:GetGlobalData();
    if globalData == nil then
        return;
    end

    local round = globalData.round;
    local tick  = game:GetTick();

    local list = game:FindAllEntityWithComponent("AutoKill")
    for _, v in ipairs(list) do
        if v.AutoKill.duration > 0 and game:GetTick() >= v.AutoKill.duration then
            game:RemoveEntity(v.uuid, {auto_remove = true});
        elseif v.AutoKill.lasting_round > 0 and round >= v.AutoKill.lasting_round then
            game:RemoveEntity(v.uuid, {auto_remove = true});
        end
    end
end

return M;
