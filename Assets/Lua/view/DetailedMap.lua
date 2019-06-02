local MapConfig = require "config.MapConfig"
local TeamModule = require "module.TeamModule"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.bg[UI.Image]:LoadSprite("map/"..MapConfig.GetMapConf(data.map_id).mapImage)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.bg[UI.Image]:SetNativeSize()
	local now_map_id = TeamModule.GetmapMoveTo()[4]
	for i = 1,self.view.mode.transform.childCount do
		local obj = self.view.mode.transform:GetChild(i-1)
		local idx = tonumber(obj.name)
		--self.view.mode[i].name[UI.Text].text = "<color=#"..(idx == data.map_id and "FFB200FF" or "FFFFFFFF")..">"..MapConfig.GetMapConf(idx).map_name.."</color>"
		self.view.mode[i].name[UI.Text].text = MapConfig.GetMapConf(idx).map_name
		self.view.mode[i][CS.UGUISpriteSelector].index = idx == data.map_id and 1 or 0
		if now_map_id == idx then
			self.view.arrows.transform.position = obj.transform.position
			self.view.arrows:SetActive(true)
		end
		self.view.mode[i][CS.UGUIClickEventListener].onClick = function ( ... )
			--showDlgError(nil,"传送到"..MapConfig.GetMapConf(idx).map_name)
			if SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId ~= idx then
				local teamInfo = TeamModule.GetTeamInfo();
				local pid = module.playerModule.Get().id
   				if teamInfo.id <= 0 or pid == teamInfo.leader.pid or teamInfo.afk_list[pid] then
					UnityEngine.GameObject.Destroy(self.gameObject)
					PlayerEnterMap(idx)
				else
					showDlgError(nil,"您不是队长，无法带领队伍传送")
				end
			else
				showDlgError(nil,"您已经在当前地图")
			end
		end
	end
end
return View