--local SettingModule = require "module.gameSettingModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local UserDefault = require "utils.UserDefault";
local View = {}

local System_Set_data=UserDefault.Load("System_Set_data");
function View:Start()
    self.Root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view=self.Root.itemNode.otherSetting.otherSettingRoot.ScrollView.Viewport.Content.settingRoot

    self.Root.itemNode.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_shezhi_01")
    CS.UGUIClickEventListener.Get(self.Root.mask.gameObject).onClick = function (obj) 
        UserDefault.Save()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.Root.itemNode.otherSetting.ExitBtn.gameObject).onClick = function (obj) 
        UserDefault.Save()
        DialogStack.Pop()
    end
    --self.AudioSourceStory=CS.UnityEngine.GameObject.Find("CurrencyChat"):GetComponent(typeof(UnityEngine.AudioSource))
    self:RefSetting()
end

function View:RefSetting()
    --System_Set_data.EffectStatus=System_Set_data.EffectStatus or false 
    self.view.top.functionContral.effect.Toggle[UI.Toggle].isOn=module.MapModule.GetShielding()
    self.view.top.functionContral.effect.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
        utils.SGKTools.ShieldingMapPlayer()--屏蔽地图玩家
        showDlgError(nil,"设置成功!")
    end)

    if System_Set_data.EquipMentChangeNotify==nil then
       System_Set_data.EquipMentChangeNotify=true
    end
    self.view.top.functionContral.equipNotity.Toggle[UI.Toggle].isOn=System_Set_data.EquipMentChangeNotify
    self.view.top.functionContral.equipNotity.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
        System_Set_data.EquipMentChangeNotify=b
        showDlgError(nil,System_Set_data.EquipMentChangeNotify and "设置成功!系统将会为您进行装备推荐" or "设置成功!您将不再收到系统装备推荐")
    end)

    PlayerInfoHelper.GetPlayerAddData(0,PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS,function (playerAddData)
        self.view.top.functionContral.friend.Toggle[UI.Toggle].isOn=playerAddData.UnionAndTeamInviteStatus
        self.view.top.functionContral.friend.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
            PlayerInfoHelper.ChangeUnionAndTeamInviteStatus(b)  
        end)
    end)
    
    System_Set_data.HideOther=System_Set_data.HideOther or false
    self.view.top.functionContral.hideOther.Toggle[UI.Toggle].isOn=System_Set_data.HideOther or false
    self.view.top.functionContral.hideOther.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
        System_Set_data.HideOther=b
        showDlgError(nil,System_Set_data.HideOther and "设置成功!设置其他玩家不可见" or "设置成功!设置其他玩家可见")
    end)

    System_Set_data.ActivityNoticeStatus=System_Set_data.ActivityNoticeStatus==nil and true or System_Set_data.ActivityNoticeStatus
    self.view.notice.activity.Toggle[UI.Toggle].isOn=System_Set_data.ActivityNoticeStatus
    self.view.notice.activity.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
        if System_Set_data.ActivityNoticeStatus~=b then
            System_Set_data.ActivityNoticeStatus=b
            UserDefault.Save();
            DispatchEvent("CHECK_ACTIVITY_NOTICE");
            showDlgError(nil,"设置成功!")
        end
    end)

    System_Set_data.SystemNoticeStatus=System_Set_data.SystemNoticeStatus==nil and true or System_Set_data.SystemNoticeStatus
    self.view.notice.system.Toggle[UI.Toggle].isOn=System_Set_data.SystemNoticeStatus
    self.view.notice.system.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
        System_Set_data.SystemNoticeStatus=b
        UserDefault.Save();
        DispatchEvent("CHECK_SYSTEM_NOTICE");
        showDlgError(nil,"设置成功!")
    end)

    self.inputText =self.view.top.Expiry.InputField[UI.InputField]
   
    --self.view.top.Expiry.Button[UI.Button].onClick:RemoveAllListeners()
     CS.UGUIClickEventListener.Get(self.view.top.Expiry.Button.gameObject).onClick = function()
        if self.inputText.text == "" then
            showDlgError(nil, "请输入兑换码")
            return
        end
        local len = GetUtf8Len(self.inputText.text)
        if len < 18  then
            showDlgError(nil, "请重新输入兑换码")
            return
        end

        -- if NetworkService.Send(7, {nil, self.inputText.text, 11001}) then
        --     --showDlgError(nil, "兑换中")
        -- end
    end
    -- self.view.top.Expiry.Button[UI.Button].onClick:AddListener(function ()
        
    -- end)

    ---背景音乐
    self.bgVoice = self.view.voice.bgVoice.Slider[UI.Slider]
    self.effectVoice = self.view.voice.effectVoice.Slider[UI.Slider]
    self.storyVoice = self.view.voice.storyVoice.Slider[UI.Slider]

    self.bgVoice.value =System_Set_data.BgVoice or 0.75 

    self.bgVoice.onValueChanged:AddListener(function (value)
        System_Set_data.BgVoice=value
        SGK.BackgroundMusicService.SetAudioListenerVolume(System_Set_data.BgVoice or 0.75)
        SGK.BackgroundMusicService.GetAudio(System_Set_data.BgVoice)
    end)
    ---特效音乐
    self.effectVoice.value = System_Set_data.EffectVoice or 0.75
    self.effectVoice.onValueChanged:AddListener(function (value)
        System_Set_data.EffectVoice=value
        SGK.AudioSourceVolumeController.effectVolume = System_Set_data.EffectVoice or 0.75;
    end)
    ---剧情对白
    self.storyVoice.value=System_Set_data.StoryVoice or 0.75
    --self.storyVoice.maxValue=System_Set_data.StoryVoiceMaxvalue or 1
    self.storyVoice.onValueChanged:AddListener(function (value)
        System_Set_data.StoryVoice=value
        SGK.AudioSourceVolumeController.voiceVolume = System_Set_data.StoryVoice or 0.75;
    end)
end

function View:OnDestroy( ... )
    UserDefault.Save();
end

function View:listEvent()
    return{
    "PLAYER_ADDDATA_CHANGE_SUCCED",
    }
end

function View:onEvent(event,data)
    if event == "PLAYER_ADDDATA_CHANGE_SUCCED" then
        if not self.CanReceive then
            self.CanReceive=true
            SGK.Action.DelayTime.Create(0.5):OnComplete(function()
                self.CanReceive=false
                if data or data ==false then
                    showDlgError(nil,data and "设置成功!您将不再收到组队邀请和加入公会邀请" or "设置成功!邀请提示开启")
                end
            end)
        end    
    end
end


return View
