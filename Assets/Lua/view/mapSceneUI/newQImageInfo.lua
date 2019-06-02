local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local PlayerModule = require "module.playerModule"
local ShopModule = require "module.ShopModule"
local openLevel = require "config.openLevel"
local View = {}

local typeIdx={[1]=1,[73]=2,[74]=3,[99]=4,[70]=4,[75]=4,[76]=5}--{[73]=2,[99]=3,[70]=3,[75]=3,[76]=4}--99[足迹 75 光环70]   
local ItemIdxTabType={1,73,74,99,76}--传参用{1,73,99,76}
local showItemTypeTab={74,99,76}--{99,76}--挂件足迹气泡框--99[足迹 75 光环70]
local addDataType={[74]="Widget",[70]="FootPrint",[75]="FootPrint",[99]="FootPrint",[76]="Bubble",[1]="ActorShow"}
local topPageTab={"形象","头衔","挂件","足迹","气泡"}--{"Q信息","头衔","足迹","气泡框"}--
function View:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject).view

    self.UIDragIconScript=self.view.bottom.itemNode.ScrollView.Viewport.Content[CS.ScrollViewContent]
    -- self.UIDragIconScript.DisableMoveTween=false;
    --self:CreatePlayer()
    self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
        self:refreshData(obj,idx)
    end)

    self.UIDragHonorScript=self.view.bottom.itemNode.HonorScrollView.Viewport.Content[CS.ScrollViewContent]
    self.UIDragHonorScript.RefreshIconCallback = (function (obj,idx)
        self:refreshData(obj,idx)
    end)

    self.UIDragShowItemScript=self.view.bottom.itemNode.ShowItemScrollView.Viewport.Content[CS.ScrollViewContent]
    self.UIDragShowItemScript.RefreshIconCallback = (function (obj,idx)
        self:refreshData(obj,idx)
    end)

    self.localSelectTabIdx={}

    self.view.top.ShowSelect.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
    	self:UpdataEffectShow()
    end)

    self.FootEffect_Time = 0

    for i=1,#topPageTab do
        CS.UGUIClickEventListener.Get(self.view.bottom.topTab.Viewport.Content[i].gameObject,true).onClick = function()
            self.selected_tab=i
            self:UpdateSelection()
            self.view.bottom.topTab.Viewport.Content[i][UI.Toggle].isOn=true
            DispatchEvent("PLAYER_INFO_IDX_CHANGE",{ItemIdxTabType[i],self.localSelectTabIdx})
        end
        self.view.bottom.topTab.Viewport.Content[i].gameObject:SetActive(true)
        --self.view.bottom.topTab.Viewport.Content[i].Text[UI.Text].text=tostring(topPageTab[i])
    end  
end
function  View:CreatePlayer()
    self.qPlayerNode = CS.UnityEngine.GameObject.Find("qPlayerNode(Clone)")
    if not self.qPlayerNode then
        local prefab = SGK.ResourcesManager.Load("prefabs/mapSceneUI/qPlayerNode.prefab")
        local Node = CS.UnityEngine.GameObject.Instantiate(prefab)
        self.qModule = CS.SGK.UIReference.Setup(Node)
    end
end

function View:UpdateSpine(mode)
    -- if self.qModule and self.qModule[SGK.LuaBehaviour] then
    --     self.qModule[SGK.LuaBehaviour]:Call("UpdateSpine",mode);
    -- end

	local SlotItem=self.view.top.Slot:GetComponent(typeof(CS.FormationSlotItem))
	SlotItem:UpdateSkeleton(mode) 
end

function View:Init(data,_select_id)
    self.selected_tab=data and (data~=1 and typeIdx[data]) or 1
    self.selected_Id=_select_id

    self.view.bottom.topTab.Viewport.Content[self.selected_tab][UI.Toggle].isOn=true
    
    local _cellX=self.view.bottom.topTab.Viewport.Content[self.selected_tab][UnityEngine.RectTransform].sizeDelta.x
    local _totalWidth=self.view.bottom.topTab[UnityEngine.RectTransform].rect.width
    local _moveOff=math.max(0,_cellX*self.selected_tab-_totalWidth)
    self.view.bottom.topTab.Viewport.Content.transform.localPosition=Vector3(-_moveOff,0,0)

    for i=1,5 do
        if self.selected_tab==i  and self.selected_Id then--跳转选中
            self.localSelectTabIdx[i]=self.selected_Id
        end
    end

    self:UpPlayerData()
    self:UpPlayerAddData() 
    self:UpdateSelection() 
