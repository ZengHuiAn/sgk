local activityConfig = require "config.activityConfig"
local RedDotModule = require "module.RedDotModule"
local View = {}

function View:Start()
    self.root= CS.SGK.UIReference.Setup(self.gameObject)
    self.view=self.root.view.Content

    self.root.view.Content.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_jingcaifuli_01")
    self.ActivityTabUI={}

    self:initUI()
    CS.UGUIClickEventListener.Get(self.view.top.ScrollView.leftBtn.gameObject).onClick = function()
      	if self.SelectIdx>1 then
      		self.SelectIdx=self.SelectIdx-1
	        self:RefMainView(self.SelectIdx)
      	end
    end

    CS.UGUIClickEventListener.Get(self.view.top.ScrollView.rightBtn.gameObject).onClick = function()
       if self.SelectIdx<#self.activityCfg then
      		self.SelectIdx=self.SelectIdx+1
	        self:RefMainView(self.SelectIdx)
      	end
    end

    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.root.view.gameObject.transform)
end

function View:initRedDot()
    self.redDotTab = {}
    self.redDotTab[1] = RedDotModule.Type.WelfareActivity.DailyDraw
    self.redDotTab[2] = RedDotModule.Type.WelfareActivity.LuckyDraw_Time
end

function View:upRedDot()
	local _parent = self.view.top.ScrollView.Viewport.Content
    --for i = 1,#self.activityCfg do
    for i = 1,2 do
        -- if self.ActivityTabUI[i] and #self.ActivityTabUI ==#self.activityCfg then
        --     self.ActivityTabUI[i].tip.gameObject:SetActive(RedDotModule.GetStatus(self.redDotTab[i], nil,self.ActivityTabUI[i].tip))
        -- end
        
        if _parent.transform.childCount == 2 then--#self.activityCfg then
        	local _obj = _parent.transform:GetChild(i-1)
        	local _item = CS.SGK.UIReference.Setup(_obj)
        	_item.tip.gameObject:SetActive(RedDotModule.GetStatus(self.redDotTab[i], nil,_item.tip))
        end
    end
end

function View:initUI()

    self.activityCfg = {"fuli_001","fuli_002"}--activityConfig.GetActivityCfgByCategory(5)

    self.SelectIdx = self.savedValues.WelfareActivitySeleIdx or 1

    self.checkMark = self.view.top.ScrollView.checkMark
    self.itemTabData = { {itemName ="welfare/DailyDrawFrame"},{itemName = "welfare/luckyDraw_time"}, } 
    
    self:initRedDot()

    local _parent = self.view.top.ScrollView.Viewport.Content
    local _prefab = self.view.top.ScrollView.Viewport.Content[1]
    for i=1,#self.activityCfg do
    -- for i=1,2 do
    	local _obj = nil
    	if i<=_parent.transform.childCount then
    		_obj =_parent.transform:GetChild(i-1).gameObject

	    else
	    	_obj = CS.UnityEngine.GameObject.Instantiate(_prefab.gameObject,_parent.transform)
        	_obj.transform.localPosition = Vector3.zero
	    end
	    _obj:SetActive(true)
    	local item = CS.SGK.UIReference.Setup(_obj)
    	-- local cfg = self.activityCfg[i]
    	-- if item and cfg then
    	if item then
	        item.name[UI.Text].text = SGK.Localize:getInstance():getValue(self.activityCfg[i])--tostring(self.activityCfg[i])-- cfg.name)
	        item.Icon[CS.UGUISpriteSelector].index = i-1

	        item.checkMark:SetActive(false)
	        if self.SelectIdx==i then
	            self:RefMainView(i)
	        end
	        CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
	            self:RefMainView(i)
	            self.SelectIdx = i
	        end
	        self:upRedDot()
    	end
    end
   
    -- self.UIDragIconScript = self.view.top.ScrollView[CS.UIMultiScroller]
    -- self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
    --     local index=idx+1;
	   --  local Item =CS.SGK.UIReference.Setup(obj);
	   --  self.ActivityTabUI[index]=Item
	   --  local cfg=self.activityCfg[index]
	   --  if cfg then
	   --      Item.gameObject:SetActive(true)
	   --      Item.name[UI.Text].text=tostring(cfg.name)
	   --      Item.Icon[CS.UGUISpriteSelector].index = idx
	   --      if self.SelectIdx==index then
	   --          self:RefMainView(index)
	   --      end
	   --      CS.UGUIClickEventListener.Get(Item.gameObject).onClick = function()
	   --          self.SelectIdx=index
	   --          self:RefMainView(index)
	   --      end
	   --  end
    -- end)

    -- self.UIDragIconScript.DataCount =#self.activityCfg
   
    self:initRedDot() 

    local item_x = self.view.top.ScrollView.Viewport.Content.Item[UnityEngine.RectTransform].rect.width
    local content_Width = self.view.top.ScrollView[UnityEngine.RectTransform].rect.width

    self.view.top.ScrollView[UI.ScrollRect].onValueChanged:AddListener(function (value)
        if 2*item_x>content_Width then
            local off_x = self.view.top.ScrollView.Viewport.Content.transform.localPosition.x
            self.view.top.ScrollView.leftBtn.gameObject:SetActive(off_x<-585 )
            self.view.top.ScrollView.rightBtn.gameObject:SetActive(off_x>-585 )
        end
    end)  
