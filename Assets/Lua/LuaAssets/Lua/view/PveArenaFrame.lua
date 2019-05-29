local arenaModule = require 'module.arenaModule';
local HeroModule = require "module.HeroModule"
local ItemHelper=require"utils.ItemHelper"
local Time = require "module.Time";
local ParameterShowInfo = require "config.ParameterShowInfo";
local RedDotModule = require "module.RedDotModule"
local PlayerModule = require "module.playerModule";
local HeroEvo = require "hero.HeroEvo"
local Property = require "utils.Property"
local TipCfg = require "config.TipConfig"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"

local View={};


local consumeId=90007
function View:Start ()	
	self.view=CS.SGK.UIReference.Setup(self.gameObject)
	self.ShowView=self.view.view
	self:Init();
end

function View:Init()
	arenaModule.ApplyJoinArena();

	self.IsUnFree=false;	
	self.SelectBuffIndex=1

	self.effectTab={}
	self.item_guardTab={}
	self.buff_tab={}

	self:setCallback();
	
	self.RolesUITab={}
	self.RewardUITab={}
	self.exRewardUITab={}
	self.BoxRewardUITab={}
	self.DetailPlayerIcon=nil

	module.guideModule.PlayByType(123,1.5)
	RedDotModule.CloseRedDot(RedDotModule.Type.Arena.First)

	DispatchEvent("CurrencyRef",{3,90025})
end

local resetTime=60*60*2
local resetConsumId = 90003
local resetConsumValue = 20
function View:setCallback()
	for i=1,3 do
		CS.UGUIClickEventListener.Get(self.ShowView.bottom.mid[i].gameObject).onClick = function (obj) 
			self.RewardsIndex=i;
			self:InRewardsPanelData(self.RewardsIndex)
		end
	end

	self.ShowView.bottom.bottom.Slider[UI.Slider].onValueChanged:AddListener(function ()
		local _value=math.floor(self.ShowView.bottom.bottom.Slider[UI.Slider].value)
		self.ShowView.bottom.bottom.Slider.Tip.Image.numText[UI.Text].text=_value~= 0 and tostring(_value) or ""
	end)

	CS.UGUIClickEventListener.Get(self.ShowView.RewardsPanel.view.GetRewards_Button.gameObject).onClick = function (obj)
		self.BoxRewardGet[self.RewardsIndex].IsGet=1;
		arenaModule.SendGetAwards(self.RewardsIndex);

		self.ShowView.RewardsPanel.view.GetRewards_Button[CS.UGUIClickEventListener].interactable=false
	end

	-- CS.UGUIClickEventListener.Get(self.ShowView.mid.challengeTicket.Add.gameObject).onClick = function (obj)
	-- 	 DialogStack.Push("ShopFrame",{index = 2});
	-- end

	CS.UGUIClickEventListener.Get(self.ShowView.RewardsPanel.view.GetRewards_Exit_Button.gameObject).onClick = function (obj)
		self.ShowView.RewardsPanel.gameObject:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.ShowView.RewardsPanel.mask.gameObject,true).onClick = function (obj) 
		self.ShowView.RewardsPanel.gameObject:SetActive(false,true);
	end

	CS.UGUIClickEventListener.Get(self.ShowView.top.TipBtn.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(TipCfg.GetAssistDescConfig(56001).info,TipCfg.GetAssistDescConfig(56001).tittle, self.root)
	end

	CS.UGUIClickEventListener.Get(self.ShowView.mid.bottom.resetBtn.gameObject).onClick = function (obj)
		self:InResetPanel()
	end
	CS.UGUIClickEventListener.Get(self.ShowView.mid.challengeTicket.gameObject,true).onClick = function (obj)
		DialogStack.PushPrefStact("ItemDetailFrame", {id =consumeId, type=utils.ItemHelper.TYPE.ITEM,InItemBag=2})
	end

	local resetConsume = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,resetConsumId)
	if resetConsume then
		self.ShowView.mid.bottom.resetBtn.unFreeTip.Image[UI.Image]:LoadSprite("icon/"..resetConsume.icon.."_small")
		self.ShowView.mid.bottom.resetBtn.unFreeTip.Text[UI.Text].text = "x"..resetConsumValue
	end

	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.gameObject.transform)
 end

