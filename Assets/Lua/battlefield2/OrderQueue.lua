local class = require "utils.class"

local OrderQueue = class({})

-- table.unpack = table.unpack or unpack;
-- table.pack   = table.pack or function(...) return {...} end

function OrderQueue:_init_()
    self.queue  = {}
    self.notify = {}
end

function OrderQueue:Pop(order)
    local o = self.queue[1];
    if o and o.order <= order then
        table.remove(self.queue, 1)
        -- print("%d %s", o.tick, o.event);
        return o.order, o.event, o.data;
    end
end

function OrderQueue:Append(order, event, data)
    local o = {order = order, event = event, data = data }
    self:Add(o);
end

function OrderQueue:Add(o)
    local n = #self.queue;

    for i = n, 1, -1 do
        local v = self.queue[i];
        if v.order <= o.order then
            return self:insert(i+1, o)
        end
    end

    self:insert(1, o)
end

function OrderQueue:insert(k, o)
    table.insert(self.queue, k, o)
end

return OrderQueue;

