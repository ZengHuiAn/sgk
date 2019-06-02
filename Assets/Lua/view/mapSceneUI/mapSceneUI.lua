local playerModule = require "module.playerModule"
local heroModule = require "module.HeroModule"
local HeroLevelup = require "hero.HeroLevelup"
local answerModule = require "module.answerModule"
local ChatManager = require 'module.ChatModule'
local MapConfig = require "config.MapConfig"
local openLevel = require "config.openLevel"
local unionModule = require "module.unionModule"
local Time = require "module.Time"
local RedDotModule = require "module.RedDotModule"
local AwardModule = require "module.AwardModule"
local NetworkService = require "utils.NetworkService"
local ItemHelper = require "utils.ItemHelper"
local quickToUseModule = require "module.quickToUseModule"
local activityConfig = require "config.activityConfig"
local DialogOpenLevelCfg = require "config.DialogOpenLevelCfg"
local UserDefault = require "utils.UserDefault"
local mapSceneUI = {}

function mapSceneUI:OpenDialog(name, data, parentTag)
    parentTag = parentTag or "UGUIRoot";

    if name == "SmallTeamDungeon" then
        local teamInfo = module.TeamModule.GetTeamInfo();
        if teamInfo.group ~= 0 then
            name = "TeamFrame"
            parentTag = "UGUIRootTop"
        else
            module.TeamModule.CreateTeam(999);--创建空队伍
            return
        end
    end
    --DialogStack.PushPrefStact(name, data,self.dialogRoot)
    if name == "fightResult/luckyCoin" then
        DialogStack.PushPref(name, data,UnityEngine.GameObject.FindWithTag(parentTag or "UGUIRoot"))
    else
        DialogStack.Push(name, data, parentTag)
    end
    -- self.bottomBar:SetActive(true)
    -- self.view.mapSceneUIRoot:SetActive(false)
end

function mapSceneUI:setChatMask() 
    self.newMapSceneChat_RealNode.mask.transform:SetParent(self.view.transform)
    local _rect = self.newMapSceneChat_RealNode.mask.gameObject:GetComponent(typeof(UnityEngine.RectTransform))
    _rect.sizeDelta = CS.UnityEngine.Vector2(0, 0)
    _rect.offsetMax = CS.UnityEngine.Vector2(_rect.offsetMax.x, 0)
    _rect.offsetMin = CS.UnityEngine.Vector2(_rect.offsetMin.x, 0)
end

function mapSceneUI:Start()
    self.IsApply = false--是否邀请
    self.IsStart = true--是否是start
    self.ChatRef_time = 0--聊天刷新间隔时间
    self.Friend_online = {}--玩家上线提示数据
    self:initData()
    self:initUI()
    self:initMapBottom()
    self:upBagRedDot()
    self:upFriendChatRedDot()
    self:initMassageBtn()
    self:loadQuestGuideTip()
    utils.SGKTools.ScrollingMarquee_Change(false)--解锁跑马灯通知
    -- self:setChatMask()
    SGK.Action.DelayTime.Create(1):OnComplete(function()
        self:initGuide()
        self:initFirstGuide()
        module.EquipHelp.ResetFlag()
        module.EquipHelp.ShowQuickToHero()
        module.HeroHelper.ShowRecommendedItem()
        --module.DefensiveFortressModule.QueryStatus()--查询元素暴走状态
    end)

    self:checkUiShow()
    --self:checkGuide()
    self:checkCityGrab(false)


    SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_star_click.prefab", function(obj)
        self.fx_star_click = CS.UnityEngine.GameObject.Instantiate(obj, self.view.mapSceneUIRoot.bottom.allBtn.transform)
        self.fx_star_click:SetActive(false);
    end);
end

function mapSceneUI:checkGuide()
    for i,v in ipairs(module.guideModule.CreateCharacterGuideCfg) do
        if i == 2 and module.guideModule.GetStoryFlag() then
            module.guideModule.SetStoryFlag(false)
        elseif v.questId then
            local _quest = module.QuestModule.Get(v.questId)
            if (_quest and _quest.status == 0) then
                if v.storyId then
                    LoadStory(v.storyId, v.func,false,true)
                    return
                else
                    local _func = v.func
                    _func()
                    return
                end
            end
        end
    end
end

function mapSceneUI:checkCityGrab(query)
    local cityGrab = UserDefault.Load("CityGrab", true)
    local unionId = module.unionModule.Manage:GetUionId(); 
    if cityGrab.guild == nil then
        cityGrab.guild = {};
    end
    if cityGrab.guild[unionId] == nil then
        cityGrab.guild[unionId] = {};
    end
    if cityGrab.guild[unionId].time and Time.now() - cityGrab.guild[unionId].time < (23 * 3600) then
        return;
    end
    if unionId ~= 0 then
        coroutine.resume(coroutine.create( function ()
            local cityCfg = activityConfig.GetCityConfig()
            for k,v in pairs(cityCfg.map_id) do
                local _unionInfo = module.BuildScienceModule.QueryScience(k, nil, query)
                if _unionInfo and _unionInfo.title == unionId then
                    if Time.now() - _unionInfo.time < (2.5 * 3600) then
                        if (cityGrab.guild[unionId].map_id ~= k) or (cityGrab.guild[unionId].time ~= _unionInfo.time) then
                            cityGrab.guild[unionId].map_id = k;
                            cityGrab.guild[unionId].time = _unionInfo.time;
                            DialogStack.PushPref("guildGrabWar/getCityTip", {map_id = k}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
                        end
                    end
                    break;
                end
            end                    
        end))    
    end
end

function mapSceneUI:loadQuestGuideTip()
    DialogStack.PushPref("mapSceneUI/QuestGuideTip", nil, self.view.guideLayerNode.gameObject)
    DialogStack.PushPref("mapSceneUI/MainUITeam", nil, self.view.mapSceneUIRoot.MainUITeam.gameObject)
    DialogStack.PushPref("mapSceneUI/WorldBossBuffList", nil, self.view.mapSceneUIRoot.top.worldBoss.gameObject)
    DialogStack.PushPref("mapSceneUI/mapSceneQuestList", nil, self.view.guideLayerNode.questListRoot.gameObject)
    -- local _p = UnityEngine.GameObject.FindWithTag("UGUIGuideRoot") or UnityEngine.GameObject.FindWithTag("UGUIRootTop")
    -- DialogStack.PushPref("StoryFrame",nil, _p)
end

function mapSceneUI:initMapBottom()
    -- if #DialogStack.GetStack() > 0 then
    --     self.bottomBar:SetActive(true)
    --     self.view.mapSceneUIRoot:SetActive(false)
    --     return
    -- end
    self:mapShowCanBack()
end

function mapSceneUI:initMapInfo()
    self.nowTime = self.view.mapSceneUIRoot.bottom.mapInfo.time[UI.Text]
    self.wifi = self.view.mapSceneUIRoot.bottom.mapInfo.network.wifi
    self.carrierData = self.view.mapSceneUIRoot.bottom.mapInfo.network.carrierData
    self.batteryNumber = self.view.mapSceneUIRoot.bottom.mapInfo.battery.batteryNumber[UI.Text]
    self.batteryStatus = self.view.mapSceneUIRoot.bottom.mapInfo.battery.batteryStatus
    self.batteryLevel = self.view.mapSceneUIRoot.bottom.mapInfo.battery.batteryLevel[UI.Image]
    self:upMapInfo()
end

function mapSceneUI:checkHomeMap()
    if utils.SGKTools.Athome() then
        local _nowHour = tonumber(os.date("%H", module.Time.now()))
        if self.lastHour and self.lastHour ~= _nowHour then
            if _nowHour >= 6 and _nowHour < 19 then
                if SceneStack.MapId() ~= 1 then
                    SceneStack.EnterMap(1)
                end
            else
                if SceneStack.MapId() == 1 then
                    SceneStack.EnterMap(1)
                end
            end
        end
        self.lastHour = _nowHour
    end
end

function mapSceneUI:upMapInfo()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad);
    if self.last_update_time == now then
        return;
    end
    self.last_update_time = now;

    -- self:checkHomeMap()
    self.nowTime.text = os.date("%H:%M", module.Time.now())

    local network_status = SGK.GetSystemInfo:networkStatus();
    if self.last_network_status ~= network_status then
        self.wifi:SetActive(network_status == 2)
        self.carrierData:SetActive(network_status == 1)
        self.last_network_status = network_status;
    end

    local battery_status = SGK.GetSystemInfo:batteryStatus()
    if self.last_battery_status ~= battery_status then
        self.batteryStatus:SetActive(battery_status)
        self.last_battery_status = battery_status;
    end

    local battery_level = SGK.GetSystemInfo:batteryLevel();
    if self.last_battery_level ~= battery_level then
        local _batteryNumber = math.floor(battery_level * 100)
        if _batteryNumber >= 50 then
            self.batteryLevel.color = {r = 59/255, g = 1, b = 188/255, a = 1}
        elseif _batteryNumber >= 10 then
            self.batteryLevel.color = {r = 1, g = 216/255, b = 0, a = 1}
        else
            self.batteryLevel.color = {r = 1, g = 26/255, b = 26/255, a = 1}
        end
        self.batteryLevel.fillAmount = battery_level
        self.batteryNumber.text = tostring(_batteryNumber)
        self.last_battery_level = battery_level;
    end
