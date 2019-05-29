local MapHelper = require "utils.MapHelper"
local MapConfig = require "config.MapConfig"
local StoryConfig = require "config.StoryConfig"
local SGKTools = require "utils.SGKTools"
local QuestRecommendedModule = require "module.QuestRecommendedModule"
local openLevel = require "config.openLevel"
local rewardModule = require "module.RewardModule"
local QuestModule = require "module.QuestModule"
local ActivityConfig = require "config.activityConfig"
local GuideHelper = require "utils.GuideHelper"

--------------------------------------完成任务----------------------------------------

local function CloseFrame()
    SGKTools.CloseFrame()
end

--底层接任务函数
local function AcceptQuest(k,quest_type)
    if not k then
        --建设城市任务
        --数量未达20个，就继续接任务
        if module.QuestModule.CityContuctInfo().today_count < 20 then
            --建设城市奖励计数道具
            local CityContuctSingleStatisticsId = 2041
            local CityContuctDoubleStatisticsId = 1041
            --第一次单倍奖励任务领取提示
            if module.ItemModule.GetItemCount(CityContuctDoubleStatisticsId) <= 0 and module.ItemModule.GetItemCount(CityContuctSingleStatisticsId) >= 10 then
                showDlgMsg(SGK.Localize:getInstance():getValue("jiansherenwu_01"), 
                    function ()
                        module.QuestModule.CityContuctAcceptQuest(quest_type)
                    end, 
                    function () end, 
                    SGK.Localize:getInstance():getValue("common_queding_01"), --确定
                    SGK.Localize:getInstance():getValue("common_cancle_01") --取消
                )
            else
                module.QuestModule.CityContuctAcceptQuest(quest_type)
            end
        else
            showDlg(nil,"您今日已完成20次建设关卡任务，无法领取新的任务")
        end
    else
        --其他任务
        module.QuestModule.Accept(k)
        --TeamQuestModuleAccept(k)
    end
end

--完成任务
local function FinishQuest(v)
    if v.type >= 41 and v.type <= 44 then
        module.QuestModule.CityContuctSubmitQuest()
    else
        module.QuestModule.Submit(v.id)
        --TeamQuestModuleSubmit(v.id)
    end

    --完成任务后对话
    local story_id = tonumber(v.id.."81")
    if StoryConfig.GetStoryConf(story_id) then
        TeamStory(story_id)
        LoadStory(story_id,function()
            --如果是建设城市任务则尝试接下一个任务
            if v.type >= 41 and v.type <= 44 then
                AcceptQuest(nil,v.type)
            end
            CloseFrame()
        end)
    else
        CloseFrame()
    end
    --删除剧情npc
    local npc_conf = MapConfig.GetMapMonsterConf(v.npc_id)
    if npc_conf and npc_conf.type == 1 then
        module.NPCModule.deleteNPC(v.npc_id)
    end

    --领取新的建设城市
    if v.type >= 41 and v.type <= 44 then
        AcceptQuest(nil,v.type)
    end
end

--完成任务前对话
local function StoryBeforeFinish(v)
    local story_id = tonumber(v.id.."61")
    if StoryConfig.GetStoryConf(story_id) then
        TeamStory(story_id)
        LoadStory(story_id,function()
            FinishQuest(v)
        end)
    else
        FinishQuest(v)
    end
end

--上交物品
local function SubmitItem(v)
    local item_list = {
        [1] = {id = v.consume_id1, type = v.consume_type1, value = v.consume_value1},
        [2] = {id = v.consume_id2, type = v.consume_type2, value = v.consume_value2}
    }
    MapHelper.OpTaskBag(item_list, function()
    CloseFrame()
        --上交物品后对话
        local story_id = tonumber(v.id.."51")
        if StoryConfig.GetStoryConf(story_id) then
            LoadStory(story_id,function()
                StoryBeforeFinish(v)
            end)
        else
            StoryBeforeFinish(v)
        end
    end)
end

