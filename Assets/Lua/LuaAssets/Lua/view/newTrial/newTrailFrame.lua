local trialModule = require "module.trialModule"
local trialTowerConfig = require "config.trialTowerConfig"
local fightModule = require "module.fightModule"

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	if not self.CurrencyChat then
        local CurrencyChat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.chat.transform)
        self.CurrencyChat = CS.SGK.UIReference.Setup(CurrencyChat.gameObject)
    end
 	self.num = 1
 	self:initData()
 	self:initClick()
 	self:initView()
 	self:initMove()
end

function View:initData()
	local MapId = SceneStack.MapId()
	self.allGiftTab = {}
	-- local index = (MapId%500 - 1)*10+self.num
	self.npc_confs = utils.MapHelper.GetConfigTable("all_npc","gid")
	local current,cfg = trialModule.GetBattleConfig();
	self.cfg = cfg
	-- self.currentGid = current.gid
	self.gid = current.gid
	self.towerCfg = trialTowerConfig.GetConfig(self.gid)
	self.saveGid = trialModule.SaveLayarGid()
	if self.towerCfg.map_npc_gid2 ~= 0 then
		self.view.bottom.NPCHelp:SetActive(true)
	else
		self.view.bottom.NPCHelp:SetActive(false)
	end
end

function View:initMove()
	if self.saveGid ~= 0 and self.gid ~= self.saveGid then
		self:Move()
		trialModule.SaveLayarGid(self.gid)
	end
end

function View:setClick(bool)
	self.view.bottom.challenge[CS.UGUIClickEventListener].interactable = bool
	self.view.bottom.sweep[CS.UGUIClickEventListener].interactable = bool
	self.view.bottom.NPCHelp[CS.UGUIClickEventListener].interactable = bool
end

function View:Move()
	--ERROR_LOG("移动")
	self:setClick(false)
	if (self.saveGid % 10) == 0 then
		local door = self.npc_confs[25011200][1]
		trialModule.GetNowWave(true)
		utils.EventManager.getInstance():dispatch("NEW_TRAIL_WLAK",{x=door.Position_x,y=door.Position_y,z=door.Position_z,func=function ( ... )
			--ERROR_LOG("停下了")
			self:PlayUIEffert()
			self:setClick(true)
			SGK.Action.DelayTime.Create(0.15):OnComplete(function()
				module.NPCModule.Ref_NPC_LuaCondition()
				utils.SGKTools.PlayerTransfer(self.towerCfg.initialposition_x,self.towerCfg.initialposition_y,self.towerCfg.initialposition_z)
			end)
		end})
	else
		utils.EventManager.getInstance():dispatch("NEW_TRAIL_WLAK",{x=self.towerCfg.initialposition_x,y=self.towerCfg.initialposition_y,z=self.towerCfg.initialposition_z,func=function ( ... )
			self:setClick(true)
		end})
	end
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self.view.bottom.challenge.gameObject).onClick = function ()
		--CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
		if not trialModule.GetIsTop() then
			DialogStack.Push("newTrial/newTrialChallenge",{cfg = self.cfg})
			trialModule.SaveLayarGid(self.gid)
		else
			showDlgError(nil,SGK.Localize:getInstance():getValue("shilianta_01"))
		end
		-- self.num = self.num + 1
		-- if self.num > 10 then
		-- 	local MapId = SceneStack.MapId()
		-- 	if MapId < 510 then
		-- 		SceneStack.EnterMap(MapId + 1)
		-- 	end
		-- else
		-- 	self:initData()
		-- 	utils.EventManager.getInstance():dispatch("NEW_TRAIL_WLAK",{x=self.towerCfg.initialposition_x,y=self.towerCfg.initialposition_y,z=self.towerCfg.initialposition_z})
		-- end
	end
	CS.UGUIClickEventListener.Get(self.view.bottom.sweep.gameObject).onClick = function ()
		if self.gid > 60000001 then
			if module.ItemModule.GetItemCount(90168) > 0 then
				DialogStack.Push("newTrial/newTrailSweep",{gid = self.gid})
			else
				showDlgError(nil, "今日已完成扫荡,请明日再来~")
			end
		else
			showDlgError(nil, "至少要挑战成功一层才可以扫荡")
		end
	end
	CS.UGUIClickEventListener.Get(self.view.bottom.NPCHelp.gameObject).onClick = function ()
		-- local door = self.npc_confs[25011200][1]
		-- utils.EventManager.getInstance():dispatch("NEW_TRAIL_WLAK",{x=door.Position_x,y=door.Position_y,z=door.Position_z,func=function ( ... )
		-- 	--ERROR_LOG("停下了")
		-- 	self:PlayUIEffert()
		-- 	SGK.Action.DelayTime.Create(0.15):OnComplete(function()
		-- 		module.NPCModule.Ref_NPC_LuaCondition()
		-- 		utils.SGKTools.PlayerTransfer(self.towerCfg.initialposition_x,self.towerCfg.initialposition_y,self.towerCfg.initialposition_z)
		-- 	end)
		-- end})
		if self.towerCfg.map_npc_gid2 ~= 0 then
			self:NPCHelp()
		end
	end
	CS.UGUIClickEventListener.Get(self.view.top.help.gameObject).onClick = function ()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shilianta_shuoming_01"))
	end

	CS.UGUIClickEventListener.Get(self.view.top.rank.gameObject).onClick = function ()
		DialogStack.PushPrefStact("rankList/rankListFrame", 4)
	end
