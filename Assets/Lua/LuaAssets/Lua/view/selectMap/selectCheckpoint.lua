local fightModule = require "module.fightModule"
local heroModule = require "module.HeroModule"
local selectCheckpoint = {}

function selectCheckpoint:Start(data)
    DispatchEvent("LOCAL_SELECTMAP_PUSH_CHECKPOINT")
    self.offX = 0
    self.offSizeX = 15
    self.offZ = 0
    self.moveOver = true
    self.offXMouse = 0
    self.currModeCfg = {}
    self.bossAnimationCache = {}
    self:initData(data)
    self:initUi()
end

function selectCheckpoint:createUi()
    self.bgSpine= CS.UnityEngine.GameObject.Find("bgSpine")
    if self.bgSpine then
        self.bgSpine.gameObject:SetActive(false)
    end
    self.bossBgNode =  CS.UnityEngine.GameObject.Find("bossBgNode")
    if self.bossBgNode == nil then
        self.bossBgNode = UnityEngine.GameObject("bossBgNode")
    end
    self.bossNodeBase = CS.UnityEngine.GameObject.Find("heroList")
    if self.bossNodeBase == nil then
        self.bossNodeBase =  UnityEngine.GameObject("heroList")
    end
    local _goCheckBoss = CS.UnityEngine.GameObject.Find("goCheBossNode")
    if _goCheckBoss then
        UnityEngine.GameObject.Destroy(_goCheckBoss)
    end
end

function selectCheckpoint:OnDestroy()
    if self.bgSpine then
        self.bgSpine.gameObject:SetActive(true)
    end
    if self.bossBgNode then
        UnityEngine.GameObject.Destroy(self.bossBgNode.gameObject)
    end
    if self.bossNodeBase then
        UnityEngine.GameObject.Destroy(self.bossNodeBase.gameObject)
    end
end

function selectCheckpoint:initBgNode()
    local _item = SGK.ResourcesManager.Load("prefabs/battlefield/environment/"..self.bgId .. ".prefab")
    local obj = CS.UnityEngine.GameObject.Instantiate(_item, self.bossBgNode.gameObject.transform)
end

function selectCheckpoint:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:createUi()
    self:initTop()
    self:initBgNode()
    self:initMiddle()
    self:initBottom()
    self:initScrollView()
    self:upBottomItemList(self.cfg[self.nowIndex].battle_id)
end

function selectCheckpoint:getNowIndex()
    for i = 1, 6 do
        local _cfg = self.cfg[i]
        if _cfg then
            for k,v in pairs(fightModule.GetFightConfigListOfBattle(_cfg.battle_id)) do
                if not fightModule.GetFightInfo(v.gid):IsPassed() then
                    self.lastGid = v.gid
                    return i
                end
            end
        end
    end
    return 6
end

function selectCheckpoint:initData(data)
    if not self.savedValues.selectIndex then self.savedValues.selectIndex = {} end
    if not data then
        if self.savedValues.selectIndex.data and self.savedValues.selectIndex.data.chapterID and self.savedValues.selectIndex.data.bgId then
            self.chapterID = self.savedValues.selectIndex.data.chapterID
            self.bgId = self.savedValues.selectIndex.data.bgId
        end
    else
        self.chapterID = data and data.chapterID or fightModule.GetChapterConfigList[1].chapter_id
        self.bgId = data and data.bgId or "18hao"
    end
    self.cfg = fightModule.GetBattleConfigListOfChapter(self.chapterID)
    self.bgNodeTab = {}
    if not self.savedValues.selectIndex.data then self.savedValues.selectIndex.data = {} end
    if self.chapterID == self.savedValues.selectIndex.data.chapterID then
        if self.savedValues.selectIndex.index then
            self.nowIndex = self.savedValues.selectIndex.index
        else
            self.nowIndex = self:getNowIndex()
        end
    else
        self.nowIndex = self:getNowIndex()
    end
    self.starNumb = 0
    self.savedValues.selectIndex.data.chapterID = self.chapterID
    self.savedValues.selectIndex.data.bgId = self.bgId
end