end
function mapSceneUI:RefTime( ... )
    if (Time.now() - module.FriendModule.RefTime()) > 300 then
        if module.FriendModule.RefTime() == 0 then
            NetworkService.Send(5011)
        else
            NetworkService.Send(5037,{nil,3});
            NetworkService.Send(5037,{nil,1});
        end
        module.FriendModule.RefTime(Time.now())
    end
end
function mapSceneUI:UpManorInfo(pid)
    local _, owner = module.ManorManufactureModule.GetManorStatus()
    if pid and math.floor(pid) == math.floor(owner) then
        self.view.mapSceneUIRoot.top.mapInfo.name[UI.Text].text=playerModule.Get(math.floor(pid)).name.."的"..MapConfig.GetMapConf(SceneStack.MapId()).map_name
    end
end
function mapSceneUI:UpUnionInfo()
    local QuestModule = require "module.QuestModule"
    local activityConfig = require "config.activityConfig"
    local mapId = SceneStack.MapId()
    local info = QuestModule.CityContuctInfo(nil,true)
    if info and info.boss and next(info.boss)~=nil then
        local cityCfg= activityConfig.GetCityConfig()
        local chat=MapConfig.GetMapConf(mapId).chat
        local _mapId = nil
        for k,v in pairs(cityCfg.map_id) do
            if v.chat == chat then
                _mapId=tonumber(k)
            end
        end
        if _mapId then
            coroutine.resume( coroutine.create( function ()
                local _unionInfo = module.BuildScienceModule.QueryScience(_mapId)

                if _unionInfo.title == 0 then
                    local map_info_confi = activityConfig.GetCityConfig(_mapId);
                    -- self.cfg.type   --地图类型
                    self.view.mapSceneUIRoot.top.unionInfo.name[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..map_info_confi.type)
                else
                    local unionInfo = module.unionModule.Manage:GetUnion(_unionInfo.title)
                    if unionInfo then
                        self.view.mapSceneUIRoot.top.unionInfo.name[UI.Text].text=unionInfo.unionName    
                    else
                        self.view.mapSceneUIRoot.top.unionInfo.name[UI.Text].text=""    
                    end
                end
                local buildLV = activityConfig.GetCityLvAndExp(info,nil,_mapId)
                self.view.mapSceneUIRoot.top.unionInfo.num.Text[UI.Text].text=buildLV
            end ) )
        else
            self.view.mapSceneUIRoot.top.unionInfo.gameObject:SetActive(false)
        end
    else
        self.view.mapSceneUIRoot.top.unionInfo.gameObject:SetActive(false)
        QuestModule.CityContuctInfo(true)
    end
end
function mapSceneUI:Update()
    self:upMapInfo()
    self:RefTime()
    self:upTop();
    --self:UpUnionInfo()
    --self:checkAnim()
end

function mapSceneUI:checkAnim()
    if self.view and self.view[UnityEngine.Animator] then
        if #DialogStack.GetStack() <= 0 then
            local _info = self.view[UnityEngine.Animator]:GetCurrentAnimatorStateInfo(0)
            if _info:IsName("close") then
                return
            end
            if not _info:IsName("open") and not _info:IsName("ui_close_1") then
                self.view[UnityEngine.Animator].enabled = true
                --self.view[UnityEngine.Animator]:Play("ui_close_1")
                local _guide = module.EncounterFightModule.GUIDE.GetInteractInfo()
                if _guide and _guide.name then
                    module.EncounterFightModule.GUIDE.Interact(_guide.name)
                end
            end
        elseif #DialogStack.GetStack() >= 1 then
            local _info = self.view[UnityEngine.Animator]:GetCurrentAnimatorStateInfo(0)
            if not _info:IsName("ui_open_1") then
                self.view[UnityEngine.Animator].enabled = true
                --self.view[UnityEngine.Animator]:Play("ui_open_1")
            end
        end
    end
end

function mapSceneUI:checkUiShow()
    if self.mapCfg then
        local _tab = BIT(self.mapCfg.Uishow or 0)
        for i,v in ipairs(_tab) do
            if tonumber(v) == 1 then
                if i == 1 then
                    self.view.mapSceneUIRoot.top.leaveBtn:SetActive(false)
                elseif i == 2 then
                    self.view.mapSceneUIRoot.top.topBtn:SetActive(false)
                elseif i == 3 then
                    self.view.mapSceneUIRoot.bottom.bg:SetActive(false)
                    self.view.mapSceneUIRoot.bottom.allBtn:SetActive(false)
                    self.view.mapSceneUIRoot.mapSceneTaskListRoot.recommend.transform.localPosition = self.view.mapSceneUIRoot.mapSceneTaskListRoot.recommend.transform.localPosition - Vector3(0, 80, 0)
                elseif i == 4 then
                    self.view.mapSceneUIRoot.MainUITeam:SetActive(false)
                elseif i == 5 then
                    self.view.guideLayerNode.guideLayerRoot:SetActive(false)
                    self.view.guideLayerNode.questListRoot:SetActive(false)
                elseif i == 6 then
                    self.view.mapSceneUIRoot.mapSceneTaskListRoot.recommend.guideRoot:SetActive(false)     
                elseif i == 7 then
                    self.view.mapSceneUIRoot.hunting:SetActive(false)
                end
            end
        end
    end
    local mapInfo = SceneStack.MapId("all");
    if mapInfo.mapId == 26 then
        DialogStack.PushPref("mapSceneUI/ManorUI", {pid = mapInfo.mapRoom}, self.view.guideLayerNode)
        if mapInfo.mapRoom ~= playerModule.GetSelfID() then
            self.view.mapSceneUIRoot.top:SetActive(false);
            self.view.mapSceneUIRoot.MainUITeam:SetActive(false);
            self.view.mapSceneUIRoot.bottom.bg:SetActive(false);
            self.view.mapSceneUIRoot.bottom.allBtn:SetActive(false)
        end
    end
end

function mapSceneUI:mapShowCanBack()
    -- local _name = SceneStack.GetStack()[SceneStack.Count()].name
    -- local _mapId = MapConfig.GetMapId(_name)
    local Stack = SceneStack.GetTopStack()
    if self.IsStart and (not (Stack.arg and Stack.arg.isPop)) and #DialogStack.GetStack() == 0 then
        self.IsStart = false
         LoadMapName(SceneStack.MapId())
    end

    if self.mapCfg then
        --self.bottomBar:SetActive(self.mapCfg.button == 1)
        --self.view.mapSceneUIRoot:SetActive(not (self.mapCfg.button == 1))
    end
    self:initQuickToUseList()
end

function mapSceneUI:initData()
    self.selectIndex = nil
    self.lastHour = nil
    self.mapCfg = MapConfig.GetMapConf(SceneStack.MapId())
    answerModule.GetTeamInfo()
end

function mapSceneUI:initUI()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.dialogRoot = self.view.prefDialogRoot
    self.uguiRoot = self.view.dialogRoot
    --self.bottomBar = self.view.CurrencyChat.UGUIResourceBar.gameObject
    --self.bottomBar:SetActive(false)
    self.view.CurrencyChat[SGK.LuaBehaviour]:Call("changeMapScene", true)
    self:initTop()
    self:initBottom()
    self:initChat()
    self:initMapInfo()
    --self:JoinRequestChange()
    self:INVITE_REF()--邀请列表刷新
    self:StartCombat()--是否显示重回战斗
    self:Roll_Query(true)--是否显示骰子
    self:checkHunting()
    NetworkService.Send(16072);--查询幸运币是否可使用
end

