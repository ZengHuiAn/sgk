
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.uuid = data and data.uuid or 0;
	self:InitData();
	self:InitView();
end

function View:InitData()
	self.battleData = module.TeamActivityModule.Get(2);
	self.npcData = self.battleData.npcs[self.uuid];
	self.updateTime = module.Time.now();
	self.allTime = self.npcData.value[1] - self.npcData.birth;
	self.action = false;
end

function View:InitView()
	if self.allTime > 0 then
		self.view.Slider:SetActive(true);
		self.view.Text:SetActive(true);
		self.view.Slider[UnityEngine.UI.Slider].value = 1;
		self.view.Text[UnityEngine.UI.Text].text = math.floor(self.allTime);
	else
		self:End();
	end
	
end

function View:End()
	if self.view.Text.activeSelf then
		self.view.Slider:SetActive(false);
		self.view.Text:SetActive(false);
		showDlgError(nil, "炸弹引爆，战斗失败！")
		DispatchEvent("FIGHT_FIALED");
	end
end

function View:Update()
	if module.Time.now() - self.updateTime >= 1 then
        self.updateTime = module.Time.now();
		if self.npcData.value[1] > module.Time.now() then
			local endTime = self.npcData.value[1] - module.Time.now();
			local value = endTime / self.allTime;
			self.view.Slider[UnityEngine.UI.Slider].value = value;
			if value > 0.5 then
				self.view.Slider.FillArea.Fill[CS.UGUISpriteSelector].index = 0;
			elseif value > 0.25 then
				self.view.Slider.FillArea.Fill[CS.UGUISpriteSelector].index = 1;
			else
				self.view.Slider.FillArea.Fill[CS.UGUISpriteSelector].index = 2;
			end
			if endTime <= 30 and not self.action then
				self.action = true;
				showDlgError(nil, "炸弹即将爆炸，尽快击杀")
				self.view.Image[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
			end
			self.view.Text[UnityEngine.UI.Text].text = math.floor(endTime);
		else
			self:End();
		end		
	end
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == ""  then

	end
end

return View;