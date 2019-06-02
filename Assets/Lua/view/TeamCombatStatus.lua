local ChatManager = require 'module.ChatModule'
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.HeroStatusColor = {
		{r=101/255,g=1,b=185/255,a=1},          --绿色：已行动
		{r=253/255,g=73/255,b=72/255,a=1},      --红色：（死亡）
		{r=85/255,g=210/255,b=1,a=1},           --蓝色：未行动
		{r=0,g=0,b=0,a=1},                      --黑色：未上阵
		[10] = {r=1,g=233/255,b=140/255,a=1}    --黄色：行动中
	}
	self.PlayerIDview = {}
	self.Player_Accumulative_Harm = {}
	self.Team_Accumulative_Harm = 0
	self.TeamChatEmoji = nil
	self:loadTeam()
end
function View:deActive(deActive)
	self.TeamChatEmoji = DialogStack.GetPref_list(self.TeamChatEmoji)
	if self.TeamChatEmoji ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.TeamChatEmoji);
	end
	return true
end
function View:loadTeam( ... )
	self.PlayerIDview = {}
	local teamInfo = module.TeamModule.GetTeamInfo();
	local members = module.TeamModule.GetTeamMembers()
	if teamInfo.group == 0 then
		self.view.Group:SetActive(false);
		return
	end

	self.view.Group:SetActive(true);

	for i = 1,5 do
		--self.view.Group[i].lv[UnityEngine.UI.Text].text = ""
		self.view.Group[i]:SetActive(false)
		self.view.Group[i].icon[UI.Image].enabled = false
	end
	local index = 0
	self.view.select:SetActive(false)
	for k,v in ipairs(members) do
		index = index + 1
		print(v.pos.."v->"..sprinttb(v))
		self.PlayerIDview[v.pid] = self.view.Group[index]
		self.view.Group[index][CS.UGUIClickEventListener].onClick = function ( ... )
			self.view.select.transform:SetParent(self.view.Group[index].icon.transform,false)
			self.view.select[UnityEngine.RectTransform].localPosition = Vector3.zero
			if self.TeamChatEmoji == nil then
				self.TeamChatEmoji = "TeamChatEmoji"
				DialogStack.PushPref("TeamChatEmoji",{player = v,idx = v.pos})
			else
				self.TeamChatEmoji = DialogStack.GetPref_list(self.TeamChatEmoji)
				if self.TeamChatEmoji then
					self.TeamChatEmoji:SetActive(true)
				end
				DispatchEvent("TeamChatEmoji_CHANGE",{player = v,idx = v.pos})
			end
		end
		local _name = self:utf8sub(5, v.name)
		if _name ~= v.name then
			self.view.Group[index].icon.name[UnityEngine.UI.Text].text = _name.."..."
		else
			self.view.Group[index].icon.name[UnityEngine.UI.Text].text = v.name
		end
		self.view.Group[index].icon.num[UnityEngine.UI.Text].text = "0%"
		local PLayerIcon = nil
		if self.view.Group[index].icon.pos.transform.childCount == 0 then
			PLayerIcon = IconFrameHelper.Hero({}, self.view.Group[index].icon.pos,nil,0.55)
		else
			local objClone = self.view.Group[index].icon.pos.transform:GetChild(0)
			PLayerIcon = SGK.UIReference.Setup(objClone)
		end
		
		PlayerInfoHelper.GetPlayerAddData(v.pid,99,function (addData)
			--self.view.Group[index].icon.Sex[CS.UGUISpriteSelector].index = addData.Sex
			IconFrameHelper.UpdateHero({pid = v.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
		end)
		--for i = 1,#v.heros do
		for i = 1,5 do
			self.view.Group[index].StatusGroup[i][UnityEngine.UI.Image].color = self.HeroStatusColor[4]
		end
		for i = 1,#v.heros do
			--ERROR_LOG(sprinttb(v.heros[i]))
			self.view.Group[index].StatusGroup[v.heros[i].pos][UnityEngine.UI.Image].color = self.HeroStatusColor[3]
		end
		self.view.Group[index]:SetActive(true)
	end
end
function View:onEvent(event,data)
	if event == "Chat_INFO_CHANGE" then
		--聊天
		if data.channel == 7 then
			self.ChatData = ChatManager.GetChatDataTeam()
			local teamInfo = module.TeamModule.GetTeamInfo();
			local members = module.TeamModule.GetTeamMembers()
			if teamInfo.group == 0 then
				return
			end
			local index = 0
			for k,v in ipairs(members) do
				index = index + 1
				if v.pid == self.ChatData[#self.ChatData].fromid then
					self.view.Group[index].chat:SetActive(false)
					self.view.Group[index].chat:SetActive(true)
					local WordFilter = WordFilter.check(self.ChatData[#self.ChatData].message)--屏蔽字
					self.view.Group[index].chat.desc[UnityEngine.UI.Text].text = WordFilter
					self.view.Group[index].chat[UnityEngine.CanvasGroup]:DOFade(1,0.5):OnComplete(function()
              			self.view.Group[index].chat[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
          					
           				end):SetDelay(1)
           			end)
					break
				end
			end
		end
	elseif event == "Team_Emoji_receive" then
		self.PlayerIDview[data[1]].emoji[UnityEngine.UI.Image]:LoadSprite("Emoji/"..data[2])
		self.PlayerIDview[data[1]].emoji[UnityEngine.UI.Image]:DOFade(1,0.5):OnComplete(function ( ... )
			self.PlayerIDview[data[1]].emoji[UnityEngine.UI.Image]:DOFade(0,0.5):OnComplete(function ( ... )
			end):SetDelay(1)
		end)
	elseif event == "Player_Accumulative_Harm" then
		--print("<color=red>harm</color>", data.pid, data.value)
		if not self.Player_Accumulative_Harm[data.pid] then
			self.Player_Accumulative_Harm[data.pid] = 0
		end
		self.Player_Accumulative_Harm[data.pid] = self.Player_Accumulative_Harm[data.pid] + data.value
		self.Team_Accumulative_Harm = self.Team_Accumulative_Harm + data.value
		for k,v in pairs(self.Player_Accumulative_Harm)do
			self.PlayerIDview[k].icon.num[UnityEngine.UI.Text].text = math.floor((self.Player_Accumulative_Harm[k]/self.Team_Accumulative_Harm)*100).."%"
		end
	elseif event == "Player_Hero_Status_Change" then
		-- ERROR_LOG("<color=red>Player_Hero_Status_Change</color>", data.pid, data.value, data.target);
		if not self.PlayerIDview[data.pid] then
			return;
		end
		-- target 0  玩家  其他  对应位置的角色
		-- value  0 不存在或者未准备好 1 已准备好  2 已死亡   默认显示 0 的状态    10 开始输入 11 等待boss
		if data.target ~= 0 and data.pid ~= 0 then
			if data.value == 10 then
				print(data.target, self.PlayerIDview[data.pid], self.HeroStatusColor[10])
				self.PlayerIDview[data.pid].StatusGroup[data.target][UnityEngine.UI.Image].color = self.HeroStatusColor[10]
			elseif data.value == 11 then
				print(data.target, self.PlayerIDview[data.pid], self.HeroStatusColor[1])
				self.PlayerIDview[data.pid].StatusGroup[data.target][UnityEngine.UI.Image].color = self.HeroStatusColor[1]
			else
				self.PlayerIDview[data.pid].StatusGroup[data.target][UnityEngine.UI.Image].color = self.HeroStatusColor[data.value == 2 and 2 or 3]
				rawset(self.PlayerIDview[data.pid].StatusGroup[data.target], "origin_status", data.value);
			end
		elseif data.pid ~= 0 then
			if data.value == 10 then     -- 输入中
				self.PlayerIDview[data.pid].statusIcon:SetActive(true)
				self.PlayerIDview[data.pid].statusIcon[CS.UGUISpriteSelector].index = 1;
				for i = 1, 5 do
					local os = rawget(self.PlayerIDview[data.pid].StatusGroup[i], "origin_status");
					if os then
						self.PlayerIDview[data.pid].StatusGroup[i][UnityEngine.UI.Image].color = self.HeroStatusColor[os == 2 and 2 or 3]
					end
				end
			elseif data.value == 11 then -- 等待boss
				self.PlayerIDview[data.pid].statusIcon:SetActive(false)
			elseif data.value == 0 then
				self.PlayerIDview[data.pid].readyIcon:SetActive(true)
				self.PlayerIDview[data.pid].readyIcon[CS.UGUISpriteSelector].index = 1;
			elseif data.value == 1 then
				self.PlayerIDview[data.pid].readyIcon:SetActive(false)
			else
				self.PlayerIDview[data.pid].statusIcon:SetActive(false)
			end
		end
	elseif event == "TeamChatEmoji_Destroy" then
		self.TeamChatEmoji = nil
	elseif event == "TeamCombatFinish" then
		if self.TeamChatEmoji ~= nil then
			self.TeamChatEmoji = DialogStack.GetPref_list(self.TeamChatEmoji)
			if self.TeamChatEmoji then
				CS.UnityEngine.GameObject.Destroy(self.TeamChatEmoji);
			end
			self.TeamChatEmoji = nil
		end
	end
end
function View:listEvent()
	return {
	"Chat_INFO_CHANGE",
	"Team_Emoji_receive",
	"Player_Accumulative_Harm",
	"Player_Hero_Status_Change",
	"TeamChatEmoji_Destroy",
	"TeamCombatFinish",
	}
end
function View:utf8sub(size, input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + 1
        end
        if (cnt + _count) >= size then
            return string.sub(input, 1, cnt + _count)
        end
    end
    return input;
end
return View