local unionConfig = require "config.unionConfig"
local ItemHelper = require"utils.ItemHelper"
local activityModule = require "module.unionActivityModule"

local newUnionExploreMapInfo = {}

function newUnionExploreMapInfo:initData(data)
    self.selectIdx = data
end

function newUnionExploreMapInfo:upData()
    self.allMapCfg = unionConfig.GetAllExploremapMessage()

    -- ERROR_LOG(self.selectIdx)
    self.mapId = self.allMapCfg[self.selectIdx].mapId
    self.cfg = unionConfig.GetExploremapMessage(self.mapId)

    -- ERROR_LOG(sprinttb(self.cfg));
    self.mapInfo = activityModule.ExploreManage:GetMapInfo(self.mapId)
end

function newUnionExploreMapInfo:getBIT(tab)
    local _tab = {}
    for k,v in pairs(tab) do
        if v ~= 0 then
            table.insert(_tab, k)
        end
    end
    return _tab
end

local property = {
    "水","火","土","气","光","暗"
}

function newUnionExploreMapInfo:initTop()
    --self.view.newUnionExploreMapInfoRoot.bg.mapName[UI.Text].text = self.cfg.name
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreMapInfoRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end

    self.yuansuTab = self:getBIT(BIT(self.mapInfo.property))
    self.mapScrollView = self.view.newUnionExploreMapInfoRoot.top.map[CS.UIMultiScroller]
    self.mapScrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _cfgId = self.yuansuTab[idx+1]
        _view.icon[UI.Image]:LoadSprite("propertyIcon/yuansu"..(_cfgId -1))

        _view.Text[UI.Text].text = property[_cfgId-1].."系";
        obj:SetActive(true)
    end
    self.mapScrollView.DataCount = #self.yuansuTab
end

function newUnionExploreMapInfo:initMiddle()
    self.view.newUnionExploreMapInfoRoot.middle.doc[UI.Text].text = self.cfg.mapDes
end

function newUnionExploreMapInfo:initBottom()
    self.ScrollView = self.view.newUnionExploreMapInfoRoot.bottom.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.cfg.reward[idx+1]
        --local _item = ItemHelper.Get(_tab.type, _tab.id, nil, _tab.valude)
        
        
        local icon =utils.IconFrameHelper.Create(_view, {id = _tab.id, type = _tab.type, showDetail = true, count = _tab.valude,func = function ( prefab )
            _view.flag:SetActive(idx == 0);
            _view.flag.transform:SetAsLastSibling();

        end})
        icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
        --_view[SGK.newItemIcon]:SetInfo(_item)
        --_view[SGK.newItemIcon].showDetail = true
        obj:SetActive(true)
    end
    self.ScrollView.DataCount = #self.cfg.reward
end

function newUnionExploreMapInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initMiddle()
    self:initBottom()
end

function newUnionExploreMapInfo:upUi()
    self.yuansuTab = self:getBIT(BIT(self.mapInfo.property))
    self.mapScrollView.DataCount = #self.yuansuTab
    self.ScrollView.DataCount = #self.cfg.reward
    self.allMapScrollView:ItemRef()
    self:initMiddle()
end

function newUnionExploreMapInfo:Start(data)
    self:initData(data)
    self:upData()
    self:initUi()
end

return newUnionExploreMapInfo
