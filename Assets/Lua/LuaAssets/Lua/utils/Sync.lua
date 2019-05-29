
local TAG = "Sync";

local function doCreateFunc(func)
    if UnityEngine.Application.isEditor then
        return function ( ... )
            local ret = {xpcall(func, function (msg) ERROR_LOG(TAG, msg, debug.traceback()) end, ...)}
            if ret[1] then
                return unpack(ret, 2);
            end
        end
    end
    return func;
end

function Sync(func, instance, ...)
    coroutine.resume(coroutine.create(doCreateFunc(function ( ... )
        func(instance, ...);
        if instance and instance.LuaBehaviour then
            instance.LuaBehaviour:LuaRegisterEventAndCallAfterStart();
        end
    end)), ...);
end