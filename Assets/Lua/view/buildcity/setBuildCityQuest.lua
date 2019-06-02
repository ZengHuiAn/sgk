local ActivityConfig = require "config.activityConfig"
local BuildCityModule = require "module.BuildCityModule"
local View = {};

function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view
	self.quest_type = data and data[1]
	self.AddValue = data and data[2]
	self.technologyLv = data and data[3]
	self.map_id = data and data[4]
	self.cityType = data and data[5]
	self.lastSetTime = data and data[6]
	self:InitView()
end

local CD = 60*60*2--60*60*2
function View:InitView()
	self.update = (module.Time.now()-self.lastSetTime)<CD
	self.view.Content.tip:SetActive(self.update)

	self.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo12")
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function()
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.Close.gameObject).onClick = function()
		DialogStack.Pop()
	end

	local _taskGroupCfg = ActivityConfig.GetCityTaskGroupConfig()
	local taskGroupCfg = {}
	for k,v in pairs(_taskGroupCfg) do
		table.insert(taskGroupCfg,v)
	end

	self.UIDragIconScript = self.view.Content.ScrollView[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		local item = CS.SGK.UIReference.Setup(obj)
		item:SetActive(true)
		local cfg = taskGroupCfg[idx+1]

		item.title.name[UI.Text].text = cfg.name

		item.title.lv[UI.Text].text = self.technologyLv~=0 and "Lv"..self.technologyLv or "科技未激活"

		item.union.Text[UI.Text].text = cfg. guild_des

		local showValue = math.floor((cfg.basis_reward+self.AddValue)/100).."%"
		item.person.Text[UI.Text]:TextFormat(cfg.play_des,showValue)

		item.status.btn:SetActive(self.quest_type~=cfg.quest_type)
		item.status.Text:SetActive(self.quest_type==cfg.quest_type)
		item.status.btn[CS.UGUIClickEventListener].interactable = not self.update
		CS.UGUIClickEventListener.Get(item.status.btn.gameObject).onClick = function()
			item.status.btn[CS.UGUIClickEventListener].interactable = false
			BuildCityModule.SetCityQuest(self.map_id,cfg.quest_type)					
		end
	end)
	
	self.UIDragIconScript.DataCount = #taskGroupCfg
end

function View:Update()
	if self.update then
		local leftTime = module.Time.now()-self.lastSetTime
		if leftTime <= CD then
			local time = CD-leftTime
			local showTime =string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
			self.view.Content.tip[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo03",showTime)
		else
			self.view.Content.tip:SetActive(false)
			self.update = false
			self.UIDragIconScript:ItemRef()
		end
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"SET_CITY_QUEST_SUCCEED",
		"CITY_CONTRUCT_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "SET_CITY_QUEST_SUCCEED" then
		if data and data[1] == self.map_id then
			showDlgError(nil,"发布成功")
		end
	elseif event == "CITY_CONTRUCT_INFO_CHANGE" then--城市建设信息变化
		local info = module.QuestModule.CityContuctInfo()
		if info and info.boss and next(info.boss)~=nil then
			self.quest_type = info.boss[self.cityType] and info.boss[self.cityType].quest_group
			self.lastSetTime = info.boss[self.cityType] and info.boss[self.cityType].lastSetTime or self.lastSetTime
			self.update = (module.Time.now()-self.lastSetTime)<CD
			self.view.Content.tip:SetActive(self.update)
			self.UIDragIconScript:ItemRef()
		end
	end
end

return View;