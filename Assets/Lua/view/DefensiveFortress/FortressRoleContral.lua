local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local Time = require "module.Time";
local View = {};

function View:Start()
	self.view=CS.SGK.UIReference.Setup(self.gameObject)
	self.mapInfoCfg=defensiveModule.GetMapCfg()
	self.Pid=playerModule.GetSelfID()
	self.PlayerUI={}	
end

function  View:InitData(data)
	self.mapInfo=data and data.MapInfo
	self.BossData=data and data.BossData
	self.PlayerData=data and data.PlayerData
	self.teamInfo=data and data.teamInfo
	self.PlayerCfg=data and data.PlayerCfg

	self.BossCfg=defensiveModule.GetBossCfg(self.BossData.Id)--BossCfg.Monster_type

	self.BossStartCD=true
	self.BossStartMoveCD=60*2
	self:InitView()
end

function View:InitView()
	self.Boss=self.view.Roles.Boss.gameObject
	self.movePoint=self.view.movePoint
	self:RefBossData()
	self:RefPlayerData()
end

function View:RefBossData()
	self.Boss:SetActive(self.BossStartCD)
	self.view.Roles.Boss.TimeCD.gameObject:SetActive(self.BossStartCD)

	local _boss=SGK.UIReference.Setup(self.Boss)
	local propertyCfg=defensiveModule.GetResourceCfgById(self.BossCfg.Monster_type)
	_boss.Icon[UI.Image]:LoadSprite("icon/"..self.BossCfg.Monster_icon)
	_boss.property[UI.Image]:LoadSprite("propertyIcon/"..propertyCfg.Resource_icon)	

	self.BossHp=defensiveModule.GetBossCfg(self.BossData.Id).Monster_hp
	self.LastHP=self.BossData.BossHp

	_boss.Slider[UI.Slider].maxValue=self.BossHp
	_boss.Slider[UI.Slider].value=math.ceil(self.LastHP)

	self.mapInfo[self.BossData.PosId].BossMark.choose1.gameObject:SetActive(self.BossData.Status~=4)

	CS.UGUIClickEventListener.Get(_boss.gameObject).onClick = function (obj)
		DispatchEvent("ON_ClICK_BOSSICON",{BossData=self.BossData,LastHP=self.LastHP})
	end
	self:UpdateOffRolePos()
end