function mapSceneUI:playChatAnim()
    if self.view and self.view[UnityEngine.Animator] then
        self.view[UnityEngine.Animator]:Play("open")

        if not self.newMapSceneChat_RealNode then
            self.newMapSceneChat_RealNode = 1;
            SGK.ResourcesManager.LoadAsync("prefabs/mapSceneUI/component/newMapSceneChat.prefab", function(o)
                self.newMapSceneChat_RealNode = SGK.UIReference.Instantiate(o, self.view.mapSceneUIRoot.chatNode.newMapSceneChat.transform);
                CS.UGUIClickEventListener.Get(self.newMapSceneChat_RealNode.closeBtn.gameObject).onClick = function()
                    if self.view and self.view[UnityEngine.Animator] then
                        self.view[UnityEngine.Animator]:Play("close")
                        DispatchEvent("Stop_MapSceneChat",{Stop_MapSceneChat = true})
                    end
                end
                self:setChatMask();
                self:playChatAnim();
            end)
        end

        if self.newMapSceneChat_RealNode == 1 then
            return;
        end

        DispatchEvent("Stop_MapSceneChat",{Stop_MapSceneChat = false})
        --DispatchEvent("newMapSceneChat_moveto")
        SGK.Action.DelayTime.Create(0.5):OnComplete(function()
            if not self.newMapSceneChat_RealNode.ChatScrollView.activeSelf then
                self.newMapSceneChat_RealNode.ChatScrollView:SetActive(true);
            end
            DispatchEvent("Stop_MapSceneChat",{Stop_MapSceneChat = false})
            self.newMapSceneChat_RealNode.ChatScrollView[CS.ChatContent]:InitData()
        end)
    end
end

function mapSceneUI:initChat()
    self:ChatRef()
    for i = 1,3 do
        self.view.mapSceneUIRoot.bottom.chatNode[i][CS.UGUIClickEventListener].onClick = function ( ... )
            local _guide = UnityEngine.GameObject.FindWithTag("GuideRoot")
            if not _guide then
                self:playChatAnim()
            end
        end
    end
end

function mapSceneUI:initOtherPlayerIcon()
    CS.UGUIClickEventListener.Get(self.otherPlayerIcon.gameObject).onClick = function()
        if self.otherPlayerPid then
            DialogStack.PushPrefStact("mapSceneUI/otherPlayerInfo", self.otherPlayerPid, self.dialogRoot)
        end
    end
end

function mapSceneUI:showFirstUi()
    -- LoadStory(10000201, function ()
    --     local Stack = SceneStack.GetTopStack()
    --     if Stack and Stack.arg then
    --         Stack.arg.first = nil
    --     end
    --     DialogStack.PushPref("mapSceneUI/guideLayer/createCharacter", {func = function()
    --         module.guideModule.Play(8203)
    --     end}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    -- end)
end

function mapSceneUI:upOtherPlayeData(pid)
    local head = playerModule.IsDataExist(pid).head ~= 0 and playerModule.IsDataExist(pid).head or 11000
    self.otherPlayerIcon.allLabel.name[UI.Text].text = playerModule.IsDataExist(pid).name
    local _honor = module.honorModule.GetCfg(playerModule.IsDataExist(pid).honor)
    if playerModule.IsDataExist(pid).honor ~= 0 then
        if _honor then
            self.otherPlayerIcon.allLabel.honor[UI.Text].text = _honor.name
        end
    end
    utils.IconFrameHelper.Create(self.otherPlayerIcon.IconFrame, {pid = pid,disabledTween = true})
    self.otherPlayerIcon.allLabel.honor:SetActive(playerModule.IsDataExist(pid).honor ~= 0 and (_honor and true))
end

function mapSceneUI:upOtherPlayeIcon(pid)
    self.otherPlayerPid = pid

    if self.otherPlayerIcon == nil then
        self.otherPlayerIcon = 1
        SGK.ResourcesManager.LoadAsync("prefabs/mapSceneUI/component/otherPlayerIcon.prefab", function(o) 
            self.otherPlayerIcon = SGK.UIReference.Instantiate(o, self.view.bottomUIRoot.gameObject.transform);
            self:initOtherPlayerIcon();
            self:upOtherPlayeIcon(self.otherPlayerPid);
        end)
    end

    if self.otherPlayerIcon == 1 then
        return;
    end

    if not pid then  
        self.otherPlayerIcon:SetActive(false);
        return
    end

    self.otherPlayerIcon:SetActive(true);

    if playerModule.IsDataExist(pid) then
        self:upOtherPlayeData(pid)
    else
        playerModule.Get(pid,(function( ... )
            self:upOtherPlayeData(pid)
        end))
    end
end

function mapSceneUI:initTop()
    self.expBar = self.view.mapSceneUIRoot.top.topBg.ExpBar[UI.Scrollbar]
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.top.topBg.stronger.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/stronger/newStrongerFrame")
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.top.settingBtn.gameObject).onClick = function()
        DialogStack.Push("SettingFrame")
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.hunting.gameObject).onClick = function()
        local map_id = SceneStack.MapId();
        local info = module.HuntingModule.GetMapInfo(map_id)
        if info and info.depend_level_id <= module.playerModule.Get().level then
            DialogStack.Push("hunting/HuntingInfo", {map_id = map_id, showBack = true})
        else  
            DialogStack.Push("hunting/HuntingFrame")
        end
    end
    self.dirty = true;
    self:upTop()
end

function mapSceneUI:checkHunting()
    module.HuntingModule.CheckPlayerStatus()
end

