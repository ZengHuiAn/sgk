local traditionalArenaModule = require "module.traditionalArenaModule"
local HeroEvo = require "hero.HeroEvo"
local unionModule = require "module.unionModule"
local HeroModule = require "module.HeroModule"

local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view.Content;
    self.Pid = module.playerModule.GetSelfID();
	self:InitView(data);
end

local challengeItemId = 90169
function View:InitView(data)
	self.selectPid = data and data[1]
	local selectPos = data and data[2]
    local showChallenge = data and data[3] or false

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function()
		DialogStack.Pop();
	end
	CS.UGUIClickEventListener.Get(self.root.view.closeBtn.gameObject).onClick = function()
		DialogStack.Pop();
	end

	self.view.top.addFriendBtn:SetActive(self.selectPid>1000000 and self.selectPid~= module.playerModule.GetSelfID())
	CS.UGUIClickEventListener.Get(self.view.top.addFriendBtn.gameObject).onClick = function()
		utils.PlayerInfoHelper.GetPlayerAddData(self.selectPid, utils.PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS, function(addData)
			unionModule.AddFriend(self.selectPid)
		end)
	end

	self._count = module.ItemModule.GetItemCount(challengeItemId)
	self.view.challengeBtn:SetActive(showChallenge)
	self.view.tip:SetActive(not showChallenge and self.selectPid~= self.Pid)
	CS.UGUIClickEventListener.Get(self.view.challengeBtn.gameObject).onClick = function()
		if self._count > 0 then
			if SceneStack.GetBattleStatus() then
				showDlgError(nil, "战斗内无法进行该操作")
				return;
			end
			if utils.SGKTools.GetTeamState() then
				if utils.SGKTools.isTeamLeader() or module.TeamModule.GetAfkStatus() then
					self.view.challengeBtn[CS.UGUIClickEventListener].interactable = false;
					traditionalArenaModule.GetChallengeData(selectPos,self.selectPid)
				else
					showDlgError(nil, "队伍内无法进行该操作")
				end
			else
				self.view.challengeBtn[CS.UGUIClickEventListener].interactable = false;
				traditionalArenaModule.GetChallengeData(selectPos,self.selectPid)
			end
		else
			DialogStack.PushPrefStact("traditionalArena/addFightNumFrame");
		end
	end

	if self.selectPid <1000000  then
		local playerdata = traditionalArenaModule.GetNpcCfg(self.selectPid)
		local headIconCfg = module.ItemModule.GetShowItemCfg(playerdata.HeadFrameId)
		local _headFrame = headIconCfg and headIconCfg.effect or ""

		utils.IconFrameHelper.Create(self.view.top.IconFrame,{type=utils.ItemHelper.TYPE.PLAYER, customCfg=
			{
				-- pid   = self.selectPid,
				head  = playerdata.icon,
				level = playerdata.level1,
				vip   = playerdata.vip_lv,
				sex   = playerdata.Sex,
				headFrame = _headFrame,
			}
		})

		self.view.top.name.Text[UI.Text].text = playerdata.name
	else
		utils.PlayerInfoHelper.GetPlayerAddData(self.selectPid,nil,function (addData)
			utils.IconFrameHelper.Create(self.view.top.IconFrame,{pid=self.selectPid,customCfg = {HeadFrame = addData.HeadFrame,sex = addData.Sex}})
			if module.playerModule.IsDataExist(self.selectPid) then
				local playerdata = module.playerModule.Get(self.selectPid);
				if playerdata then
					self.view.top.name.Text[UI.Text].text = playerdata.name
				end
			else
				module.playerModule.Get(self.selectPid,function ( ... )
					local playerdata = module.playerModule.Get(self.selectPid);
					if playerdata then
						self.view.top.name.Text[UI.Text].text = playerdata.name
					end          
				end)
			end
		end)

	end

	local rank_Info = traditionalArenaModule.GetDefenderFightInfo(self.selectPid)
	self:updateFormation(rank_Info)

	self:updateReward(selectPos)
end

function View:updateFormation(rank_Info)
	for i=1,self.view.mid.Content.transform.childCount do
		self.view.mid.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	if rank_Info then
		self.view.top.capacity.Text[UI.Text].text = rank_Info.capacity
		for i=1,#rank_Info.heros do
			local item = traditionalArenaModule.GetCopyUIItem(self.view.mid.Content,self.view.mid.Content.item,i)
			if item then
				local _hero = rank_Info.heros[i]
				item.capacity.Text[UI.Text].text = _hero.property.capacity
				
				local heroCfg = HeroModule.GetConfig(_hero.id)
				local _quality = heroCfg and heroCfg.role_stage or 1
				utils.IconFrameHelper.Create(item.IconFrame,{
					customCfg = {
						icon    = _hero.mode,
						role_stage = _quality,
						star    = _hero.star,
						level   = _hero.level,
					}, type = utils.ItemHelper.TYPE.HERO});
			end
		end
	end
end

function View:updateReward(pos)
	local rewardsCfg = traditionalArenaModule.GetRewardsCfg(pos).rewards
	for i=1,self.view.bottom.Content.transform.childCount do
		self.view.bottom.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	for i=1,#rewardsCfg do
		local item = traditionalArenaModule.GetCopyUIItem(self.view.bottom.Content,self.view.bottom.Content.item,i)
		if item then
			local _rewardCfg = rewardsCfg[i]
			utils.IconFrameHelper.Create(item.IconFrame,{type = _rewardCfg.type, id = _rewardCfg.id, count = _rewardCfg.count,showDetail=true})
		end
	end
end

function View:initGuide()
    module.guideModule.PlayByType(120,0.2)
end

function View:listEvent()
	return {
		"TRADITIONAL_RANKINFO_CHANGE",
		"TRADITIONAL_ARENA_FORMATION_CHANGE",
		"TRADITIONAL_ARENA_FORMATION_CHANGE_FAILD",
		"SHOP_BUY_SUCCEED",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event,data)
	if event == "TRADITIONAL_RANKINFO_CHANGE"  then
		if data and self.selectPid == data.pid then
			self:updateFormation(data)
		end
	elseif event == "TRADITIONAL_ARENA_FORMATION_CHANGE" or event == "TRADITIONAL_ARENA_FORMATION_CHANGE_FAILD" then
		self.view.challengeBtn[CS.UGUIClickEventListener].interactable = true;
	elseif event == "SHOP_BUY_SUCCEED" then
		self._count = module.ItemModule.GetItemCount(challengeItemId)
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

return View;