function View:RefPlayerData()
	if next(self.PlayerData)~=nil then
		local prefab=self.view.Roles.player.gameObject
		for k,v in pairs(self.PlayerData) do	
			local _player=nil
			_player,self.PlayerUI=defensiveModule.CopyUI(self.PlayerUI,self.movePoint.RoleRoot.gameObject.transform,prefab,k)
			_player.Icon[UI.Image]:LoadSprite("icon/"..(self.PlayerCfg[k] and self.PlayerCfg[k].head and (self.PlayerCfg[k].head~=0 and self.PlayerCfg[k].head or 11000) or 11000))
			_player.arrow.gameObject:SetActive(false)
			self.PlayerData[k].Item=_player
			--玩家计时条
			_player.TimeCD.gameObject:SetActive(self.PlayerData[k].Status==10 or self.PlayerData[k].Status==12 or self.PlayerData[k].Status==14)

			if k==self.Pid then
				self.mapInfo[self.PlayerData[k].PosId].Pos.choose.gameObject:SetActive(self.PlayerData[k].Status~=10)
				_player.arrow[UI.Image]:DOFade(0,0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
			end
			self:UpdateOffRolePos(k)	
		end
	end
end
--1：破坏据点，2：发呆，3：生命回复4.移动
--10：移动，11.资源减少12：禁锢，13.攻击boss 14：无法行动20秒 15开宝箱 16修复据点 17 搜集资源  30地图资源冷却
local delayTime={
		[10]=defensiveModule.GetActionTimeCfg(2).Move_time/1000,
		[101]=defensiveModule.GetActionTimeCfg(2).Move_cd/1000,
		[12]=defensiveModule.GetActionTimeCfg(2).Imprison_time/1000,--禁锢
		[14]=defensiveModule.GetActionTimeCfg(2).Forbid_time/1000,--昏迷
		[17]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,--搜集时间
		[21]=defensiveModule.GetActionTimeCfg(2).Openbox_time/1000,
		[22]=defensiveModule.GetActionTimeCfg(2).Repair_time/1000,
		[23]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,
		[30]=defensiveModule.GetActionTimeCfg(3).Resoure_produce_time/1000,--10--采集冷却时间
	}
function View:UpdateOffRolePos(pid)
	local _role=pid and self.PlayerData[pid].Item or SGK.UIReference.Setup(self.Boss)
	local _status=pid and self.PlayerData[pid].Status or self.BossData.Status
	local TargetStatus=pid and 10 or 4
	if _status ==TargetStatus then
		local MoveInterval=pid and delayTime[10] or defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000
		self.BossData.ChangeStatusTime=type(self.BossData.ChangeStatusTime)=="string" and Time.now() or self.BossData.ChangeStatusTime
		local detal=pid and (MoveInterval+self.PlayerData[pid].LastMoveTime-Time.now()) or (MoveInterval+self.BossData.ChangeStatusTime-Time.now())
		if pid then
			self.PlayerData[pid].NextPosId=self.PlayerData[pid].PosId
			self.PlayerData[pid].PosId=self.PlayerData[pid].LastPosId
		else
			self.BossData.NextPosId=self.BossData.PosId
			self.BossData.PosId=self.BossData.LastPosId
		end
		local RoleRoot=pid and self.movePoint.RoleRoot or self.movePoint.BossRoot

		_role.transform:SetParent(RoleRoot.gameObject.transform,false);

		local posStart=pid and self.movePoint[self.mapInfo[self.PlayerData[pid].PosId].Idx].gameObject.transform.localPosition or self.movePoint[self.mapInfo[self.BossData.PosId].Idx].gameObject.transform.localPosition
		local posEnd=pid and self.movePoint[self.mapInfo[self.PlayerData[pid].NextPosId].Idx].gameObject.transform.localPosition or self.movePoint[self.mapInfo[self.BossData.NextPosId].Idx].gameObject.transform.localPosition
		local off=pid and Vector3(-50,100,0) or Vector3(0,50,0)

		_role.transform.localPosition=Vector3.Lerp(posStart+off,posEnd+off,(MoveInterval-detal)/MoveInterval)
		_role.transform:DOLocalMove(Vector3(posEnd.x+off.x,posEnd.y+off.y,posEnd.z),detal):SetEase(CS.DG.Tweening.Ease.Linear)
		_role.transform.localScale=Vector3(0.5,0.5,1)
		_role.TimeCD.transform.localScale=2*Vector3.one
	else
		local _Idx=pid and self.mapInfo[self.PlayerData[pid].PosId].Idx or self.mapInfo[self.BossData.PosId].Idx
		local parent=pid and self.movePoint[_Idx].RoleRoot or self.movePoint[_Idx].BossRoot
		_role.transform:SetParent(parent.gameObject.transform,false);
		_role.transform.localScale=Vector3.one
		_role.TimeCD.transform.localScale=Vector3.one
	end
end

--1：破坏据点，2：发呆，3：生命回复4.移动
function View:UpdateRoleStatus(data)
	--print("958==角色状态改变",data[2],data[3],data[4],sprinttb(data))
	if data[1]==0 then
		if self.BossData.Status~=data[3] then--当Boss状态变化时	
			if self.BossData.Status==4 then--移动结束
				self.BossData.NowHp=data[5]
				self:InBossMoveOver()
			end			
			self.BossData.ChangeStatusTime=data[4]
			self.BossData.Status=data[3]
			self:InUpdateRoleStatus(data)
		end
		--处理被玩家攻击 没引发Boss事件
		if self.LastHP~=data[5]then
			self.BossData.NowHp=data[5]
			self:InHpChange()
		end
	else
		if self.PlayerData[data[1]] then
			if self.PlayerData[data[1]].Status~=data[3] then		
				if self.PlayerData[data[1]].Status==10 then--移动结束后
					self:InPlayerMoveOver(data[1])
				elseif self.PlayerData[data[1]].Status==12 or self.PlayerData[data[1]].Status==14 then
					showDlgError(nil,string.format("%s恢复了自由",self.PlayerCfg[data[1]].name))
					local _player=CS.SGK.UIReference.Setup(self.PlayerUI[data[1]])
					_player.TimeCD.gameObject:SetActive(false)
				end
				self.PlayerData[data[1]].ChangeStatusTime=data[4]	
				self.PlayerData[data[1]].Status=data[3]
				self:InUpdateRoleStatus(data)
			else
				showDlgError(nil,string.format("%s被魔王打劫",self.PlayerCfg[data[1]].name))
			end
		end
	end	
end
--10：移动，11.资源减少12：禁锢，13.攻击boss 14：无法行动20秒 15开宝箱 16修复据点 17 搜集资源--20 待机
--1：破坏据点，2：发呆，3：生命回复4.移动
function View:InUpdateRoleStatus(data)
	--print("1064==="..sprinttb(data))
	if data[3]==1 then
		showDlgError(nil,"魔王开始破坏据点")
	elseif data[3]==2 then
		showDlgError(nil,"魔王懵圈了")
	elseif data[3]==3 then
		showDlgError(nil,"魔王开始疗伤")
	elseif data[3]==4 then
		
		showDlgError(nil,"魔王向据点发起攻击")
		self.mapInfo[self.BossData.PosId].BossMark.choose1.gameObject:SetActive(false)

		if self.BossData.PosId~=data[6] then
			self.Boss.transform.localPosition=self.movePoint[self.mapInfo[data[6]].Idx].gameObject.transform.localPosition+Vector3(0,50,0)
		end

		self.BossData.LastPosId=data[6]
		self.BossData.PosId=data[2]
		self.MapBoxInfo=data[6]

		self:UpdateOffRolePos()
	elseif data[3]==10 then--玩家移动
		if data[1]==self.Pid then
			self.mapInfo[self.PlayerData[self.Pid].PosId].Pos.choose.gameObject:SetActive(false)
		end
		self.PlayerData[data[1]].Action=10
		self.PlayerData[data[1]].Status=10

		local _player=CS.SGK.UIReference.Setup(self.PlayerUI[data[1]])
		_player.TimeCD.gameObject:SetActive(true)

		self.PlayerData[data[1]].LastMoveTime=data[4]

		if self.PlayerData[data[1]].PosId~=data[5] then
			local _nowPos=self.mapInfo[data[5]]
			_player.transform.localPosition=self.movePoint[_nowPos.Idx].gameObject.transform.localPosition+Vector3(-50,100,0)
		end
		self.PlayerData[data[1]].LastPosId=data[5]
		self.PlayerData[data[1]].PosId=data[2]

		self:UpdateOffRolePos(data[1])
	elseif data[3]==11 then
		showDlgError(nil,string.format("%s被魔王打劫!!!",self.PlayerCfg[data[1]].name))
	elseif data[3]==12 then
		showDlgError(nil,string.format("%s被魔王囚禁了",self.PlayerCfg[data[1]].name))
		self.PlayerData[data[1]].Path={}
		local _player=CS.SGK.UIReference.Setup(self.PlayerUI[data[1]])
        _player.TimeCD.gameObject:SetActive(true)
        self.PlayerData[data[1]].Status=12
       	self.PlayerData[data[1]].Path={}
	elseif data[3]==13 then
		showDlgError(nil,string.format("%s偷袭了魔王",self.PlayerCfg[data[1]].name))
		self.PlayerData[data[1]].Status=20
	elseif data[3]==14 then
		showDlgError(nil,string.format("%s被魔王打晕了",self.PlayerCfg[data[1]].name))
		self.PlayerData[data[1]].Path={}
		self.PlayerData[data[1]].Action=14
		self.PlayerData[data[1]].Path={}
		local _player=CS.SGK.UIReference.Setup(self.PlayerUI[data[1]])
		_player.TimeCD.gameObject:SetActive(true)
	end
end

function View:InBossMoveOver()
	if self.BossData.NextPosId then
		self.Boss.transform:DOKill()
		self.BossData.PosId=self.BossData.NextPosId
		self.mapInfo[self.BossData.PosId].BossMark.choose1.gameObject:SetActive(true)

		if self.mapInfoCfg[self.mapInfo[self.BossData.PosId].Idx].Is_Pitfall~=0  then--当boss在非据点不在受伤
			local _nowLevel=self.mapInfo[self.BossData.PosId].Pitfall_level
			local _nowtype=self.mapInfo[self.BossData.PosId].Pitfall_type
			local _PitFallCfg=defensiveModule.GetPitFallLevelCfg(_nowtype,_nowLevel)
			self:playEffect(_PitFallCfg.Effect_id,nil,1000)
		end
		self.Boss.transform.localPosition=self.movePoint[self.mapInfo[self.BossData.PosId].Idx].gameObject.transform.localPosition+Vector3(0,50,0)
		self.Boss.transform:SetParent(self.movePoint[self.mapInfo[self.BossData.PosId].Idx].BossRoot.gameObject.transform,false);
		
		self.view.Roles.Boss.TimeCD.transform.localScale=Vector3.one
		self.Boss.transform.localScale=Vector3.one
		DispatchEvent("BOSS_MOVE_OVER");
	end
end

function View:InPlayerMoveOver(pid)
	local _player=self.PlayerData[pid].Item
	_player.TimeCD.gameObject:SetActive(false)
	_player.transform:DOKill()
	self.PlayerData[pid].PosId=self.PlayerData[pid].NextPosId
	self.PlayerData[pid].Action=0
	local _nowPos=self.mapInfo[self.PlayerData[pid].PosId]
	--if pid==self.Pid then
	_nowPos.Pos.choose.gameObject:SetActive(pid==self.Pid)
	_player.transform.localPosition=self.movePoint[_nowPos.Idx].gameObject.transform.localPosition+Vector3(-50,100,0)
	if  next(self.PlayerData[pid].Path)~=nil  then
		_nowPos.Pos.choose.gameObject:SetActive(false)
		defensiveModule.QueryMove(self.PlayerData[pid].Path[#self.PlayerData[pid].Path])
		table.remove(self.PlayerData[pid].Path,#self.PlayerData[pid].Path)
	else
		_player.transform:SetParent(self.movePoint[_nowPos.Idx].RoleRoot.gameObject.transform,false);
		_player.TimeCD.transform.localScale=Vector3.one
		_player.transform.localScale=Vector3.one
		if pid==self.Pid then
			DispatchEvent("PLAYER_MOVE_OVER",self.PlayerData[pid].PosId);
		end
	end
	--end
	--玩家位置改变
	DispatchEvent("PLAYER_POS_CHANGE",{pid=pid,PosId=self.PlayerData[pid].PosId});
end

function View:InHpChange()
	local hp=self.BossData.NowHp
	local changeValue=math.ceil(hp-self.LastHP)
	self:ShowHartNum(changeValue)
	self.LastHP=hp
	local _boss=SGK.UIReference.Setup(self.Boss)
	_boss.Slider[UI.Slider].value=math.ceil(hp>=0  and hp or 0)
	self.view.Roles.Boss.TimeCD.gameObject:SetActive(hp>0)
end

--10：移动，11.资源减少12：禁锢，13.攻击boss 14：无法行动20秒 15开宝箱 16修复据点 17 搜集资源 30地图资源冷却
function View:InPlayerAction(_Slider,actionIdx,Pid)
	_Slider.gameObject:SetActive(true)
	_Slider[UI.Slider].maxValue=delayTime[actionIdx]
	self.PlayerData[Pid].StartActionTime=Time.now()
	self.PlayerData[Pid].Action=actionIdx
end

function View:playEffect(effectName, position, sortOrder)
	local _boss=SGK.UIReference.Setup(self.Boss)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" ..tostring(effectName) .. ".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, _boss.EffNode.gameObject.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation = Quaternion.identity;

        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
        local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
        _obj:Play()
       UnityEngine.Object.Destroy(o, _obj.main.duration)
    end
end

function View:ShowHartNum(value)
	local _boss=SGK.UIReference.Setup(self.Boss)
    local prefab = SGK.ResourcesManager.Load("prefabs/battlefield/hurt_normal.prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, _boss.EffNode.gameObject.transform);
    o.transform.localPosition =Vector3.zero;
    local nm = o:GetComponent(typeof(CS.NumberMovement));
     if not nm.text then
        nm.text = o:GetComponent(typeof(UnityEngine.UI.Text));
    end
    nm.text.text = string.format("%s%d%s",value>=0 and "<color=#3BFFBCFF>" or "<color=#FF1A1AFF>",value,"</color>");
end

function View:UpdateTimeShow(_player,pid,actionIdx,desc)
	if self.PlayerData[pid].Status==actionIdx then
		local rate=actionIdx==10 and #self.PlayerData[self.Pid].Path+1 or 1
		local time=self.PlayerData[pid].ChangeStatusTime+delayTime[actionIdx]*rate-Time.now()
		if time>=0 then
			_player.TimeCD[UI.Text].text=string.format("%s:%02d:%02d",desc,math.floor(math.floor(time/60)%60),math.floor(time%60))
		else
			_player.TimeCD.gameObject:SetActive(false)
			if actionIdx~=10 then
				self.PlayerData[pid].Action=0
				self.PlayerData[pid].Status=0
			end
		end
	end
end
function View:UpdateTimeText()
	if self.mapInfo==nil or not self.teamInfo then return end

	--玩家状态 10：移动，11.资源减少12：禁锢，13.攻击boss 14：无法行动20秒 20.待机-发呆
	-- 21开宝箱 22修复据点 23 搜集资源  24 强化陷阱
	for k,v in pairs(self.teamInfo.members) do
		if self.PlayerUI[v.pid] then
			local _player=CS.SGK.UIReference.Setup(self.PlayerUI[v.pid])
			self:UpdateTimeShow(_player,v.pid,10,"移动中")
			self:UpdateTimeShow(_player,v.pid,12,"囚禁中")
			self:UpdateTimeShow(_player,v.pid,14,"昏迷中")
		end
	end

    --Boss 初次移动倒计时	--1：破坏据点，2：发呆，3：生命回复4.移动 0.待机
	if self.BossStartCD then--游戏开始
		local time=Time.now()-self.BossData.GameStartTime

		if self.BossData.Status==0 then
			local _time=self.BossStartMoveCD+self.BossData.ChangeStatusTime-Time.now()
			if _time>0 then
				self.view.Roles.Boss.TimeCD[UI.Text].text=string.format("等待中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==1 then
			local _breakTime=defensiveModule.GetActionTimeCfg(self.BossData.Id).incident1_time/1000
			local _time=_breakTime+self.BossData.ChangeStatusTime-Time.now()
			local _Time=_breakTime-_time
			if _time>0 then
				self.view.Roles.Boss.TimeCD[UI.Text].text=string.format("破坏据点中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
				--self.mapInfo[self.mapInfoCfg[i].Site_id].ResourcesPoint
			else

			end
		end
		if self.BossData.Status==2 then
			local _sleepTime=defensiveModule.GetActionTimeCfg(self.BossData.Id).incident2_time/1000
			local _time=_sleepTime+self.BossData.ChangeStatusTime-Time.now()
			if _time>0 then
				self.view.Roles.Boss.TimeCD[UI.Text].text=string.format("发呆中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==3 then
			local _sleepTime=defensiveModule.GetActionTimeCfg(self.BossData.Id).incident3_time/1000
			local _time=_sleepTime+self.BossData.ChangeStatusTime-Time.now()
			if _time>0 then
				self.view.Roles.Boss.TimeCD[UI.Text].text=string.format("恢复生命中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			end
		end
		if self.BossData.Status==4 then
			local MoveInterval=defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000
			local _time=MoveInterval+self.BossData.ChangeStatusTime-Time.now()
			if _time>=0 then
				self.view.Roles.Boss.TimeCD[UI.Text].text=string.format("移动中:%02d:%02d",math.floor(math.floor(_time/60)%60),math.floor(_time%60))
			else
				self.view.Roles.Boss.TimeCD.gameObject:SetActive(false)
				self.BossData.Status=0
			end
		end
	end
end

function View:Update()
	self:UpdateTimeText()
end

function View:listEvent()
	return {
		"APPLY_PLAYER_MOVE",
		"ROlE_DATA_CHANGE",
		"MOVE_MAP_POS",
		"PLAYER_ACTION_CHANGE",--玩家行为改变
	}
end

function View:onEvent(event,data)
	if event=="APPLY_PLAYER_MOVE" then
		self.PlayerData[self.Pid].Path=defensiveModule.GetPath(self.PlayerData[self.Pid].PosId,data.targetPosId)
		if next(self.PlayerData[self.Pid].Path)~=nil then
			defensiveModule.QueryMove(self.PlayerData[self.Pid].Path[#self.PlayerData[self.Pid].Path])
			table.remove(self.PlayerData[self.Pid].Path,#self.PlayerData[self.Pid].Path)
		end
	elseif event =="ROlE_DATA_CHANGE" then
			self:UpdateRoleStatus(data)
	elseif event =="MOVE_MAP_POS" then
		local _player=CS.SGK.UIReference.Setup(self.PlayerUI[self.Pid])
		_player.arrow.gameObject:SetActive(true)
		SGK.Action.DelayTime.Create(2):OnComplete(function()
			_player.arrow.gameObject:SetActive(false)
		end)
	elseif event =="PLAYER_ACTION_CHANGE" then
		self.PlayerData[data.pid].Action=data.actionIdx
	end
end

 
return View;