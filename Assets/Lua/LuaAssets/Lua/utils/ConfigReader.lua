
local protobuf = require "protobuf"

local ConfigReader = {
    tables = {}
}

local emptyTable = {}

function ConfigReader.Load(name)
    local table = ConfigReader.tables[name];
    if table == emptyTable then
        return nil;
    end

    if table then
        return table;
    end

    -- local def = SGK.ResourcesManager.Load("config/" .. name .. ".def.bytes");
    local def = SyncLoad("config/" .. name .. ".def.bytes");
    if not def then
        print("ConfigReader", name, "not exists")
        ConfigReader.tables[name] = emptyTable;
        return nil;
    end

    protobuf.register(def.bytes);

    -- local bytes = SGK.ResourcesManager.Load("config/" .. name .. ".cfg.bytes").bytes;
    local bytes = SyncLoad("config/" .. name .. ".cfg.bytes").bytes;

    local cfg = protobuf.decode("sgk.config.config_" .. name, bytes);

    if cfg then
        ConfigReader.tables[name] = cfg.rows;
        return cfg.rows;
    end
    return {};
end

function ConfigReader.ForEach(name, callback)
    local t = ConfigReader.Load(name)
    for i, row in ipairs(t or {}) do
        callback(row, i)
    end
end


local config_list = nil;

function ConfigReader.Preload(n)
    if config_list == nil then
        local func = loadfile("config/ConfigList.lua")
        config_list = func and func() or {}
    end

    if not config_list[1] then return end;

    local name = config_list[1]
    table.remove(config_list, 1)
    ConfigReader.Load(name);
    return name;
end

return ConfigReader;