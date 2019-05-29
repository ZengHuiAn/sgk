local activityModule = require "module.unionActivityModule"
local ItemHelper = require"utils.ItemHelper"
local unionConfig = require "config.unionConfig"
local RewardItemShowCfg = require "config.RewardItemShow"

local newUnionExplore = {}

function newUnionExplore:setNowIndex(index)
    if index then
        self.nowIndex = index
        self.savedValues.unionExplore = self.nowIndex
    end
end

function newUnionExplore:initData()
    self.allBossNode = {}
    self.talkListTime = {}
    self.Manage = activityModule.ExploreManage
    self.nowIndex = self.savedValues.unionExplore or 1
    self:setNowIndex(self.nowIndex)
    self.mapCfg = unionConfig.GetExploremapMessage(self.nowIndex)
end

function newUnionExplore:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initTop()
    self:initEventNode()
    self:initMiddle()
    self:initLog()
    self:upArrow()
    self:initMoveMap()
    SGK.Action.DelayTime.Create(5):OnComplete(function()
        self:showTalk()
    end)
    self:upEventList()
end

function newUnionExplore:upEventList()
    SGK.Action.DelayTime.Create(5):OnComplete(function()
        self:upEventNode()
        self:upEventList()
    end)
end

function newUnionExplore:initEventNode()
    self.eventNode = self.view.newUnionExploreRoot.top.eventNode
    self:upEventNode()
end

function newUnionExplore:showIconType(node, typeId)
    if not node then return end
    if not typeId then return end
    for i = 1, #node do
        node[i]:SetActive(typeId == i)
    end
end

function newUnionExplore:closeBossNode()
    for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
        local _view = self.view.newUnionExploreRoot.top.bossNode[i]
        _view:SetActive(false)
    end
end

function newUnionExplore:upEventNode()

    if utils.SGKTools.GameObject_null(self.eventNode) then
        return;
    end
    local _mapInfo = self.Manage:GetTeamInfo(self.mapCfg.mapId)
    self.eventList = self.Manage:GetMapEventList(self.mapCfg.mapId) or {}
    local _eventTab = {}
    for k,v in pairs(self.eventList) do
        for j,p in pairs(v) do
            if p.beginTime < module.Time.now() then
                table.insert(_eventTab, p)
            end
        end
    end
    for i = 1, 3 do
        local _tab = _eventTab[i]

        if utils.SGKTools.GameObject_null(self.eventNode[i].gameObject) == true then
            return;
        end
        if _tab then
            local _cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _tab.heroId)
            local _eventCfg = unionConfig.GetTeamAccident(_tab.eventId) or {}

            
            utils.IconFrameHelper.Create(self.eventNode[i].newCharacterIcon, {type = 42, uuid = _cfg.uuid, func = function(obj)
                -- obj.LowerRightText:SetActive(false)
            end})
            self:showIconType(self.eventNode[i].status, _eventCfg.accident_type)
            CS.UGUIClickEventListener.Get(self.eventNode[i].gameObject).onClick = function()
                ---弹框
                local _data = {
                    mapCfg = self.mapCfg,
                    order = _mapInfo.order,
                    cfg   = _tab,
                }
                self:closeBossNode()
                DialogStack.PushPrefStact("newUnion/newUnionExploreBox", _data)
                --self.Manage:FinishEvent(self.mapCfg.mapId, _mapInfo.order, _tab.uuid)
            end
        end
        if _tab then
            self.eventNode[i]:SetActive(true)
        else
            self.eventNode[i]:SetActive(false)
        end
        if not _mapInfo then
            self.eventNode[i]:SetActive(false)
        end
    end
end

function newUnionExplore:upUi()
    self.mapCfg = unionConfig.GetExploremapMessage(self.nowIndex)
    self:upTop()
    self:upEventNode()
    self:upHeroIcon()
    self:upGiftNode()
    self:upArrow()
    self:upMoveMap()
    self:restTalk()
    self.view.newUnionExploreRoot.transform:DOLocalMove(Vector3(0, 0, 0), 5):OnComplete(function()
        self:showTalk()
    end)