function View:InBaseData()
	self.BoxRewardGet=self.ArenaData.GetRewardStatus;
	if Time.now()-self.ArenaData.lastResetTime >= resetTime then
		self.IsUnFree = false;
	else
		self.IsUnFree = true;	
	end
	self.ShowView.mid.bottom.resetBtn.freeTip:SetActive(not self.IsUnFree)
	self.ShowView.mid.bottom.resetBtn.unFreeTip:SetActive(self.IsUnFree)
	self.ShowView.mid.bottom.resetTip.gameObject:SetActive(self.IsUnFree);

	--self.ShowView.mid.bottom.resetBtn[CS.UGUIClickEventListener].interactable=not self.IsUnFree

	local winNum=self.ArenaData.winNum;
	local GetBuffTime=self.ArenaData.GetBuffTime

	if (math.floor(winNum/2)>0  and GetBuffTime<math.floor(winNum/2) and winNum< 9) or (winNum>=8 and GetBuffTime<4) then-- 2 4 6  8
		self:InBuffSelectPanel(winNum)
	end
	local consume = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,consumeId)
	self.ChallengeTicketCount=module.ItemModule.GetItemCount(consumeId)
	self.ShowView.mid.challengeTicket.Icon[UI.Image]:LoadSprite("icon/"..consume.icon.."_small")
	self.ShowView.mid.challengeTicket.num[UI.Text]:TextFormat("{0}/30",self.ChallengeTicketCount);

	local buffs = self.ArenaData.buffs;       
	self:refreshBattlePointData(buffs);	
	self:refreshRewardsData(winNum);
end

function View:InBuffSelectPanel(winNum)
	local condition=winNum<4 and 2 or winNum<6 and 4 or winNum <8 and 6 or 8
	self.ShowView.buffSelectPanel.gameObject:SetActive(true);

	self.ShowView.buffSelectPanel.view.Icon[CS.UGUISpriteSelector].index = math.floor(winNum/2);
	self.ShowView.buffSelectPanel.view.Tip[UI.Text].text=string.format("恭喜获得%s场胜利\n<color=#FF5A3AFF>可选择一个增益奖励</color>",winNum)
	
	self.ShowView.buffSelectPanel.view.buff_EnSure_Btn[CS.UGUIClickEventListener].interactable=false
	local buffTab=arenaModule.GetBuffCfgByCondition(condition)

	for i,v in ipairs(buffTab) do
		---self.ShowView.buffSelectPanel.view.buffs[i].Background[UI.Image]:LoadSprite("icon/"..v.buff_icon_bg)
		local isperc = false
		if string.find(v.des, "%%%%") ~= nil then
			isperc = true;
		end

		self.ShowView.buffSelectPanel.view.buffs[i].Label[UI.Text].text=string.format(v.des,isperc and math.floor(v.buff_value1/100) or v.buff_value1)

		CS.UGUIClickEventListener.Get(self.ShowView.buffSelectPanel.view.buffs[i].gameObject).onClick = function (obj)
			self.SelectBuffIndex=i;
			self.ShowView.buffSelectPanel.view.buff_EnSure_Btn[CS.UGUIClickEventListener].interactable=true
		end
	end
	CS.UGUIClickEventListener.Get(self.ShowView.buffSelectPanel.view.buff_EnSure_Btn.gameObject).onClick = function (obj)
		self.ShowView.buffSelectPanel.view.buff_EnSure_Btn[CS.UGUIClickEventListener].interactable=false
		arenaModule.SendAddBuff(buffTab[self.SelectBuffIndex].gid);
	end
end

