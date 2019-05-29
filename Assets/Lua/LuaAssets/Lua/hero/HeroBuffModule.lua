local buff_configs = nil;

local function GetBuffConfig(id)
    if buff_configs == nil then
        buff_configs = LoadDatabaseWithKey("buff", "buff_id");
    end
    return buff_configs[id];
end


local buffs = nil;

local function LoadBuffs()
    if buffs == nil then
        buffs = {}
        utils.NetworkService.Send(197);
    end
end

local function GetBuff(id)
    LoadBuffs();

    return buffs[id];
end

local function GetBuffList()
    if not buffs then
        LoadBuffs();
    end
    return buffs;
end

local function UpdateBuff(data)
    local id, value, end_time = data[1], data[2], data[3];
    local now = module.Time.now();
    if end_time <= now then
        buffs[id] = nil;
        print('remove hero buff', id);
        return;
    end

    if not buffs[id] then
        buffs[id] = { id = id, value = value ,end_time = end_time, cfg = GetBuffConfig(id) }
    else
        buffs[id].value = value;
        buffs[id].end_time = end_time;
    end

    -- print('update hero buff', id, buffs[id].value, buffs[id].end_time  - now);
end

utils.EventManager.getInstance():addListener("server_respond_198", function(_, _, data)
    -- print("server_respond_198", sprinttb(data));
    local sn, result = data[1], data[2];
    if result ~= 0 then
        buffs = nil;
        return;
    end

    buffs = {};
    for _, v in ipairs(data[3]) do
        UpdateBuff(v);
    end
    DispatchEvent("HERO_BUFF_CHANGE");
end)

utils.EventManager.getInstance():addListener("server_notify_61", function(_, _, data)
    --print("server_notify_61", sprinttb(data));

    if not buffs then
        return;
    end
    --[[--暂时不提示获得buff
    local _buffId,_value = data[1],data[2]
    local changeValue = _value
    if buffs[_buffId] then  
        changeValue = _value - buffs[_buffId].value
    end
    if changeValue>0 then
        PopUpTipsQueue(10, {_buffId,changeValue})
    end
    --]]

    UpdateBuff(data); 
    DispatchEvent("HERO_BUFF_CHANGE");
end)

utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function()
    buffs = nil;
    LoadBuffs();
end);

local function CaclProperty(hero)
    local now = module.Time.now();
    local t = {}
    for k, v in pairs(buffs or {}) do
        if v.end_time < now then
            buffs[k] = nil;
        else
            if v.cfg and ((v.cfg.hero_id == 0) or (v.cfg.hero_id == hero.id)) then
                if v.cfg.type ~= 0 then
                    t[v.cfg.type] = (t[v.cfg.type] or 0) + (v.cfg.value * v.value);
                end
            end
        end
    end
    return t;
end

return {
    -- Get = GetBuff,
    GetList = GetBuffList,
    GetBuffConfig = GetBuffConfig,
    CaclProperty = CaclProperty,
}
