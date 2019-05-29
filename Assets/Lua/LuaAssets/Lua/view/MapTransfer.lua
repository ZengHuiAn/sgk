local MapConfig = require "config.MapConfig"
local TeamModule = require "module.TeamModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	DispatchEvent("Player_Stop_MoveTo")
	local x = self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].transform.localPosition.x
	if module.playerModule.GetFirst_start() then
		self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform]:DOLocalMove(Vector3(x,-(2668- math.abs(self.view.ScrollView.Viewport.Content.transform.localPosition.y)),0),2)
		module.playerModule.GetFirst_start(false)
	else
		self.view.ScrollView.Viewport.Content.transform.localPosition = Vector3(x,-(2668- math.abs(self.view.ScrollView.Viewport.Content.transform.localPosition.y)),0)
	end
	self.view.ScrollView.Viewport.Content.bg[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.back[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	for i = 1,self.view.ScrollView.Viewport.Content.bg.Dotbg.transform.childCount do
		local obj = self.view.ScrollView.Viewport.Content.bg.Dotbg.transform:GetChild(i-1)
		local idx = tonumber(obj.name)
		local objview = SGK.UIReference.Setup(obj)
		--ERROR_LOG(MapConfig.GetMapConf(self.mapId).map_name)
		objview.open.mask.icon[UnityEngine.UI.Image]:LoadSprite("guanqia/" .. MapConfig.GetMapConf(idx).use_icon)
		objview.name[UnityEngine.UI.Text].text = MapConfig.GetMapConf(idx).map_name
		if MapConfig.GetMapConf(idx).mapImage == "" then
			SGK.ResourcesManager.LoadAsync("sound/ditu.mp3",typeof(UnityEngine.AudioClip),function (Audio)
				objview.open[CS.UGUIClickEventListener].clickClip = Audio
			end)
		end
		objview.open[CS.UGUIClickEventListener].onClick = function ( ... )
			if MapConfig.GetMapConf(idx).mapImage == "" then
				if SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId ~= idx then
					local teamInfo = TeamModule.GetTeamInfo();
					local pid = module.playerModule.GetSelfID()
	   				if teamInfo.id <= 0 or pid == teamInfo.leader.pid or teamInfo.afk_list[pid] then
	   					DispatchEvent("KEYDOWN_ESCAPE")
						PlayerEnterMap(idx)
					else
						showDlgError(nil,"您不是队长，无法带领队伍传送")
					end
				else
					showDlgError(nil,"您已经在当前地图")
				end
			else
				DialogStack.PushPref("MapUI/DetailedMap"..idx,{map_id = idx},self.view)
			end
			--SceneStack.EnterMap(idx);
		end
		objview.open.aureole[1]:SetActive(SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId ~= idx)
		objview.open.aureole[2]:SetActive(SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId == idx)
		if SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId == idx then
			self.view.HeroPos.transform:SetParent(objview.transform, false);
			self.view.HeroPos.transform.localPosition = Vector3(0,85,0)
			self.view.HeroPos.transform:SetParent(self.view.ScrollView.Viewport.Content.bg.transform, true);
			local head = module.playerModule.IsDataExist(module.playerModule.GetSelfID()).head ~= 0 and module.playerModule.IsDataExist(module.playerModule.GetSelfID()).head or 11000
			self.view.HeroPos.mask[1]:SetActive(false)--[UnityEngine.UI.Image]:LoadSprite("icon/" .. head)
			local PLayerIcon = IconFrameHelper.Hero({},self.view.HeroPos.mask)
			PLayerIcon.transform.localScale = Vector3(0.45,0.45,1)
			PlayerInfoHelper.GetPlayerAddData(module.playerModule.GetSelfID(),99,function (addData)
            	IconFrameHelper.UpdateHero({icon = head,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
			end)
			self.view.HeroPos:SetActive(true)
		end
	end
	module.guideModule.PlayByType(15, 0.2)
end

function View:listEvent()
	return {
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, ...)
	if event == "LOCAL_GUIDE_CHANE" then
		module.guideModule.PlayByType(15, 0.2)
	end
end

return View