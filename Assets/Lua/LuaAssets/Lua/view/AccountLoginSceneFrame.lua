local View = {};
function View:Start(data)
	self.Data = data
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	local ImageName = ""
	if false and module.playerModule.Get().level <= 15 then
		ImageName = "loading_xiaobai"..math.random(1,2)
	else
		ImageName = "loading_0"..math.random(1,6)
	end
	self.view.Scrollbar.SlidingArea.Handle:SetActive(false)
	print("ImageName", ImageName);
	self.view[UnityEngine.UI.Image]:LoadSpriteWithExt("loading/"..ImageName..".jpg",function ( ... )
		self.view.Scrollbar.SlidingArea.Handle:SetActive(true)
		SGK.SceneService.GetInstance():SwitchScene(data.name, false, false, "", self.Data.callback);
		UnityEngine.GameObject.Destroy(self.gameObject);
		-- self.view[CS.AccountLoginScene]:LoadGame(data.name,self.Data.callback)--function ( ... )
		-- 	if self.Data.callback then
		-- 		self.Data.callback()
		-- 	end
		-- end)
	end)
	--SGK.Action.DelayTime.Create(5):OnComplete(function()
		
	--end)
	-- self.view[UnityEngine.UI.Image]:DOFade(1,0.5):OnComplete(function ( ... )

	-- end)
end
function View:OnDestroy()
	
end
function View:listEvent()
	return {

	}
end

function View:onEvent(event, data)

end
return View