end

function View:NPCHelp()
	local buffNpc = self.towerCfg.map_npc_gid2
	local noc_id = self.npc_confs[buffNpc][1].mode
	local menus = {}
    table.insert(menus, {name="赠送", auto = false, icon = "bg_db_songli", action = function()
        DispatchEvent("KEYDOWN_ESCAPE")
        utils.SGKTools.OpenNPCBribeView(noc_id)
    end})
	table.insert(menus, {name="交谈", auto = false, icon = "bg_db_xianliao", action = function()
        local buffCfg = trialTowerConfig.GetBuffConfig(self.gid)
        ERROR_LOG(self.gid,sprinttb(buffCfg)) 
        if module.ItemModule.GetItemCount(buffCfg.item_id) >= buffCfg.item_value then
        	LoadStory(noc_id * 1000 + 801,nil,nil,nil,function ()
        		--self:NPCHelp()
        		DispatchEvent("RE_NPCHelp")
        	end)
        else
        	LoadStory(noc_id * 1000 + 802,nil,nil,nil,function ()
        		DispatchEvent("RE_NPCHelp")
        	end)
        end
    end})
    SetStoryOptions(menus)
	LoadStoryOptions()
	LoadStory(noc_id * 10 + 1)
end

function View:Sweeping()
	self:PlayUIEffert()
	SetItemTipsState(false)
	utils.SGKTools.LockMapClick(true)
	local towerCfg = trialTowerConfig.GetConfig(60000001)
	trialModule.IsSweep(true)
	trialModule.GetSweepWave(1)
	--SetItemTipsState(false)
	self.count = 0  
	self.SweepTime = self.gid - 60000000
	SGK.Action.DelayTime.Create(0.15):OnComplete(function()
		module.NPCModule.Ref_NPC_LuaCondition()
		utils.SGKTools.PlayerTransfer(towerCfg.initialposition_x,towerCfg.initialposition_y,towerCfg.initialposition_z)
		SGK.Action.DelayTime.Create(1):OnComplete(function()
			self:StartSweep()
		end)
	end)
end

function View:StartSweep(bool)
	if not bool and self.count ~= 0 and self.count %10 == 0 then
		local door = self.npc_confs[25011200][1]
		trialModule.GetSweepWave(math.floor(self.count/10)+1)
		local towerCfg = trialTowerConfig.GetConfig(60000001)
		utils.EventManager.getInstance():dispatch("NEW_TRAIL_WLAK",{x=door.Position_x,y=door.Position_y,z=door.Position_z,func=function ( ... )
			self:PlayUIEffert()
			SGK.Action.DelayTime.Create(0.15):OnComplete(function()
				module.NPCModule.Ref_NPC_LuaCondition()
				utils.SGKTools.PlayerTransfer(towerCfg.initialposition_x,towerCfg.initialposition_y,towerCfg.initialposition_z)
				SGK.Action.DelayTime.Create(1):OnComplete(function()
					self:StartSweep(true)
				end)
			end)
		end})
	else
		self.count = self.count + 1
		if self.count < self.SweepTime then
			local gid = self.count + 60000000
			local npc_id = trialTowerConfig.GetConfig(gid).map_npc_gid1
			local npcCfg = self.npc_confs[npc_id][1]
			utils.EventManager.getInstance():dispatch("NEW_TRAIL_WLAK",{x=npcCfg.Position_x,y=npcCfg.Position_y,z=npcCfg.Position_z,func=function ( ... )
				module.NPCModule.LoadNpcEffect(npc_id,"fx_dadou")
				SGK.Action.DelayTime.Create(1):OnComplete(function()
					fightModule.Sweeping(gid, 1)
					--module.NPCModule.deleteNPC(npc_id)
					--module.NPCModule.RemoveNPC(npc_id)
					trialModule.SetSweepLayer(self.count)
					module.NPCModule.Ref_NPC_LuaCondition()
				end)
			end})
		else
			trialModule.SaveLayarGid(self.gid)
			trialModule.ClearAllSweepData()
			self.saveGid = trialModule.SaveLayarGid()
			utils.SGKTools.LockMapClick(false)
			utils.EventManager.getInstance():dispatch("OVER_TRIAL_SWEEP")
			SetItemTipsState(true)
		    for i,v in ipairs(self:getGiftTab()) do
		        PopUpTipsQueue(1,{v[2], v[3], v[1],v[4]})
		    end
			self:Move()
		end
	end