end

function newUnionExplore:restTalk()
    for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
        local _view = self.view.newUnionExploreRoot.top.bossNode[i].dialogue
        _view[UnityEngine.CanvasGroup].alpha = 0
    end
    self.view.newUnionExploreRoot.transform:DOKill()
end

function newUnionExplore:upArrow()
    self.view.newUnionExploreRoot.top.leftBtn:SetActive(self.nowIndex > 1)
    self.view.newUnionExploreRoot.top.rightBtn:SetActive(self.nowIndex < #unionConfig.GetExploremapMessage())
end

function newUnionExplore:canStart()
    if not self.Manage:GetTempHeroTab(self.mapCfg.mapId) then
        return false
    end
    for k,v in ipairs(self.Manage:GetTempHeroTab(self.mapCfg.mapId)) do
        if v ~= 0 then
            return true
        end
    end
    return false
end

function newUnionExplore:initTop()
    self.mapName = self.view.newUnionExploreRoot.top.mapName.name[UI.Text]
    self.mapIcon = self.view.newUnionExploreRoot.top.mapName.icon
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.top.mapName.info.gameObject).onClick = function()
        --self:closeBossNode()
        -- newUnionExploreMapDoneInfo
        DialogStack.PushPrefStact("newUnion/newUnionExploreMapDoneInfo", self.nowIndex)
       
    end

    self.view.newUnionExploreRoot.bg.Image.tipBtn[CS.UGUIClickEventListener].onClick = function()
        -- DialogStack.PushPrefStact("newUnion/newUnionExploreMapDoneInfo", self.nowIndex)
     utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("juntuan_tanxian_shuoming_02"))
       
    end
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.top.allMap.gameObject).onClick = function()
        self:closeBossNode()
        DialogStack.PushPrefStact("newUnion/newUnionExploreMapInfo", {index = (self.nowIndex or 1)})
    end
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.top.leftBtn.gameObject).onClick = function()
        if self.nowIndex - 1 > 0 then
            self.nowIndex = self.nowIndex - 1
            -- ERROR_LOG(self.nowIndex);
            self:setNowIndex(self.nowIndex)
            self:upUi()
            self:mapEventTip();
        end
    end
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.top.rightBtn.gameObject).onClick = function()
        if module.unionScienceModule.GetScienceInfo(12) and module.unionScienceModule.GetScienceInfo(12).level > self.mapCfg.mapId then

            if self.nowIndex + 1 <= #unionConfig.GetExploremapMessage() then
                self.nowIndex = self.nowIndex + 1
                -- ERROR_LOG(self.nowIndex);
                self:setNowIndex(self.nowIndex)
                self:upUi()
                self:mapEventTip();
            end
        else
            showDlgError(nil, SGK.Localize:getInstance():getValue("guild_explore_lock"))
        end

        
    end
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.middle.top.start.gameObject).onClick = function()
        if self:canStart() then
            if module.unionScienceModule.GetScienceInfo(12) and module.unionScienceModule.GetScienceInfo(12).level >= self.mapCfg.mapId then

                self.Manage:startExplore(self.mapCfg.mapId, self.Manage:GetTempHeroTab(self.mapCfg.mapId), self.mapCfg.mapId)
            else
                showDlgError(nil, "当前地图未解锁")
            end

        else
            showDlgError(nil, "请选择英雄")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.middle.top.stop.gameObject).onClick = function()
        if self.Manage:GetTeamInfo(self.mapCfg.mapId) then
            showDlg(nil,"停止探险将放弃所有事件和奖励\n点击确定停止探险", function()
                self.Manage:stopExplore(self.mapCfg.mapId, self.Manage:GetTeamInfo(self.mapCfg.mapId).order)
            end, function() end)
        end
    end
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.top.bossIcon.gameObject).onClick = function()
        --限时boss icon
    end
    self:upTop()
end

