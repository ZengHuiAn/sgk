local openLevel = require "config.openLevel"
local MapHelper = require "utils.MapHelper"

--养成界面装备
local dialogTab_1 = {
    go = function (heroId)
        heroId = heroId and heroId ~= 0 and heroId or 11000
        DialogStack.Push("newRole/roleFramework", {heroid = heroId , idx = 1})
    end,
    check = function ( ... )
        return openLevel.GetStatus(1101)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1101)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1101))
    end 
}

--养成界面进阶
local dialogTab_2 = {
    go = function (heroId)
        heroId = heroId and heroId ~= 0 and heroId or 11000
        DialogStack.Push("newRole/roleFramework", {heroid = heroId , idx = 2})
    end,
    check = function ( ... )
        return openLevel.GetStatus(1106)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1106)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1106))
    end 
}

--养成界面升星
local dialogTab_3 = {
    go = function (heroId)
        heroId = heroId and heroId ~= 0 and heroId or 11000
        DialogStack.Push("newRole/roleFramework", {heroid = heroId , idx = 3})
    end,
    check = function ( ... )
        return openLevel.GetStatus(1103)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1103)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1103))
    end  
}

--每日任务
local dialogTab_4 = {
    go = function ()
        DialogStack.Push("mapSceneUI/dailyTask")
    end,
    check = function ( ... )
        return openLevel.GetStatus(3201)
    end,
    get = function ()
        return openLevel.GetCloseInfo(3201)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(3201))
    end  
}

--聊天
local dialogTab_9 = {
    go = function ()
        DialogStack.Push("NewChatFrame")
    end,
    check = function ( ... )
        return openLevel.GetStatus(2801)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2801)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2801))
    end 
}

--好友
local dialogTab_10 = {
    go = function ()
        DialogStack.Push("FriendSystemList")
    end,
    check = function ( ... )
        return openLevel.GetStatus(2501)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2501)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2501))
    end 
}

--打开狩猎界面
local dialogTab_11 = {
    go = function (map_id)
        map_id = map_id and map_id ~= 0 and map_id
        if map_id then
            DialogStack.Push("hunting/HuntingInfo", {map_id = map_id})
        else
            DialogStack.Push("hunting/HuntingFrame")
        end
    end,
    check = function ( ... )
        return openLevel.GetStatus(3222)
    end,
    get = function ()
        return openLevel.GetCloseInfo(3222)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(3222))
    end 
}

--打开任务界面
local dialogTab_12  = {
    go = function (questId)
        DialogStack.Push("mapSceneUI/newQuestList", {questId = questId})
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

--邮箱
local dialogTab_13 = {
    go = function ()
        DialogStack.Push("FriendSystem/FriendMail")
    end,
    check = function ( ... )
        return openLevel.GetStatus(1501)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1501)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1501))
    end 
}
--历练笔记
local dialogTab_14 = {
    go = function ()
        DialogStack.Push("dailyCheckPointTask/dailyTaskList")
    end,
    check = function ( ... )
        return openLevel.GetStatus(2211)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2211)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2211))
    end 
}

--阵容
local dialogTab_21 = {
    go = function ()
        DialogStack.Push("FormationDialog")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}


--商店
local dialogTab_31 = {
    go = function (shopId)
        shopId = shopId and shopId ~= 0 and shopId or 1 --(1 限时商店 2金币商店...)
        DialogStack.Push("ShopFrame",{index = shopId});
    end,
    check = function (shopId)
        if openLevel.GetStatus(2401) then
            shopId = shopId and shopId ~= 0 and shopId or 1 --(1 限时商店 2金币商店...)
            return true
        else
            return false
        end
    end,
    get = function ()
        if openLevel.GetStatus(2401) then
            shopId = shopId and shopId ~= 0 and shopId or 1 --(1 限时商店 2金币商店...)

        else
            return openLevel.GetCloseInfo(2401)
        end
    end,
    show = function ()
        if openLevel.GetStatus(2401) then
            shopId = shopId and shopId ~= 0 and shopId or 1 --(1 限时商店 2金币商店...)
            -- if not module.ShopModule.GetOpenShop(shopId) then
            --     showDlgError(nil,"商店未开放");
            -- end
        else
            showDlgError(nil, openLevel.GetCloseInfo(2401))
        end    
    end 
}