end

function View:UpPlayerData()
    PlayerInfoHelper.GetSelfBaseInfo(function (player)
        self.player=player
        --有上次选中头衔显示上次选中,否则显示自身
        self.localSelectTabIdx[2] =self.localSelectTabIdx[2] or (player.honor~=0 and player.honor) or (module.HonorModule.GetSelfHonorList()[1] and module.HonorModule.GetSelfHonorList()[1].gid or 0)
        local honorConfig=module.HonorModule.GetCfg(self.localSelectTabIdx[2])
        self:upTopHonorShow(honorConfig)
        self:upPlayerHonorShow(honorConfig)
        if self.selected_tab==1 and self.UIDragIconScript.DataCount~=0 then
            self.UIDragIconScript:ItemRef()  
        end
        if self.selected_tab==2 and self.UIDragHonorScript.DataCount~=0 then
            self.UIDragHonorScript:ItemRef() 
        end
    end)
end

local pageTabIdx={[1]=1,[3]=74,[4]=99,[5]=76}
function View:UpPlayerAddData()
    PlayerInfoHelper.GetPlayerAddData(0,nil,function (addData)
        if self.view then
            self.playerAddData=addData
            for idx,TabType in pairs(pageTabIdx) do
            	self.localSelectTabIdx[idx] =self.localSelectTabIdx[idx] or self.playerAddData[addDataType[TabType]] or 0
            	if idx~= 1 then
            		self.localSelectTabIdx[idx] =self.localSelectTabIdx[idx]~=0 and self.localSelectTabIdx[idx]-- or PlayerInfoHelper.GetShowItemList(showItemTypeTab[idx-2])[1].id
            	end

                local ShowItemCfg = nil
                if addDataType[idx]== "ActorShow" then
                    ShowItemCfg = PlayerInfoHelper.GetModeCfg(self.localSelectTabIdx[idx])
                    if ShowItemCfg then
                        self:UpdateSpine(tostring(ShowItemCfg.mode)) 
                    else
                        ERROR_LOG(" mode cfg is nil",self.localSelectTabIdx[idx])
                    end
                else 
                    ShowItemCfg = module.ItemModule.GetShowItemCfg(self.localSelectTabIdx[idx])
                    self:upTopShowItemShow(ShowItemCfg,idx)
                end
                self:upShowItemInfo(ShowItemCfg)
            end

            if self.UIDragShowItemScript.DataCount~=0 then
                self.UIDragShowItemScript:ItemRef()
            end
        end
    end)
end

function View:UpdataEffectShow()
	self.view.top.ShowSelect.Toggle.tip.Text[UI.Text].text=self.selected_tab ==1 and "屏蔽预览" or "屏蔽其它"
	local status=not self.view.top.ShowSelect.Toggle[UI.Toggle].isOn

	self.view.top.Slot.title.gameObject:SetActive(self.selected_tab ==2 and self.localSelectTabIdx[2]~=0 or status and self.localSelectTabIdx[2]~=0)
	self.view.top.Slot.Widget.gameObject:SetActive(self.selected_tab ==3 and self.localSelectTabIdx[3]~=0 or status and self.localSelectTabIdx[3]~=0)
	self.view.top.Slot.footPrint.gameObject:SetActive(self.selected_tab ==4 and self.localSelectTabIdx[4]~=0 or status and self.localSelectTabIdx[4]~=0)
	self.view.top.Slot.bubble.gameObject:SetActive(self.selected_tab ==5 and self.localSelectTabIdx[5]~=0 or status and self.localSelectTabIdx[5]~=0)

