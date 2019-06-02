local StoryConfig = require "config.StoryConfig"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local ItemHelper = require "utils.ItemHelper";
local UserDefault = require "utils.UserDefault";

local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	local old_Vec3 = nil
	self.view.ScrollView[CS.UGUIPointerEventListener].onPointerDown = function ()
		old_Vec3 = CS.UnityEngine.Input.mousePosition
	end
	self.view.ScrollView[CS.UGUIPointerEventListener].onPointerUp = function ()
		if CS.UnityEngine.Vector3.Distance(old_Vec3,CS.UnityEngine.Input.mousePosition) < 1 then
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	self.view.ScrollView.Viewport.Content.desc[UI.Text].text = ""
	self.StoryData = StoryConfig.GetStoryConf(self.Data.id)
	self:UIRef()
end
function View:UIRef()
	if self.StoryData then
		local name = ""
		if self.StoryData.active_role == 1 then
			name = self.StoryData.name
		elseif self.StoryData.active_role == 2 then
			name = self.StoryData.role2_name
		elseif self.StoryData.active_role == 3 then
			name = self.StoryData.role3_name
		end
		local desc = self.StoryData.dialog
		if desc ~= "" then
			self.view.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.ScrollView.Viewport.Content.desc[UI.Text].text.."<size=36><color=#"..self.StoryData.namecolor..">"..name.."</color></size>:\n"..desc.."\n\n"
		end
		if self.StoryData.story_id ~= self.Data.now_id then
			self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
			self:UIRef()
		end
	end
end
return View