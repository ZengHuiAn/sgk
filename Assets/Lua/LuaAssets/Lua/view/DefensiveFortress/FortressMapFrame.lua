local fightModule = require "module.fightModule"
local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local TeamModule = require "module.TeamModule"
local Time = require "module.Time";
local View = {};


function View:Start()
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.ScrollView.Viewport.Content.map

	self.teamInfo = TeamModule.GetTeamInfo();
	self.mapInfoCfg=defensiveModule.GetMapCfg()
	self.resourcesCfg=defensiveModule.GetResourceCfg()
	self.Pid=playerModule.GetSelfID()
end

function  View:InitData(data)
	self.BossData=data and data.BossData
	self.PlayerData=data and  data.PlayerData
	self.OwnResource=data and data.OwnResource
	self.PlayerCfg=data and data.PlayerCfg

	self.node=data and data.node
	self.targetPos=data and data.targetPos

	self.mapInfo={}
	for i=1,#self.mapInfoCfg do
		self.mapInfo[self.mapInfoCfg[i].Site_id]=data.MapPointData[self.mapInfoCfg[i].Site_id]
		self.mapInfo[self.mapInfoCfg[i].Site_id].Pos=self.view.mapPoint[i]
		self.mapInfo[self.mapInfoCfg[i].Site_id].Idx=i
		self.mapInfo[self.mapInfoCfg[i].Site_id].BossMark=self.view.BossMark[i]	
		self.mapInfo[self.mapInfoCfg[i].Site_id].ResourcesPoint=self.view.resourcesPoint[i]

		self.mapInfo[self.mapInfoCfg[i].Site_id].Pos.gameObject:SetActive(true)	
		self.view.mapPoint[i].gameObject.name=tostring(self.mapInfoCfg[i].Site_id)
	end
	self:InitView()
end

