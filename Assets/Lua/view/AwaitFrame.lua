local openLevel = require "config.openLevel"
local NetworkService = require "utils.NetworkService"
local GuildPVPGroupModule = require "guild.pvp.module.group"
local StoryConfig = require "config.StoryConfig"
local Time = require "module.Time"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.StartTime = Time.now()
    self.data = data
    StoryConfig.InitStoryConf()
    GuildPVPGroupModule.QueryReport();
    utils.UserDefault.Load("TaskListState", true).state = true
    assert(coroutine.resume(coroutine.create(self.LoadThread), self))
end

function View:LoadThread()
    module.QuestModule.GetList();
    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.id > 0 then
        local data = NetworkService.SyncRequest(18044, {nil,teamInfo.leader.pid})--查询队长位置   
        if data[2] == 0 then
            local mapid, x, z, y = data[3][1], data[3][2], data[3][3], data[3][4];
            SceneStack.EnterMap(mapid,{pos = {x, y, z}});
            return;
        end
    end

    if self.StartTime then
        module.CemeteryModule.Query_Player_Record(1)
        module.CemeteryModule.Query_Player_Record(2)
        AssociatedLuaScript("guide/login_map.lua")
    end
end

function View:Update()
    if self.StartTime and (Time.now() - self.StartTime) >= 6 then
        self.StartTime = nil;
        module.CemeteryModule.Query_Player_Record(1)
        module.CemeteryModule.Query_Player_Record(2)
        AssociatedLuaScript("guide/login_map.lua")
    end
end

return View;
