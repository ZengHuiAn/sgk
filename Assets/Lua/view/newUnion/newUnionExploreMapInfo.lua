local unionConfig = require "config.unionConfig"
local ItemHelper = require"utils.ItemHelper"
local activityModule = require "module.unionActivityModule"

local newUnionExploreMapInfo = {}

function newUnionExploreMapInfo:initAllMapUi()
    self.allMapScrollView = self.view.newUnionExploreMapInfoRoot.top.ScrollView[CS.UIMultiScroller]
    self.allMapScrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj).map
        local _tab = self.allMapCfg[idx+1]
        _view.icon[UI.Image]:LoadSprite("guanqia/".._tab.picture)
        _view.lock.Text[UI.Text].text=_tab.techlevel
        _view.lock:SetActive(_tab.teamLevel > module.unionModule.Manage:GetSelfUnion().unionLevel)
        local _nameLock = ""
        if _view.lock.activeSelf then
            _nameLock = "(Lv<color=#FF0000>".._tab.teamLevel.."</color>)"
        end
        _view.checkMark:SetActive(self.selectIdx == (idx + 1))
        _view.name[UI.Text].text = _tab.name.._nameLock

        -- checkMark
        local scienlev = module.unionScienceModule.GetScienceInfo(12).level or 0
        -- if (idx+1) > scienlev then

        -- end
        _view.lock:SetActive((idx+1) > scienlev);

        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if (idx+1) > scienlev then
                showDlgError(nil, SGK.Localize:getInstance():getValue("guild_explore_lock"))
                return;
            end

            
            if _view.lock.activeSelf then
                showDlgError(nil, "公会升至".._tab.teamLevel.."级解锁")
            else
                self.selectIdx = idx + 1
                self:upData()
                self:upUi()
                DispatchEvent("LOCAL_UNION_EXPLORE_SELECTMAP_CHANGE", _tab.mapId)
                DialogStack.Pop()
            end
        end
        self:upDoneEventNode(_view,_tab.mapId);
        

        obj:SetActive(true)
    end
    self.allMapScrollView.DataCount = #self.allMapCfg


    self.pageView = self.view.newUnionExploreMapInfoRoot.top.ScrollView[CS.UIPageView]
    self.pageView.DataCount = math.ceil(#self.allMapCfg / 3)
end

function newUnionExploreMapInfo:initData(data)
    self.selectIdx = data.index
end


function newUnionExploreMapInfo:mapEventTip()
    local allmap = unionConfig.GetAllExploremapMessage();
    for k,v in pairs(allmap) do
        -- ERROR_LOG("--------->>>",sprinttb(v))
        local info = self.Manage:GetTeamInfo(v.mapId);
        if info and #info.rewardDepot > 0 then

            -- ERROR_LOG(v.mapId.."地图信息------------>>>",sprinttb(info.rewardDepot));
            -- self.view.newUnionExploreRoot.top.allMap.icon.Image:SetActive(true);
            return;
        end
    end
    -- self.view.newUnionExploreRoot.top.allMap.icon.Image:SetActive(false);
end

function newUnionExploreMapInfo:showIconType(node, typeId,flag)
    if not node then return end
    if not typeId then return end

    if typeId == 0 then
        for i=1,#node do
            node[i]:SetActive(false)
        end
        node.tip:SetActive(false)
    else
        node.tip:SetActive(true)
        node[(typeId - 1)*3+flag]:SetActive(true)
        node[(typeId - 1)*3+flag].transform:SetAsLastSibling();
    end
end

function newUnionExploreMapInfo:upDoneEventNode( item,mapid )

    local _mapInfo = self.Manage:GetTeamInfo(mapid)
    local eventList = self.Manage:GetMapEventList(mapid) or {}
    local _eventTab = {}
    for k,v in pairs(eventList) do
        for j,p in pairs(v) do
            if p.beginTime < module.Time.now() then
                table.insert(_eventTab, p)
            end
        end
    end

    for i=1,3 do
        self:showIconType(item.status,0);
    end

    for i = 1, 3 do
        local _tab = _eventTab[i]
        if _tab then
            local _cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _tab.heroId)
            local _eventCfg = unionConfig.GetTeamAccident(_tab.eventId) or {}

            ERROR_LOG(sprinttb(_eventCfg));
            self:showIconType(item.status, _eventCfg.accident_type,i)
        end
    end
end

function newUnionExploreMapInfo:upData()
    self.allMapCfg = unionConfig.GetAllExploremapMessage()
    self.mapId = self.allMapCfg[self.selectIdx].mapId
    self.cfg = unionConfig.GetExploremapMessage(self.mapId)
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

function newUnionExploreMapInfo:initTop()
    --self.view.newUnionExploreMapInfoRoot.bg.mapName[UI.Text].text = self.cfg.name
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreMapInfoRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end

    self.yuansuTab = self:getBIT(BIT(self.mapInfo.property))
end

function newUnionExploreMapInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    self:mapEventTip();
    self:initTop()
end

function newUnionExploreMapInfo:upUi()
    self.yuansuTab = self:getBIT(BIT(self.mapInfo.property))
    self.allMapScrollView:ItemRef()
end

function newUnionExploreMapInfo:Start(data)
    self.Manage = activityModule.ExploreManage
    self:initData(data)
    self:upData()
    self:initUi()
    self:initAllMapUi()
end

return newUnionExploreMapInfo
