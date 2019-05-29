local HeroModule=require "module.HeroModule";
local RoleRebornModule=require "module.RoleRebornModule";

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:initData(data)
	self:initClick()
	self:initScrollView()
end

function View:initData(data)
	self.roleId = data.roleId
	self.Hero = HeroModule.GetManager():Get(self.roleId)
	self.iconList = RoleRebornModule.GetRoleRebornRewardList(self.roleId)
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self.view.Dialog.Content.confirmBtn.gameObject).onClick = function ()
		RoleRebornModule.RoleReborn(self.Hero.gid,self.Hero.uuid)
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.view.Dialog.Content.cancelBtn.gameObject).onClick = function ()
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.view.Dialog.Close.gameObject).onClick = function ()
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject,true).onClick = function ()
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
end

function View:initScrollView()
	local UIMultiScroller = self.view.Dialog.Content.ScrollView.Viewport.Content[CS.ScrollViewContent];

	UIMultiScroller.RefreshIconCallback = function(obj, idx)
		obj:SetActive(true);
		local slot = SGK.UIReference.Setup(obj);
		local cfg = self.iconList[idx+1];
		utils.IconFrameHelper.Create(slot.IconFrame, {type = cfg.type, id = cfg.id, count = cfg.count, showDetail = false})

		-- CS.UGUIClickEventListener.Get(slot.gameObject).onClick = function()
		-- 	if not self.is_assists_view then
		-- 		utils.EventManager.getInstance():dispatch("OPEN_ROLE_REBORN",{RoleId = id})
		-- 		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
		-- 	end
		-- end
	end

	UIMultiScroller.DataCount = #self.iconList;
end

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)

end


return View;