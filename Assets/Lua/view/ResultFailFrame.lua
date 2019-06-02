local View={}
function View:Start()
	self.view=SGK.UIReference.Setup(self.gameObject);

	CS.UGUIClickEventListener.Get(self.view.Exit.gameObject).onClick = function (obj)
		SceneStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.view.Record.gameObject).onClick = function (obj)
		DispatchEvent("FIGHT_RESULT_RECORD")
	end

	CS.UGUIClickEventListener.Get(self.view.Image.Grow.gameObject).onClick = function()
        DialogStack.InsertDialog("mapSceneUI/stronger/newStrongerFrame")
		SceneStack.Pop()
	end

	
	self.exit_left = 5;
end
function View:updateReplayInfo(data)
	-- self.view.TryAgain[UI.Button].interactable =false
	self.view.Image.TryAgain:SetActive(not not data)
	CS.UGUIClickEventListener.Get(self.view.Image.TryAgain.gameObject).onClick = function()
		data()
	end
end

return View;
