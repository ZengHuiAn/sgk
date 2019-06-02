local View = {}
local trialModule = require "module.trialModule"
local battleCfg = require "config.battle"
local trialTowerConfig = require "config.trialTowerConfig"
local playerModule = require "module.playerModule"

local MapConfig = require "config.MapConfig"

local ItemModule = require "module.ItemModule"

local Vector3 = UnityEngine.Vector3;

local Vector2 = UnityEngine.Vector2;



local mt = {
	__index = function(t, k)
		local v = rawget(t, k)
		if v ~= nil then return v; end
		v = rawget(t, '_v3_' .. k);
		if v ~= nil then return Vector3(v[1], v[2], v[3]) end

		v = rawget(t, '_v2_' .. k);
		if v ~= nil then return Vector2(v[1], v[2]) end

	end
}


--buff NPC参数
local BuffData = setmetatable({
	--动画播放时间
	["dur"] = 0.5,
	["_v2_StartPoint"] = {-300,0},
},mt);

--三个怪物的参数
local BossData = {
	["Boss1"] = setmetatable({ _v2_StartPoint = {0,-300}, dur = 1 ,_v3_targetPoint = {0,100,0}}, mt),
	["Boss2"] = setmetatable({ _v2_StartPoint = {0,-300}, dur = 0.5 ,_v3_targetPoint = {-177,-50,0}}, mt),
	["Boss3"] = setmetatable({ _v2_StartPoint = {0,-300}, dur = 0.5 ,_v3_targetPoint = {161,-70,0}}, mt),
}

--玩家的数据
local PlayerData =setmetatable ({
	["_v2_StartPoint"] = {0,466},
	["dur"] = 1.5,
	["_v3_EndPoint"]  = {0,-50,0},
	--玩家走到Boss的点
	["_v3_BOSSPoint"] = {0,-367,0},
	--玩家走向怪物的速度
	["MoveSpeed"] = 0.5,
},mt)

local BattleData = setmetatable({
	["_v2_StartPoint"] = {0,-562},
	["dur"] = 1.5,
	["_v3_EndPoint"] = {0,-176,0};
},mt)
--左边图标数据
local BattleStartData = setmetatable({
	--每个icon的偏移
	offest = -100;
	--开始点
	_v2_startPoint = {0,-45};
	--标志的位置
	_v2_flagPos	   = {0,-120};
},mt)



local MoveToData = {
	["Boss2"] = setmetatable ({  dur = 0.5 ,_v3_targetPoint = {0,100,0},},mt),
	["Boss3"] = setmetatable ({  dur = 0.5 ,_v3_targetPoint = {-177,-50,0},},mt),
	["Boss1"] = setmetatable ({  dur = 1 ,_v3_targetPoint = {161,-70,0},},mt),
}

-- local MoveToData = {
-- 	["Boss2"] = {  dur = 0.5 ,targetPoint = Vector3(0,100,0),scale = 1},
-- 	["Boss3"] = {  dur = 0.5 ,targetPoint = Vector3(-177,-50,0)},
-- 	["Boss1"] = {  dur = 1 ,targetPoint = Vector3(161,-70,0)},
-- }


function View:CloseTips()
	self.view.bg[CS.UGUIClickEventListener].onClick = function ()
		self.view.bg.battle.list[UI.ToggleGroup]:SetAllTogglesOff();
	end
end

function View:OpenPenguin()
	print("企鹅提示")
	local onClick = self.view.bg.NpcNode.boss[CS.UGUIClickEventListener].onClick;
	print("====================>>>>>>>>>>>>>>>>>>>>>>>>")
	if onClick then

		
		onClick();
	end
end

function View:OpenBuffTips()
	local onClick = self.view.bg.buffNpcNode.boss[CS.UGUIClickEventListener].onClick;

	if onClick then
		onClick();
	end
	self.buff_npc_Time = nil;
end

