local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local BuildShopModule = require "module.BuildShopModule"
local QuestModule = require "module.QuestModule"
local GuildSeaElectionModule = require "module.GuildSeaElectionModule"
local GuildGrabWarModule = require "module.GuildGrabWarModule"
local OpenLevelConfig = require "config.openLevel"
local ActivityConfig = require "config.activityConfig"
local buildScienceConfig = require "config.buildScienceConfig"
local BuildScienceModule = require "module.BuildScienceModule"
local BuildCityModule = require "module.BuildCityModule"

local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.updateTime = 0;
	self.status = 0;
	self.view.top.baseInfo.static_Text_lv[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo01")
	self.view.top.baseInfo.static_Text_boss[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo02")

	self:Init(data);
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

function View:Init(data)
	local map_id = data
	self.cityConfig = ActivityConfig.GetCityConfig(map_id)
	self:updateCityInfo()
end

function View:updateCityInfo()
	--城市拥有者信息
	local scienceInfo = BuildScienceModule.GetScience(self.cityConfig.map_id)
	if scienceInfo then
		self:updateOwenInfo(scienceInfo)
	else
		BuildScienceModule.QueryScience(self.cityConfig.map_id)
	end
	
	self.view.top.Icon.Image[UI.Image]:LoadSprite("icon/buildCity/"..self.cityConfig.picture)
	self.view.top.difficulty_Image[CS.UGUISpriteSelector].index = self.cityConfig.city_quality-1
	self.view.top.difficulty_Image.ClickTip.Text[UI.Text].text = SGK.Localize:getInstance():getValue("daditu_0"..self.cityConfig.city_quality)
	local listener = CS.UGUIPointerEventListener.Get(self.view.top.difficulty_Image.gameObject);
	if listener.isLongPress ~= nil then
		listener.isLongPress = true;
	end
	listener.onPointerDown = function(go, pos)
		if not self.view.top.difficulty_Image.ClickTip.activeSelf then
			self.view.top.difficulty_Image.ClickTip:SetActive(true)
			self.view.top.difficulty_Image.transform:DOScale(Vector3.one,0.1):OnComplete(function ( ... )
				self.view.top.difficulty_Image.ClickTip[UnityEngine.CanvasGroup].alpha = 1;
    		end)
		end
	end

	listener.onPointerUp = function(go, pos)
		self.view.top.difficulty_Image.ClickTip[UnityEngine.CanvasGroup].alpha = 0;
		self.view.top.difficulty_Image.ClickTip:SetActive(false)
	end

	CS.UGUIPointerEventListener.Get(self.view.top.Icon.IncomeBtn.gameObject,true).onPointerDown = function(go, pos)
		self:updateIncomeInfoShow()
	end

	CS.UGUIPointerEventListener.Get(self.view.top.Icon.IncomeBtn.gameObject, true).onPointerUp = function(go, pos)
		self.view.top.IncomePanel:SetActive(false)
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.tasks.TipBtn.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guanqiazhengduo41"),nil,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
	end
	
	CS.UGUIClickEventListener.Get(self.view.bottom.register.TipBtn.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guanqiazhengduo42"),nil,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
	end

	self:updateRegisterInfo()
	self:updateBossShow()
end

function View:updateOwenInfo(scienceInfo)
	coroutine.resume(coroutine.create(function ()
		local unionId = scienceInfo.title
		local cityOwner = false
		local cityOwnerUnionLeader = false
		local unionInfo = nil
		if unionId~= 0 then		
			unionInfo = module.unionModule.Manage:GetUnion(unionId)
			if unionInfo then
				self.view.top.baseInfo.unionName.Text[UI.Text].text = unionInfo.unionName or ""
			else
				ERROR_LOG("union is nil,id",unionId)
			end

			local uninInfo = module.unionModule.Manage:GetSelfUnion();
			if uninInfo and uninInfo.id and uninInfo.id == unionId then
				cityOwner = true
				if uninInfo.leaderId == module.playerModule.GetSelfID()  then
					cityOwnerUnionLeader = true
				end
			end	
		else
			self.view.top.baseInfo.unionName.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cityConfig.type)	
		end
		--占领城市的公会会长才可以发布任务
		self.view.bottom.tasks.changeBtn:SetActive(cityOwnerUnionLeader)

		--科技有没有激活，需要看城市繁荣度有没有超过科技需求等级
		self.cityContructQuestLevel = scienceInfo.data
		--查到城市归属后 查到城市归属后询城市繁荣度
		local info = QuestModule.CityContuctInfo(nil,true)
		if info and info.boss and next(info.boss)~=nil then
			self:updateDcity_exp(info)
		else
			QuestModule.CityContuctInfo(true)
		end
	end))
end

function View:showTechnologyDesc(item,desc)
	self.view.top.Icon.technologyDesc.Text[UI.Text].text = desc
	self.view.top.Icon.technologyDesc.transform:SetParent(item.transform)
	self.view.top.Icon.technologyDesc.transform.localPosition = Vector3(-30,60,0)
	self.view.top.Icon.technologyDesc:SetActive(true)
end

function View:updateIncomeInfoShow()
	local businessInfo = BuildCityModule.GetCityBusinessInfo(self.cityConfig.map_id) or {}
	self.view.top.IncomePanel:SetActive(true)

	businessInfo[1] = businessInfo[1] or {num=0,value=0}
	self.view.top.IncomePanel.content[1][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo27")
	self.view.top.IncomePanel.content[2][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo25",businessInfo[1].num)
	self.view.top.IncomePanel.content[3][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo26",businessInfo[1].value)

	businessInfo[2] = businessInfo[2] or {num=0,value=0}
	self.view.top.IncomePanel.content[4][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo28")
	self.view.top.IncomePanel.content[5][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo25",businessInfo[2].num)
	self.view.top.IncomePanel.content[6][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo26",businessInfo[2].value)

	businessInfo[3] = businessInfo[3] or {num=0,value=0}
	self.view.top.IncomePanel.content[7][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo29")
	self.view.top.IncomePanel.content[8][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo25",businessInfo[3].num)
	self.view.top.IncomePanel.content[9][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo26",businessInfo[3].value)
end

local build_Type_To_OpenLevel ={[44]=4001,[43]=4004,[42]=4002,[41]=4003,}
local function GetCurrCityQuest()
	local cityQuest = nil
	for k,_ in pairs(build_Type_To_OpenLevel) do--类型 41 到 44的任务为建设任务	
		local allQuests = QuestModule.GetList(k,0);
		for _,v in ipairs(allQuests) do
			cityQuest = v
			break
		end
		if cityQuest then
			break
		end
	end
	return cityQuest
end

function View:UpdateTaskInfo(info,technologyLv,technologyCfgGroup,lastSetTime)
	local questGroup = info.boss[self.cityConfig.type] and info.boss[self.cityConfig.type].quest_group
	local taskCfg = ActivityConfig.GetCityTaskGroupConfig(questGroup)
	if taskCfg then
		local addValue = 0
		if technologyCfgGroup then
			for i=1,#technologyCfgGroup do
				if technologyCfgGroup[i].skill_level == technologyLv then
					addValue = technologyCfgGroup[i].param
					break
				end
			end
		end
		local questInfo = QuestModule.CityContuctInfo()
		local questOwener = questInfo.current_city

		local today_count = questInfo and questInfo.today_count or 0
		--self.view.bottom.tasks.content[1][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo30")..taskCfg.name.."("..today_count.."/".."20)"
		self.view.bottom.tasks.content[1][UI.Text].text = string.format("%s%s ( %s/20 )",SGK.Localize:getInstance():getValue("guanqiazhengduo30"),taskCfg.name,today_count)
		local showValue = math.floor((taskCfg.basis_reward+addValue)/100).."%"
		self.view.bottom.tasks.content[2][UI.Text]:TextFormat(taskCfg.play_des,showValue)
		self.view.bottom.tasks.content[3][UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo31")

		for i=1,self.view.bottom.tasks.content.rewards.transform.childCount do
			self.view.bottom.tasks.content.rewards.transform:GetChild(i-1).gameObject:SetActive(false)
		end

		local prefab = self.view.bottom.tasks.content.rewards.itemPrefab --SGK.ResourcesManager.Load("prefabs/IconFrame")
		if taskCfg.reward_exhibition1~=0 then
			local cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM,taskCfg.reward_exhibition1,nil,0)
			if cfg then
				local item = GetCopyUIItem(self.view.bottom.tasks.content.rewards,prefab,1)
				utils.IconFrameHelper.Create(item.IconFrame, {customCfg = cfg,showDetail=true})
			end
		end

		if taskCfg.reward_exhibition2~=0 then
			local cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM,taskCfg.reward_exhibition2,nil,0)
			if cfg then
				local item = GetCopyUIItem(self.view.bottom.tasks.content.rewards,prefab,2)
				utils.IconFrameHelper.Create(item.IconFrame, {customCfg = cfg,showDetail=true})
			end
		end
		-- ERROR_LOG(info.current_city,self.cityConfig.type,sprinttb(info))
		self.cityQuest = GetCurrCityQuest()
		self.view.bottom.tasks.getBtn:SetActive(questOwener ~= self.cityConfig.type or not self.cityQuest)
		self.view.bottom.tasks.goToBtn:SetActive(questOwener == self.cityConfig.type and self.cityQuest)


		CS.UGUIClickEventListener.Get(self.view.bottom.tasks.goToBtn.gameObject).onClick = function (obj)	
			local teamInfo = module.TeamModule.GetTeamInfo();
			if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
				--不在一个队伍中或自己为队长
				if self.cityQuest then
					DialogStack.CleanAllStack()
					QuestModule.StartQuestGuideScript(self.cityQuest.cfg, true)
				end
			else
				showDlgError(nil,"你正在队伍中，无法进行该操作")
			end
		end

		self.view.bottom.tasks.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton02")
		CS.UGUIClickEventListener.Get(self.view.bottom.tasks.getBtn.gameObject).onClick = function (obj)
			self:AcceptQuest(questGroup)
		end

		self.view.bottom.tasks.changeBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton03")
		CS.UGUIClickEventListener.Get(self.view.bottom.tasks.changeBtn.gameObject).onClick = function (obj)	
			DialogStack.PushPrefStact("buildCity/setBuildCityQuest",{questGroup,addValue,technologyLv,self.cityConfig.map_id,self.cityConfig.type,lastSetTime});
		end
	end
end

--建设城市奖励计数道具
local CityContuctSingleStatisticsId = 2041
local CityContuctDoubleStatisticsId = 1041
function View:AcceptQuest(questGroup)
	if OpenLevelConfig.GetStatus(build_Type_To_OpenLevel[questGroup]) then
		--建设城市
		local cityQuest = nil
		for k,_ in pairs(build_Type_To_OpenLevel) do
			local allQuests = QuestModule.GetList(k,0);
			for _,v in ipairs(allQuests) do
				if build_Type_To_OpenLevel[v.type] then--类型 41 到 44的任务为建设任务
					cityQuest = v
					break
				end
			end
			if cityQuest then
				break
			end
		end
		
		if not cityQuest then
			if QuestModule.CityContuctInfo().today_count < 20 then
				if module.ItemModule.GetItemCount(CityContuctDoubleStatisticsId) <= 0 and module.ItemModule.GetItemCount(CityContuctSingleStatisticsId) >= 10 then
					showDlgMsg(SGK.Localize:getInstance():getValue("jiansherenwu_01"), 
						function ()
							self.view.bottom.tasks.getBtn[CS.UGUIClickEventListener].interactable = false
							self.questGroup = questGroup
							QuestModule.CityContuctAcceptQuest(self.cityConfig.type)
						end, 
						function () end, 
						SGK.Localize:getInstance():getValue("common_queding_01"), --确定
						SGK.Localize:getInstance():getValue("common_cancle_01") --取消
					)
				else
					self.view.bottom.tasks.getBtn[CS.UGUIClickEventListener].interactable = false
					self.questGroup = questGroup
					QuestModule.CityContuctAcceptQuest(self.cityConfig.type)
				end
			else
				showDlg(nil,"您今日已完成20次建设关卡任务，无法领取新的任务")
			end
		else
			showDlgMsg(SGK.Localize:getInstance():getValue("guanqiazhengduo44"), 
				function ()
					self.ChangeCityQuest = {cancelUuid = cityQuest.uuid,acceptType = self.cityConfig.type}
					self.ChangeCityQuest.sn = utils.NetworkService.Send(11043, {nil,cityQuest.uuid});
				end, 
				function ()
				end, 
				SGK.Localize:getInstance():getValue("common_queding_01"), --确定
				SGK.Localize:getInstance():getValue("common_cancle_01"), --取消
				nil, nil,SGK.Localize:getInstance():getValue("guanqiazhengduo43"))
		end
	else	
		self:checkStatus(questGroup)
	end
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

function View:updateRegisterInfo()
	self.updateTime1, self.updateTime2 = -1, -1;
	coroutine.resume(coroutine.create( function ()
		local status = 0; --0没有比赛信息 1报名未开始 2正在报名 3报名结束未开始战斗 4正在进行海选比赛 5正在进行决赛 6比赛结束  7无人参赛
		local allInfo = GuildSeaElectionModule.GetAll();
		if allInfo[self.cityConfig.map_id] and allInfo[self.cityConfig.map_id].apply_begin_time ~= -1 then
			local warInfo = GuildGrabWarModule.Get(self.cityConfig.map_id);
			if warInfo.war_info.attacker_gid == nil and allInfo[self.cityConfig.map_id].final_begin_time >= Time.now() then
				warInfo:Query();
			end
			local cityInfo = module.BuildScienceModule.QueryScience(self.cityConfig.map_id);
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo04","")
			if warInfo.final_winner ~= -1 then
				status = 6
			elseif allInfo[self.cityConfig.map_id].apply_begin_time > Time.now() then	--尚未到报名时间
				status = 1;
			elseif allInfo[self.cityConfig.map_id].apply_end_time > Time.now() then
				status = 2;
			elseif allInfo[self.cityConfig.map_id].fight_begin_time > Time.now() then
				status = 3;
			elseif #allInfo[self.cityConfig.map_id].apply_list == 0 then
				status = 7;
			elseif #allInfo[self.cityConfig.map_id].apply_list == 1 and (cityInfo.title == 0 or cityInfo.title == allInfo[self.cityConfig.map_id].apply_list[1]) then --没人占领的城市，只有一个公会报名
				status = 6
			elseif allInfo[self.cityConfig.map_id].final_begin_time > Time.now() then
				status = 4;
			else
				status = 5;
			end
		end
		self.status = status;
		-- coroutine.resume(coroutine.create(function ()
		-- 	local side1_guild = utils.Container("UNION"):Get(10000390); --10000390 10000415
		-- 	local side2_guild = utils.Container("UNION"):Get(10000419); --10000419 10000418
		-- 	print("side1_guild", sprinttb(side1_guild))
		-- 	print("side2_guild", sprinttb(side2_guild))
		-- end))
		print("海选信息", self.cityConfig.map_id, status,Time.now(), sprinttb(allInfo[self.cityConfig.map_id]))
		if status == 0 then
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo32","")
			self.view.bottom.register.starTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo05","")
			self.view.bottom.register.leftTime.Text[UI.Text].text = "尚未开始报名"
			self.view.bottom.register.starTime.Text[UI.Text].text = "暂无争夺战"
			self.view.bottom.register.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton04")
			SetButtonStatus(false, self.view.bottom.register.btn);
		elseif status == 1 then
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo32","")
			self.view.bottom.register.starTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo05","")
			self.updateTime1 = allInfo[self.cityConfig.map_id].apply_begin_time - Time.now();
			self.view.bottom.register.leftTime.Text[UI.Text].text = GetTimeFormat(self.updateTime1, 2);
			self.view.bottom.register.starTime.Text[UI.Text].text = "20:30:00"
			SetButtonStatus(false, self.view.bottom.register.btn);
		elseif status == 2 then
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo04","");
			self.view.bottom.register.starTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo05","")
			self.updateTime1 = allInfo[self.cityConfig.map_id].apply_end_time - Time.now();
			self.updateTime2 = allInfo[self.cityConfig.map_id].fight_begin_time - Time.now();
			self.view.bottom.register.leftTime.Text[UI.Text].text = GetTimeFormat(self.updateTime1, 2);
			self.view.bottom.register.starTime.Text[UI.Text].text = "20:30:00";
			if GuildSeaElectionModule.CheckApply(self.cityConfig.map_id) == 0 then
				self.view.bottom.register.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton04")
				if GuildSeaElectionModule.CanApply() == 0 then
					SetButtonStatus(true, self.view.bottom.register.btn);
				else
					SetButtonStatus(false, self.view.bottom.register.btn);
				end
			else
				self.view.bottom.register.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton13")
				SetButtonStatus(true, self.view.bottom.register.btn);
			end
		elseif status == 3 or status == 4 or status == 5 then
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo04","");
			self.view.bottom.register.leftTime.Text[UI.Text].text = "报名已结束";
			if status == 3 then
				self.view.bottom.register.starTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo05","")
				self.updateTime2 = allInfo[self.cityConfig.map_id].fight_begin_time - Time.now();
				self.view.bottom.register.starTime.Text[UI.Text].text = "20:30:00";
			elseif status == 4 then
				self.view.bottom.register.starTime[UI.Text].text = "距离决赛开始："
				self.updateTime2 = allInfo[self.cityConfig.map_id].final_begin_time - Time.now();
				self.view.bottom.register.starTime.Text[UI.Text].text = GetTimeFormat(self.updateTime2, 2);
			elseif status == 5 then
				self.view.bottom.register.starTime[UI.Text].text = "争夺战决赛："
				self.view.bottom.register.starTime.Text[UI.Text].text = "决赛进行中"
			end
			-- if GuildSeaElectionModule.CheckApply(self.cityConfig.map_id) == 0 then
			-- 	self.view.bottom.register.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton04")
			-- 	SetButtonStatus(false, self.view.bottom.register.btn);
			-- else
			-- end
			if status == 5 then
				self.view.bottom.register.btn.Text[UI.Text].text = "前往"
			else
				self.view.bottom.register.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton13")
			end
			SetButtonStatus(true, self.view.bottom.register.btn);
		elseif status == 6 then
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo04","");
			self.view.bottom.register.leftTime.Text[UI.Text].text = "报名已结束";
			self.view.bottom.register.starTime[UI.Text].text = "争夺战决赛："
			self.view.bottom.register.starTime.Text[UI.Text].text = "比赛已结束";
			self.view.bottom.register.btn.Text[UI.Text].text = "比赛结束"
			SetButtonStatus(false, self.view.bottom.register.btn);
		elseif status == 7 then
			self.view.bottom.register.leftTime[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo04","");
			self.view.bottom.register.leftTime.Text[UI.Text].text = "报名已结束";
			self.view.bottom.register.starTime[UI.Text].text = "争夺战战况："
			self.view.bottom.register.starTime.Text[UI.Text].text = "因无人参赛取消";
			SetButtonStatus(false, self.view.bottom.register.btn);
		end
		CS.UGUIClickEventListener.Get(self.view.bottom.register.btn.gameObject).onClick = function (obj)	
			local warInfo = GuildGrabWarModule.Get(self.cityConfig.map_id);
			if allInfo[self.cityConfig.map_id].apply_end_time <= Time.now() then
				if allInfo[self.cityConfig.map_id].final_begin_time <= Time.now() then
					SceneStack.EnterMap(self.cityConfig.map_id);
				else
					DialogStack.PushPref("guildGrabWar/guildGrabWarReport", {map_id = self.cityConfig.map_id})
				end
			else
				local uninInfo = module.unionModule.Manage:GetSelfUnion();
				local memberInfo = module.unionModule.Manage:GetSelfInfo()
				if uninInfo and uninInfo.id then
					if GuildSeaElectionModule.CheckApply(self.cityConfig.map_id) == 0 then
						if memberInfo == nil or memberInfo.title ~= 1 then
							showDlgError(nil, "你不是工会会长")
							return;
						end
						local flag = GuildSeaElectionModule.CanApply();
						if flag == 0 then
							if not self:CheckHaveCity() then
								showDlg(self.view,"确定要报名参加争夺战吗？",function()
									GuildSeaElectionModule.Apply(self.cityConfig.map_id)
								end, function() end)
							else
								showDlg(self.view, SGK.Localize:getInstance():getValue("guanqiazhengduo39"), function()
									GuildSeaElectionModule.Apply(self.cityConfig.map_id)
								end, function() end)
							end
						elseif flag == 1 then
							showDlgError(nil, "你的公会已经报名了今天的争夺战");
						elseif flag == 2 then
							showDlgError(nil, "你的公会已经作为防守方参加了今天的争夺战");
						end
					else
						DialogStack.PushPref("guildGrabWar/guildGrabWarReport", {map_id = self.cityConfig.map_id})
					end
				else
					showDlgError(nil, "尚未加入公会")
				end
			end
		end
	end ))
end

function View:CheckHaveCity()
	local uninInfo = module.unionModule.Manage:GetSelfUnion();
	if uninInfo and uninInfo.id then
		local cityCfg = ActivityConfig.GetCityConfig().map_id;
		for k,v in pairs(cityCfg) do
			local cityInfo = module.BuildScienceModule.QueryScience(v.map_id);
			local owner = cityInfo and cityInfo.title or 0;
			if owner == uninInfo.id then
			   return true; 
			end		
		end
	end
	return false;
end

local quest_technology_Type = 7
function View:updateDcity_exp(info)
	local cityBudildCfg = ActivityConfig.GetBuildCityConfig(self.cityConfig.type)
	local lastLv,exp,_value=ActivityConfig.GetCityLvAndExp(info,self.cityConfig.type)
	if lastLv and exp and _value then
		self.view.top.baseInfo.lv[UI.Text].text=tostring(lastLv)
		self.view.top.baseInfo.Slider[CS.UnityEngine.UI.Slider].value =exp/_value
		self.view.top.baseInfo.Slider.Text[UI.Text].text=string.format("%s/%s",exp,_value)
	end

	--获取影响任务的科技类型配置
	if self.cityContructQuestLevel then
		local technologyCfgGroup = buildScienceConfig.GetScienceConfig(self.cityConfig.map_id,quest_technology_Type);
		local technologyCfg = technologyCfgGroup and technologyCfgGroup[1]
		--只有当城市繁荣度超过科技需求等级时 科技才激活
		local technologyLv = 0
		--ERROR_LOG("technologyCfg.city_level<=lastLv",self.cityContructQuestLevel,technologyCfg.city_level,lastLv)
		if technologyCfg.city_level<=lastLv then
			technologyLv = self.cityContructQuestLevel[quest_technology_Type] or 0
		end

		local lastSetTime = 0
		if info.boss and next(info.boss)~=nil then
        	lastSetTime = info.boss[self.cityConfig.type] and info.boss[self.cityConfig.type].lastSetTime or 0
    	end

		self:UpdateTaskInfo(info,technologyLv,technologyCfgGroup,lastSetTime)

		self:updateCityScience(lastLv)
	end
end

function View:updateCityScience(cityLv)
	local technologyStr = self.cityConfig.core_technology
	local technologyGroup = StringSplit(self.cityConfig.core_technology,"|")

	for i=1,self.view.top.Icon.technologyContent.transform.childCount do
		self.view.top.Icon.technologyContent.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	for i=1,#technologyGroup do
		local technologyType = tonumber(technologyGroup[i])
		local technologyCfgGroup = buildScienceConfig.GetScienceConfig(self.cityConfig.map_id,technologyType);
		local technologyLv = self.cityContructQuestLevel[technologyType]
		--城市繁荣度超过科技激活需要的等级
		if technologyLv then
			local technologyCfg = technologyCfgGroup and technologyCfgGroup[technologyLv+1]
			if technologyLv>=1 and technologyCfg and technologyCfg.city_level<=cityLv then
				local item = GetCopyUIItem(self.view.top.Icon.technologyContent,self.view.top.Icon.technologyContent[1],i)
				if item then
					item[UI.Image]:LoadSprite("icon/"..technologyCfg.icon)
					CS.UGUIPointerEventListener.Get(item.gameObject,true).onPointerDown = function(go, pos)
						self:showTechnologyDesc(item,technologyCfg.describe)
					end

					CS.UGUIPointerEventListener.Get(item.gameObject,true).onPointerUp = function(go, pos)
						self.view.top.Icon.technologyDesc:SetActive(false)
					end
				else
					ERROR_LOG("technologyCfg is nil,",self.cityConfig.map_id,technologyType)
				end
			end
		end
	end
end

function View:updateBossShow()
	local monster_npc = self.cityConfig.monster_npc and self.cityConfig.monster_npc ~= 0 and self.cityConfig.monster_npc
	self.view.bottom.boss.NoMonster:SetActive(not monster_npc)
	self.view.bottom.boss.MonsterInfo:SetActive(not not monster_npc)
	if monster_npc then
		self.view.bottom.boss.MonsterInfo[SGK.LuaBehaviour]:Call("InitUI",self.cityConfig.map_id)
	end
end

function View:Update()
	if Time.now() - self.updateTime > 0 then
		self.updateTime = Time.now();
		-- print("时间", self.updateTime1, self.updateTime2)
		if self.updateTime1 and self.updateTime1 >= 0 then
			self.view.bottom.register.leftTime.Text[UI.Text].text = GetTimeFormat(self.updateTime1, 2);
			if self.updateTime1 == 0 then
				self:updateRegisterInfo();
			else
				self.updateTime1 = self.updateTime1 - 1;
			end
		end
		if self.updateTime2 and self.updateTime2 >= 0 then
			if self.status == 4 or self.status == 5 then
				self.view.bottom.register.starTime.Text[UI.Text].text = GetTimeFormat(self.updateTime2, 2);
			end
			if self.updateTime2 == 0 then
				self:updateRegisterInfo();
				DispatchEvent("LOCAL_CITYWAR_STATUS_CHANGE");
			else
				self.updateTime2 = self.updateTime2 - 1;
			end
		end
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"CITY_CONTRUCT_INFO_CHANGE",
		"LOCAL_SLESET_MAPID_CHANGE",
		"GUILD_APPLY_FOR_SEA_ELECTION",
		"GUILD_GRABWAR_SEAINFO_CHANGE",
		"QUERY_MAP_DEPOT",
		"QUERY_SCIENCE_SUCCESS",
		"CITY_CONTUCT_ACCEPT_SUCCEED",
		"CITY_CONTUCT_ACCEPT_FAILD",
		"CITY_BUSINESS_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "CITY_CONTRUCT_INFO_CHANGE" then--城市建设信息变化
		if data and self.ChangeCityQuest and self.ChangeCityQuest.sn and data == self.ChangeCityQuest.sn then
			print("放弃任务成功"..self.ChangeCityQuest.cancelUuid)
			if self.ChangeCityQuest.acceptType then
				QuestModule.CityContuctAcceptQuest(self.ChangeCityQuest.acceptType)
				print("更换任务"..self.ChangeCityQuest.acceptType)
				self.ChangeCityQuest = {}
			end
		else
			local info = module.QuestModule.CityContuctInfo()
			if info and info.boss and next(info.boss)~=nil then
				self:updateDcity_exp(info)
			end
		end
	elseif event =="LOCAL_SLESET_MAPID_CHANGE" then--切换城市
		if data then
			self.cityConfig = ActivityConfig.GetCityConfig(data)
			self:updateCityInfo()
		end
	elseif event == "GUILD_APPLY_FOR_SEA_ELECTION" then
		local uninInfo = module.unionModule.Manage:GetSelfUnion();
		if uninInfo and uninInfo.id and uninInfo.id == data then
			self:updateRegisterInfo();
		end
	elseif event == "GUILD_GRABWAR_SEAINFO_CHANGE" then
		self:updateRegisterInfo();
	-- elseif event == "QUERY_MAP_DEPOT" then
	-- 	if data and self.cityConfig and data == self.cityConfig.map_id then
	-- 		local cityDepotResource = BuildShopModule.GetMapDepot(self.cityConfig.map_id)
	-- 		self:InResourcesShow(cityDepotResource)
	-- 	end
	elseif event == "QUERY_SCIENCE_SUCCESS" then--查询 城市归属 和 科技 统一处理
		if data and data == self.cityConfig.map_id then
			local scienceInfo = BuildScienceModule.GetScience(self.cityConfig.map_id)
			if scienceInfo then
				self:updateOwenInfo(scienceInfo)
			else
				ERROR_LOG("scienceInfo is nil",self.cityConfig.map_id)
			end
		end
	elseif event =="CITY_CONTUCT_ACCEPT_SUCCEED" then
		if data == self.cityConfig.type then
			self.view.bottom.tasks.getBtn[CS.UGUIClickEventListener].interactable = true
			showDlgError(nil,"建设城市任务领取成功")
			self.cityQuest = GetCurrCityQuest()
			local questOwener = QuestModule.CityContuctInfo().current_city
			self.view.bottom.tasks.getBtn:SetActive(questOwener ~= self.cityConfig.type or not self.cityQuest)
			self.view.bottom.tasks.goToBtn:SetActive(questOwener == self.cityConfig.type and self.cityQuest)
		end
	elseif event == "CITY_CONTUCT_ACCEPT_FAILD" then
		if self.cityConfig.type == data then
			ERROR_LOG("任务领取失败",data)
			self.view.bottom.tasks.getBtn[CS.UGUIClickEventListener].interactable = true
		end
	elseif event == "CITY_BUSINESS_INFO_CHANGE" then
		if data and data == self.cityConfig.map_id then
			self:updateIncomeInfoShow()
		end
	end
end

return View;
