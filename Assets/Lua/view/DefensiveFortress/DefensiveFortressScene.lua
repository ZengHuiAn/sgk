local defensiveModule = require "module.DefensiveFortressModule"
local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule";
local NpcTransportConf = require "config.MapConfig";
local Time = require "module.Time";

local View = {}
function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.content = self.view.MapSceneController;

	defensiveModule.QueryMapInfo()
end

local totalTime=15*60
function View:InItData(data)
	if not data then return end

	self.mapCfg = defensiveModule.GetMapCfg()
	self.sitePointCfg = defensiveModule.GetSitePoint()
	self.resourcesCfg = defensiveModule.GetResourceCfg()
	self.pitFallCfg = defensiveModule.GetPitFallLevelCfg()
	self.boxCfg = defensiveModule.GetBoxCfg()
	self.diversionCfg = defensiveModule.GetDiversionCfg()

	self.data  = data
	self.BossStartCD = true
	self.OwnResource = data and data.TeamResourceData --- 拥有资源数量
	self.PlayerData = data.PlayerData
	self.BossData = data.BossData
	self.mapInfo = data.MapPointData

	if self.BossData and Time.now()-self.BossData.GameStartTime <= totalTime then
		self.Pid = playerModule.GetSelfID()
		self.teamInfo = TeamModule.GetTeamInfo();
		self.PlayerCfg = {}
		for i,v in ipairs(self.teamInfo.members) do
			if playerModule.IsDataExist(v.pid) then
		        self.PlayerCfg[v.pid] = playerModule.IsDataExist(v.pid)
		    else
		        playerModule.Get(pid,function ( ... )
		            self.PlayerCfg[v.pid] = playerModule.Get(v.pid);
		        end)
		    end
		end

		self.BossData.NowHp = self.BossData.BossHp--显示用
		self:InItUI()

		if DialogStack.GetPref_list("DefensiveFortress/DefensiveFortressFrame") then
			DispatchEvent("LOCAL_MAPINFO_CHANGE",data); 
		end
	else
		if not self.BossData then
			ERROR_LOG("not self.BossData ")
		else
			ERROR_LOG("超时",Time.now()-self.BossData.GameStartTime<=totalTime)
		end	
		defensiveModule.BackToEntranceNpc()
	end
end

function View:InItUI()
	--创建Boss
	self:CreateBoss()
	--地图TeamResources
	self.MapItemTab = {}
	self.prefab = self.prefab or SGK.ResourcesManager.Load("prefabs/DefensiveFortress/ItemPrefab.prefab")

	for k,v in pairs(self.mapInfo) do
		if self.mapCfg[k].Is_Pitfall ~= 0 then--该据点是否有陷阱 能否产生资源
			--刷新陷阱   
			self:upDateMapPitFallShow(k,v.Pitfall_type,v.Pitfall_level)
			--刷新资源
			--if v.Status==0 then--据点状态是完好的
				self:updateMapResource(k,true)
			--end
			--刷新宝箱
			if v.Box_Id ~= 0 then
				self:updateMapBox(k,v.Box_Id)
			end
		end
	end

	if self.BossData.Status ~= 4 then
		--刷新路障
		local _siteCfg = self.mapCfg[self.BossData.PosId]
		if _siteCfg.Monster_site and next(_siteCfg.Monster_site) ~= nil then
			for i=1,#_siteCfg.Monster_site do
				local _next_siteId = _siteCfg.Monster_site[i]
				self:updateObstruct(_next_siteId,self.mapInfo[_next_siteId].Diversion_value,self.BossData.PosId,true)---该点的诱敌方式
			end
		end
	end
end

function View:upDateMapPitFallShow(siteId,pitfall_type,pitfall_level)
	self.MapItemTab["pitFall"]=self.MapItemTab["pitFall"] or {}
	if self.pitFallCfg[pitfall_type] and  self.pitFallCfg[pitfall_type][pitfall_level] then
		local pitFallCfg =self.pitFallCfg[pitfall_type][pitfall_level]
		local item
		item,self.MapItemTab["pitFall"]=defensiveModule.CopyUI(self.MapItemTab["pitFall"],self.content.gameObject.transform,self.prefab,"pitFall"..siteId)
		if item then
			local Item_Script=item[SGK.MapInteractableMenu]
			Item_Script.LuaTextName = "DefensiveFortress/AddPitFall"
			Item_Script.values = {siteId}

			local pos = self.mapCfg[siteId].pos

			self:updateSceneItemShow(item,pitFallCfg.Pitfall_mode,pos,pitFallCfg.Pitfall_name)
		end
	else
		ERROR_LOG(siteId," pitFallCfg nil ,type",pitfall_type,pitfall_level)
	end
