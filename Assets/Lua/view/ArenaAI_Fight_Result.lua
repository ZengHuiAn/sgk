local View = {};
function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
end

function View:UpdateResult(data)
	local pid=data and data[1]
	local win=data and data[2]
	utils.IconFrameHelper.Create(self.view.IconFrame,{pid=pid})
	-- self.view.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(player,true)
	self.view.name[UI.Text]:TextFormat("挑战 {0}{1}{2}",win and "<color=#3BFFBCFF>" or "<color=#FF1A1AFF>",win and "成功" or "失败","</color>")
end

return View;