--上交物品前检查和对话
local function BeforeSubmitItem(v)
    --检查上交物品是否足够
    local result = module.QuestModule.CanSubmit(v.id)
    if result == true then
        if v.consume_value1 + v.consume_value2 > 0 then
            --上交物品前对话
            local story_id = tonumber(v.id.."41")
            if StoryConfig.GetStoryConf(story_id) then
                TeamStory(story_id)
                LoadStory(story_id,function()
                    SubmitItem(v)
                end)
            else
                SubmitItem(v)
            end
        else
            StoryBeforeFinish(v)
        end
    else
        CloseFrame()
    end
end

--战斗函数
local function StartFight(v)
    local win = false
    if v.event_type1 == 2 then
        win = module.fightModule.StartFightInThread(v.event_id1)
    else
        win = module.fightModule.StartFightInThread(v.event_id2)
    end
    if win == true then
        local npc_conf = MapConfig.GetMapMonsterConf(v.npc_id)
        if npc_conf.type == 1 then
            --删除击败的怪
            SGKTools.loadEffect("UI/fx_chuan_ren",v.npc_id)
            Sleep(0.5)
            module.NPCModule.deleteNPC(v.npc_id)

            --如果还要打怪则生成新的怪
            local _,result_type = module.QuestModule.CanSubmit(v.id)
            if result_type == 2 then
                --读取随机点的表
                local key_table = MapHelper.GetConfigTable("all_position","map_id")
                local location = nil
                local map_id = FindMapId(v)
                for k,v in pairs(key_table) do
                    if k == map_id then
                        local num = math.random(1,#v)
                        location = {v[num].Position_x,v[num].Position_y,v[num].Position_z}
                        break
                    end
                end
                if location then
                    module.NPCModule.LoadNpcOBJ(v.npc_id,Vector3(location[1],location[2],location[3]))
                else
                    module.NPCModule.LoadNpcOBJ(v.npc_id)
                end
            end
        end
        --战斗后剧情
        local story_id = tonumber(v.id.."31")
        if StoryConfig.GetStoryConf(story_id) then
            TeamStory(story_id)
            LoadStory(story_id,function()
                BeforeSubmitItem(v)
            end)
        else
            BeforeSubmitItem(v)
        end
    else
        CloseFrame()
    end
end


--战斗前剧情
local function BeforeFight(v)
    local story_id = tonumber(v.id.."21")
    if StoryConfig.GetStoryConf(story_id) then
        TeamStory(story_id)
        LoadStory(story_id,function ()
            StartFight(v)
        end)
    else
        StartFight(v)
    end
end

local function FindMapId(quest)
    local map_id = quest.map_id
    local npc_conf

    if quest.npc_id and quest.npc_id > 0 then
        npc_conf = MapConfig.GetMapMonsterConf(quest.npc_id)
    elseif quest.monster_id and quest.monster_id > 0 then
        npc_conf = MapConfig.GetMapMonsterConf(quest.monster_id)
    end

    if npc_conf then
        map_id = npc_conf.mapid
    end
    return map_id
end

local function FindNpcId(quest)
    local npc_conf = nil

    --获取任务的npc配置
    if quest.npc_id and quest.npc_id > 0 then
        npc_conf = MapConfig.GetMapMonsterConf(quest.npc_id)
    elseif quest.monster_id and quest.monster_id > 0 then
        npc_conf = MapConfig.GetMapMonsterConf(quest.monster_id)
    end

    return npc_conf
end

--[[
    1、进入场景会触发
    2、接到任务会触发
    3、战斗结束会触发(战斗胜利则任务完成)
]]
function OnEnterMap(quest,id,name)
    --如果是战斗直接结束
    if name == "battle" then return end

    --SGKTools.PlayGameObjectAnimation("camera_ani", "CameraActive")
    --生成物资箱（关卡建设）
    if id == 30 then
        module.NPCModule.LoadNpcOBJ(3030000)
    end
    if id == 19 then
        module.NPCModule.LoadNpcOBJ(3019000)
    end
    if id == 13 then
        module.NPCModule.LoadNpcOBJ(3013000)
    end
    if id == 10 then
        module.NPCModule.LoadNpcOBJ(3010000)
    end
    if id == 22 then
        module.NPCModule.LoadNpcOBJ(3022000)
    end
    if id == 28 then
        module.NPCModule.LoadNpcOBJ(3028000)
    end
    if id == 32 then
        module.NPCModule.LoadNpcOBJ(3032000)
    end
    if id == 27 then
        module.NPCModule.LoadNpcOBJ(3027000)
    end

    local map_id = FindMapId(quest)

    --如果不是任务地图则直接返回
    if map_id == nil or id ~= map_id then return end
    --如果任务不是已领取状态则返回
    if quest.status ~= 0 then return end


    local npc_conf = FindNpcId(quest)

    --增加巡逻遇怪事件
    if quest.monster_id and quest.monster_id > 0 then
        local result_type,result
        result,result_type = module.QuestModule.CanSubmit(quest.id)
        if result_type == 2 then
            module.EncounterFightModule.SetFightData({type="quest_" .. quest.id, map_id = map_id,depend_level = quest.depend_level,fun =  function()
                BeforeFight(quest)
            end})
        end
    end

    --生成怪
    if npc_conf and npc_conf.type ~= 2 then
        --读取随机点的表
        local key_table = MapHelper.GetConfigTable("all_position","map_id")
        local location_list = key_table[map_id] or {};
        if #location_list > 0 and npc_conf.type == 5 then
            local location;
            if quest.random_hit then
                location = location_list[quest.random_hit % #location_list + 1];
            else
                location = location_list[math.random(1, #location_list)];
            end
            module.NPCModule.LoadNpcOBJ(npc_conf.gid,Vector3(location.Position_x,location.Position_y,location.Position_z))
        elseif npc_conf.type ~= 9 then
            module.NPCModule.LoadNpcOBJ(npc_conf.gid)
        end
    end

    --生成巡逻点
    local map_idd = map_id
    if map_id < 10 then
        map_idd = "0"..map_idd
    end
    if map_id < 100 then
        map_idd = "0"..map_idd
    end

    local bounty_id1 = tonumber("4"..map_idd.."990")
    local bounty_id2 = tonumber("4"..map_idd.."991")
    local bounty_id3 = tonumber("4"..map_idd.."992")
    local bounty_id4 = tonumber("4"..map_idd.."993")

    module.NPCModule.LoadNpcOBJ(bounty_id1)
    module.NPCModule.LoadNpcOBJ(bounty_id2)
    module.NPCModule.LoadNpcOBJ(bounty_id3)
    module.NPCModule.LoadNpcOBJ(bounty_id4)

end



function Guide(quest)
    --地图传送
    local function Change_map(map_id)
        if map_id ~= GetCurrentMapID() then
            SGKTools.PlayerMoveZERO()
            SGKTools.loadEffect("UI/fx_chuan_ren")
            SGKTools.PLayerConceal(true)
            Sleep(0.5)
            --SceneStack.EnterMap(map_id)
            module.EncounterFightModule.GUIDE.EnterMap(map_id)
        end
    end

    --找npc
    local function TrackNpc(quest,npc_id)
        if quest then
            SGKTools.SetTaskId(quest.id)
        end

        if quest then
            local npc_conf = FindNpcId(quest)
            --如果没有生成该npc则生成
            local npc_obj = module.NPCModule.GetNPCALL(npc_id)
            if npc_obj then
                if not npc_obj.activeSelf then
                    npc_obj:SetActive(true)
                end
            elseif npc_conf.type ~= 9 then
                module.NPCModule.LoadNpcOBJ(npc_id)
            end
        end

        --悬赏任务没有status
        if not quest or not quest.status or quest.status == 0 then
            Interact("NPC_"..npc_id)
        else
            if quest.accept_npc_id ~= 0 then
                Interact("NPC_"..quest.accept_npc_id)
            end
        end
    end

    --巡逻
    local function Patrol(map_id)
        --找到目标并打开交互界面
        local map_idd = map_id

        if map_id < 10 then
            map_idd = "0"..map_idd
        end

        if map_id < 100 then
            map_idd = "0"..map_idd
        end

        local bounty_id1 = "NPC_4"..map_idd.."990"
        local bounty_id2 = "NPC_4"..map_idd.."991"
        local bounty_id3 = "NPC_4"..map_idd.."992"
        local bounty_id4 = "NPC_4"..map_idd.."993"

        for i = 1, 10 do
            Interact(bounty_id1)
            Interact(bounty_id2)
            Interact(bounty_id3)
            Interact(bounty_id4)
        end
    end

    --根据推荐任务类型获得推荐任务
    local function Get_recommend_activity(type)
        local activity_list = MapHelper.GetConfigTable("recommend_activity","quest_type")
        return activity_list[type][1]
    end

    for i = 1, 1 do
        if module.QuestModule.CanSubmit(quest.id) and quest.npc_id == 0 then
            QuestModule.Submit(quest.id)
            return            
        end
        
        if quest.relation_type then
            --Edit——18.10.27_by_Albert
            --如果是关联任务，执行任务逻辑
            if (quest.relation_type == 1001 or quest.relation_type == 501) and quest.relation_type ~= nil  then
                if module.QuestModule.CanSubmit(quest.id) and quest.npc_id == 0 then
                    module.QuestModule.Finish(quest.id)
                    return
                end
            -- --部分界面给予默认值
            -- elseif (quest.relation_value == 0 or quest.relation_value == nil) and quest.relation_type ~= 100 then
            --     quest.relation_value = 1
            end

            if quest.relation_type == 1001 then--关联任务
                local relation_quest_type = tonumber(quest.relation_value)
                --已接任务  0 未完成   1 完成  2  取消
                local allQuests = module.QuestModule.GetList(relation_quest_type,0) or {};
                if #allQuests > 0 then
                    --如果已经领取关联的任务，则去做关联的任务
                    quest = allQuests[1]
                else
                    --如果没领取关联的任务，前往领取关联的任务
                    local activity = Get_recommend_activity(relation_quest_type)
                    local npc_id = tonumber(activity.result_count)
                    GuideHelper.Go(501,quest.relation_value)
                    return
                end
            elseif quest.relation_type == 1002 then--打开穿戴逆血魔装界面

            elseif quest.relation_type == 1003 then--关卡任务修改交付NPC（限关卡争夺用）
                local build_Type_To_OpenLevel ={[44]=4001,[43]=4004,[42]=4002,[41]=4003,}
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
                if cityQuest then
                    local teamInfo = module.TeamModule.GetTeamInfo();
                    if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                        --不在一个队伍中或自己为队长
                        if cityQuest then
                            DialogStack.CleanAllStack()
                            QuestModule.StartQuestGuideScript(cityQuest.cfg, true)
                        end
                    else
                        showDlgError(nil,"你正在队伍中，无法进行该操作")
                    end
                end
                return
            else
                GuideHelper.Go(quest.relation_type,quest.relation_value)
                return
            end

            --[==[
                 --如果是关联任务，执行任务逻辑
                if (quest.relation_type == 14 or quest.relation_type == 15) and quest.relation_type ~= nil  then
                    if module.QuestModule.CanSubmit(quest.id) then
                        module.QuestModule.Finish(quest.id)
                        return
                    end
                --部分界面给予默认值
                elseif (quest.relation_value == 0 or quest.relation_value == nil) and quest.relation_type ~= 4 then
                    quest.relation_value = 1
                end
                --打开副本界面
                if quest.relation_type == 1 then
                    local openCondition = 2201
                    if quest.relation_value == 2 then
                        openCondition = 2202
                    elseif quest.relation_value == 3 then
                        openCondition = 1221
                    end    
                    if openLevel.GetStatus(openCondition) then
                        DialogStack.Push("newSelectMap/selectMap", {idx = quest.relation_value})
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(openCondition))
                    end
                    return
                --打开活动界面
                elseif quest.relation_type == 2 then
                    if openLevel.GetStatus(1201) then
                        DialogStack.Push("mapSceneUI/newMapSceneActivity", {filter={flag=false,id=1003},activityId = quest.relation_value})
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1201))
                    end
                    return
                --打开公会界面
                elseif quest.relation_type == 3 then
                    if openLevel.GetStatus(2101) then
                        local uninInfo = module.unionModule.Manage:GetSelfUnion();
                        if uninInfo and next(uninInfo) then
                            if quest.relation_value == 1 then--公会投资
                                DialogStack.PushMapScene("newUnion/newUnionInvestment")
                            elseif quest.relation_value == 2 then--公会物资
                                DialogStack.PushMapScene("newUnion/newUnionWish")
                            elseif quest.relation_value == 3 then--公会探险
                                if module.unionScienceModule.GetScienceInfo(12) and module.unionScienceModule.GetScienceInfo(12).level ~=0 then
                                    DialogStack.PushMapScene("newUnion/newUnionExplore")
                                else
                                    showDlgError(nil, SGK.Localize:getInstance():getValue("guild_tech_lock"))
                                end
                            end
                        else
                            showDlgError(nil,SGK.Localize:getInstance():getValue("dati_tips_05"))
                        end
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(2101))
                    end   
                    return
                --打开基地界面:0总览  1酒馆  2研究院  3工坊  4~7矿洞
                elseif quest.relation_type == 4 then
                    if quest.relation_value == 0 then
                        if openLevel.GetStatus(2001) then
                            DialogStack.Push("Manor_Overview")
                        else
                            showDlgError(nil, openLevel.GetCloseInfo(2001))
                        end 
                    else
                        local openCondition = 2002
                        if quest.relation_value == 2 then
                            openCondition = 2004
                        elseif quest.relation_value == 3 then
                            openCondition = 2005
                        else
                            openCondition = 2008
                        end
                        if openLevel.GetStatus(openCondition) then
                            MapHelper.EnterManorBuilding(quest.relation_value)
                        else
                            showDlgError(nil, openLevel.GetCloseInfo(openCondition))
                        end 
                    end
                    return
                --前往地图
                elseif quest.relation_type == 5 then
                    if openLevel.GetStatus(2601) then
                        module.EncounterFightModule.GUIDE.EnterMap(quest.relation_value)
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(2601))
                    end   
                    return
                --打开商店界面
                elseif quest.relation_type == 6 then
                    if openLevel.GetStatus(2401) then
                        DialogStack.Push("ShopFrame",{index=quest.relation_value})
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(2401))
                    end 
                    return
                --占卜
                elseif quest.relation_type == 7 then
                    if openLevel.GetStatus(1801) then
                        DialogStack.Push("DrawCard/newDrawCardFrame")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1801))
                    end
                    return
                --伙伴界面
                elseif quest.relation_type == 8 then
                    if openLevel.GetStatus(1101) then
                        DialogStack.Push("newrole/roleFramework",{heroid = 11000,idx = quest.relation_value})
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1101))
                    end
                    return
                --打开排名竞技场界面
                elseif quest.relation_type == 9 then
                    if openLevel.GetStatus(1902) then
                        DialogStack.Push("traditionalArena/traditionalArenaFrame")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1902))
                    end 
                    return   
                --打开财力竞技场界面
                elseif quest.relation_type == 10 then
                    if openLevel.GetStatus(1901) then
                        DialogStack.Push("PvpArena_Frame")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1901))
                    end  
                    return
                --打开英雄比拼界面
                elseif quest.relation_type == 11 then
                    if openLevel.GetStatus(1911) then
                        DialogStack.Push("PveArenaFrame")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1911))
                    end   
                    return
                --试练塔
                elseif quest.relation_type == 12 then
                    if openLevel.GetStatus(3101) then
                        MapHelper.OpenTrialTower()
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(3101))
                    end               
                    return
                --虚空镜界
                elseif quest.relation_type == 13 then
                    if openLevel.GetStatus(1921) then
                        DialogStack.Push("expOnline/expOnline")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1921))
                    end
                    return
                --关联任务
                elseif quest.relation_type == 14 then
                    local relation_quest_type = tonumber(quest.relation_value)
                    --已接任务  0 未完成   1 完成  2  取消
                    local allQuests = module.QuestModule.GetList(relation_quest_type,0) or {};
                    if #allQuests > 0 then
                        --如果已经领取关联的任务，则去做关联的任务
                        quest = allQuests[1]
                    else
                        --如果没领取关联的任务，前往领取关联的任务
                        local activity = Get_recommend_activity(relation_quest_type)
                        local npc_id = tonumber(activity.result_count)

                        local npc_confs = MapHelper.GetConfigTable("all_npc","gid") or {}
                        local map_id = npc_confs[npc_id][1].mapid
                        Change_map(map_id)
                        TrackNpc(nil,npc_id)
                        return
                    end
                --找npc
                elseif quest.relation_type == 15 then
                    local npc_id = quest.relation_value
                    local npc_confs = MapHelper.GetConfigTable("all_npc","gid") or {}
                    local map_id = npc_confs[npc_id][1].mapid
                    Change_map(map_id)
                    TrackNpc(nil,npc_id)
                    return
                --打开趣味答题界面
                elseif quest.relation_type == 16 then
                    if module.QuestRecommendedModule.CheckActivity(module.QuestRecommendedModule.GetCfg(39)) then
                        DialogStack.Push("answer/answer")
                        return
                    else
                        if not openLevel.GetStatus(1251) then
                            showDlg(nil,"您的等级未到"..openLevel.GetCfg(1251).open_lev.."级", function() end)
                            return
                        end
                        showDlg(nil,"当前活动未开放", function() end)
                        return
                    end
                --答题竞赛
                elseif quest.relation_type == 17 then
                    if openLevel.GetStatus(1252) then
                        DialogStack.Push("answer/weekAnswerFrame")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(1252))
                    end
                    return
                --聊天
                elseif quest.relation_type == 20 then
                    if openLevel.GetStatus(2801) then
                        DialogStack.Push("NewChatFrame")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(2801))
                    end
                    return
                --好友
                elseif quest.relation_type == 21 then
                    if openLevel.GetStatus(2501) then
                        DialogStack.Push("FriendSystemList")
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(2501))
                    end
                    return
                elseif quest.relation_type == 22 then--打开建设城市相关
                    DialogStack.Push("buildCity/buildCityFrame")
                    return
                --打开狩猎界面
                elseif quest.relation_type == 23 then
                    if openLevel.GetStatus(3222) then
                        if quest.relation_value > 0 then
                            DialogStack.Push("hunting/HuntingInfo", {map_id = quest.relation_value})
                        else
                            DialogStack.Push("hunting/HuntingFrame")
                        end
                    else
                        showDlgError(nil, openLevel.GetCloseInfo(3222))
                    end
                    return
                --打开任务界面
                elseif quest.relation_type == 27 then
                    local result = QuestModule.CanSubmit(quest.id)
                    if result == true then
                        FinishQuest(quest)
                    else
                        DialogStack.Push("mapSceneUI/newQuestList", {questId = quest.id})
                    end
                    return
                --组队副本
                elseif quest.relation_type == 28 then
                    DialogStack.Push("newSelectMap/activityInfo", {gid = quest.relation_value})
                    return
                --好友庄园
                elseif quest.relation_type == 29 then
                    DialogStack.Push("manor/ManorFriend")
                    return
                --盗团资料
                elseif quest.relation_type == 30 then
                    DialogStack.Push("dataBox/UnionData", {consortia_id = quest.relation_value});
                    return
                end
            --]==]
        end
    end

    -- --进入任务地图
    local map_id =  quest.map_id or FindMapId(quest)
    Change_map(map_id)

    local npc_conf = FindNpcId(quest)
    --确定去巡逻还是去找npc
    if npc_conf and npc_conf.gid > 0 then
        TrackNpc(quest,npc_conf.gid)
    else
        Patrol(map_id)
    end
end

--领取任务后触发
function OnAccept(quest)
    --特殊任务特效
    if quest.animation and quest.animation ~= "0" then
        SGKTools.loadEffectVec3(quest.animation,Vector3(0,0,0),3,false,nil,1)
    end

    local story_id = tonumber(quest.id.."11")
    if StoryConfig.GetStoryConf(story_id) then
        LoadStory(story_id,function()
            
        end)
    end

    --0：不自动    1：自动交   2：自动引导  3：都自动
    if quest.is_auto and quest.is_auto >= 2 then
        Guide(quest)
    end
end