function mapSceneUI:upTop()
    if not self.dirty then
        return ;
    end
    self.dirty = false;

    local hero = heroModule.GetManager():Get(11000)
    local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
    local Level_exp = hero_level_up_config[hero.level]
    local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1] or hero_level_up_config[hero.level]
    self.expBar.size = (hero.exp-Level_exp)/(Next_hero_level_up-Level_exp)

    self.view.mapSceneUIRoot.top.topBg.level[UI.Text].text = string.format("Lv %s", hero.level)
    
    utils.IconFrameHelper.Create(self.view.mapSceneUIRoot.top.topBg.IconFrame, {pid = module.playerModule.Get().id,type = utils.ItemHelper.TYPE.PLAYER, showDetail = true, onClickFunc = function()
        DialogStack.Push("mapSceneUI/newPlayerInfoFrame")
    end})

    self.view.mapSceneUIRoot.top.topBg.expNumber[UI.Text].text = string.format("%s%%", math.floor(self.expBar.size * 100))

    local _fighting = 0
    for i,v in ipairs(module.HeroModule.GetManager():GetFormation()) do
        if v ~= 0 then
            local _hero = module.HeroModule.GetManager():Get(v)
            if _hero then
                _fighting = _hero.capacity + _fighting
            else
                ERROR_LOG("_hero is nil,id",v)
            end
        end
    end

    self.view.mapSceneUIRoot.top.topBg.fighting.number[UI.Text].text = tostring(_fighting)

    self:upOpenLevelUi()
    self.view.mapSceneUIRoot.massage.answer:SetActive(module.answerModule.GetTeamStatus())
    local teamInfo=module.TeamModule.GetTeamInfo();
    self.view.mapSceneUIRoot.massage.DefensiveFortress:SetActive(module.DefensiveFortressModule.GetActivityStatus() and #teamInfo.members>=1)
end

function mapSceneUI:checkForbid(maps)
    local mapId = SceneStack.MapId();
    for i,v in ipairs(maps) do
        if v == mapId then
            return true;
        end
    end
    return false;
end

function mapSceneUI:upOpenLevelUi()
    self.view.mapSceneUIRoot.hunting:SetActive(openLevel.GetStatus(3222))

    for i = 1, #self.view.mapSceneUIRoot.bottom.allBtn do
        local _view = self.view.mapSceneUIRoot.bottom.allBtn[i]
        local _cfg = DialogOpenLevelCfg.MapSceneBottomBtn[i]
        if _cfg.openLevel then
            _view.lock.Text[UI.Text].text = openLevel.GetCloseInfo(_cfg.openLevel)
            if openLevel.GetStatus(_cfg.openLevel) then
                if _cfg.forbidMap and self:checkForbid(_cfg.forbidMap) then
                    _view.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
                else
                    _view.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
                end
                if _cfg.red then
                    _view.tip:SetActive(RedDotModule.GetStatus(_cfg.red))
                end
            else
                _view.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
            end
        elseif _cfg.red then
            _view.tip:SetActive(RedDotModule.GetStatus(_cfg.red))
        end
    end
    for i = 1, #self.view.mapSceneUIRoot.top.topBtn do
        local _view = self.view.mapSceneUIRoot.top.topBtn[i]
        local _cfg = DialogOpenLevelCfg.MapSceneTopBtn[i]
        _view.tip:SetActive(false)
        if _cfg.openLevel then
            _view.lock.Text[UI.Text].text = openLevel.GetCloseInfo(_cfg.openLevel)
            if openLevel.GetStatus(_cfg.openLevel) then
                if _cfg.canOpen then
                    _view:SetActive(_cfg.canOpen())
                else
                    _view:SetActive(true)
                end
                --_view[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
                if _cfg.red then
                    _view.tip:SetActive(RedDotModule.GetStatus(_cfg.red))
                end
            else
                _view:SetActive(false)
                --_view[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
                _view.tip:SetActive(false)
            end
        end
    end

    local _nodeList = {
        [1] = {node = self.view.mapSceneUIRoot.bottom.roleNode.itemNode,
        cfg  = DialogOpenLevelCfg.MapSceneBottomRole},
        [2] = {node = self.view.mapSceneUIRoot.bottom.competitionNode.itemNode,
        cfg  = DialogOpenLevelCfg.MapSceneBottomCompetition},
        -- [3] = {node = self.view.mapSceneUIRoot.bottom.leaveNode.itemNode,
        -- cfg  = DialogOpenLevelCfg.MapSceneBottomLeaveNode},
        [3] = {node = self.view.mapSceneUIRoot.bottom.shopNode.itemNode,
        cfg  = DialogOpenLevelCfg.MapSceneBottomShop},
    }

    for i,v in ipairs(_nodeList) do
        for j=1, #v.node do
            local _view = v.node[j]
            local _cfg = v.cfg[j]
            if _cfg then
                if _cfg.red then
                    RedDotModule.GetStatus(_cfg.red, nil, _view.tip)
                end
                if _cfg.openLevel then
                    if openLevel.GetStatus(_cfg.openLevel) then
                        _view.bg.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
                    else
                        _view.bg.icon[UI.Image].color = {r = 99/255, g = 99/255, b = 99/255, a = 1}
                    end
                else
                    _view.bg.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
                end
            end
        end
    end
    -- local _idx = 0
    -- if not openLevel.GetStatus(2201) then
    --     _idx = 1
    -- end
    -- self.view.mapSceneUIRoot.bottom.fb[CS.UGUISpriteSelector].index = _idx
end

function mapSceneUI:initBottom()
    local _func = function(_view, _cfg, i)
        if _cfg[i].mapName then
            if SceneStack.MapId() == _cfg[i].mapName then
                if tonumber(_cfg[i].mapName) == 26 and module.TeamModule.GetmapMoveTo()[6] ~= module.playerModule.GetSelfID() then
                    SceneStack.EnterMap(_cfg[i].mapName, {mapid = 26, mapType = 1})
                else
                    showDlgError(nil, "您当前已在"..MapConfig.GetMapConf(SceneStack.MapId()).map_name.."内")
                    return
                end
            end
            if utils.SGKTools.GetTeamState() then
                if utils.SGKTools.isTeamLeader() and tonumber(_cfg[i].mapName) == 26 then
                    SceneStack.EnterMap(_cfg[i].mapName, {mapid = 26, mapType = 1})
                elseif _cfg[i].teamDialog then
                    if tonumber(_cfg[i].mapName) == 25 then
                        showDlgError(nil, SGK.Localize:getInstance():getValue("guild_transpot_error"))
                    else
                        self:OpenDialog(_cfg[i].teamDialog, _cfg[i].data)
                    end
                end
            else
                if tonumber(_cfg[i].mapName) == 26 then
                    SceneStack.EnterMap(_cfg[i].mapName, {mapid = 26, mapType = 1})
                elseif tonumber(_cfg[i].mapName) == 25 then
                    if module.unionModule.Manage:GetUionId() == 0 then
                        DialogStack.Push("newUnion/newUnionList")
                    else
                        SceneStack.EnterMap(_cfg[i].mapName, _cfg[i].data)
                    end
                else
                    SceneStack.EnterMap(_cfg[i].mapName, _cfg[i].data)
                end
            end
        elseif _cfg[i].dialog then
            self:OpenDialog(_cfg[i].dialog, _cfg[i].data)
        elseif _cfg[i].callback then
            _cfg[i].callback();
        end
    end

    for i = 1, #self.view.mapSceneUIRoot.top.topBtn do
        local _view = self.view.mapSceneUIRoot.top.topBtn[i]
        local _cfg = DialogOpenLevelCfg.MapSceneTopBtn[i]
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _cfg.openLevel then
                if openLevel.GetStatus(_cfg.openLevel) then
                    _func(_view, DialogOpenLevelCfg.MapSceneTopBtn, i)
                else
                    _view.lock:SetActive(true)
                    _view.lock.transform:DOLocalMove(Vector3(0, 0, 0), 0.5):SetRelative(true):OnComplete(function()
                        _view.lock:SetActive(false)
                    end)
                end
            else
                _func(_view, DialogOpenLevelCfg.MapSceneTopBtn, i)
            end
        end
    end

    for i = 1, #self.view.mapSceneUIRoot.bottom.roleNode.itemNode do
        local _view = self.view.mapSceneUIRoot.bottom.roleNode.itemNode[i]
        local _cfg = DialogOpenLevelCfg.MapSceneBottomRole[i]
        CS.UGUIClickEventListener.Get(_view.bg.gameObject).onClick = function()
            if _cfg.openLevel then
                if openLevel.GetStatus(_cfg.openLevel) then
                    _func(_view, DialogOpenLevelCfg.MapSceneBottomRole, i)
                    self.view.mapSceneUIRoot.bottom.roleNode:SetActive(false)
                else
                    showDlgError(nil, openLevel.GetCloseInfo(_cfg.openLevel))
                end
            else
                _func(_view, DialogOpenLevelCfg.MapSceneBottomRole, i)
                self.view.mapSceneUIRoot.bottom.roleNode:SetActive(false)
            end
        end
    end
    for i = 1, #self.view.mapSceneUIRoot.bottom.competitionNode.itemNode do
        local _view = self.view.mapSceneUIRoot.bottom.competitionNode.itemNode[i]
        local _cfg = DialogOpenLevelCfg.MapSceneBottomCompetition[i]
        CS.UGUIClickEventListener.Get(_view.bg.gameObject).onClick = function()
            if _cfg.openLevel then
                if openLevel.GetStatus(_cfg.openLevel) then
                    _func(_view, DialogOpenLevelCfg.MapSceneBottomCompetition, i)
                    self.view.mapSceneUIRoot.bottom.competitionNode:SetActive(false)
                else
                    showDlgError(nil, openLevel.GetCloseInfo(_cfg.openLevel))
                end
            else
                _func(_view, DialogOpenLevelCfg.MapSceneBottomCompetition, i)
                self.view.mapSceneUIRoot.bottom.competitionNode:SetActive(false)
            end
        end
    end

    for i = 1, #self.view.mapSceneUIRoot.bottom.shopNode.itemNode do
        local _view = self.view.mapSceneUIRoot.bottom.shopNode.itemNode[i]
        local _cfg = DialogOpenLevelCfg.MapSceneBottomShop[i]
        CS.UGUIClickEventListener.Get(_view.bg.gameObject).onClick = function()
            if _cfg.openLevel then
                if openLevel.GetStatus(_cfg.openLevel) then
                    _func(_view, DialogOpenLevelCfg.MapSceneBottomShop, i)
                    self.view.mapSceneUIRoot.bottom.shopNode:SetActive(false)
                else
                    showDlgError(nil, openLevel.GetCloseInfo(_cfg.openLevel))
                end
            else
                _func(_view, DialogOpenLevelCfg.MapSceneBottomShop, i)
                self.view.mapSceneUIRoot.bottom.shopNode:SetActive(false)
            end
        end
    end

    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.bottom.roleNode.mask.gameObject, true).onClick = function()
        self.view.mapSceneUIRoot.bottom.roleNode:SetActive(false)
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.bottom.competitionNode.mask.gameObject, true).onClick = function()
        self.view.mapSceneUIRoot.bottom.competitionNode:SetActive(false)
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.bottom.shopNode.mask.gameObject, true).onClick = function()
        self.view.mapSceneUIRoot.bottom.shopNode:SetActive(false)
    end

    -- if utils.SGKTools.Athome() then
    --     self.view.mapSceneUIRoot.top.leaveBtn[CS.UGUISpriteSelector].index = 0
    -- else
    --     self.view.mapSceneUIRoot.top.leaveBtn[CS.UGUISpriteSelector].index = 1
    -- end
    self.view.mapSceneUIRoot.top.unionInfo.gameObject:SetActive(true)
    self:UpUnionInfo()
    local changeOutUI= function(k)
        self.view.mapSceneUIRoot.top.mapInfo.num.gameObject:SetActive(false)
        self.view.mapSceneUIRoot.top.mapInfo.name[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-3,-0.7)
    end
    local mapId = SceneStack.MapId();
    local mapConfig=MapConfig.GetMapConf(mapId)
    --self.view.mapSceneUIRoot.top.mapInfo.num.gameObject:SetActive(true)
    self.view.mapSceneUIRoot.top.mapInfo.num[UI.Text].text="No."..mapConfig.chat
    self.view.mapSceneUIRoot.top.mapInfo.name[UI.Text].text=mapConfig.map_name
    if utils.SGKTools.Athome() then
        changeOutUI(4)
        self.view.mapSceneUIRoot.top.unionInfo.gameObject:SetActive(false)
    elseif mapId == 25 then
        changeOutUI(1)
        --self.view.mapSceneUIRoot.top.unionInfo.gameObject:SetActive(false)
    elseif mapId == 26 then
        changeOutUI(2)
        --self.view.mapSceneUIRoot.top.unionInfo.gameObject:SetActive(false)
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.top.leaveBtn.gameObject).onClick = function()
        -- if utils.SGKTools.Athome() then
        --     self.view.mapSceneUIRoot.bottom.leaveNode:SetActive(true)
        -- else
        -- end
        module.EncounterFightModule.GUIDE.EnterMap(1)
    end

    local _redFunc = function()
        for i = 1, #self.view.mapSceneUIRoot.bottom.roleNode.itemNode do
            local _view = self.view.mapSceneUIRoot.bottom.roleNode.itemNode[i]
            if DialogOpenLevelCfg.MapSceneBottomRole[i].red then
                _view.tip:SetActive(RedDotModule.GetStatus(DialogOpenLevelCfg.MapSceneBottomRole[i].red, nil, _view.tip))
            else
                _view.tip:SetActive(false)
            end
        end
    end

    local fx_star_click = self.view.mapSceneUIRoot.bottom.fx_star_click;
    for i = 1, #self.view.mapSceneUIRoot.bottom.allBtn do
        local _view = self.view.mapSceneUIRoot.bottom.allBtn[i]
        module.RedDotModule.PlayRedAnim(_view.tip)
        local _cfg = DialogOpenLevelCfg.MapSceneBottomBtn[i]
        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            if self.fx_star_click then
                self.fx_star_click:SetActive(true);
                self.fx_star_click.transform.position = _view.transform.position -- + Vector2(0, 3);
            end

            if i == 1 then
                _redFunc()
                self.view.mapSceneUIRoot.bottom.roleNode:SetActive(true)
            elseif i == 3 then
                self.view.mapSceneUIRoot.bottom.shopNode:SetActive(true)   
            else
                if _cfg.forbidMap and self:checkForbid(_cfg.forbidMap) then
                    showDlgError(nil, "本地图禁止传送")
                else
                    if _cfg.openLevel then
                        if openLevel.GetStatus(_cfg.openLevel) then
                            _func(_view, DialogOpenLevelCfg.MapSceneBottomBtn, i)
                        else
                            _view.lock:SetActive(true)
                            _view.lock.transform:DOLocalMove(Vector3(0, 0, 0), 0.5):SetRelative(true):OnComplete(function()
                                _view.lock:SetActive(false)
                            end)
                        end
                    else
                        _func(_view, DialogOpenLevelCfg.MapSceneBottomBtn, i)
                    end
                end
            end
        end
    end

    RedDotModule.PlayRedAnim(self.view.mapSceneUIRoot.bottom.friend.tip)

    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.answer.gameObject).onClick = function()
        DialogStack.Push("answer/weekAnswerFrame")
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.questBtn.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/newQuestList")
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.bottom.chatSetting.gameObject).onClick = function()
        DialogStack.PushPref("FiltrationChat")
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.bottom.friend.gameObject).onClick = function()
        DialogStack.PushPrefStact("FriendSystemList")
    end

    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.fight.gameObject).onClick = function()
        --重回战斗
        module.EncounterFightModule.SetCombatTYPE(0)
        module.EncounterFightModule.StartCombat()
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.PubReward.gameObject).onClick = function()
        --骰子
        local data = module.TeamModule.GetPubRewardData()
        DialogStack.Push("fightResult/PubReward")
    end
    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.ExtraSpoils.gameObject).onClick = function()
        --幸运币
        DialogStack.PushPref("fightResult/luckyCoin")
    end

    CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.DefensiveFortress.gameObject).onClick = function()
        --元素暴走
        local teamInfo=module.TeamModule.GetTeamInfo();
        if #teamInfo.members>=1 then
            module.DefensiveFortressModule.QueryEnterActivity()
        else
            self.view.mapSceneUIRoot.massage.DefensiveFortress:SetActive(false)
        end
    end