function View:refreshBattlePointData(buffs)
	-- local startbattlePoint=self.ArenaData.startbattlepoint;
	for k,v in pairs(self.buff_tab) do
		v.gameObject:SetActive(false)
	end
	self.ShowView.top.battlepoint.gameObject:SetActive(true)

	local _capacity=HeroModule.GetManager():GetCapacity();
	local capacity=_capacity

	if buffs~= nil and next(buffs)~=nil then
		capacity =0
		for _,v in pairs(self.ArenaData.selfFormation) do
			local property_list = {};
			for _k,_v in pairs(v.property_list) do
				property_list[_k]=_v
			end

			for _k,_v in pairs(buffs) do
				property_list[_k]=property_list[_k] or 0 +_v
			end
			local property = Property(property_list)
			capacity=capacity+property.capacity
		end
	end

	self.ShowView.top.battlepoint.battlepoint[UI.Text]:TextFormat("<color=#FFD800FF>{0}</color>",math.floor(capacity))
	-- if self.ArenaData.WinRate>100 then
	-- 	self.ShowView.top.battlepoint.battlepoint[UI.Text]:TextFormat("英雄比拼战力:{0}{1}{2}\t\t我的战力:{3}{4}{5}","<color=#FFD800FF>",self.ArenaData.MatchCapacity,"</color>","<color=#FFD800FF>",math.floor(capacity),"</color>")
	-- else
	-- 	self.ShowView.top.battlepoint.battlepoint[UI.Text]:TextFormat("胜率:{0}{1}%{2}\t\t英雄比拼战力:{3}{4}{5}\t\t我的战力:{6}{7}{8}","<color=#FFD800FF>",self.ArenaData.WinRate,"</color>","<color=#FFD800FF>",self.ArenaData.MatchCapacity,"</color>","<color=#FFD800FF>",math.floor(capacity),"</color>")
	-- end
	
	-- self.ShowView.top.battlepoint.battlepoint.Addbattlepoint.gameObject:SetActive(math.floor(capacity-_capacity)>0)
	-- self.ShowView.top.battlepoint.battlepoint.Addbattlepoint[UI.Text].text=string.format('(+%d)',math.floor(capacity-_capacity))

	local _temp={}
	local __temp={}
	local i=0
	if buffs then
		for k,v in pairs(buffs) do
			local cfg = ParameterShowInfo.Get(k);
			if cfg and not __temp[cfg.name] then
				__temp[cfg.name]=v
				local _tab={}
				_tab.k=k
				_tab.key=cfg.name
				_tab.Value=v
				table.insert(_temp,_tab)
			else
				ERROR_LOG("ParameterShowInfo is nil,k",k)
			end
		end
	end
	table.sort(_temp, function(a, b)
		local buffTab_a=arenaModule.GetBuffConfigByBuffType(a.k)
		local buffTab_b=arenaModule.GetBuffConfigByBuffType(b.k)
		return buffTab_a.condition<buffTab_b.condition
	end)

	for i=1,4 do
		self.ShowView.top.statusBar[i].active.gameObject:SetActive(not not _temp[i])
		self.ShowView.top.statusBar[i].deactive.gameObject:SetActive(not _temp[i])
		if _temp[i] then
			local buffTab=arenaModule.GetBuffConfigByBuffType(_temp[i].k)
			--self.ShowView.top.statusBar[i].active.Image[UI.Image]:LoadSprite("propertyIcon/"..buffTab.buff_icon_small)
			local isperc = false
			if string.find(buffTab.des, "%%%%") ~= nil then
				isperc = true;
			end
			self.ShowView.top.statusBar[i].active.Text[UI.Text].text=string.format(buffTab.des,isperc and math.floor(_temp[i].Value/100) or _temp[i].Value)--.text=tostring(buffs[i].Label);
		else
			self.ShowView.top.statusBar[i].deactive.Text[UI.Text]:TextFormat("{0}胜激活",2*i)
		end
	end
end

