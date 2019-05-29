

table.pack = table.pack or function(...) return {...} end
table.unpack = table.unpack or unpack

local Event = {}

function Event.Init(game)
    game.event_list = {}
    game.event_watcher = {}
end

function Event.Start(game)
end

local function safe_call(game, func, ...)
    local success, err = coroutine.resume(coroutine.create(func),  ...);
    if not success then
       game:ERROR(err); 
    end
end

local function dispatchOneEvent(game, event, ...)
    local watcher = game.event_watcher[event];
    for _, v in ipairs(watcher or {}) do
        safe_call(game, v, game, event, ...);
    end

    local watcher = game.event_watcher['*'];
    for _, v in ipairs(watcher or {}) do
        safe_call(game, v, game, event, ...);
    end
end

function Event.Dispatch(game, event, ...)
    if not game.event_list then
        game:LOG('event_list is null', debug.traceback());
        return;
    end

    table.insert(game.event_list, {event, ...})

    if #game.event_list > 1 then
        return;
    end

    while #game.event_list > 0 do
        local content = game.event_list[1];
        dispatchOneEvent(game, table.unpack(content));
        table.remove(game.event_list, 1);
    end
end

function Event.Watch(game, event, func)
    game.event_watcher[event] = game.event_watcher[event] or {}
    table.insert(game.event_watcher[event], func);
end

function Event.Tick(game)
end

function Event.Stop(game)
end

return Event;
