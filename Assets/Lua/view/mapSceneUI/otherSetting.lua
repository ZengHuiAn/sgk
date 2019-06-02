local SettingModule = require "module.gameSettingModule"

local otherSetting = {}

function otherSetting:Start()
    self:initData()
    self:initUi()
end

function otherSetting:initData()

end

function otherSetting:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.settingRoot = self.view.otherSettingRoot.ScrollView.Viewport.Content.settingRoot
    self:initTop()
end

function otherSetting:initTop()
    ---场景特效展示
    self.showEffect = self.settingRoot.top.effect.Toggle[UI.Toggle]
    self.showEffect.isOn = SettingModule.Get(SettingModule.Type.EffectShow)
    self.showEffect.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.EffectShow, value)
    end)

    ---拒绝好友邀请
    self.friend = self.settingRoot.top.friend.Toggle[UI.Toggle]
    self.friend.isOn = SettingModule.Get(SettingModule.Type.FirendInvite)
    self.friend.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.FirendInvite, value)
    end)

    ---同屏显示人数
    self.showPeople = self.settingRoot.top.showPeople.group[UI.ToggleGroup]
    self.settingRoot.top.showPeople.group[SettingModule.Get(SettingModule.Type.PeopleCount)][UI.Toggle].isOn = true
    for i = 1, #self.settingRoot.top.showPeople.group do
        local _view = self.settingRoot.top.showPeople.group[i]
        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                SettingModule.Set(SettingModule.Type.PeopleCount, i)
            end
        end)
    end

    ---语音设置
    self.language = self.settingRoot.language.group[UI.ToggleGroup]
    self.settingRoot.language.group[SettingModule.Get(SettingModule.Type.LanguageVoice)][UI.Toggle].isOn = true
    for i = 1, #self.settingRoot.language.group do
        local _view = self.settingRoot.language.group[i]
        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                SettingModule.Set(SettingModule.Type.LanguageVoice, i)
            end
        end)
    end

    ---背景音乐
    self.bgVoice = self.settingRoot.voice.bgVoice.Slider[UI.Slider]
    self.bgVoice.value = SettingModule.Get(SettingModule.Type.BgVoice)
    self.bgVoice.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.BgVoice, value)
    end)

    ---特效音乐
    self.effectVoice = self.settingRoot.voice.effectVoice.Slider[UI.Slider]
    self.effectVoice.value = SettingModule.Get(SettingModule.Type.EffectVoice)
    self.effectVoice.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.EffectVoice, value)
    end)

    ---剧情对白
    self.storyVoice = self.settingRoot.voice.storyVoice.Slider[UI.Slider]
    self.storyVoice.value = SettingModule.Get(SettingModule.Type.StoryVoice)
    self.storyVoice.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.StoryVoice, value)
        SGK.AudioSourceVolumeController.voiceVolume = System_Set_data.StoryVoice or 0.75;
    end)

    ---限时活动消息
    self.activity = self.settingRoot.notice.activity.Toggle[UI.Toggle]
    self.activity.isOn = SettingModule.Get(SettingModule.Type.ActivityNotice)
    self.activity.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.ActivityNotice, value)
    end)

    ---系统通知
    self.system = self.settingRoot.notice.system.Toggle[UI.Toggle]
    self.system.isOn = SettingModule.Get(SettingModule.Type.SystemNotice)
    self.system.onValueChanged:AddListener(function (value)
        SettingModule.Set(SettingModule.Type.SystemNotice, value)
    end)
end

return otherSetting