local boxTab={89010,89011,89012}
function View:refreshRewardsData(idx)
	self.ShowView.top.Icon[CS.UGUISpriteSelector].index = math.floor(idx/2);

	self.ShowView.bottom.bottom.Slider[UI.Slider].value=idx;
	self.ShowView.bottom.bottom.Slider.Tip.Image.numText[UI.Text].text=tostring(idx)
	if idx==0 then
		for i=2,4 do
			self.ShowView.bottom.bottom.Slider.Container[i].gameObject:SetActive(false);
		end
	end
	for i=1,3 do
		if idx>=i*3 then
			self.ShowView.bottom.bottom.Slider.Container[i+1].gameObject:SetActive(true);
		end

		if idx>=3*i then
			if self.BoxRewardGet[i].IsGet==0 then
				--self.ShowView.bottom.mid[i].box[UI.Image]:LoadSprite("icon/"..boxTab[i].."-1")
				self.ShowView.bottom.mid[i].box[CS.UGUISpriteSelector].index = 0
				if not self.effectTab[i] then
					self.effectTab[i]=self:playEffect("fx_TreasureBox_get", Vector3(0, 0, 0),self.ShowView.bottom.mid[i].fx_node.gameObject)
				end
			else
				-- self.ShowView.bottom.mid[i].box[UI.Image]:LoadSprite("icon/"..boxTab[i].."-2")
				self.ShowView.bottom.mid[i].box[CS.UGUISpriteSelector].index = 1
				if self.effectTab[i] then
					UnityEngine.GameObject.Destroy(self.effectTab[i])
				end
			end
		else
			-- self.ShowView.bottom.mid[i].box[UI.Image]:LoadSprite("icon/"..boxTab[i].."-1")
			self.ShowView.bottom.mid[i].box[CS.UGUISpriteSelector].index = 0
			if self.effectTab[i] then
				UnityEngine.GameObject.Destroy(self.effectTab[i])
			end
		end
	end
end

function View:InRewardsPanelData(idx)
	if not self.ArenaData then return end
	self.ShowView.RewardsPanel.gameObject:SetActive(true);
	self.ShowView.RewardsPanel.view.Tip[UI.Text]:TextFormat('战胜{0}位玩家后可领取',3*idx)
	local BoxReward=self.ArenaData.BoxRewards[idx];

	self.BoxRewardUITab=self:InRefReardShow(BoxReward,self.BoxRewardUITab,self.ShowView.RewardsPanel.view.Content)
	local case=self.ArenaData.winNum>=3*idx and self.BoxRewardGet[idx].IsGet==0

	self.ShowView.RewardsPanel.view.GetRewards_Button[CS.UGUIClickEventListener].interactable=case
	self.ShowView.RewardsPanel.view.GetRewards_Button.Text[UI.Text]:TextFormat(self.BoxRewardGet[idx].IsGet==1 and "已领取" or "领取")--.text=self.BoxRewardGet[idx].IsGet==1 and "已领取" or "领取"
end

function View:DoCopy(i,_prefab)
	local _obj
	if self.item_guardTab[i] then
		_obj=self.item_guardTab[i]
	else
		_obj = UnityEngine.Object.Instantiate(_prefab.gameObject)
		_obj.name = "item_guard_"..i
		self.item_guardTab[i] = _obj
		_obj.transform:SetParent(self.ShowView.mid.ScrollView.Viewport.Content.gameObject.transform,false)
	end
	_obj.gameObject:SetActive(true)
	local item = CS.SGK.UIReference.Setup(_obj.transform)
	return item
end

function View:InGuardsPanel(Reset)
	for k,v in pairs(self.item_guardTab) do
		v.gameObject:SetActive(false)
	end
	local _prefab=self.ShowView.mid.ScrollView.Viewport.Content.item_guard
	if not self.GuardsData then return end
	if not Reset then
		for i=1,9 do
			if self.GuardsData[i] then
				local item_guard = self:DoCopy(i,_prefab)
				self:InGuardInfo(item_guard,i)
			end
		end
	else
		for i=1,3 do
			if self.GuardsData[i] then
				local _Idx = i
				local item_guard = self:DoCopy(_Idx,_prefab)
				item_guard.transform:DORotate(Vector3(0,-180,0),0.1):OnComplete(function ( ... )
					self:InGuardInfo(item_guard,_Idx)
					item_guard.transform:DORotate(Vector3(0,-360,0),0.1)
				end):SetDelay((i-1)*0.1)
			end
			if self.GuardsData[i+3] then
				local _Idx = i+3
				local item_guard = self:DoCopy(_Idx,_prefab)
				item_guard.transform:DORotate(Vector3(0,-180,0),0.1):OnComplete(function ( ... )
					self:InGuardInfo(item_guard,_Idx)
					item_guard.transform:DORotate(Vector3(0,-360,0),0.1)
				end):SetDelay((i-1)*0.1+0.15)
			end
			if self.GuardsData[i+6] then
				local _Idx = i+6
				local item_guard = self:DoCopy(_Idx,_prefab)
				item_guard.transform:DORotate(Vector3(0,-180,0),0.1):OnComplete(function ( ... )
					self:InGuardInfo(item_guard,_Idx)
					item_guard.transform:DORotate(Vector3(0,-360,0),0.1)	
				end):SetDelay((i-1)*0.1+0.3)
			end
		end
		self.view.transform:DOScale(Vector3.one, 0.5):OnComplete(function()
          	showDlgError(nil, "刷新成功")
        end)
	end
