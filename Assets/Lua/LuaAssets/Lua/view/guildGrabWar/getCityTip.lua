local MapConfig = require "config.MapConfig"
local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.map_id = data and data.map_id;
	self:InitView();
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.BG.gameObject).onClick = function ( object )
        UnityEngine.GameObject.Destroy(self.gameObject);
   	end
    CS.UGUIClickEventListener.Get(self.view.close.gameObject).onClick = function ( object )
        UnityEngine.GameObject.Destroy(self.gameObject);
    end
    CS.UGUIClickEventListener.Get(self.view.go.gameObject).onClick = function ( object )
        DialogStack.Push("buildCity/buildCityFrame",{map_Id = self.map_id})
        UnityEngine.GameObject.Destroy(self.gameObject);
    end
    local mapCfg = MapConfig.GetMapConf(self.map_id);
    self.view.Image.Text[UI.Text].text = mapCfg.map_name;
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