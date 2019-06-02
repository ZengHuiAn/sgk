local M = {API = {}}

function M.Init(game)
    game.__rng = 1;
end

function M.API.RAND(skill, ...)
    local game = skill.game;
    if game.__rng == 1 then
        local sync_data = game:GetSingleton('GlobalData');
        if sync_data.seed == nil then
            game:ERROR('no seed');
        end
        game.__rng = WELLRNG512a(sync_data.seed or 0);
    end

    local a, b = select(1, ...);

    local o = game.__rng();

    if not a then
        return math.floor(o / 0xffffffff * 100) / 100;
    end

    local v = 0;
    if not b then
        if a <= 0 then
            assert(a > 0, 'interval is empty' .. debug.traceback());
        end
        v = 1 + o % a;
    elseif b >= a then
        v = a + (o % (b-a+1))
    else
        v = a;
    end

    return v;
end

function M.RAND(game, ...)
    if game.__rng == 1 then
        local sync_data = game:GetSingleton('GlobalData');
        if sync_data.seed == nil then
            game:ERROR('no seed');
        end
        game.__rng = WELLRNG512a(sync_data.seed or 0);
    end

    local a, b = select(1, ...);

    local o = game.__rng();

    if not a then
        return math.floor(o / 0xffffffff * 100) / 100;
    end

    local v = 0;
    if not b then
        if a <= 0 then
            assert(a > 0, 'interval is empty' .. debug.traceback());
        end
        v = 1 + o % a;
    elseif b >= a then
        v = a + (o % (b-a+1))
    else
        v = a;
    end

    return v;
end

return M;
