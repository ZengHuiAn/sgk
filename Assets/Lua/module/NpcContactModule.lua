local EventManager = require 'utils.EventManager';
local function GetQuestEnv(quest)
    if not quest.script then
        return {}
    end

    if not quest._env then
        if quest.script == nil or quest.script == "" or quest.script == "0" or quest.script == 0 then
            quest._env = {};
            return quest._env;
        end

        local script = quest.script;
        local env = setmetatable({
            EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
            Interact = module.EncounterFightModule.GUIDE.Interact,
            GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
            GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
            SGKTools = utils.SGKTools,
            showDlgError = showDlgError,
			ERROR_LOG = ERROR_LOG,
			Mod = module.GetModule,
        }, {__index=_G})

        local func = loadfile(script, 'bt', env)
        if func then func(); end

        quest._env = env;
    end

    return quest._env;
end

local function callQuestScript(quest, name, ...)
    local env = GetQuestEnv(quest);
    if rawget(env, name) then
        coroutine.resume(coroutine.create(env[name]), quest, ...);
        return true;
    end
end
local function NpcContack(name,data)
	local quest = {
    	script = "guide/FriendAction.lua",
		data = data,
	}
    callQuestScript(quest, name)
end
EventManager.getInstance():addListener("Player_login_CHANGE", function(event, data)
    NpcContack("login",data)
end)
EventManager.getInstance():addListener("LOCAL_HERO_STAR_UP", function(event, data)
	NpcContack("starUp",data)
end)
EventManager.getInstance():addListener("LOCAL_HERO_QUEST_FINISH", function(event, data)
    NpcContack("quest",data)
end)
EventManager.getInstance():addListener("LOCAL_HERO_STAGE_UP", function(event, data)
    NpcContack("stageUp",data)
end)
EventManager.getInstance():addListener("Bribe_Npc_Info", function(event, data)
    NpcContack("gift",data)
end)
EventManager.getInstance():addListener("PLAYER_LEVEL_UP", function(event, data)
    NpcContack("leverUp",data)
end)
EventManager.getInstance():addListener("LOCAL_FIGHT_RESULT_WIN", function(event, data)
    NpcContack("fight",data)
end)
return{
}