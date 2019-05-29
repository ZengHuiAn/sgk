local strongerModule = require "module.strongerModule"
local openLevel = require "config.openLevel"
local GuideHelper = require "utils.GuideHelper"
local newStrongerUp = {}

function newStrongerUp:Start()
    self:initData()
    self:initUi()
end

function newStrongerUp:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initLevelScope()
end

function newStrongerUp:initData()
    self.idx = strongerModule.StrongerUpArg.idx or 1
end

function newStrongerUp:initLevelScope()
    local _expList = strongerModule.GetExpectation(999)
    for i,v in ipairs(_expList) do
        if v.lv_min <= module.HeroModule.GetManager():Get(11000).level and v.lv_max >= module.HeroModule.GetManager():Get(11000).level then
            --self.view.top.levelInfo[UI.Text].text = SGK.Localize:getInstance():getValue("bianqiang_02", v.lv_min, v.lv_max)
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
            self.view.top.levelInfo[UI.Text].text = SGK.Localize:getInstance():getValue("当前战力：".._fighting)
            

            local _exp = module.HeroModule.GetManager():GetCapacity() / v.expectation
            local _idx = 0
            if _exp >= 1 or _exp >= 0.8 then
                _idx = 2
            elseif _exp >= 0.5 or _exp >= 0.799 then
                _idx = 1
            else
                _idx = 0
            end
            self.view.top.icon[CS.UGUISpriteSelector].index = _idx
            return
        end
    end
    self.view.top.levelInfo[UI.Text].text = ""
end

function newStrongerUp:getHeroList()
    local _heroList = module.HeroModule.GetManager():GetFormation()
    local _list = {}
    for i,v in ipairs(_heroList) do
        if v ~= 0 then
            table.insert(_list, v)
        end
    end
    return _list
end

local openLevelList = {
    [1] = 1701,
    [2] = 1702,
    [3] = 1703,
    [4] = 1704,
    [5] = 1705,
}