function View:InitView()
	self.view.FortressRoleContral.gameObject:SetActive(true)
	self.view.FortressRoleContral[SGK.LuaBehaviour]:Call("InitData",{MapInfo= self.mapInfo,BossData=self.BossData,PlayerData=self.PlayerData,teamInfo=self.teamInfo,PlayerCfg=self.PlayerCfg})

	CS.UGUIClickEventListener.Get(self.view.buttonGroup.btns.addPitFallBtn.gameObject).onClick = function (obj)
		self.view.buttonGroup.gameObject:SetActive(false)
		self.root.AddPitFallFrame.gameObject:SetActive(true)
		self.root.AddPitFallFrame[SGK.LuaBehaviour]:Call("InitData",{mapInfo=self.mapInfo,PlayerData=self.PlayerData,BossId=self.BossData.Id,OwnResource=self.OwnResource})
	end

	CS.UGUIClickEventListener.Get(self.view.buttonGroup.btns.diversionBtn.gameObject).onClick = function (obj)
		self.view.buttonGroup.gameObject:SetActive(false)
		self.root.DiversionFrame.gameObject:SetActive(true)
		self.root.DiversionFrame[SGK.LuaBehaviour]:Call("InitData",{mapInfo=self.mapInfo,PlayerData=self.PlayerData,BossId=self.BossData.Id,OwnResource=self.OwnResource}) 
	end

	CS.UGUIClickEventListener.Get(self.view.buttonGroup.btns.collectBtn.gameObject).onClick = function (obj) 
		self.view.buttonGroup.gameObject:SetActive(false)
		--print("map PLayer .PosId",self.PlayerData[self.Pid].PosId)
		if not self.mapInfo[self.PlayerData[self.Pid].PosId].ResourceCd then
			defensiveModule.QueryCollection()
		else
			showDlgError(nil,"暂时还不能搜集资源")
			self.view.buttonGroup.gameObject:SetActive(true)
		end
	end
	CS.UGUIClickEventListener.Get(self.view.buttonGroup.gameObject,true).onClick = function (obj) 
		self.view.buttonGroup.gameObject:SetActive(false)
	end

	CS.UGUIClickEventListener.Get(self.view.buttonGroup.btns.openBoxBtn.gameObject).onClick = function (obj) 
		ERROR_LOG(self.PlayerData[self.Pid].OpenTimes)
		if self.PlayerData[self.Pid].OpenTimes<10 then
			self:InOpenBox()
		else
			showDlgError(nil,"今日已达到开启上限")
		end
	end

	CS.UGUIClickEventListener.Get(self.view.buttonGroup.btns.repairBtn.gameObject).onClick = function (obj) 
		self:InRepairPoint()
	end

	for i=1,#self.mapInfoCfg do
		CS.UGUIClickEventListener.Get(self.view.mapPoint[i].Button.gameObject).onClick = function (obj) 
			self:OnClickPoint(i)
		end
	end

	self.movePoint=self.view.FortressRoleContral.movePoint
	self.resourcesPoint=self.view.resourcesPoint
	local BossCfg=defensiveModule.GetBossCfg(self.BossData.Id)--BossCfg.Monster_type
	local IsHurt=false--是否有与Boss属性相克的陷阱
	for k,v in pairs(self.mapInfo) do
		local cfg=defensiveModule.GetMapCfg(k)
		self.mapInfo[k].Pos.pitFallIcon.gameObject:SetActive(cfg.Is_Pitfall==1)	
		if cfg.Is_Pitfall==1 then
			--刷新陷阱
			local pitFallCfg =defensiveModule.GetPitFallLevelCfg(v.Pitfall_type,v.Pitfall_level)
			self.mapInfo[k].Pos.pitFallIcon[UI.Image]:LoadSprite("propertyIcon/"..pitFallCfg.Pitfall_icon)
			--地图Boss瞄准
			self.movePoint[self.mapInfo[k].Idx].Aim.gameObject:SetActive(v.Pitfall_type==BossCfg.restrain_type)
			if v.Pitfall_type==BossCfg.restrain_type then
				self.movePoint[self.mapInfo[k].Idx].Aim.AimIcon.gameObject.transform:DOScale(Vector3(0.5,0.5,0.5),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo)
				IsHurt=true
			end
			--刷新资源
			self.resourcesPoint[self.mapInfo[k].Idx].ResourcesRoot.Resource.Icon[UI.Image]:LoadSprite("propertyIcon/"..self.resourcesCfg[self.mapInfo[k].Resource_Id].Resource_icon)	
		end
		self.resourcesPoint[self.mapInfo[k].Idx].ResourcesRoot.Resource.gameObject:SetActive(v.Status==0 and cfg.Is_Pitfall==1)
		--刷新地图宝箱
		self.resourcesPoint[self.mapInfo[k].Idx].ResourcesRoot.Box.gameObject:SetActive(v.Box_Id~=0)
		--chooseObject
		self.mapInfo[k].Pos.choose.gameObject:SetActive(false)
		self.view.BossMark[self.mapInfo[k].Idx].choose1.gameObject:SetActive(false)
	end
	--诱敌显示
	for i,v in ipairs(self.mapInfo[self.BossData.PosId].Monster_site) do
		if self.mapInfo[v].Diversion_value~=0 then
			self.view.BossMark[self.mapInfo[self.BossData.PosId].Idx].choose1.mask[i].gameObject.transform:DOScale(Vector3(0.5,0.5,0.5),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo)
		end
	end
end

function View:ReturnTip()
	if self.PlayerData[self.Pid].Action==10 then
		showDlgError(nil,"移动中")
		return true
	elseif self.PlayerData[self.Pid].Action == 14 then
		showDlgError(nil,"被魔王打晕,昏迷中")
		return true
	elseif self.PlayerData[self.Pid].Action == 21 then
		showDlgError(nil,"别急,看看箱子里有什么")
		return true
	elseif self.PlayerData[self.Pid].Action == 22 then
		showDlgError(nil,"正在努力工作")
		return true
	elseif self.PlayerData[self.Pid].Action==23 then
		showDlgError(nil,"采集中")
		return true
	end