--占卜
local dialogTab_32 = {
    go = function ()
        DialogStack.Push("DrawCard/newDrawCardFrame")
    end,
    check = function ( ... )
        return openLevel.GetStatus(1801)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1801)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1801))
    end
}

--交易行
local dialogTab_33 = {
    go = function (id)
        DialogStack.Push("Trade_Dialog",{find_id = id})
    end,
    check = function ( ... )
        return openLevel.GetStatus(5002)
    end,
    get = function ()
        return openLevel.GetCloseInfo(5002)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(5002))
    end 
}

--资料柜
local dialogTab_40 = {
    go = function ()
        DialogStack.Push("dataBox/DataBox")
    end,
    check = function ()
        return openLevel.GetStatus(8100)
    end,
    get = function ()
        return openLevel.GetCloseInfo(8100)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(8100))
    end 
}


--排行榜
local dialogTab_42 = {
    go = function (idx)
        idx = idx and idx ~= 0 and idx or 1, --默认星星排行榜1~4 (等级，星星，财力，爬塔)
        DialogStack.Push("rankList/rankListFrame",idx)
    end,
    check = function ()
        return openLevel.GetStatus(2204)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2204)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2204))
    end  
}

--装备图鉴
local dialogTab_43 = {
    go = function (suit_id)
        if not suit_id or suit_id == 0 then
            DialogStack.PushPrefStact("dataBox/suitsManualFrame", {suitId = suit_id,hideSuits = true})
        else
            DialogStack.Push("dataBox/suitsManualFrame")
        end
    end,
    check = function ()
        return openLevel.GetStatus(8100)
    end,
    get = function ()
        return openLevel.GetCloseInfo(8100)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(8100))
    end 
}

--盗团资料
local dialogTab_44 = {
    go = function (idx)
        idx = idx and idx ~= 0 and idx
        if idx then --某个盗团
            DialogStack.Push("dataBox/UnionData", {consortia_id = idx});
        else--盗团资料总览
            DialogStack.Push("dataBox/UnionOverview")
        end
    end,
    check = function ( ... )
        return openLevel.GetStatus(8102)
    end,
    get = function ( ... )
        return openLevel.GetCloseInfo(8102)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(8102))
    end 
}

--人物传记
local dialogTab_45 = {
    go = function (npc_id)
        local _npc_Friend_list = {}
        if npc_id then
            local npcConfig = require "config.npcConfig"
            for k,v in pairs(npcConfig.GetNpcFriendList()) do
                if v.npc_id == npc_id then
                    _npc_Friend_list[1] = v
                    break
                end
            end
        end
        if next(_npc_Friend_list) then
            DialogStack.PushPrefStact("dataBox/NpcData", {pos = 1, npcFriendData = _npc_Friend_list});
        else
            DialogStack.Push("dataBox/NpcRelationship")
        end
    end,
    check = function ()
        return openLevel.GetStatus(8101)
    end,
    get = function ()
        return openLevel.GetCloseInfo(8101)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(8101))
    end
}

--成就
local dialogTab_46 = {
    go = function (idx)
        --local idx 从0~7 开始 总览，成长，历程-- local sub_idx 分页签
        idx = idx or 0
        DialogStack.Push("newAchievement/newAchievement",{idx = idx,second = 0})
    end,
    check = function ()
        return openLevel.GetStatus(2701)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2701)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2701))
    end 
}

local function checkFightStatus (fight_id)
    fight_id = tonumber(fight_id)
    local fightInfo = module.FightModule.GetFightInfo(fight_id)
    if fightInfo then
        return fightInfo:IsOpen()
    else
        ERROR_LOG("fightInfo is nil,gid",fight_id)
        return false
    end
end

