local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local Time = require "module.Time";
local View = {};

function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content
	
	self.exchangePanelRescourcesUI={}
	self.ExchangeResourcesTab={}--兑换资源的Ui

	self.resourcesCfg=defensiveModule.GetResourceCfg()
	self.exchangeCfg=defensiveModule.GetExchangeCfg()
	self.Pid=playerModule.GetSelfID()

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.view.ExitBtn.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end
	self:InitData(data)
end

function View:InitData(data)
	self.PlayerData=data and data.PlayerData
	self.OwnResource=data and data.OwnResource
	self.nowIndex=self.nowIndex or 1

	local _CfgCD=self.exchangeCfg[self.nowIndex].Time_cd/1000
	self.ExchangeCD=(_CfgCD+self.PlayerData[self.Pid].LastExchangeTime-Time.now())<0

	self.UseResourcesTab={}
	self.SelectedResourceId={}--兑换面板资源
	self:InitUI()
end

function View:InitUI()
	self:UpTeamResources()
	self:refreshSelectIconShow()
	self:InExchangeResources()

	for i,v in ipairs(self.resourcesCfg) do
		CS.UGUIClickEventListener.Get(self.exchangePanelRescourcesUI[v.Resource_id].gameObject).onClick = function (obj)
			self.UseResourcesTab[v.Resource_id]=self.UseResourcesTab[v.Resource_id] and self.UseResourcesTab[v.Resource_id]+1 or 1
			self.UseResourcesTab[v.Resource_id]=self.UseResourcesTab[v.Resource_id]>2 and 2 or self.UseResourcesTab[v.Resource_id]
			if self.OwnResource[v.Resource_id]-self.UseResourcesTab[v.Resource_id]>=0 then
				if self.SelectedResourceId[1] then
					self.SelectedResourceId[2]=v.Resource_id		
				else
					self.SelectedResourceId[1]=v.Resource_id	
				end
				self:refreshSelectIconShow()
				local _item=CS.SGK.UIReference.Setup(self.exchangePanelRescourcesUI[v.Resource_id])
				_item.num[UI.Text].text=string.format("x%d",self.OwnResource[v.Resource_id]-(self.UseResourcesTab[v.Resource_id] and self.UseResourcesTab[v.Resource_id] or 0))
			else
				showDlgError(nil,"资源不足")
			end
		end
	end
	--ref exchange resourceshow
	for i=1,2 do
		CS.UGUIClickEventListener.Get(self.view.consume[i].gameObject).onClick = function (obj) 
			if self.SelectedResourceId and self.SelectedResourceId[i] then
				self.UseResourcesTab[self.SelectedResourceId[i]]=self.UseResourcesTab[self.SelectedResourceId[i]] and self.UseResourcesTab[self.SelectedResourceId[i]]-1 or 0
				
				local _item=CS.SGK.UIReference.Setup(self.exchangePanelRescourcesUI[self.SelectedResourceId[i]])
				_item.num[UI.Text].text=string.format("x%d",self.OwnResource[self.SelectedResourceId[i]]-(self.UseResourcesTab[self.SelectedResourceId[i]] and self.UseResourcesTab[self.SelectedResourceId[i]] or 0))
				
				self.SelectedResourceId[i]=nil
				self:refreshSelectIconShow()
			end	
		end
	end

	CS.UGUIClickEventListener.Get(self.view.exchangeBtn.gameObject).onClick = function (obj) 
		if self.SelectedResourceId[1]==nil or self.SelectedResourceId[2] ==nil then 
			return 
		end

		if Time.now()-self.PlayerData[self.Pid].LastExchangeTime>=self.exchangeCfg[self.nowIndex].Time_cd/1000 then
			--不同类型的资源兑换时，数量>1 同种资源 num>2
			local case=self.SelectedResourceId[1]~=self.SelectedResourceId[2] and self.OwnResource[self.SelectedResourceId[1]]+self.OwnResource[self.SelectedResourceId[2]]>=2 or self.OwnResource[self.SelectedResourceId[1]]>=2
			if case then
				defensiveModule.QueryExchange({self.SelectedResourceId[1],self.SelectedResourceId[2]},self.exchangeCfg[self.nowIndex].Resource_id)
				
				self.UseResourcesTab={}
				self.SelectedResourceId={}
			else
				showDlgError(nil,"资源不足")
			end
		else
			showDlgError(nil,"现在还不能兑换")
		end
	end
end

function View:refreshSelectIconShow()
	self:InSelectButton(1)
	self:InSelectButton(2)
	for k,v in pairs(self.exchangePanelRescourcesUI) do
		local _item=CS.SGK.UIReference.Setup(v)
		_item.checkMark:SetActive(k==self.SelectedResourceId[1] or k==self.SelectedResourceId[2])
	end
	
	self.view.exchangeBtn[CS.UGUIClickEventListener].interactable=#self.SelectedResourceId==2
