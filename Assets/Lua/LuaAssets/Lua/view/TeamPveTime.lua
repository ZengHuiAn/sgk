local CemeteryConf = require "config.cemeteryConfig"
local CemeteryModule = require "module.CemeteryModule"
local playerModule = require "module.playerModule"
local TeamModule = require "module.TeamModule"
local Time = require "module.Time"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	local activityid = CemeteryModule.Getactivityid()
	local cfg = CemeteryConf.Getteam_battle_conf(activityid)
	self.name = cfg.tittle_name
	self.start_time = 0
	self.end_time = 0
	if TeamModule.GetTeamPveTime(activityid) then
		self.start_time = TeamModule.GetTeamPveTime(activityid).start_time or 0
		self.end_time = TeamModule.GetTeamPveTime(activityid).end_time or 0
	else
		TeamModule.QUERY_BATTLE_TIME_REQUEST(activityid)
	end
	self.start_transfer = false
	self.view.bg.Btn[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Push("TeamPveEntrance", {gid = activityid,GroupId = activityid})
	end
end
function View:transfer()
	local teamInfo = module.TeamModule.GetTeamInfo();
	if not self.start_transfer and teamInfo.id > 0 and teamInfo.leader.pid == playerModule.GetSelfID() and self.start_time > 0 then
		self.start_transfer = true
		DlgMsg({msg = "挑战超时，5秒后将被移除副本.",confirm = function()
			local activityid = CemeteryModule.Getactivityid()
			local uuid = module.CemeteryModule.GetTEAM_PveStateUid(activityid)
			if uuid then
            	module.QuestModule.Cancel(uuid)
	            module.QuestModule.SetOldUuid(nil)
	        end
			SceneStack.EnterMap(10)
		end,time = 5,NotExit = true})
	end
end
function View:Update()
	if self.start_time and self.end_time then
		local time =  math.floor(self.end_time - Time.now())
		if time > 0 then
			self.view.bg.desc[UI.Text].text = self.name.."\n"..string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
		else
			self.view.bg.desc[UI.Text].text = self.name.."\n00:00:00"
			self:transfer()
		end
	end
end
function View:onEvent(event, data)
	if event == "QUERY_BATTLE_TIME_REQUEST" then
		local activityid = CemeteryModule.Getactivityid()
		if TeamModule.GetTeamPveTime(activityid) then
			self.start_time = TeamModule.GetTeamPveTime(activityid).start_time or 0
			self.end_time = TeamModule.GetTeamPveTime(activityid).end_time or 0
		else
			TeamModule.QUERY_BATTLE_TIME_REQUEST(activityid)
		end
	end
end
function View:OnDestroy( ... )
	DialogStack.Destroy("TeamPveTime")
end
function View:listEvent()
    return {
    "QUERY_BATTLE_TIME_REQUEST",
    }
end
return View