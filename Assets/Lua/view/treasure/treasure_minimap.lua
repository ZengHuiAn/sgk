local View = {};
function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject)
end



return View;