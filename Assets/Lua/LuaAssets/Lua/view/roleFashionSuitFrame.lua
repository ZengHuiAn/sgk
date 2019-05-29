local openLevel = require "config.openLevel"
local HeroModule = require "module.HeroModule"
local NetworkService = require "utils.NetworkService";
local ParameterShowInfo = require "config.ParameterShowInfo";
local playerModule = require "module.playerModule";
local HeroHelper = require "module.HeroHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local QuestModule = require "module.QuestModule"
local OpenLevel = require "config.openLevel"

local heroBuffModule = require "hero.HeroBuffModule"


local View = {};
function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	self.UIDragIconScript=self.view.ScrollView[CS.UIMultiScroller]
	self.Data = data and data or self.savedValues.Data
	
	self.AnimationIndex = 1--动画索引位置
	self.SuitIndex= self.savedValues.SuitIndex--当前英雄头像位置

	self.ConditionItemUITab={}

	self.SuitList = HeroHelper.GetFashionSuits(self.Data.heroid)-- HeroModule.GetSortHeroList(1)
		
	local hero = HeroModule.GetManager():Get(self.Data.heroid)

	self.showMode = hero.showMode
	self:ExchangeFashionSuit(hero)--兑换时装
	self.lastSuitIdx=1

	if not self.SuitIndex then
		if self.view.HeroAnimation.gameObject.transform.childCount == 0 then
			self.Animation = {}
			for i = 1,#self.SuitList do
				if self.SuitList[i].showMode== self.showMode then
					self.SuitIndex = i
					break
				end
			end
		end
	end

	self:RefHeroAnimation()
	self:UpdateButtonStatuShow(self.SuitList[self.SuitIndex])
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		obj:SetActive(true)

		local Item=CS.SGK.UIReference.Setup(obj);
		local suitCfg=self.SuitList[idx+1]
		utils.IconFrameHelper.Create(Item.Background.IconFrame, {customCfg = {level = 0,star = 0,quality = 0,icon = suitCfg.showMode,type = utils.ItemHelper.TYPE.HERO}})

	    Item[UI.Toggle].isOn = suitCfg.showMode==self.showMode
	    
	    CS.UGUIClickEventListener.Get(Item.Background.gameObject).onClick = function (obj)
			if self.SuitIndex~=idx+1 then 
				Item[UI.Toggle].isOn=true
				local pos_x=idx+1>self.SuitIndex and 1500 or -1500
				self.SuitIndex=idx+1
				self:HeroIconClick(pos_x)

				self.SelectSuitCfg=suitCfg
				self:UpdateButtonStatuShow()
			end
		end

		Item.gameObject:SetActive(true)
	end)

	self.UIDragIconScript.DataCount=#self.SuitList

	CS.UGUIClickEventListener.Get(self.view.GetBtn.gameObject,true).onClick = function (obj) 
		self:RefContiditonsShow()
	end

	CS.UGUIClickEventListener.Get(self.view.UseBtn.gameObject,true).onClick = function (obj) 
		local heroUuid=HeroModule.GetManager():Get(self.Data.heroid).uuid
		local suitId=self.SelectSuitCfg.suitId
		if self.SelectSuitCfg.suitId==0 then
			local _cfg = HeroHelper.GetCfgByShowMode(self.Data.heroid,self.showMode)
			suitId = _cfg.suitId
		end
		HeroModule.ChangeSpecialStatus(heroUuid,suitId,self.SelectSuitCfg.suitId~=0 and true)
	end

	CS.UGUIClickEventListener.Get(self.root.backBtn.gameObject,true).onClick = function (obj) 
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.shareBtn.weixing.gameObject).onClick=function()
		DialogStack.PushPrefStact("shareFrame",{name="RoleFashionSuit"},UnityEngine.GameObject.Find("mapSceneUI(Clone)/UGUITopRoot"))
     end
end

function View:ExchangeFashionSuit(hero)
	for k,v in pairs(self.SuitList) do
		if v.suitId~= 0 then
			if not hero.items[v.suitId] or (hero.items[v.suitId] and hero.items[v.suitId]<1)then
				module.HeroHelper.GetHeroSuit(hero,v.suitId)
			end
		end
	end
end

