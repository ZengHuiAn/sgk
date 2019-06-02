local class = require "utils.class"

local M = class();

function M:_init_()
    self.all_is_auto = false;
    self.last_all_is_auto = false;
    self.pids = {}
end

function M:Serialize()
    local list = {}
    for k, v in pairs(self.pids) do
        table.insert(list, {k, v});
    end
    
    return {self.all_is_auto, list}
end

function M:DeSerialize(data)
    self.all_is_auto = data[1];
    local list = data[2];
    self.pids = {}
    for _, v in ipairs(list) do
        local pid, status = v[1], v[2];
        self.pids[pid] = {auto = status, last = status};
    end
end

function M:SerializeChange()
    local list = {}
    for pid, v in pairs(self.pids) do
        if v.last ~= v.auto then
            v.last = v.auto
            table.insert(list, {pid, v.auto});
        end
    end

    if #list == 0 and self.last_all_is_auto == self.all_is_auto then
        return;
    end

    self.last_all_is_auto = self.all_is_auto;

    return {self.all_is_auto, list};
end

function M:ApplyChange(changes)
    self.all_is_auto = changes[1];

    local list = changes[2];
    for _, v in ipairs(list) do
        local pid, status = v[1], v[2];
        self.pids[pid] = {auto = status, changed = false};
    end
end

function M:SetAutoInput(status, pid)
    if not pid then
        self.all_is_auto = status;
    else
        self.pids[pid] = self.pids[pid] or {auto = false, last = false}
        self.pids[pid].auto = status;
    end
end

function M:GetAutoInput(pid)
    if not pid or self.all_is_auto then
        return self.all_is_auto;
    end

    if self.pids[pid] then
        return self.pids[pid].auto;
    end

    return false;
end

M.exports = {
    {"SetAutoInput", M.SetAutoInput},
    {"GetAutoInput", M.GetAutoInput},
}


return M;