local function getFightCloseInfo(fight_id)
    fight_id = tonumber(fight_id)
    local fightInfo = module.FightModule.GetFightInfo(fight_id)
    if fightInfo then
        if not fightInfo:IsOpen() then
            return "战斗未解锁"
        end
    else
        ERROR_LOG("fightInfo is nil,gid",fight_id)
        return "战斗不存在"
    end
end

local function showFightCloseInfo(fight_id)
    fight_id = tonumber(fight_id)
    local fightInfo = module.FightModule.GetFightInfo(fight_id)
    if fightInfo then
        if not fightInfo:IsOpen() then
            showDlgError(nil,SGK.Localize:getInstance():getValue("战斗未解锁"))
        end
    else
        ERROR_LOG("fightInfo is nil,gid",fight_id)
        showDlgError(nil,SGK.Localize:getInstance():getValue("战斗不存在"))
    end
end

--历练副本
local dialogTab_51 = {
    go = function (fight_id)
        if fight_id and fight_id ~= 0 then--某一场战斗
            MapHelper.OpFightInfo(fight_id)
        else
            DialogStack.Push("newSelectMap/selectMap",{idx = 1})
        end
    end,
    check = function (fight_id)
        if fight_id and fight_id ~= 0 then--某一场战斗
            return checkFightStatus(fight_id)
        else
            return true
        end
    end,
    get = function (fight_id)
        if fight_id and fight_id ~= 0 then--某一场战斗
            return getFightCloseInfo(fight_id)
        end
    end,
    show = function (fight_id)
        if fight_id and fight_id ~= 0 then--某一场战斗
            showFightCloseInfo(fight_id)
        end
    end 
}

--伙伴副本
local dialogTab_52 = {
    go = function (fight_id)
        if fight_id and fight_id ~= 0 then--某一场战斗
            MapHelper.OpFightInfo(fight_id)
        else
            DialogStack.Push("newSelectMap/selectMap",{idx = 2})
        end
    end,

    check = function (fight_id)
        if openLevel.GetStatus(2202) then
            if fight_id and fight_id ~= 0 then--某一场战斗
                return checkFightStatus(fight_id)
            else
                return true
            end
        else
            return false
        end
    end,
    get = function (fight_id)
        if openLevel.GetStatus(2202) then
            if fight_id and fight_id ~= 0 then--某一场战斗
                return getFightCloseInfo(fight_id)
            end
        else
            return openLevel.GetCloseInfo(2202)
        end
    end,
    show = function (fight_id)
        if openLevel.GetStatus(2202) then
            if fight_id and fight_id ~= 0 then--某一场战斗
                showFightCloseInfo(fight_id)
            end
        else
            showDlgError(nil, openLevel.GetCloseInfo(2202))
        end
    end 
}


--组队副本
local dialogTab_53 = {
    go = function (fight_id)
        if fight_id and fight_id ~= 0 then--某一场战斗
            DialogStack.Push("newSelectMap/activityInfo", {gid = tonumber(fight_id)})
        else
            DialogStack.Push("newSelectMap/selectMap",{idx = 3})
        end
    end,
    check = function (fight_id)
        if openLevel.GetStatus(1221) then
            if fight_id and fight_id ~= 0 then--某一场战斗
                return checkFightStatus(fight_id)
            else
                return true
            end
        else
            return false
        end
    end,
    get = function (fight_id)
        if openLevel.GetStatus(1221) then
            if fight_id and fight_id ~= 0 then--某一场战斗
                return getFightCloseInfo(fight_id)
            end
        else
            openLevel.GetCloseInfo(1221)
        end
    end,
    show = function (fight_id)
        if openLevel.GetStatus(1221) then
            if fight_id and fight_id ~= 0 then--某一场战斗
                showFightCloseInfo(fight_id)
            end
        else
            showDlgError(nil, openLevel.GetCloseInfo(1221))
        end
    end  
}

--打开基地界面 
local dialogTab_100 = {
    go = function (idx)
        idx = idx and idx ~= 0 and idx
        if idx then--1酒馆  2石头  3木头 4鱼  5藤蔓
            MapHelper.EnterManorBuilding(idx)
        else -- 总览
            DialogStack.Push("Manor_Overview")
        end
    end,
    check = function ()
        return openLevel.GetStatus(2001)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2001)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2001))
    end
}

