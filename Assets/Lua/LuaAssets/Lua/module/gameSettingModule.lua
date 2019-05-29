local UserDefault = require "utils.UserDefault"

local Type = {
    EffectShow      = "effectShowStatus",
    FirendInvite    = "firendInviteStatus",
    PeopleCount     = "peopleCountStatus",
    LanguageVoice   = "languageVoiceStatus",
    BgVoice         = "bgVoiceStatus",
    EffectVoice     = "effectVoiceStatus",
    StoryVoice      = "storyVoiceStatus",
    ActivityNotice  = "activityNoticeStatus",
    SystemNotice    = "systemNoticeStatus",
}

local function toBool(data, status)
    if data == nil then
        if status ~= nil then
            return status
        end
        return true
    elseif data == 1 then
        return true
    else
        return false
    end
end

local SaveName = "gameSetting"

local gameSettingInfo = {
    effectShowStatus = toBool(UserDefault.Load(SaveName, true)[Type.EffectShow]),
    firendInviteStatus = toBool(UserDefault.Load(SaveName, true)[Type.FirendInvite]),
    peopleCountStatus = UserDefault.Load(SaveName, true)[Type.PeopleCount] or 1,
    languageVoiceStatus = UserDefault.Load(SaveName, true)[Type.LanguageVoice] or 1,
    bgVoiceStatus = UserDefault.Load(SaveName, true)[Type.BgVoice] or 1,
    effectVoiceStatus = UserDefault.Load(SaveName, true)[Type.EffectVoice] or 1,
    storyVoiceStatus = UserDefault.Load(SaveName, true)[Type.StoryVoice] or 1,
    activityNoticeStatus = toBool(UserDefault.Load(SaveName, true)[Type.ActivityNotice]),
    systemNoticeStatus = toBool(UserDefault.Load(SaveName, true)[Type.SystemNotice]),
}

local function Get(typeId)
    if gameSettingInfo[typeId] == nil then
        print("game setting info", typeId, "not find")
        return true
    end
    return gameSettingInfo[typeId]
end

local function Set(typeId, status)
    local _status = status
    if status == true then
        _status = 1
    elseif status == false then
        _status = 2
    end
    if gameSettingInfo[typeId] == nil then
        print("game setting info", typeId, "not find")
        return
    end
    gameSettingInfo[typeId] = status
    UserDefault.Load("gameSetting", true)[typeId] = _status
    DispatchEvent("LOACL_GAMESETTING_CHANGE")
end



return {
    Type = Type,
    Get = Get,
    Set = Set,
}