end

function mapSceneUI:initMassageBtn()
    -- CS.UGUIClickEventListener.Get(self.view.mapSceneUIRoot.massage.teamApply.gameObject).onClick = function()
    --     --临时队伍申请入口
    --     --print("1111111111")
    --     local teamInfo = module.TeamModule.GetTeamInfo();
    --     if teamInfo.group ~= 0 and module.playerModule.GetSelfID() == teamInfo.leader.pid then
    --         DialogStack.Push("TeamFrame",{idx = 3})
    --         --DialogStack.PushPrefStact("TeamApplyFrame",{Type = 1},self.dialogRoot)
    --     else
    --         --DialogStack.Push("TeamFrame",{idx = 4})
    --         --DialogStack.PushPrefStact("TeamApplyFrame",{Type = 2},self.dialogRoot)
    --     end
    -- end
end

function mapSceneUI:initGuide()
    module.guideModule.PlayByType(4, 0.1)
    module.guideModule.PlayByType(1, 0.2)
end

function mapSceneUI:initFirstGuide()
    if module.guideModule.GetFirstLogin() then
        if utils.SGKTools.Athome() and #DialogStack.GetStack() == 0 then
            -- ERROR_LOG("zoe初次主界面调用1000引导")
            module.guideModule.PlayByType(1000, 0.1)
            module.guideModule.PlayByType(1200)
            module.guideModule.SetFirstLogin(false)
        end
    end
end

function mapSceneUI:upBagRedDot()
    self.view.mapSceneUIRoot.bottom.allBtn.bag.tip.gameObject:SetActive(RedDotModule.GetStatus(RedDotModule.Type.Bag.Bag))
end

function mapSceneUI:upFriendChatRedDot()
    self.view.mapSceneUIRoot.bottom.friend.tip.gameObject:SetActive(RedDotModule.GetStatus(RedDotModule.Type.FriendChat.Chat))
end