--[[qModule
	self.view.top.Slot.title.gameObject:SetActive(self.selected_tab ==2 and self.localSelectTabIdx[2]~=0 or status and self.localSelectTabIdx[2]~=0)
    local itemWidgetCfg=module.ItemModule.GetShowItemCfg(self.localSelectTabIdx[3])
	self.view.top.Slot.Widget.gameObject:SetActive((self.selected_tab ==3 and itemWidgetCfg and itemWidgetCfg.effect_type==1) or (status and itemWidgetCfg and itemWidgetCfg.effect_type==1))
	local itemFootPrintCfg=module.ItemModule.GetShowItemCfg(self.localSelectTabIdx[4])
    
    self.view.top.Slot.footPrint.gameObject:SetActive((self.selected_tab ==4 and itemFootPrintCfg and itemFootPrintCfg.effect_type==1) or (status and itemFootPrintCfg and itemFootPrintCfg.effect_type==1))
    self.view.top.Slot.bubble.gameObject:SetActive(self.selected_tab ==5 and self.localSelectTabIdx[5]~=0 or status and self.localSelectTabIdx[5]~=0)
    
    self.qModule[SGK.LuaBehaviour]:Call("UpdateWidget",status and itemWidgetCfg)
    self.qModule[SGK.LuaBehaviour]:Call("UpdateFootPrint",status and itemFootPrintCfg);
    --]]
end

function View:UpdateSelection()
    local sub_tab  = self.selected_tab  or 1;
    self.SelectIdx=nil
    self.LastSelctHonorItem=nil

    local itemList={}
    if sub_tab==1  then
        itemList = PlayerInfoHelper.GetModeCfg()
    elseif sub_tab==2 then
        itemList = module.HonorModule.GetSelfHonorList()
    else
        itemList = PlayerInfoHelper.GetShowItemList(showItemTypeTab[sub_tab-2])
    end

    self.selected_tab=sub_tab
    self:initScroll(itemList);

    self:UpdataEffectShow()
end

function View:initScroll(itemList)
    self.itemList=itemList
    local item=nil
    self.idx=0

    self.view.bottom.itemNode.ScrollView:SetActive(self.selected_tab == 1)
    self.view.bottom.itemNode.HonorScrollView:SetActive(self.selected_tab == 2)
    self.view.bottom.itemNode.ShowItemScrollView:SetActive(self.selected_tab ~= 1  and self.selected_tab ~= 2)

    local _ScrollView=nil
    if self.selected_tab == 2  then--头衔
        _ScrollView=self.view.bottom.itemNode.HonorScrollView.Viewport.Content
        item = _ScrollView.Item.ItemTitle.gameObject;
        local _honorCfg=module.HonorModule.GetCfg(self.localSelectTabIdx[self.selected_tab])
        self:upPlayerHonorShow(_honorCfg)
   
        if _honorCfg then
            for i=1,#itemList do
                local _cfg=itemList[i].special<9999 and 1000 or itemList[i].gid
                if  _cfg ==self.localSelectTabIdx[self.selected_tab] then
                    self.idx=i-1
                end
            end
        end
    else
        if self.selected_tab == 1 then
            _ScrollView=self.view.bottom.itemNode.ScrollView.Viewport.Content
        else
            _ScrollView=self.view.bottom.itemNode.ShowItemScrollView.Viewport.Content
        end

        local _itemInfoCfg=module.ItemModule.GetShowItemCfg(self.localSelectTabIdx[self.selected_tab])
        self:upShowItemInfo(_itemInfoCfg)--刷新Tip显示
        --self.UIDragIconScript.itemPrefab=self.view.bottom.itemNode.ScrollView.Viewport.Content.Item.ItemElse.gameObject;
        item=_ScrollView.Item.ItemElse.gameObject;

        for i=1,#self.itemList do
            local _cfg=self.itemList[i]
            if (self.selected_tab~=1 and self.localSelectTabIdx[self.selected_tab]==_cfg.id) or (self.localSelectTabIdx[self.selected_tab]==_cfg.mode) then
                self.idx=i-1
            end
        end
    end

    _ScrollView[CS.ScrollViewContent].DataCount= #itemList
    if self.selected_tab == 1  or self.selected_tab == 2 then
        --local move_y = _ScrollView[CS.ScrollViewContent].cellHeight*math.ceil((self.idx+1)/_ScrollView[CS.UIMultiScroller].maxPerLine)
        local move_y = _ScrollView[CS.ScrollViewContent].cellSize.y*math.ceil((self.idx+1)/_ScrollView[CS.ScrollViewContent].constraintCount)
        local _y = move_y-_ScrollView[UnityEngine.RectTransform].rect.height
        if _y > 0 then
            _ScrollView.transform.localPosition = Vector3(0,_y,0)
        end
    else
        --local move_x=_ScrollView[CS.UIMultiScroller].cellWidth*math.ceil((self.idx+1)/_ScrollView[CS.UIMultiScroller].maxPerLine)
        local move_x = _ScrollView[CS.ScrollViewContent].cellSize.x*math.ceil((self.idx+1)/_ScrollView[CS.ScrollViewContent].constraintCount)
        local _x = move_x-_ScrollView[UnityEngine.RectTransform].rect.width
        if _x>0 then
            _ScrollView.transform.localPosition=Vector3(-_x,0,0)
        end
    end
