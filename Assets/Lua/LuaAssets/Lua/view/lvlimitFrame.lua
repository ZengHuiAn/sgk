local NetworkService = require "utils.NetworkService"
local TeamModule = require "module.TeamModule"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.min = 1
	self.max = 80
	self.lv = {1,80}

	self:Init(data)
	
	self.view.Leftmask.ScrollView[CS.newScrollText].RefreshCallback = (function (idx)
		idx = idx + self.min
		self.lv[1] = idx > self.max and self.max or idx
		if self.lv[2] < self.lv[1] then--and self.lv[2] > 0 then
			self.lv[2] = self.lv[1]
			self.view.Rightmask.ScrollView[CS.newScrollText]:MovePosition(self.max - self.lv[1])
		end
	end)
	self.view.Rightmask.ScrollView[CS.newScrollText].RefreshCallback = (function (idx)
		idx = idx + self.min
		self.lv[2] = idx > self.max and self.max or idx
		if self.lv[1] > self.lv[2] then
			self.lv[1] = self.lv[2]
			self.view.Leftmask.ScrollView[CS.newScrollText]:MovePosition(self.lv[1])
		end
	end)
	-- self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	NetworkService.Send(18184, {nil,self.lv[1],self.lv[2]})
	-- 	DispatchEvent("KEYDOWN_ESCAPE")
	-- end
	-- local teamInfo = TeamModule.GetTeamInfo();
	-- self.view.Leftmask.ScrollView[CS.newScrollText]:MovePosition(teamInfo.lower_limit-1)
	-- self.lv[1] = teamInfo.lower_limit
	-- self.view.Rightmask.ScrollView[CS.newScrollText]:MovePosition(teamInfo.upper_limit-1)
	-- self.lv[2] = teamInfo.upper_limit
end
function View:onEvent(event, data)
	if event == "LvLimitChange" then
		data.team_lower = data.lower_limit
		data.team_upper = data.upper_limit
		self:Init(data)
	end
end
function View:Init(data)
	self.min = data.lower_limit
	self.max = data.upper_limit
	self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text = ""
	self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text = ""
	for i = self.min,self.max do
		if i < self.max then
			self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text..i.."\n"
			self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text..i.."\n"
		else
			self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text..i
			self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text..i
		end
	end
	UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.Rightmask.ScrollView.Viewport.Content[UnityEngine.RectTransform])
	local y = self.view.Rightmask.ScrollView.Viewport.Content.desc[UnityEngine.RectTransform].sizeDelta.y
	local height = y / (self.max - self.min + 1)
	self.view.Leftmask.ScrollView[CS.newScrollText].height = height
	self.view.Rightmask.ScrollView[CS.newScrollText].height = height
	self.view.Leftmask.ScrollView[CS.newScrollText]:MovePosition(data.team_lower-self.min)
	self.lv[1] = data.team_lower
	self.view.Rightmask.ScrollView[CS.newScrollText]:MovePosition(data.team_upper-self.min)
	self.lv[2] = data.team_upper
end
function View:listEvent()
	return{
	"LvLimitChange",
	}
end

function View:Close()
	NetworkService.Send(18184, {nil,self.lv[1],self.lv[2]})
end

return View