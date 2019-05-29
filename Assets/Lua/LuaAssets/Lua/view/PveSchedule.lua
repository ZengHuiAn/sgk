local CemeteryModule = require "module.CemeteryModule"
local MapConfig = require "config.MapConfig"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.IsShow = false
	self.descArr = {}
	self.view.bg.desc.open[CS.UGUIClickEventListener].onClick = function ( ... )
		self.IsShow = not self.IsShow
		self.view.bg.desc.open.transform.localEulerAngles = self.IsShow and Vector3(0,0,180) or Vector3.zero
		self:ShowDesc(self.descArr)
	end
	self:RefUI()
end
function View:RefUI()
	local descArr = {}
	local activityid = CemeteryModule.Getactivityid()
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(activityid).idx) do
		for i = 1,#v do
			if CemeteryModule.GetTEAMRecord(v[i].gid) > 0 then
				local conf = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid)
				if not descArr[conf.sequence] then
					descArr[conf.sequence] = {}
				end
				descArr[conf.sequence][#descArr[conf.sequence]+1] = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid)
			end
		end
	end
	self:ShowDesc(descArr)
	self.descArr = descArr
end
function View:ShowDesc(descArr)
	local desc = ""
	local Count = 0
	for i = 1,#descArr do
		for j = 1,#descArr[i] do
			if Count == 2 and self.IsShow == false then
				break
			end
			if desc == "" then
				desc = descArr[i][j].win_des
			else
				desc = desc.."\n"..descArr[i][j].win_des
			end
			Count = Count + 1
		end
	end
	self.view.bg:SetActive(desc ~= "")
	self.view.bg.desc[UnityEngine.UI.Text].text = desc
end
function View:onEvent(event, data)
	if event == "update_monster_schedule" then
		self:RefUI()
	end
end
function View:OnDestroy( ... )
	DialogStack.Destroy("PveSchedule")
end
function View:listEvent()
	return{
	"update_monster_schedule",
	}
end
return View