function newUnionExplore:playTalkNext(cfg)
    if self.Manage:GetTeamInfo(self.mapCfg.mapId) then
        local _heroTab = self.Manage:GetTeamInfo(self.mapCfg.mapId).heroTab
        for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
            if self.view.newUnionExploreRoot.top.bossNode[i].name == tostring(cfg.role_id) then
                local _view = self.view.newUnionExploreRoot.top.bossNode[i].dialogue
                --_view[UnityEngine.CanvasGroup].alpha = 1
                _view[UnityEngine.CanvasGroup]:DOKill()
                ShowNpcDesc(_view, cfg.talking_des, function()
                    self:showTalkNext(unionConfig.GetExploreTalkingTabById(cfg.next_id))
                end, cfg.talking_frametype, 3)
            end
        end
    end
end

function newUnionExplore:showTalkNext(cfg)
    if cfg then
        if cfg.next_id ~= 0 then
            self:playTalkNext(cfg)
        else
            self:showTalk()
        end
    end
end

function newUnionExplore:showTalk()
    local _teamCfg = self.Manage:GetTeamInfo(self.mapCfg.mapId)
    if _teamCfg then
        local _heroTab = self.Manage:GetTeamInfo(self.mapCfg.mapId).heroTab
        local _talkMapId = self.mapCfg.mapId
        if _teamCfg.count >= _teamCfg.maxCount then
            _talkMapId = 99
        end
        local _talk, _talkType = unionConfig.GetExploreTalking(_talkMapId, _heroTab)
        if not _talkType then

            if utils.SGKTools.GameObject_null(self.view.newUnionExploreRoot.top.bossNode) then
                return;
            end
            for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
                if _talk and self.view.newUnionExploreRoot.top.bossNode[i].name == tostring(_talk.role_id) then
                    local _view = self.view.newUnionExploreRoot.top.bossNode[i].dialogue
                    --_view[UnityEngine.CanvasGroup].alpha = 1
                    _view[UnityEngine.CanvasGroup]:DOKill()
                    for i,v in ipairs(self.talkListTime) do
                        v:Kill()
                    end
                    self.talkListTime =  {}
                    ShowNpcDesc(_view, _talk.talking_des, function()
                        local _action = SGK.Action.DelayTime.Create(7):OnComplete(function()
                            self:showTalk()
                        end)
                        table.insert(self.talkListTime, _action)
                    end, _talk.talking_frametype, 3)
                end
            end
        else
            self:showTalkNext(_talk)
        end
    end
end

function newUnionExplore:initMoveMap()
    self.map1 = self.view.newUnionExploreRoot.top.mapMask.map_tansuo1
    self.map2 = self.view.newUnionExploreRoot.top.mapMask.map_tansuo2


    self.map3 = self.view.newUnionExploreRoot.top.mapMaskCenter.map_tansuo1
    self.map4 = self.view.newUnionExploreRoot.top.mapMaskCenter.map_tansuo2

    self.map5 = self.view.newUnionExploreRoot.top.mapMaskFront.map_tansuo1
    self.map6 = self.view.newUnionExploreRoot.top.mapMaskFront.map_tansuo2
    self:upMoveMap()
end

function newUnionExplore:upMoveMap()
    self.map1[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap.."_1")
    self.map2[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap.."_1")
    self.map3[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap.."_2")
    self.map4[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap.."_2")
    self.map5[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap.."_3")
    self.map6[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap.."_3")
end


local offest_Speed = {
    0.5, --前
    1,   --中
    0.9, --后
}

