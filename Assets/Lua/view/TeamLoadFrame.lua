local TeamModule = require "module.TeamModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	self.Teamview = {}
	self.TeamSlidingArea = {}

	for i = 1,5 do
		self.view.Root[i]:SetActive(false)
	end
	for i = 1,#self.Data.members do
		--ERROR_LOG(teamInfo.members[i].pid)
		self.view.Root[i]:SetActive(true)
		self.view.Root[i].name[UI.Text].text = self.Data.members[i].name
		-- self.view.Root[i].leader:SetActive(teamInfo.leader.pid == self.Data.members[i].pid)
		self.Teamview[self.Data.members[i].pid] = self.view.Root[i]

		utils.IconFrameHelper.Create(self.view.Root[i].pos.IconFrame, {pid = self.Data.members[i].pid});
		self.view.Root[i].SlidingArea:SetActive(data and data.scrollView)
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--CS.UnityEngine.GameObject.Destroy(self.gameObject)
		--DispatchEvent("TeamLoadSlidingArea",{pid = 463856567974,SlidingArea = 100})
	end
end
function View:Scrollbar(pid,SlidingArea)
	self.TeamSlidingArea[pid] = SlidingArea
	if SlidingArea == 100 then
		self.Teamview[pid].status[CS.UGUISpriteSelector].index = 1;
	else
		self.Teamview[pid].status[CS.UGUISpriteSelector].index = 0;
	end
	self.Teamview[pid].status[UI.Image]:SetNativeSize();
	local accomplish = 0
	for k,v in pairs(self.TeamSlidingArea) do
		if v == 100 then
			accomplish = accomplish + 1
		end
	end
	if accomplish == #self.Data.members then
		SGK.Action.DelayTime.Create(0.5):OnComplete(function()
			CS.UnityEngine.GameObject.Destroy(self.gameObject)
		end)
	end
end
function View:onEvent(event, data)
	if event == "TeamLoadSlidingArea" then
		local pid = data.pid
		local SlidingArea = data.SlidingArea
		if self.Teamview[pid] and SlidingArea >= 0 and SlidingArea <= 100 then
			if self.Data and self.Data.scrollView then
				self.Teamview[pid].SlidingArea.Scrollbar[UnityEngine.UI.Image]:DOFillAmount(SlidingArea/100,1):OnComplete(function ( ... )
					self:Scrollbar(pid,SlidingArea)
				end)
			else
				self:Scrollbar(pid,SlidingArea)
			end
		end
	elseif event == "TeamLoadFinished" then
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end
end
function View:listEvent()
    return {
		"TeamLoadFinished",
    	"TeamLoadSlidingArea",
    }
end
return View