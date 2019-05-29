local HeroLevelup = require "hero.HeroLevelup"
local openLevel = require "config.openLevel"

local guideLayer = {}

function guideLayer:Start()
    self:initData()
    self:initUi()
    self.questList = module.QuestModule.GetConfigType(97)
    for i,v in ipairs(self.questList) do
        if v then
            module.QuestModule.Accept(v.id)
        end
    end
end

function guideLayer.title(view)
    local _quest = module.QuestModule.Get(module.guideLayerModule.Type.Title)
    if _quest.status == 1 then
        showDlgError(nil, "已领取")
    elseif module.QuestModule.CanSubmit(_quest.uuid) then
        view[CS.UGUIClickEventListener].interactable = false
        view[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        coroutine.resume(coroutine.create(function()
            module.QuestModule.Finish(_quest.uuid)
            view[CS.UGUIClickEventListener].interactable = true
            view[UI.Image].material = nil
        end))
    else
        showDlgError(nil, _quest.name)
    end
end

function guideLayer.getHero(view)
    local _quest = module.QuestModule.Get(module.guideLayerModule.Type.GetHero)
    if _quest.status == 1 then
        showDlgError(nil, "已领取")
    elseif module.QuestModule.CanSubmit(_quest.uuid) then
        view[CS.UGUIClickEventListener].interactable = false
        view[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        coroutine.resume(coroutine.create(function()
            module.QuestModule.Finish(_quest.uuid)
            -- ShowGetHeroSystemChat(_quest.reward_id1)
            -- utils.SGKTools.HeroShow(_quest.reward_id1)
            view[CS.UGUIClickEventListener].interactable = true
            view[UI.Image].material = nil
        end))
    else
        showDlgError(nil, _quest.name)
    end
end

function guideLayer.showGetHeroCheck()
    return module.HeroModule.GetManager():Get(11000).level >= 15
end

function guideLayer.levelUp(view)
    local _quest = module.QuestModule.Get(module.guideLayerModule.Type.LevelUp)
    if _quest.status == 1 then
        showDlgError(nil, "已领取")
    elseif module.QuestModule.CanSubmit(_quest.uuid) then
        view[CS.UGUIClickEventListener].interactable = false
        view[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        coroutine.resume(coroutine.create(function()
            module.QuestModule.Finish(_quest.uuid)
            view[CS.UGUIClickEventListener].interactable = true
            view[UI.Image].material = nil
        end))
    else
        showDlgError(nil, _quest.name)
    end
end

function guideLayer:getLevelTime()
    local _quest = module.QuestModule.Get(module.guideLayerModule.Type.LevelUp)
    local _time = module.playerModule.Get().loginTime
    if _quest.records[1] == 0 then
        _time = _quest.accept_time
    end
    return (_time + (_quest.condition[1].count - _quest.records[1])), _quest.condition[1].count
end

function guideLayer:getLastQuestTime()
    for i,p in ipairs(self.questList) do
        local v = module.QuestModule.Get(p.id)
        if v and v.status == 0 and not module.QuestModule.CanSubmit(v.id) then
            if self.lastQuest == v then
                return self.recordLastTime, v.condition[1].count
            else
                local _time = module.playerModule.Get().loginTime
                if v.records[1] == 0 then
                    _time = v.accept_time
                end
                if self.ScrollView and self.lastQuest ~= nil then
                    self.ScrollView:ItemRef()
                end
                self.lastQuest = v
                self.recordLastTime = (_time + (v.condition[1].count - v.records[1]))
                return self.recordLastTime, v.condition[1].count
            end
        end
    end
end

function guideLayer:Update()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad);
    if self.last_update_time == now then
        return;
    end
    self.last_update_time = now;

    if self.view.root.top["item"..3] and self.view.root.top["item"..3].activeSelf and self.view.root.top["item"..3].name.activeSelf then
        local _time, _condition = self:getLastQuestTime()
        if _time then
            local _time_ = (_condition - _time + module.Time.now()) / _condition
            self.view.root.top["item"..3].icon[UI.Image].fillAmount = _time_
            self.view.root.top["item"..3].name[UI.Text].text = GetTimeFormat(_time - module.Time.now(), 2, 2)
        else
            --self.view.root.top["item"..3].icon[UI.Image].fillAmount = 1
            self.view.root.top["item"..3].name:SetActive(false)
            self.view.root.top["item"..3].textInfo:SetActive(true)
        end
        local _status = false
        for i,v in ipairs(self.questList) do
            if module.QuestModule.Get(v.id) then
                _status = true
                break
            end
        end
        self.view.root.top["item"..3].tip:SetActive(not (_time and true) or _status)
    end
    if self.view.root.top["item"..5] and self.view.root.top["item"..5].text.activeSelf then
        local _quest = module.QuestModule.Get(module.guideLayerModule.Type.LevelUp)
        if not _quest then
            self.view.root.top["item"..5]:SetActive(false)
            return
        end
        local _questTime, _condition = self:getLevelTime()
        local _time = _questTime - module.Time.now()
        if _time > 0 then
            self.view.root.top["item"..5].text[UI.Text].text = GetTimeFormat(_time, 2, 2).."可领"
            self.view.root.top["item"..5].icon[UI.Image].fillAmount = (_condition - _time) / _condition
        else
            self.view.root.top["item"..5].text:SetActive(false)
            self.view.root.top["item"..5].name:SetActive(true)
            module.QuestModule.Finish(module.guideLayerModule.Type.LevelUp)
        end
    end
end

function guideLayer.checkLevelUp()
    local _count = module.ItemModule.GetItemCount(90032)
    return _count > 0
end

function guideLayer.goLevelUp(view)
    view[CS.UGUIClickEventListener].interactable = false
    view[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
    coroutine.resume(coroutine.create(function()
        if module.ShopModule.Buy(1080002, 8, 1) then
            local hero = module.HeroModule.GetManager():Get(11000)
            local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
            local Level_exp = hero_level_up_config[hero.level]
            local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1] or hero_level_up_config[hero.level]
            utils.NetworkService.SyncRequest(29,{nil, 0, 90, 90000, Next_hero_level_up - Level_exp})
            guideLayer:upUi()
        end
        view[CS.UGUIClickEventListener].interactable = true
        view[UI.Image].material = nil
    end))
end

function guideLayer.checkOnline()
    local _first = module.QuestModule.Get(module.guideLayerModule.Type.OnlineRewardFirst)
    local _end = module.QuestModule.Get(module.guideLayerModule.Type.OnlineReward)
    for i = module.guideLayerModule.Type.OnlineRewardFirst, module.guideLayerModule.Type.OnlineReward do
        local _quest = module.QuestModule.Get(i)
        if _quest and _quest.status == 0 then
            return true
        end
    end
    return false
end

function guideLayer:sevenDays()
    return module.QuestModule.GetSevenDayOpen() and openLevel.GetStatus(1311)
end

function guideLayer.checkFunc()
    return false
end

function guideLayer:initData()
    self.topDialog = {
        [1] = {dialog = "mapSceneUI/guideLayer/guideGetHero", openLevel = 9999, checkFunc = self.checkFunc},
        [2] = {dialog = "mapSceneUI/guideLayer/guideFashion", openLevel = 9999, checkFunc = self.checkFunc},
        [3] = {dialog = "mapSceneUI/guideLayer/guideOnlineRewards", checkFunc = self.checkOnline, openLevel = 5007},
        [4] = {dialog = "mapSceneUI/guideLayer/guideGetTitle", openLevel = 9999, checkFunc = self.checkFunc},
        [5] = {dialog = "mapSceneUI/guideLayer/guideShaar", openLevel = 9999, checkFunc = self.checkFunc},
        [6] = {dialog = "mapSceneUI/guideLayer/guideShaar", openLevel = 9999, checkFunc = self.checkFunc},
        [7] = {dialog = "SevenDaysActivity", openLevel = 9999, checkFunc = self.checkFunc},
        [8] = {dialog = "Trade_Dialog", openLevel = 9999, checkFunc = self.checkFunc},
        [9] = {dialog = "rankList/rankListFrame", openLevel = 9999, checkFunc = self.checkFunc},
        [10] = {dialog = "mapSceneUI/guideLayer/zeroPlan", openLevel = 9999, checkFunc = self.checkFunc},
        [11] = {dialog = "dataBox/DataBox", openLevel = 9999, checkFunc = self.checkFunc},
        -- [11] = {dialog = "dataBox/StoryReview", openLevel = 9999},
    }
end

function guideLayer:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initRight()
    self:upUi()
end

function guideLayer:initTop()
    for i = 1, #self.view.root.top do
        local _view = self.view.root.top["item"..i]

        if i == 4 then
            _view:SetActive(false);
        end

        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if self.topDialog[i].dialog then
                DialogStack.Push(self.topDialog[i].dialog, self.topDialog[i].checkId)
            elseif self.topDialog[i].func then
                self.topDialog[i].func(_view)
            end
        end
    end
end

function guideLayer:getFashionCount()
    local cfg = module.guideLayerModule.GetFashionCfg()
    local _count = 0
    -- if not cfg then
    --     return 0, 0
    -- end
    for i = 1, (#cfg.conditions - 1) do
        local _quest = module.QuestModule.Get(cfg.conditions[i])
        if _quest and _quest.status == 1 then
            _count = _count + 1
        end
    end
    return _count, (#cfg.conditions - 1)
end

function guideLayer:getTitleCount()
    local _quest = module.QuestModule.Get(module.guideLayerModule.Type.Title)
    if _quest then
        local _have = module.ItemModule.GetItemCount(_quest.consume[1].id)
        return _have, _quest.consume[1].value
    end
    return 0, 0
end

function guideLayer:upTop()
    for i = 1, #self.view.root.top do
        local _view = self.view.root.top["item"..i]
        local _checkFunc = self.topDialog[i].checkFunc or true
        if self.topDialog[i].checkFunc then
            _checkFunc = self.topDialog[i].checkFunc()
        end
        module.RedDotModule.PlayRedAnim(_view.tip)

        local _open = function(_quest_)
            local _time = (_quest_.end_time - 1) * 86400
            local _off = (module.playerModule.Get().create_time + _time) - module.Time.now()
            return _off > 0
        end

        if self.topDialog[i].checkId and _checkFunc then
            local _quest = module.QuestModule.Get(self.topDialog[i].checkId)
            if _view.icon.activeSelf then
                if i == 2 then
                    local _finish, _count = self:getFashionCount()
                    _view.icon[UI.Image].fillAmount = _finish / _count
                elseif i == 4 then
                    local _finish, _count =  self:getTitleCount()
                    _view.icon[UI.Image].fillAmount = _finish / _count
                end
            end
            if i == 1 and _quest then
                if module.QuestModule.CanSubmit(_quest.id) then
                    _view.name[UI.Text]:TextFormat("<color=#E28B41>{0}</color>级可领", _quest.event_count1)
                    _view.tip:SetActive(true)
                else
                    _view.name[UI.Text]:TextFormat("<color=#E33737>{0}</color>级可领", _quest.event_count1)
                    _view.tip:SetActive(false)
                end

            end
            _view:SetActive(_quest and _quest.status == 0 and _open(_quest) and i ~= 4)
        elseif self.topDialog[i].checkId == nil and _checkFunc then
            _view:SetActive(true)
            if self.topDialog[i].openLevel then
                if not openLevel.GetStatus(self.topDialog[i].openLevel) then
                    _view:SetActive(false)
                end
            end
        else
            _view:SetActive(false)
        end
        if self.topDialog[i].red then
            _view.red:SetActive(module.RedDotModule.GetStatus(self.topDialog[i].red))
        end
    end
end

function guideLayer:initRight()
    self.story = self.view.root.right.story
    self.equip = self.view.root.right.equip
    CS.UGUIClickEventListener.Get(self.story.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/guideLayer/guideCommon", self.stroyCfg.id)
    end
end

function guideLayer:upRightBottom()
    local _stroyCfg = module.guideLayerModule.GetQuest(module.guideLayerModule.Type.Trailer)
    self.view.root.rightBottom.item1:SetActive(_stroyCfg and true)
    if self.view.root.rightBottom.item1.activeSelf then
        self.view.root.rightBottom.item1.desc[UI.Text].text = _stroyCfg.name
        if _stroyCfg.icon ~= 0 then
            self.view.root.rightBottom.item1.icon[UI.Image]:LoadSprite("guideLayer/".._stroyCfg.icon)
            self.view.root.rightBottom.item1.icon:SetActive(true);
        else
            self.view.root.rightBottom.item1.icon:SetActive(false);
        end
        CS.UGUIClickEventListener.Get(self.view.root.rightBottom.item1.gameObject).onClick = function()
            DialogStack.Push("mapSceneUI/guideLayer/guideInfo", {questId = _stroyCfg.id})
        end
    end
    --self.view.root.rightBottom.item1:SetActive(false)
end

function guideLayer:upUi()
    self:upTop()
    self:upRight()
    self:upRightBottom()
end

function guideLayer:upRight()
    self.stroyCfg = module.guideLayerModule.GetQuest(module.guideLayerModule.Type.Story)
    self.story:SetActive(self.stroyCfg ~= nil)
end

function guideLayer:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "PLAYER_LEVEL_UP",
    }
end

function guideLayer:OnEnable()
    self:upUi()
end

function guideLayer:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" or event == "PLAYER_LEVEL_UP" then
        self:upUi()
    end
end


return guideLayer