end

function View:updateMapResource(siteId,show)
	self.MapItemTab["resource"]=self.MapItemTab["resource"] or {}
	if show then
		local resource_Id=self.mapInfo[siteId].Resource_Id
		local next_resource_Id=self.mapInfo[siteId].NextResourceId
		local resourceCfg=self.resourcesCfg[resource_Id]
		if resourceCfg then
			local item
			item,self.MapItemTab["resource"]=defensiveModule.CopyUI(self.MapItemTab["resource"],self.content.gameObject.transform,self.prefab,"resource"..siteId)
			
			if item then
				local Item_Script=item[SGK.MapInteractableMenu]
				Item_Script.LuaTextName = "DefensiveFortress/Collect"
				Item_Script.values = {siteId}

				local _seed = self.teamInfo and self.teamInfo.id+siteId or siteId 
				local _randomCfg = defensiveModule.GetRandom(self.sitePointCfg[1][siteId],_seed,1)
				local _pos = _randomCfg.pos

				self:updateSceneItemShow(item,resourceCfg.Resource_mode,_pos,resourceCfg.Resource_name)
			end
		else
			ERROR_LOG(siteId,"resourceCfg is nil,resource_Id",resource_Id)
		end
	else
		if self.MapItemTab["resource"]["resource"..siteId] then
			self.MapItemTab["resource"]["resource"..siteId].gameObject:SetActive(false)
		end
	end
end

function View:updateMapBox(siteId,box_Id)
	self.MapItemTab["box"]=self.MapItemTab["box"] or {}
	if box_Id and box_Id ~=0 then
		local boxCfg=self.boxCfg[box_Id]
		if boxCfg then
			local item
			item,self.MapItemTab["box"]=defensiveModule.CopyUI(self.MapItemTab["box"],self.content.gameObject.transform,self.prefab,"box"..siteId)

			if item then
				local Item_Script = item[SGK.MapInteractableMenu]
				Item_Script.LuaTextName = "DefensiveFortress/Open"
				Item_Script.values = {siteId}
				
				local _seed = self.teamInfo and self.teamInfo.id+siteId or siteId 
				local _randomCfg = defensiveModule.GetRandom(self.sitePointCfg[2][siteId],_seed,2)
				local _pos = _randomCfg.pos
				self:updateSceneItemShow(item,boxCfg.mode,_pos,"宝箱")
			end
		else
			ERROR_LOG(siteId,"boxCfg is nil,boxId",box_Id)
		end
	else
		if self.MapItemTab["box"]["box"..siteId] then
			self.MapItemTab["box"]["box"..siteId].gameObject:SetActive(false)
		end
	end
end

function View:updateObstruct(siteId,diversion_value,ownerSiteId,update)
	self.MapItemTab["obstruct"]=self.MapItemTab["obstruct"] or {}
	if update and self.BossData.Status~=4 then--移动状态不强制显示路障
		local _diversionId=self.mapCfg[siteId].Is_diversion--该据点的诱敌方式
		local _cfg=self.diversionCfg[_diversionId]
		if _cfg then
			local item
			item,self.MapItemTab["obstruct"]=defensiveModule.CopyUI(self.MapItemTab["obstruct"],self.content.gameObject.transform,self.prefab,"obstruct"..siteId)

			if item then
				local Item_Script=item[SGK.MapInteractableMenu]
				Item_Script.LuaTextName = "DefensiveFortress/AddObstruct"
				Item_Script.values = {siteId}
			
				local _pos = self.mapCfg[ownerSiteId].ObstructPos[siteId]
				local _rotate = self.mapCfg[ownerSiteId].ObstructRoa[siteId]
				local _socaleX = self.mapCfg[ownerSiteId].ObstructScaX[siteId]
				
				local _modeId
				if diversion_value ~= 0 then
					_modeId=_cfg.mode_after
					self:updateSceneItemShow(item,_modeId,_pos,"路障",_rotate,_socaleX)
				else
					_modeId=_cfg.mode_before
					self:updateSceneItemShow(item,_modeId,_pos,"路障")
				end
			end
		else
			ERROR_LOG(siteId,"divensionCfg is nil,diversionId",_diversionId)
		end
	else
		if self.MapItemTab["obstruct"]["obstruct"..siteId] and self.mapInfo[siteId].Diversion_value==0 then
			self.MapItemTab["obstruct"]["obstruct"..siteId].gameObject:SetActive(false)
		end
	end