end

function View:InGuardInfo(item_guard,i)
		local guardStatus =self.GuardsData[i].status;
		local battlePoint=self.GuardsData[i].StartBattlePoint and self.GuardsData[i].StartBattlePoint or 1000;
		local difficulty=self.GuardsData[i].difficulty and self.GuardsData[i].difficulty or 1;
		local buffTime=self.GuardsData[i].buffIncrease;
	
		local FightNum=self.GuardsData[i].FightNum;
		self.GuardsData[i].level=self.GuardsData[i].level and self.GuardsData[i].level or 999

		if self.reseted == false then
			self.reseted = true;
			guardStatus = 2;
			battlePoint = battlePoint+math.floor(battlePoint*0.01)*buffTime;
		end
		
		item_guard.playerInfo.name.Text[UI.Text].text=tostring(self.GuardsData[i].name);
		item_guard.playerInfo.battlepoint.Text[UI.Text].text=string.format("%s%d%s","<color=#FFD800FF>",math.floor(battlePoint),"</color>");

		local pid=self.GuardsData[i].pid
		if pid < 110000 and  pid > 100000 then
			local npcPlayerCfg=arenaModule.GetGuardData(pid).cfg
			self.GuardsData[i].head=npcPlayerCfg.icon
			self.GuardsData[i].level=npcPlayerCfg.level1;

			self.GuardsData[i].vip=0

			local headIconCfg = module.ItemModule.GetShowItemCfg(npcPlayerCfg.HeadFrameId)
			self.GuardsData[i].sex =npcPlayerCfg.Sex
			self.GuardsData[i].headFrame =headIconCfg and headIconCfg.effect or ""

			utils.IconFrameHelper.Create(item_guard.Icon.IconFrame,{customCfg=self.GuardsData[i]})
		else
			PlayerInfoHelper.GetPlayerAddData(pid, 99, function (addData)
				utils.IconFrameHelper.Create(item_guard.Icon.IconFrame,{pid = pid,customCfg = {HeadFrame = addData.HeadFrame,sex = addData.Sex}})
			end)
		end

		for i=1,5 do
			item_guard.playerInfo.difficult[i].gameObject:SetActive(false);
		end
		for i=1,difficulty do
			item_guard.playerInfo.difficult[i].gameObject:SetActive(true);
		end
		
		item_guard.WinImage.gameObject:SetActive(guardStatus==1);
		item_guard.DefeatedImage.gameObject:SetActive(guardStatus==0 and FightNum>0);

		CS.UGUIClickEventListener.Get(item_guard.Icon.gameObject,true).onClick = function (obj) 
			self:InGuardDetailPanel(i);	
		end
end

