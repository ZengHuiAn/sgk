local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local TeamModule = require "module.TeamModule"
local Time = require "module.Time";
local TipCfg = require "config.TipConfig"
local View = {};

function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view

	self.teamInfo = TeamModule.GetTeamInfo();

	self.OwnRescourceUI={}

	self.PlayerCfg={}
	for i,v in ipairs(self.teamInfo.members) do
		if playerModule.IsDataExist(v.pid) then
	        self.PlayerCfg[v.pid]=playerModule.IsDataExist(v.pid)
	    else
	        playerModule.Get(pid,function ( ... )
	            self.PlayerCfg[v.pid]=playerModule.Get(v.pid);
	        end)
	    end
	end

	-- self.OwnResource=data and data.TeamResourceData --- 拥有资源数量
	-- self.PlayerData=data.PlayerData
	-- self.BossData=data.BossData

	-- self.Boss=UnityEngine.GameObject.Find("Boss_"..self.BossData.Id)

	-- self.BossDelayTime = {
	-- 	[1] = defensiveModule.GetActionTimeCfg(self.BossData.Id).incident1_time/1000,--发呆
	-- 	[2] = defensiveModule.GetActionTimeCfg(self.BossData.Id).incident2_time/1000,--发呆
	-- 	[3] = defensiveModule.GetActionTimeCfg(self.BossData.Id).incident3_time/1000,--回复
	-- 	[4] = defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000,--移动时间
	-- }

	-- self:InItUI()
	self:Init(data)
end

function View:Init(data)
	self.OwnResource=data and data.TeamResourceData --- 拥有资源数量
	self.PlayerData=data.PlayerData
	self.BossData=data.BossData

	self.Boss=UnityEngine.GameObject.Find("Boss_"..self.BossData.Id)

	self.BossDelayTime = {
		[1] = defensiveModule.GetActionTimeCfg(self.BossData.Id).incident1_time/1000,--发呆
		[2] = defensiveModule.GetActionTimeCfg(self.BossData.Id).incident2_time/1000,--发呆
		[3] = defensiveModule.GetActionTimeCfg(self.BossData.Id).incident3_time/1000,--回复
		[4] = defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000,--移动时间
	}

	self:InItUI()
end

function View:InItUI()
	local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)
	self.view.MainFrame.top.BossDetail.Icon[UI.Image]:LoadSprite("icon/"..bossCfg.Monster_icon)

	local propertyCfg=defensiveModule.GetResourceCfgById(bossCfg.Monster_type)
	self.view.MainFrame.top.BossDetail.propertyIcon[UI.Image]:LoadSprite("propertyIcon/"..propertyCfg.Resource_icon)

	local _hp=self.BossData.BossHp<=bossCfg.Monster_hp and  self.BossData.BossHp or bossCfg.Monster_hp

	self.BossData.NowHp=_hp

	self.view.MainFrame.top.BossDetail.HP.Image[UI.Image].fillAmount = _hp/bossCfg.Monster_hp
	self.view.MainFrame.top.BossDetail.HP.Text[UI.Text].text=string.format("%s%%",math.floor(_hp/bossCfg.Monster_hp*100))

	--self:updateBossStatusText(self.BossData.Status)

	self.view.MainFrame.roleNode[SGK.LuaBehaviour]:Call("InitData",{BossData=self.BossData,PlayerData=self.PlayerData,teamInfo=self.teamInfo})--,UINode)

	CS.UGUIClickEventListener.Get(self.view.MainFrame.bottom.tipData.tipBtn.gameObject).onClick = function (obj) 
		utils.SGKTools.ShowDlgHelp(TipCfg.GetAssistDescConfig(70001).info,TipCfg.GetAssistDescConfig(70001).tittle, self.root)
	end

	-- self.view.MainFrame.bottom.exitBtn:SetActive(self.teamInfo.leader.pid == module.playerModule.GetSelfID())
	CS.UGUIClickEventListener.Get(self.view.MainFrame.bottom.exitBtn.gameObject).onClick = function (obj) 
		showDlg(nil,"是否确认退出队伍并离开？\n",function()
			--defensiveModule.BackToEntranceNpc()
			module.TeamModule.KickTeamMember()
		end,function() end)
	end
	--地图TeamResources
	self.resourcesCfg=defensiveModule.GetResourceCfg()
	self:updateResourcesItem()

	self.view.MainFrame.bottom.tipData.Image:SetActive(true)

	self.BossStartCD=true
	self.BossStartMoveCD=60*2
end