end

function View:updateSceneItemShow(item,modeId,pos,name,_rotate,_ScaleX)
	item.transform.localPosition=pos
	item.Item.Label.name[UI.Text].text=name

	local modeCfg = NpcTransportConf.GetNpcTransport(modeId)
	for i = 1,item.node.transform.childCount do  
        UnityEngine.GameObject.Destroy(item.node.transform:GetChild(i-1).gameObject)
    end

	local _effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..modeCfg.modename .. ".prefab")

	if _effect then
		local Effect = CS.UnityEngine.GameObject.Instantiate(_effect,item.node.transform)
		Effect.transform.localPosition = Vector3.zero
		if _rotate and _ScaleX then
			Effect.transform.localScale = Vector3(modeCfg.Size_x*_ScaleX,modeCfg.Size_y,modeCfg.Size_z)
			Effect.transform.localRotation = Quaternion.Euler(_rotate)
		else
			Effect.transform.localScale = Vector3(modeCfg.Size_x,modeCfg.Size_y,modeCfg.Size_z)
		end

		local Collider = Effect:GetComponent(typeof(UnityEngine.BoxCollider))
		if utils.SGKTools.GameObject_null(Collider) == false then    
			Collider = Effect:GetComponent(typeof(UnityEngine.BoxCollider))
			item[UnityEngine.BoxCollider].center = Collider.center
			item[UnityEngine.BoxCollider].size = Collider.size
			Collider.enabled = false
		else
			item[UnityEngine.BoxCollider].center = Vector3(modeCfg.centent_x,modeCfg.centent_y,modeCfg.centent_z)
			item[UnityEngine.BoxCollider].size = Vector3(modeCfg.Size_x,modeCfg.Size_y,modeCfg.Size_z)
		end
	else
		ERROR_LOG("effect/UI is nil ,name:",modeCfg.modename)
	end
end

-- self.controller = self.content[SGK.MapSceneController];
--local character = self.mapController:Get(pid) 
--1：破坏据点，2：发呆，3：生命回复4.移动
function View:CreateBoss()
	local id = self.BossData.Id or 0
	local bossCfg = defensiveModule.GetBossCfg(id)

	local name = bossCfg.Monster_name
	local mode = bossCfg.Monster_mode
	local status = self.BossData.Status

	--SGK.ResourcesManager.Load("prefabs/DefensiveFortress/BossPrefab")--SGK.ResourcesManager.Load("prefabs/CharacterPrefab")----SGK.ResourcesManager.Load("prefabs/DefensiveFortress/CharacterPrefab")--
	local prefab=SGK.ResourcesManager.Load("prefabs/DefensiveFortress/BossPrefab.prefab")
	local obj= CS.UnityEngine.GameObject.Instantiate(prefab, self.content.gameObject.transform);
	if obj then
		self.BossObj = CS.SGK.UIReference.Setup(obj);
		obj.name = "Boss_"..id;
		local animation = self.BossObj.Character.Sprite[CS.Spine.Unity.SkeletonAnimation];

		local resource = SGK.ResourcesManager.Load("roles_small/"..mode.."/"..mode.."_SkeletonData.asset")
		animation.skeletonDataAsset = resource or SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData.asset");
		animation:Initialize(true);

		self.BossObj.Character.Label.name[UI.Text].text = string.format("<size=44><color=#68FF00FF>%s</color></size>",name);
		local nowPos = self:GetPos(status)
		self.BossObj.transform.localPosition = nowPos
		self.BossObj.transform.localScale = Vector3.one*bossCfg.scale

		obj:SetActive(true);

		self.BossObj[UnityEngine.AI.NavMeshAgent].stoppingDistance = 0
		if status == 4 then
			local _toPos = self.mapCfg[self.BossData.PosId].pos
			local _s = Vector3.Distance(_toPos, nowPos);
			local _t = defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000
			self.BossObj[UnityEngine.AI.NavMeshAgent].speed = _s/_t

			self.BossObj[SGK.MapPlayer]:MoveTo(_toPos)
		end
	end
end