function View:InGuardDetailPanel(idx)
	self.ShowView.GuardDetailPanel.gameObject:SetActive(true);

	local difficulty=self.GuardsData[idx].difficulty;
	local battlePoint=self.GuardsData[idx].StartBattlePoint;
	local buffTime=self.GuardsData[idx].buffIncrease;

	battlePoint=battlePoint+math.floor(battlePoint*0.01)*buffTime;
		
	self.guardIndex=idx;--守卫的Index
	local detailData=self.ShowView.GuardDetailPanel.view.Grid.detailData

	local pid=self.GuardsData[idx].pid
	if pid < 110000 and  pid > 100000 then
		self:RefDetailPlayerIcon(self.GuardsData[idx],pid)
	else
		PlayerModule.Get(pid,function ( ... )
			local player=PlayerModule.Get(pid);
			self:RefDetailPlayerIcon(player,pid)	
		end)
	end

	detailData.playerInfo.name.Text[UI.Text].text=self.GuardsData[idx].name;
	detailData.playerInfo.battlepoint.Text[UI.Text].text=tostring(math.floor(battlePoint));

	local Grid=self.ShowView.GuardDetailPanel.view.Grid

	for i=1,5 do
		detailData.playerInfo.difficult[i].gameObject:SetActive(false);
	end

	for i=1,difficulty do
		detailData.playerInfo.difficult[i].gameObject:SetActive(true);
	end

	local heroes=arenaModule.GetGuardHeros(idx);
	self:RefHeroInfo(heroes,self.GuardsData[idx].pid)

	local Reward=self.GuardsData[idx].Rewards
	self.RewardUITab=self:InRefReardShow(Reward,self.RewardUITab,Grid.Reward.ScrollView.Viewport.Content)	

	local case=tonumber(self.GuardsData[idx].status)==0 and self.GuardsData[idx].FightNum>0

	Grid.extraReward.gameObject:SetActive(false);--不再有额外奖励
	--Grid.extraReward.gameObject:SetActive(not not case);
	Grid.challenge_Panel.Tip.gameObject:SetActive(not not case);

	local consume=utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,consumeId)
	self.ShowView.GuardDetailPanel.view.Grid.challenge_Panel.challenge_Button.Icon[UI.Image]:LoadSprite("icon/"..consume.icon.."_small")
	Grid.challenge_Panel.Tip[UI.Text]:TextFormat("若挑战成功扣除1{0},若失败不扣除",consume.name)
	-- if  case then
	-- 	local exReward=self.GuardsData[idx].exRewards
	-- 	self.exRewardUITab=self:InRefReardShow(exReward,self.exRewardUITab,Grid.extraReward.ScrollView.Viewport.Content)		
	-- end
	
	local _guardStatus =self.GuardsData[self.guardIndex].status;
	--showDlgError(nil,"该关卡已胜利")
	self.ShowView.GuardDetailPanel.view.Grid.challenge_Panel.challenge_Button[CS.UGUIClickEventListener].interactable=_guardStatus~=1
	CS.UGUIClickEventListener.Get(self.ShowView.GuardDetailPanel.view.Grid.challenge_Panel.challenge_Button.gameObject).onClick = function (obj) 
	  	if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
        elseif utils.SGKTools.GetTeamState() then
            showDlgError(nil, "队伍内无法进行该操作")
        else
        	self:challenge();
        end	
	end
	CS.UGUIClickEventListener.Get(self.ShowView.GuardDetailPanel.view.Exit_Button.gameObject).onClick = function (obj) 
		self.ShowView.GuardDetailPanel.gameObject:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.ShowView.GuardDetailPanel.mask.gameObject,true).onClick = function (obj) 
		self.ShowView.GuardDetailPanel.gameObject:SetActive(false);
	end
end

function View:RefDetailPlayerIcon(info,pid)
	if pid < 110000 and  pid > 100000 then
		utils.IconFrameHelper.Create(self.ShowView.GuardDetailPanel.view.Grid.detailData.PlayerIcon,{pid = pid,customCfg = {HeadFrame = info.HeadFrame,sex = info.Sex}})
	else
		PlayerInfoHelper.GetPlayerAddData(pid, 99, function (addData)
			utils.IconFrameHelper.Create(self.ShowView.GuardDetailPanel.view.Grid.detailData.PlayerIcon,{pid = pid,customCfg = {HeadFrame = addData.HeadFrame,sex = addData.Sex}})
		end)
	end	
end