--刷新主面板资源
function View:updateResourcesItem()-- type ==1 Resources ==2 exchange
	local prefab=self.view.MainFrame.bottom.resources.Viewport.Content.Item
	for k,v in pairs(self.OwnRescourceUI) do
		v.gameObject:SetActive(false)
	end
	for i,v in ipairs(self.resourcesCfg) do
		local _obj=nil
		local cfg =self.resourcesCfg[i]
		if self.OwnRescourceUI[cfg.Resource_id] then 
			_obj=self.OwnRescourceUI[cfg.Resource_id]--self.resourcesCfg[i]
		else      
			_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
			_obj.transform:SetParent(self.view.MainFrame.bottom.resources.Viewport.Content.gameObject.transform,false)
			self.OwnRescourceUI[cfg.Resource_id]=_obj
		end
		_obj.gameObject:SetActive(true)
		local Item=CS.SGK.UIReference.Setup(_obj);
		Item.Icon[UI.Image]:LoadSprite("propertyIcon/"..cfg.Resource_icon)
		Item.num[UI.Text].text=string.format("%d",self.OwnResource[cfg.Resource_id]>=0 and  self.OwnResource[cfg.Resource_id] or 0)
	end
end
local delayTime={
		[23]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,--搜集时间
	}

function View:InResourcesChange(data)
	--data[3]   1:收集资源2:加强陷阱3:兑换资源4:诱敌消耗资源5:与boss相遇掉资源6:战斗结束之后获得资源
	self.OwnResource=data[1]
	local _Delaytime=data[3] and (data[3]==1 and delayTime[23]+1 or 0) or 0
	self.view.transform:DOScale(Vector3.one,_Delaytime):OnComplete(function()
		for k,v in pairs(data[2]) do
			if  self.OwnResource[k]~=v then
				CS.SGK.UIReference.Setup(self.OwnRescourceUI[k]).num[UI.Text].text=tostring(self.OwnResource[k]>=0 and self.OwnResource[k] or 0)
				self:ShowChangeNum(self.OwnResource[k]-v,CS.SGK.UIReference.Setup(self.OwnRescourceUI[k]))	
			end
		end
	end)
end

function View:ShowChangeNum(value,pos)
	-- print("资源数量变化",pos.x,pos.y,pos.z)
    local prefab = SGK.ResourcesManager.Load("prefabs/DefensiveFortress/hurt_normal_.prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab,pos.gameObject.transform);
    o.transform.localPosition=Vector3.zero
    local nm = o:GetComponent(typeof(CS.NumberMovement));
     if not nm.text then
        nm.text = o:GetComponent(typeof(UnityEngine.UI.Text));
    end
    nm.text.text = string.format("%s%d%s",value>=0 and "<color=#3BFFBCFF>" or "<color=#FF1A1AFF>",value,"</color>");
	o.transform:DOLocalMove(Vector3(0,100,0),0.5):OnComplete(function( ... )
		if self.gameObject then
			CS.UnityEngine.GameObject.Destroy(o)
		end
	end)
end
--1：破坏据点，2：发呆，3：生命回复4.移动
function View:updateBossStatus(data)
	--ERROR_LOG("更新 boss状态",sprinttb(data))		
	self.BossData.ChangeStatusTime=data[4]
	self.BossData.Status=data[3]
	
	local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)
	local _hp=data[5]<=bossCfg.Monster_hp and data[5] or bossCfg.Monster_hp
	self.BossData.NowHp=_hp

	self.view.MainFrame.top.BossDetail.HP.Image[UI.Image].fillAmount = _hp/bossCfg.Monster_hp
	self.view.MainFrame.top.BossDetail.HP.Text[UI.Text].text=string.format("%s%%",math.floor(_hp/bossCfg.Monster_hp*100))
end