end

function View:PlayUIEffert()
	local effect_1 = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dark_tra_1.prefab"), self.view.effert.transform)
	SGK.Action.DelayTime.Create(0.8):OnComplete(function()
		if effect_1 then
        	CS.UnityEngine.GameObject.Destroy(effect_1.gameObject)
        end
        local effect_2 = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dark_tra_2.prefab"), self.view.effert.transform)
        SGK.Action.DelayTime.Create(0.8):OnComplete(function()
        	if effect_2 then
        		CS.UnityEngine.GameObject.Destroy(effect_2.gameObject)
        	end
        end)
    end)
end

function View:initView()
-- 	local index = self.gid - 60000000
-- 	local third = math.floor(index / 100) 
-- 	local second = math.floor(index / 10)
-- 	local first = index % 10
	local first,second,third = trialModule.GetLayer()
	--print("试炼塔层数",third,second,first)
	self.view.top.title.second[CS.UGUISpriteSelector].index = second
	self.view.top.title.first[CS.UGUISpriteSelector].index = first
	if third == 0 then
		self.view.top.title.third:SetActive(false)
	end
	if third == 0 and second == 0 then
		self.view.top.title.second:SetActive(false)
	end
end

function View:addGiftTab(data)
    for i,v in ipairs(data) do
        if v[2] ~= 90001 and v[2] ~= 90000 then
            if v[1] == 43 then
                table.insert(self.allGiftTab,v)
            else
                if self.allGiftTab[v[2]] then
                    self.allGiftTab[v[2]][3] = self.allGiftTab[v[2]][3] + v[3]
                else
                    self.allGiftTab[v[2]] = v
                end
            end
        end
    end
end

function View:getGiftTab()
    local _tab = {}
    for k,v in pairs(self.allGiftTab) do
        -- if #v==3 then
        --     v[4]=nil
        -- end
        table.insert(_tab, v)
    end
    self.allGiftTab = {}
    return _tab
end

function View:OnDestroy()
	--ERROR_LOG("清除扫荡数据")
	trialModule.ClearAllSweepData()
end

function View:listEvent()
    return {
    "TRIAL_SCENE_READY",
    "LOCAL_FIGHT_SWEEPING",
    "CONFIRM_TRIAL_SWEEP",
    "LOCAL_SOTRY_DIALOG_START",
    "LOCAL_SOTRY_DIALOG_CLOSE",
    "RE_NPCHelp",
    }
end

function View:onEvent(event,data)
	if event == "TRIAL_SCENE_READY" then
		ERROR_LOG(self.gid,self.saveGid)
		if self.saveGid ~= 0 and self.gid ~= self.saveGid then
			self:Move()
			trialModule.SaveLayarGid(self.gid)
		end
	elseif event == "LOCAL_FIGHT_SWEEPING" then
		if self.count < self.SweepTime then
			self:addGiftTab(data)
			self:StartSweep()
		end
	elseif event == "CONFIRM_TRIAL_SWEEP" then
		self:Sweeping()
	elseif event == "LOCAL_SOTRY_DIALOG_START" then
		self.view[UnityEngine.CanvasGroup].alpha = 0
	elseif event == "LOCAL_SOTRY_DIALOG_CLOSE" then
		self.view[UnityEngine.CanvasGroup].alpha = 1
	elseif event == "RE_NPCHelp" then
		self:NPCHelp()
	end
end


return View;