local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local Time = require "module.Time";
local View = {};


function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content

	self.mapCfg=defensiveModule.GetMapCfg()
	self.Pid=playerModule.GetSelfID()
	self:InitData(data)
end

function View:InitData(data)
	self.mapInfo=data and data.mapInfo
	self.PlayerData=data and data.PlayerData
	self.BossData=data and data.BossData
	
	self.posId=data and data.posId--boss位置
	self.Id=data and data.id

	self.OwnResource=data and data.OwnResource
	self.Site_Id=data and data.siteId

	self:InitUI()
end

function View:InitUI()
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.view.ExitBtn.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end

	local diversionId=self.mapCfg[self.Site_Id].Is_diversion
	self.diversiveCfg=defensiveModule.GetDiversionCfg(diversionId)

	self.view.Icon.Icon[UI.Image]:LoadSprite("icon/" .. self.diversiveCfg.icon)
	self.view.Icon.name[UI.Text].text=self.diversiveCfg.name
	self.view.desc.Text[UI.Text].text=self.diversiveCfg.des

	self.root.AddPanel.slider[UI.Slider].maxValue=self.diversiveCfg.Time_cd/1000
	self.lastClickTime = not self.AddObstructing and 0 or self.PlayerData[self.Pid].LastDiversionTime
	self.AddObstructing = (self.lastClickTime+self.diversiveCfg.Time_cd/1000-Time.now())>0

	self.root.AddPanel.gameObject:SetActive(self.AddObstructing)

	local bossCfg=defensiveModule.GetBossCfg(self.Id)
	local consumeId=self.diversiveCfg.Diversion_consume==0 and bossCfg.Monster_type or self.diversiveCfg.Diversion_consume
	local consumeCfg=defensiveModule.GetResourceCfgById(consumeId)

	self.view.consume.item.Icon[UI.Image]:LoadSprite("propertyIcon/"..consumeCfg.Resource_icon)
	self.view.consume.item.num[UI.Text]:TextFormat("X{0}",self.diversiveCfg.Consume_value);

	CS.UGUIClickEventListener.Get(self.view.addBtn.gameObject).onClick = function (obj)
		if (Time.now()-self.PlayerData[self.Pid].LastDiversionTime)>=self.diversiveCfg.Time_cd/1000 then
			if self.OwnResource[consumeId]>=self.diversiveCfg.Consume_value then
				self.AddObstructing=true
				self.lastClickTime=Time.now()
				self.view.addBtn.gameObject:SetActive(false);
				self.root.AddPanel.gameObject:SetActive(true)	
			else
				showDlgError(nil,"资源不足")
			end
		else
			showDlgError(nil,"功能冷却中")
		end	
	end

	CS.UGUIClickEventListener.Get(self.root.AddPanel.closeBtn.gameObject).onClick = function (obj)
		self.AddObstructing=true
		self.lastClickTime=0
		self.view.addBtn.gameObject:SetActive(true);
		self.root.AddPanel.gameObject:SetActive(false)
	end
end

function View:Update()
	if self.AddObstructing and self.lastClickTime~=0 then
		if Time.now()-self.lastClickTime<=self.diversiveCfg.Time_cd/1000 then
			local time = self.lastClickTime +self.diversiveCfg.Time_cd/1000 - Time.now()
			self.root.AddPanel.slider[UI.Slider].value = Time.now() - self.lastClickTime
			self.root.AddPanel.slider.Text[UI.Text].text=string.format("%sS",math.floor(time))
		else
			self.AddObstructing=false

			if self.mapCfg[self.posId].Monster_site and next(self.mapCfg[self.posId].Monster_site)~=nil and #self.mapCfg[self.posId].Monster_site>1 then
				local addedSites=0
				for i=1,#self.mapCfg[self.posId].Monster_site do
					local _siteId=self.mapCfg[self.posId].Monster_site[i]
					if self.mapInfo[_siteId].Diversion_value>0 then
						addedSites=addedSites+1
					end
				end
				if addedSites<#self.mapCfg[self.posId].Monster_site-1 then
					defensiveModule.QueryDiversion(self.Site_Id)
				else
					showDlgError(nil,"不能激活更多的路障了!")
				end
			end

			DialogStack.Pop()
		end
	end
end


function View:listEvent()
	return {
		"RESOURCES_NUM_CHANGE",
		"POINT_INFO_CHANGE",
		"BOSS_DATA_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "RESOURCES_NUM_CHANGE" then
		self.OwnResource=data[1]
	elseif event=="POINT_INFO_CHANGE" then
		if self.mapInfo then
			self.mapInfo[data.PosId].Diversion_value=data.Diversion_value
		end
	elseif event=="BOSS_DATA_CHANGE" then
		if data and data[3] == 4 and self.mapInfo then
			self.AddObstructing = false
			self.lastClickTime=0
			self.root.AddPanel.gameObject:SetActive(false)
			DialogStack.Pop()
			showDlgError(nil,"魔王向据点发起攻击,设置路障失败")
		end
	end
end

return View;