end

function View:RefMainView(Idx)
	if self.SelectIdx and self.SelectIdx ~= Idx then
		local obj = self.view.top.ScrollView.Viewport.Content.transform:GetChild(self.SelectIdx-1)
		if obj then
			local Item = CS.SGK.UIReference.Setup(obj)
			Item.checkMark:SetActive(false)
		end
	end

	local _obj = self.view.top.ScrollView.Viewport.Content.transform:GetChild(Idx-1)

	-- local Item = self.ActivityTabUI[Idx]
	if _obj then
		local Item = CS.SGK.UIReference.Setup(_obj)
		Item.checkMark:SetActive(true)
		Item.checkMark.Icon[CS.UGUISpriteSelector].index = Idx-1
		Item.checkMark.name[UI.Text].text = SGK.Localize:getInstance():getValue(self.activityCfg[Idx])
		local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFD800FF');
		Item.checkMark.name[UI.Text].color = color
		-- Item.checkMark.transform:SetParent(Item.Icon.gameObject.transform,false)
		-- Item.checkMark.transform.localPosition = Vector3.zero
		--Item.checkMark:SetActive(true)


		-- self.checkMark.Icon[CS.UGUISpriteSelector].index=Idx-1
		-- self.checkMark.name[UI.Text].text=tostring(self.activityCfg[Idx].name)
		-- local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFD800FF');
		-- self.checkMark.name[UI.Text].color=color
		-- self.checkMark.transform:SetParent(Item.Icon.gameObject.transform,false)
		-- self.checkMark.transform.localPosition=Vector3.zero
		-- self.checkMark:SetActive(true)

		-- self.nowSelectItem = DialogStack.GetPref_list(self.nowSelectItem)
		-- if self.nowSelectItem then
		-- 	UnityEngine.GameObject.Destroy(self.nowSelectItem)
		-- end

		for i=1,self.view.viewRoot.transform.childCount do
			self.view.viewRoot.transform:GetChild(i-1).gameObject:SetActive(i==Idx)
			if i== Idx then
				local panel = CS.SGK.UIReference.Setup(self.view.viewRoot.transform:GetChild(i-1).gameObject)
				panel[SGK.LuaBehaviour]:Call("Init")
			end
		end

		-- if self.itemTabData[Idx] and self.itemTabData[Idx].itemName~="" then
		-- 	self.nowSelectItem = self.itemTabData[Idx].itemName
		-- 	DialogStack.PushPref(self.itemTabData[Idx].itemName, nil, self.view.viewRoot.gameObject)
		-- end
	end
end

function View:OnDestroy( ... )
    self.savedValues.WelfareActivitySeleIdx =self.SelectIdx;
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
    return true
end

function View:listEvent()
    return{
        "DrawCard_Succeed",
        "QUEST_INFO_CHANGE",

    }
end

function View:onEvent(event,data)
    if event =="DrawCard_Succeed" or event =="QUEST_INFO_CHANGE" then
        self:upRedDot()
    end
end

return View;
