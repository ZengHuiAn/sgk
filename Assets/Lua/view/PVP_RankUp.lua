local PVPArenaModule = require "module.PVPArenaModule";

local Number = {"Ⅰ","Ⅱ","Ⅲ","Ⅳ","Ⅴ","Ⅵ","Ⅶ","Ⅷ","Ⅸ"}
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
	self:InitData();
	self:InitView();
end

function View:InitData()
	local info = PVPArenaModule.GetPlayerInfo();
	if info then
		local str,stage,num = PVPArenaModule.GetRankName(info.wealth);
		self.view.Text.rank[CS.UnityEngine.UI.Image]:LoadSprite("icon/cl_"..stage, true);
	
		self.view.Text.rank.class[UnityEngine.UI.Text].text = Number[num];
		self.view.Text.rank.name[UnityEngine.UI.Text]:TextFormat(str);
		self.view.Text.Text.num[UnityEngine.UI.Text].text = tostring(info.rank);
		if stage == 1 then
			self.view.Text.rank.class.gameObject.transform.localPosition = Vector3(0,-76.5,0);
		else
			self.view.Text.rank.class.gameObject.transform.localPosition = Vector3(0,-68.5,0);
		end
	end

end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.BG.gameObject,true).onClick = function (obj)
		UnityEngine.Object.Destroy(self.gameObject)
	end
    CS.UGUIClickEventListener.Get(self.view.close.gameObject,true).onClick = function (obj)
		UnityEngine.Object.Destroy(self.gameObject)
	end
end

function View:listEvent()
	return {
		"ARENA_GET_PLAYER_INFO_SUCCESS",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "ARENA_GET_PLAYER_INFO_SUCCESS"  then
		self:InitData();
	end
end

return View;