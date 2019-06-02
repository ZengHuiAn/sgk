local ActivityTeamlist = require "config.activityConfig"
local CemeteryConf = require "config.cemeteryConfig"
local CemeteryModule = require "module.CemeteryModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local IconFrameHelper = require "utils.IconFrameHelper"
local NetworkService = require "utils.NetworkService"
local ItemModule = require "module.ItemModule"
local TeamModule = require "module.TeamModule"
local questModule = require "module.QuestModule"
local View = {};
function View:Start(data)
	print("组队活动数据",sprinttb(data))
	self.viewRoot = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data or self.savedValues.data
	self.savedValues.data = self.Data
	self.view = self.viewRoot.Root
	self.GroupId = 0
	self.teamBattleCfg = {}
	self.viewRoot.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end
	self.viewRoot.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end
	local teamInfo = module.TeamModule.GetTeamInfo()
	self.open = ActivityTeamlist.CheckActivityOpen(self.Data.gid) --活动是否开启
	-- self.open = true
	if self.open then
		self.view.bottom.startBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("common_qianwang_01");
	else
		self.view.bottom.startBtn[CS.UGUIClickEventListener].interactable = false
		self.view.bottom.startBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("common_weikaiqi")
	end
	self.teamBattleCfg = CemeteryConf.Getteam_battle_activity(self.Data.gid,0)
	self:LoadUI(self.teamBattleCfg,self.Data.is_on)
	self.viewRoot.Dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_zuduihuodong_01")
end

