local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local Time = require "module.Time";
local View = {};


function View:Start()
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content

	self.diversionPanelRescourcesUI={}
	self.resourcesCfg=defensiveModule.GetResourceCfg()
	self.Pid=playerModule.GetSelfID()
end

function View:InitData(data)
	self.mapInfo=data and data.mapInfo
	self.PlayerData=data and data.PlayerData
	self.BossId=data and data.BossId
	self.OwnResource=data and data.OwnResource

	self.PosId=self.PlayerData[self.Pid].PosId
	local diversiveId=defensiveModule.getMapCfgById(self.PosId).Is_diversion---该点的诱敌方式
	self.diversiveCfg=defensiveModule.GetDiversionCfg(diversiveId)

	self.DiversionCD=not (self.PlayerData[self.Pid].LastDiversionTime+self.diversiveCfg.Time_cd/1000-Time.now()<0)
	self:InitUI()
end

function View:InitUI()
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj)
		self.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function (obj)
		self.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.root.view.ExitBtn.gameObject).onClick = function (obj)
		self.gameObject:SetActive(false)
	end

	self:UpTeamResources()

	local BossCfg=defensiveModule.GetBossCfg(self.BossId)
	local propertyCfg=defensiveModule.GetResourceCfgById(BossCfg.Monster_type)

	self.view.Top.Icon[UI.Image]:LoadSprite("icon/"..BossCfg.Monster_icon)
	self.view.Top.property.Icon[UI.Image]:LoadSprite("propertyIcon/"..propertyCfg.Resource_icon)

	self.root.view.Title[UI.Text]:TextFormat("诱敌");
	self.view.Top.tip[UI.Text]:TextFormat("目标:\t{0}",BossCfg.Monster_name);
	self.view.Top.desc[UI.Text]:TextFormat("引诱敌人行走此路线,此条路线诱敌值越高Boss越可能走该条路线");
	self.view.mid.static_addedOdds[UI.Text]:TextFormat("诱敌后");
	self.view.mid.static_addedOdds.static_odds[UI.Text]:TextFormat("额外几率");
	self.view.mid.status.desc[UI.Text]:TextFormat("当前Boss选择此道路几率");

	-- 	--诱敌消耗--诱敌元素类型 该点的 诱敌方式的 Diversion_consume  该值为0 则与boss 相同  else 为该类型
	local consumeId=self.diversiveCfg.Diversion_consume==0 and BossCfg.Monster_type or self.diversiveCfg.Diversion_consume
	local consumeCfg=defensiveModule.GetResourceCfgById(consumeId)
	self.view.consume.static_consume[UI.Text]:TextFormat("消耗：");
	self.view.consume.item.Icon[UI.Image]:LoadSprite("propertyIcon/"..consumeCfg.Resource_icon)
	self.view.consume.item.num[UI.Text]:TextFormat("X{0}",self.diversiveCfg.Consume_value);

	self:UpDiversionData()

	CS.UGUIClickEventListener.Get(self.view.diversionBtn.gameObject).onClick = function (obj)
		if (Time.now()-self.PlayerData[self.Pid].LastDiversionTime)>=self.diversiveCfg.Time_cd/1000 then
			if self.OwnResource[consumeId]>=self.diversiveCfg.Consume_value then
				defensiveModule.QueryDiversion()
			else
				showDlgError(nil,"资源不足")
			end
		else
			showDlgError(nil,"诱敌冷却中")
		end	
	end
end

function View:UpTeamResources()	
	--ref Teamresource show
	for k,v in pairs(self.diversionPanelRescourcesUI) do
		v.gameObject:SetActive(false)
	end

	for i,v in ipairs(self.resourcesCfg) do
		local k=v.Resource_id
		local item=nil
		item,self.diversionPanelRescourcesUI=defensiveModule.CopyUI(self.diversionPanelRescourcesUI,self.view.TeamResources.resources,self.view.TeamResources.resources.Item,k)
		
		item.Icon[UI.Image]:LoadSprite("propertyIcon/"..v.Resource_icon)
		item.num[UI.Text].text=string.format("%d",self.OwnResource[v.Resource_id])
	end
end

function View:UpDiversionData()	
	local _value=self.mapInfo[self.PosId].Diversion_value/10000
	self.view.mid.status.addedOdds.odds[UI.Text]:TextFormat("{0}%",_value*100<=100 and _value*100 or 100);
	--诱敌方式ID
	local next_OddsValue=self.diversiveCfg.Diversion_probability
	self.view.mid.status.addedOdds[UI.Text]:TextFormat("↑{0}%",_value*100<=100 and next_OddsValue/100 or "--");
	self.view.diversionBtn.CDTime.gameObject:SetActive(self.DiversionCD)
end

function View:AfterDiversion(Diversion_value,LastDiversionTime)
	self.PlayerData[self.Pid].LastDiversionTime=LastDiversionTime
	self.mapInfo[self.PosId].Diversion_value=Diversion_value

	self.DiversionCD=true
	self.view.diversionBtn.CDTime.gameObject:SetActive(true)
	self:UpDiversionData()
end

function View:Update()
	if self.DiversionCD then
		local time=self.diversiveCfg.Time_cd/1000+self.PlayerData[self.Pid].LastDiversionTime-Time.now()
		if time>=0 then
			self.view.diversionBtn.CDTime[UI.Text].text=string.format("%ds",time)
		else
			self.DiversionCD=false
			self.view.diversionBtn.CDTime.gameObject:SetActive(false)
		end
	end
end

function View:listEvent()
	return {
		"DIVERSION_VALUE_CHANGE",
		"RESOURCES_NUM_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "DIVERSION_VALUE_CHANGE" then
		self:AfterDiversion(data.Diversion_value,data.LastDiversionTime)
	elseif event == "RESOURCES_NUM_CHANGE" then
		self.OwnResource=data[1]
		self:UpTeamResources()
	end
end

return View;