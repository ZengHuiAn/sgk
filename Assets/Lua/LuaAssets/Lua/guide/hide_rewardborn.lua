local gid = ...
gid = tonumber(gid)

if gid == 6028004 then
    if not module.QuestModule.Get(350013) or module.QuestModule.Get(350013).status ~= 1 then
        return true
    else
        return false
    end
end

if gid == 6028005 then
    if not module.QuestModule.Get(350013) or module.QuestModule.Get(350013).status ~= 1 then
        return false
    end
end

if gid == 6014001 then
    if not module.QuestModule.Get(350014) or module.QuestModule.Get(350014).status ~= 1 then
        return false
    end
end