function newUnionExplore:Update()

    local allmap = unionConfig.GetAllExploremapMessage();

    for k,v in pairs(allmap) do
        if v.mapId ~= self.mapCfg.mapId then
            self.Manage:GetTeamInfo(v.mapId);
        end
    end
    local _cfg = self.Manage:GetTeamInfo(self.mapCfg.mapId)
    if _cfg then
        local _offX = 2
        if _cfg.count >= _cfg.maxCount then
            _offX = 0.2
        end
        if not self.view.newUnionExploreRoot.top.ExpBar.activeSelf then
            self.view.newUnionExploreRoot.top.ExpBar:SetActive(true)
            self.view.newUnionExploreRoot.top.Node:SetActive(true)
        end
        self.view.newUnionExploreRoot.top.ExpBar[UI.Scrollbar].size = (_cfg.maxCount - _cfg.count) / _cfg.maxCount
        for i,v in ipairs(self.allBossNode) do
            if v and v.activeSelf then
                local _spine = v:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
                if _spine then
                    if _cfg.count >= _cfg.maxCount then
                        _spine.timeScale = 0.2
                    else
                        _spine.timeScale = 1
                    end
                end
            end
        end

        self.map1.transform.localPosition = self.map1.transform.localPosition - Vector3(_offX*offest_Speed[3], 0, 0)
        self.map2.transform.localPosition = self.map2.transform.localPosition - Vector3(_offX*offest_Speed[3], 0, 0)

        self.map3.transform.localPosition = self.map3.transform.localPosition - Vector3(_offX*offest_Speed[2], 0, 0)
        self.map4.transform.localPosition = self.map4.transform.localPosition - Vector3(_offX*offest_Speed[2], 0, 0)
        self.map5.transform.localPosition = self.map5.transform.localPosition - Vector3(_offX*offest_Speed[1], 0, 0)
        self.map6.transform.localPosition = self.map6.transform.localPosition - Vector3(_offX*offest_Speed[1], 0, 0)


        if math.floor(self.map1.transform.localPosition.x) <= (-self.map1.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width) then
            self.map1.transform.localPosition = Vector3((self.map1.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width), 0, 0)
        end
        if self.map2.transform.localPosition.x <= (-self.map1.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width) then
            self.map2.transform.localPosition = Vector3((self.map2.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width), 0, 0)
        end

        if math.floor(self.map3.transform.localPosition.x) <= (-self.map3.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width) then
            self.map3.transform.localPosition = Vector3((self.map3.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width), 0, 0)
        end
        if math.floor(self.map4.transform.localPosition.x) <= (-self.map4.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width) then
            self.map4.transform.localPosition = Vector3((self.map4.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width), 0, 0)
        end

        if self.map5.transform.localPosition.x <= (-self.map5.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width) then
            self.map5.transform.localPosition = Vector3((self.map5.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width), 0, 0)
        end
        if self.map6.transform.localPosition.x <= (-self.map6.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width) then
            self.map6.transform.localPosition = Vector3((self.map6.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width), 0, 0)
        end


    else
        if self.view.newUnionExploreRoot.top.ExpBar.activeSelf then
            self.view.newUnionExploreRoot.top.ExpBar:SetActive(false)
            self.view.newUnionExploreRoot.top.Node:SetActive(false)
        end
    end
end

function newUnionExplore:getBIT(tab)
    local _tab = {}
    for k,v in pairs(tab) do
        if v ~= 0 then
            table.insert(_tab, k)
        end
    end
    return _tab
end

function newUnionExplore:setRunOrIdle(typeId)
    for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
        local _view = self.view.newUnionExploreRoot.top.bossNode[i]
        _view[SGK.DialogSprite].idle = typeId
    end
end

