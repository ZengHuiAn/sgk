local traditionalArenaModule = require "module.traditionalArenaModule"
local QuestModule = require "module.QuestModule"
local ShopModule = require "module.ShopModule"

local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view
    
	self:InitView();
end

local CfgRewardType={[1]=2,[2]=1}
function View:InitView()
	self.UIDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
		DialogStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function()
		DialogStack.Pop();
	end

	self.rankPos = traditionalArenaModule.GetSelfRankPos() or 9999
	self.selected_tab = 1
	self:UpdateSelection()

	for i = 1, 2 do
        self.view.topTab[i][UI.Toggle].isOn = i==self.selected_tab
        self.view.topTab[i].SelectArrow:SetActive(i == self.selected_tab)
        CS.UGUIClickEventListener.Get(self.view.topTab[i].gameObject,true).onClick = function()
            self.view.topTab[self.selected_tab].SelectArrow:SetActive(false)
            self.view.topTab[i].SelectArrow:SetActive(true)
            self.selected_tab = i
            self:UpdateSelection()
        end
    end

	CS.UGUIClickEventListener.Get(self.view.helpBtn.gameObject).onClick = function()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("chuantongjjc_02"),SGK.Localize:getInstance():getValue("zhaomu_shuoming_01"), self.root)
	end	

	self.view.topTab[1].redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.RankArena.ScoreRewards, nil,self.view.topTab[1].redDot))
	self.view.topTab[2].redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.RankArena.RankRewards, nil,self.view.topTab[2].redDot))
end

local totalScoreItemId = 90170
function View:UpdateSelection()
	self.view.title[UI.Text].text = SGK.Localize:getInstance():getValue(self.selected_tab==1 and "chuantongjjc_03" or "chuantongjjc_04")
	self.view.helpBtn:SetActive(self.selected_tab == 2)
	self.view.scoreRewardTip:SetActive(self.selected_tab == 1)

	local totalScore = module.ItemModule.GetItemCount(totalScoreItemId)
	self.view.scoreRewardTip.valueText[UI.Text].text = totalScore

	local cfgType = CfgRewardType[self.selected_tab]
	local rewardsList = traditionalArenaModule.GetScoreRewards(cfgType)
	
	self.UIDragIconScript.RefreshIconCallback = (function (Obj,idx)
		local _Item = CS.SGK.UIReference.Setup(Obj);
		local rewardsCfg = rewardsList[idx+1]
		if rewardsCfg and next(rewardsCfg)~=nil then
			_Item.gameObject:SetActive(true)
			_Item[1]:SetActive(self.selected_tab == 1)
			_Item[2]:SetActive(self.selected_tab == 2)
			local item = _Item[self.selected_tab]

			if self.selected_tab == 1 then
				local quest_id = rewardsCfg.quest_id
				item.consumeTip[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_07",rewardsCfg.questLimit)
				
				item.btn[CS.UGUIClickEventListener].interactable = totalScore >= rewardsCfg.questLimit
				local _quest = QuestModule.Get(quest_id)
				if _quest then
					if idx ==0 then
						self.view.scoreRewardTip.tipText[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_06",os.date("%H:%M ",math.floor(_quest.cfg.time.from)))
					end
					item.btn:SetActive(_quest and _quest.status==0)
					item.GettedTip:SetActive(_quest and _quest.status==1)
					CS.UGUIClickEventListener.Get(item.btn.gameObject).onClick = function()
						if totalScore>= rewardsCfg.questLimit then
							if _quest.status == 0 then
								QuestModule.Finish(quest_id)
							else
								ERROR_LOG("任务已完成,quest_id",quest_id)
							end
						else
							local _scoreItemCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,totalScoreItemId)
							showDlgError(nil, string.format("%s不足",_scoreItemCfg.name))
						end
					end
					if _quest and _quest.status==2 then
						ERROR_LOG("任务过期",quest_id)
					end
				else
					ERROR_LOG("quest is nil,quest_id",quest_id)
				end
			elseif self.selected_tab == 2 then
				local _consumecfg = utils.ItemHelper.Get(rewardsCfg.consume.type,rewardsCfg.consume.id)
				if _consumecfg then
					item.customIcon[UI.Image]:LoadSprite("icon/" .. _consumecfg.icon.."_small")
					item.customValue[UI.Text].text = math.floor(rewardsCfg.consume.value / 0.1)
					item.off.Text[UI.Text].text = rewardsCfg.consume.value

					item.static_Text[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_09")
					item.tip[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_08",rewardsCfg.rankPos)
					
					item.btn:SetActive(rewardsCfg.status)
					item.GettedTip:SetActive(not rewardsCfg.status)

					local ownCount = module.ItemModule.GetItemCount(rewardsCfg.consume.id)
					item.btn[CS.UGUIClickEventListener].interactable = self.rankPos <= rewardsCfg.rankPos and rewardsCfg.consume.value<= ownCount					

					CS.UGUIClickEventListener.Get(item.btn.gameObject).onClick = function()
						local owenCount = module.ItemModule.GetItemCount(rewardsCfg.consume.id)
						if owenCount >= rewardsCfg.consume.value then
							for i=1,#rewardsCfg.rewards do
								local product_gid = rewardsCfg.product_gids[i]
								if product_gid then
									ShopModule.Buy(rewardsCfg.shop_id,product_gid,1)
								end
							end
						else
							showDlgError(nil, string.format("%s不足",_consumecfg.name))
						end
					end
				else
					ERROR_LOG("consumecfg is nil,type,id",rewardsCfg.consume.type,rewardsCfg.consume.id)
				end
			end

			for i=1,item.rewardContent.transform.childCount do
				item.rewardContent.transform:GetChild(i-1).gameObject:SetActive(false)
			end
		
			for i=1,#rewardsCfg.rewards do
				local _rewardItem = traditionalArenaModule.GetCopyUIItem(item.rewardContent,item.rewardContent[1],i)
				if _rewardItem then
					local _rewardCfg = rewardsCfg.rewards[i]
					utils.IconFrameHelper.Create(_rewardItem.IconFrame,{type = _rewardCfg.type,id = _rewardCfg.id,count = _rewardCfg.value,showDetail=true})
				end
			end
		end
	end)

	self.UIDragIconScript.DataCount = #rewardsList
end

function View:initGuide()
    module.guideModule.PlayByType(121,0.2)
end

function View:listEvent()
	return {
		"ITEM_INFO_CHANGE",
		"QUEST_INFO_CHANGE",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event,data)
	if event == "ITEM_INFO_CHANGE" then
		if self.selected_tab == 2 then
			if not self.updateScoreRewards then
				self.updateScoreRewards = true
				self.gameObject.transform:DOScale(Vector3.one,0.5):OnComplete(function()
					self:UpdateSelection()
					self.view.topTab[2].redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.RankArena.RankRewards, nil,self.view.topTab[2].redDot))
					self.updateScoreRewards = false
					DispatchEvent("UPDATA_LOCALREWARD_REDDOT")
				end)
			end
		end
	elseif event == "QUEST_INFO_CHANGE" then
		if self.selected_tab == 1 then
			if not self.updateRankRewards then
				self.updateRankRewards = true
				self.gameObject.transform:DOScale(Vector3.one,0.5):OnComplete(function()
					self:UpdateSelection()
					self.view.topTab[1].redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.RankArena.ScoreRewards, nil,self.view.topTab[1].redDot))
					self.updateRankRewards = false
					DispatchEvent("UPDATA_LOCALREWARD_REDDOT")
				end)
			end
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

return View;