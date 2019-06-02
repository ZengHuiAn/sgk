local class = require "utils.class"

local M = class()
function M:_init_(func)
    self.func = func;
end

function M:Do(...)
    local success, v1, v2, v3 = pcall(self.func, ...);
    if not success then
        print(v1);
        return;
    end
    return v1, v2, v3
end

return M;