function newUnionExplore:upTop()

    if not self.mapName or utils.SGKTools.GameObject_null(self.mapName) == true then
        return;
    end
    self.mapName.text = self.mapCfg.name
    if not self.Manage:GetMapInfo(self.mapCfg.mapId) then
        ERROR_LOG("server mapid error", self.mapCfg.mapId)
        return
    end
    local _tab = self:getBIT(BIT(self.Manage:GetMapInfo(self.mapCfg.mapId).property))

    -- ERROR_LOG("属性",sprinttb(_tab));
    if _tab and _tab[1] and utils.SGKTools.GameObject_null(self.mapIcon.gameObject) ~= true then
        self.mapIcon[UI.Image]:LoadSprite("propertyIcon/yuansu"..(_tab[1]-1))
    end
    if self.Manage:GetTeamInfo(self.mapCfg.mapId) then
        self:setRunOrIdle(false)
        self.view.newUnionExploreRoot.middle.top.stop:SetActive(true)
    else
        self:setRunOrIdle(true)
        self.view.newUnionExploreRoot.middle.top.stop:SetActive(false)
    end
    self.view.newUnionExploreRoot.middle.top.start:SetActive(not self.view.newUnionExploreRoot.middle.top.stop.activeSelf)
    local _material = nil
    if not self.Manage:GetTempHeroTab(self.mapCfg.mapId) then
        self.view.newUnionExploreRoot.middle.top.start[CS.UGUISelectorGroup]:setGray()
        --_material = self.view.newUnionExploreRoot.middle.top.start[CS.UnityEngine.MeshRenderer].materials[0]
    else
        self.view.newUnionExploreRoot.middle.top.start[CS.UGUISelectorGroup]:reset()
    end
    --self.view.newUnionExploreRoot.middle.top.start[UI.Image].material = _material
    self.view.newUnionExploreRoot.top.lock:SetActive(not self.Manage:GetTempHeroTab(self.mapCfg.mapId))
    self.view.newUnionExploreRoot.middle.lock:SetActive(not self.Manage:GetTempHeroTab(self.mapCfg.mapId))
    self.view.newUnionExploreRoot.middle.top.get:SetActive(self.view.newUnionExploreRoot.middle.top.stop.activeSelf)
end

function newUnionExplore:initHeroIcon()
    for i = 1, #self.view.newUnionExploreRoot.middle.top.heroNode do
        local _view = self.view.newUnionExploreRoot.middle.top.heroNode[i]
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if self.Manage:GetTeamInfo(self.mapCfg.mapId) then
                showDlgError(nil, "探险中无法切换阵容")
            else
                if module.unionScienceModule.GetScienceInfo(12) and module.unionScienceModule.GetScienceInfo(12).level >= self.mapCfg.mapId then

                else
                    showDlgError(nil, "当前地图未解锁")
                    return;
                end

                DialogStack.PushPrefStact("FormationDialog", {type = 3, unionExplore = self.mapCfg.mapId, online = self:getHeroList(), master = 0, unionExploreFunc = function(data)
                    DispatchEvent("LOCAL_UNION_GOTO_EXPLORE", {index = self.mapCfg.mapId, tab = data})
                    for i,v in ipairs(data) do
                        if v ~= 0 then
                            self.Manage:startExplore(self.mapCfg.mapId, data, self.mapCfg.mapId)
                            DialogStack.Pop()
                            return
                        end
                    end
                    showDlgError(nil, "请选择英雄")
                end})
                --DialogStack.Push("newUnion/newUnionExplainBattle", {mapid = self.mapCfg.mapId, _index = self.mapCfg.mapId, showBg = true})
            end
        end
    end 
end

