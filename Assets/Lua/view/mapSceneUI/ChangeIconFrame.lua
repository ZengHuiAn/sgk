local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local PlayerModule = require "module.playerModule"
local ItemHelper = require "utils.ItemHelper"
local openLevel = require "config.openLevel"
local View = {}

function View:Start(data)
    self.root= CS.SGK.UIReference.Setup(self.gameObject)
    self.view =self.root.view

    self.Idx=data and data[1] or self.savedValues.ChangeIconIdx or 1
    self.selectIconFrameId=data and data[2]~=0 and data[2]

    self:UpdateUI()
end

local CanPush=true
local HeadFrameType=72
local titleLanguageTab = {"biaoti_touxianggenghuan_01","biaoti_touxiangkuang_01"}
function View:UpdateUI()
    self.iconTab =PlayerInfoHelper.GetHeadCfg()

    self.IconFrameTab=PlayerInfoHelper.GetShowItemList(HeadFrameType)
    self.nowSelectItem = self.Idx==1 and self.view.Content.itemNode.IconContent or self.view.Content.itemNode.IconFrameContent 
    
    self.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue(titleLanguageTab[self.Idx])
    for i = 1, 2 do
        self.view.Content.itemNode[i].gameObject:SetActive(false)

        self.view.Content.topTab[i+1][UI.Toggle].isOn=i==self.Idx
        self.view.Content.topTab[i+1].arrow:SetActive(i==self.Idx)
    end
    self.nowSelectItem.gameObject:SetActive(true)

    self:initTopTab()
    self:initCloseBtn()
    self:initScrollView(self.Idx)
    
end
function View:initTopTab()
    for i = 1, 2 do
        local _view = self.view.Content.topTab[i+1]
        CS.UGUIClickEventListener.Get(_view.gameObject,true).onClick = function()
            if self.nowSelectItem then
                self.nowSelectItem.gameObject:SetActive(false)
            end
            self.nowSelectItem = i==1 and self.view.Content.itemNode.IconContent or self.view.Content.itemNode.IconFrameContent  
            self.nowSelectItem.gameObject:SetActive(true)

            self.selectHeadId=nil
            self.selectIconFrameId=nil
            self:initScrollView(i)
            self.Idx=i
            for j = 1, 2 do
                self.view.Content.topTab[j+1].arrow.gameObject:SetActive(j==self.Idx)
            end
            self.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue(titleLanguageTab[self.Idx])
        end
    end
    CS.UGUIClickEventListener.Get(self.view.Content.itemNode.IconContent.ScrollView.SaveBtn.gameObject).onClick = function()
        if self.selectHeadId then
            PlayerModule.ChangeIcon(self.selectHeadId)
        else
            showDlgError(nil, "请选择需要更换的头像")
        end
        DialogStack.Pop()
    end

    PlayerInfoHelper.GetSelfBaseInfo(function (player)   
        player.vip=player.vip or 0
        self.view.Content.itemNode.IconFrameContent.ScrollView.detailInfo.IconFrame.CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
    end)

    local HeadIconFrameTab=PlayerInfoHelper.GetShowItemByActivityType(HeadFrameType)
    
    self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[1].Text[UI.Text].text="全部"
    self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[1].gameObject:SetActive(true)
    self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[1].Checkmark.gameObject:SetActive(true)

    self.SelectHeadIconFilterItem = self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[1]
    self.SelectHeadIconFilterItem.Text[UI.Text].color = {r=0,g=0,b=0,a=1}
    local i=1
    for k,v in pairs(HeadIconFrameTab) do
        i=i+1
        self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[i].gameObject:SetActive(true)
        self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[i].Text[UI.Text].text=tostring(k)
        self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[i].Checkmark.gameObject:SetActive(false)
    end
    local _Count =self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content.transform.childCount
    for i=1,_Count do
        CS.UGUIClickEventListener.Get(self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[i].gameObject).onClick = function()
            self.SelectHeadIconFilterItem.Checkmark.gameObject:SetActive(false)
            self.SelectHeadIconFilterItem.Text[UI.Text].color = {r=1,g=1,b=1,a=1}
            self.SelectHeadIconFilterItem=self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[i]
            self.SelectHeadIconFilterItem.Text[UI.Text].color = {r=0,g=0,b=0,a=1}
            self.SelectHeadIconFilterItem.Checkmark.gameObject:SetActive(true)

            if i~=1 then
                local _tab=HeadIconFrameTab[self.view.Content.itemNode.IconFrameContent.filter.Viewport.Content[i].Text[UI.Text].text]
                table.sort(_tab,function(a,b)
                    local count1=module.ItemModule.GetItemCount(a.id)
                    local count2=module.ItemModule.GetItemCount(b.id)
                    if count1~=count2 then
                        return count1>count2
                    end
                    return a.id<b.id  
                end)
                self.IconFrameTab=_tab
            else
                self.IconFrameTab=PlayerInfoHelper.GetShowItemList(HeadFrameType)
            end

            self.selectIconFrameId=nil
            self:upHeadIconShowFrame()
            self:initScrollView(_Count)
        end
    end

    self:upHeadIconShowFrame()
