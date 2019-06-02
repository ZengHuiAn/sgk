local HeroLevelup = require "hero.HeroLevelup"
local playerModule = require "module.playerModule"
local View={}

function View:Start()
	self.view = SGK.UIReference.Setup(self.gameObject);
end

local function SortList(data)
	local list = {}
	local tab = {}
	for k,v in pairs(data) do
		local list = {}
		for i=1,#v do
			list[i] = v[i]
		end
		table.insert(tab,{list = list,pid =k})
	end

	list.totalValue = 0
	list.roles = {}
	for i=1,#tab do
		local totalValue = 0
		list.roles[i] = {pid = tab[i].pid,value = 0}
		for j=1,#tab[i].list do
			list.roles[i].value = list.roles[i].value + tab[i].list[j].damage
		end
		list.totalValue = list.totalValue+ list.roles[i].value
	end
	table.sort(list.roles,function (a,b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.pid<b.pid
	end)
	return list
end

function View:Init(data)
	self.teamInfo = SortList(data[1])
	self.rewards = data[2]

	local totalValue = 0
	local selfInfo = nil
	local mvpInfo = nil
	-- for k, v in pairs(self.teamInfo) do
	-- 	local _value = tonumber(v[3] and v[3] or 0)
	-- 	totalValue = totalValue + _value
	-- 	if v[1] == playerModule.GetSelfID() then
	-- 		selfInfo = v
	-- 	end
	-- 	if v[4] then
	-- 		mvpInfo = v
	-- 	end
	-- end
	local selfIdx = 0
	for i=1,#self.teamInfo.roles do
		if self.teamInfo.roles[i].pid == playerModule.GetSelfID() then
			selfIdx = i
			break
		end
	end
--self.teamInfo.totalValue
	if self.teamInfo.roles[1] then
		self:updateMvpInfoShow(self.teamInfo.roles[1])
	end

	if selfIdx~=0 then
		self:updateSelfInfoShow(self.teamInfo.roles[selfIdx],selfIdx)
	end
end

local function updateInfoShow(Slot,Info,totalValue,Idx)
	-- local pid = Info[1]
	-- local scoreLv = Info[2]>0 and Info[2]<8 and Info[2] or 7
	-- local showValue = Info[3] and Info[3] or 0

	-- utils.IconFrameHelper.Create(Slot.scaler.IconFrame, {pid = pid});
	-- Slot.scaler.TopTag[CS.UGUISpriteSelector].index = scoreLv-1

	-- Slot.hart[UnityEngine.UI.Image].fillAmount = totalValue~=0 and showValue/ totalValue or 0
	-- local _showM = math.modf(showValue/1000000)--string.format("%0.1f", dt)--  一位
	-- local _showK = math.modf(showValue/1000)
	-- Slot.hartValue[UI.Text].text=_showM>0 and string.format("%0.1fM",showValue/1000000) or (_showK>0 and string.format("%0.1fK",showValue/1000) or tostring(showValue))
	
	-- playerModule.Get(pid,function ( ... )
	-- 	local player = playerModule.Get(pid);
	-- 	Slot.nameText[UI.Text].text = player.name 
	-- end)

	-- utils.PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
	-- 	Slot.sexImage[CS.UGUISpriteSelector].index = addData.Sex
	-- end)

	local pid = Info.pid
	local scoreLv = Idx --Info[2]>0 and Info[2]<8 and Info[2] or 7
	local showValue = Info.value --Info[3] and Info[3] or 0

	utils.IconFrameHelper.Create(Slot.scaler.IconFrame, {pid = pid});
	Slot.scaler.TopTag[CS.UGUISpriteSelector].index = scoreLv-1

	Slot.hart[UnityEngine.UI.Image].fillAmount = totalValue~=0 and showValue/ totalValue or 0
	local _showM = math.modf(showValue/1000000)--string.format("%0.1f", dt)--  一位
	local _showK = math.modf(showValue/1000)
	Slot.hartValue[UI.Text].text=_showM>0 and string.format("%0.1fM",showValue/1000000) or (_showK>0 and string.format("%0.1fK",showValue/1000) or tostring(showValue))
	
	playerModule.Get(pid,function ( ... )
		local player = playerModule.Get(pid);
		Slot.nameText[UI.Text].text = player.name 
	end)

	utils.PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
		Slot.sexImage[CS.UGUISpriteSelector].index = addData.Sex
	end)
end

local function GetExpValue()
	local hero = module.HeroModule.GetManager():Get(11000)
	local HeroLevelup = require "hero.HeroLevelup"
	local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
	local Level_exp = hero_level_up_config[hero.level]
	local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1]-Level_exp or hero_level_up_config[hero.level]-hero_level_up_config[hero.level-1]
	local ShowExp=hero.exp-Level_exp<=Next_hero_level_up and (hero.exp-Level_exp>=0 and hero.exp-Level_exp or 0) or Next_hero_level_up

	return ShowExp,Next_hero_level_up
end

function View:updateMvpInfoShow(Info)
	local Slot = self.view.top.Slot
	if Slot then
		updateInfoShow(Slot,Info,self.teamInfo.totalValue,1)
	end
end

