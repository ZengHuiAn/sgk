local PlayerModule = require "module.playerModule"
local traditionalArenaModule = require "module.traditionalArenaModule"

local View={};
function View:Start(rankType)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view = self.root.view

    self.callback = function ( ... )
        traditionalArenaModule.QueryJoinArena()
    end

    self.Pid = module.playerModule.GetSelfID();
    self.pidsList = {}
    self.animList = {}

    self:initUi()
    
    self:showRewardTip()
    self.CurrChat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.root.transform)
end

local shopId = 12
function View:initUi()
    CS.UGUIClickEventListener.Get(self.view.helpBtn.gameObject, true).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("chuantongjjc_01"),SGK.Localize:getInstance():getValue("zhaomu_shuoming_01"), self.root)
    end

    CS.UGUIClickEventListener.Get(self.view.formationBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact('FormationDialog', {type = 4}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"));  
    end

    CS.UGUIClickEventListener.Get(self.view.recordBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("traditionalArena/replayFrame");
    end 

    CS.UGUIClickEventListener.Get(self.view.rewardBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("traditionalArena/rewardFrame");
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.buyBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("traditionalArena/addFightNumFrame");
    end
    CS.UGUIClickEventListener.Get(self.view.shopBtn.gameObject).onClick = function()
        self.resetTopResourcesIcon = true
        DialogStack.Push("ShopFrame",{index = shopId,DoResetTopResourcesIcon =true })
    end
    CS.UGUIClickEventListener.Get(self.view.shareBtn.weixing.gameObject).onClick=function()
        DialogStack.PushPrefStact("shareFrame",{name="athletics"},UnityEngine.GameObject.Find("mapSceneUI(Clone)/UGUITopRoot"))
    end

    self:updatePlayerArenaInfo()
end

local challengeItemId = 90169
function View:updatePlayerArenaInfo()
    local _count = module.ItemModule.GetItemCount(challengeItemId)
    self.view.bottom.challenge_times[UI.Text].text = string.format("%s/6",_count)

    self.view.bottom.buyBtn:SetActive(_count<=0)

    self.view.bottom.refreshBtn:SetActive(_count>0)
    CS.UGUIClickEventListener.Get(self.view.bottom.refreshBtn.gameObject).onClick = function()
        traditionalArenaModule.Refresh()
    end 
end

function View:showRewardTip()
    local rewardTipPanel = self.view.bottom.rewardTip.view
    if self.playerInfo then
        print(sprinttb(self.playerInfo))
        local pos = self.playerInfo.pos
        local rewardsCfg = traditionalArenaModule.GetRewardsCfg(pos).rewards
        print(sprinttb(rewardsCfg))
        for i=1,rewardTipPanel.rewards.transform.childCount do
            rewardTipPanel.rewards.transform:GetChild(i-1).gameObject:SetActive(false)
        end

        for i=1,#rewardsCfg do
            local item = traditionalArenaModule.GetCopyUIItem(rewardTipPanel.rewards,rewardTipPanel.rewards.Item,i)
            local _rewardCfg = rewardsCfg[i]
            utils.IconFrameHelper.Create(item.IconFrame,{type = _rewardCfg.type, id = _rewardCfg.id, count = _rewardCfg.count,showDetail=true})
        end
    end
end

function View:updateRankList(data)
    self.rankInfo = data
    local rankList = {}

    if data.list and next(data.list)~=nil then
        for k,v in pairs(data.list) do
            table.insert(rankList,v)
        end
    end
    
    if data.CanAttackList and next(data.CanAttackList) then
        for k,v in pairs(data.CanAttackList) do
            if not data.list or not data.list[k] then
               table.insert(rankList,v) 
            end
        end
    end

    if not data.list or not data.list[self.Pid] then
        table.insert(rankList,data.selfInfo)
    end

    table.sort(rankList,function(a,b)
        return a.pos < b.pos
    end)

    for i=1,#rankList do
        self.pidsList[rankList[i].pid] = self.pidsList[rankList[i].pid] or {}
        self.pidsList[rankList[i].pid].pos = i
    end
    if rankList[11] then
        self.cloud = rankList[11].pos > 11
        -- print("cloud-------",self.cloud,rankList[11].pos,type(rankList[11].pos))
    end
    self.localRankList = rankList

    local item_first = self.view.ScrollView.Viewport.Content.rankItem_first[UnityEngine.RectTransform].rect.height
    local item_y = self.view.ScrollView.rankItem[UnityEngine.RectTransform].rect.height

    self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,770+item_y*(#rankList-1))
    for i=1,#rankList do
        -- print(i,sprinttb(rankList[i]))
        local item = traditionalArenaModule.GetCopyUIItem(self.view.ScrollView.Viewport.Content,self.view.ScrollView.rankItem,i)
        if item then
            if i == 1 then
                if item.Image.fx_node.transform.childCount == 0 then
                    self:playEffect("fx_jjc_first", Vector3.zero,item.Image.fx_node.transform)
                end 
            end
            
            self:upRankPlayerInfo(i,rankList[i],item.Image)
        end
    end

    local firstItem_y = self.view.ScrollView.Viewport.Content.rankItem_first[UnityEngine.RectTransform].rect.height
    
    local _y = firstItem_y + item_y*(self.pidsList[self.Pid].pos-1)

    local ScreenHeight = UnityEngine.Screen.height /  UnityEngine.Screen.width * 750;

    if _y - ScreenHeight >0 then
        self.view.ScrollView.Viewport.Content.transform.localPosition=Vector3(0, _y-ScreenHeight+200,0)
    end

    self.view.ScrollView.topArrow:SetActive(_y - ScreenHeight >0)
    self.view.ScrollView.bottomArrow:SetActive(_y - ScreenHeight <=0)
    module.guideModule.PlayByType(119,0.2)
    
    self.view.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function (value)
        local off_y = self.view.ScrollView.Viewport.Content.transform.localPosition.y
        local total_y = self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].rect.height
        self.view.ScrollView.topArrow:SetActive(off_y > item_y )
        self.view.ScrollView.bottomArrow:SetActive(off_y < total_y - ScreenHeight)
    end)
end


local selfPosFxTab = {"fx_jjc_First1","fx_JJC_Second","fx_JJC_Second","fx_JJC_juese"}
function View:upRankPlayerInfo(_pos,_rankInfo,item)
    local pos = _rankInfo.pos
    local pid = _rankInfo.pid
    local capacity = _rankInfo.capacity
    if pos~=1 then
        local _off_x = -150--self.view.ScrollView.rankItem.Image.transform.localPosition.x
        _off_x = _pos%2~=0 and -_off_x or _off_x
        item.transform.localPosition = Vector3(_off_x,0,0)
        item.capacity_left:SetActive(_pos%2==0)
        item.capacity_right:SetActive(_pos%2~=0)
    else
        item.capacity_left:SetActive(true)
        item.capacity_right:SetActive(false)
    end

    item.capacity_left.Text[UI.Text].text = capacity
    item.capacity_right.Text[UI.Text].text = capacity 


    item.rankMark.Text:SetActive(pos> 3)
    if pos<= 3 then
        item[CS.UGUISpriteSelector].index = pos -1
        item.rankMark[CS.UGUISpriteSelector].index = pos -1
    elseif pos> 3 and pos<= 10 then
        item[CS.UGUISpriteSelector].index = 3
        item.rankMark[CS.UGUISpriteSelector].index = 3
        item.rankMark.Text[UI.Text].text = pos
    else
        item[CS.UGUISpriteSelector].index = 4
        item.rankMark[CS.UGUISpriteSelector].index = 4
        item.rankMark.Text[UI.Text].text = pos
    end
    for i = 1,item.pos_fx_node.transform.childCount do  
        UnityEngine.GameObject.Destroy(item.pos_fx_node.transform:GetChild(i-1).gameObject)
    end
    if pid == self.Pid then
        local fx_name = pos<=3 and selfPosFxTab[pos] or selfPosFxTab[4]
        self:playEffect(fx_name, Vector3.zero,item.pos_fx_node.transform)
    end
    if self.cloud then
        if _pos == 10 then
            self:playEffect("fx_ui_jjc_cloud", Vector3(0,-115,0),item.pos_fx_node.transform)
        elseif _pos > 10 then
            item[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(item[UnityEngine.RectTransform].anchoredPosition.x,-200)
        end
    end
    -- self:updatePlayerShow(pid)
    
    CS.UGUIClickEventListener.Get(item.Slot.spine.gameObject,true).onClick = function()
        if pid~=self.Pid then
            local showChallenge = self.rankInfo.CanAttackList[pid] and (pid~=self.Pid)
            DialogStack.PushPrefStact("traditionalArena/defenderInfoFrame",{pid,pos,showChallenge});
        end
    end
end

function View:updatePlayerShow(pid)
    local _pos = self.pidsList[pid].pos
    if pid and pid ~= 0 then
        if pid <= 500000 then
            local _pos = self.pidsList[pid].pos
            if _pos and _pos<= self.view.ScrollView.Viewport.Content.transform.childCount then
                local _obj = self.view.ScrollView.Viewport.Content.transform:GetChild(_pos-1)
                local Slot = CS.SGK.UIReference.Setup(_obj).Image.Slot
                if Slot then
                    local playerdata = traditionalArenaModule.GetNpcCfg(pid)
                    if playerdata then
                        Slot.name[UI.Text].text = playerdata.name
                        Slot.title:SetActive(false)
                        self:upPlayerAddDataShow(pid,playerdata.icon)
                    end
                end
            end
        else
            local player = module.playerModule.Get(pid)
            if player then
                self:upPlayerDataShow(pid,player)
            end

            local playerAddData = utils.PlayerInfoHelper.GetPlayerAddData(pid,99)
            if playerAddData then
                local mode = playerAddData and playerAddData.ActorShow or 11048
                self:upPlayerAddDataShow(pid,mode,playerAddData)
            end
        end
    else
        ERROR_LOG("pid is err,",pid)
    end
end

function View:upPlayerDataShow(pid,playerData)
    local _pos = self.pidsList[pid].pos
    if _pos and _pos<= self.view.ScrollView.Viewport.Content.transform.childCount then  
        local _obj = self.view.ScrollView.Viewport.Content.transform:GetChild(_pos-1)
        local Slot = CS.SGK.UIReference.Setup(_obj).Image.Slot
        if Slot then
            Slot.name[UI.Text].text = playerData.name
            --honor 
            if playerData.honor ~=0 and (not self.pidsList[pid].honor or  self.pidsList[pid].honor ~= playerData.honor) then
                local cfg = module.honorModule.GetCfg(playerData.honor,pid);
                Slot.title:SetActive(not not cfg)
                if cfg then
                    local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(cfg.font_color);
                    
                    Slot.title.nameText:SetActive(cfg.effect_type == 0)
                    Slot.title.nameIcon:SetActive(cfg.effect_type == 1)
                
                    if cfg.effect_type == 0 then
                        Slot.title.nameText[UI.Text].text = cfg.name;
                        Slot.title.nameText[UI.Text].color = _color;
                    elseif cfg.effect_type == 1 then
                        local _showItemCfg = module.ItemModule.GetShowItemCfg(cfg.only_text)
                        if _showItemCfg then
                            local icon_id = _showItemCfg.effect
                            Slot.title.nameIcon[UI.Image]:LoadSprite("icon/"..icon_id)
                        else
                            Slot.title.nameIcon:SetActive(false)
                            ERROR_LOG("_showItemCfg is nil,id",cfg.only_text)
                        end
                    end
                else
                    ERROR_LOG("honor cfg is nil,honor",playerData.honor)
                end
            end
        end
    end
end

function View:upPlayerAddDataShow(pid,mode,playerAddData)
    local _pos = self.pidsList[pid].pos
    if _pos and _pos<= self.view.ScrollView.Viewport.Content.transform.childCount then  
        local _obj = self.view.ScrollView.Viewport.Content.transform:GetChild(_pos-1)
        if _obj then    
            local Slot = CS.SGK.UIReference.Setup(_obj).Image.Slot
            if mode and Slot then
                if not self.pidsList[pid].mode or  self.pidsList[pid].mode ~=mode then 
                    self.pidsList[pid].mode = mode
                    local SlotItem = Slot:GetComponent(typeof(CS.FormationSlotItem))
                    -- Slot.spine[Spine.Unity.SkeletonGraphic].raycastTarget = false;
                    CS.FormationSlotItem.animationName = _pos ~=1 and "idle3" or "idle1"
                    if _pos ~=1 and _pos%2==0 then
                        local _currScale = self.view.ScrollView.rankItem.Image.Slot.spine.transform.localScale
                        Slot.spine.transform.localScale = Vector3(-_currScale.x,_currScale.y,_currScale.z)
                    end
                    SlotItem:UpdateSkeleton(mode)
                end
            end
        --[[
            Slot.footPrint:SetActive(false)
            Slot.Widget:SetAcitive(false)

            for i = 1,Slot.footPrint.effect.transform.childCount do  
                UnityEngine.GameObject.Destroy(Slot.footPrint.effect.transform:GetChild(i-1).gameObject)
            end
            for i = 1,Slot.Widget.effect.transform.childCount do  
                UnityEngine.GameObject.Destroy(Slot.Widget.effect.transform:GetChild(i-1).gameObject)
            end
            self.pidsList[pid].FootEffect_Name = nil
            if playerAddData then
                local footPrint = playerAddData.FootPrint
                if footPrint then
                    Slot.footPrint:SetActive(true)
                    if not self.pidsList[pid].footPrint or  self.pidsList[pid].footPrint ~= footPrint then 
                        self.pidsList[pid].footPrint = footPrint
                        if footPrint > 0 then
                            local ShowItemCfg = module.ItemModule.GetShowItemCfg(footPrint)
                            if not ShowItemCfg then return end
                                if ShowItemCfg.sub_type == 75 then
                                    self.pidsList[pid].FootEffect_Name = "prefabs/effect/UI/"..ShowItemCfg.effect
                                else
                                    local footprint_effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..ShowItemCfg.effect)
                                    local FootEffect = CS.UnityEngine.GameObject.Instantiate(footprint_effect,Slot.footPrint.effect.transform)
                                    FootEffect.transform.localPosition = Vector3.zero
                                end
                            end
                        end
                    end
                end
                local Widget = playerAddData.Widget
                if Widget then
                    if not self.pidsList[pid].Widget or self.pidsList[pid].Widget ~= Widget then
                        self.pidsList[pid].Widget = Widget
                        if Widget > 0 then
                            local ShowItemCfg = module.ItemModule.GetShowItemCfg(Widget)
                            if not ShowItemCfg then return end
                            Slot.Widget:SetAcitive(true)
                            local Widget_effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..ShowItemCfg.effect)
                            if Widget_effect then
                                local WidgetEffect = CS.UnityEngine.GameObject.Instantiate(Widget_effect,Slot.Widget.effect.transform)
                                WidgetEffect.transform.localPosition = Vector3.zero
                            end
                        end
                    end
                end
            end
            --]]
        end
    end
end

local FootEffect_Time = 0
function View:Update()
    if self.callback then
        self.callback();
        self.callback = nil
    end

    if self.localRankList and #self.localRankList<= self.view.ScrollView.Viewport.Content.transform.childCount then
        for i=1,#self.localRankList do
            local pid = self.localRankList[i].pid
            self:updatePlayerShow(pid)
        end
        self.localRankList = nil
    end
    --[[
    FootEffect_Time = FootEffect_Time + UnityEngine.Time.deltaTime
    if FootEffect_Time >= 0.5 then
       FootEffect_Time = FootEffect_Time -0.5 

       for k,v in pairs(self.pidsList) do
            if v.FootEffect_Name then
                local _pos = v.pos
                if _pos and self.rankListUI[_pos] then
                    local Slot = CS.SGK.UIReference.Setup(self.rankListUI[_pos]).Image.Slot
                    if Slot then
                        for i = 1,Slot.footPrint.effect.transform.childCount do  
                            UnityEngine.GameObject.Destroy(Slot.footPrint.effect.transform:GetChild(i-1).gameObject)
                        end
                        local footprint_effect =self:playEffect(v.FootEffect_Name, Vector3(0, 0, -10),Slot.footPrint.effect.transform,Vector3(-45, 0, 0),100,"UI",30000)
                    end
                end
            end
        end
    end
    --]]

    if self.CurrChat then
        self.CurrChat = nil
        DispatchEvent("CurrencyRef",{4,90025})
    end
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation =rotation and Quaternion.Euler(rotation) or Quaternion.identity;
        transform.localScale = scale and scale*Vector3.one or Vector3.one
        if layerName then
            o.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            for i = 0,transform.childCount-1 do
                transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            end
        end
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function View:OnDestroy( ... )
    if not self.resetTopResourcesIcon then
        DispatchEvent("CurrencyRef")
    end
end

function View:listEvent()
    return {
        "TRADITIONAL_ARENA_PLAYERINFO_CHANGE",
        "TRADITIONAL_ARENA_RANKLIST_CHANGE",

        "TRADITIONAL_RANKINFO_CHANGE",
        
        "PLAYER_INFO_CHANGE",
        "PLAYER_ADDDATA_CHANGE",
        "SHOP_BUY_SUCCEED",
        "LOCAL_GUIDE_CHANE",

        "UPDATA_LOCALREWARD_REDDOT",
    }
end

function View:onEvent(event, data)
    if event == "TRADITIONAL_ARENA_PLAYERINFO_CHANGE"  then
        self.playerInfo = data
        self:showRewardTip()
        self.view.rewardBtn.redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.RankArena.Rewards, nil,self.view.rewardBtn.redDot))
    elseif event == "PLAYER_INFO_CHANGE"  then
        local pid = data
        if self.pidsList[pid] then
            local player = module.playerModule.Get(pid)
            if player then
                self:upPlayerDataShow(pid,player)
            end
        end
    elseif event == "PLAYER_ADDDATA_CHANGE"  then
        local pid = data
        if self.pidsList[pid] then
            local playerAddData = utils.PlayerInfoHelper.GetPlayerAddData(pid,99)
            if playerAddData then
                local mode = playerAddData and playerAddData.ActorShow or 11048
                self:upPlayerAddDataShow(pid,mode,playerAddData)
            end
        end
    elseif event == "TRADITIONAL_ARENA_RANKLIST_CHANGE"  then
        self:updateRankList(data)
    elseif event == "TRADITIONAL_RANKINFO_CHANGE" then
        local pid = data.pid
        if self.pidsList[pid] then
            local _pos = self.pidsList[pid].pos
            if _pos and _pos<= self.view.ScrollView.Viewport.Content.transform.childCount then
                local _obj = self.view.ScrollView.Viewport.Content.transform:GetChild(_pos-1)
                if _obj then
                    local item = CS.SGK.UIReference.Setup(_obj).Image
                    item.capacity_left.Text[UI.Text].text = data.capacity 
                    item.capacity_right.Text[UI.Text].text = data.capacity 
                end
            end
        end
    elseif event == "SHOP_BUY_SUCCEED" then
        self:updatePlayerArenaInfo()
    elseif event == "UPDATA_LOCALREWARD_REDDOT" then
        if not self.updateRewards then
            self.updateRewards = true
            self.gameObject.transform:DOScale(Vector3.one,0.5):OnComplete(function()
                self.view.rewardBtn.redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.RankArena.Rewards, nil,self.view.rewardBtn.redDot))
                self.updateRewards = false
            end)
        end   
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(119,0.2)
    end
end

return View
