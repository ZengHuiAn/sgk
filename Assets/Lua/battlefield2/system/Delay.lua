local M = {API={}}

function M.Init(game)
    game.delay_list = {}
end

function M.Start(game)
end

function M.Call(game, tick, func, ctx)
    if tick <= game.tick then
        tick = game.tick + 1
    end

    game.delay_list[tick] = game.delay_list[tick] or {}
    table.insert(game.delay_list[tick], {tick = tick, func = func, ctx = ctx});
end

function M.Tick(game)
    local list = game.delay_list[game.tick]
    game.delay_list[game.tick] = nil;
    for _, item in ipairs(list or {}) do
        item.func(game, item.ctx);
    end
end

function M.Stop(game)
end

function M.API.Sleep(skill, time)
    local co = coroutine.running();
    M.Call(skill.game, skill.game:GetTick(time), function()
        assert(coroutine.resume(co));
    end)
    return coroutine.yield();
end

return M;