function selectCheckpoint:initPointList()
    local _item = SGK.ResourcesManager.Load("prefabs/selectMap/pointItem.prefab")
    self.selectPointTab = {}
    for i = 1, #self.cfg do
        local obj = CS.UnityEngine.GameObject.Instantiate(_item, self.pointList.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(obj)
        if i == self.nowIndex then
            self.selectPoint = _view.Image.gameObject
            self.selectPoint:SetActive(true)
        end
        self.selectPointTab[i] = _view.Image.gameObject
    end
end

function selectCheckpoint:switchPoint()
    self:upBottomItemList(self.cfg[self.nowIndex].battle_id)
    self.selectPoint:SetActive(false)
    self.selectPoint = self.selectPointTab[self.nowIndex]
    self.selectPoint:SetActive(true)
end

function selectCheckpoint:initBoss()
    self.bossTab = {}
    local _index = 0
    local _item = SGK.ResourcesManager.Load("prefabs/selectMap/bossCanvas.prefab")
    for k = 0, 2 do
        if self.nowIndex+k > #self.cfg then
            _index = self.nowIndex - (self.nowIndex+k - #self.cfg)
        else
            _index = self.nowIndex+k
        end

        local v = self.cfg[_index]

        local _go = UnityEngine.GameObject("boss"..k)
        _go.transform.parent = self.bossNodeBase.gameObject.transform
        local _boss = _go:AddComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
        
        local obj = CS.UnityEngine.GameObject.Instantiate(_item, _go.transform)
        local _view = CS.SGK.UIReference.Setup(obj)

        self.bossTab[k+1] = {go =_go, index = _index, bossCanvas = _view}
    end

    if self.nowIndex ~= #self.cfg then
        for i = 1, #self.bossTab do
            self.bossTab[i].go.transform.localPosition = Vector3((i-1)*self.offSizeX , -2.3, self.offZ)
        end
        if self.nowIndex ~= 1 and self.nowIndex ~= #self.cfg then
            self.bossTab[#self.bossTab].go.transform.localPosition = Vector3(-self.offSizeX , -2.3, self.offZ)
            self.bossTab[#self.bossTab].index = self.bossTab[1].index - 1
        end
    else
        for i = 1, #self.bossTab do
            self.bossTab[i].go.transform.localPosition = Vector3(-(i-1)*self.offSizeX , -2.3, self.offZ)
            self.bossTab[2].index = self.bossTab[1].index - 1
            self.bossTab[#self.bossTab].index = self.bossTab[1].index - 2
        end
    end

    self:upBossAnimation()

    table.sort(self.bossTab, function (a, b)
        return a.index < b.index
    end)

    local _posIndex = 1
    if self.nowIndex == #self.cfg then
        _posIndex = 3
    elseif self.nowIndex == 1 then
        _posIndex = 1
    else
        _posIndex = 2
    end
    self.bossTab[_posIndex].go.transform.localPosition = Vector3(self.bossTab[_posIndex].go.transform.localPosition.x , self.bossTab[_posIndex].go.transform.localPosition.y, 0)

    self:initBossPoint()

    self:upBossStartPoint()
end

function selectCheckpoint:upBossPosX()
    for k,v in pairs(self.bossTab) do
        if k == 2 then
            v.go.transform.localPosition = Vector3(v.go.transform.localPosition.x , v.go.transform.localPosition.y, 0)
        else
            v.go.transform.localPosition = Vector3(v.go.transform.localPosition.x , v.go.transform.localPosition.y, self.offZ)
        end
    end
end

function selectCheckpoint:upBossStartPoint()
    self.bossStartPoint = {}
    for i,v in ipairs(self.bossTab) do
        self.bossStartPoint[i] = v.go.transform.localPosition
    end
end

function selectCheckpoint:upBossAnimation()
    for k,v in pairs(self.bossTab) do
        if self.cfg[v.index] then

            local _go = v.go:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
            
            local modeId = self.cfg[v.index].mode_id;

            v.bossCanvas.item.text[UI.Text].text = self.cfg[v.index].desc

            if not self.bossAnimationCache[modeId] or self.bossAnimationCache[modeId] ~= _go.skeletonDataAsset then
                _go.transform.localScale = Vector3.one * (self.cfg[v.index].scale * 1.8)
                --_go.transform.localScale = Vector3(0.6, 0.6, 0.6)
                _go.skeletonDataAsset = nil;

                if self.bossAnimationCache[modeId] then
                    _go.skeletonDataAsset = self.bossAnimationCache[modeId]
                    _go:Initialize(true)
                    _go.state:SetAnimation(0,"idle",true)
                else
                    SGK.ResourcesManager.LoadAsync(_go, "roles/"..modeId.."/"..modeId.."_SkeletonData.asset", function(o)
                        self.bossAnimationCache[modeId] = o
                        _go.skeletonDataAsset = o;
                        _go:Initialize(true)
                        _go.state:SetAnimation(0,"idle",true)
                    end)
                end
            end
        end
    end
end


function selectCheckpoint:initBossPoint()
    self.selectBossNode = self.view.selectCheckpointRoot.top.bossNode
    CS.UGUIPointerEventListener.Get(self.selectBossNode.gameObject).onPointerDown = function(go, pos)
        self.onDown = true
    end

    CS.UGUIPointerEventListener.Get(self.selectBossNode.gameObject).onPointerUp = function(go, pos)
        self.onDown = false
        local _tempTab = {}
        for i,v in ipairs(self.bossTab) do
            if self.offXMouse < 0 then
                _tempTab[i] = {_x = math.abs(self.offSizeX / 2 - v.go.transform.localPosition.x), index = v.index}
            else
                _tempTab[i] = {_x = math.abs(self.offSizeX / 2 + v.go.transform.localPosition.x), index = v.index}
            end
        end
        table.sort(_tempTab, function(a, b)
                return a._x < b._x
            end)
        self.offX = self.nowIndex - _tempTab[1].index
        self:moveBoss()
    end

    CS.UGUIScrollRectEventListener.Get(self.selectBossNode.gameObject).onDrag = function(go, position, delta) 
        if self.onDown and self.moveOver then
            self.offXMouse = delta[0] / 30
            if self.nowIndex >= #self.cfg and self.offXMouse < 0 then 
                return
            end
            if self.nowIndex - 1 <= 0 and self.offXMouse > 0 then
                return
            end
            for i,v in ipairs(self.bossTab) do
                local _p = v.go.transform.localPosition
                v.go.transform.localPosition = Vector3(_p.x + self.offXMouse, _p.y, _p.z)
            end
        end
    end
end

function selectCheckpoint:moveBoss()
    if not self.moveOver then return end
    self.moveOver = false
    for i,v in ipairs(self.bossTab) do
        if self.offX > 0 then
            if self.nowIndex - 1 > 0 then
                v.go.transform:DOLocalMove(self.bossStartPoint[i] + Vector3(self.offSizeX, 0 , 0),0.2):OnComplete(function ()
                    if v.go.transform.localPosition.x == self.offSizeX * 2 then
                        v.go.transform.localPosition = Vector3(-self.offSizeX, v.go.transform.localPosition.y, self.offZ)
                        self.bossTab[#self.bossTab].index = self.bossTab[#self.bossTab].index - 3
                        table.sort(self.bossTab, function (a, b)
                            return a.index < b.index
                        end)
                    end
                end)
            end
        elseif self.offX < 0 then
            if self.nowIndex < #self.cfg then
                v.go.transform:DOLocalMove(self.bossStartPoint[i] - Vector3(self.offSizeX, 0 , 0),0.2):OnComplete(function ()
                    if v.go.transform.localPosition.x == (-self.offSizeX * 2) then
                        v.go.transform.localPosition = Vector3(self.offSizeX, v.go.transform.localPosition.y, self.offZ)
                        self.bossTab[1].index = self.bossTab[1].index + 3
                        table.sort(self.bossTab, function (a, b)
                            return a.index < b.index
                        end)
                    end
                end)
            end
        elseif self.offX == 0 then
            v.go.transform:DOLocalMove(self.bossStartPoint[i], 0.2)
        end
    end

    SGK.Action.DelayTime.Create(0.21):OnComplete(function()
        self.moveOver = true
        self:upBossStartPoint()
        self:upBossAnimation()
        self:upBossPosX()
    end)

    if self.offX > 0 then
        if self.nowIndex - 1 > 0 then
            self.nowIndex = self.nowIndex - 1
        end
    elseif self.offX < 0 then
        if self.nowIndex + 1 <= #self.cfg then
            self.nowIndex = self.nowIndex + 1
        end
    end
    self.savedValues.selectIndex.index = self.nowIndex
    self.savedValues.selectIndex.data.chapterID = self.chapterID
    self.savedValues.selectIndex.data.bgId = self.bgId
    self:switchPoint()
    self.offX = 0
end

--[[
function selectCheckpoint:Update()
    if self.onDown and self.moveOver then
        self.offXMouse = (CS.UnityEngine.Input.GetAxis("Mouse X")) / 2
        if self.nowIndex >= #self.cfg and self.offXMouse < 0 then 
            return
        end
        if self.nowIndex - 1 <= 0 and self.offXMouse > 0 then
            return
        end
        for i,v in ipairs(self.bossTab) do
            local _p = v.go.transform.localPosition
            v.go.transform.localPosition = Vector3(_p.x + self.offXMouse, _p.y, _p.z)
        end
    end
end
]]

function selectCheckpoint:initMiddleButton()
    self.leftBtn = self.view.selectCheckpointRoot.middle.left[UI.Button].onClick
    self.rightBtn = self.view.selectCheckpointRoot.middle.right[UI.Button].onClick


    self.leftBtn:RemoveAllListeners()
    self.leftBtn:AddListener(function()
        self.offX = 1
        self:moveBoss()
    end)

    self.rightBtn:RemoveAllListeners()
    self.rightBtn:AddListener(function()
        self.offX = -1
        self:moveBoss()
    end)
end

function selectCheckpoint:initMiddle()
    self.pointList = self.view.selectCheckpointRoot.middle.pointList
    self:initPointList()
    self:initMiddleButton()
end

function selectCheckpoint:initTop()
    self.bossNode = self.view.selectCheckpointRoot.top.bossNode
    self:initBoss()
end

function selectCheckpoint:initBottom()
    self.fighteNumb = self.view.selectCheckpointRoot.bottom.myFighte.fighteNumb[UI.Text]
    self.starNumber = self.view.selectCheckpointRoot.bottom.myFighte.starNumber[UI.Text]
    heroModule.GetManager():GetCapacity()
    self.fighteNumb.text = tostring(heroModule.GetManager():GetCapacity())
    self:initGiftBox()
end

function selectCheckpoint:upBottomItemList(battle_id)
    local fightList = fightModule.GetFightConfigListOfBattle(battle_id)

    self.starNumb = 0

    for i = 0, self.content.gameObject.transform.childCount - 1 do
        local _cfg = fightList[i+1]
        local _info = fightModule.GetFightInfo(_cfg.gid)

        local _item = self.content.gameObject.transform:GetChild(i)
        local _view = CS.SGK.UIReference.Setup(_item)

        _view.bgBtn.node.fighteNumb[UI.Text].text = tostring(_cfg.capacity)
        _view.bgBtn.node.hpNumb[UI.Text].text = tostring(_cfg.cost_item_value)
        _view.bgBtn.node.selectNum[UI.Text].text = tostring(i+1)

        
        for j = 0, 2 do
            local _star = _view.bgBtn.node.starNode.gameObject.transform:GetChild(j):GetComponent(typeof(UI.Image))
            if fightModule.GetOpenStar(_info.star, j+1) ~= 0 then
                _star:LoadSprite("icon/fuben_06")
                _star.color = UnityEngine.Color(1, 1, 1, 1)
                self.starNumb = self.starNumb + 1
            else
                _star:LoadSprite("icon/fuben_05")
                _star.color = UnityEngine.Color(1, 1, 1, 0.5)
            end
        end

        local _bgBtnImg = _view.bgBtn[UI.Button]

        if fightModule.IsLock(_cfg.gid) then
            _bgBtnImg.interactable = false
            _view.bgBtn.node.gameObject:SetActive(false)
            _view.bgBtn.endNode.gameObject:SetActive(true)
            _view.bgBtn.lock.gameObject:SetActive(true)
            _view.bgBtn.endNode.Text[UI.Text].text = tostring(i+1)
            _view.bgBtn.endNode.open[UI.Text].text = "通过"..fightModule.GetPveConfig(_cfg.depend_fight0_id).scene_name
        else
            _bgBtnImg.interactable = true
            _view.bgBtn.node.gameObject:SetActive(true)
            _view.bgBtn.endNode.gameObject:SetActive(false)
            _view.bgBtn.lock.gameObject:SetActive(false)

            CS.UGUIClickEventListener.Get(_view.bgBtn.gameObject).onClick = function()
                if _bgBtnImg.interactable then
                    DialogStack.Push("selectMap/goCheckpoint", {gid = _cfg.gid})
                end
            end
        end

        if not self.lastGid then
            self:getNowIndex()
        end
        if _cfg.gid == self.lastGid and not fightModule.IsLock(_cfg.gid) then
            _view.bgBtn.nowBg.gameObject:SetActive(true)
        else
            _view.bgBtn.nowBg.gameObject:SetActive(false)
        end
    end
    self.starNumber.text = self.starNumb.."/"..(self.content.gameObject.transform.childCount * 3)
end

function selectCheckpoint:initGiftBox()
    self.giftBtn = self.view.selectCheckpointRoot.bottom.myFighte.giftBox
    CS.UGUIClickEventListener.Get(self.giftBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = self.cfg[self.nowIndex].battle_id, star = self.starNumb, index = 2}, UnityEngine.GameObject.FindWithTag("UGUIRoot"))
    end
end


function selectCheckpoint:initScrollView()
    self.ScrollView = self.view.selectCheckpointRoot.bottom.ScrollView
    self.content = self.ScrollView.Viewport.Content
    local _itme = SGK.ResourcesManager.Load("prefabs/selectMap/enemys/selectCheckItem.prefab")
    for i = 1, #fightModule.GetFightConfigListOfBattle(self.cfg[self.nowIndex].battle_id) do
        local obj = CS.UnityEngine.GameObject.Instantiate(_itme, self.content.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(obj)
    end
end

return selectCheckpoint
