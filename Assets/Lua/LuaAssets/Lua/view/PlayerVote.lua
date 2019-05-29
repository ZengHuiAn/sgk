local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local Time = require "module.Time"
local ActivityTeamlist = require "config.activityConfig"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.mask[UnityEngine.UI.Button].interactable then
			self:Hide();
		end
	end
	self.view.ExitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.mask[UnityEngine.UI.Button].interactable then
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	self.view.NBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.NBtn[UnityEngine.UI.Button].interactable then
			if self.Data.oneselfVote then
				self.Data.oneselfVote(0)
			end
			self.view.mask[UnityEngine.UI.Button].interactable = true
		end
	end
	self.view.YBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.YBtn[UnityEngine.UI.Button].interactable then
			if self.Data.oneselfVote then
				self.Data.oneselfVote(1)
			end
			self.view.mask[UnityEngine.UI.Button].interactable = true
		end
	end
	self.voteList = {}--投票列表
	self.memberlist = data.list--成员列表
	self:RefUI()
	self.EndTime = data.EndTime
	self.type = data.type or 0
	self.timeCD = math.floor(data.EndTime - Time.now())
	self.view.mask[UnityEngine.UI.Button].interactable = false
	if self.Data.title then
		self.view.title[UI.Text].text = self.Data.title
	end
end
function View:check()
	for i = 1,#self.memberlist do
		if not self.voteList[self.memberlist[i]] then
			return false
		end
	end
	return true
end
function View:Show()
	local CanvasGroup = self.view[UnityEngine.CanvasGroup]
	CanvasGroup.alpha = 1;
	CanvasGroup.interactable = true;
	CanvasGroup.blocksRaycasts = true;
end

function View:Hide()
	local CanvasGroup = self.view[UnityEngine.CanvasGroup]
	CanvasGroup.alpha = 0;
	CanvasGroup.interactable = false;
	CanvasGroup.blocksRaycasts = false;
end

function View:Update()
	if self.gameObject and self.Data and self.view.time and self.timeCD then
		local time = math.floor(self.EndTime - Time.now())
		if time >= 0 then
			self.view.TimeProcess[UnityEngine.UI.Slider].value = time/self.timeCD
			self.view.time[UnityEngine.UI.Text].text = math.floor(self.EndTime - Time.now())
		else
			self.timeCD = nil
			self:verifyDesc()
			UnityEngine.GameObject.Destroy(self.gameObject)
			if self.Data.VoteFinish then
				self.Data.VoteFinish()
			end
		end
	end
end

function View:SetButtonEnable(btn, enable)
	btn[UnityEngine.UI.Button].interactable = enable
	btn[UnityEngine.UI.Image].color = UnityEngine.Color(1,1,1, enable and 1 or 0.5)
	btn.Text[UnityEngine.UI.Text].color = UnityEngine.Color(0,0,0, enable and 1 or 0.5)
end

function View:verifyDesc()
	--[=[
	local ys = ""
	local ns = ""
	local ot = ""
	for j = 1,#self.memberlist do
		local name = self.view.Grid[j].name[UnityEngine.UI.Text].text
		local desc = self.view.Grid[j].state[UnityEngine.UI.Text].text
		local is_ready = false
		local status = self.voteList[self.memberlist[j]]
		if status == 1 then
			if ys ~= "" then
				ys = ys.."、"
			end
			ys = ys..name
		elseif status == 0 then
			if ns ~= "" then
				ns = ns.."、"
			end
			ns = ns..name
		else
			if ot ~= "" then
				ot = ot.."、"
			end
			ot = ot..name
		end
	end

	local desc = ""
	if ys ~= "" then
		desc = "<color=#FEBA01>"..ys.."</color> 已确认"
	end
	if ns ~= "" then
		if desc ~= "" then
			desc = desc.."\n"
		end
		desc = desc.."<color=#FF410A>"..ns.."</color> 已拒绝"
	end
	if ot ~= "" then
		if desc ~= "" then
			desc = desc.."\n"
		end
		desc = desc.."<color=#23FFE3>"..ot.."</color> 未投票"
	end
	showDlgError(nil,desc)
	--]=]