--1：破坏据点，2：发呆，3：生命回复4.移动
function View:updateBossStatus(data)
	--ERROR_LOG(data[3],"boss 状态变化",sprinttb(data))
	if self.BossData and self.BossData.Status~=data[3] then--当Boss状态变化时	
		self.BossData.ChangeStatusTime=data[4]
		self.BossData.Status=data[3]
		local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)
		local _hp=data[5]<=bossCfg.Monster_hp and data[5] or bossCfg.Monster_hp
		if self.BossData.BossHp and _hp~=self.BossData.BossHp then
			local value =  _hp-self.BossData.BossHp
			self:ShowHartNum(value)
			self.BossData.BossHp=data[5]
		end
		if data[3]~=4 then--移动结束
			if data[3]==1 then
				showDlgError(nil,"魔王发呆中")
			elseif data[3]==2 then
				showDlgError(nil,"魔王懵圈了")
			elseif data[3]==3 then
				showDlgError(nil,"魔王开始疗伤")
			end

			--self:InBossMoveOver()

			self.BossData.PosId=data[2]
			self.BossObj.transform.localPosition=self.mapCfg[self.BossData.PosId].pos

			if self.mapCfg[self.BossData.PosId].Is_Pitfall~=0  then--当boss在非据点不在受伤
				--"播放受伤特效"
				local _nowLevel=self.mapInfo[self.BossData.PosId].Pitfall_level
				local _nowtype=self.mapInfo[self.BossData.PosId].Pitfall_type
				local _PitFallCfg=defensiveModule.GetPitFallLevelCfg(_nowtype,_nowLevel)
	
				local fx_node=CS.SGK.UIReference.Setup(self.MapItemTab["pitFall"]["pitFall"..self.BossData.PosId]).node
				self:playEffect(_PitFallCfg.Effect_id, Vector3(0, 0, 0),fx_node.gameObject)
			end
			
			--刷新宝箱
			for k,v in pairs(data[7]) do
				self:updateMapBox(k,v.Box_Id)
			end
			--刷新路障
			for k,v in pairs(self.mapCfg) do
				if v.Monster_site and next(v.Monster_site)~=nil and #v.Monster_site>1 then
					for i=1,#v.Monster_site do
						local _next_siteId=v.Monster_site[i]
						self:updateObstruct(_next_siteId,self.mapInfo[_next_siteId].Diversion_value,self.BossData.PosId)---该点的诱敌方式
					end
				end
			end

			for k,v in pairs(self.mapCfg) do
				if k==self.BossData.PosId then
					if v.Monster_site and next(v.Monster_site)~=nil and #v.Monster_site>1 then
						for i=1,#v.Monster_site do
							local _next_siteId=v.Monster_site[i]
							self:updateObstruct(_next_siteId,self.mapInfo[_next_siteId].Diversion_value,self.BossData.PosId,true)---该点的诱敌方式
						end
					end
				end
			end
		else
			--隐藏所有路障
			for k,v in pairs(self.mapCfg) do
				if v.Monster_site and next(v.Monster_site)~=nil then
					for i=1,#v.Monster_site do
						local _next_siteId=v.Monster_site[i]
						self:updateObstruct(_next_siteId,self.mapInfo[_next_siteId].Diversion_value,self.BossData.PosId)
					end
				end
			end

			showDlgError(nil,"魔王向据点发起攻击")
			--更新boss起始位置
			self.BossObj.transform.localPosition=self.mapCfg[data[6]].pos

			self.BossData.LastPosId=data[6]
			self.BossData.PosId=data[2]
			self.MapBoxInfo=data[6]
			--boss移动
			local MoveInterval = defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000
			local posStart = self.mapCfg[self.BossData.LastPosId].pos
			local posEnd = self.mapCfg[self.BossData.PosId].pos
			local _s = Vector3.Distance(posEnd,posStart);
			local _t = MoveInterval
			self.BossObj[UnityEngine.AI.NavMeshAgent].speed = _s/_t
			self.BossObj[SGK.MapPlayer]:MoveTo(posEnd)
		end
	end
	--处理被玩家攻击 没引发Boss事件
	-- if self.LastHP~=data[5]then
	-- 	ERROR_LOG("错误事件,玩家攻击Boss",self.LastHP,data[5])
	-- 	-- self.BossData.NowHp=data[5]
	-- 	-- self:InHpChange()
	-- end		
end