function View:updateSelfInfoShow(Info,idx)
	local Slot = self.view.mid.Slot
	if Slot then
		updateInfoShow(Slot,Info,self.teamInfo.totalValue,idx)

		local ShowExp,Next_hero_level_up = GetExpValue()

		Slot.exp[UI.Image].fillAmount =ShowExp/Next_hero_level_up
		Slot.expValue[UI.Text].text=string.format("%s/%s",math.floor(ShowExp),math.floor(Next_hero_level_up))
	end
end

--[[
local HelpTipItem= 90035--提示记数道具
local consumeItem=1080003--提示消耗道具(购买一个,消耗一次)
function View:updateMvpShow(teamInfo)
	ERROR_LOG(sprinttb(teamInfo))
	showTeamLeaderShow=true---组队战斗
	self.teamInfo=teamInfo

	local _ItemCount=module.ItemModule.GetItemCount(HelpTipItem)
	self.have_score_info = true;
	SGK.Action.DelayTime.Create(1.1):OnComplete(function()
	if self.gameObject then
		local list = {};
		local totalValue=0
		for _, v in pairs(teamInfo) do
			table.insert(list, v);
			totalValue=totalValue+tonumber(v[3] and v[3] or 0)
		end
	
		table.sort(list, function(a,b)
			if a[1]~=b[1] then
				return a[1]==module.playerModule.GetSelfID()
			end
			if a[4] ~= b[4]then
				return a[4]
			end
			return a[3] > b[3]   
		end)			
		ERROR_LOG(sprinttb(list))
	    local prefab =SGK.ResourcesManager.Load("prefabs/CharacterIcon")
	    for i=1,#list do
	        local slot = self.view.characters[i];
	        if slot then
	            playerModule.Get(list[i][1],function ( ... )
					local player = playerModule.Get(list[i][1]);
					local scoreLv=list[i][2]>0 and list[i][2]<8 and list[i][2] or 7
					local showValue=list[i][3] and list[i][3] or 0
					slot:SetActive(true);
					local CharacterIcon= SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, self.view.characters[i].scaler.CharacterIcon.gameObject.transform));
					CharacterIcon.gameObject.transform.localScale =i==1 and Vector3.one*0.9 or Vector3.one*0.8

					CharacterIcon.gameObject.transform.localPosition=Vector3.zero
					CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
					if i==1 then
						self:UpdatePlayerExp()
					end
					if list[i][4] then
						module.ChatModule.SystemChatMessage(string.format("<color=#FFD800FF>%s</color>贡献巨大成为MVP,获得奖励",player.name))
					end

					slot.scaler.name[UI.Text].text=player.name   

					slot.scaler.TopTag[CS.UGUISpriteSelector].index =scoreLv-1
					slot.TempScore[CS.UGUISpriteSelector].index =scoreLv-1

					slot.TempScore[UI.Image]:DOFade(1,0.05):SetDelay(0.15*i)
					slot.TempScore.gameObject.transform:DOLocalMove(Vector3(-50,50,0),0.05):OnComplete(function ( ... )          
						slot.TempScore.gameObject:SetActive(false)
						slot.scaler.TopTag.gameObject:SetActive(true)
					end):SetDelay(0.15*i)

					slot.hart[UnityEngine.UI.Image].fillAmount =totalValue~=0 and showValue/ totalValue or 0
					local _showM=math.modf(showValue/1000000)--string.format("%0.1f", dt)--  一位
					local _showK=math.modf(showValue/1000)
					slot.hartValue[UI.Text].text=_showM>0 and string.format("%0.1fM",showValue/1000000) or (_showK>0 and string.format("%0.1fK",showValue/1000) or tostring(showValue))
				end)
			end
		end
	   
		SGK.Action.DelayTime.Create(1):OnComplete(function()
			if self.gameObject then
				local mvpCharacter=list[1][4] and self.view.characters[1] or self.view.characters[2]
				self.view.characters[1].mvpBg.gameObject:SetActive(list[1][4])
				mvpCharacter.mvpRoot.MvpImage[UI.Image]:DOFade(1,0.05);
				mvpCharacter.mvpRoot.MvpImage.gameObject.transform:DOScale(list[1][4] and Vector3.one or Vector3.one*0.5,0.1)
				mvpCharacter.mvpRoot.MvpImage.gameObject.transform:DOLocalMove(Vector3.zero,0.1)
				-- self.view.gameObject.transform:DOPunchScale(Vector3.one*1.2,0.1,0.1,0)
				self.view.gameObject.transform:DOScale(Vector3.one*1.2,0.1)
				self.view.gameObject.transform:DOScale(Vector3.one,0.1)

				SGK.Action.DelayTime.Create(0.5):OnComplete(function()
					if self.gameObject then
						if _ItemCount>0 then
							mvpCharacter.mvpRoot.desc.gameObject:SetActive(true)
							mvpCharacter.mvpRoot.desc.info[UI.Text].text=TipConfig.GetAssistDescConfig(83001).info

							self.view.characters[1].desc.gameObject:SetActive(true) 
							self.view.characters[1].desc.info[UI.Text].text=TipConfig.GetAssistDescConfig(83002).info

							module.ShopModule.Buy(8, consumeItem, 1)
						end
					end
				end)
			end
		end)
	end
	end)
end
--]]
function View:listEvent()
	return {
		""
	}
end

function View:onEvent(event)
	if event == "" then
	
	end
end

return View;