end

local delayTime={
		[10]=defensiveModule.GetActionTimeCfg(2).Move_time/1000,
		[101]=defensiveModule.GetActionTimeCfg(2).Move_cd/1000,
		[12]=defensiveModule.GetActionTimeCfg(2).Imprison_time/1000,--禁锢
		[14]=defensiveModule.GetActionTimeCfg(2).Forbid_time/1000,--昏迷
		[21]=defensiveModule.GetActionTimeCfg(2).Openbox_time/1000,
		[22]=defensiveModule.GetActionTimeCfg(2).Repair_time/1000,
		[23]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,--搜集时间
		[30]=defensiveModule.GetActionTimeCfg(3).Resoure_produce_time/1000,--10--采集冷却时间
	}

function View:OnClickPoint(idx)
	if self.mapInfoCfg[idx].Is_Pitfall==0 then return end --该配置点是否有陷阱 有 为操作点 else 非 是否可操作
	if self:ReturnTip() then return end
	self.curClickPosId=self.mapInfoCfg[idx].Site_id
	if self.PlayerData[self.Pid].PosId==self.curClickPosId then
		self.view.buttonGroup.gameObject:SetActive(not self.view.buttonGroup.gameObject.activeSelf)
		if not self.view.buttonGroup.gameObject.activeSelf then return end
		--玩家在这个点打开功能
		--据点是否被破坏 0 为 完好  1为破坏
		self.view.buttonGroup.btns.repairBtn.gameObject:SetActive(self.mapInfo[self.curClickPosId].Status==1)
		--如果玩家所在点在Boss下一次移动的范围内 则可诱敌 
		local CanDiversion=false
		for i,v in ipairs(self.mapInfo[self.BossData.PosId].Monster_site) do
			if v==self.curClickPosId then
				CanDiversion=true
				break
			end
		end
		self.view.buttonGroup.btns.diversionBtn.gameObject:SetActive(CanDiversion)
		--是否有宝箱
		self.view.buttonGroup.btns.openBoxBtn.gameObject:SetActive(self.mapInfo[self.curClickPosId].Box_Id~=0)
		--采集资源冷却 并且据点完好
		local _case=(Time.now()-self.mapInfo[self.mapInfoCfg[idx].Site_id].LastCollectTime)>=(delayTime[23]+delayTime[30])
		self.view.buttonGroup.btns.collectBtn.gameObject:SetActive(not not _case and self.mapInfo[self.curClickPosId].Status==0)

		local Point=self.view.mapPoint[idx].gameObject.transform.position
		self.view.buttonGroup.btns.gameObject.transform.position=Vector3(Point.x-0.2,Point.y,0)	
	else--移动
		self.view.buttonGroup.gameObject:SetActive(false)
		local _pos=self.mapInfo[self.curClickPosId].Pos.gameObject.transform.localPosition

		if self.PlayerData[self.Pid].Status == 12 then
			showDlgError(nil,"你被魔王囚禁了,哪也去不了")
		elseif next(self.PlayerData[self.Pid].Path)~=nil then
			showDlgError(nil,"移动中")
		else
			DispatchEvent("APPLY_PLAYER_MOVE",{targetPosId=self.curClickPosId,pid=self.Pid})
		end
	end
end