end

function  View:refreshData(Obj,idx)
    local Item=CS.SGK.UIReference.Setup(Obj);
    Item.gameObject:SetActive(true);

    if self.selected_tab==2 then
        local honorConfig =self.itemList[idx+1]
        local _TitleItem=Item.ItemTitle 
        _TitleItem:SetActive(not not honorConfig)      
        --如果默认 选中为 公会职务 则公会职务匹配 
        if honorConfig then
            local _realHonorId=honorConfig.special<9999 and 1000 or honorConfig.gid
            --ERROR_LOG(self.localSelectTabIdx[self.selected_tab],honorConfig.gid,_realHonorId)
            _TitleItem.ItemIcon.title.Text[UI.Text].text = tostring(honorConfig.name)
            _TitleItem.ItemIcon.checkMark.gameObject:SetActive(self.localSelectTabIdx[self.selected_tab]==honorConfig.gid)
            if self.localSelectTabIdx[self.selected_tab]==_realHonorId or self.localSelectTabIdx[self.selected_tab]==honorConfig.gid then
                self.SelectIdx=idx
                self:upPlayerHonorShow(honorConfig,idx)
            end
            _TitleItem.ItemIcon.selectArrow:SetActive(self.localSelectTabIdx[self.selected_tab]==_realHonorId or self.localSelectTabIdx[self.selected_tab]==honorConfig.gid)
            
            CS.UGUIClickEventListener.Get(_TitleItem.ItemIcon.gameObject).onClick = function (obj)
                self.localSelectTabIdx[2]=honorConfig.special<9999 and 1000 or honorConfig.gid
                DispatchEvent("PLAYER_INFO_IDX_CHANGE",{ItemIdxTabType[self.selected_tab],self.localSelectTabIdx})
                self:upTopHonorShow(honorConfig)
                self:upPlayerHonorShow(honorConfig,idx)
            end
        end
    else
        local ShowItemCfg = self.itemList[idx+1]
        local item=Item.ItemElse

        item:SetActive(not not ShowItemCfg)
        if ShowItemCfg then
            if ShowItemCfg.mode then
                utils.IconFrameHelper.Create(item.ItemIcon.IconFrame,{customCfg={icon=ShowItemCfg.icon,type=42,level=0,role_stage=0,star=0},func = function (itemIcon)
                    -- itemIcon.Frame:SetActive(false)
                end})                 
            else
                utils.IconFrameHelper.Create(item.ItemIcon.IconFrame,{customCfg=setmetatable({count=0},{__index=ShowItemCfg})})
                item.Name[UI.Text].text=tostring(ShowItemCfg.name)
            end
            item.Name.gameObject:SetActive(not ShowItemCfg.mode)
            item.ItemIcon.lock.gameObject:SetActive(ShowItemCfg.isLocked)

            item.ItemIcon.checkMark.gameObject:SetActive(false)--self.localSelectTabIdx[self.selected_tab] and self.localSelectTabIdx[self.selected_tab]==ShowItemCfg.id or self.localSelectTabIdx[self.selected_tab]==ShowItemCfg.mode or false) 
            if (self.selected_tab~=1 and self.localSelectTabIdx[self.selected_tab]==ShowItemCfg.id) or (self.localSelectTabIdx[self.selected_tab]==ShowItemCfg.mode) then
                self.SelectIdx=idx
                self:upShowItemInfo(ShowItemCfg,idx)
            end

            CS.UGUIClickEventListener.Get(item.ItemIcon.gameObject).onClick = function (obj)
                self.localSelectTabIdx[self.selected_tab] = ShowItemCfg.mode and ShowItemCfg.mode or ShowItemCfg.id
                DispatchEvent("PLAYER_INFO_IDX_CHANGE",{ItemIdxTabType[self.selected_tab],self.localSelectTabIdx})
                self:upShowItemInfo(ShowItemCfg,idx)
            end
        end
    end