function View:LoadUI(cfg,is_on)
	local data = cfg[1]
	print(sprinttb(data))
	--活跃度
	local activitycfg = ActivityTeamlist.GetActivity(self.Data.gid)
	-- local ActiveCount = ActivityTeamlist.GetActiveCountById(data.activity_id)
	-- activitycfg.huoyuedu = tonumber(activitycfg.huoyuedu)
 --  	if questModule.Get(activitycfg.huoyuedu) and questModule.Get(activitycfg.huoyuedu).status ~= 1 then
	-- 	self.view.top.active.num[UnityEngine.UI.Text].text="0".."/"..questModule.Get(activitycfg.huoyuedu).cfg[1].cfg.raw.reward_value1
	-- 	self.view.top.active.Scrollbar[UI.Scrollbar].size = 0
 --  	else
	-- 	self.view.top.active.num[UnityEngine.UI.Text].text=questModule.Get(activitycfg.huoyuedu).cfg[1].cfg.raw.reward_value1.."/"..questModule.Get(activitycfg.huoyuedu).cfg[1].cfg.raw.reward_value1
	-- 	self.view.top.active.Scrollbar[UI.Scrollbar].size = 1
 --  	end
  	--背景图
	self.view.top.bg[UnityEngine.UI.Image]:LoadSprite(data.use_picture)
	self.view.top.desc[UnityEngine.UI.Text].text = activitycfg.des
	self.GroupId = data.gid_id
	--说明
	self.view.middle.time.Text[UnityEngine.UI.Text].text = data.fresh_time_des
	self.view.middle.lv.Text[UnityEngine.UI.Text].text = data.limit_level.."级或以上"
	self.view.middle.mode.Text[UnityEngine.UI.Text].text = "需要"..data.team_member.."~5人组队"
	if activitycfg.advise_text ~= 0 then
		self.view.middle.guide.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue(activitycfg.advise_text)
	else
		self.view.middle.guide.Text[UnityEngine.UI.Text].text = "暂无攻略"
	end
	--奖励
	local a_count,b_count = ItemModule.GetItemCount(data.rewrad_count_one),ItemModule.GetItemCount(data.rewrad_count_ten)
	-- print(a_count,b_count)
	local PveState = a_count + b_count
	local max = 3--暂无地方可读
	local itemIDs = {data.drop1,data.drop2,data.drop3}
	local itemtypes = {data.type1,data.type2,data.type3}
	for i = 1,3 do
		--ERROR_LOG(i,itemIDs[i],itemtypes[i])
		if itemIDs[i] ~= 0 and itemtypes[i] ~= 0 then
			local ItemIconView = nil
			local ItemClone =nil
			-- if self.view.ItemGroup.transform.childCount < i then
			-- 	ItemIconView = IconFrameHelper.Item({id = itemIDs[i],type = itemtypes[i],showDetail = true},self.view.ItemGroup)
			-- 	ItemIconView.transform.localScale = Vector3(0.75,0.75,1)
			-- else
			-- 	local ItemClone = self.view.ItemGroup.transform:GetChild(i-1)
			-- 	ItemClone.gameObject:SetActive(true)
			-- 	ItemIconView = SGK.UIReference.Setup(ItemClone)
			-- 	IconFrameHelper.UpdateItem({id = itemIDs[i],type = itemtypes[i],showDetail = true})
			-- end
			if self.view.reward.ItemGroup.transform.childCount < i then
				local _obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/IconFrame.prefab"),self.view.reward.ItemGroup.gameObject.transform)
				--ItemIconView = IconFrameHelper.Item({id = itemIDs[i],type = itemtypes[i],showDetail = true},self.view.ItemGroup)
				_obj.transform.localScale = Vector3(0.75,0.75,1)
				ItemClone = _obj
			else
				ItemClone = self.view.reward.ItemGroup.transform:GetChild(i-1)
				ItemClone.gameObject:SetActive(true)
			end
			local ItemIconView = SGK.UIReference.Setup(ItemClone)
			utils.IconFrameHelper.Create(ItemIconView,{id = itemIDs[i],type = itemtypes[i],count=0,showDetail = true})
		else
			if self.view.reward.ItemGroup.transform.childCount >= i then
				local ItemClone = self.view.reward.ItemGroup.transform:GetChild(i-1)
				ItemClone.gameObject:SetActive(false)
			end
	    end
	end
	--按钮
	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
	self.view.bottom.teamBtn.Text[UnityEngine.UI.Text].text = teamInfo.id > 0 and "我的队伍" or "寻找队伍"
	self.view.bottom.teamBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--找队or我的队
		if teamInfo.id > 0 then
			if self.Data.notPush then
				DialogStack.PushPrefStact('TeamFrame',{idx = 1});
			else
				DialogStack.Push('TeamFrame',{idx = 1});
			end
		else
			local list = {}
			list[2] = {id = self.GroupId}
			if self.Data.notPush then
				DialogStack.PushPrefStact('TeamFrame',{idx = 2,viewDatas = list});
			else
				DialogStack.Push('TeamFrame',{idx = 2,viewDatas = list});
			end
		end
	end
	self.view.bottom.startBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--前往
		if SceneStack.GetBattleStatus() then
	        showDlgError(nil, "战斗内无法进行该操作")
	        return
	    end

	     local mapId = SceneStack.MapId();
		 if mapId == 601 then
			 showDlgMsg("现在退出场景将离开队伍", function ()
                module.TeamModule.KickTeamMember()--解散队伍
            end, function ()
            	end, "确定", "返回", nil, nil)
			return;
		end

		local teamInfo = module.TeamModule.GetTeamInfo()
		if teamInfo.id <= 0 then
			if module.playerModule.Get().level < data.limit_level then
				showDlgError(nil,"等级不足")
			else
				module.TeamModule.CreateTeam(self.GroupId,nil,data.limit_level,data.des_limit);--创建队伍

				--local team_battle_cfg = CemeteryConf.Getteam_battle_conf(self.GroupId)
				--NetworkService.Send(18184, {nil,team_battle_cfg.limit_level,team_battle_cfg.des_limit})
				--NetworkService.Send(18184, {nil,data.limit_level,data.des_limit})
			end
		else
			if module.playerModule.GetSelfID() == teamInfo.leader.pid then
				local index = 0
				local unqualified_name = {}
				for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
					index = index + 1
					if v.level < data.limit_level then
						unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
					end
				end
				if #module.TeamModule.GetTeamMembers() >= data.team_member then
					if #unqualified_name == 0 then
						if SceneStack.GetBattleStatus() then
							showDlgError(nil, "战斗内无法进行该操作")
						else
							if is_on then
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								if module.TeamModule.GetTeamInfo().auto_match then
									module.TeamModule.TeamMatching(true)
								end
								-- print(sprinttb(data))
								AssociatedLuaScript("guide/"..data.enter_script..".lua",data)
							else
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								if module.TeamModule.GetTeamInfo().auto_match then
									module.TeamModule.TeamMatching(true)
								end
								--ERROR_LOG(CemeteryModule.Getactivityid(),data.gid_id)
								if CemeteryModule.Getactivityid() == data.gid_id and (data.difficult == 1 or data.difficult == 2) then
									CemeteryModule.ContinuePve()
								else
									print("寻找npc",data.find_npc)
									utils.SGKTools.Map_Interact(data.find_npc)
								end
								DialogStack.CleanAllStack()
								--DispatchEvent("KEYDOWN_ESCAPE")
								DispatchEvent("TeamPveDetails_close")
							end
						end
					else
						for i =1 ,#unqualified_name do
							module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
						end
					end
				else
					showDlgError(nil,"队伍人数不足")
				end
			else
				showDlgError(nil,"只有队长可以带领队伍前往")
			end
		end
	end
	if self.open then
		self.view.bottom.startBtn.Text[UnityEngine.UI.Text].text = teamInfo.id <= 0 and "创建队伍" or "参加活动"
		if CemeteryModule.Getactivityid() == data.gid_id and (data.difficult == 1 or data.difficult == 2) then
			self.view.bottom.startBtn[CS.UGUISpriteSelector].index = 1
			self.view.bottom.startBtn.Text[UnityEngine.UI.Text].text = "继续前进"
		else
			self.view.bottom.startBtn[CS.UGUISpriteSelector].index = 0
		end
	end
end
function View:onEvent(event, data)
	if event == "TEAM_INFO_CHANGE" then
		self:LoadUI(self.teamBattleCfg,self.Data.is_on)
	end
end
function View:listEvent()
    return {
    "TEAM_INFO_CHANGE",
   }
end
return View