--好友庄园
local dialogTab_101 = {
    go = function ()
        DialogStack.Push("manor/ManorFriend")
    end,
    check = function ()
        return openLevel.GetStatus(2001)
    end,
    get = function ()
        return openLevel.GetCloseInfo(2001)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(2001))
    end 
}

--公会
local dialogTab_200 = {
    go = function (idx)
        local idx = idx or 0
        if idx == 1 then--公会投资
            DialogStack.PushMapScene("newUnion/newUnionInvestment")
        elseif idx == 2 then--公会物资
            DialogStack.PushMapScene("newUnion/newUnionWish")
        elseif idx == 3 then--公会探险
            DialogStack.PushMapScene("newUnion/newUnionExplore")
        else--公会总览
            DialogStack.PushMapScene("newUnion/newUnionFrame")
        end
    end,
    check = function (idx)
        if openLevel.GetStatus(2101) then
            local uninInfo = module.unionModule.Manage:GetSelfUnion();
            if uninInfo and next(uninInfo) then
                if idx == 3 then--公会探险
                    if not module.unionScienceModule.GetScienceInfo(12) or module.unionScienceModule.GetScienceInfo(12).level <=0 then
                        return false
                    end
                end
            else
                return false
            end
        else
            return false
        end
        return true
    end,
    get = function (idx)
        if openLevel.GetStatus(2101) then
            local uninInfo = module.unionModule.Manage:GetSelfUnion();
            if uninInfo and next(uninInfo) then
                if idx == 3 then
                    if not module.unionScienceModule.GetScienceInfo(12) or module.unionScienceModule.GetScienceInfo(12).level <=0 then
                        return SGK.Localize:getInstance():getValue("guild_tech_lock")
                    end
                end
            else
                return SGK.Localize:getInstance():getValue("dati_tips_05")
            end
        else
            return openLevel.GetCloseInfo(2101)
        end
    end,
    show = function (idx)
        if openLevel.GetStatus(2101) then
            local uninInfo = module.unionModule.Manage:GetSelfUnion();
            if uninInfo and next(uninInfo) then
                if idx == 3 then
                    if not module.unionScienceModule.GetScienceInfo(12) or module.unionScienceModule.GetScienceInfo(12).level <=0 then
                        showDlgError(nil, SGK.Localize:getInstance():getValue("guild_tech_lock"))
                    end
                end
            else
                showDlgError(nil,SGK.Localize:getInstance():getValue("dati_tips_05"))
            end
        else
            showDlgError(nil, openLevel.GetCloseInfo(2101))
        end
    end 
}

--活动面板
local dialogTab_300 = {
    go = function (activityId)
        activityId = activityId and activityId ~= 0 and activityId
        DialogStack.Push("mapSceneUI/newMapSceneActivity", {activityId = activityId,filter = {flag = false, id = 1003}})
    end,
    check = function ()
        return openLevel.GetStatus(1201)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1201)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1201))
    end
}


--活动[挑战]
--神陵关卡
    --总览
local dialogTab_301 = {
    go = function (map_id)
        map_id = map_id and map_id ~= 0 and map_id or 10
        DialogStack.Push("buildCity/buildCityFrame",{map_Id = map_id,Idx = 1})
    end,
    check = function ()
        return openLevel.GetStatus(4001)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4001)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4001))
    end
}
    --扭蛋
local dialogTab_302 = {
    go = function (map_id)
        map_id = map_id and map_id ~= 0 and map_id or 10
        DialogStack.Push("buildCity/buildCityFrame",{map_Id = map_id,Idx = 2})
    end,
    check = function ()
        return openLevel.GetStatus(4001)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4001)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4001))
    end
}
    --商店
local dialogTab_303 = {
    go = function (map_id)
        map_id = map_id and map_id ~= 0 and map_id or 10
        DialogStack.Push("buildCity/buildCityFrame",{map_Id = map_id,Idx = 3})
    end,
    check = function ()
        return openLevel.GetStatus(4001)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4001)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4001))
    end
}
    --科技