--1：破坏据点，2：发呆，3：生命回复4.移动
--10：移动，11.资源减少12：禁锢，13.攻击boss 14：无法行动20秒 15开宝箱 16修复据点 23 搜集资源  30地图资源冷却
local delayTime={
		[10]=defensiveModule.GetActionTimeCfg(2).Move_time/1000,
		[101]=defensiveModule.GetActionTimeCfg(2).Move_cd/1000,
		[12]=defensiveModule.GetActionTimeCfg(2).Imprison_time/1000,--禁锢
		[14]=defensiveModule.GetActionTimeCfg(2).Forbid_time/1000,--昏迷
		[17]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,--搜集时间
		[21]=defensiveModule.GetActionTimeCfg(2).Openbox_time/1000,
		[22]=defensiveModule.GetActionTimeCfg(2).Repair_time/1000,
		[23]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,--采集
		[30]=defensiveModule.GetActionTimeCfg(3).Resoure_produce_time/1000,--10--采集冷却时间
	}

function View:RefPointInfoShow(data)
	--ERROR_LOG("据点信息变化",sprinttb(data),self.mapInfo and sprinttb(self.mapInfo))
	if data.PosId and self.mapInfo and self.mapInfo[data.PosId] then
		if  self.PlayerData[data.Pid] then 	
			if self.mapInfo[data.PosId].Resource_Id~=data.NextResourceId and self.mapInfo[data.PosId].NextResourceId~=data.NextResourceId then
				self:InCollectResources(data.Pid,data.NextResourceId,data.PosId,data.LastActionTime)
				
				local resourceCfg=self.resourcesCfg[self.mapInfo[data.PosId].Resource_Id]
				if self.PlayerCfg[data.Pid] and resourceCfg then
					self.view.transform:DOScale(Vector3.one,delayTime[23]):OnComplete(function()
						local _str=string.format("%s采集获得:%s",self.PlayerCfg[data.Pid].name,resourceCfg.Resource_name)
						utils.SGKTools.showScrollingMarquee(_str)
					end)
				end
			end

			if self.mapInfo[data.PosId].Pitfall_level~=data.Pitfall_level then
				self:InPitFallLevelChange(data.Pid,data.PosId,data.Pitfall_level,data.LastActionTime)

				local pitfall_type=self.mapInfo[data.PosId].Pitfall_type
				local _PitFallCfg=defensiveModule.GetPitFallLevelCfg(pitfall_type,data.Pitfall_level)
				if self.PlayerCfg[data.Pid] and _PitFallCfg then
					local _str=string.format("%s强化 %s 到%s级",self.PlayerCfg[data.Pid].name,_PitFallCfg.Pitfall_name,data.Pitfall_level)
					utils.SGKTools.showScrollingMarquee(_str)
				end
			end

			if self.mapInfo[data.PosId].Diversion_value~=data.Diversion_value then
				self.mapInfo[data.PosId].Diversion_value=data.Diversion_value
				self:updateObstruct(data.PosId,data.Diversion_value,self.BossData.PosId,true)

				if self.PlayerCfg[data.Pid]then
					local _str=string.format("%s设置了路障",self.PlayerCfg[data.Pid].name)
					utils.SGKTools.showScrollingMarquee(_str)
				end	
			end

			if self.mapInfo[data.PosId].Box_Id~=data.Box_Id then--box状态变化 
				self.mapInfo[data.PosId].Box_Id=data.Box_Id
				self:updateMapBox(data.PosId,data.Box_Id)

				if self.PlayerCfg[data.Pid] and data.Box_Id==0 then
					local _str=string.format("%s打开了宝箱",self.PlayerCfg[data.Pid].name)
					utils.SGKTools.showScrollingMarquee(_str)
				end
			end
		else
			print("not self.PlayerData[pid]",data.Pid)
		end
	end
end

function View:InCollectResources(Pid,NextResourceId,PosId,lastCollectTime)
	self.mapInfo[PosId].ResourceCd=true
	self.mapInfo[PosId].LastCollectTime=lastCollectTime
	self.mapInfo[PosId].NextResourceId=NextResourceId

	if Pid == self.Pid then
		utils.SGKTools.EffectGather(nil,79013,nil,delayTime[23])
	end
	self.view.transform:DOScale(Vector3.one,delayTime[23]):OnComplete(function()
  		self:updateMapResource(PosId,false)
    end)
	self.PlayerData[Pid].StartActionTime=Time.now()
	self.PlayerData[Pid].Action=23