end
	
function View:InSelectButton(Idx)
	local item=self.view.consume[Idx]
	item.Add:SetActive(not self.SelectedResourceId[Idx])
	item.Item:SetActive(self.SelectedResourceId[Idx])
	if self.SelectedResourceId[Idx] then
		local cfg=defensiveModule.GetResourceCfgById(self.SelectedResourceId[Idx])
		item.Item.Icon[UI.Image]:LoadSprite("propertyIcon/"..cfg.Resource_icon)
		item.Item.Text[UI.Text].text=cfg.Resource_name
	end
end
---兑换资源滑动功能
function View:InExchangeResources()
	local _Pos=self.view.Top.ScrollView.Viewport.Content
	for i,v in ipairs(self.exchangeCfg) do
		local _obj=nil
		local k=v.Resource_id
		if self.ExchangeResourcesTab[k]  then 
			_obj=self.ExchangeResourcesTab[k]
		else      
			_obj=UnityEngine.Object.Instantiate(_Pos.Item.gameObject)
			_obj.transform:SetParent(_Pos.gameObject.transform,false)
			_obj.name=tostring(k)
			self.ExchangeResourcesTab[k]=_obj
		end

		_obj.gameObject:SetActive(true)
		local item=CS.SGK.UIReference.Setup(_obj.transform).item
		item.Icon[UI.Image]:LoadSprite("propertyIcon/"..v.Resource_icon)
		item.num[UI.Text].text=string.format("%s",v.Resource_name)
	end
	self.view.Top.ScrollView[CS.UIPageView].OnPageChanged =(function (index)
		if self.nowIndex~=index+1 then
			self.nowIndex=index+1
			for i,v in ipairs(self.ExchangeResourcesTab) do
				CS.SGK.UIReference.Setup(v).item.transform.localScale=self.nowIndex==i and Vector3.one or Vector3.one*0.8
			end
		end
 	end)

	CS.UGUIClickEventListener.Get(self.view.Top.ScrollView.leftArrow.gameObject).onClick = function (obj) 
		self.nowIndex=self.nowIndex or 1
		if self.nowIndex>1 then
			self.view.Top.ScrollView[CS.UIPageView]:pageTo(self.nowIndex -2)
		end
	end
	CS.UGUIClickEventListener.Get(self.view.Top.ScrollView.rightArrow.gameObject).onClick = function (obj) 
		self.nowIndex=self.nowIndex or 1
		if self.nowIndex-1<=self.view.Top.ScrollView[CS.UIPageView].dataCount-1 then
			self.view.Top.ScrollView[CS.UIPageView]:pageTo(self.nowIndex)
		end
	end
end

function View:AfterExchange(data)
	if data[5]==self.Pid then
		self.view.exchangeBtn.CDTime.gameObject:SetActive(true)
		self.PlayerData[data[5]].LastExchangeTime=data[3]
		self.ExchangeCD=true
		self:refreshSelectIconShow()
	end
end

function View:UpTeamResources()	
	--ref Teamresource show
	for k,v in pairs(self.exchangePanelRescourcesUI) do
		v.gameObject:SetActive(false)
	end

	for i,v in ipairs(self.resourcesCfg) do
		local k=v.Resource_id
		local item=nil
		item,self.exchangePanelRescourcesUI=defensiveModule.CopyUI(self.exchangePanelRescourcesUI,self.view.TeamResources.resources,self.view.TeamResources.resources.Item,k)
		
		item.Icon[UI.Image]:LoadSprite("propertyIcon/"..v.Resource_icon)
		item.property[UI.Text].text=v.Resource_name
		item.num[UI.Text].text=string.format("x%d",self.OwnResource[v.Resource_id]-(self.UseResourcesTab[v.Resource_id] and self.UseResourcesTab[v.Resource_id] or 0))
	end
end

function View:Update()
	if self.ExchangeCD then
		local _CfgCD=self.exchangeCfg[self.nowIndex].Time_cd/1000
		local time=_CfgCD+self.PlayerData[self.Pid].LastExchangeTime-Time.now()
		if time>=0 then
			self.view.exchangeBtn.CDTime[UI.Text].text=string.format("%ds",time)
		else
			self.ExchangeCD=false
			self.view.exchangeBtn.CDTime.gameObject:SetActive(false)
		end
	end
end

function View:listEvent()
	return {
		"EXCHANGE_SUCCEED",
		"RESOURCES_NUM_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "EXCHANGE_SUCCEED" then
		self:AfterExchange(data)
	elseif event == "RESOURCES_NUM_CHANGE" then
		self.OwnResource=data[1]
		self:UpTeamResources()
	end
end

 
return View;