local EventManager = require 'utils.EventManager';
local NetworkService = require 'utils.NetworkService';

local _server_time = os.time();
local login = false;
local last_sync_time = os.time();
local _open_server_time = 0

local function now()
    return _server_time + os.time() - last_sync_time;
end

local function upOpenServerTime(opServer)
    if opServer then
        local _t = os.date("*t", opServer)
        _open_server_time = opServer - _t.sec - (_t.min * 60) - (_t.hour * 3600)
    end
end

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
    login = true;
    NetworkService.Send(100);
    last_sync_time = os.time();
end);

EventManager.getInstance():addListener("server_respond_101", function(event, cmd, data)
    local sn, result, now, opServer = data[1], data[2], data[3], data[4];
    if result == 0 then
        print("sync time success", now)
        _server_time = now;
        upOpenServerTime(opServer)
    end
end);

SGK.CoroutineService.Schedule(function()
    if not login or os.time() - last_sync_time < 60 then
        return;
    end

    last_sync_time = os.time();

    NetworkService.Send(100);
end);


local start_sec = 1478361600;   -- 2016-11-06 00:00:00' sunday
local day_sec = 24 * 3600;
local week_sec = 24 * 3600;

local function day(t)
    t = t or now();
    local pass = t - start_sec;
    return math.floor(pass / day_sec), pass % day_sec;
end

local function week(t)
    t = t or now();
    local pass = t - start_sec;
    local week_left =  pass % week_sec;
    return math.floor(pass / week_sec), math.floor(week_left / day_sec), week_left % day_sec;
end

local function openServerTime()
    return _open_server_time
end

return {
    now = now,
    day = day,
    week = week,
    openServerTime = openServerTime,
}
