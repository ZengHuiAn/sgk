local M = { }

function M.Init(game)
    game.input_timeout_record = {};
end

function M.Start(game)

end

function M.Tick(game)
    for tick, v in pairs(game.input_timeout_record) do
        if tick <= game.tick then
            for _, info in pairs(v) do
                local co = info.co;
                info.co = nil;
                assert(coroutine.resume(co, 'TIMEOUT'));
            end
            game.input_timeout_record[tick] = nil;
        end
    end
end

function M.Stop(game)
end

local function record_timeout(game, co, time)
    if not time or time <= 0 then
        return {co = co}
    end

    local tick = game:GetTick(time);
    local info = {co = co, tick = tick}

    game.input_timeout_record[info.tick] = game.input_timeout_record[info.tick] or {}
    local list = game.input_timeout_record[info.tick];
    local pos = #list + 1;
    list[pos] = info;
    info.pos = pos;

    return info;
end

local function remove_timeout(game, info)
    if game.input_timeout_record[info.tick] then
        game.input_timeout_record[info.tick][info.pos] = nil;
    end
end

function M.Read(input, type, timeout)
    type = type or 1

    local co = coroutine.running();

    input.data[type] = input.data[type] or {cos = {}}

    if (not input.token) or (input.data[type].data == nil) then
        input.entity.game:LOG(input.entity.uuid, 'start read');
        -- input.entity.game:DispatchEvent('INPUT_START', input.entity.uuid);
        local info = record_timeout(input.entity.game, co, timeout);
        table.insert(input.data[type].cos, info)
        -- input.entity.game:DispatchEvent('INPUT_FINISHED', input);
        local data = coroutine.yield()
        input.entity.game:LOG(input.entity.uuid, 'finish read');
        return data;
    else
        local data = input.data[type].data;
        input.data[type].data = nil
        -- input.token = nil;
        return data
    end
end

function M.Push(input, data, typa)
    if typa == "SKILL" then
        assert(type(data) ~= "number", debug.traceback());
    end

    typa = typa or 1

    if not input.token then
        return
    end

    input.data[typa] = input.data[typa] or {cos = {}}
    while input.data[typa].cos[1] do
        local info = input.data[typa].cos[1];
        table.remove(input.data[typa].cos, 1);
        if info.co then
            remove_timeout(input.entity.game, info)
            assert(coroutine.resume(info.co, data));
            return;
        end
    end
    input.data[typa].data = data;
end

function M.SetToken(input, bool)
    input.token = bool;
    if not input.token then
        M.Reset(input);
    end
end

function M.GetToken(input)
    return input.token;
end

function M.SetRecord(game,records)
end

function M.GetRecord(game, uuid)
end

function M.Reset(input)
    local od = input.data;

    input.data = {}

    for _, d in pairs(od) do
        for _, info in ipairs(d.cos) do
            remove_timeout(input.entity.game, info)
            if info.co then
                assert(coroutine.resume(info.co, 'STOP')); 
            end
        end
    end
end

return M;