function View:updateBossStatusText()
	if self.BossStartCD and self.BossData and self.BossDelayTime then--游戏开始
		--local time=Time.now()-self.BossData.GameStartTime
		if self.BossData.Status==0 then
			local _time = self.BossStartMoveCD+self.BossData.ChangeStatusTime-Time.now()
			if _time>0 then
				self.view.MainFrame.top.BossDetail.status.Text[UI.Text].text = string.format("发呆中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==1 then
			local _breakTime = self.BossDelayTime[1]
			local _time = _breakTime+self.BossData.ChangeStatusTime-Time.now()
			local _Time = _breakTime-_time
			if _time>0 then
				self.view.MainFrame.top.BossDetail.status.Text[UI.Text].text = string.format("发呆中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==2 then
			local _sleepTime = self.BossDelayTime[2]
			local _time = _sleepTime+self.BossData.ChangeStatusTime-Time.now()
			if _time>0 then
				self.view.MainFrame.top.BossDetail.status.Text[UI.Text].text = string.format("懵圈中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==3 then
			local _sleepTime = self.BossDelayTime[3]
			local _time = _sleepTime+self.BossData.ChangeStatusTime-Time.now()
			if _time>0 then
				self.view.MainFrame.top.BossDetail.status.Text[UI.Text].text = string.format("恢复生命中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==4 then
			local MoveInterval = self.BossDelayTime[4]
			local _time = MoveInterval+self.BossData.ChangeStatusTime-Time.now()
			if _time>=0 then
				self.view.MainFrame.top.BossDetail.status.Text[UI.Text].text = string.format("移动中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
	end
end
--收集资源
function View:TryCollectResources(data)
	--print("--收集资源"..sprinttb(data))
	if data[3]==0 then--0为搜集资源
		--showDlgError(nil,"资源搜集中")		
		--收集完成后播放收集特效
		SGK.Action.DelayTime.Create(delayTime[23]):OnComplete(function()
            self:ShowGetResourcesEffect(data[4])
        end) 
	else--进入战斗
		-- local PosInfo=defensiveModule.getMapCfgById(self.PlayerData[self.Pid].PosId)
		-- local fightId=PosInfo.Combat_id
		-- --local fight_data=data[3]
		-- fightModule.StartFight(fightId,nil,function (win,heros,starInfo)
		-- 	defensiveModule.QueryAfterFight()
		-- end)
	end
end

function View:ShowGetResourcesEffect(_resourcesInfo)
	local prefab_fly = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_lizi.prefab"); 
	local prefab_explode = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_bao.prefab");

	for i=1,#_resourcesInfo do
		local posId=_resourcesInfo[i][1]
		local resourceId=_resourcesInfo[i][2]
		--local resourcePos=self.resourcesPoint[self.mapInfo[posId].Idx].gameObject.transform.position
		--世界坐标转本地
		local pos=Vector3.zero--self.view.MainFrame.bottom.gameObject.transform:InverseTransformVector(resourcePos)
		local o = prefab_fly and UnityEngine.GameObject.Instantiate(prefab_fly,self.view.MainFrame.bottom.gameObject.transform);
		o.layer = UnityEngine.LayerMask.NameToLayer("Default");
		for i = 0,o.transform.childCount-1 do
			o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("Default");
		end
		o.transform.localPosition = Vector3(pos.x,pos.y,pos.z)

		local resourceNode=CS.SGK.UIReference.Setup(self.OwnRescourceUI[resourceId]).Icon.gameObject.transform

		local curr_Pos = resourceNode:TransformPoint(o.transform.localPosition)
		local targetPos = o.transform:InverseTransformPoint(curr_Pos);
		o.transform:DOLocalMove(Vector3(targetPos.x,targetPos.y,targetPos.z),0.5):OnComplete(function( ... )
			if resourceNode then
				local fx_o  = prefab_explode and UnityEngine.GameObject.Instantiate(prefab_explode, resourceNode);
				fx_o.layer = UnityEngine.LayerMask.NameToLayer("Default");
				for i = 0,fx_o.transform.childCount-1 do
					fx_o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("Default");
				end
				fx_o.transform.localPosition =Vector3(0,0,-5) 
				fx_o.transform.localScale = Vector3.one*100
				fx_o.transform.localRotation = Quaternion.identity;  
				local _obj = fx_o :GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
				UnityEngine.Object.Destroy(fx_o , _obj.main.duration)                              
			end
			CS.UnityEngine.GameObject.Destroy(o)
		end)
	end
end

function View:InGameOver(data)
	DialogStack.PushPrefStact("DefensiveFortress/ClearGameFrame",{status=data[1],Rewards=data[2]});
	if self.gameObject then
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end
end

local lastGetTime=0
local GetInterval=5
local tipTab={"yuansubaozou_tips_01","yuansubaozou_tips_02","yuansubaozou_tips_03","yuansubaozou_tips_04"}
function View:updateTipShow()
	if not lastGetTime then
		lastGetTime=Time.now()
	else
		if Time.now()-lastGetTime>=GetInterval then
			lastGetTime=Time.now()
			local _tip=defensiveModule.GetRandom(tipTab,self.teamInfo.id,3)
			self.view.MainFrame.bottom.tipData.Text[UI.Text].text=SGK.Localize:getInstance():getValue(_tip)
		end
	end
end

function View:Update()
	--每5秒更新一次tip
	if self.view.MainFrame.bottom.tipData.Image.activeSelf then
		self:updateTipShow()
	end
	--更新boss状态
	self:updateBossStatusText()
end

function View:listEvent()
	return {
		"FORTRESS_GAME_OVER",
		"RESOURCES_NUM_CHANGE",
		"LOCAL_GUIDE_CHANE",
		"BOSS_DATA_CHANGE",
		"START_COLLECT_RESOURCES",
		"LOCAL_MAPINFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event =="RESOURCES_NUM_CHANGE" then
		self:InResourcesChange(data)
	elseif event=="BOSS_DATA_CHANGE" then
		self:updateBossStatus(data)
	elseif event =="START_COLLECT_RESOURCES" then
		self:TryCollectResources(data)
	elseif event =="FORTRESS_GAME_OVER" then
		self:InGameOver(data)
	elseif event=="LOCAL_GUIDE_CHANE" then
		if data==9001 then
			defensiveModule.QueryMapInfo(self._tab)
			self.view.MainFrame.gameObject:SetActive(true)
			module.guideModule.PlayWaitTime(9002)
		elseif data==9002 then
			utils.SGKTools.ShowDlgHelp(TipCfg.GetAssistDescConfig(70001).info,TipCfg.GetAssistDescConfig(70001).tittle, self.root)
		end
	elseif event=="LOCAL_MAPINFO_CHANGE" then
		self:Init(data)
	end
end
 
return View;