end

function View:upTopHonorShow(honorConfig)
    self.view.top.Slot.title:SetActive(not not honorConfig)
    if honorConfig then
        local _show_type=tonumber(honorConfig.effect_type)
        self.view.top.Slot.title.nameText.gameObject:SetActive(_show_type==0)
        self.view.top.Slot.title.nameIcon.gameObject:SetActive(_show_type==1)
        if _show_type==0 then
            self.view.top.Slot.title.nameText[UI.Text].text=tostring(honorConfig.name)
            local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(honorConfig.font_color);
            self.view.top.Slot.title.nameText[UI.Text].color = _color;
        elseif _show_type==1 then
            local _showItemCfg=module.ItemModule.GetShowItemCfg(honorConfig.only_text)
            if _showItemCfg then
                self.view.top.Slot.title.nameIcon[UI.Image]:LoadSprite("icon/".._showItemCfg.effect)
            else
                self.view.top.Slot.title.nameIcon:SetActive(false)
                ERROR_LOG("showItem is nil",honorConfig.only_text)
            end
        end
    else     
        self.view.top.Slot.title.nameIcon.gameObject:SetActive(false)
        self.view.top.Slot.title.nameText.gameObject:SetActive(false)
    end
end

function View:upPlayerHonorShow(cfg,idx)
    local obj=nil
    if self.SelectIdx then
        obj=self.UIDragHonorScript:GetItem(self.SelectIdx)
        if obj then
            local _selectItem = SGK.UIReference.Setup(obj);
            _selectItem.ItemTitle.ItemIcon.checkMark:SetActive(false)
            _selectItem.ItemTitle.ItemIcon.selectArrow:SetActive(false)
        end
    end

    if idx then
        obj=self.UIDragHonorScript:GetItem(idx)
        if obj then
            local _selectItem = SGK.UIReference.Setup(obj);
            _selectItem.ItemTitle.ItemIcon.checkMark:SetActive(true)
            _selectItem.ItemTitle.ItemIcon.selectArrow:SetActive(true)
        end
        self.SelectIdx=idx
    end

    local InfoText=self.view.bottom.itemNode.HonorScrollView.right.InfoText.Text
    if cfg then
        local _start = nil
        local _end = nil
        if cfg.show_deadtime and cfg.show_deadtime > 0 and  cfg.end_time and cfg.end_time > 0 then
            local _startTime = os.date("*t", cfg.show_deadtime)
            _start = _startTime.year..".".._startTime.month..".".._startTime.day
            -- local _endTime = os.date("*t", cfg.end_time)
            -- _end = _endTime.year..".".._endTime.month..".".._endTime.day
        end
        -- if _end and _start then
            -- InfoText[UI.Text]:TextFormat("称谓信息:{0}\n称谓获得方式:{1}\n过期时间:{2} - {3}", cfg.des, cfg.access_way, _start, _end);
        if _start then
           InfoText[UI.Text]:TextFormat("称谓信息:{0}\n称谓获得方式:{1}\n过期时间:{2}", cfg.des, cfg.access_way, _start);
        else
            InfoText[UI.Text]:TextFormat("称谓信息:{0}\n称谓获得方式:{1}", cfg.des, cfg.access_way)
        end
    else
        InfoText[UI.Text].text ="暂无选中头衔";
    end
    --公会职务
    local _realHonorId=cfg and (cfg.special<9999 and 1000 or cfg.gid) or 0
    --使用头衔
    self.view.bottom.itemNode.HonorScrollView.right.titleBtns.UseBtn.gameObject:SetActive(cfg and _realHonorId~=self.player.honor)
    CS.UGUIClickEventListener.Get(self.view.bottom.itemNode.HonorScrollView.right.titleBtns.UseBtn.gameObject).onClick = function()
        if cfg.gid ~= 0 then
            self.view.bottom.itemNode.HonorScrollView.right.titleBtns.UseBtn[CS.UGUIClickEventListener].interactable=false
            PlayerModule.ChangeHonor(_realHonorId);
        end  
    end
    --卸下---参数0
    self.view.bottom.itemNode.HonorScrollView.right.titleBtns.unUseBtn.gameObject:SetActive(_realHonorId==self.player.honor and _realHonorId~=0)
    CS.UGUIClickEventListener.Get(self.view.bottom.itemNode.HonorScrollView.right.titleBtns.unUseBtn.gameObject).onClick = function()
        if _realHonorId==self.player.honor then
            self.view.bottom.itemNode.HonorScrollView.right.titleBtns.unUseBtn[CS.UGUIClickEventListener].interactable=false
            PlayerModule.ChangeHonor(0);
        end  
    end