local dialogTab_304 = {
    go = function (map_id)
        map_id = map_id and map_id ~= 0 and map_id or 10
        DialogStack.Push("buildCity/buildCityFrame",{map_Id = map_id,Idx = 4})
    end,
    check = function ()
        return openLevel.GetStatus(4001)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4001)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4001))
    end
}

--打开趣味答题界面
local dialogTab_311 = {
    go = function ()
        DialogStack.Push("answer/answer")
    end,
    check = function ()
        return openLevel.GetStatus(1251)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1251)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1251))
    end
}

--答题竞赛
local dialogTab_312 = {
    go = function ()
        DialogStack.Push("answer/weekAnswerFrame")
    end,
    check = function ()
        return openLevel.GetStatus(1252)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1252)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1252))
    end
}

--神陵秘宝
local dialogTab_313 = {
    go = function ()
        showDlgError(nil,"神陵秘宝")
        ERROR_LOG("神陵秘宝")
    end,
    check = function ()
        return openLevel.GetStatus(4005)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4005)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4005))
    end
}


--试练塔
local dialogTab_314 = {
    go = function ()
        SceneStack.EnterMap(501,{pos = module.trialModule.GetPos()})
    end,
    check = function ()
        return openLevel.GetStatus(3101)
    end,
    get = function ()
        return openLevel.GetCloseInfo(3101)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(3101))
    end
}

--迷宫寻宝
local dialogTab_315 = {
    go = function ()
        showDlgError(nil,"迷宫寻宝")
        ERROR_LOG("迷宫寻宝")
    end,
    check = function ()
        return openLevel.GetStatus(1303)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1303)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1303))
    end
}

--领主降临
local dialogTab_316 = {
    go = function ()
        showDlgError(nil,"领主降临")
        ERROR_LOG("领主降临")
    end,
    check = function ()
        return openLevel.GetStatus(4006)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4006)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4006))
    end
}

--活动[公会]
    --公会领主
local dialogTab_351 = {
    go = function ()
        showDlgError(nil,"公会领主")
        ERROR_LOG("公会领主")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

    --公会答题
local dialogTab_352 = {
    go = function ()
        showDlgError(nil,"公会答题")
        ERROR_LOG("公会答题")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}
    --公会钓鱼
local dialogTab_353 = {
    go = function ()
        showDlgError(nil,"公会钓鱼")
        ERROR_LOG("公会钓鱼")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

    --海盗入侵
local dialogTab_354 = {
    go = function ()
        showDlgError(nil,"海盗入侵")
        ERROR_LOG("海盗入侵")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

    --公会宴会
local dialogTab_355 = {
    go = function ()
        showDlgError(nil,"公会宴会")
        ERROR_LOG("公会宴会")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}
    --公会寻宝
local dialogTab_356 = {
    go = function ()
        showDlgError(nil,"公会寻宝")
        ERROR_LOG("公会寻宝")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

    --公会战
local dialogTab_357 = {
    go = function ()
        showDlgError(nil,"--公会战")
        ERROR_LOG("--公会战")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

    --关卡争夺
local dialogTab_358 = {
    go = function ()
        showDlgError(nil,"--关卡争夺")
        ERROR_LOG("--关卡争夺")
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
}

--活动[合作]
--元素暴走
local dialogTab_381 = {
    go = function ()
        utils.SGKTools.Map_Interact(551)
    end,
    check = function ()
        return openLevel.GetStatus(1241)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1241)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1241))
    end
}

--棱镜探险
local dialogTab_382 = {
    go = function ()
        module.mazeModule.Start(601);
    end,
    check = function ()
        return openLevel.GetStatus(1242)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1242)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1242))
    end
}

--基地保卫战
local dialogTab_383 = {
    go = function () 
        utils.SGKTools.Map_Interact(67)
    end,
    check = function ()
        return openLevel.GetStatus(1299)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1299)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1299))
    end
}

