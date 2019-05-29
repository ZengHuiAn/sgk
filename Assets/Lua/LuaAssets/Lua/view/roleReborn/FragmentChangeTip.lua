local View = {}



function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:initClick()
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self.view.Dialog.Content.confirmBtn.gameObject).onClick = function ()
		utils.EventManager.getInstance():dispatch("Confirm_Change")
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

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)

end


return View;