function View:RefPointInfoShow(data)
	-- print("据点信息变化",sprinttb(data))
	if self.mapInfo[data.PosId] then
		if self.mapInfo[data.PosId].Resource_Id~=data.NextResourceId and self.mapInfo[data.PosId].NextResourceId~=data.NextResourceId then
			self:InCollectResources(data.Pid,data.NextResourceId,data.PosId,data.LastActionTime)
		end

		if self.mapInfo[data.PosId].Pitfall_level~=data.Pitfall_level then
			self:InPitFallLevelChange(data.Pid,data.PosId,data.Pitfall_level,data.LastActionTime)
		end

		if self.mapInfo[data.PosId].Diversion_value~=data.Diversion_value then
			self:InDiversionValueChange(data.Pid,data.PosId,data.Diversion_value,data.LastActionTime)
		end
		if self.mapInfo[data.PosId].Status~=data.Status then--据点状态变化 
			self.mapInfo[data.PosId].Status=data.Status
			self.resourcesPoint[self.mapInfo[data.PosId].Idx].ResourcesRoot.Slider.gameObject:SetActive(false)
			self.resourcesPoint[self.mapInfo[data.PosId].Idx].ResourcesRoot.Resource.gameObject:SetActive(self.mapInfo[data.PosId].Status==0)
		end

		if self.mapInfo[data.PosId].Box_Id~=data.Box_Id then--box状态变化 
			self.mapInfo[data.PosId].Box_Id=data.Box_Id
			self.resourcesPoint[self.mapInfo[data.PosId].Idx].ResourcesRoot.Box.gameObject:SetActive(data.Box_Id~=0)
		end
	end
end

function View:InDiversionValueChange(pid,PosId,Diversion_value,LastActionTime)
	self.mapInfo[PosId].Diversion_value=Diversion_value
	self.PlayerData[pid].LastDiversionTime=LastActionTime
	if pid==self.Pid then
		DispatchEvent("DIVERSION_VALUE_CHANGE",{Diversion_value=Diversion_value,LastDiversionTime=LastActionTime});
	end

	if Diversion_value< 6000 then
		for i,v in ipairs(self.mapInfo[self.BossData.PosId].Monster_site) do
			if v==PosId then
				self.view.BossMark[self.mapInfo[self.BossData.PosId].Idx].choose1.mask[i].gameObject.transform:DOScale(Vector3(0.5,0.5,0.5),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo)
				break
			end
		end
	end
end

function View:InPitFallLevelChange(pid,PosId,Pitfall_level,LastActionTime)
	self.PlayerData[pid].LastAddTime=LastActionTime
	self.PlayerData[pid].Action=24
	self.mapInfo[PosId].NextPitfall_level=Pitfall_level
	if pid==self.Pid then
		DispatchEvent("PITFALL_LEVEL_CHANGE",{NextPitfall_level=Pitfall_level,LastAddTime=LastActionTime});
	end
end

function View:InPlayerAction(_Slider,actionIdx,Pid)
	_Slider.gameObject:SetActive(true)
	_Slider[UI.Slider].maxValue=delayTime[actionIdx]
	self.PlayerData[Pid].StartActionTime=Time.now()
	self.PlayerData[Pid].Action=actionIdx
end

function View:InCollectResources(Pid,NextResourceId,PosId,lastCollectTime)
	print("资源搜集中")
	self.mapInfo[PosId].ResourceCd=true
	self.mapInfo[PosId].LastCollectTime=lastCollectTime
	local _Slider=self.resourcesPoint[self.mapInfo[PosId].Idx].ResourcesRoot.Resource.Slider
	self.mapInfo[PosId].NextResourceId=NextResourceId
	self:InPlayerAction(_Slider,23,Pid)
end

function View:InOpenBox()
	self.view.buttonGroup.gameObject:SetActive(false)
	local _Slider=self.resourcesPoint[self.mapInfo[self.PlayerData[self.Pid].PosId].Idx].ResourcesRoot.Box.Slider
	self:InPlayerAction(_Slider,21,self.Pid)	
end

function View:InRepairPoint()
	self.view.buttonGroup.gameObject:SetActive(false)
	local _Slider=self.resourcesPoint[self.mapInfo[self.PlayerData[self.Pid].PosId].Idx].ResourcesRoot.Slider
	self:InPlayerAction(_Slider,22,self.Pid)
end

