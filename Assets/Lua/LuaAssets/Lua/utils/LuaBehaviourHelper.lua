


local statless_file = {
    ['view/npcInfo.lua'] = {},
    ['view/IconFrame.lua'] = {},
}

local function foo()
end

local function load_statless_file(file)
    if statless_file[file] == nil then return end;
    
    if statless_file[file].func == nil then
        statless_file[file].func = SGK.LuaController.Load(file, file) or foo;
    end

    return statless_file[file].func
end

if CS.SGK.LuaBehaviour.AddStatlessFile ~= nil then
    CS.SGK.LuaBehaviour.CleanStatlessFile();

    local function CreateLuaBehaviour(path)
        return load_statless_file(path)();
    end

    for path, _ in pairs(statless_file) do
        CS.SGK.LuaBehaviour.AddStatlessFile(path, CreateLuaBehaviour);
    end
end

loadfile = function(file, m, env)
    if statless_file[file] and env == nil then
        return load_statless_file(file);
    end
    return SGK.LuaController.Load(file, file, env);
end
