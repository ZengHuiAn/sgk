local class = require "utils.class"

local M = class()

function M:_init_(target)
    self.list   = {}
    self.target =  target;
    self.changes = {}

    self.count = -1;
end

function M:Start()
end

function M:OnDestroy()
end

function M:Serialize()
    local info = {self.target, {}}
    for _, v in ipairs(self.list) do
        table.insert(info[2], {v.count, v.cd});
    end
    return info;
end

function M:DeSerialize(data)
    self.target  = data[1]
    self.list    = {}
    self.changes = {};
    self.count   = 0;
    for _, v in ipairs(data[2]) do
        table.insert(self.list, {count = v[1], cd = v[2]})
        self.count = self.count + v[1];
    end
end

local function sortList(list)
    table.sort(list, function(a, b)
        return a.cd < b.cd;
    end);
end

function M:SerializeChange()
    if not next(self.changes) then
        return;
    end

    local info = {}
    for cd, count in ipairs(self.changes) do
        table.insert(info, {cd, count});
    end

    self.changes = {}
    self.count   = -1;

    return info;
end

local function changeCount(list, cd, count)
    for k, v in ipairs(list) do
        if v.cd == cd then
            if count == 0 then
                table.remove(list, k);
            else
                v.count = count;
            end
            return;
        end
    end

    if count > 0 then
        table.insert(list, {count = count, cd = cd});
    end
end


function M:ApplyChange(changes)
    for cd, count in ipairs(changes) do
        changeCount(self.list, cd, count);
    end
    sortList(self.list);
    self.count = -1;
end

function M:Add(n, cd)
    if n <= 0 then return end

    self.count = -1;

    for _, v in ipairs(self.list) do
        if v.cd == cd then
            v.count          = v.count + n;
            self.changes[cd] = v.count;
            return
        end
    end

    table.insert(self.list, {count = n, cd = cd});

    sortList(self.list);
    self.changes[cd] = n;
end

function M:Remove(n)
    if n <= 0 then return end

    self.count = -1;

    while n > 0 and #self.list > 0 do
        local info = self.list[1];
        if info.count > n then
            info.count = info.count - n
            self.changes[info.cd] = info.count;
            break;
        else
            n = n - info.count;
            table.remove(self.list, 1);
            self.changes[info.cd] = 0;
        end
    end
end

function M:Count()
    if self.count < 0 then
        self.count = 0;
        for _, v in ipairs(self.list) do
            self.count = self.count + v.count;
        end
    end
    return self.count;
end

function M:FirstCD()
    local first = self.list[1]
    return first and first.cd or 0;
end

function M:FirstCount()
    local first = self.list[1]
    return first and first.count or 0;
end

function M:RemoveFrist()
    local first = self.list[1]
    if first then
        table.remove(self.list, 1);
        self.changes[first.cd] = 0;
    end
end

M.exports = {
    {"Count",             M.Count},
    {"FirstCount",        M.FirstCount},
    {"FirstCD",           M.FirstCD},
    {"RemoveFrist",       M.RemoveFrist},
}

return M;