end

function View:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
       DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function()
       DialogStack.Pop()
    end
end

function View:initScrollView(TabIdx)
    self.ScrollViewScript = self.nowSelectItem.ScrollView[CS.UIMultiScroller]
    self.ScrollViewScript.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        if TabIdx==1 then
            PlayerInfoHelper.GetSelfBaseInfo(function (player) 
                local _tab = self.iconTab[idx+1]
                _view.ItemIcon.CheckMark.gameObject:SetActive(false)

                utils.IconFrameHelper.Create(_view.ItemIcon.IconFrame,{customCfg={icon=_tab.icon,star=0,role_stage=0,level=0},type=ItemHelper.TYPE.HERO,func = function(itemIcon)
                    -- itemIcon.Frame:SetActive(false)
                end})

                _view.ItemIcon.lock.gameObject:SetActive(_tab.isLocked)

                local headIcon=player.head~=0 and player.head or 11000
                self.selectHeadId=self.selectHeadId or headIcon
                if _tab.icon==self.selectHeadId then
                    self.selectHeadId=_tab.icon
                    self.selectHeadItem =_view.ItemIcon.CheckMark.gameObject
                    self.selectHeadItem:SetActive(true)
                end

                CS.UGUIClickEventListener.Get(_view.ItemIcon.gameObject).onClick = function()
                    if self.selectHeadItem and self.selectHeadItem~=_view.ItemIcon.CheckMark.gameObject  then
                        self.selectHeadItem:SetActive(false)
                    end
                    self.selectHeadItem =_view.ItemIcon.CheckMark.gameObject
                    self.selectHeadItem:SetActive(true)
                    self.selectHeadId = _tab.icon
                    if _tab.isLocked then
                        if _tab.hero==1 then
                            local item=ItemHelper.Get(ItemHelper.TYPE.ITEM,_tab.icon+10000)
                            DispatchEvent("OnClickItemIcon",item,{[0]=2,[1]=0})
                        else
                            showDlgError(nil,"暂无获取途径")
                        end
                    end
                    self.view.Content.itemNode.IconContent.ScrollView.SaveBtn[CS.UGUIClickEventListener].interactable =not _tab.isLocked
                end  
            end)
        else
            PlayerInfoHelper.GetPlayerAddData(0,2,function (playerAddData) 
                -- self.addData=playerAddData
                local _tab = self.IconFrameTab[idx+1]
                _view.ItemIcon.ItemIcon[SGK.ItemIcon]:SetInfo(_tab)
                _view.ItemIcon.ItemIcon[SGK.ItemIcon].Count = 0

                _view.ItemIcon.mark.gameObject:SetActive(module.ItemModule.GetItemCount(_tab.id)<1)
                _view.ItemIcon.CheckMark.gameObject:SetActive(false)
               
                self.selfHeadFrameId = playerAddData.HeadFrameId
                self.selectIconFrameId = self.selectIconFrameId or (self.selfHeadFrameId and self.selfHeadFrameId~= 0 and self.selfHeadFrameId or _tab.id)
                if self.selectIconFrameId == _tab.id then
                    self.selectIconFrameItem =_view.ItemIcon.CheckMark.gameObject
                    self.selectIconFrameItem:SetActive(true)
                    self.selectIconFrameId = _tab.id
                    self:upHeadIconShowFrame()
       

                end
                CS.UGUIClickEventListener.Get(_view.ItemIcon.gameObject).onClick = function()
                    if self.selectIconFrameItem and self.selectIconFrameItem ~=_view.ItemIcon.CheckMark.gameObject then
                        self.selectIconFrameItem:SetActive(false)
                    end
                    self.selectIconFrameItem =_view.ItemIcon.CheckMark.gameObject
                    self.selectIconFrameItem:SetActive(true)
                    self.selectIconFrameId = _tab.id
                    self:upHeadIconShowFrame()
                end
            end)
        end
        obj.gameObject:SetActive(true)
    end
    self.ScrollViewScript.DataCount =TabIdx==1 and  #self.iconTab or #self.IconFrameTab