function newStrongerUp:upMiddleUi()
    local _cfg = strongerModule.GetTitleList()[self.idx]
    local _middleCfg_ = strongerModule.GetClassify(_cfg.title)
    local _middleCfg = {}
    local _middleExpCfg = {}

    for i,p in ipairs(_middleCfg_) do
        local _expCfgList = strongerModule.GetExpectation(p.id)
        if _expCfgList then
            for i,v in ipairs(_expCfgList) do
                if v.lv_min <= module.HeroModule.GetManager():Get(11000).level and v.lv_max >= module.HeroModule.GetManager():Get(11000).level then
                    table.insert(_middleExpCfg, v)
                    table.insert(_middleCfg, p)
                    break
                end
            end
        end
    end
    if #_middleCfg < self.view.ScrollView.Viewport.Content.transform.childCount then
        for i=#_middleCfg,self.view.ScrollView.Viewport.Content.transform.childCount do
            self.view.ScrollView.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
        end
    end

    for i = 1, #_middleCfg do
        local _obj = utils.SGKTools.GetCopyUIItem(self.view.ScrollView.Viewport.Content,self.view.ScrollView.Viewport.item,i)
        local _item = CS.SGK.UIReference.Setup(_obj.gameObject)

        _item.topFomation:SetActive(_middleCfg[i].is_root == 1)
        _item.topSingle:SetActive(_middleCfg[i].is_root == 2)

        local _heroListCfg = strongerModule.GetCfg(_middleCfg[i].title, _middleCfg[i].classify)
        local _heroList = self:getHeroList()

        _item[UI.VerticalLayoutGroup].padding.top = _middleCfg[i].is_root == 1 and 238 or 195
        _item.arrow:SetActive(#_heroListCfg>0)
        if _middleCfg[i].is_root == 1 then
            local _view = _item.topFomation
            _view.name[UI.Text].text = _middleCfg[i].classify_name
            
            for j = 1, #_heroListCfg do
                local _groupItem = _item.Group.item.transform
                local _itemObj = CS.UnityEngine.GameObject.Instantiate(_groupItem, _item.Group.transform)
                local _itemView = CS.SGK.UIReference.Setup(_itemObj.gameObject)
                _itemView.name[UI.Text].text = _heroListCfg[j].classify_name
                _itemView.desc[UI.Text].text = _heroListCfg[j].desc
                _itemView.icon[UI.Image]:LoadSprite("guideLayer/".._heroListCfg[j].icon)
                _itemObj.gameObject:SetActive(true)
                CS.UGUIClickEventListener.Get(_itemView.gameObject).onClick = function()
                    GuideHelper.Go(_heroListCfg[j].guide,_heroListCfg[j].guideValue)
                end
            end
            local _heroExp = 0
            for j = 1, #_view.hero do
                local _heroView = _view.hero[j]
                _heroView.lock:SetActive(_heroList[j] == nil)
                _heroView.lock:SetActive(_heroList[j] == nil)
                _heroView.IconFrame:SetActive(_heroList[j] and true)
                _heroView.lockNode:SetActive(not openLevel.GetStatus(openLevelList[j]))
                _heroView.lockNode.Text[UI.Text].text = openLevel.GetCloseInfo(openLevelList[j])
                if _heroView.IconFrame.activeSelf then
                    local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _heroList[j])
                    _heroView.IconFrame.name[UI.Text].text = _heroCfg.name
                    utils.IconFrameHelper.Create(_heroView.IconFrame, {type = utils.ItemHelper.TYPE.HERO, uuid = _heroCfg.uuid})
                    local _exp = strongerModule.GetHeroExp(_heroList[j], _middleCfg[i].id)
                    _heroExp = _heroExp + _exp
                    _heroView.IconFrame.number[UI.Text].text = math.floor(_exp + 0.5).."%"
                end
                CS.UGUIClickEventListener.Get(_heroView.gameObject).onClick = function()
                    if _heroView.lockNode.activeSelf then
                        return
                    end
                    if _heroView.IconFrame.activeSelf then
                        GuideHelper.Go(_middleCfg[i].guide,_heroList[j])
                    else
                        DialogStack.Push("FormationDialog")
                    end
                end
            end

            _view.ExpBar.number[UI.Text].text = math.floor((_heroExp / _middleExpCfg[i].formation_count) + 0.5).."%"
            _view.ExpBar[UI.Scrollbar].size = _heroExp / (_middleExpCfg[i].formation_count * 100)
            -- CS.UGUIClickEventListener.Get(_view.upBtn.gameObject).onClick = function()
            --     -- _func({cfg = _middleCfg[i]})
            --     GuideHelper.Go(_middleCfg[i].guide,_middleCfg[i].guideValue)
            -- end
            -- _view.top.name[UI.Text].text = _middleCfg[i].classify_name
            -- local _heroList = self:getHeroList()
            -- local _heroListCfg = strongerModule.GetCfg(_middleCfg[i].title, _middleCfg[i].classify)

            -- _view.arrow:SetActive(#_heroListCfg>0)
            -- for j = 1, #_heroListCfg do
            --     ERROR_LOG( #_heroListCfg,_middleCfg[i].title, _middleCfg[i].classify,sprinttb( _heroListCfg[j]))
            --     local _groupItem = _view.Group.item.transform
            --     local _itemObj = CS.UnityEngine.GameObject.Instantiate(_groupItem, _view.Group.transform)
            --     local _itemView = CS.SGK.UIReference.Setup(_itemObj.gameObject)
            --     _itemView.name[UI.Text].text = _heroListCfg[j].classify_name
            --     _itemView.desc[UI.Text].text = _heroListCfg[j].desc
            --     _itemView.icon[UI.Image]:LoadSprite("guideLayer/".._heroListCfg[j].icon)
            --     _itemObj.gameObject:SetActive(true)
            --     CS.UGUIClickEventListener.Get(_itemView.gameObject).onClick = function()
            --         GuideHelper.Go(_heroListCfg[j].guide,_heroListCfg[j].guideValue)
            --     end
            -- end
            -- local _heroExp = 0
            -- for j = 1, #_view.top.hero do
            --     local _heroView = _view.top.hero[j]
            --     _heroView.lock:SetActive(_heroList[j] == nil)
            --     _heroView.lock:SetActive(_heroList[j] == nil)
            --     _heroView.IconFrame:SetActive(_heroList[j] and true)
            --     _heroView.lockNode:SetActive(not openLevel.GetStatus(openLevelList[j]))
            --     _heroView.lockNode.Text[UI.Text].text = openLevel.GetCloseInfo(openLevelList[j])
            --     if _heroView.IconFrame.activeSelf then
            --         local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _heroList[j])
            --         _heroView.IconFrame.name[UI.Text].text = _heroCfg.name
            --         utils.IconFrameHelper.Create(_heroView.IconFrame, {type = utils.ItemHelper.TYPE.HERO, uuid = _heroCfg.uuid})
            --         local _exp = strongerModule.GetHeroExp(_heroList[j], _middleCfg[i].id)
            --         _heroExp = _heroExp + _exp
            --         _heroView.IconFrame.number[UI.Text].text = math.floor(_exp + 0.5).."%"
            --     end
            --     CS.UGUIClickEventListener.Get(_heroView.gameObject).onClick = function()
            --         if _heroView.lockNode.activeSelf then
            --             return
            --         end
            --         if _heroView.IconFrame.activeSelf then
            --             -- _func({cfg = _middleCfg[i], heroId = _heroList[j]})
            --             GuideHelper.Go(_middleCfg[i].guide,_heroList[j])
            --         else
            --             DialogStack.Push("FormationDialog")
            --         end
            --     end
            -- end
            -- _view.top.ExpBar.number[UI.Text].text = math.floor((_heroExp / _middleExpCfg[i].formation_count) + 0.5).."%"
            -- _view.top.ExpBar[UI.Scrollbar].size = _heroExp / (_middleExpCfg[i].formation_count * 100)
            -- CS.UGUIClickEventListener.Get(_view.top.upBtn.gameObject).onClick = function()
            --     -- _func({cfg = _middleCfg[i]})
            --     ERROR_LOG("_middleCfg[i].guide,_middleCfg[i].guideValue",_middleCfg[i].guide,_middleCfg[i].guideValue)
            --     GuideHelper.Go(_middleCfg[i].guide,_middleCfg[i].guideValue)
            -- end
                _item.arrow.transform.localScale = Vector3(_item.Group.activeSelf and 1 or -1,1,1)
                CS.UGUIClickEventListener.Get(_item.gameObject).onClick = function()
                    if #_heroListCfg>0 then
                        _item.arrow.transform.localScale = Vector3(_item.Group.activeSelf and -1 or 1,1,1)
                        _item.Group:SetActive(not _item.Group.activeSelf)
                    end
                end
        else
            local _view = _item.topSingle
            _view.name[UI.Text].text = _middleCfg[i].classify_name

            local _heroExp = 0
            for j = 1, #_heroList do
                local _exp = strongerModule.GetHeroExp(_heroList[j], _middleCfg[i].id)
                _heroExp = _heroExp + _exp
            end

            _view.desc[UI.Text].text = _middleCfg[i].desc

            _view.ExpBar.number[UI.Text].text = math.floor((_heroExp / _middleExpCfg[i].formation_count) + 0.5).."%"
            _view.ExpBar[UI.Scrollbar].size = _heroExp / (_middleExpCfg[i].formation_count * 100)

            CS.UGUIClickEventListener.Get(_item.gameObject).onClick = function()
                GuideHelper.Go(_middleCfg[i].guide,_middleCfg[i].guideValue)
            end
        end
        _obj.gameObject:SetActive(true)
    end
end

function newStrongerUp:initTop()
    self.view.top.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = strongerModule.GetTitleList()[idx + 1]
        _view.Toggle.Background.Label[UI.Text].text = _cfg.title_name
        _view.Toggle[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
            if not value then
                _view.Toggle.Background.Label[UI.Text].color = {r = 1, b = 1, g = 1, a = 1}
            else
                _view.Toggle.Background.Label[UI.Text].color = {r = 0, b = 0, g = 0, a = 1}
            end
        end)
        CS.UGUIClickEventListener.Get(_view.Toggle.gameObject).onClick = function()
            self.idx = idx + 1
            strongerModule.StrongerUpArg.idx = self.idx
            self:upMiddleUi()
        end
        obj:SetActive(true)
    end
    self.view.top.ScrollView[CS.UIMultiScroller].DataCount = #strongerModule.GetTitleList()
    local _obj = self.view.top.ScrollView[CS.UIMultiScroller]:GetItem(self.idx - 1)
    if _obj then
        local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
        _view.Toggle[UI.Toggle].isOn = true
        _view.Toggle.Background.Label[UI.Text].color = {r = 0, b = 0, g = 0, a = 1}
    end
    self:upMiddleUi()
end

function newStrongerUp:listEvent()
    return {
        "LOCAL_PLACEHOLDER_CHANGE",
    }
end

function newStrongerUp:onEvent(event, data)
    if event == "LOCAL_PLACEHOLDER_CHANGE" then
        self:upMiddleUi()
    end
end


return newStrongerUp