function newUnionExplore:initGiftNode()
    ERROR_LOG("get----->>>>>>>",sprinttb(self.Manage:GetTeamInfo(self.mapCfg.mapId)))
    CS.UGUIClickEventListener.Get(self.view.newUnionExploreRoot.middle.top.get.gameObject).onClick = function()
        local _team = self.Manage:GetTeamInfo(self.mapCfg.mapId)
        if _team and #_team.rewardDepot >= 1 then
            self.view.newUnionExploreRoot.middle.top.get[CS.UGUIClickEventListener].interactable = false
            self.view.newUnionExploreRoot.middle.top.get[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            self.Manage:reward(_team.mapId, _team.order, function()
                self.view.newUnionExploreRoot.middle.top.get[CS.UGUIClickEventListener].interactable = true
                self.view.newUnionExploreRoot.middle.top.get[UI.Image].material = nil
            end)
        else
            showDlgError(nil, "无物品/道具领取")
        end
    end
    self.view.newUnionExploreRoot.middle.top.giftNode.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = {}
        if not self.view.newUnionExploreRoot.middle.top.stop.activeSelf then
            _tab = unionConfig.GetExploremapMessage(self.mapCfg.mapId).reward[idx+1]
        else
            _tab = self.Manage:GetTeamInfo(self.mapCfg.mapId).rewardDepot[idx+1]
        end
        local icon = utils.IconFrameHelper.Create(_view, {id = _tab.id, type = _tab.type, showDetail = true, count = _tab.count or 0,func = function ( prefab )
            _view.flag:SetActive(not self.view.newUnionExploreRoot.middle.top.stop.activeSelf and idx == 0);
            _view.flag.transform:SetAsLastSibling();
        end})
        icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
        obj:SetActive(true)
    end
    self:upGiftNode()
end

function newUnionExplore:upGiftNode()
    local _teamInfo = self.Manage:GetTeamInfo(self.mapCfg.mapId)
    local _const = 0
    if _teamInfo and #_teamInfo.rewardDepot > 0 then
        _const = #_teamInfo.rewardDepot
    end
    local _material = nil
    local _team = self.Manage:GetTeamInfo(self.mapCfg.mapId)
    if not _team or #_team.rewardDepot < 1 then
        _material = self.view.newUnionExploreRoot.middle.top.get[UnityEngine.MeshRenderer].materials[0]
        self.view.newUnionExploreRoot.middle.top.giftNode.maxText:SetActive(false)
    else
        self.view.newUnionExploreRoot.middle.top.giftNode.maxText:SetActive(_teamInfo.count >= _teamInfo.maxCount)
    end
    if not self.view.newUnionExploreRoot.middle.top.stop.activeSelf then
        self.view.newUnionExploreRoot.middle.top.giftNode.ScrollView[CS.UIMultiScroller].DataCount = #RewardItemShowCfg.Get(RewardItemShowCfg.TYPE.UNION_EXPLORE)
        self.view.newUnionExploreRoot.middle.bg.Text[UI.Text]:TextFormat("可获得")
    else
        self.view.newUnionExploreRoot.middle.top.giftNode.ScrollView[CS.UIMultiScroller].DataCount = _const
        self.view.newUnionExploreRoot.middle.bg.Text[UI.Text]:TextFormat("已获得")
    end
    self.view.newUnionExploreRoot.middle.top.get[UI.Image].material = _material
end

function newUnionExplore:getHeroList()
    local _tempHeroTab = self.Manage:GetTempHeroTab(self.mapCfg.mapId)
    local _mapInfo = self.Manage:GetTeamInfo(self.mapCfg.mapId)
    local _list = {}
    for i = 1, #self.view.newUnionExploreRoot.middle.top.heroNode do
        if _mapInfo then
            if _mapInfo.heroTab[i] ~= 0 then
                table.insert(_list, _mapInfo.heroTab[i])
            else
                table.insert(_list, 0)
            end
        else
            if _tempHeroTab and _tempHeroTab[i] and _tempHeroTab[i] ~= 0 then
                table.insert(_list, _tempHeroTab[i])
            else
                table.insert(_list, 0)
            end
        end
    end
    return _list
end

function newUnionExplore:upHeroIcon()
    local indexI = 0
    local indexY = 0

    for i = 1, #self.view.newUnionExploreRoot.middle.top.heroNode do
        local _view = self.view.newUnionExploreRoot.middle.top.heroNode[i]
        local _tempHeroTab = self.Manage:GetTempHeroTab(self.mapCfg.mapId)
        local _mapInfo = self.Manage:GetTeamInfo(self.mapCfg.mapId)

        if _tempHeroTab~=nil then
            local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _tempHeroTab[i])
            local map_info = unionConfig.GetAllExploremapMessage(self.mapCfg.mapId)
           if _tempHeroTab[i]~=0 then
              indexI=indexI+1
              if map_info.property==hero_cfg.cfg.type then
                 indexY=indexY +1
              end
           end
        end


        if _mapInfo then
            if _mapInfo.heroTab[i] ~= 0 then
                _view.IconFrame:SetActive(true)
                local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _mapInfo.heroTab[i])
                --_view.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(hero_cfg)

                -- ERROR_LOG();
                utils.IconFrameHelper.Create(_view.IconFrame, {type = 42, uuid = hero_cfg.uuid,func = function ( obj )

                    -- local map_info = unionConfig.GetAllExploremapMessage(self.mapCfg.mapId)
                    -- local flag = obj.transform:Find("unionExploreFlag(Clone)");
                    -- if map_info.property ~= hero_cfg.cfg.type then
                    --     if flag then
                    --         flag.gameObject:SetActive(false);
                    --     end
                    --     return;
                    -- end

                    -- if flag then
                    --     flag.gameObject:SetActive(true);
                    --     return;
                    -- end
                    -- -- favorable
                    -- local iconframe = CS.SGK.UIReference.Setup(obj);
                    -- iconframe.Star.transform:SetAsLastSibling();
                    -- local starIndex = iconframe.Star.transform:GetSiblingIndex();

                    -- if not self.unionExploreObj then
                    --     self.unionExploreObj = SGK.ResourcesManager.Load("prefabs/expOnline/unionExploreFlag.prefab");         
                    -- end
                    -- if self.unionExploreObj then
                    --     local slider = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(self.unionExploreObj,obj.gameObject.transform));
                    --     slider.gameObject.transform:SetSiblingIndex(starIndex+1);
                    -- end
                    
                end})
                self.Manage:SetTempHeroTab(self.mapCfg.mapId, i, _mapInfo.heroTab[i])
            else
                _view.IconFrame:SetActive(false)
            end
        else
            if _tempHeroTab and _tempHeroTab[i] and _tempHeroTab[i] ~= 0 then
                _view.IconFrame:SetActive(true)
                local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _tempHeroTab[i])
                utils.IconFrameHelper.Create(_view.IconFrame, {type = 42, uuid = hero_cfg.uuid,func = function ( obj )

                    -- local map_info = unionConfig.GetAllExploremapMessage(self.mapCfg.mapId)
                    -- local flag = obj.transform:Find("unionExploreFlag(Clone)");
                    -- if map_info.property ~= hero_cfg.cfg.type then
                    --     if flag then
                    --         flag.gameObject:SetActive(false);
                    --     end
                    --     return;
                    -- end

                    -- if flag then
                    --     flag.gameObject:SetActive(true);
                    --     return;
                    -- end
                    -- -- favorable
                    -- local iconframe = CS.SGK.UIReference.Setup(obj);
                    -- iconframe.Star.transform:SetAsLastSibling();
                    -- local starIndex = iconframe.Star.transform:GetSiblingIndex();

                    -- if not self.unionExploreObj then
                    --     self.unionExploreObj = SGK.ResourcesManager.Load("prefabs/expOnline/unionExploreFlag.prefab");         
                    -- end
                    -- if self.unionExploreObj then
                    --     local slider = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(self.unionExploreObj,obj.gameObject.transform));
                    --     slider.gameObject.transform:SetSiblingIndex(starIndex+1);
                    -- end
                    
                end})
            else
                _view.IconFrame:SetActive(false)
            end
        end
    end
    self.view.newUnionExploreRoot.middle.top.currentReward.additionValue[UI.Text].text="+" .. (indexI+indexY)*10 .."%"
    self.allBossNode = {}

    -- ERROR_LOG("=======>>>>",self.mapCfg.mapId,sprinttb(self.Manage:GetTempHeroTab(self.mapCfg.mapId)));
    for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
        local _view = self.view.newUnionExploreRoot.top.bossNode["boss"..i]
        local _tempHeroTab = self.Manage:GetTempHeroTab(self.mapCfg.mapId)
        local _boss = _view:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
        --_view:GetComponent(typeof(UnityEngine.MeshRenderer)).sortingOrder = 1
        table.insert(self.allBossNode, _view)
        if _tempHeroTab and _tempHeroTab[i] and _tempHeroTab[i] ~= 0 then
            local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _tempHeroTab[i])

            if hero_cfg then

                if _view.current_hero_mode ~= hero_cfg.showMode then
                    SGK.ResourcesManager.LoadAsync(_boss, "roles_small/"..hero_cfg.showMode.."/"..hero_cfg.showMode.."_SkeletonData.asset", function(o)
                        if o then
                            _boss.skeletonDataAsset = o
                            _boss:Initialize(true)
                            local _sprite = _view:GetComponent(typeof(SGK.DialogSprite))
                            _sprite:SetDirty()
                        else
                            _boss.skeletonDataAsset = nil
                            --_view:GetComponent(typeof(UnityEngine.MeshRenderer)).material = nil
                            _view.name = "boss"
                        end
                    end)
                end
                _view:SetActive(true)
                _view.name = tostring(hero_cfg.id)
                _view.current_hero_mode = hero_cfg.showMode;
                
            end
        else
            _view:SetActive(false)
            _boss.skeletonDataAsset = nil
            --_view:GetComponent(typeof(UnityEngine.MeshRenderer)).material = nil
            _view.name = "boss"
        end
    end
