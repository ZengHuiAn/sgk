local ActivityConfig = require "config.activityConfig"
local View = {};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.close.gameObject,true).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	self:InitView(data)
end

function View:InitView(data)
	local cityType = data and data.cityType or 41
	local name = data and data.name or "神秘生物"
	local BossLv = data and data.bossLv or 1
	local CityLv = data and data.cityLv or 1

	self.view.title[UI.Text].text = SGK.Localize:getInstance():getValue("chengshijianshe_03")

	self.view.top.name[UI.Text].text = name
	self.view.top.tip[UI.Text].text = SGK.Localize:getInstance():getValue("每日首次击杀有几率获得奖励")

	local cityCfg = ActivityConfig.GetBuildCityConfig(cityType)
	ERROR_LOG(sprinttb(cityCfg))
	for i=1,self.view.bottom.transform.childCount do
		if i > #cityCfg then
			self.view.bottom.transform:GetChild(i-1).gameObject:SetActive(false)
		end
	end

	local CommonIconPool = CS.GameObjectPool.GetPool("CommonIconPool");
	for i=1,#cityCfg do
		local _rewardItem = utils.SGKTools.GetCopyUIItem(self.view.bottom,self.view.itemPrefab,i)
		_rewardItem.static_Text[UI.Text].text =  SGK.Localize:getInstance():getValue("guanqiazhengduo01")

		_rewardItem.cityLevel[UI.Text].text =  cityCfg[i].dcity_lv 
		
		-- local cityLvCfg = ActivityConfig.GetBuildCityConfig(cityType,cityCfg[i].dcity_lv)
		ERROR_LOG(sprinttb(cityCfg[i].squad))
		for k,v in pairs(cityCfg[i].squad) do
			if v.pos == 11 then
				_rewardItem.bossLevel[UI.Text].text =  SGK.Localize:getInstance():getValue("领主等级 "..v.level)
				break
			end
		end
		_rewardItem.mark:SetActive(cityCfg[i].dcity_lv == CityLv)
		_rewardItem[CS.UGUISpriteSelector].index = cityCfg[i].dcity_lv == CityLv and 1 or 0

		for j=1,4 do
			if cityCfg[i]["monster_reward"..j] and cityCfg[i]["monster_reward"..j] ~= 0 then
				local ItemIcon = nil
				if j <= _rewardItem.rewardsContent.transform.childCount then
					local _obj = _rewardItem.rewardsContent.transform:GetChild(j-1)
					ItemIcon = SGK.UIReference.Setup(CommonIconPool:Get(_rewardItem.rewardsContent.transform))
				else
					ItemIcon = SGK.UIReference.Setup(CommonIconPool:Get(_rewardItem.rewardsContent.transform))
					ItemIcon.transform.localScale = Vector3.one * 0.5
					ItemIcon:SetActive(true)
				end

				utils.IconFrameHelper.UpdateIcon({type = utils.ItemHelper.TYPE.ITEM,id = cityCfg[i]["monster_reward"..j],count = 0},ItemIcon, {
					showDetail = true,
					onClick = function ()
						DialogStack.PushPrefStact("ItemDetailFrame", {type = utils.ItemHelper.TYPE.ITEM,id = cityCfg[i]["monster_reward"..j]},self.gameObject)
					end,
				});
			end
		end
	end
end
 
return View;