end

function View:InResourcesChange(data)
	--data[3]   1:收集资源2:加强陷阱3:兑换资源4:诱敌消耗资源5:与boss相遇掉资源6:战斗结束之后获得资源
	self.OwnResource=data[1]
end

function View:InPitFallLevelChange(pid,siteId,Pitfall_level,LastActionTime)
	self.PlayerData[pid].LastAddTime=LastActionTime
	self.PlayerData[pid].Action=24
	self.mapInfo[siteId].NextPitfall_level=Pitfall_level

	--播放强化动画-- 强化后
	local fx_node = CS.SGK.UIReference.Setup(self.MapItemTab["pitFall"]["pitFall"..siteId]).node
	local playTime = self:playEffect("fx_trap_shengji", Vector3(0, 0, 0),fx_node.gameObject)

	local pitfall_type=self.mapInfo[siteId].Pitfall_type
	local _PitFallCfg=defensiveModule.GetPitFallLevelCfg(pitfall_type,Pitfall_level)
	local delay=_PitFallCfg.Time_cd/1000 +playTime

	self.view.transform:DOScale(Vector3.one,delay):OnComplete(function()
		self:upDateMapPitFallShow(siteId,pitfall_type,self.mapInfo[siteId].NextPitfall_level)
	end)
end

function View:InClickOpenBox(pid,siteId)
	if self.PlayerData[pid].OpenTimes <10 then
		utils.SGKTools.EffectGather(nil,"79019","开启中...",delayTime[21])
		self.view.transform:DOScale(Vector3.one,delayTime[21]):OnComplete(function()
			defensiveModule.QueryOpenBox(pid,siteId)
		end)
	else
		print(pid,self.PlayerData[pid].OpenTimes)
		showDlgError(nil,"今日已达到开启上限")
	end
end

function View:ShowHartNum(value)
	if self.BossObj then
		local _effect = SGK.ResourcesManager.Load("prefabs/effect/boss_word.prefab")
		local _effectObj = UnityEngine.GameObject.Instantiate(_effect.gameObject, self.BossObj.gameObject.transform)
		_effectObj.transform.localScale = Vector3.one*2
		_effectObj.transform.localPosition = Vector3(0, 6.5, -0.1)
		local _view = CS.SGK.UIReference.Setup(_effectObj.gameObject)
		_view.word_ani["New Text"][UnityEngine.TextMesh].text = string.format("%s%d%s",value>=0 and "<color=#3BFFBCFF>" or "<color=#FF1A1AFF>",value,"</color>");
		UnityEngine.GameObject.Destroy(_effectObj, 1)
	end
end

function View:GetPos(status)
	if status ==4 then
		local MoveInterval=defensiveModule.GetActionTimeCfg(self.BossData.Id).Move_time/1000
		self.BossData.ChangeStatusTime=type(self.BossData.ChangeStatusTime)=="string" and Time.now() or self.BossData.ChangeStatusTime
		local detal=(MoveInterval+self.BossData.ChangeStatusTime-Time.now())

		local posStart=self.mapCfg[self.BossData.LastPosId].pos
		local posEnd=self.mapCfg[self.BossData.PosId].pos

		return Vector3.Lerp(posStart,posEnd,(MoveInterval-detal)/MoveInterval)
	else
		return self.mapCfg[self.BossData.PosId].pos
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
		 		self:updateMapResource(k,true)
		 	end
		end
	end
end

function View:playEffect(effectName, position, node, sortOrder)
	local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
	local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
	local playTime = 0
	if o then
		local transform = o.transform;
		transform.localPosition = position or Vector3.zero;
		transform.localRotation = Quaternion.identity;
		if sortOrder then
			SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
		end
		local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
		UnityEngine.Object.Destroy(o, _obj.main.duration)
		playTime = _obj.main.duration
	else
		ERROR_LOG(effectName.."is nil")
	end 
	return playTime
end

function View:OnDestroy()	

end

function View:Update()
	self:UpdateTimeText()

	if self.data and not self.FortressFrame then
		local UIRoot = UnityEngine.GameObject.FindWithTag("MapSceneUIRootMid")	
		if UIRoot and not utils.SGKTools.GameObject_null(UIRoot.gameObject) then
			self.FortressFrame = true
			DialogStack.PushPref("DefensiveFortress/DefensiveFortressFrame",self.data,UIRoot.gameObject)
		end
	end
end

