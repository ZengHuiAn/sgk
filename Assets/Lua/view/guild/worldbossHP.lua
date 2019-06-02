local View = {};


function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)

	self.bossInfo = module.worldBossModule.GetBossInfo(1);

	-- 
	local cfg = module.worldBossModule.GetBossCfg(self.bossInfo.id);
	self.view[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(tonumber(cfg.pos_x or 0),tonumber(cfg.pos_y or 0))
	self:FreshHP();
	self.dur = module.Time.now() + 50;

end

function View:FreshHP(  )
	local _bossInfo = module.worldBossModule.GetBossInfo(1);
	self.view.HPSlider[UI.Slider].value = _bossInfo.hp /_bossInfo.allHp;
	self.view.HPSlider.Text[UI.Text].text = math.floor((_bossInfo.hp /_bossInfo.allHp)*100).."%";
end


function View:onEvent( event ,data )
	if event == "LOCAL_WORLDBOSS_INFO_CHANGE" or "LOCAL_WORLDBOSS_ATTACK_INFO" then
		self:FreshHP();
	end
end

function View:Update( ... )
    if self.dur then
        local time = self.dur - module.Time.now();
        if time <0 then
            module.worldBossModule.SendWatch(self.bossInfo.watch);
            self.dur = module.Time.now() + 50;
        end
    end
end


function View:listEvent()
	return {
	"LOCAL_WORLDBOSS_ATTACK_INFO",
	"LOCAL_WORLDBOSS_INFO_CHANGE"
}
end

return View;