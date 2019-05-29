local function AddInPauseEventList(id, delay)
    AddEventNeedPause(function()
        utils.MapHelper.PlayGuide(id, delay)
    end, 10)
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "PALY_BATTLE_GUIDE" then
        if root.args.remote_server or root.speedUp then return end
        local info = ...
        AddInPauseEventList(info.id, 0.5)
    end
end

function EVENT.LOCAL_GUIDE_CHANE(...)
    module.guideModule.PlayByType(7)
    module.guideModule.PlayByType(70)
end
