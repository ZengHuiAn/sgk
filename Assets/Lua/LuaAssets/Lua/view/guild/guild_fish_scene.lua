local TAG = "guild_fish_scene"

local View = {}
function View:Start(data)
	DispatchEvent("MAP_UI_HideGuideLayerObj");
	-- UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/guild/guildFish"))

	DialogStack.PushPref("FishUI",nil, UnityEngine.GameObject.Find("bottomUIRoot"));
end


return View;