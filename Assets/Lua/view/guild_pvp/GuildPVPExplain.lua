local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.exitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
end
return View