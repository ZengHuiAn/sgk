local npc_table = {
	[11001] = {"我是阿尔"}
}

-- local a = SGKTools.GetNPCBribeValue(19906)





--登录触发
function login(para)
	--showDlgError(nil,para.data.test.."当前登入时间:"..Mod.Time.now())
	--SGKTools.NpcChatData(19906,"呼叫呼叫,已成功登入"..Mod.Time.now())

end

--DispatchEvent("LOCAL_HERO_QUEST_FINISH", {questId = quest.id})
--完成任务
function quest(para)
	--某个伙伴参战n次后（任务计数）

end

--战斗后
--DispatchEvent("LOCAL_FIGHT_RESULT_WIN")
function fight(para)
	

end

--DispatchEvent("Bribe_Npc_Info",{npc_id = self.Data.id,grow = self.click_value.grow,item = item})
--grow好感度提升   
--送礼后
function gift(para)
	-- para.data.item.id
end

--DispatchEvent("LOCAL_HERO_STAR_UP", {heroId = self.heroId, now = _now, next = _next})
--升星后
function starUp(para)

end

--DispatchEvent("LOCAL_HERO_STAGE_UP", {heroId = self.heroId, now = _now, next = _next})
--进阶后
function stageUp(para)

end

--DispatchEvent("ACTOR_LEVEL_UP",{lv=self.heros[id].level,old=oldLv})
--升级后
function leverUp(para)

end