end

function newUnionExplore:initMiddle()
    self:initHeroIcon()
    self:upHeroIcon()
    self:initGiftNode()
end

function newUnionExplore:addLog()
    local _text = ""
    for i = #self.Manage:GetMapLog(), 1, -1 do
        local v = self.Manage:GetMapLog()[i]
        local _mapCfg = unionConfig.GetExploremapMessage(v.mapId)
        local _eventCfg = unionConfig.GetTeamAccident(v.eventId)

        if _eventCfg then
            local _eventText = string.format(_eventCfg.accident_log, v.name)
            _text = _text..string.format("<color=#FABC43>%s</color>：%s\n", _mapCfg.name, _eventText)
            --todo
        end
    end
    self.view.newUnionExploreRoot.log.unLog:SetActive(#self.Manage:GetMapLog() <= 0)
    return _text
end

function newUnionExplore:initLog()
    self.logText = self.view.newUnionExploreRoot.log.ScrollView.Viewport.Content.Text[UI.Text]
    self.logText.text = self:addLog()
end

function newUnionExplore:Start()
    self:initData()
    self:initUi()
    self:mapEventTip();
    module.guideModule.PlayByType(18, 0.3)
end

function newUnionExplore:mapEventTip()
    local allmap = unionConfig.GetAllExploremapMessage();
    for k,v in pairs(allmap) do
        --if v.mapId ~= self.mapCfg.mapId then
            local info = self.Manage:GetTeamInfo(v.mapId);
            if info and #info.rewardDepot > 0 then

                -- ERROR_LOG(v.mapId.."地图信息------------>>>",sprinttb(info));
                self.view.newUnionExploreRoot.top.allMap.icon.Image:SetActive(true);
                return;
            end
       -- end
    end
    self.view.newUnionExploreRoot.top.allMap.icon.Image:SetActive(false);
end

function newUnionExplore:listEvent()
    return {
        "LOCAL_UNION_EXPLORE_TEAMCHANGE",
        "LOCAL_EXPLORE_OVERFLOW",
        "LOCAL_UNION_EXPLORE_SELECTMAP_CHANGE",
        "LOCAL_EXPLORE_MAPEVENT_CHANGE",
        "LOCAL_UNION_EXPLORE_LOG_CHANGE",
        "PrefStact_POP",
        "LOCAL_GUIDE_CHANE",
    }
end

function newUnionExplore:onEvent(event, data)
    if event == "LOCAL_UNION_EXPLORE_TEAMCHANGE" or event == "LOCAL_EXPLORE_OVERFLOW" then
        self:upUi()
        self:mapEventTip();
    elseif event == "LOCAL_UNION_EXPLORE_SELECTMAP_CHANGE" then
        self:setNowIndex(data)
        self:upUi()
    elseif event == "LOCAL_EXPLORE_MAPEVENT_CHANGE" then
        self:upEventNode()
    elseif event == "LOCAL_UNION_EXPLORE_LOG_CHANGE" then
        self.logText.text = self:addLog()
    elseif event == 'PrefStact_POP' then
        for i = 1, #self.view.newUnionExploreRoot.top.bossNode do
            local _view = self.view.newUnionExploreRoot.top.bossNode[i]
            _view:SetActive(_view.name ~= "boss")
        end
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(18, 0.3)
    end
end

return newUnionExplore