function mapSceneUI:listEvent()
    return {
        "LOCAL_MAPSCENE_OPEN_TASKLIST",
        "LOCAL_MAPSCENE_OPEN_ACTIVITYINFO",
        "UIRoot_refresh",
        "LOCAL_MAPSCENE_PUSHSCENE",
        "PLAYER_INFO_CHANGE",
        "Chat_INFO_CHANGE",
        "LOCAL_MAPSCENE_OPEN_CHATFRAME",
        "PLAYER_ADDDATA_CHANGE_SUCCED",
        --"TEAM_JOIN_REQUEST_CHANGE",
        --"JOIN_CONFIRM_REQUEST",
        --"delApply_succeed",
        "TEAM_PLAYER_INVITE_LIST_CHANGE",
        "TEAM_PLAYER_QUERY_INVITE_REQUEST",
        "Map_Click_Player",                     ---点击玩家
        "LOCAL_REDDOT_BAG_CHANE",               ---背包红点提示
        "LOCAL_REDDOT_CLOSE",
        "Team_members_Request",                 ---当前点击人的队伍消息
        "LOCLA_QUICKTOSUE_CHANE",
        "MapSceneUI_Push",
        "PlayAudioSource",
        "LOCLA_MAPSCENE_OPEN_OTHER",
        "PlayAudioEffectSource",
        "QUEST_INFO_CHANGE",
        "AFTER_QUEST_INFO_CHANGE",
        "QUEST_FINISH",
        "LOCAL_GUIDE_CHANE",
        "TeamCombatFinish",
        "LOCAL_NOTIFY_MAPSCENE_PUSH",
        "LOCAL_NOTIFY_MAPSCENE_PUSH_ERROR",
        "LOCAL_NOTIFY_CLOSE_BOTTOMBAR",
        "LOCLA_MAPSCENE_SHOW_QUICKTOHERO",
        "ITEM_INFO_CHANGE",
        "PLAYER_LEVEL_UP",
        "Roll_Query_Respond",
        "TEAM_QUERY_NPC_REWARD_REQUEST",
        "HeroCamera_DOOrthoSize",
        --"Friend_INFO_Desc",
        "PrivateChatData_CHANGE",
        "Mail_Delete_Succeed",
        "MAP_CHARACTER_DISAPPEAR",
        "LOCAL_DIALOGSTACK_PUSHMID",
        "LOCAL_ANSWER_STATUS_CHANGE",
        "RECOMMENDED_ITEM_CHANGE",
        "GiftBoxPre_to_FlyItem",
        "LOCAL_ACHIEVEMENT_CHANGE",
        "ENTER_PROTECT_BASE",
        "MANOR_SCENE_CHANGE",
        "TEAM_LIST_CHANGE",
        "GUILD_GRABWAR_START",
        "TEAM_PLAYER_REPLY_INVITATION_REQUEST",
        "NOTIFY_TEAM_ALL_CHANGE",
        "MAP_OWNER_CHANGE",
        "MapSceneUI_Role_Icon",
        "SystemMessageListRedDotChange",
        "ONE_TIME_REWARD_INFO_CHANGE",
    }
end

function mapSceneUI:FreshMSG( ... )

    if module.TeamModule.getAFKMembers( module.playerModule.GetSelfID() ) then
        showDlg(nil,"队长发起全体归队，是否归队？",function()
            module.TeamModule.QueryLeaderInfo(function (_data)
                print("队长地图信息",sprinttb(_data));
                
                print("查看是否能切换地图",module.TeamModule.CheckEnterMap(_data[3][1],true));
                if not module.TeamModule.CheckEnterMap(_data[3][1],true) then
                    showDlgError(nil,"无法传送到队长身边");
                    return;
                else
                    module.TeamModule.TEAM_AFK_RESPOND(function (err )
                        if err == 0 then
                            module.TeamModule.QueryLeaderInfo();--查询队长位置
                        end
                    end)


                end

            end)
        end,function()end)
    end
end

function mapSceneUI:ChatRef( ... )
    if self.ChatRef_time < Time.now() then
        self.ChatRef_time = Time.now()
        local channelName = {[0] = "系统",[1] = "世界",[6] = "私聊",[3] = "公会",[7] = "队伍",[8] = "好友",[10] = "组队",[100] = "地图"}
        self.ChatData = ChatManager.GetNewChat()

        for i = 1,#self.ChatData do
            local label = self.view.mapSceneUIRoot.bottom.chatNode[i+1][UnityEngine.UI.Text]
            label.text = ""
            local desc = WordFilter.check(self.ChatData[i].message)
            local applyLen =string.len(desc)
            self.applyType=string.sub(desc,0,1)
            if tonumber(self.applyType)==3  or tonumber(self.applyType)==1 or tonumber(self.applyType)==4 then
                desc = string.sub(desc,2,applyLen)
            else
                desc = desc
            end
            if self.ChatData[i].channel == 0 then
                desc = self.ChatData[i].message
            end
            local desc_list = StringSplit(desc,"\n")
            if #desc_list > 1 then
                desc = ""
                for i =1,#desc_list do
                    desc = desc..desc_list[i]
                end
            end
            local name = self.ChatData[i].fromname..":"
            if self.ChatData[i].channel == 0 then
                name = ""
            end
            label.text = label.text.."["..(channelName[self.ChatData[i].channel] or "未知").."]"..name..desc.."\n"
            self.view.mapSceneUIRoot.bottom.chatNode[i+1][CS.InlineText].onClick = function (name,id)
                if id == 1 then--申请入队
                    local teamInfo = module.TeamModule.GetTeamInfo();
                    if teamInfo.group == 0 then
                        if openLevel.GetStatus(1601) then
                            self.IsApply = true
                            module.TeamModule.GetPlayerTeam(self.ChatData[i].fromid,true)--查询玩家队伍信息
                        else
                            showDlgError(nil,"等级不足")
                        end
                    else
                        showDlgError(nil,"已在队伍中")
                    end
                elseif id == 2 then--申请入会
                    if module.unionModule.Manage:GetUionId() == 0 then
                        module.unionModule.JoinUnionByPid(self.ChatData[i].fromid)
                    else
                        showDlgError(nil,"您已经加入了一个公会")
                    end
                end
            end
        end
    end
    self.view.mapSceneUIRoot.bottom.chatNode.bg.tip.gameObject:SetActive(RedDotModule.GetStatus(RedDotModule.Type.Chat.ChatShow, nil, self.view.mapSceneUIRoot.bottom.chatNode.bg.tip))
end

-- function mapSceneUI:JoinRequestChange()
--     local waiting = module.TeamModule.GetTeamWaitingList(3)
--     local count = 0
--     for k, v in pairs(waiting) do
--         count = count + 1
--     end
--     local teamInfo = module.TeamModule.GetTeamInfo();
--     local _btnRoot = self.view.mapSceneUIRoot.bottom.top.allBtn
--     local applyBtn = false
--     if count > 0 and teamInfo.leader.pid == playerModule.Get().id then
--         applyBtn = true
--     end
--     ---------------------------------------------------------------------------------------------------
--     self.view.mapSceneUIRoot.massage.teamApply.gameObject:SetActive(count > 0 and teamInfo.leader.pid == playerModule.Get().id)
-- end


