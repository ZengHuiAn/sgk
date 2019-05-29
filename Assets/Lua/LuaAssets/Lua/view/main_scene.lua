local playerModule = require "module.playerModule";
local heroModule = require "module.HeroModule"
local ShopModule = require "module.ShopModule"
local ItemModule = require "module.ItemModule"
local ActivityModule = require "module.ActivityModule"
local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local equipmentModule = require "module.equipmentModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local equipCfg = require "config.equipmentConfig"
local HeroLevelup = require "hero.HeroLevelup"
local unionModule = require "module.unionModule"
local UserDefault = require "utils.UserDefault"
local TeamModule = require "module.TeamModule"
local StoryConfig = require "config.StoryConfig"
local ManorManufactureModule = require "module.ManorManufactureModule"
local NpcContactModule = require "module.NpcContactModule"
local openLevel = require "config.openLevel"
local GuildPVPGroupModule = require "guild.pvp.module.group"
local HeroScroll = require "hero.HeroScroll"
local ChatManager = require 'module.ChatModule'

local View = {};

SGK.SceneService.GetInstance():StartLoading();

function View:Start(data)
    self.StartTime = os.time()
    self.data = data
    utils.UserDefault.Load("TaskListState", true).state = true

    assert(coroutine.resume(coroutine.create(self.LoadThread), self))

    self.load_list = {
        {GuildPVPGroupModule.QueryReport},
        {StoryConfig.InitStoryConf},
        {equipCfg.EquipmentTab},
        {equipCfg.InscriptionCfgTab},
        {HeroScroll.GetScrollConfig, 0},
        {ChatManager.LoadOldData},
        {ChatManager.GetSystemMessageList},
        {ShopModule.GetNpcSouvenirShopList},
    }
end

function View:LoadThread()
    module.HeroModule.GetManager():GetAll()
    module.QuestModule.QueryQuestList(true);
    module.QuestModule.CheckChangeNameQuest()
    module.QuestModule.AcceptSideQuest()
    module.worldBossModule.QueryAll()
    module.answerModule.QueryInfo()

    -- module.TreasureModule.GetBefore();
    GetAllTitleStatus()--获取称号任务状态

    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo and teamInfo.id > 0  then
        module.unionModule.queryPlayerUnioInfo(teamInfo.leader.pid)
        local data = NetworkService.SyncRequest(18044, {nil,teamInfo.leader.pid})--查询队长位置

        if data[2] == 0 then
            local mapid, x, z, y, mapType, room = data[3][1], data[3][2], data[3][3], data[3][4], data[3][5], data[3][6];
            --如果是 元素暴走地图,并且自己是队长
            local pid = module.playerModule.GetSelfID();
            if mapid == 551 and teamInfo.leader.pid == pid then
                --查询活动装备
                module.DefensiveFortressModule.QueryStatus()
                return
            end

            if module.TeamModule.CheckEnterMap(mapid,true) then
                if teamInfo.afk_list[pid] then
                    SceneStack.EnterMap(1);--暂离状态直接回家
                else
                    SceneStack.TeamEnterMap(mapid, {mapid = mapid, x = x, y = y, z = z, mapType = mapType, room = room});
                end
            else
                showDlgError(nil,"无法传送到队长身边");
                module.TeamModule.TEAM_AFK_REQUEST(function ()
                    SceneStack.EnterMap(1);
                end, pid);
            end 
            return;
        else
            module.TeamModule.KickTeamMember();
        end
    end

    self:EnterMap();
end

function View:EnterMap()
    if self.StartTime then
        self.StartTime = nil;
        module.CemeteryModule.Query_Player_Record(1)
        module.CemeteryModule.Query_Player_Record(2)
        AssociatedLuaScript("guide/login_map.lua")
    end
end

function View:Update()
    local info = self.load_list[1];
    if info then
        info[1](info[2]);
        table.remove(self.load_list, 1);
    end

    for i = 1, 4 do
        utils.ConfigReader.Preload()
    end

    if self.StartTime and (os.time() - self.StartTime) >= 6 then
        self:EnterMap();
    end
end

return View;