--收集资源
function View:TryCollectResources(data)
	--print("--收集资源"..sprinttb(data))
	if data[3]==0 then--0为搜集资源
		showDlgError(nil,"资源搜集中")		
		--收集完成后播放收集特效
		SGK.Action.DelayTime.Create(delayTime[23]):OnComplete(function()
            self:ShowGetResourcesEffect(data[4])
        end) 
	else--进入战斗
		local PosInfo=defensiveModule.getMapCfgById(self.PlayerData[self.Pid].PosId)
		local fightId=PosInfo.Combat_id
		--local fight_data=data[3]
		fightModule.StartFight(fightId,nil,function (win,heros,starInfo)
			defensiveModule.QueryAfterFight()
		end)
	end
end

function View:MoveMapPos()
	local offPos=self.root.ScrollView.Viewport.Content.gameObject.transform.localPosition-self.view.mapPoint.gameObject.transform.localPosition
	self.root.ScrollView.Viewport.Content.gameObject.transform.localPosition=offPos/2-self.movePoint[self.mapInfo[self.PlayerData[self.Pid].PosId].Idx].gameObject.transform.localPosition
end

function View:RefMapBoxShow()
	for k,v in pairs(self.mapInfo) do--宝箱	
		self.resourcesPoint[self.mapInfo[k].Idx].ResourcesRoot.Box.gameObject:SetActive(v.Box_Id~=0)
	end	
end

--1：破坏据点，2：发呆，3：生命回复4.移动
	--玩家状态 10：移动，11.资源减少12：禁锢，13.攻击boss 14：无法行动20秒 20.待机-发呆
	-- 21开宝箱 22修复据点 23 搜集资源  24 强化陷阱
function View:UpdateTimeText()
	if self.mapInfo==nil then return end
	--资源冷却
	for k,v in pairs(self.mapInfo) do
		if self.mapInfo[k].ResourceCd then
		 	local time=v.LastCollectTime+delayTime[30]+delayTime[23]-Time.now()
		 	if time<0 then
		 		self.mapInfo[k].ResourceCd=false
		 		self.mapInfo[k].Resource_Id=self.mapInfo[k].NextResourceId
				self.resourcesPoint[self.mapInfo[k].Idx].ResourcesRoot.Resource.Icon[UI.Image]:LoadSprite("propertyIcon/"..self.resourcesCfg[self.mapInfo[k].Resource_Id].Resource_icon)
				self.resourcesPoint[self.mapInfo[k].Idx].ResourcesRoot.Resource.gameObject:SetActive(self.mapInfo[k].Status==0)
		 	end
		end
	end
		
	for k,v in pairs(self.teamInfo.members) do
		if self.PlayerData[v.pid].Action==21 then
			local time=Time.now()-self.PlayerData[v.pid].StartActionTime
			local _Slider=self.resourcesPoint[self.mapInfo[self.PlayerData[v.pid].PosId].Idx].ResourcesRoot.Box.Slider
			if time<delayTime[21] then
				_Slider[UI.Slider].value=time
			else
				_Slider.gameObject:SetActive(false)
				defensiveModule.QueryOpenBox(v.pid)
				DispatchEvent("PLAYER_ACTION_CHANGE",{pid=v.pid,actionIdx=0});
				self.PlayerData[v.pid].Action=0
			end
		end
		if self.PlayerData[v.pid].Action==22 then
			local time=Time.now()-self.PlayerData[v.pid].StartActionTime
			local _Slider=self.resourcesPoint[self.mapInfo[self.PlayerData[v.pid].PosId].Idx].ResourcesRoot.Slider
			if time< delayTime[22] then
				_Slider[UI.Slider].value=time
			else
				_Slider.gameObject:SetActive(false)
				defensiveModule.QueryRepairPoint()
				DispatchEvent("PLAYER_ACTION_CHANGE",{pid=v.pid,actionIdx=0});
				self.PlayerData[v.pid].Action=0
			end
		end

		if self.PlayerData[v.pid].Action==23 then
			local time=Time.now()-self.PlayerData[v.pid].StartActionTime
			local _Slider=self.resourcesPoint[self.mapInfo[self.PlayerData[v.pid].PosId].Idx].ResourcesRoot.Resource.Slider
			if time<delayTime[23] then
				_Slider[UI.Slider].value=time
			else
				--print("收集资源结束",delayTime[23],Time.now(),self.BossData.ChangeStatusTime)
				_Slider.gameObject:SetActive(false)
				self.resourcesPoint[self.mapInfo[self.PlayerData[v.pid].PosId].Idx].ResourcesRoot.Resource.gameObject:SetActive(false)
				DispatchEvent("PLAYER_ACTION_CHANGE",{pid=v.pid,actionIdx=0});
				self.PlayerData[v.pid].Action=0
			end
		end
	end

	if self.BossData.Status==1 then
		local _breakTime=defensiveModule.GetActionTimeCfg(self.BossData.Id).incident1_time/1000
		local time=Time.now()-self.BossData.ChangeStatusTime
		local _Slider=self.resourcesPoint[self.mapInfo[self.BossData.PosId].Idx].ResourcesRoot.Slider
		_Slider[UI.Slider].maxValue=_breakTime
		_Slider.gameObject:SetActive(true)
		if time<_breakTime then
			_Slider[UI.Slider].value=time
		-- else
		-- 	_Slider.gameObject:SetActive(false)
		-- 	self.resourcesPoint[self.mapInfo[self.BossData.PosId].Idx].ResourcesRoot.gameObject:SetActive(false)
		end
	end