function View:RefHeroInfo(heroes,pid)
	for k,v in pairs(self.RolesUITab) do
		v.gameObject:SetActive(false)
	end
	if heroes then
		for i=1,#heroes do
			local evoConfig = HeroEvo.GetConfig(heroes[i].id);
			if pid < 110000 and  pid > 100000 then
				local _heroes=arenaModule.GetGuardData(pid).heros
				local _heroCfg = module.HeroModule.GetConfig(_heroes[i].id)
			 	heroes[i].role_stage = _heroCfg and _heroCfg.role_stage or 1;
			 	heroes[i].star=_heroes[i].star
			 else
			 	local _heroCfg = module.HeroModule.GetConfig(heroes[i].id)
				heroes[i].icon=heroes[i].mode
		 		heroes[i].star = heroes[i].grow_star;
			 	heroes[i].role_stage = _heroCfg and _heroCfg.role_stage or 1;
			end

			local _obj
			if self.RolesUITab[i] then
				_obj=self.RolesUITab[i]
			else
				_obj=SGK.ResourcesManager.Load("prefabs/base/CharacterIcon.prefab")
				_obj= CS.UnityEngine.GameObject.Instantiate(_obj)
				_obj.gameObject.transform.localScale =Vector3(0.8,0.8,1)
				_obj.transform:SetParent(self.ShowView.GuardDetailPanel.view.Grid.formation.ScrollView.Viewport.Content.gameObject.transform,false)
				self.RolesUITab[i]=_obj
			end
			_obj.gameObject:SetActive(true)
			local _heroIcon=SGK.UIReference.Setup(_obj.transform)
			_heroIcon[SGK.CharacterIcon]:SetInfo(heroes[i])
		end
	end
end

local resetInfoId = 56002
function View:InResetPanel()
	self.ShowView.resetPanel.gameObject:SetActive(true);
	local resetInfo=TipCfg.GetAssistDescConfig(resetInfoId)

	self.ShowView.resetPanel.view.Tip_bg.Tip[UI.Text].text=tostring(resetInfo.info)
	CS.UGUIClickEventListener.Get(self.ShowView.resetPanel.view.reset_EnSure_Button.gameObject).onClick = function (obj) 
		if not self.IsUnFree then
			self.reseted = false;
			arenaModule.ApplyReset(self.IsUnFree);
			self.ShowView.resetPanel.view.reset_EnSure_Button[CS.UGUIClickEventListener].interactable=false	
		else
			if module.ItemModule.GetItemCount(resetConsumId) >= resetConsumValue then
				self.reseted = false;
				arenaModule.ApplyReset(self.IsUnFree)
				self.ShowView.resetPanel.view.reset_EnSure_Button[CS.UGUIClickEventListener].interactable=false	
			else
				local _consumeItem = utils.ItemHelper.Get(ItemHelper.TYPE.ITEM,resetConsumId);
				showDlgError(nil,string.format("%s不足",_consumeItem.name)) 
			end
		end
	end

	CS.UGUIClickEventListener.Get(self.ShowView.resetPanel.view.reset_Exit_Button.gameObject).onClick = function (obj) 
		self.ShowView.resetPanel.gameObject:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.ShowView.resetPanel.view.reset_Cancel_Button.gameObject).onClick = function (obj) 
		self.ShowView.resetPanel.gameObject:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.ShowView.resetPanel.mask.gameObject,true).onClick = function (obj) 
		self.ShowView.resetPanel.gameObject:SetActive(false);
	end
end

--刷新重置信息显示
function View:resetRefresh(succeed)
	self.ShowView.resetPanel.view.reset_EnSure_Button[CS.UGUIClickEventListener].interactable=true
	self.ShowView.resetPanel.gameObject:SetActive(false);

	self.ShowView.mid.bottom.resetTip:SetActive(true);
	self.ShowView.mid.bottom.resetBtn.freeTip:SetActive(false)
	self.ShowView.mid.bottom.resetBtn.unFreeTip:SetActive(true)
	self:refreshBattlePointData();
	self.winNum=0;
	self:refreshRewardsData(0);
	if succeed then
		self.GuardsData=arenaModule.GetGuardsData();
		self:InGuardsPanel(true);
		self.IsUnFree = true
	end
end

function View:InRefReardShow(Reward,UITab,parent)
	for k,v in pairs(UITab) do
		v.gameObject:SetActive(false)
	end
	for i=1,#Reward do
		local _obj
		if UITab[i] then
			_obj=UITab[i]
		else
			_obj=SGK.ResourcesManager.Load("prefabs/base/ItemIcon.prefab")
			_obj= CS.UnityEngine.GameObject.Instantiate(_obj)
			_obj.gameObject.transform.localScale =Vector3(0.8,0.8,1)

			_obj.transform:SetParent(parent.gameObject.transform,false)
			UITab[i]=_obj
		end
		_obj.gameObject:SetActive(true)
		local ItemIcon=SGK.UIReference.Setup(_obj.transform)
		local _item=ItemHelper.Get(Reward[i][1],Reward[i][2]);
		ItemIcon[SGK.ItemIcon]:SetInfo(_item,false,Reward[i][3])
		ItemIcon[SGK.ItemIcon].showDetail=true
	end
	return UITab
