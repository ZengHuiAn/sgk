local Event_list = {}
local global_index = 0
local co = nil
local resume_delay = nil

local effect_delay = 0

function AddEventNeedPause(fun, weight)
    global_index = global_index + 1
    table.insert(Event_list, {fun = fun, weight = weight, index = global_index})
    if #Event_list == 1 then
    end
end

function EventNeedPause_Resume()
    if not co then
        return
    end
    assert(coroutine.resume(co))
    resume_delay = nil
end

function EventNeedPause_Yield(duraiton)
    if not co then
        return
    end

    if duraiton then
        resume_delay = duraiton
    end

    coroutine.yield()
end

function Update()
    if resume_delay then
        resume_delay = resume_delay - UnityEngine.Time.deltaTime
        if resume_delay < 0 then
            EventNeedPause_Resume()
            resume_delay = nil
        end
    end

    if effect_delay > 0 then
        effect_delay = effect_delay - UnityEngine.Time.deltaTime
        return
    end

    if not Event_list[1] then
        return
    end 

    if co then
        return
    end

    table.sort(Event_list, function(a, b)
        if a.weight ~= b.weight then
            return a.weight > b.weight
        end

        return a.index < b.index
    end)

    co = coroutine.create(function()
        root:Pause()
        Event_list[1].fun()
        table.remove(Event_list, 1)
        co = nil
        root:Resume()            
    end)
    assert(coroutine.resume(co))
end