end

function View:Update()
	self:UpdateTimeText()
end

function View:ShowGetResourcesEffect(_resourcesInfo)
	local prefab_fly = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_lizi.prefab"); 
	local prefab_explode = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_bao.prefab");

	for i=1,#_resourcesInfo do
		local posId=_resourcesInfo[i][1]
		local resourceId=_resourcesInfo[i][2]
		local resourcePos=self.resourcesPoint[self.mapInfo[posId].Idx].gameObject.transform.position
		--世界坐标转本地
		local pos=self.node.MainFrame.bottom.gameObject.transform:InverseTransformVector(resourcePos)
		local o = prefab_fly and UnityEngine.GameObject.Instantiate(prefab_fly,self.node.MainFrame.bottom.gameObject.transform);
	    o.layer = UnityEngine.LayerMask.NameToLayer("Default");
	    for i = 0,o.transform.childCount-1 do
	        o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("Default");
	    end
	    o.transform.localPosition =Vector3(pos.x,pos.y,-5)

	   	local resourceNode=CS.SGK.UIReference.Setup(self.targetPos[resourceId]).gameObject.transform
	    local targetPos=self.node.MainFrame.bottom.gameObject.transform:InverseTransformVector(resourceNode.position)
	    o.transform:DOLocalMove(Vector3(targetPos.x,targetPos.y,-5),1):OnComplete(function( ... )
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

function View:listEvent()
	return {
		"POINT_INFO_CHANGE",
		"OPEN_BOX_INFO_CHANGE",
		"START_COLLECT_RESOURCES",
		"MOVE_MAP_POS",
		"START_BREAK_POINT",
		"PLAYER_MOVE_OVER",
		"BOSS_MOVE_OVER",
	}
end

function View:onEvent(event,data)
	if event =="POINT_INFO_CHANGE" then
		self:RefPointInfoShow(data)
	elseif event =="OPEN_BOX_INFO_CHANGE" then
		ERROR_LOG(data[1],data[2])
		self.PlayerData[data[1]].OpenTimes=data[2]
		-- self.mapInfo[self.PlayerData[self.Pid].PosId].Box_Id=0
		-- self.resourcesPoint[self.mapInfo[self.PlayerData[self.Pid].PosId].Idx].ResourcesRoot.Box.gameObject:SetActive(false)
	elseif event =="START_COLLECT_RESOURCES" then
		self:TryCollectResources(data)
	elseif event =="MOVE_MAP_POS" then
		self:MoveMapPos()
	elseif event =="PLAYER_MOVE_OVER" then
		self:OnClickPoint(self.mapInfo[data].Idx)
	elseif event =="BOSS_MOVE_OVER" then
		self:RefMapBoxShow()
	end
end
 
return View;