end

function View:challenge()
	local guardStatus =self.GuardsData[self.guardIndex].status;
	local guardPid =self.GuardsData[self.guardIndex].pid;
	if  guardStatus==0 then
		--if self.GuardsData[self.guardIndex].FightNum<3 and self.ChallengeTicketCount<1	then
		if self.ChallengeTicketCount<1	then
			showDlgError(nil,'挑战券数量不足'..self.ChallengeTicketCount)
		else
			local _challengeTime=self.GuardsData[self.guardIndex].FightNum>=1 and 1 or 0 
			arenaModule.startChanllge(guardPid,self.guardIndex,_challengeTime)
		end
		self.ShowView.GuardDetailPanel.gameObject:SetActive(false);	
	elseif guardStatus==1 then
		showDlgError(nil,"该关卡已胜利")
	end
end

function View:Update()
	if self.IsUnFree and self.ArenaData then
		local time=self.ArenaData.lastResetTime+resetTime-Time.now()
		if time>=0 then
			local timeCD = string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
			self.ShowView.mid.bottom.resetTip.timer_Text[UI.Text]:TextFormat("{0}后免费",timeCD);		
		else
			self.ShowView.mid.bottom.resetTip:SetActive(false);
			self.ShowView.mid.bottom.resetBtn.freeTip:SetActive(true)
			self.ShowView.mid.bottom.resetBtn.unFreeTip:SetActive(false)
			--self.ShowView.mid.bottom.resetBtn[CS.UGUIClickEventListener].interactable=true;
			self.IsUnFree=false;
		end
	end
end

function View:playEffect(effectName, position, node, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        --transform.localScale = Vector3.zero
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function View:OnDestroy()
	DispatchEvent("CurrencyRef")
end

function View:listEvent()
	return {
		"GUARDS_INFO_CHANGE",
		"RESET_INFO",
		"AWARD_INFO_CHANGE",
		"SELF_INFO_CHANGE",
		"PLAYER_INFO_CHANGE",
		"HEROS_INFO_CHANGE",
		"LOCAL_GUIDE_CHANE",
		"GET_BUFF_SUCCEED",
		"ITEM_INFO_CHANGE",
	}
end

function View:onEvent(event,...)
	if event == "GUARDS_INFO_CHANGE" then
		self.GuardsData=arenaModule.GetGuardsData();
		self:InGuardsPanel();	
	elseif event == "SELF_INFO_CHANGE" then
		self.ArenaData=arenaModule.GetArenaData();
		if self.ArenaData and next(self.ArenaData)~= nil then
			self:InBaseData();
		end
	elseif	event == "RESET_INFO" or event == "RESET_INFO_FAILED" then
		self:resetRefresh(event == "RESET_INFO");
	elseif event == "AWARD_INFO_CHANGE" then	
		local o=self:playEffect("fx_box_kai_blue", Vector3(0, 0, 0),self.ShowView.bottom.mid[self.RewardsIndex].gameObject)
		local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
       	UnityEngine.Object.Destroy(o, _obj.main.duration)
		self.ShowView.RewardsPanel.gameObject:SetActive(false);

		self:refreshRewardsData(self.ArenaData.winNum);
	elseif	event == "HEROS_INFO_CHANGE" then	
		local heroes=arenaModule.GetGuardHeros(...);
		self:RefHeroInfo(heroes,self.GuardsData[...].pid)
	elseif event == "LOCAL_GUIDE_CHANE" then
		module.guideModule.PlayByType(123,1.5)
	elseif event == "GET_BUFF_SUCCEED" then
		self.ShowView.buffSelectPanel.gameObject:SetActive(false);
	elseif event=="ITEM_INFO_CHANGE" then
		self.ChallengeTicketCount=module.ItemModule.GetItemCount(consumeId)
		self.ShowView.mid.challengeTicket.num[UI.Text]:TextFormat("x{0}/30",self.ChallengeTicketCount);
	end
end

return View;