end

function View:upShowItemInfo(ShowItemCfg,idx)
    local _ScrollViewRoot =self.selected_tab == 1  and self.view.bottom.itemNode.ScrollView or self.view.bottom.itemNode.ShowItemScrollView
    local obj=nil
    if self.SelectIdx then
        obj = _ScrollViewRoot.Viewport.Content[CS.ScrollViewContent]:GetItem(self.SelectIdx)
        if obj then
            local _selectItem = SGK.UIReference.Setup(obj);
            _selectItem.ItemElse.ItemIcon.checkMark:SetActive(false)
        end
    end
    if self.selected_tab == 1  then
        _ScrollViewRoot.modeBtns.gameObject:SetActive(idx and ShowItemCfg.mode)
    else
        _ScrollViewRoot.bottom.gameObject:SetActive(idx and ShowItemCfg)
    end
    -- self.view.bottom.itemNode.ScrollView.bottom.gameObject:SetActive(idx and ShowItemCfg and not ShowItemCfg.mode)
    -- self.view.bottom.itemNode.ScrollView.bottom.Btns.gameObject:SetActive(idx and ShowItemCfg and not ShowItemCfg.mode) 
    -- self.view.bottom.itemNode.ScrollView.bottom.tip.gameObject:SetActive(idx and ShowItemCfg and not ShowItemCfg.mode)
    -- self.view.bottom.itemNode.ShowItemScrollView.modeBtns.gameObject:SetActive(idx and ShowItemCfg and ShowItemCfg.mode)

    if idx and ShowItemCfg then
        if idx then
            obj = _ScrollViewRoot.Viewport.Content[CS.ScrollViewContent]:GetItem(idx)
            if obj then
                local _selectItem = SGK.UIReference.Setup(obj);
                _selectItem.ItemElse.ItemIcon.checkMark:SetActive(true)
            end
            self.SelectIdx = idx
        end

        if ShowItemCfg.mode then--modeCfg
            --self.LocalSlotItem:UpdateSkeleton(tostring(ShowItemCfg.mode))
            self:UpdateSpine(tostring(ShowItemCfg.mode))
            _ScrollViewRoot.modeBtns.SaveBtn.gameObject:SetActive(self.playerAddData.ActorShow~=ShowItemCfg.mode and not ShowItemCfg.isLocked)
            CS.UGUIClickEventListener.Get(_ScrollViewRoot.modeBtns.SaveBtn.gameObject).onClick = function (obj)
                -- print("使用装饰物",sprinttb(ShowItemCfg))
                self.SelectShowItemId=ShowItemCfg.mode
                PlayerInfoHelper.ChangeActorShow(ShowItemCfg.mode)
            end
        else
            self:upTopShowItemShow(ShowItemCfg)

            _ScrollViewRoot.bottom.tip.Text[UI.Text].text=tostring(ShowItemCfg.info)
            --佩戴中的 隐藏使用按钮
            _ScrollViewRoot.bottom.Btns.toUseBtn[CS.UGUIClickEventListener].interactable =module.ItemModule.GetItemCount(ShowItemCfg.id)>0
            _ScrollViewRoot.bottom.Btns.toUseBtn.gameObject:SetActive(self.playerAddData[addDataType[ShowItemCfg.sub_type]]~=ShowItemCfg.id)
            CS.UGUIClickEventListener.Get(_ScrollViewRoot.bottom.Btns.toUseBtn.gameObject).onClick = function (obj)
                -- print("使用装饰物",sprinttb(ShowItemCfg))
                self.SelectShowItemId=ShowItemCfg.id
                PlayerInfoHelper.ChangePlayerShowItem(ShowItemCfg.sub_type,ShowItemCfg.id)
            end

            --卸下该装饰物 参数0
            _ScrollViewRoot.bottom.Btns.unUseBtn.gameObject:SetActive(self.playerAddData[addDataType[ShowItemCfg.sub_type]]==ShowItemCfg.id)
            CS.UGUIClickEventListener.Get(_ScrollViewRoot.bottom.Btns.unUseBtn.gameObject).onClick = function (obj)
                self.SelectShowItemId=0
                PlayerInfoHelper.ChangePlayerShowItem(ShowItemCfg.sub_type,self.SelectShowItemId)
            end
            --[[--暂时关闭购买功能
                _ScrollView.bottom.Btns.toBuyBtn.gameObject:SetActive(module.ItemModule.GetItemCount(ShowItemCfg.id)<1)
                CS.UGUIClickEventListener.Get(_ScrollView.bottom.Btns.toBuyBtn.gameObject).onClick = function (obj)
                    self.Shop_id=9---节日商店Id
                    self.SelectShowItemId = ShowItemCfg.id
                    ShopModule.Query(9)
                end
            --]]
            
        end
    end