function View:UpdateButtonStatuShow(suitCfg)
	local suitCfg=suitCfg or self.SelectSuitCfg
	local Getted=true
	if suitCfg.suitId~= 0 then
		local hero=HeroModule.GetManager():Get(self.Data.heroid)
		if hero.items[suitCfg.suitId] and hero.items[suitCfg.suitId]>0 then
			Getted=true
		else  -----如果未获得道具 就检查任务是否完成
			Getted=false
			local allFinished=true
			for i=1,#suitCfg.conditions do
				local _quest = QuestModule.Get(suitCfg.conditions[i])
				if _quest and _quest.status ==0 then
					if QuestModule.CanSubmit(suitCfg.conditions[i]) then
						QuestModule.Finish(suitCfg.conditions[i])
					end
					allFinished=false
				end
			end
		end
	end

	self.view.UseBtn:SetActive(Getted and suitCfg.showMode~=self.showMode)
	self.view.UsingTip:SetActive(Getted and suitCfg.showMode==self.showMode)
	self.view.GetBtn:SetActive(not Getted)
end

function View:InitViewialize_HeroObj(i,mode)
	local gameobj = UnityEngine.GameObject("Suit"..1);
	gameobj.transform.parent = self.view.HeroAnimation.gameObject.transform;
	
	local CurPos,_Scale=self:GetModePosCfg(self.SuitIndex)

	local x = (i == 1 and 0 or -15)
	gameobj.transform.localPosition =Vector3(CurPos.x,CurPos.y,0)+ Vector3(x,0,0)
	gameobj.transform.localScale = _Scale
	gameobj.transform.localEulerAngles = Vector3.zero
	self.Animation[i] = {}
	self.Animation[i][1] = gameobj
	self.Animation[i][2] = gameobj:AddComponent(typeof(CS.Spine.Unity.SkeletonGraphic));
end

function View:HeroIconClick(x)
	local DestroyARR = self.Animation[self.AnimationIndex][1]

	local lastPos = self:GetModePosCfg(self.lastSuitIdx)
	local CurPos = self:GetModePosCfg(self.SuitIndex)
	if CurPos and lastPos then
		local _lastPos = Vector3(lastPos.x,lastPos.y,0)
		self.Animation[self.AnimationIndex][1].transform:DOLocalMove(_lastPos+Vector3(-x,0,0),0.5):OnComplete(function ( ... )
			CS.UnityEngine.GameObject.Destroy(DestroyARR)
		end)
		self.AnimationIndex = self.AnimationIndex == 1 and 2 or 1
		self:RefHeroAnimation()
		local _curPos = Vector3(CurPos.x,CurPos.y,0)
		self.Animation[self.AnimationIndex][1].transform.localPosition = _curPos+Vector3(x,0,0)
		self.Animation[self.AnimationIndex][1].transform:DOLocalMove(_curPos,0.5)
		self.lastSuitIdx=self.SuitIndex
	end
end

function View:RefHeroAnimation()--刷新英雄动画
	local suitCfg=self.SuitList[self.SuitIndex]
	self:InitViewialize_HeroObj(self.AnimationIndex,suitCfg.showMode)

	self.Animation[self.AnimationIndex][2].skeletonDataAsset =utils.SGKTools.loadExistSkeletonDataAsset("roles/",self.Data.heroid,suitCfg.showMode,"_SkeletonData.asset")-- SGK.ResourcesManager.Load("roles/"..suitCfg.showMode.."/"..suitCfg.showMode.."_SkeletonData");--skeletonDataName;

	self.Animation[self.AnimationIndex][2].startingAnimation ="idle"
	self.Animation[self.AnimationIndex][2].startingLoop = true
	self.Animation[self.AnimationIndex][2]:Initialize(true);
	
	self.view.top.name[UI.Text].text=suitCfg.fashion_name
	if suitCfg.effect_type ~= 0 then
		local cfg = ParameterShowInfo.Get(suitCfg.effect_type);
		if cfg then
			if cfg.rate == 1 then
				self.view.top.proprety[UI.Text].text=string.format("%s+%s",cfg.name,suitCfg.effect_value)
			else
				local _value=type(suitCfg.effect_type)=="string" and math.floor(suitCfg.effect_value*100)  or math.floor(suitCfg.effect_value*100/cfg.rate)  
				self.view.top.proprety[UI.Text].text = string.format("%s+%s%%",cfg.name,_value)				
			end
		else
			ERROR_LOG("cfg is nil ,id",suitCfg.effect_type)
			self.view.top.proprety[UI.Text].text = ""
		end
	else
		self.view.top.proprety[UI.Text].text = ""
	end
end