function mapSceneUI:INVITE_REF()
    --查询玩家邀请列表
    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.group == 0 or (teamInfo.group ~= 0 and module.playerModule.GetSelfID() ~= teamInfo.leader.pid)then
        --local _btnRoot = self.view.mapSceneUIRoot.bottom.top.allBtn
        --self.view.mapSceneUIRoot.massage.teamApply.gameObject:SetActive(#module.TeamModule.getTeamInvite()>0)
        local list = module.TeamModule.getTeamInvite()

        print(" snake 邀请列表 =====",sprinttb(list))
        if #list > 0 then
            --local pid = list[1].hostId
            --playerModule.Get(pid,function(data)
                --ERROR_LOG("!!!",sprinttb(list))
                local playerInfo = playerModule.Get();
                print("玩家信息",sprinttb(playerInfo));
                module.unionModule.queryPlayerUnioInfo(list[1].leader_id)
                DispatchEvent("showDlgMsg",{
                    msg = "玩家<color=#a95000>"..list[1].leader_name.."</color>邀请你加入队伍",
                    confirm = function ( ... )
                        module.TeamModule.GetPlayerTeam(list[1].leader_id,true,function ( ... )
                            coroutine.resume( coroutine.create( function ( ... )
                                -- body
                                local info = module.TeamModule.GetClickTeamInfo(list[1].leader_id);
                                -- ERROR_LOG(sprinttb(info));
                                -- ERROR_LOG("玩家信息",sprinttb(playerInfo));
                                local lev = playerInfo.level;

                                print("队伍要求等级",info.upper_limit,info.lower_limit);
                                if lev > info.upper_limit or lev < info.lower_limit then
                                    NetworkService.Send(18156,{nil,list[1].team_id,false});
                                    showDlgError(nil,"未满足队伍条件");
                                else
                                    NetworkService.SyncRequest(18156,{nil,list[1].team_id,true});
                                    module.TeamModule.QueryLeaderInfo(function (_data)
                                        if module.TeamModule.CheckEnterMap(_data[3][1]) then

                                        else

                                            module.TeamModule.TEAM_AFK_REQUEST();
                                            showDlgError(nil,"无法传送到队长身边");
                                        end 
                                    end)
                                end
                            end))
                        end)
                    end,
                    cancel = function ( ... )
                        NetworkService.Send(18156,{nil,list[1].team_id,false});
                    end,
                    txtConfirm = "同意",
                    txtCancel = "拒绝",
                    NotExit = true})
            --end)
        end
    end
end
function mapSceneUI:StartCombat()
    self.view.mapSceneUIRoot.massage.fight:SetActive(module.EncounterFightModule.GetCombatData())
end
function mapSceneUI:FriendRed()
    self.listData = {}
    local ChatData = ChatManager.GetManager(6)--私聊内容
    if ChatData then
        for k,v in pairs(ChatData)do
            if #v > 0 then
                local tempData = v[#v]
                local count = ChatManager.GetPrivateChatData(tempData.fromid)
                if count and count > 0 then
                    return true
                end
            end
        end
    end
    --ERROR_LOG(sprinttb(ChatData))
    ChatData = ChatManager.GetManager(8)--好友通知
    if ChatData then
        for k,v in pairs(ChatData)do
            if #v > 0 and v[1].status == 1 then
                return true
            end
        end
    end
    ChatData = ChatManager.GetSystemMessageList()--系统离线消息
    for k,v in pairs(ChatData) do
        for i = 1,#v do
            if v[i][6] and v[i][6] == 0 then
                return true
            end
        end
    end
    return false
end

function mapSceneUI:Roll_Query(load)
    local data = module.TeamModule.GetPubRewardData()
    local is_active = false
    for k,v in pairs(data)do
        is_active = true
    end
    self.view.mapSceneUIRoot.massage.PubReward:SetActive(is_active)
    if is_active == false and load then
        module.TeamModule.Roll_Query(2)--查询骰子是否有正在Roll
    end
end
function mapSceneUI:onEvent(event, ...)
    if event == "LOCAL_MAPSCENE_OPEN_TASKLIST" then
        DialogStack.PushPrefStact("mapSceneUI/item/taskList", nil, self.dialogRoot)
    elseif event == "LOCAL_NOTIFY_CLOSE_BOTTOMBAR" then
        --self.bottomBar:SetActive(false)
    elseif event == "LOCAL_MAPSCENE_OPEN_ACTIVITYINFO" then
        DialogStack.PushPrefStact("mapSceneUI/item/activityInfo", ..., self.dialogRoot)
    elseif event == "UIRoot_refresh" then
        local data = ...
        if not data.IsActive then
            -- self.view.mapSceneUIRoot:SetActive(true)
            -- self.bottomBar:SetActive(false)
            self:mapShowCanBack()
            DispatchEvent("LOCAL_MAPSCENE_UI_REFRESH")
        end

        if #DialogStack.GetStack() == 0 then
            local _guide = module.EncounterFightModule.GUIDE.GetInteractInfo()
            if _guide and _guide.name then
                module.EncounterFightModule.GUIDE.Interact(_guide.name)
            end
        end

        self:ChatRef()
        -- self:upTop()
        -- self.dirty = true;
        -- self:initGuide()
        self:upOpenLevelUi()
        self:initQuickToUseList()
        module.EquipHelp.ShowQuickToHero()
        module.HeroHelper.ShowRecommendedItem()
    elseif event == "LOCAL_MAPSCENE_PUSHSCENE" then
        local _data = ...
        if _data.gototype == 2 then
            self:pushActivityScene(_data.gotowhere)
        elseif _data.gototype == 1 then
            local _data = ...
            local _tab = {}
            _tab.npc_id = _data.npcId
            _tab.map_id = tonumber(_data.gotowhere)
            _tab.script = "guide/bounty/activityQuest.lua"
            module.QuestModule.StartQuestGuideScript(_tab, true)
        elseif _data.gototype == 3 then
            SceneStack.Push(_data.gotowhere, "view/".._data.gotowhere..".lua")
        elseif _data.gototype == 4 then
            SceneStack.EnterMap(tonumber(_data.gotowhere))
        else
            print("error", sprinttb(_data))
        end
    elseif event == "PLAYER_INFO_CHANGE" then
        local pid = ...
        if pid == module.playerModule.GetSelfID() then
            self.dirty = true;
            self:initGuide()
        end
    elseif event == "PLAYER_ADDDATA_CHANGE_SUCCED" then
        local pid = select(3, ...)
        if pid == module.playerModule.GetSelfID() then
            self.dirty = true;
        end
    elseif event == "Chat_INFO_CHANGE" or event == "PrivateChatData_CHANGE" or event == "Mail_Delete_Succeed" then
        self:upFriendChatRedDot()
        if event == "Chat_INFO_CHANGE" then
            self:ChatRef()
        end
    elseif event == "LOCAL_MAPSCENE_OPEN_CHATFRAME" then
        self:OpenDialog("NewChatFrame", ...)
    elseif event == "TEAM_PLAYER_REPLY_INVITATION_REQUEST" then
        -- self:INVITE_REF()
    elseif event == "MapSceneUI_Push" then
        local data = ...
        self:OpenDialog(data.name,data.data)
    -- elseif event == "TEAM_JOIN_REQUEST_CHANGE" or event == "JOIN_CONFIRM_REQUEST" or event == "delApply_succeed" then
    --     --队伍申请列表变化通知 or 审批玩家申请 or 拒绝玩家申请
    --     self:JoinRequestChange()
    elseif event == "TEAM_PLAYER_INVITE_LIST_CHANGE" then
        --查询邀请列表返回 or 邀请列表更新通知
        self:INVITE_REF()
    elseif event == "Map_Click_Player" then
        self:upOtherPlayeIcon(...)
    elseif event == "MAP_CHARACTER_DISAPPEAR" then
        self:upOtherPlayeIcon(nil)
    elseif event == "LOCAL_REDDOT_BAG_CHANE" then
        self:upBagRedDot()
    elseif event == "LOCAL_REDDOT_CLOSE" then
        self:upBagRedDot()
    elseif event == "Team_members_Request" then
        if self.IsApply then
            self.IsApply = false
            local data = ...
            --ERROR_LOG(data.upper_limit)
            if data.upper_limit == 0 or (module.playerModule.Get(module.playerModule.GetSelfID()).level >= data.lower_limit and  module.playerModule.Get(module.playerModule.GetSelfID()).level <= data.upper_limit) then
                module.TeamModule.JoinTeam(data.members[3])
            else
                showDlgError(nil,"你的等级不满足对方的要求")
            end
        end
    elseif event == "LOCLA_QUICKTOSUE_CHANE" then
        self:initQuickToUseList()
    elseif event == "PlayAudioSource" then
        local data = ...
        self.view[SGK.AudioSourceVolumeController]:Play("sound/"..data.playName)
    elseif event == "PlayAudioEffectSource" then
        local data = ...
        self.view[SGK.AudioSourceVolumeController]:Play("sound/"..data.playName)
    elseif event == "LOCLA_MAPSCENE_OPEN_OTHER" then
        local _data = ...
        self:OpenDialog(_data.name, _data.data)
    elseif event == "QUEST_INFO_CHANGE" then
        local npc_all = module.NPCModule.GetNPCALL()
        for k,v in pairs(npc_all) do
            localNpcStatus(v,k)
        end
        self.dirty = true;
        -- self:upTop()
        module.NPCModule.Ref_NPC_LuaCondition()
        -- self:initGuide()
        local data = ...
        if data ~= nil and data.cfg.cfg.type == 10 then
            self.Play_1200 = true
            -- if utils.SGKTools.Athome() and #DialogStack.GetStack() == 0 then
            --     --print("zoe本地任务改变调用1000引导",sprinttb(data)) 
            --     module.guideModule.PlayByType(1000, 0.1)
            -- end
            -- module.guideModule.PlayByType(1200)
        end
    elseif event == "AFTER_QUEST_INFO_CHANGE" then
            self:initGuide()
            if self.Play_1200 then
                if utils.SGKTools.Athome() and #DialogStack.GetStack() == 0 then 
                    module.guideModule.PlayByType(1000, 0.1)
                end
                ERROR_LOG("zoe本地任务改变调用1000引导") 
                module.guideModule.PlayByType(1200)
                self.Play_1200 = false
            end
    elseif event == "QUEST_FINISH" then
        local _obj = SGK.ResourcesManager.Load("prefabs/mapSceneUI/item/questFinishAn.prefab")
        local _item = UnityEngine.Object.Instantiate(_obj, self.dialogRoot.transform)
        local fun = ...
        SGK.Action.DelayTime.Create(2):OnComplete(function()
            fun()
            CS.UnityEngine.GameObject.Destroy(_item)
        end)
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
        if ... ~= nil then
            if utils.SGKTools.Athome() and #DialogStack.GetStack() == 0 then
                --print("zoe本地引导改变调用1000引导") 
                module.guideModule.PlayByType(1000)    
            end
        end
        -- SGK.Action.DelayTime.Create(0.5):OnComplete(function() 
        -- end)
        module.guideModule.PlayByType(1200)
    elseif event == "ONE_TIME_REWARD_INFO_CHANGE" then
        module.guideModule.PlayByType(1200)
    elseif event == "TeamCombatFinish" then
        self:StartCombat()
    elseif event == "LOCAL_NOTIFY_MAPSCENE_PUSH" then
        --self.bottomBar:SetActive(true)
        --self.view.mapSceneUIRoot:SetActive(false)
    elseif event == "LOCAL_NOTIFY_MAPSCENE_PUSH_ERROR" then
        --self.bottomBar:SetActive(false)
        --self.view.mapSceneUIRoot:SetActive(true)
    elseif event == "RECOMMENDED_ITEM_CHANGE" then
        if self.view.quickToHeroNode.transform.childCount > 0 then
            return
        end
        DialogStack.PushPref("mapSceneUI/item/quickToHeroItem", ..., self.view.quickToHeroNode)
    elseif event == "LOCLA_MAPSCENE_SHOW_QUICKTOHERO" then
        if self.view.quickToHeroNode.transform.childCount > 0 or not GetGetItemTipsState() then
            return
        end
        local _ic = module.EquipHelp.QuickToHero(...)
        if _ic then
            local _equip = module.equipmentModule.GetByUUID(_ic.newUuid)
            if _equip.heroid ~= 0 then
                return
            end
            if _ic.oldUuid then
                DialogStack.PushPref("mapSceneUI/item/quickToHeroChange", module.EquipHelp.QuickToHero(...), self.view.quickToHeroNode)
            else
                DialogStack.PushPref("mapSceneUI/item/quickToHero", module.EquipHelp.QuickToHero(...), self.view.quickToHeroNode)
            end
            module.EquipHelp.OpenFlag()
        end
    elseif event == "ITEM_INFO_CHANGE" then
        local _data = ...
        if _data then
            local _cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, _data.gid)
            if _cfg.sub_type == 21 then
                self:initGuide()
            end
        end
    elseif event == "PLAYER_LEVEL_UP" then
        if utils.SGKTools.Athome() and #DialogStack.GetStack() == 0 then
            --print("zoe角色升级调用1000引导") 
            module.guideModule.PlayByType(1000, 0.1)
        end
        module.guideModule.PlayByType(1200)
    elseif event == "Roll_Query_Respond" then
        self:Roll_Query()
    elseif event == "TEAM_QUERY_NPC_REWARD_REQUEST" then
        local data = ...
        self.view.mapSceneUIRoot.massage.ExtraSpoils:SetActive(#data.reward_content > 0)
    elseif event == "HeroCamera_DOOrthoSize" then
        local data = ...
        if not data then
            self:initMapBottom()
        end
        if data then
            self.view.guideLayerNode[UnityEngine.CanvasGroup].alpha = 0
            self.view.mapSceneUIRoot[UnityEngine.CanvasGroup].alpha = 0
            if utils.SGKTools.Athome() then
                self.view.dialogRoot[UnityEngine.CanvasGroup].alpha = 1
            elseif UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
                self.view.dialogRoot[UnityEngine.CanvasGroup].alpha = 1
            else
                self.view.dialogRoot[UnityEngine.CanvasGroup].alpha = 0
            end
        else
            self.view.guideLayerNode[UnityEngine.CanvasGroup].alpha = 1
            self.view.mapSceneUIRoot[UnityEngine.CanvasGroup].alpha = 1
            self.view.dialogRoot[UnityEngine.CanvasGroup].alpha = 1
        end
    -- elseif event == "Friend_INFO_Desc" then
    --     if ... then
    --         self.Friend_online[#self.Friend_online + 1] = ...
    --     end
    --     if #self.Friend_online > 0 and not self.view.mapSceneUIRoot.bottom.FriendTisp.activeSelf then
    --         self.view.mapSceneUIRoot.bottom.FriendTisp:SetActive(true)
    --         self.view.mapSceneUIRoot.bottom.FriendTisp.Text:TextFormat(self.Friend_online[1])
    --         SGK.Action.DelayTime.Create(0.1):OnComplete(function()
    --             self.view.mapSceneUIRoot.bottom.FriendTisp[UnityEngine.CanvasGroup].alpha = 1
    --             local x = self.view.mapSceneUIRoot.bottom.FriendTisp.Text[UnityEngine.RectTransform].sizeDelta.x + 30
    --             self.view.mapSceneUIRoot.bottom.FriendTisp[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(x,54)
    --         end)
    --         table.remove(self.Friend_online,1)
    --         self.view.mapSceneUIRoot.bottom.FriendTisp[UnityEngine.CanvasGroup]:DOFade(0, 1):SetDelay(2):OnComplete(function( ... )
    --             self.view.mapSceneUIRoot.bottom.FriendTisp:SetActive(false)
    --             DispatchEvent("Friend_INFO_Desc")
    --         end)
    --     end
    elseif event == "LOCAL_DIALOGSTACK_PUSHMID" then
        --self.view.CurrencyChat:SetActive(...)
    elseif event == "LOCAL_ANSWER_STATUS_CHANGE" then
        -- self.view.mapSceneUIRoot.massage.answer:SetActive(module.answerModule.GetTeamStatus())
    elseif event == "GiftBoxPre_to_FlyItem" then
        local x,y,z = self.view.mapSceneUIRoot.bottom.allBtn.bag.transform.position.x,self.view.mapSceneUIRoot.bottom.allBtn.bag.transform.position.y,self.view.mapSceneUIRoot.bottom.allBtn.bag.transform.position.z
        utils.SGKTools.FlyItem({x,y,z},...)
    elseif event == "LOCAL_ACHIEVEMENT_CHANGE" then
        -- ERROR_LOG(event,sprinttb(...));
        PopUpTipsQueue(8, ...)
    elseif event == "ENTER_PROTECT_BASE" then
        DialogStack.PushPref("mapSceneUI/ProtectBaseUI", nil, self.view.middleRoot.gameObject)
    elseif event == "GUILD_GRABWAR_START" then
        local side = ...;
        self.view.guideLayerNode.questListRoot:SetActive(side == 0);
        if side ~= 0 then
            self.view.mapSceneUIRoot.mapSceneTaskListRoot.recommend.guideRoot.taskTimeItem:SetActive(false)
        end
        DialogStack.PushPref("guildGrabWar/guildGrabWarUI", nil, self.view.guideLayerNode.gameObject)
    elseif event == "MANOR_SCENE_CHANGE" then
        local state,pid = ...;
        if state and pid ~= playerModule.GetSelfID() then
            self:UpManorInfo(pid)
            --DialogStack.PushPref("mapSceneUI/ManorSteal", {pid = pid}, self.view.mapSceneUIRoot.mapSceneTaskListRoot.gameObject);
        end
    elseif event == "NOTIFY_TEAM_ALL_CHANGE" then
        self:FreshMSG();
    elseif event == "MAP_OWNER_CHANGE" then
        self:checkCityGrab(true);
    elseif event == "MapSceneUI_Role_Icon" then
        self.view.mapSceneUIRoot.bottom.roleNode:SetActive(true)
    elseif event == "SystemMessageListRedDotChange" then
        self:upFriendChatRedDot()
    end
end

function mapSceneUI:initQuickToUseList()
    if not GetGetItemTipsState() then return end
    if self.view.quickToUseNode.transform.childCount <= 0 then
        for k,v in pairs(quickToUseModule.Get()) do
            local _item = ItemHelper.Get(ItemHelper.TYPE.ITEM, v.gid)
            if _item then
                --可快速使用 接任务的 道具 --多选礼包
                if _item.type_Cfg.quick_use and (_item.type_Cfg.quick_use == 3 or _item.type_Cfg.quick_use == 4) then
                    DialogStack.PushPref("mapSceneUI/item/quickToUse", {type = ItemHelper.TYPE.ITEM, id = v.gid}, self.view.quickToUseNode.transform)
                    return
                else
                    DialogStack.PushPref("mapSceneUI/item/quickToUseMax", {type = ItemHelper.TYPE.ITEM, id = v.gid}, self.view.quickToUseNode.transform)
                    return
                end
            end
        end
    end
end

function mapSceneUI:pushActivityScene(data)
    if data then
        DialogStack.Pop()
        self:OpenDialog(data)
    end
end

return mapSceneUI