end

function View:upTopShowItemShow(ShowItemCfg,idx)
    local ItemRoot =nil
    if (ShowItemCfg and ShowItemCfg.sub_type==74)  or (not ShowItemCfg and idx==3) or (not ShowItemCfg and not idx and self.selected_tab ==3) then--挂件
        ItemRoot=self.view.top.Slot.Widget
        --self.qModule[SGK.LuaBehaviour]:Call("UpdateWidget",ShowItemCfg)
    elseif (ShowItemCfg and (ShowItemCfg.sub_type==75  or ShowItemCfg.sub_type==70))  or (not ShowItemCfg and idx==4) or  (not ShowItemCfg and not idx and self.selected_tab ==4)  then--足迹
        ItemRoot=self.view.top.Slot.footPrint
        --self.qModule[SGK.LuaBehaviour]:Call("UpdateFootPrint",ShowItemCfg);
    elseif (ShowItemCfg and ShowItemCfg.sub_type==76) or (not ShowItemCfg and idx==5) or (not ShowItemCfg and not idx and self.selected_tab ==5) then--气泡框
        ItemRoot=self.view.top.Slot.bubble
    end

    ItemRoot.NoIcon.gameObject:SetActive(false)
    ItemRoot.node.gameObject:SetActive(not not ShowItemCfg)
    ItemRoot.gameObject:SetActive(not not ShowItemCfg)
    if ShowItemCfg then
        if ShowItemCfg.effect_type==1 then--Icon
            ItemRoot.node.Icon[UI.Image]:LoadSprite("icon/"..ShowItemCfg.effect)
            if ShowItemCfg and ShowItemCfg.sub_type == 76 then
                local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(ShowItemCfg.text_color)
                if ShowItemCfg.text_color and _color then
                    ItemRoot.Text[UI.Text].color = _color
                end
            end
        elseif ShowItemCfg.effect_type==2 then--effect
            --ItemRoot.gameObject:SetActive(false)
			for i = 1,ItemRoot.node.effect.transform.childCount do  
				UnityEngine.GameObject.Destroy(ItemRoot.node.effect.transform:GetChild(i-1).gameObject)
			end

			if ShowItemCfg.sub_type==75 or ShowItemCfg.sub_type==70 then
				self.FootEffect_Name=nil
			end
            if ShowItemCfg.sub_type==75 then
            	self.FootEffect_Name = ShowItemCfg.effect
            else
            	local footprint_effect =self:playEffect("UI/"..ShowItemCfg.effect, Vector3(0, 0, -10),ItemRoot.node.effect.transform,Vector3(ShowItemCfg.sub_type==74 and 0 or -45, 0, 0),100,"UI",1)
        	end
        elseif ShowItemCfg.effect_type == 3 then--effect
            for i = 1,ItemRoot.node.npcEffect.transform.childCount do  
                UnityEngine.GameObject.Destroy(ItemRoot.node.npcEffect.transform:GetChild(i-1).gameObject)
            end

            self:playEffect(ShowItemCfg.effect, Vector3(0, -15, -10),ItemRoot.node.npcEffect.transform,Vector3(ShowItemCfg.sub_type==74 and 0 or -45, 0, 0),50,"UI",1)
        end
        ItemRoot.node.Icon:SetActive(ShowItemCfg.effect_type==1)
        ItemRoot.node.effect:SetActive(ShowItemCfg.effect_type==2)
        if ItemRoot.node.npcEffect then
            ItemRoot.node.npcEffect:SetActive(ShowItemCfg.effect_type==3)
        end
    else
        ItemRoot.gameObject:SetActive(false)
   	end
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder,orderLayer)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation =rotation and Quaternion.Euler(rotation) or Quaternion.identity;
        transform.localScale = scale and scale*Vector3.one or Vector3.one

        if layerName then
            o.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            local layerList = o:GetComponentsInChildren(typeof(UnityEngine.Transform))
            for i=0,layerList.Length-1 do
                layerList[i].gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            end
            -- for i = 0,transform.childCount-1 do
            --     transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            -- end
        end
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function View:Update()
    if self.FootEffect_Name and self.view.top.Slot.footPrint.activeSelf then
        self.FootEffect_Time = self.FootEffect_Time + UnityEngine.Time.deltaTime
        if self.FootEffect_Time >= 0.5 then
           self.FootEffect_Time = self.FootEffect_Time - 0.5

           	for i = 1,self.view.top.Slot.footPrint.node.effect.transform.childCount do  
				UnityEngine.GameObject.Destroy(self.view.top.Slot.footPrint.node.effect.transform:GetChild(i-1).gameObject)
			end
            local footprint_effect =self:playEffect("UI/"..self.FootEffect_Name, Vector3(0, 0, -10),self.view.top.Slot.footPrint.node.effect.transform,Vector3(-45, 0, 0),100,"UI",30000)
        end
    end