--陵兽暴动
local dialogTab_384 = {
    go = function ()
        showDlgError(nil,"--陵兽暴动")
        ERROR_LOG("--陵兽暴动")
    end,
    check = function ()
        return openLevel.GetStatus(4007)
    end,
    get = function ()
        return openLevel.GetCloseInfo(4007)
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(4007))
    end
}


--竞技面板
local dialogTab_400 = {
    go = function (activityId)--竞技面板
        activityId = activityId and activityId ~= 0 and activityId
        DialogStack.Push("mapSceneUI/newMapSceneActivity", {activityId = activityId,filter = {flag = true, id = 1003}}) 
    end,
    check = function ( ... )
        return openLevel.GetStatus(2205)
    end,
    get = function ( ... )
        return openLevel.GetCloseInfo(2205)
    end,
    show = function ( ... )
        showDlgError(nil, openLevel.GetCloseInfo(2205))
    end 
}

--排名竞技场界面
local dialogTab_401 = {
    go = function ()
       DialogStack.Push("traditionalArena/traditionalArenaFrame")
    end,
    check = function ( ... )
        return openLevel.GetStatus(1902)
    end,
    get = function ( )
        return openLevel.GetCloseInfo(1902)           
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1902))
    end
}

--英雄比拼界面
local dialogTab_402 = {
    go = function ()
       DialogStack.Push("PveArenaFrame")
    end,
    check = function ()
        return openLevel.GetStatus(1911)
    end,
    get = function ( )
        return openLevel.GetCloseInfo(1911)           
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1911))
    end 
}

--财力竞技场界面
local dialogTab_403 = {
    go = function ()
        DialogStack.Push("PvpArena_Frame")
    end,
    check = function ( ... )
        return openLevel.GetStatus(1901)
    end,
    get = function ( ... )
        return openLevel.GetCloseInfo(1901)
    end,
    show = function ( ... )
        showDlgError(nil, openLevel.GetCloseInfo(1901))
    end 
}

--虚空镜界
local dialogTab_404 = {
    go = function ()
        DialogStack.Push("expOnline/expOnline")
    end,
    check = function ()
        return openLevel.GetStatus(1921)
    end,
    get = function ()
        return openLevel.GetCloseInfo(1921)           
    end,
    show = function ()
        showDlgError(nil, openLevel.GetCloseInfo(1921))
    end 
}

--地图
local dialogTab_500 = {
    go = function (map_id)
        module.EncounterFightModule.GUIDE.EnterMap(map_id)
    end,
    check = function ( ... )
        return openLevel.GetStatus(2601)
    end,
    get = function ( ... )
        return openLevel.GetCloseInfo(2601)
    end,
    show = function ( ... )
        showDlgError(nil, openLevel.GetCloseInfo(2601))
    end 
}  

--npc
local dialogTab_501 = {
    go = function (npc_id)
        local function Change_map(map_id)
            if map_id ~= SceneStack.MapId() then
                utils.SGKTools.PlayerMoveZERO()
                utils.SGKTools.loadEffect("UI/fx_chuan_ren")
                utils.SGKTools.PLayerConceal(true)
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
                module.EncounterFightModule.GUIDE.Interact("NPC_"..npc_id)
            else
                if quest.accept_npc_id ~= 0 then
                    module.EncounterFightModule.GUIDE.Interact("NPC_"..quest.accept_npc_id)
                end
            end
        end

        local npc_confs = MapHelper.GetConfigTable("all_npc","gid") or {}
        if npc_confs and npc_confs[npc_id] and npc_confs[npc_id][1] and npc_confs[npc_id][1].mapid then
            local map_id = npc_confs[npc_id][1].mapid
            Change_map(map_id)
            TrackNpc(nil,npc_id)
        end
    end,
    check = function ( ... )
        return true
    end,
    get = function ( ... )
        -- body
    end,
    show = function ( ... )
        -- body
    end 
} 

