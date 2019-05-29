local View = {}
local ItemHelper = require "utils.ItemHelper"
local Time = require "module.Time"
local mazeModule = require "module.mazeModule"


local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time

    if not time or time < 0 then
    	return 0,0,0;
    end
    return H,M,S
end


function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);

	self.this_startTime , self.end_time  = mazeModule.GetTime();
	self.group = self.view.bg.view.bg.main.bg.group;

	CS.UGUIClickEventListener.Get(self.view.bg.view.bg.btn.exit.gameObject,true).onClick = function (obj)
		module.TeamModule.KickTeamMember()--解散队伍
		SceneStack.EnterMap(10);
	end

	CS.UGUIClickEventListener.Get(self.view.bg.view.bg.btn.fog.gameObject,true).onClick = function (obj)
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.mask[UI.Button].onClick:AddListener(function ()
		UnityEngine.GameObject.Destroy(self.gameObject)
	end);
	
	self:UpdateMazeCount();
	self:UpdateMonsterCount();
end

function View:UpdateMonsterCount(count)
	self.group.monster.num[UI.Text].text = tostring(count or (mazeModule.GetNpcCount() or 0));
end

function View:UpdateMazeCount(count)
	self.group.maze.num[UI.Text].text = tostring(count or mazeModule.GetMazeCount());
end

function View:UpdateTime(time)
	local H,M,S = getTimeHMS(time);
	self.group.time.deltatime[UI.Text].text = string.format("%02d:%02d",M,S);
end


function View:Update()
	

	if self.end_time then

		local thisTime = Time.now();

		local ret = self.end_time - thisTime;

		if ret >=0 then
			self:UpdateTime(ret);
		else
			DialogStack.Pop();
		end


	end
end





return View;