local fightModule = require "module.fightModule"
local ItemHelper=require"utils.ItemHelper"
local HeroLevelup = require "hero.HeroLevelup"
local GetModule = require "module.GetModule"

local sweepingInfo = {}

function sweepingInfo:Start(data)
    self.Data={}
    self.playerExp=0
    self.roleExp=0
    SetTipsState(false)
    self:initData(data)
    self:initUi()
    --self:startSweeping(1)

    if self.type then
        fightModule.Sweeping(self.gid[1],1)
    else
        fightModule.Sweeping(self.gid, 1)
    end
end

function sweepingInfo:initData(data)
    self.type = data.type
    self.gid = data.gid
    self.count = self.type and #data.gid or data.count 
    self.oldExp = {}
    self.nowCount = 0
    self.sweepFlag = true
    self.allGiftTab = {}
end

function sweepingInfo:upHeroRoot(data)
    local _heroList = self:getFormationList()
    for i,v in ipairs(_heroList) do
        local _view = self.view.sweepingInfoRoot.top.heroRoot[i]
        local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, v)

        local hero_level_up_config = HeroLevelup.GetExpConfig(1, _hero)
        local Level_exp = hero_level_up_config[_hero.level]
        local Next_hero_level_up = hero_level_up_config[_hero.level+1] and hero_level_up_config[_hero.level+1] or hero_level_up_config[_hero.level]
        local _addExp = 0
        -- if v == 11000 then
        --     for i,p in ipairs(data) do
        --         if p[2] == 90000 then
        --             _addExp = p[3]
        --             --self.playerExp=self.playerExp+p[3]
        --             --print("zeo查看exp",p[3])
        --         end
        --     end
        --else
            for i,p in ipairs(data) do
                if p[2] == 90001 then
                    _addExp = p[3]
                    --self.roleExp=self.roleExp+p[3]
                    --print("zeo查看exp",p[3])
                end
            end
        --end
            _view.expNum[UI.Text].text=tonumber(_view.expNum[UI.Text].text)+_addExp
        local level_AddExp = _hero.exp - Level_exp
        if level_AddExp <= _addExp then
            _view.Exp[UnityEngine.UI.Image]:DOFillAmount(1, 0.5):OnComplete(function ()
                local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_icon_up.prefab");
                local o = prefab and UnityEngine.GameObject.Instantiate(prefab, _view.scaler.gameObject.transform)
                local _duration = 0
                if o then
                    o.transform.localPosition =Vector3.zero;
                    o.transform.localScale = Vector3.one
                    o.transform.localRotation = Quaternion.identity;
                    local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
                    _obj:Play()
                    _duration = _obj.main.duration
                    UnityEngine.Object.Destroy(o, _obj.main.duration)
                    _view.transform:DORotate(Vector3(0, 0, 0), 0.1):OnComplete(function()
                        self:initHeroRoot()
                    end)
                end
            end)
        else
            _view.Exp[UnityEngine.UI.Image]:DOFillAmount(((_hero.exp + _addExp) - Level_exp) / (Next_hero_level_up - Level_exp), 0.5):OnComplete(function ()
                self:initHeroRoot()
            end)
        end
    end
end

function sweepingInfo:getFormationList()
    local _list = {}
    for i,v in ipairs(module.HeroModule.GetManager():GetFormation()) do
        if v ~= 0 then
            table.insert(_list, v)
        end
    end
    return _list
end

function sweepingInfo:initHeroRoot(needFill)
    local _heroList = self:getFormationList()
    for i,v in ipairs(_heroList) do
        local _view = self.view.sweepingInfoRoot.top.heroRoot[i]
        local hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, v)
        utils.IconFrameHelper.Create(_view.scaler.IconFrame, {type = 42, customCfg = hero})
        _view.Name[UI.Text].text = hero.name

        local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero)
        local Level_exp = hero_level_up_config[hero.level]
        local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1] or hero_level_up_config[hero.level]
        if not needFill then
            _view.Exp[UnityEngine.UI.Image].fillAmount = (hero.exp - Level_exp) / (Next_hero_level_up - Level_exp)
        end

        _view:SetActive(true)
    end
end

function sweepingInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initHeroRoot()
    self:initBottom()
    --self:initAllGiftItem()
end

function sweepingInfo:addSweepingItem(data)
    local _obj = CS.UnityEngine.GameObject.Instantiate(self.sweepingItem.gameObject, self.content.gameObject.transform)
    local _view = CS.SGK.UIReference.Setup(_obj)
    if self.type then
        _view.root.count[UI.Text].text = SGK.Localize:getInstance():getValue("shilianta_common_tip2", (self.gid[self.nowCount] - 60000000))
    else
        _view.root.count[UI.Text].text = SGK.Localize:getInstance():getValue("common_cishu_01", self.nowCount)
    end
    local dataTable = {}
    for i,v in ipairs(data) do
        if v[2] ~= 90001 then
            table.insert(dataTable,v)
        end
    end
    local _scrollView = _view.root.ScrollView[CS.UIMultiScroller]
    _scrollView.RefreshIconCallback = function (obj,idx)
        local _objView = CS.SGK.UIReference.Setup(obj)
        local _cfg = dataTable[idx + 1]
        utils.IconFrameHelper.Create(_objView.IconFrame, {uuid = _cfg[4], id = _cfg[2], type = _cfg[1], showDetail = true, count = _cfg[3]})
        self.view.sweepingInfoRoot.transform:DOLocalRotate(Vector3(0, 0, 0), 0.2):OnComplete(function()
            obj.gameObject:SetActive(true)
                local _Obj=CS.SGK.UIReference.Setup(obj)
            _Obj.IconFrame.gameObject.transform:DOScale(Vector3(0.2,0.2,0.2),0.02):OnComplete(function()
                _Obj.IconFrame.gameObject.transform:DOScale(Vector3(0.95,0.95,0.95),0.14):OnComplete(function()
                    _Obj.IconFrame.gameObject.transform:DOScale(Vector3(0.7,0.7,0.7),0.07)
                    end)
                end)
        end)
    end
    _scrollView.DataCount = #dataTable
    _obj.gameObject:SetActive(true)