local Router = {
    [1] = dialogTab_1,
    --养成界面进阶
    [2] = dialogTab_2,
    --养成界面升星
    [3] = dialogTab_3,
    --每日任务
    [4] = dialogTab_4,
    --聊天
    [9] = dialogTab_9,
    --好友
    [10] = dialogTab_10,
    --打开狩猎界面
    [11] = dialogTab_11,
    --打开任务界面
    [12] = dialogTab_12,
    --邮箱
    [13] = dialogTab_13,
    --历练笔记
    [14] = dialogTab_14,
    --阵容
    [21] = dialogTab_21,
    --商店
    [31] = dialogTab_31,
    --占卜
    [32] = dialogTab_32,
    --交易行
    [33] = dialogTab_33,
    --资料柜
    [40] = dialogTab_40,
    --排行榜
    [42] = dialogTab_42,
    --装备图鉴
    [43] = dialogTab_43,
    --盗团资料
    [44] = dialogTab_44,
    --人物传记
    [45] = dialogTab_45,
    --成就
    [46] = dialogTab_46,
    --历练副本
    [51] = dialogTab_51,
    --伙伴副本
    [52] = dialogTab_52,
    --组队副本
    [53] = dialogTab_53,
    --打开基地界面 
    [100] = dialogTab_100,
    --好友庄园
    [101] = dialogTab_101,
    --公会
    [200] = dialogTab_200,
    --活动面板
    [300] = dialogTab_300,
    --活动[挑战]
    --神陵关卡
        --总览
    [301] = dialogTab_301,
        --扭蛋
    [302] = dialogTab_302,
        --商店
    [303] = dialogTab_303,
        --科技
    [304] = dialogTab_304,
    --打开趣味答题界面
    [311] = dialogTab_311,
    --答题竞赛
    [312] = dialogTab_312,
    --神陵秘宝
    [313] = dialogTab_313,
    --试练塔
    [314] = dialogTab_314,
    --迷宫寻宝
    [315] = dialogTab_315,
    --领主降临
    [316] = dialogTab_316,
    --活动[公会]
        --公会领主
    [351] = dialogTab_351,
        --公会答题
    [352] = dialogTab_352,
        --公会钓鱼
    [353] = dialogTab_353,
        --海盗入侵
    [354] = dialogTab_354,
        --公会宴会
    [355] = dialogTab_355,
        --公会寻宝
    [356] = dialogTab_356,
        --公会战
    [357] = dialogTab_357,
        --关卡争夺
    [358] = dialogTab_358,

    --活动[合作]
    --元素暴走
    [381] = dialogTab_381,
    --棱镜探险
    [382] = dialogTab_382,
    --基地保卫战
    [383] = dialogTab_383,
    --陵兽暴动
    [384] = dialogTab_384,
    --竞技面板
    [400] = dialogTab_400,
    --排名竞技场界面
    [401] = dialogTab_401,
    --英雄比拼界面
    [402] = dialogTab_402,
    --财力竞技场界面
    [403] = dialogTab_403,
    --虚空镜界
    [404] = dialogTab_404,
    --地图
    [500] = dialogTab_500,
    --npc
    [501] = dialogTab_501,
}

local function Go(type,...)

    if Router[type] then
        if Router[type].check(...) then
            Router[type].go(...)
        else
            Router[type].show(...)
        end
    else
        showDlgError(nil,"未知物品来源")
        ERROR_LOG("未知物品来源",...)
    end
end

local function Check(type,... )
    if Router[type] then
        return Router[type].check(...)
    else
        showDlgError(nil,"未知物品来源")
        ERROR_LOG("未知物品来源",...)
    end
end

local function GetCloseInfo(type,...)
    if Router[type] then
        return Router[type].get(...)
    else
        showDlgError(nil,"未知物品来源")
        ERROR_LOG("未知物品来源",type,...)
    end
end

local function ShowCloseInfo(type,...)
    if Router[type] then
        Router[type].show(...)
    else
        showDlgError(nil,"未知物品来源")
        ERROR_LOG("未知物品来源",type,...)
    end
end

return {
    Go = Go,
    Check = Check,
    Get = GetCloseInfo,
    Show = ShowCloseInfo,
}