function View:onEvent(event, data)
	if event =="MAP_INFO_CHANGE" then
		self:InItData(data)
	elseif event =="ROlE_DATA_CHANGE" then
		-- ERROR_LOG("ROlE_DATA_CHANGE",sprinttb(data))
		-- self:updatePlayerStatus(data)
	elseif event=="BOSS_DATA_CHANGE" then
		self:updateBossStatus(data)
	elseif event =="RESOURCES_NUM_CHANGE" then
		self:InResourcesChange(data)

	elseif event =="POINT_INFO_CHANGE" then
		self:RefPointInfoShow(data)
	elseif event =="OPEN_BOX_INFO_CHANGE" then--开宝箱次数变化
		self.PlayerData[data[1]].OpenTimes=data[2]
	elseif event =="CLICK_OPEN_ADDPANEL" then
		if data.siteId ~= self.BossData.PosId then
			DialogStack.Push("DefensiveFortress/AddPitFallFrame",{siteId=data.siteId,mapInfo=self.mapInfo,PlayerData=self.PlayerData,BossId=self.BossData.Id,OwnResource=self.OwnResource})
		else
			showDlgError(nil,"不能强化该陷阱!")
		end
	elseif event =="CLICK_OPEN_EXCHANGEPANEL" then
		DialogStack.Push("DefensiveFortress/ExchangeFrame",{PlayerData=self.PlayerData,OwnResource=self.OwnResource})
	elseif event=="CLICK_ADD_OBSTRUCT" then
		if self.mapCfg[self.BossData.PosId].Monster_site and next(self.mapCfg[self.BossData.PosId].Monster_site)~=nil and #self.mapCfg[self.BossData.PosId].Monster_site>1 then
			local addedSites=0
			for i=1,#self.mapCfg[self.BossData.PosId].Monster_site do
				local _siteId=self.mapCfg[self.BossData.PosId].Monster_site[i]
				if self.mapInfo[_siteId].Diversion_value>0 then
					addedSites=addedSites+1
				end
			end
			
			if addedSites<#self.mapCfg[self.BossData.PosId].Monster_site-1 then
				if self.mapInfo[data.siteId].Diversion_value==0 then
					DialogStack.Push("DefensiveFortress/AddObstructFrame",{siteId=data.siteId,mapInfo=self.mapInfo,PlayerData=self.PlayerData,posId=self.BossData.PosId,id=self.BossData.Id,OwnResource=self.OwnResource})
				else
					showDlgError(nil,"不能再次设置路障了!")
				end
			else
				showDlgError(nil,"不能激活更多的路障了!")
			end	
		end	
	elseif event=="CLICK_OPEN_BOX" then
		local _pid = module.playerModule.GetSelfID()
		self:InClickOpenBox(_pid,data.siteId)
	elseif event =="FORTRESS_GAME_OVER" then
		for k,v in pairs(self.mapInfo) do
			--if self.mapCfg[k].Is_Pitfall ~= 0 then--该据点是否有陷阱 能否产生资源
				--刷新陷阱 
				if self.MapItemTab["pitFall"]["pitFall"..k] then
					self.MapItemTab["pitFall"]["pitFall"..k].gameObject:SetActive(false)
				end  
				if self.MapItemTab["resource"]["resource"..k] then
					self.MapItemTab["resource"]["resource"..k].gameObject:SetActive(false)
				end
				if self.MapItemTab["box"]["box"..k] then
					self.MapItemTab["box"]["box"..k].gameObject:SetActive(false)
				end
				if self.MapItemTab["obstruct"]["obstruct"..k] then
					self.MapItemTab["obstruct"]["obstruct"..k].gameObject:SetActive(false)
				end
			--end
		end
	end
end

function View:listEvent()
	return{
	    "MAP_INFO_CHANGE",
	    "ROlE_DATA_CHANGE",
	    "PLAYER_ACTION_CHANGE",

	    "POINT_INFO_CHANGE",
	    "OPEN_BOX_INFO_CHANGE",

	    "RESOURCES_NUM_CHANGE",

	    "BOSS_DATA_CHANGE",
	    "ROlE_DATA_CHANGE",

	    "CLICK_OPEN_ADDPANEL",
	    "CLICK_OPEN_EXCHANGEPANEL",
	    "CLICK_ADD_OBSTRUCT",
	    "CLICK_OPEN_BOX",

	    "FORTRESS_GAME_OVER",
	}
end
return View