local View = {};
function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
end

function View:UpdateResult(data)
    local hero=data and data[1]
    local cfg=data and data[2]
    local win=data and data[3]
	self.view.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(hero)
    self.view.name[UI.Text]:TextFormat("{0} 挑战 {1}{2}",cfg.name,win and "<color=#3BFFBCFF>成功" or "<color=#FF1A1AFF>失败","</color>")
end

return View;