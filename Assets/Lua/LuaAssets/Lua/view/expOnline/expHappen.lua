local View = {}
local expModule = require "module.expModule"


-- 1为自己的buff 2为敌人buff
local Happen = {
	{
		--1为加成
		{index = 1},
		{index = 2},
	},
	{
		{index = 2},
		{index = 1},
	}

}

function View:Start(data)
	
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.view.bg.gameObject:SetActive(false);
	self.time = 0.4;
	-- self.view.gameObject:SetActive(true);
	-- ERROR_LOG(sprinttb(data or {}))
	
	local happend_type = data.type;

	local happend_value = data.value;
	--自己加buff
	if happend_type == 1 then
		local config = expModule.GetBuffConfig(happend_value[1]);

		if config.reward_value>0 then
			-- 加buff
			self:FreshView(happend_type,config,0);
		else
			-- 减buff
			self:FreshView(happend_type,config,1);
		end
	else
		--敌人加buff
		local config = expModule.GetBuffConfig(happend_value[1]);

		if config.reward_value>0 then
			-- 加buff
			self:FreshView(happend_type,config,1);
		else
			-- 减buff
			self:FreshView(happend_type,config,0);
		end
	end
	


end


function View:Update()

	if self.time then
		if self.time>0 then
			self.time = self.time - UnityEngine.Time.deltaTime;
		else
			self.time = nil;
			self:WaitDone();
		end
	end
	
end

function View:WaitDone()
	self.view.bg[UnityEngine.Transform].localScale = UnityEngine.Vector3(0,0,0);
	self.view.bg.gameObject:SetActive(true);

	self.view.bg.transform:DOScale(1,0.3);
	SetItemTipsStateAndShowTips(true);

	StartCoroutine(function()
		WaitForSeconds(0.5)
		self.view.mask[CS.UGUIClickEventListener].onClick = function ()
			DialogStack.Pop();
		end
	end)
end

function View:OnDestroy( ... )
	SetItemTipsStateAndShowTips(true);
end

function View:FreshView(type,cfg,happend_type)

	local flag = type == 1 and "己方" or "敌方";
	self.view.bg[CS.UGUISpriteSelector].index = happend_type;
	if happend_type ~= 1 then
		self.view.fx_bao_buff:SetActive(true);
		SGK.ResourcesManager.LoadAsync("sound/xkjj_buff_up.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
		end)
	else
		self.view.fx_bao_debuff:SetActive(true);
		SGK.ResourcesManager.LoadAsync("sound/xkjj_buff_down.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
		end)
	end

	
	if cfg then
		self.view.bg.tip.Image[UI.Image]:LoadSprite("icon/buff/"..cfg.icon)
		self.view.bg.tip.Text[UI.Text].text = flag..cfg.desc..(math.floor(math.abs( cfg.reward_value )/ cfg.rate))..(cfg.rate == 100 and "%" or "");
	else
		ERROR_LOG("未找到配置---->>>");
	end
end

function View:listEvent()
    return {

    }
end

function View:onEvent(event,data)
end


return View;