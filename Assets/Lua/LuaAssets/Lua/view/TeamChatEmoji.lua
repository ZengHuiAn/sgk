local ChatManager = require 'module.ChatModule'
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	self.HeroStatusDesc = {
		"<color=#65FEBB>已行动</color>",          --绿色：已行动
		"<color=#FF494D>已死亡</color>",          --红色：（死亡）
		"<color=#4FB6E1>未行动</color>",          --蓝色：未行动
		"<color=#000000>未上阵</color>",          --黑色：未上阵
		[10] = "<color=#FFE88B>行动中</color>"    --黄色：行动中
	}
	self.HeroStatusColor = {
		{r=101/255,g=1,b=185/255,a=1},          --绿色：已行动
		{r=253/255,g=73/255,b=72/255,a=1},      --红色：（死亡）
		{r=85/255,g=210/255,b=1,a=1},           --蓝色：未行动
		{r=0,g=0,b=0,a=1},                      --黑色：未上阵
		[10] = {r=1,g=233/255,b=140/255,a=1}    --黄色：行动中
	}
	self.Player_Accumulative_Harm = {}
	self.Team_Accumulative_Harm = 0
	self.IsFix = false
	self.HeroData = {}
	for i = 1,8 do
		self.view.bg.Group[i].desc[UnityEngine.UI.Text].text = ChatManager.TeamChatKeywordList()[i]
		if GetUtf8Len(ChatManager.TeamChatKeywordList()[i]) >= 6 then
			self.view.bg.Group[i].desc.gameObject.transform.localPosition = Vector3(-12,0,0)
			self.view.bg.Group[i].label:SetActive(true)
		else
			self.view.bg.Group[i].desc.gameObject.transform.localPosition = Vector3.zero
			self.view.bg.Group[i].label:SetActive(false)
		end
		self.view.bg.Group[i].close[CS.UGUIClickEventListener].onClick = function ( ... )
			ChatManager.TeamChatKeywordList(i,"")
		end
		if i > 1 and i < 8 then
			self.view.bg.Group[i].bg2:SetActive(ChatManager.TeamChatKeywordList()[i] ~= "")
		end
		self.view.bg.Group[i][CS.UGUIClickEventListener].onClick = function ( ... )
			if i == 1 then
				if not self.IsFix then
					local _type = self.view.choose.activeSelf and 1 or 0
					local teamInfo = module.TeamModule.GetTeamInfo();
					if self.view.choose.activeSelf then
						if module.playerModule.Get().id == teamInfo.leader.pid then
							module.TeamModule.ChatToTeam(self.view.bg.Group[i].desc[UnityEngine.UI.Text].text, 1) 
							self.view.tips[UnityEngine.UI.Text].text = "使用强力提醒"
	 						self.view.choose:SetActive(false)
	 					else
	 						showDlgError(nil,"只有队长可以使用")
	 					end
					else
						module.TeamModule.ChatToTeam("对"..self.Data.player.name..":"..self.view.bg.Group[i].desc[UnityEngine.UI.Text].text, 0);
					end
					self.view:SetActive(false)
				end
			elseif i == 8 then
				self.IsFix = not self.IsFix
				self.view.bg.Group[1].mask:SetActive(self.IsFix)
				self.view.bg.Group[8].bg2:SetActive(self.IsFix)
				for j = 2 , 7 do
					--ERROR_LOG(j..tostring(ChatManager.TeamChatKeywordList()[j] ~= ""))
					self.view.bg.Group[j].close:SetActive(ChatManager.TeamChatKeywordList()[j] ~= "" and self.IsFix)
				end
			else
				if self.IsFix then
					--填写修改关键词
					self.view.FixTips:SetActive(true)
					self.view.FixTips.ybtn[CS.UGUIClickEventListener].onClick = function ( ... )
						local input = self.view.FixTips.InputField[UnityEngine.UI.InputField]
						if input.text ~= "" then
							ChatManager.TeamChatKeywordList(i,input.text)
							input.text = ""
						else
							showDlgError(nil,"输入内容不能为空")
						end
					end
				else
					if self.view.bg.Group[i].bg1.activeSelf or self.view.bg.Group[i].bg2.activeSelf then
						local teamInfo = module.TeamModule.GetTeamInfo();
						if self.view.choose.activeSelf then
							if module.playerModule.Get().id == teamInfo.leader.pid then
								module.TeamModule.ChatToTeam(self.view.bg.Group[i].desc[UnityEngine.UI.Text].text, 1);
								self.view.tips[UnityEngine.UI.Text].text = "使用强力提醒"
	 							self.view.choose:SetActive(false)
 							else
		 						showDlgError(nil,"只有队长可以使用")
		 					end
						else
							module.TeamModule.ChatToTeam("对"..self.Data.player.name..":"..ChatManager.TeamChatKeywordList()[i], 0);
						end
						self.view:SetActive(false)
					end
				end
			end
		end
	end
	self.view.FixTips.nbtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.FixTips:SetActive(false)
	end
	self.view.Emoji[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(true)
 	end
 	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(false)
 	end
 	 self.view.maskbg[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view:SetActive(false)
 	end
 	for i =1,#self.view.mask.bg do
 		self.view.mask.bg[i][CS.UGUIClickEventListener].onClick = function ( ... )
 			self.view.mask:SetActive(false)
 			module.TeamModule.SyncTeamData(106,{module.playerModule.GetSelfID(),i})
 			self.view:SetActive(false)
 		end
 	end
 	self.view.up[CS.UGUIClickEventListener].onClick = function ( ... )
 		if self.Data.idx == 1 then
 			self.Data.idx = #self.HeroData
 		else
 			self.Data.idx = self.Data.idx - 1
 		end
 		self.Data.player = self.HeroData[self.Data.idx]
 		self:loadTeam(self.Data.idx)
 	end
 	self.view.down[CS.UGUIClickEventListener].onClick = function ( ... )
 		if self.Data.idx == #self.HeroData then
 			self.Data.idx = 1
 		else
 			self.Data.idx = self.Data.idx + 1
 		end
 		self.Data.player = self.HeroData[self.Data.idx]
 		self:loadTeam(self.Data.idx)
 	end
 	self.view.StronglySuggest[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.tips[UnityEngine.UI.Text].text = self.view.choose.activeSelf and "使用强力提醒" or "勾选强力提醒"
 		self.view.choose:SetActive(not self.view.choose.activeSelf)
 	end
 	self:loadTeam(data.idx)
end
function View:loadTeam(idx)
	self.Playerview = nil
	local teamInfo = module.TeamModule.GetTeamInfo();
	local members = module.TeamModule.GetTeamMembers()
	if teamInfo.group == 0 then
		return
	end
	if self.Team_Accumulative_Harm == 0 then
		self.view.harm[UnityEngine.UI.Text].text = "总伤害:<color=#FFDC40>"..self.Team_Accumulative_Harm.."</color> <color=#00FFBD>(0%)</color>"
	elseif not self.Player_Accumulative_Harm[self.Data.player.pid] or self.Player_Accumulative_Harm[self.Data.player.pid] == 0 then
		self.view.harm[UnityEngine.UI.Text].text = "总伤害:<color=#FFDC40>"..self.Team_Accumulative_Harm.."</color> <color=#00FFBD>(0%)</color>"
	else
		self.view.harm[UnityEngine.UI.Text].text = "总伤害:<color=#FFDC40>"..self.Team_Accumulative_Harm.."</color> <color=#00FFBD>("..((self.Player_Accumulative_Harm[self.Data.player.pid]/self.Team_Accumulative_Harm)*100).."%)</color>"
	end
	self.view.time[UnityEngine.UI.Text].text = ""
	if idx <= 5 then
		for i = 1,5 do
			self.view.TeamGroup[i]:SetActive(false)
			self.view.labels[i][UnityEngine.UI.Text].color = {r= 115/255,g= 115/255,b= 115/255,a=1}
		end
		self.view.labels[idx][UnityEngine.UI.Text].color = {r= 1,g= 189/255,b= 56/255,a=1}
		local index = 0
		for k,v in ipairs(members) do
			index = index + 1
			self.HeroData[index] = v
			if index == idx then
				--print(v.pos.."v->"..sprinttb(v))
				self.Playerview = self.view.TeamGroup[index]
				self.view.Hero.name[UnityEngine.UI.Text].text = v.name
				self.view.Hero.lv[UnityEngine.UI.Text].text = "Lv"..v.level
				local PLayerIcon = nil
				if self.view.Hero.icon.transform.childCount == 0 then
					PLayerIcon = IconFrameHelper.Hero({},self.view.Hero.icon,nil,0.8)
				else
					local objClone = self.view.Hero.icon.transform:GetChild(0)
					PLayerIcon = SGK.UIReference.Setup(objClone)
				end
				PlayerInfoHelper.GetPlayerAddData(v.pid,99,function (addData)
					IconFrameHelper.UpdateHero({pid = v.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
				end)				
				--for i = 1,#v.heros do
				for i = 1,5 do
					self.view.Hero.StatusGroup[i][UnityEngine.UI.Image].color = self.HeroStatusColor[4]
				end
				for i = 1,#v.heros do
					--ERROR_LOG(sprinttb(v.heros[i]))
					self.view.Hero.StatusGroup[v.heros[i].pos][UnityEngine.UI.Image].color = self.HeroStatusColor[3]
					self.view.TeamGroup[v.heros[i].pos]:SetActive(true)
					self.view.TeamGroup[v.heros[i].pos].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. v.heros[i].id)
					self.view.TeamGroup[v.heros[i].pos].lv[UnityEngine.UI.Text].text = "Lv"..v.heros[i].level
					self.view.TeamGroup[v.heros[i].pos].status[UnityEngine.UI.Text].text = self.HeroStatusDesc[3]
				end
				self.view.Hero:SetActive(true)
			end
		end
	else

	end
end
function View:onEvent(event,data)
	if event == "Chat_TeamChatKeyword_CHANGE" then
		--小队聊天关键字
		self.view.FixTips:SetActive(false)
		for i = 2,7 do
			self.view.bg.Group[i].desc[UnityEngine.UI.Text].text = ChatManager.TeamChatKeywordList()[i]
			if GetUtf8Len(ChatManager.TeamChatKeywordList()[i]) >= 6 then
				self.view.bg.Group[i].desc.gameObject.transform.localPosition = Vector3(-12,0,0)
				self.view.bg.Group[i].label:SetActive(true)
			else
				self.view.bg.Group[i].desc.gameObject.transform.localPosition = Vector3.zero
				self.view.bg.Group[i].label:SetActive(false)
			end
			self.view.bg.Group[i].bg2:SetActive(ChatManager.TeamChatKeywordList()[i] ~= "")
			self.view.bg.Group[i].close:SetActive(ChatManager.TeamChatKeywordList()[i] ~= "")
		end
	elseif event == "Player_Accumulative_Harm" then
		--print("<color=red>harm</color>", data.pid, data.value)
		if not self.Player_Accumulative_Harm[data.pid] then
			self.Player_Accumulative_Harm[data.pid] = 0
		end
		self.Player_Accumulative_Harm[data.pid] = self.Player_Accumulative_Harm[data.pid] + data.value
		self.Team_Accumulative_Harm = self.Team_Accumulative_Harm + data.value
		self.view.harm[UnityEngine.UI.Text].text = "总伤害:<color=#FFDC40>"..self.Team_Accumulative_Harm.."</color> <color=#00FFBD>("..((self.Player_Accumulative_Harm[data.pid]/self.Team_Accumulative_Harm)*100).."%)</color>"
	elseif event == "Player_Hero_Status_Change" then
		--ERROR_LOG("<color=red>Player_Hero_Status_Change</color>", data.pid, data.value, data.target);
		-- target 0  玩家  其他  对应位置的角色
		-- value  0 不存在或者未准备好 1 已准备好  2 已死亡   默认显示 0 的状态    10 开始输入 11 等待boss
		if data.target ~= 0 and data.pid ~= 0 then
			if data.value == 10 then
				--print(data.target, self.PlayerIDview[data.pid], self.HeroStatusColor[10])
				self.view.Hero.StatusGroup[data.target][UnityEngine.UI.Image].color = self.HeroStatusColor[10]
				self.view.TeamGroup[data.target].status[UnityEngine.UI.Text].text = self.HeroStatusDesc[10]
			elseif data.value == 11 then
				--print(data.target, self.PlayerIDview[data.pid], self.HeroStatusColor[1])
				self.view.Hero.StatusGroup[data.target][UnityEngine.UI.Image].color = self.HeroStatusColor[1]
				self.view.TeamGroup[data.target].status[UnityEngine.UI.Text].text = self.HeroStatusDesc[1]
			else
				self.view.Hero.StatusGroup[data.target][UnityEngine.UI.Image].color = self.HeroStatusColor[data.value == 2 and 2 or 3]
				self.view.TeamGroup[data.target].status[UnityEngine.UI.Text].text =	self.HeroStatusDesc[data.value == 2 and 2 or 3]
				rawset(self.view.Hero.StatusGroup[data.target], "origin_status", data.value);
			end
		elseif data.pid ~= 0 then
			if data.value == 10 then     -- 输入中
				for i = 1, 5 do
					local os = rawget(self.view.Hero.StatusGroup[i], "origin_status");
					if os then
						self.view.Hero.StatusGroup[i][UnityEngine.UI.Image].color = self.HeroStatusColor[os == 2 and 2 or 3]
					end
				end
			end
		end
	elseif event == "TeamChatEmoji_CHANGE" then
		self.Data = data
		self:loadTeam(self.Data.idx)
	end
end
function View:listEvent()
	return {
	"Chat_TeamChatKeyword_CHANGE",
	"Player_Hero_Status_Change",
	"Player_Accumulative_Harm",
	"TeamChatEmoji_CHANGE",
	}
end
return View