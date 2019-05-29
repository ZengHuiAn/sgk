local MapConfig = require "config.MapConfig"
local FightModule = require "module.fightModule"
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	self.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_biaoti2")

	CS.UGUIClickEventListener.Get(self.view.Close.gameObject).onClick = function (obj) 
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj) 
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self:initGuide()
	self:updateCheckPointList(data)	
end

function View:initGuide()
    module.guideModule.PlayByType(115,0.2)
end

local difficultyCfg = {
    [1] = {pic = "pic"},
    [2] = {pic = "pic2"},
    [3] = {pic = "pic3"},
}
function View:updateCheckPointList(_quest_id)
	if not _quest_id then
		ERROR_LOG("_quest_id is nil") 
		return 
	end
	
	local fight_List = {}
	local cfg_List = MapConfig.GetFightList(_quest_id) or {}


	--tonumber(_cfg.script) ~= 1 then
	for i,v in ipairs(cfg_List) do
		local _fight_Cfg = FightModule.GetPveConfig(v.fight_id)
		local _fight_info = FightModule.GetFightInfo(v.fight_id)
		local _openStatus, _closeInfo = _fight_info:IsOpen()
		table.insert(fight_List,{
			fight_info = _fight_info,
			_openStatus = _openStatus,
			_closeInfo = _closeInfo,
			fight_Cfg = _fight_Cfg,
			fight_id = v.fight_id,
			})
	end
	--已解锁>未解锁,boss关卡>非boss关卡,噩梦>非噩梦,后期副本>前期副本
	table.sort(fight_List,function(a,b)
		if a._openStatus ~= b._openStatus then
			return a._openStatus
		end

		local a_difficultIdx = tonumber(string.sub(a.fight_id,-2,-2))
		local b_difficultIdx = tonumber(string.sub(b.fight_id,-2,-2))
		if a_difficultIdx ~= b_difficultIdx then
			return a_difficultIdx > b_difficultIdx
		end

		local a_charperId = tonumber(string.sub(a.fight_id,-4,-1))
		local b_charperId = tonumber(string.sub(b.fight_id,-4,-1))
		if a_charperId ~= b_charperId then
			return a_charperId > b_charperId
		end
	end)

	self.UIDragIconScript = self.view.Content.ScrollView[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
		local item = CS.SGK.UIReference.Setup(obj.gameObject)
		local cfg = fight_List[idx + 1]
		
		local fight_id,fight_Cfg,fight_info,_openStatus, _closeInfo = cfg.fight_id,cfg.fight_Cfg,cfg.fight_info,cfg._openStatus,cfg._closeInfo
		if fight_info and fight_Cfg then	
			item.unlock:SetActive(_openStatus)
			item.lock:SetActive(not _openStatus)

			item[CS.UGUIClickEventListener].interactable = _openStatus
			if _openStatus then
				item.unlock.Text[UI.Text].text = (fight_Cfg.count_per_day - fight_info.today_count).."/"..fight_Cfg.count_per_day
			else
				item.lock.Text[UI.Text].text = _closeInfo
			end

			--章节 fight_id 最后一位 为 节 倒数 3 4位 为章
			--倒数第二位 为 难度 0 普通 1困难 2 噩梦
			local charperId = math.floor(string.sub(fight_id,-4,-3))
			local sectionId = tonumber(string.sub(fight_id,-1))+1
			item.chapter[UI.Text].text = charperId.."-"..sectionId

			local battle_Id = fight_Cfg.battle_id
			local battle_cfg = FightModule.GetBattleConfig(battle_Id)
			if battle_cfg then
				item.name[UI.Text].text = battle_cfg.name
				local npc_id = fight_List[idx + 1].npc_id
			
				--关卡难度
				-- local difficultIdx = 0
				-- for i=1,#difficultyCfg do
				-- 	local _pic = battle_cfg[difficultyCfg[i].pic]
				-- 	local _picTab = StringSplit(_pic, "|")

				-- 	for j=1,#_picTab do
				-- 		if _picTab[j] == npc_id then
				-- 			difficultIdx = i
				-- 			break
				-- 		end
				-- 	end
				-- 	if difficultIdx ~= 0 then
				-- 		break
				-- 	end
				-- 	ERROR_LOG(npc_id,difficultIdx,sprinttb(_picTab))
				-- end
				local difficultIdx = tonumber(string.sub(fight_id,-2,-2))
				item.mark[CS.UGUISpriteSelector].index = difficultIdx
			end
			--前往
			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj) 
				DialogStack.PushPrefStact("newSelectMap/newGoCheckpoint", {gid = fight_id})
			end
		else
			ERROR_LOG("fight_Cfg is nil,id",fight_id)
		end
		obj:SetActive(true)
	end

	self.UIDragIconScript.DataCount = #fight_List
	if next(fight_List)==nil then
		ERROR_LOG("fight_List is {},questId",_quest_id)
	end   
end

function View:listEvent()
	return {
	"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event,data)
	if event == "LOCAL_GUIDE_CHANE" then
		self:initGuide()
	end
end
return View