function View:Init(current)
	self:Fresh();

	self.view.bg.helpBtn[CS.UGUIClickEventListener].onClick = function ()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shilianta_shuoming_01"))
		self.view.bg[CS.UGUIClickEventListener].onClick();
	end

	
	self.view.bg.rank[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("rankList/rankListFrame", 4)
		self.view.bg[CS.UGUIClickEventListener].onClick();
	end
	local tips = self.view.bg.NpcNode.boss.bossModeRoot.tips;

	

	self.view.bg.reward[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("trial/trialReward",current);
		self.view.bg[CS.UGUIClickEventListener].onClick();
	end
	if current.gid  == 101 then
		return;
	end
	local cfg = trialTowerConfig.GetConfig(current.gid);
	tips.Text[UI.Text].text = cfg and cfg.buff_des or "你已通关!";
	self.view.bg.NpcNode.boss[CS.UGUIClickEventListener].onClick = function ()
		--企鹅气泡

		ERROR_LOG("=====企鹅气泡=======");
		
		self.view.bg[CS.UGUIClickEventListener].onClick();
		if tips.gameObject.activeInHierarchy == true then
			tips.gameObject:SetActive(false);
		else

			tips.gameObject:SetActive(true);
			self.npcTime = 0;
		end
	end

	
	
end

function View:Fresh()
	local num = module.ItemModule.GetItemCount(90168);
	-- print("扫荡数量",num);
	print("==============",self.current);
	if self.current ~= 60000001 then
		self.view.bg.reward.gameObject:SetActive(true);
		if num >0  then
			local ret = trialModule.GetIsSweeping();
			if ret then
				self.view.bg.reward.tips.gameObject:SetActive(true);
			end
		else
			self.view.bg.reward.tips.gameObject:SetActive(false);
		end
	else
		self.view.bg.reward.gameObject:SetActive(false);
	end
end

--检测当前层是否是新的一层
function View:CheckCurrent(gid,func)
	local ret = trialModule.GetCurrent();
	if not ret or gid ~= ret then
		--进入到新的一层
		if func then
			func(ret,gid);
		end
	else
		self.view.bg.title.bg.Text[UI.Text].text = tonumber(gid)- 60000000;
		-- print("不是新的一层");
	end

	trialModule.SetCurrent(gid);
end

function View:Update()

	if self.npcTime then
		self.npcTime = self.npcTime + UnityEngine.Time.deltaTime;

		if self.npcTime >=3 then
			self.view.bg.NpcNode.boss.bossModeRoot.tips.gameObject:SetActive(false);
			self.npcTime = nil;
			print("关闭企鹅");
		end
	end

	if self.buff_npc_Time then
		self.buff_npc_Time = self.buff_npc_Time + UnityEngine.Time.deltaTime;

		if self.buff_npc_Time >=3 then
			self.view.bg.buffNpcNode.boss.bossModeRoot.bossMode.tips.gameObject:SetActive(false);
			self.buff_npc_Time = nil;
			print("关闭助阵");
		end
	end
end


function View:CloseMode( )
	
end

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	local init_obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
	
	local bossNode = self.view.bg.bossNode;
	local current,cfg = trialModule.GetBattleConfig();

	if not current then
		showDlgError(nil,"已通关!");
		-- self.view.bg.playerNode.gameObject:SetActive(false);
		self.view.bg.bossNode.gameObject:SetActive(false);
		self.view.bg.NpcNode.gameObject:SetActive(false);
		self.view.bg.buffNpcNode.gameObject:SetActive(false);
		self.view.bg.battle.gameObject:SetActive(false);
		self.view.bg.title.gameObject:SetActive(false);
		
		self:Init({gid = 101});

		self.view.bg.helpBtn[CS.UGUIClickEventListener].onClick = function ()
			utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shilianta_shuoming_01"))
			if self.view.bg[CS.UGUIClickEventListener].onClick then
				self.view.bg[CS.UGUIClickEventListener].onClick();
			end
		end

		
		self.view.bg.rank[CS.UGUIClickEventListener].onClick = function ()
			DialogStack.PushPrefStact("rankList/rankListFrame", 4)
			if self.view.bg[CS.UGUIClickEventListener].onClick then
				self.view.bg[CS.UGUIClickEventListener].onClick();
			end
		end
		local tips = self.view.bg.NpcNode.boss.bossModeRoot.tips;

		self.view.clickMask[UI.Image].enabled= false;

		self.view.bg.reward[CS.UGUIClickEventListener].onClick = function ()
			DialogStack.PushPrefStact("trial/trialReward");
			if self.view.bg[CS.UGUIClickEventListener].onClick then
				self.view.bg[CS.UGUIClickEventListener].onClick();
			end
		end
		self:FreshPlayerInfo(nil,function ( ... )
			-- print(self.buff_npc);
			
		end);


		return;
	end
	print("当前层数:",sprinttb(current),sprinttb(cfg));
	self:CloseTips();

	self.current = current.gid;
	self:Init(current);
	self.cfg = cfg;
	self.Win = nil;
	self:CheckCurrent(current.gid,function (up,cur)
		-- print("上一层"..(up or 0),"新的一层"..cur);

		if up and up ~=cur then
			self.Win = true;
		end
		-- self.Win = true;
		self.view.bg.title.bg.Text[UI.Text].text = tonumber(cur)- 60000000;
		-- self.view.bg.title.bg.Text.gameObject.transform:DO

	end);
	



	if not self.Win then
		--刷新三波怪
		self:FreshBossNode(bossNode.boss,cfg._data.gid,true,BossData["Boss1"].StartPoint);
		self:FreshBossNode(bossNode.boss1,cfg._data.gid+1,nil,BossData["Boss2"].StartPoint);
		self:FreshBossNode(bossNode.boss2,cfg._data.gid+2,nil,BossData["Boss2"].StartPoint);	

		bossNode.boss[CS.UGUIClickEventListener].onClick = function ()
			-- print("点击");
			self.view.bg[CS.UGUIClickEventListener].onClick();
			self:MoveToNpc(function ( ... )
				DialogStack.PushPrefStact("trial/trialMonster",{["cfg"] = cfg,callback = function ( ... )
					self:BackToBorn(function ( ... )
						--播放待机动作
						self:FreshPlayerDir(0);
						self:FreshPlayerSprite(true);
					end);
				end});
			end);
		end
		
		
		
		--刷新怪物UI
		self:FreshMonster(cfg._data.gid,function ()
			ERROR_LOG("===============>>>>",sprinttb(cfg));
			if cfg and trialTowerConfig.GetConfig(cfg._data.gid) then
				self.view.bg.battle.list.flag.gameObject:SetActive(true);
			end
		end);
		
		local cfg = trialTowerConfig.GetConfig(current.gid);
		local buffConfig = trialTowerConfig.GetBuffConfig(current.gid);

		ERROR_LOG("不是新的一层",buffConfig == nil);
		local buff_flag = 0;
		if not buffConfig then
			self:FreshBuffNpc(0);
		else
			local num = ItemModule.GetItemCount(buffConfig.item_id);
			if num and num >=buffConfig.item_value then
				self:FreshBuffNpc(cfg.buff_role_mode,cfg.buff_role_talking);
				
				buff_flag = 1;
			else
				buff_flag = 2;
				self:FreshBuffNpc(0);
			end
		end
		--如果buffnpc不存在
		-- if not self.buff_npc then
		-- 	if self.view.bg.NpcNode.boss[CS.UGUIClickEventListener].onClick then
		-- 		self.view.bg.NpcNode.boss[CS.UGUIClickEventListener].onClick();
		-- 	end
		-- end
		self.view.clickMask[UI.Image].enabled= true;
		self:PlayBossAnimation(bossNode.boss,BossData["Boss1"].targetPoint,BossData["Boss1"].dur,  function ( ... )
			self:PlayBossAnimation(bossNode.boss1,BossData["Boss2"].targetPoint,BossData["Boss2"].dur,function ( ... )
				self:PlayBossAnimation(bossNode.boss2,BossData["Boss3"].targetPoint,BossData["Boss3"].dur,function ( ... )
					--如果buffNpc满足
					bossNode.boss[CS.UGUIClickEventListener].interactable = true;
					bossNode.boss.bossModeRoot.bossMode[Spine.Unity.SkeletonGraphic].raycastTarget = true;

					self.view.clickMask[UI.Image].enabled= false;
					self.view.bg.battle.list[UI.Mask].enabled = false;
				end);
			end);
		end);

		self:FreshPlayerInfo(nil,function ( ... )
			-- print(self.buff_npc);
			if self.buff_npc then
				self:PlayBuffNpcAnimation(function ( ... )
					self:OpenBuffTips();
				end);
			else
				--不满足buffNpc
				
				
				print(buff_flag);
				if buff_flag == 1 then
					--满足条件
					self:OpenPenguin();
					self.view.bg.buffNpcNode.boss.bossModeRoot.bossMode.tips.gameObject:SetActive(true);
				elseif buff_flag == 2 then
					self.view.bg.NpcNode.boss.bossModeRoot.tips.gameObject:SetActive(true);
					self.npcTime = nil;
					--不满足条件
				end
			end
		end);
		self:FreshNpcNode();
	else
		self.view.clickMask[UI.Image].enabled= true;
		-- ERROR_LOG("新的一层");
		self:FreshBossNode(bossNode.boss,cfg._data.gid-1,true,Vector2(BossData["Boss1"].targetPoint.x,BossData["Boss1"].targetPoint.y),true);
		self:FreshBossNode(bossNode.boss1,cfg._data.gid,nil,Vector2(BossData["Boss2"].targetPoint.x,BossData["Boss2"].targetPoint.y),true);
		self:FreshBossNode(bossNode.boss2,cfg._data.gid+1,nil,Vector2(BossData["Boss3"].targetPoint.x,BossData["Boss3"].targetPoint.y),true);
		self:FreshPlayerInfo(nil,nil,Vector2(PlayerData["BOSSPoint"].x,PlayerData["BOSSPoint"].y),PlayerData["EndPoint"],UnityEngine.Vector3(1,1,1))
		self:FreshPlayerDir(0);
		self:FreshPlayerSprite(true);
		local pos = Vector2(BattleData["EndPoint"].x,BattleData["EndPoint"].y);

		-- ERROR_LOG(pos);
		
		self:FreshMonster(cfg._data.gid-1,nil,true);
		self.view.bg.battle.list.points[UnityEngine.RectTransform].anchoredPosition = pos;
		self:PlayLayer(function ( ... )
			self.view.clickMask[UI.Image].enabled= false;
			self.view.bg.battle.list[UI.Mask].enabled = false;
			local cfg = trialTowerConfig.GetConfig(current.gid);
			local buffConfig = trialTowerConfig.GetBuffConfig(current.gid);
			local buff_flag = 0;
			ERROR_LOG("新的一层",buffConfig == nil);
			if not buffConfig then
				self:FreshBuffNpc(0);
			else
				local num = ItemModule.GetItemCount(buffConfig.item_id);
				if num and num >=buffConfig.item_value then
					--助阵npc条件满足
					self:FreshBuffNpc(cfg.buff_role_mode,cfg.buff_role_talking);
					-- self.view.bg.buffNpcNode.boss[CS.UGUIClickEventListener].onClick();
					buff_flag = 1;
				else
					--助阵npc条件不满足
					self:FreshBuffNpc(0);
					buff_flag = 2;
				end
			end


			
			if self.buff_npc then
				self:PlayBuffNpcAnimation(function ( ... )
					self:OpenBuffTips();
				end);
			else
				--不满足buffNpc
				self:OpenPenguin();
				

				print(buff_flag);
				if buff_flag == 1 then
					--满足条件
					self.view.bg.buffNpcNode.boss.bossModeRoot.bossMode.tips.gameObject:SetActive(true);
				elseif buff_flag == 2 then
					self.view.bg.NpcNode.boss.bossModeRoot.tips.gameObject:SetActive(true);
					self.npcTime = nil;
					--不满足条件
				end
			end
		end);
		self:FreshNpcNode();
		-- self:BackToBorn(function ( ... )
		-- 			--播放待机动作
		-- 			self:FreshPlayerDir(0);
		-- 			self:FreshPlayerSprite(true);
		-- 		end);
	end
	self:initGuide()
end

function View:initGuide()
    module.guideModule.PlayByType(128,0.1)
end

local alpha = 1

--播放胜利动画
function View:PlayLayer(func)
	local bossNode = self.view.bg.bossNode;
	bossNode.boss.flag.gameObject:SetActive(false);
	self:PlayUpBossAnimat(bossNode,nil,nil,function ( ... )
		self:AnimationSucc(func);
		self:Back();
	end);
end

function View:Back( ... )
	self:BackToBorn(function ( ... )
		--播放待机动作
		self:FreshPlayerDir(0);
		self:FreshPlayerSprite(true);
	end);
end





-- (node,targetPoint,dur,func,onstart,dir)
--胜利动画播放完成 func怪物播放完动画回调
function View:AnimationSucc(func)

	local bossNode = self.view.bg.bossNode;
	self.view.bg.battle.list.points["point1"]:SetActive(false);
	self:FreshDownBattle();
	self.view.bg.battle.list.points["point1"][UnityEngine.RectTransform].anchoredPosition = BattleStartData.startPoint + Vector2(0,BattleStartData.offest*5 or 0);
	self:PlayBattleFirst(1,0.1,function ( ... )
		self:FreshDownBattle();
		self:FreshModeColor();

		self:MoveToUp(self.view.bg.battle.list,function ( ... )
			-- if cfg and trialTowerConfig.GetConfig(cfg._data.gid) then
			-- 	self.view.bg.battle.list.flag.gameObject:SetActive(true);
			-- end
			self.view.bg.battle.list[UI.Image].enabled = false;
			self.view.bg.battle.list[UI.Mask].enabled = false;

			bossNode.boss1.flag.gameObject:SetActive(true);
			
			--将第一波怪刷回去
			self:FreshBossNode(bossNode.boss,self.cfg._data.gid+2,nil,Vector2(BossData["Boss1"].StartPoint.x,BossData["Boss1"].StartPoint.y));
			--播放动画
			self:PlayBossAnimation(bossNode.boss1, MoveToData["Boss2"].targetPoint, MoveToData["Boss2"].dur, function ( ... )
				self:PlayBossAnimation(bossNode.boss2, MoveToData["Boss3"].targetPoint, MoveToData["Boss3"].dur, function ( ... )

					local local_cfg = trialTowerConfig.GetConfig(self.cfg._data.gid+2);
					if local_cfg and next(local_cfg) then
						bossNode.boss.gameObject:SetActive(true);
					end

					
					self:PlayBossAnimation(bossNode.boss, MoveToData["Boss1"].targetPoint, MoveToData["Boss1"].dur,function ( ... )
						bossNode.boss1[CS.UGUIClickEventListener].interactable = true;
						bossNode.boss1.bossModeRoot.bossMode[Spine.Unity.SkeletonGraphic].raycastTarget = true;
						if func then
							func();
						end
						bossNode.boss1[CS.UGUIClickEventListener].onClick = function ()
							-- print("点击");
							self.view.bg[CS.UGUIClickEventListener].onClick();
							self:MoveToNpc(function ( ... )
								DialogStack.PushPrefStact("trial/trialMonster",{["cfg"] = self.cfg,callback = function ( ... )
									self:BackToBorn(function ( ... )
										--播放待机动作
										self:FreshPlayerDir(0);
										self:FreshPlayerSprite(true);
									end);
								end});
							end);
						end
					end);
				end,nil,3);
			end, function ( ... )
				-- 开始
				self:FreshDir(bossNode.boss1,2);

				if MoveToData["Boss2"].scale then
					bossNode.boss1.bossModeRoot.bossMode.transform:DOScale(MoveToData["Boss2"].scale,MoveToData["Boss2"].dur)
				end
			end,5);



		end);
	end,function ( ... )
		-- 将数据恢复


	end);
end

function View:FreshModeColor(alpha)
	self.view.bg.bossNode.boss.bossModeRoot.bossMode[CS.Spine.Unity.SkeletonGraphic]:DOFade(1,1);
	self.view.bg.bossNode.boss.gameObject:SetActive(false);
	-- ERROR_LOG("刷新颜色");
	self.view.bg.bossNode.boss[UnityEngine.RectTransform].anchoredPosition = BossData["Boss1"].StartPoint;
end

local MoveUp = 0.5
--battle移动
function View:MoveToUp(list,func)
	 list.points.transform:DOLocalMove(BattleData["EndPoint"] + Vector3(0,-BattleStartData.offest,0),MoveUp):OnComplete(function ( ... )
	 		if func then
	 			func();
	 		end
	 end);
end



--刷新最后一个怪物UI数据
function View:FreshDownBattle()
	
	-- self.view.bg.battle.list.points["point1"]
	local cfg = trialTowerConfig.GetConfig(self.current + 4);

	if cfg then
		self:FreshItemMonster(self.view.bg.battle.list.points["point1"],cfg,cfg.difficulty and (cfg.difficulty == 2) or nil);
		self:PlayUpBossAnimat(self.view.bg.bossNode,0.1,nil,function ( ... )
			self:FreshBattleAlpha();
		end);
	end

	
end

function View:FreshBattleAlpha()
	self.view.bg.battle.list.points["point1"].root.IconFrame[UI.Image]:DOFade(1,0.1);
	self.view.bg.battle.list.points["point1"].root[UI.Image]:DOFade(1,0.1):OnComplete(function ( ... )
		self.view.bg.battle.list.points["point1"]:SetActive(true);
	end)
end

function View:PlayBattleFirst(value,dur,func,start)
	dur = dur or alpha;
	-- self.view.bg.battle.list.points["point1"].root.IconFrame[UI.Image]:DOKill();
	local tweer = self.view.bg.battle.list.points["point1"].root.IconFrame[UI.Image]:DOFade(value,dur):OnComplete(function ( ... )
		if func then
			func();
		end
	end)
	tweer:OnStart(function ( ... )
		if start then
			start();
		end
	end);

	self.view.bg.battle.list.points["point1"].root[UI.Image]:DOFade(value,dur);
end

function View:PlayUpBossAnimat(node,dur,start1,end1)
	dur = dur or alpha;
	local tweer = node.boss.bossModeRoot.bossMode[CS.Spine.Unity.SkeletonGraphic]:DOFade(0,dur);
	tweer:SetEase(CS.DG.Tweening.Ease.Linear);
	tweer:OnStart(function ()
		if start1 then
			start1();
		end

		self:PlayBattleFirst(0,dur);
	end)
	tweer:OnComplete(function ( ... )
		self:PlayBattleFirst(1,dur);
		local tweer1 = node.boss.bossModeRoot.bossMode[CS.Spine.Unity.SkeletonGraphic]:DOFade(1,dur);
		tweer1:OnComplete(function ()
			self:PlayBattleFirst(0,dur);
			node.boss.bossModeRoot.bossMode[CS.Spine.Unity.SkeletonGraphic]:DOFade(0,dur):OnComplete(function ( ... )
				if end1 then
					end1();
					-- ERROR_LOG("结束");
				end
			end);
		end);
	end)
end

--
function View:MoveToNpc(callback)
	self.view.bg.playerNode.player[UnityEngine.RectTransform]:DOKill();
	local currentdis = self.view.bg.playerNode.player[UnityEngine.RectTransform].anchoredPosition.y - PlayerData["BOSSPoint"].y
	local dis = PlayerData["EndPoint"].y - PlayerData["BOSSPoint"].y

	local dur = currentdis/dis;
	-- print(dur);
	self:FreshPlayerDir(0);
	self:FreshPlayerSprite(false);
	-- print(BossData["Boss1"].targetPoint.y);
	self.tweer = self.view.bg.playerNode.player[UnityEngine.RectTransform]:DOLocalMove(PlayerData["BOSSPoint"],dur* PlayerData["MoveSpeed"]);

	self.tweer:OnComplete(function ( ... )
		self:FreshPlayerSprite(true);
		if callback then
			callback();
		end
	end);
end


function View:PlayBuffNpcAnimation(func)
	local tweer = self.view.bg.buffNpcNode.boss.transform:DOLocalMoveX(0,BuffData.dur);
    self:FreshBuffNpcSprite(nil,6);
    tweer:SetEase(CS.DG.Tweening.Ease.Linear);
    tweer:OnComplete(function ()
    	self:FreshBuffNpcSprite(true,0);
    	-- _sprite.direction = 0;

    	if func then
    		func();
    	end
    end);
end


--关闭页面回去
function View:BackToBorn(callback,_dur)
	self.view.bg.playerNode.player[UnityEngine.RectTransform]:DOKill();
	local currentdis = self.view.bg.playerNode.player[UnityEngine.RectTransform].anchoredPosition.y - PlayerData["BOSSPoint"].y
	local dis = PlayerData["EndPoint"].y - PlayerData["BOSSPoint"].y
	local dur = currentdis/dis;

	local tweer = self.view.bg.playerNode.player[UnityEngine.RectTransform]:DOLocalMove(PlayerData["EndPoint"], (1 - dur) * PlayerData["MoveSpeed"]);
	self:FreshPlayerSprite(false);
	self:FreshPlayerDir(4);

	tweer:OnComplete(function ()
		if callback then
			callback();
		end
	end);
	-- tweer
end


function View:PlayBossAnimation(node,targetPoint,dur,func,onstart,dir)
	local bossNode = node.bossModeRoot.bossMode
	local _obj = bossNode.gameObject;
    
    local _boss = bossNode[CS.Spine.Unity.SkeletonGraphic];

    if _boss then
	local _sprite = _obj:GetComponent(typeof(SGK.DialogSprite))
		local tweer = node[UnityEngine.RectTransform]:DOLocalMove(targetPoint,dur);
		tweer:SetEase(CS.DG.Tweening.Ease.Linear);
		tweer:OnStart(function ()
			if dir then
				self:FreshDir(bossNode,dir)
			end
			self:FreshSprite(bossNode,false);
			if onstart then
				onstart();
			end
		end)
	    tweer:OnComplete(function ( ... )
	    	_sprite.idle = true;
	    	self:FreshDir(bossNode,4)
	    	if func then
	    		func();
	    	end
	    end)
	end
end
function View:FreshBuffNpc(mode,desc)
	if mode == 0 then self.view.bg.buffNpcNode.gameObject:SetActive(false); return end;
	-- print(mode);

	self.buff_npc = true;
	-- self.view.bg.buffNpcNode.gameObject:SetActive(true);
	local buffNpcNode = self.view.bg.buffNpcNode.boss.bossModeRoot.bossMode;

	local _obj = buffNpcNode.gameObject;
    _obj.transform.localScale = Vector3(0.8,0.8,0.8);
    local _boss = buffNpcNode[CS.Spine.Unity.SkeletonGraphic];

    local path = "roles_small/";
    -- print(path..cfg.mode.."/"..cfg.mode.."_SkeletonData");
    local _dataAsset = SGK.ResourcesManager.Load(path..mode.."/"..mode.."_SkeletonData.asset")

    if _dataAsset then
    	local _sprite = _obj:GetComponent(typeof(SGK.DialogSprite))
    	_boss.skeletonDataAsset = _dataAsset
        _boss:Initialize(true)
        _boss.startingLoop = true
        _boss.AnimationState:SetAnimation(0, "idle1", true)
        self.view.bg.buffNpcNode.boss[UnityEngine.RectTransform].anchoredPosition = BuffData["StartPoint"];

        
	else
		_boss.skeletonDataAsset = nil;
		-- ERROR_LOG("该动画不存在");
	end

	local tips = self.view.bg.buffNpcNode.boss.bossModeRoot.bossMode.tips;
	tips.gameObject:SetActive(false);

	self.view.bg.buffNpcNode.boss[CS.UGUIClickEventListener].onClick = function ()
		print("-----");
		self.view.bg[CS.UGUIClickEventListener].onClick();
		if tips.gameObject.activeInHierarchy then
			tips.gameObject:SetActive(false);
		else
			tips.Text[UI.Text].text = desc;
			tips.gameObject:SetActive(true);
			self.buff_npc_Time = 0;
		end
	end



end

function View:FreshNpcNode()
	local NpcNode = self.view.bg.NpcNode.boss.bossModeRoot.bossMode;

	local _boss = NpcNode[CS.Spine.Unity.SkeletonGraphic];
	local _obj = NpcNode.gameObject;
	local path = "roles/";

	 local _dataAsset = SGK.ResourcesManager.Load(path..tostring(19920).."/"..tostring(19920).."_SkeletonData.asset")

	if _dataAsset then
    	local _sprite = _obj:GetComponent(typeof(SGK.DialogSprite))
    	_sprite.enabled = false
    	-- _obj.transform.localScale = UnityEngine.Vector3(0.2, 0.2, 0.2)
    	_boss.skeletonDataAsset = _dataAsset
    	 _boss:Initialize(true)
    	_boss.AnimationState:SetAnimation(0, "idle", true)
        -- _boss.AnimationState:SetAnimation(0, "idle1", true)
	else
		_boss.skeletonDataAsset = nil;
		-- ERROR_LOG("该动画不存在");
	end
end

--刷新BOSS动画
function View:FreshBossNode(node,current,center,pos,status)

	-- bossNode.boss.bossModeRoot.bossMode
	local cfg = trialTowerConfig.GetConfig(current);
	local bossNode = node.bossModeRoot.bossMode
	-- ERROR_LOG("============>>>>>",sprinttb(cfg));
	if not cfg  or not cfg.mode_type or not next(cfg) then 
		node.gameObject:SetActive(false);

		ERROR_LOG("隐藏物体========>>>>",sprinttb(cfg));
		return;
	end
	if pos then
		node[UnityEngine.RectTransform].anchoredPosition = pos;
	end
	node.flag.gameObject:SetActive(center==true);

	-- print("136",sprinttb(cfg));
	local _obj = bossNode.gameObject;
    
    local _boss = bossNode[CS.Spine.Unity.SkeletonGraphic];

    local path = cfg.mode_type == 1 and "roles_small/" or "roles/";
    -- print(path..cfg.mode.."/"..cfg.mode.."_SkeletonData");
    local _dataAsset = SGK.ResourcesManager.Load(path..cfg.mode.."/"..cfg.mode.."_SkeletonData.asset")

    -- print(_dataAsset);

    if _dataAsset then
    	local _sprite = _obj:GetComponent(typeof(SGK.DialogSprite))
    	_sprite.enabled = (cfg.mode_type ~= 2)
    	_sprite.direction = 4;
    	-- _sprite
    	_sprite.idle = status == nil and false or true;
    	-- print(sprinttb(cfg));
    	_obj.transform.localScale = UnityEngine.Vector3(cfg.mode_scale, cfg.mode_scale, cfg.mode_scale)*1
    	_boss.skeletonDataAsset = _dataAsset
    	 _boss:Initialize(true)
    	_boss.AnimationState:SetAnimation(0, cfg.mode_type == 1 and "idle1" or "idle", true)
        
        if cfg.mode_type == 1 then
        	bossNode[UnityEngine.RectTransform].rect.size = UnityEngine.Vector2(100,180);
	        node.flag[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(0,88);
	    else
	    	-- bossNode[UnityEngine.RectTransform].rect.size = UnityEngine.Vector2(744,1263);
	    	
	    end
	    
	else
		_boss.skeletonDataAsset = nil;
		-- ERROR_LOG("该动画不存在");
	end
end
function View:FreshPlayerInfo(current,func,start,_end,scale,animation_func,tag)
	local playerInfo = playerModule.Get();
	-- print("玩家信息",sprinttb(playerInfo));
	self.view.bg.playerNode.player.name[UI.Text].text = playerInfo.name;
	self.view.bg.battle.playerIcon.root.IconFrame[UI.Image]:LoadSprite("icon/"..playerInfo.head);
	self.view.bg.battle.playerIcon.root.gameObject.transform.localScale = UnityEngine.Vector3(0.8,0.8,1);
	self:FreshPlayerNode(playerInfo.head);


	--玩家动画播放
	self.view.bg.playerNode.player[UnityEngine.RectTransform].anchoredPosition = start and start or PlayerData["StartPoint"];
	self.view.bg.playerNode.player.transform.localScale = scale and scale or UnityEngine.Vector3(0.6,0.6,0.6);

	if not start then
		self.view.bg.playerNode.player.transform:DOKill();
		local tweer = self.view.bg.playerNode.player.transform:DOLocalMove(_end and _end or PlayerData["EndPoint"],PlayerData["dur"]);
		tweer:SetEase(CS.DG.Tweening.Ease.Linear);
		tweer:OnStart(function ()
			--播放移动动画
			self.view.bg.playerNode.player.transform:DOScale(1,PlayerData["dur"]):OnComplete(function ()
				-- print("玩家动画播放完毕");
				--播放idle
				self:FreshPlayerSprite(true);

				if func then
					func();
				end
			end)
		end);
	else
		self:FreshPlayerDir(4);
	end
	
end

function View:FreshPlayerSprite(status)
	local playerNode = self.view.bg.playerNode.player.bossModeRoot.bossMode;
	self:FreshSprite(playerNode,status);
end

function View:FreshSprite(node,status)
	local _sprite = node[CS.SGK.DialogSprite];

	_sprite.idle = status;
end

function View:FreshDir(node,dir)
	local _boss = node[CS.Spine.Unity.SkeletonGraphic];

	if _boss then
		local _sprite = node[CS.SGK.DialogSprite];

		if _sprite then
    		_sprite.direction = dir;
		end
	end
end

function View:FreshBuffNpcSprite(status,dir)
	local buffNpcNode = self.view.bg.buffNpcNode.boss.bossModeRoot.bossMode;
	local _sprite = buffNpcNode[CS.SGK.DialogSprite];
	if dir then
		_sprite.direction = dir;
	end
	self:FreshSprite(buffNpcNode,status);
end


function View:FreshPlayerNode(status)
	local playerNode = self.view.bg.playerNode.player.bossModeRoot.bossMode;

	-- print(gid);

	utils.PlayerInfoHelper.GetPlayerAddData(nil,99,function ( playerAddData )
		local mode = nil;
		if playerAddData then
			mode = playerAddData.ActorShow;
		else
			return;
		end

		local _obj = playerNode.gameObject;
	    -- _obj.transform.localScale = UnityEngine.Vector3(cfg.mode_scale, cfg.mode_scale, cfg.mode_scale)
	    local _boss = playerNode[CS.Spine.Unity.SkeletonGraphic];

    	-- print("=================",(SGK.BattlefieldObject.GetskeletonGraphicBonePosition(_boss,"head")))
    	local temp = self.view.bg.playerNode.player.name[UnityEngine.RectTransform].anchoredPosition
    	local pos = SGK.BattlefieldObject.GetskeletonGraphicBonePosition(_boss,"head");
	    if pos == UnityEngine.Vector3.zero then

	    	self.view.bg.playerNode.player.name[UnityEngine.RectTransform].anchoredPosition = Vector2(temp.x,205) 

	    else
	    	self.view.bg.playerNode.player.name[UnityEngine.RectTransform].anchoredPosition = Vector2(temp.x,pos.y) 
	    end
	    -- 205.4
	    local path = "roles_small/";
	    -- print(path..cfg.mode.."/"..cfg.mode.."_SkeletonData");
	    local _dataAsset = SGK.ResourcesManager.Load(path..mode.."/"..mode.."_SkeletonData.asset")

	    if _dataAsset then
	    	_boss.skeletonDataAsset = _dataAsset
	        _boss:Initialize(true)
	        _boss.startingLoop = true
	        
	        if not status then
		        _boss.AnimationState:SetAnimation(0, "idle1", true)
	        else
	        	_boss.AnimationState:SetAnimation(0, "run1", true)
		    end
	        self:FreshPlayerSprite(false);
		else
			_boss.skeletonDataAsset = nil;
			-- ERROR_LOG("该动画不存在");
		end
	end)


	
	
	
end

--刷新玩家朝向
function View:FreshPlayerDir(dir)
	local playerNode = self.view.bg.playerNode.player.bossModeRoot.bossMode;

	local _boss = playerNode[CS.Spine.Unity.SkeletonGraphic];

	if _boss then
		local _sprite = playerNode[CS.SGK.DialogSprite];

		if _sprite then
    		_sprite.direction = dir;
		end
	end
end

function View:FreshMonster(current,func,status,func1)
	local list = self.view.bg.battle.list;
	local flag = nil
	self.view.bg.battle.list.flag[UnityEngine.RectTransform].anchoredPosition = BattleStartData.flagPos;
	for i=1,5 do
		local cfg = trialTowerConfig.GetConfig(current+i-1);
		local item = list.points["point"..i];

		item[UnityEngine.RectTransform].anchoredPosition = BattleStartData.startPoint + Vector2(0,BattleStartData.offest*(i-1) or 0);
		if not cfg then
			item.gameObject:SetActive(false);
		else
			flag = (cfg.difficulty == 2) and i or flag ;
			self:FreshItemMonster(item,cfg,cfg.difficulty == 2);
		end
	end
	
	if not status then
		list.points[UnityEngine.RectTransform].anchoredPosition = BattleData["StartPoint"];
		-- print(BattleData["dur"])
		local tweer = list.points.transform:DOLocalMove(BattleData["EndPoint"],BattleData["dur"]);
		tweer:OnComplete(function ( ... )
			list[UI.Image].enabled = false;
			if func then
				func();
			end
		end);
	else
		if func1 then
			func1();
		end
	end
	
end

function View:FreshItemMonster(parent,cfg,isBoss)
	-- print(cfg.fight_id);

	parent.name.boss.gameObject:SetActive(isBoss);


	if  not cfg or not cfg.fight_id  then
		return;
	end
	if isBoss then
		for i=1,#parent.name-1 do
			parent.name[i].gameObject:SetActive(false);
		end
	else
		local current = cfg.fight_id - 60000000;
		local wei = 1;
		while(math.floor(current/UnityEngine.Mathf.Pow(10,wei or 1)) ~= 0) do 
			wei = wei +1;
		end
		parent.name[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(50+wei*10,28);
		parent.name.Text[UI.Text].text = cfg.fight_id - 60000000
	end

	parent.root.IconFrame[UI.Image]:LoadSprite("icon/"..cfg.icon);
	parent.root.gameObject.transform.localScale = not isBoss and UnityEngine.Vector3(0.5,0.5,1) or UnityEngine.Vector3(0.7,0.7,1);
	parent.root.IconLine[CS.UGUISpriteSelector].index = (isBoss and 1 or 0);
	local frame = parent.root.IconFrame;

	local status = nil
	frame[UI.Toggle].onValueChanged:AddListener(function (value) 
		
		if value == true then
			frame.reward.gameObject:SetActive(true);
			if not status then
				self:RreshFirstReward(frame,cfg);
			end

		else
			frame.reward.gameObject:SetActive(false);
		end
	end)

end


function View:RreshFirstReward(parent,cfg)
	print(sprinttb(cfg.firstReward));

	for i=1,4 do
		local item = parent.reward.bg["IconFrame"..i];

		local data = cfg.firstReward[i];
		
		if data then
			item.gameObject:SetActive(true);
			local item_cfg = utils.ItemHelper.Get(data.type,data.id);
			item_cfg.count = data.count;
			utils.IconFrameHelper.Create(item, {customCfg = item_cfg, type = 41,showName =true, showDetail= true});
		else
			item.gameObject:SetActive(false);
		end
	end

	parent.reward[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(#cfg.firstReward*200,parent.reward[UnityEngine.RectTransform].sizeDelta.y);
end


function View:listEvent()
	return{
		"PLAYER_ADDDATA_CHANGE",
		"TRIAL_SWEEPING_SUCCESS",
		"QUEST_INFO_CHANGE",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event,data)
	if event == "PLAYER_ADDDATA_CHANGE" then
		-- self:FreshPlayerNode(true);
	elseif event == "TRIAL_SWEEPING_SUCCESS" then
		self.view.bg.reward.tips.gameObject:SetActive(false);
	elseif event == "QUEST_INFO_CHANGE" then
		print(data and data.id or "++++");
		if data and data.id == self.current then
			self:Fresh();
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end
-- if event == "PLAYER_ADDDATA_CHANGE" then


return View;