end

function View:OnDestroy()
    self.view=nil 
end

function View:listEvent()
    return {
        "PLAYER_INFO_CHANGE",
        "ITEM_INFO_CHANGE",
        "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_OK",
        "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_ERROR",
        "OPEN_SHOP_INFO_RETURN",
        "PLAYER_ADDDATA_CHANGE_SUCCED",
    }
end

function View:onEvent(event,data)
    if event == "PLAYER_INFO_CHANGE" then
        if data and data==module.playerModule.GetSelfID() then
            if not self.CanRef then--连续收到 infoChange导致界面闪
                self.CanRef=true
                SGK.Action.DelayTime.Create(0.5):OnComplete(function()
                    if self.view then
                        self:UpPlayerData()
                        self.CanRef=false
                    end
                end)  
            end
        end
   elseif event== "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_OK" then
        self.view.bottom.itemNode.HonorScrollView.right.titleBtns.UseBtn[CS.UGUIClickEventListener].interactable=true
        self.view.bottom.itemNode.HonorScrollView.right.titleBtns.unUseBtn[CS.UGUIClickEventListener].interactable=true
        if data==0 then
            self.localSelectTabIdx[self.selected_tab]=0
        end
        showDlgError(nil,data==0 and  "移除成功" or "更换成功");
    elseif event=="LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_ERROR" then
        self.view.bottom.itemNode.HonorScrollView.right.titleBtns.UseBtn[CS.UGUIClickEventListener].interactable=true
    elseif event == "OPEN_SHOP_INFO_RETURN" then
        if self.Shop_id and self.SelectShowItemId then
            if ShopModule.GetOpenShop(self.Shop_id) and data then
                if openLevel.GetStatus(2401)then
                    DialogStack.Push("ShopFrame",{index =self.Shop_id,selectId=self.SelectShowItemId});
                    self.SelectShowItemId=nil
                else
                    showDlgError(nil,"等级不足")
                end
            else
                showDlgError(nil,"商店未开放");
            end
            self.Shop_id=nil
        end
    elseif event == "PLAYER_ADDDATA_CHANGE_SUCCED" then
        if data and data==self.SelectShowItemId then
            self.localSelectTabIdx[self.selected_tab]=self.SelectShowItemId 
            self.SelectShowItemId =nil
        end
        self:UpPlayerAddData()
        showDlgError(nil,data==0 and "移除成功" or "更换成功")
    end
end

return View