local achievementModule = require "module.AchievementModule"
local newAchievementAll = {}

function newAchievementAll:Start()
    self:initData()
    self:initUi()
end

function newAchievementAll:initData()
    self.scrollBarList = {}
    self:initRecentData()
end

function newAchievementAll:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initDropdown()
    self:initRecent()
    self:initAllAchievement()
end

function newAchievementAll:initDropdown()
    self.view.root.dropdown[SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue("chengjiu_01"))
    self.view.root.dropdown[SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue("chengjiu_02"))
    self.view.root.dropdown.Label[UI.Text].text = SGK.Localize:getInstance():getValue("chengjiu_01")
    self.view.root.dropdown[UI.Dropdown].onValueChanged:AddListener(function (i)
        for j = 2, #self.view.root.child do
            self.view.root.child[j]:SetActive((j - 1) == i)
        end
    end)
    self.view.root.dropdown[UI.Dropdown].value = 1;
end

function newAchievementAll:initRecentData()
    local recentQuestList = module.QuestModule.GetList(31)
    
    self.recentQuestList = {};
    local notContians = {};
    for i=1,#recentQuestList do
        local ret =  module.achievementModule.GetCfg(recentQuestList[i].id);
        if ret then

            if recentQuestList[i].status == 1 or module.QuestModule.CanSubmit(recentQuestList[i].id) then
                table.insert( self.recentQuestList, recentQuestList[i] )
            end
        end
    end

    table.sort(self.recentQuestList, function(a, b)
        if b.finish_time == a.finish_time then
            return a.id > b.id
        else
            return a.finish_time > b.finish_time
        end
    end)

    -- ERROR_LOG("==============>>>>",sprinttb(self.recentQuestList));
end

function newAchievementAll:upAchievement()
    local _finishCount = 0
    local _maxCount = 0
    for i,_view in pairs(self.scrollBarList) do
        _view.ExpBar[UI.Scrollbar].size = achievementModule.GetFinishCount(i) / #achievementModule.GetCfg(nil, i)
        _view.ExpBar.number[UI.Text].text = achievementModule.GetFinishCount(i).."/"..#achievementModule.GetCfg(nil, i)
        _finishCount = _finishCount + achievementModule.GetFinishCount(i)
        _maxCount = _maxCount + #achievementModule.GetCfg(nil, i)
    end
    self.view.root.child.item2.ExpBar.number[UI.Text].text = _finishCount.."/".._maxCount
    self.view.root.child.item2.ExpBar[UI.Scrollbar].size = _finishCount / _maxCount
end

function newAchievementAll:OnEnable()
    self:upUi()
end

function newAchievementAll:initAllAchievement()
    local _item = self.view.root.child.item2.ScrollView.Viewport.Content.item.gameObject
    local _content = self.view.root.child.item2.ScrollView.Viewport.Content.transform
    for i,v in pairs(achievementModule.GetFistCfg()) do
        local _obj = CS.UnityEngine.GameObject.Instantiate(_item, _content)
        local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
        _view.name[UI.Text].text = v.name
        self.scrollBarList[i] = _view
        _obj:SetActive(true)
    end
    self:upAchievement()
end

function newAchievementAll:initRecent()
    self.view.root.child.item1.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.recentQuestList[idx + 1]
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.desc[UI.Text].text = _cfg.button_des
        -- ERROR_LOG(_cfg.id);

        local rewardCfg = module.achievementModule.GetCfg(_cfg.id);

        
        _view.root.time[UI.Text].text = os.date(SGK.Localize:getInstance():getValue("chengjiu_03"), _cfg.finish_time)
        -- ERROR_LOG("时间",rewardCfg.reward_quest_id);
        local isRed = module.QuestModule.CanSubmit(tonumber(rewardCfg.reward_quest_id));
        -- local  = 1
        -- ERROR_LOG(isRed);
        
        -- ERROR_LOG(sprinttb(_cfg));
        
        local _reward_cfg = module.QuestModule.Get(rewardCfg.reward_quest_id);
        _view.root.bg[CS.UGUISpriteSelector].index = (not _reward_cfg or _reward_cfg.status ~= 1) and 0 or 1
        _view.root.getBtn:SetActive(not _reward_cfg or _reward_cfg.status ~= 1)
        _view.root.time:SetActive(_reward_cfg and _reward_cfg.status == 1)
        _view.root.bg.tishi:SetActive(isRed)
        -- utils.IconFrameHelper.Create(_view.root.icon, {customCfg = {
        --         icon    = _cfg.icon,
        --         quality = 0,
        --         star    = 0,
        --         level   = 0,
        -- }, type = 42})
        local _material = nil
        if not _view.root.bg.tishi.activeSelf then
            _material = SGK.QualityConfig.GetInstance().grayMaterial
        end
        _view.root.getBtn[UI.Image].material = _material
        local _record = module.QuestModule.GetOtherRecords(_cfg, 1)
        local _conditionValue = _cfg.condition[1].count

        -- ERROR_LOG(_record,_conditionValue);
        _view.root.bg.ExpBar[UI.Scrollbar].size = _record / _conditionValue

        _view.root.bg.ExpBar.number[UI.Text].text = (_record >_conditionValue and _conditionValue or _record).. "/".. _conditionValue
        

        for i=1,2 do
            local _rView = _view.root.rewardList["reward"..i];
            local _rCfg = _reward_cfg and _reward_cfg.reward[i];
            if _rCfg then
                utils.IconFrameHelper.Create(_rView, {id = _rCfg.id, type = _rCfg.type, showDetail = true, count = _rCfg.value,func=function(IconItem)
                -- IconItem.LowerRightText.transform.localScale = Vector3.one*1.2
            end})
            end
            _rView:SetActive(_rCfg)
        end
        _view.root.rewardList:SetActive(not _reward_cfg or _reward_cfg.status~=1)
        CS.UGUIClickEventListener.Get(_view.root.getBtn.gameObject).onClick = function()
            if _view.root.bg.tishi.activeSelf then
                _view.root.getBtn[CS.UGUIClickEventListener].interactable = false
                _view.root.getBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                coroutine.resume(coroutine.create(function()
                    module.QuestModule.Finish(_reward_cfg.id)
                    _view.root.getBtn[CS.UGUIClickEventListener].interactable = true
                    _view.root.getBtn[UI.Image].material = nil
                end))
            end
        end

        obj:SetActive(true)
    end

    self.view.root.child.item1.ScrollView[CS.UIMultiScroller].DataCount = (#self.recentQuestList > 5 and 5 or #self.recentQuestList)
end

function newAchievementAll:upUi()
    self:upAchievement()
    self:initRecentData()
    self.view.root.child.item1.ScrollView[CS.UIMultiScroller].DataCount = (#self.recentQuestList > 5 and 5 or #self.recentQuestList)
end

function newAchievementAll:Update( ... )
    if self.freshCallBack then
        self.freshCallBack();
        self.freshCallBack = nil
    end
end

function newAchievementAll:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newAchievementAll:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.type == 31 or data.type == 30 then
            self.freshCallBack = function ( ... )
                self:upUi()
            end
        end
    end
end

return newAchievementAll