end

function sweepingInfo:initAllGiftItem()
    self.allGiftScrollView = self.view.sweepingInfoRoot.bottom.allGift.ScrollView[CS.UIMultiScroller]
    self.allGiftScrollView.RefreshIconCallback = function (obj,idx)
        local _objView = CS.SGK.UIReference.Setup(obj)
        local _cfg = self:getGiftTab()[idx + 1]
        local icon = utils.IconFrameHelper.Create(_objView, {uuid = _cfg[4], id = _cfg[2], type = _cfg[1], showDetail = true, count = _cfg[3]})
        icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
        obj.gameObject.transform:DOLocalMove(Vector3(obj.gameObject.transform.localPosition.x+15,0,0),0.1)
        obj:SetActive(true)
    end
    self.allGiftScrollView.DataCount = #self:getGiftTab()
    -- for i=1,#self:getGiftTab() do
    --     self.view.sweepingInfoRoot.bottom.allGift.ScrollView
    -- end
end

function sweepingInfo:initTop()
    self.content = self.view.sweepingInfoRoot.top.ScrollView.Viewport.Content
    self.scrollView = self.view.sweepingInfoRoot.top.ScrollView[UI.ScrollRect]
    self.sweepingItem = self.view.sweepingInfoRoot.top.ScrollView.Viewport.Content.sweepingItem
    --self.stopBtnText = self.view.sweepingInfoRoot.bottom.stopBtn.Text[UI.Text]
end

function sweepingInfo:initBottom()
    CS.UGUIClickEventListener.Get(self.view.sweepingInfoRoot.bottom.stopBtn.gameObject).onClick = function()
        if self.sweepFlag then
            self.sweepFlag = false
            self.view.sweepingInfoRoot.bottom.finishBtn:SetActive(true)
            self.view.sweepingInfoRoot.bottom.stopBtn:SetActive(false)
            --self.stopBtnText:TextFormat("扫荡完成")
            self:initAllGiftItem()
        else
            DialogStack.Pop()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.sweepingInfoRoot.bottom.finishBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.sweepingInfoRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
end

function sweepingInfo:addGiftTab(data)
    for i,v in ipairs(data) do
        if v[2] ~= 90001 and v[2] ~= 90000 then
            if v[1] == 43 then
                table.insert(self.allGiftTab,v)
            else
                if self.allGiftTab[v[2]] then
                    self.allGiftTab[v[2]][3] = self.allGiftTab[v[2]][3] + v[3]
                else
                    self.allGiftTab[v[2]] = v
                end
            end
        end
    end
end

function sweepingInfo:getGiftTab()
    local _tab = {}
    for k,v in pairs(self.allGiftTab) do
        -- if #v==3 then
        --     v[4]=nil
        -- end
        table.insert(_tab, v)
    end
    return _tab
end

function sweepingInfo:startSweeping(time)
    StartCoroutine(function()
        WaitForSeconds(time)
        if self.nowCount < self.count and self.sweepFlag  then
                --todo
            fightModule.Sweeping(self.type and self.gid[self.nowCount] or self.gid, 1)
        else
            self.sweepFlag = false
            --self.stopBtnText:TextFormat("扫荡完成")
            self.view.sweepingInfoRoot.bottom.finishBtn:SetActive(true)
            self.view.sweepingInfoRoot.bottom.stopBtn:SetActive(false)
            self:initAllGiftItem()
        end
    end)
end

function sweepingInfo:OnDestroy()
    SetItemTipsState(true)
    for i,v in ipairs(self:getGiftTab()) do
        PopUpTipsQueue(1,{v[2], v[3], v[1],v[4]})
    end
end

function sweepingInfo:listEvent()
    return {
        "LOCAL_FIGHT_SWEEPING",
        "EQUIPMENT_INFO_CHANGE",
    }
end

function sweepingInfo:onEvent(event, data)
    if event == "LOCAL_FIGHT_SWEEPING" then
        self.nowCount = self.nowCount + 1
        self:upHeroRoot(data)
        self:addGiftTab(data)
        local _data={}
        local ref = true
        for i,v in ipairs(data) do
            if v[2]~=90001 and v[2]~=90000 then
                if v[4] then
                    v[4]=math.floor(v[4])
                    ref=false
                end
            end
            _data[#_data+1]=v
        end
        self.Data=_data
        
        --ERROR_LOG(sprinttb(self.Data));
        if ref then
            if self.type then
                self:addSweepingItem(_data)
            else
                self:addSweepingItem(_data)
            end
        end
        self:startSweeping(1)
        --self.allGiftScrollView.DataCount = #self:getGiftTab()
    elseif event == "EQUIPMENT_INFO_CHANGE" then
            for i,v in ipairs(self.Data) do
                if v[4]==data then
                    self:addSweepingItem(self.Data)
                end
            end
        
    end
end

return sweepingInfo
