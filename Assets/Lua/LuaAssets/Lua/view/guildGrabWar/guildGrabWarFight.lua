local playerModule = require "module.playerModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.data = data;
	self:InitView();
end

function View:InitView()
	local side1 = playerModule.GetSelfID();
	local side2 = self.data.attacker_pid == side1 and self.data.defender_pid or self.data.attacker_pid;
	module.playerModule.Get(side1, function (player)
		self.view.side1.name[UI.Text].text = player.name;
		utils.IconFrameHelper.Create(self.view.side1.IconFrame, {pid = player.id});
		module.playerModule.GetFightData(side1, false, function ()
			self.view.side1.rotateNum[SGK.RotateNumber]:Change(0, math.ceil(module.playerModule.GetFightData(side1).capacity));
		end)
	end)
	module.playerModule.Get(side2, function (player)
		self.view.side2.name[UI.Text].text = player.name;
		utils.IconFrameHelper.Create(self.view.side2.IconFrame, {pid = player.id});
		module.playerModule.GetFightData(side2, true, function ()
			self.view.side2.rotateNum[SGK.RotateNumber]:Change(0, math.ceil(module.playerModule.GetFightData(side2).capacity));
		end)
	end)
	local action = self.data.winner == side1 and "guild_fight_ani1" or "guild_fight_ani2";
    self.view[UnityEngine.Animator]:Play(action);
	SGK.Action.DelayTime.Create(4.5):OnComplete(function ()
		if self.data and self.data.func then
			self.data.func()
		end
        UnityEngine.GameObject.Destroy(self.gameObject)
    end)
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == ""  then

	end
end

return View;