end
function View:RefUI()
	for i = #self.memberlist + 1, 5 do
		self.view.Grid[i].gameObject:SetActive(false)
	end

	local ready_count = 0;
	--ERROR_LOG(sprinttb(self.memberlist))
	for j = 1,#self.memberlist do
		self.view.Grid[j].gameObject:SetActive(true)
		self.view.Grid[j].leader:SetActive(false)
		local PLayerIcon = nil
		if self.view.Grid[j].icon.transform.childCount == 0 then
			PLayerIcon = IconFrameHelper.Hero({},self.view.Grid[j].icon)
		else
			local objClone = self.view.Grid[j].icon.transform:GetChild(0)
			PLayerIcon = SGK.UIReference.Setup(objClone)
		end
		module.playerModule.Get(self.memberlist[j],function (data)
			self.view.Grid[j].name[UnityEngine.UI.Text].text = data.name
		end)
		PlayerInfoHelper.GetPlayerAddData(self.memberlist[j],99,function (addData)
            IconFrameHelper.UpdateHero({pid = self.memberlist[j],sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
		end)
		local status = self.voteList[ self.memberlist[j] ];
		if status == 1 then
			ready_count = ready_count + 1;
			self.view.Grid[j].state[CS.UGUISpriteSelector].index = 0;
			self.view.Grid[j].state:SetActive(true) -- [UnityEngine.UI.Text].text = "<color=#FEBA01>已确认</color>"
			self.view.Grid[j].Gray:SetActive(false)
			self.view.Grid[j].name[UnityEngine.UI.Text].color = UnityEngine.Color(0, 0, 0, 1);
		elseif status == 0 then
			-- self.view.Grid[j].state[UnityEngine.UI.Text].text = "<color=#FF410A>已拒绝</color>"
			self.view.Grid[j].state[CS.UGUISpriteSelector].index = 1;
			self.view.Grid[j].state:SetActive(true)
			self.view.Grid[j].Gray:SetActive(false)
			self.view.Grid[j].name[UnityEngine.UI.Text].color = UnityEngine.Color(0, 0, 0, 1);
		else
			-- self.view.Grid[j].state[UnityEngine.UI.Text].text = "<color=#23FFE3>待确认</color>"
			self.view.Grid[j].state:SetActive(false)
			self.view.Grid[j].Gray:SetActive(true)
			self.view.Grid[j].name[UnityEngine.UI.Text].color = UnityEngine.Color(0, 0, 0, 0.7);
		end

		if self.memberlist[j] == playerModule.GetSelfID() and ((status == 0) or (status == 1)) then
			self:SetButtonEnable(self.view.NBtn, false);
			self:SetButtonEnable(self.view.YBtn, false);
			self.view.mask[UnityEngine.UI.Button].interactable = true
		end
	end

	self.view.countDesc2[UnityEngine.UI.Text].text = string.format("%d/%d", ready_count, #self.memberlist);
end

function View:ChangeStatus(pid, status)
	if self.voteList[pid] ~= status then
		self.voteList[pid] = status;
		playerModule.Get(pid, function(player)
			if status == 1 then
				showDlgError(nil, "<color=#FEBA01>" .. player.name .. "已确认</color>");
			elseif status == 0 then
				showDlgError(nil, "<color=#FF410A>" .. player.name .. "已拒绝</color>");
			end
		end)
		if self:check() and self.type == 0 then --检查所有玩家是否投票完成
			DispatchEvent("PlayerVoteFinish");
		end
	end
end

function View:onEvent(event,data) 
	if event == "PlayerVoteRef" then
		for i = 1,#data do
			local pid, status = data[i][1], data[i][2];
			self:ChangeStatus(pid, status)
		end
		self:RefUI()
	elseif event == "PlayerVoteFinish" then
		self.timeCD = nil
		self:verifyDesc()
		self.view.transform:DOScale(Vector3(1,1,1),0):SetDelay(1):OnComplete(function( ... )
			UnityEngine.GameObject.Destroy(self.gameObject)
		end)
	elseif event == "PlayerVoteShow" then
		self:Show()
	end
end

function View:listEvent()
    return {
    "PlayerVoteRef",
	"PlayerVoteFinish",
	"PlayerVoteShow",
}
end
return View