function View:RefContiditonsShow()
	local suitCfg=self.SelectSuitCfg
	self.root.conditionsShowPanel:SetActive(true)

	local Getted=true
	if suitCfg.suitId ~=0 then
		local hero=HeroModule.GetManager():Get(self.Data.heroid)
		Getted=hero.items[suitCfg.suitId] and hero.items[suitCfg.suitId]>0
	end
	self.root.conditionsShowPanel.questShow:SetActive(suitCfg.quest_go_where==1)
	self.root.conditionsShowPanel.sourceShowFrame:SetActive(suitCfg.quest_go_where==0)
	if suitCfg.quest_go_where==1  then
		self.root.conditionsShowPanel.questShow.Btn[CS.UGUIClickEventListener].interactable = Getted
		CS.UGUIClickEventListener.Get(self.root.conditionsShowPanel.questShow.Btn.gameObject,true).onClick = function (obj) 
			self.SelectSuitCfg=suitCfg
			local heroUuid=HeroModule.GetManager():Get(self.Data.heroid).uuid
			local suitId=suitCfg.suitId
			if suitCfg.suitId==0 then
				local _cfg=HeroHelper.GetCfgByShowMode(self.Data.heroid,self.showMode)
				suitId=_cfg.suitId
			end
			HeroModule.ChangeSpecialStatus(heroUuid,suitId,suitCfg.suitId~=0 and true)
		end
		CS.UGUIClickEventListener.Get(self.root.conditionsShowPanel.questShow.ExitBtn.gameObject).onClick = function (obj) 
			self.root.conditionsShowPanel.gameObject:SetActive(false)
		end

		for k,v in pairs(self.ConditionItemUITab) do
			v.gameObject:SetActive(false)
		end
		for i=1,#suitCfg.conditions do
			local _obj=nil
			if self.ConditionItemUITab[i] then
				_obj=self.ConditionItemUITab[i]
			else
				_obj=UnityEngine.Object.Instantiate(self.root.conditionsShowPanel.questShow.sourceTipPrefab.gameObject,self.root.conditionsShowPanel.questShow.gameObject.transform)
				self.ConditionItemUITab[i]=_obj
			end
			
			if not suitCfg.conditions[i] then return end
			_obj.gameObject:SetActive(true)

			local item=CS.SGK.UIReference.Setup(_obj.transform)	

			local _quest = QuestModule.Get(suitCfg.conditions[i])
			local _questCfg =module.QuestModule.GetCfg(suitCfg.conditions[i])
			
			if _questCfg then
				item.name[UI.Text].text=string.format((not _quest or _quest.status ==1) and "%s" or "<color=#808080FF>%s</color>",string.gsub(_questCfg.name ,"\n",""))
				
				local case=not (_quest and _quest.status ==0) and true or false
				item.bg1.gameObject:SetActive(not case)
				item.bg2.gameObject:SetActive(case)
				
				-- item.goMark.gameObject:SetActive(_quest and _quest.status ==0)
				-- item.finishMark.gameObject:SetActive(_quest and _quest.status ==1)

				--if _quest and _quest.status ==0 then
					CS.UGUIClickEventListener.Get(_obj.gameObject,case).onClick = function (obj) 
						local _gotoConfig = QuestModule.GetGoWhereConfig(_questCfg.go_where);
						if _gotoConfig then
							if _gotoConfig.gototype == 1 and _gotoConfig.findnpcname ~= 0 then
	                            DialogStack.Pop()
	                            utils.SGKTools.Map_Interact(tonumber(_gotoConfig.findnpcname))
	                        elseif _gotoConfig.gototype == 2 then
	                            DialogStack.Push(_gotoConfig.gotowhere,nil,"UGUIRootMid");
	                        elseif _gotoConfig.gototype == 3 then
	                            if _gotoConfig.scriptname ~= "0" then
	                                SceneStack.Push(_gotoConfig.gotowhere, _gotoConfig.scriptname);
	                            else
	                                SceneStack.Push(_gotoConfig.gotowhere, "view/".._gotoConfig.gotowhere..".lua");
	                            end
	                        elseif _gotoConfig.gototype == 4 then
	                            DialogStack.Pop()
	                            SceneStack.EnterMap(tonumber(_gotoConfig.gotowhere))
	                        elseif _gotoConfig.gototype == 5 then--_questCfg.go_where==112 then--类型为 112 跳转至主线(来自7天活动)
								local mainQuest = QuestModule.GetList(10,0);
								--print("测试主线任务", sprinttb(mainQuest))
								if #mainQuest == 0 then
									showDlgError(nil, "主线任务已完成");
								elseif #mainQuest == 1 then
									local _size = #DialogStack.GetStack() + #DialogStack.GetPref_stact()
						            for i = 1, _size do
						                DialogStack.Pop()
						            end
									utils.SGKTools.Map_Interact(mainQuest[1].npc_id)
								else
									table.sort( mainQuest, function ( a,b )
										return a.id > b.id
									end )

									local _size = #DialogStack.GetStack() + #DialogStack.GetPref_stact()
						            for i = 1, _size do
						                DialogStack.Pop()
						            end
									utils.SGKTools.Map_Interact(mainQuest[1].npc_id)
								end
							elseif _gotoConfig.gototype == 6 then
								DialogStack.Push("ShopFrame",{index = tonumber(_gotoConfig.gotowhere)});
							else
								ERROR_LOG("_gotoConfig.gototype is unknown",_gotoConfig.gototype)
							end
						else
							ERROR_LOG("gotoConfig is nil,_questCfg.go_where",_questCfg.go_where)
						end
					end
				--end
			else
				ERROR_LOG("_questCfg is nil",suitCfg.conditions[i])
			end
		end
	elseif suitCfg.quest_go_where==0 then--时装 来源 为 物品来源
		local x=self.root.conditionsShowPanel.sourceShowFrame[UnityEngine.RectTransform].sizeDelta.x
		local y=self.root.conditionsShowPanel.sourceShowFrame.sourceTipPrefab[UnityEngine.RectTransform].sizeDelta.y
		local sourceCfg = module.ItemModule.GetItemSource(suitCfg.conditions[1])
		self.root.conditionsShowPanel.sourceShowFrame.Btn:SetActive(not not sourceCfg)
		if sourceCfg then
			local count = #sourceCfg
			self.root.conditionsShowPanel.sourceShowFrame[UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(x,333+count*y)
			self.root.conditionsShowPanel.sourceShowFrame[SGK.LuaBehaviour]:Call("ShowSourceTitle",suitCfg.conditions[1],nil,true)
			self.root.conditionsShowPanel.sourceShowFrame.Btn[CS.UGUIClickEventListener].interactable = Getted
			CS.UGUIClickEventListener.Get(self.root.conditionsShowPanel.sourceShowFrame.Btn.gameObject,true).onClick = function (obj) 
				self.SelectSuitCfg=suitCfg
				local heroUuid=HeroModule.GetManager():Get(self.Data.heroid).uuid
				local suitId=suitCfg.suitId
				if suitCfg.suitId==0 then
					local _cfg=HeroHelper.GetCfgByShowMode(self.Data.heroid,self.showMode)
					suitId=_cfg.suitId
				end
				HeroModule.ChangeSpecialStatus(heroUuid,suitId,suitCfg.suitId~=0 and true)
				self.root.conditionsShowPanel.gameObject:SetActive(false)
			end
		else
			self.root.conditionsShowPanel.sourceShowFrame[SGK.LuaBehaviour]:Call("ShowSourceTitle",suitCfg.conditions[1],nil,true)
		end

		CS.UGUIClickEventListener.Get(self.root.conditionsShowPanel.sourceShowFrame.ExitBtn.gameObject).onClick = function (obj) 
			self.root.conditionsShowPanel.gameObject:SetActive(false)
		end
	end
	CS.UGUIClickEventListener.Get(self.root.conditionsShowPanel.mask.gameObject,true).onClick = function (obj) 
		self.root.conditionsShowPanel.gameObject:SetActive(false)
	end
end

function View:GetModePosCfg(Idx)
	local suitCfg=self.SuitList[Idx]
	local Pos,Scale = DATABASE.GetBattlefieldCharacterTransform(tostring(suitCfg.showMode), "ui");
	local position = {x = Pos.x*100,y=Pos.y*100,z=0}
	return position,Scale
end

function View:OnSuitInfoChange()
	local hero=HeroModule.GetManager():Get(self.Data.heroid)
	self.showMode=hero.showMode
	--self.UIDragIconScript:ItemRef()
end

function View:OnDestroy()
	self.savedValues.Data=self.Data
	self.savedValues.SuitIndex=self.SuitIndex
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"SHOP_INFO_CHANGE",
		"HERO_ITEM_CHANGE",
		"SHOP_BUY_SUCCEED"
	}
end

function View:onEvent(event,data)
	if event == "HERO_INFO_CHANGE" then
		if self.SelectSuitCfg then
			self:OnSuitInfoChange()
			self:UpdateButtonStatuShow()
			self.SelectSuitCfg=nil
		end
	elseif event == "SHOP_INFO_CHANGE" or event == "HERO_ITEM_CHANGE" then
		if not self.SelectSuitCfg then
			self:OnSuitInfoChange()	
		end
	elseif event == "SHOP_BUY_SUCCEED" then
		if self.root.conditionsShowPanel.gameObject.activeSelf then
			local hero=HeroModule.GetManager():Get(self.Data.heroid)
			self:ExchangeFashionSuit(hero)--兑换时装
			self:RefContiditonsShow()
			self:OnSuitInfoChange()
			self:UpdateButtonStatuShow()
		end

    end
end

return View