end

function View:upHeadIconShowFrame()
    local infoPanel=self.view.Content.itemNode.IconFrameContent.ScrollView.detailInfo
    infoPanel.name.gameObject:SetActive(not not self.selectIconFrameId)
    infoPanel.desc.gameObject:SetActive(not not self.selectIconFrameId)
    infoPanel.IconFrame.playerFrame.gameObject:SetActive(not not self.selectIconFrameId)
    if self.selectIconFrameId then
        for i=1, #self.IconFrameTab do
            if self.selectIconFrameId==self.IconFrameTab[i].id then
                local headIconCfg=self.IconFrameTab[i]
                infoPanel.IconFrame.playerFrame[UI.Image]:LoadSprite("icon/"..headIconCfg.effect)
                infoPanel.name[UI.Text].text=tostring(headIconCfg.name)
                infoPanel.desc[UI.Text].text=tostring(headIconCfg.info)
                local count=module.ItemModule.GetItemCount(headIconCfg.id)
        
                infoPanel.useBtn.gameObject:SetActive(self.selfHeadFrameId~=headIconCfg.id)

                infoPanel.useBtn.Text[UI.Text].text = count>=1 and "使用" or "去获取"
                CS.UGUIClickEventListener.Get(infoPanel.useBtn.gameObject).onClick = function()
                    if count < 1 then 
                        local _sourceCfg = module.ItemModule.GetItemSource(headIconCfg.id)
                        if _sourceCfg and _sourceCfg[1] then
                            DialogStack.Pop()
                            utils.GuideHelper.Go(_sourceCfg[1].from,_sourceCfg[1].sub_from)
                        else
                            showDlgError(nil,"暂无获取途径")
                        end
                    else
                        self.localChangeHeadId=headIconCfg.id
                        PlayerInfoHelper.ChangeHeadFrame(self.localChangeHeadId)
                    end
                end

                infoPanel.unUseBtn.gameObject:SetActive(self.selfHeadFrameId==headIconCfg.id)
                CS.UGUIClickEventListener.Get(infoPanel.unUseBtn.gameObject).onClick = function()
                    self.localChangeHeadId=0
                    PlayerInfoHelper.ChangeHeadFrame(self.localChangeHeadId)
                end
            end
        end 
    end

    --infoPanel.useBtn.gameObject:SetActive(not not self.selectIconFrameId)
end

function View:OnDestroy( ... )
    self.savedValues.ChangeIconIdx=self.Idx;
    self.selectIconFrameItem=nil
end

function View:listEvent()
    return {
        "PLAYER_ADDDATA_CHANGE_SUCCED",
        "OPEN_SHOP_INFO_RETURN",
    }
end

function View:onEvent(event,data)
    if event == "PLAYER_ADDDATA_CHANGE_SUCCED" then
        if data and self.localChangeHeadId and data== self.localChangeHeadId then
            showDlgError(nil,data==0 and "移除成功" or "更换成功 ")
            self.localChangeHeadId=nil
            self.selfHeadFrameId =data~=0 and data
            if data==0 then
                if self.selectIconFrameItem then
                    self.selectIconFrameItem:SetActive(false)
                end
                
                self.selectIconFrameId=nil
                self.view.Content.itemNode.IconFrameContent.ScrollView.detailInfo.unUseBtn.gameObject:SetActive(false)
            end
            self:upHeadIconShowFrame()

        end
    elseif event == "OPEN_SHOP_INFO_RETURN" then
        if CanPush then
            CanPush=false
            if module.ShopModule.GetOpenShop(self.Shop_id) and data then
                if openLevel.GetStatus(2401)then
                    DialogStack.Push("ShopFrame",{index =self.Shop_id});
                else
                    showDlgError(nil,"等级不足")
                end
            else
                showDlgError(nil,"商店未开放");
            end
        end
    end
end

return View
