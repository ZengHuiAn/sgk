local ActivityConfig = require "config.activityConfig"
local battleCfg = require "config.battle"
local QuestModule = require "module.QuestModule"
local OpenLevelConfig = require "config.openLevel"
local BuildScienceModule = require "module.BuildScienceModule"
local View = {};

function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
end

local effectType = 8--冒险者协会
function View:InitUI(data)
	self.map_id = data or 30
	self.cityCfg = ActivityConfig.GetCityConfig(self.map_id)

	local bossIcon = self.cityCfg.monster_picture~="0" and self.cityCfg.monster_picture or "19055_bg"
	self.view.Icon[UI.Image]:LoadSprite("buildCity/" ..bossIcon)

	self:InitView()
end

function View:InitView()
	local scienceInfo = BuildScienceModule.GetScience(self.map_id)
	local lockStatus = scienceInfo and scienceInfo.data and scienceInfo.data[effectType] and scienceInfo.data[effectType]>0
	self.view.locked:SetActive(not lockStatus)
	self.view.unLock:SetActive(not not lockStatus)

	if self.view.unLock.activeSelf then
		self.view.Icon[UI.Image].material = nil
		self.info = module.QuestModule.CityContuctInfo()
		if self.info and self.info.boss and next(self.info.boss)~=nil then
			self:InMonstInfo()
		end
	end

	if self.view.locked.activeSelf then
		self.view.Icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
		self.view.locked.tip[UI.Text].text = SGK.Localize:getInstance():getValue("chengshijianshe_02")
	end
end

local build_Type_To_OpenLevel ={[44]=4001,[43]=4004,[42]=4002,[41]=4003}
function View:InMonstInfo()
	local _view = self.view.unLock
	self.info = module.QuestModule.CityContuctInfo()

	for i=1,_view.skillContent.transform.childCount do
		_view.skillContent.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	local lastLv,exp,_value = ActivityConfig.GetCityLvAndExp(self.info,self.cityCfg.type)
	if lastLv and exp and _value then
		local function updateMonstInfo(id,level)
			local _roleCfg = battleCfg.LoadNPC(id, level)
			local _info = ""
			if _roleCfg then
				if _roleCfg.skills and next(_roleCfg.skills) then
					for i=1,#_roleCfg.skills do
						if _roleCfg.skills[i] then
							local _skillItem = utils.SGKTools.GetCopyUIItem(_view.skillContent,_view.skillContent[1],i)
							_skillItem[UI.Image]:LoadSprite("icon/".._roleCfg.skills[i].icon)

							local listener = CS.UGUIPointerEventListener.Get(_skillItem.gameObject);
							if listener.isLongPress ~= nil then
								listener.isLongPress = true;
							end

							listener.onPointerDown = function(go, pos)
								if not self.view.unLock.skillView.activeSelf then
					    			self.view.unLock.skillView.arrow.transform:SetParent(_skillItem.transform, false)
									self.view.unLock.skillView.arrow.transform.localPosition = Vector3(0,40,0)
									self.view.unLock.skillView.arrow:SetActive(true)
									self:updateSkillShow(_roleCfg.skills[i])
								end
							end

							listener.onPointerUp = function(go, pos)
								self.view.unLock.skillView.arrow:SetActive(false)
								self.view.unLock.skillView:SetActive(false)
							end
						end
					end
				end
				_view.name[UI.Text].text = "Lv"..level.." ".._roleCfg.name
			end

			CS.UGUIClickEventListener.Get(_view.rewardBtn.gameObject).onClick = function (obj)
				DialogStack.PushPref("buildCity/rewardShow",{cityType = self.cityCfg.type,name = _roleCfg.name,cityLv = lastLv})
			end
		end

		local cityLvCfg = ActivityConfig.GetBuildCityConfig(self.cityCfg.type,lastLv)
		for k,v in pairs(cityLvCfg.squad) do
			if v.pos == 11 then
				updateMonstInfo(v.roleId,v.level)
				break
			end
		end

		local questGroup = self.info.boss[self.cityCfg.type] and self.info.boss[self.cityCfg.type].quest_group
		CS.UGUIClickEventListener.Get(_view.btn.gameObject,true).onClick = function (obj)
			if OpenLevelConfig.GetStatus(build_Type_To_OpenLevel[self.cityCfg.type]) then
				utils.SGKTools.Map_Interact(self.cityCfg.monster_npc)
			else	
				self:checkStatus(questGroup)
			end
		end
	end

	CS.UGUIClickEventListener.Get(_view.TipBtn.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("chengshijianshe_01"),nil,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
	end
end

function View:updateSkillShow(cfg)
	self.view.unLock.skillView:SetActive(true)
	self.view.unLock.skillView.Head.skillName[UI.Text].text = cfg.name

	self.view.unLock.skillView.Head.hurtTypeIcon:SetActive(cfg.consume_value and cfg.consume_value ~= 0)
	self.view.unLock.skillView.Head.hurtTypeText[UI.Text].text = cfg.consume_value and cfg.consume_value ~= 0 and cfg.consume_value or ""

	self.view.unLock.skillView.Head.attTypeText[UI.Text].text = "主动"
	self.view.unLock.skillView.desc[UI.Text].text = cfg.desc 
end

--检查任务不能接的原因
function View:checkStatus(questGroup)
	local _cfg = OpenLevelConfig.GetCfg(build_Type_To_OpenLevel[questGroup]);
	if _cfg then
		if module.playerModule.Get().level >= _cfg.open_lev then
			for j=1,1 do						
				if _cfg["event_type"..j] == 1 then
					if _cfg["event_id"..j] ~= 0 then
						local _quest = module.QuestModule.Get(_cfg["event_id"..j])
						if not _quest or _quest.status ~=1 then
							local _questCfg=module.QuestModule.GetCfg(_cfg["event_id"..j])
							if _questCfg then
								showDlgError(nil,string.format("完成任务 <color=#FF1A1AFF>(%s)</color>解锁",_questCfg.name))
							else
								ERROR_LOG("任务",_cfg["event_id"..j],"不存在")
							end
						end
					end
				end
			end
		else
			showDlgError(nil,string.format("<color=#FF1A1AFF>%s级</color>开启",_cfg.open_lev));
		end
	end	
end

function View:listEvent()
	return {
		"QUERY_SCIENCE_SUCCESS",
	}
end

function View:onEvent(event,data)
	if event == "QUERY_SCIENCE_SUCCESS" then--查询 城市归属 和 科技 统一处理
		if data and data == self.map_id then
			self:InitView()
		end
	end
end
 
return View;