local RedDotModule = require "module.RedDotModule"
local QuestModule = require "module.QuestModule"

---战斗中出现的按钮
local FightingBtnInfo = {
    --[[-开服七天
    [2] = {
        ---双子星
        {dialogName = "mapSceneUI/guideLayer/guideFashion", openLevel = 5003, questId = module.guideLayerModule.Type.FashionLayer},
        ---陆游七
        {dialogName = "mapSceneUI/guideLayer/guideOnlineRewards", openLevel = 5007, canOpen = module.guideLayerModule.CheckOnline, redFunc = module.guideLayerModule.CheckOnline},
        ---肖斯塔亚
        {dialogName = "mapSceneUI/guideLayer/guideGetTitle", openLevel = 5004, questId = module.guideLayerModule.Type.Title},
        ---7日计划
        {dialogName = "SevenDaysActivity", canOpen = QuestModule.GetSevenDayOpen},
        ---拍卖行
        {dialogName = "Trade_Dialog", openLevel = 5002},
        ---排行
        {dialogName = "rankList/rankListFrame"},
    },

        ---福利
        {dialogName = "welfareActivity", openLevel = 1301,red = RedDotModule.Type.WelfareActivity.WelfareActivity},
        ---商店
        {dialogName = "ShopFrame", openLevel = 2401},
        ---招募
        {dialogName = "DrawCard/newDrawCardFrame", openLevel = 1801, red = RedDotModule.Type.DrawCard.DrawCardFree},
        ---活动
        {dialogName = "FriendSystem/FriendMail", red = RedDotModule.Type.Mail.Mail, data = {idx = 3}},
        -- ---基地
        -- {dialogName = "Manor_Overview", openLevel = 2001, red = RedDotModule.Type.Manor.Manor},
        --
        -- ---成就
        -- {dialogName = "achievement/achievementFrame", openLevel = 2701, red = RedDotModule.Type.Achievement.Achievement},
        -- ---邮件
        -- {dialogName = "FriendSystemList", red = RedDotModule.Type.Mail.Mail, data = {idx = 3}},
        -- ---设置
        -- {dialogName = "SettingFrame"},

        dailyTask
    --]]
    [1] = {
        ---背包
        {dialogName = "ItemBagNew", openLevel = 2301},
        ---公会
        {dialogName = "newUnion/newUnionFrame", openLevel = 2101},
        ---任务
        {dialogName = "mapSceneUI/newQuestList", openLevel = 1401},
        ---组队
        {dialogName = "TeamFrame", openLevel = 1221},
        ---好友
        {dialogName = "FriendSystemList", openLevel = 2501},
    },

    [2] = {
        ---每日任务
        {dialogName = "mapSceneUI/dailyTask", openLevel = 3201},
        ---变强
        {dialogName = "mapSceneUI/stronger/newStrongerFrame", openLevel = 2901},
        ---设置
        {dialogName = "SettingFrame"},
    },

    [3] = {
        ---培养
        {dialogName = "Role_Frame", openLevel = 1101},
        ---阵容
        {dialogName = "FormationDialog", openLevel = 1701},
        ---占卜
        {dialogName = "DrawCard/newDrawCardFrame", openLevel = 1801},
        ---商店
        {dialogName = "ShopFrame", openLevel = 2401},
        ---交易行
        {dialogName = "Trade_Dialog", openLevel = 5002},
    },

    [4] = {
        ---竞技
        {dialogName = "mapSceneUI/newMapSceneActivity", openLevel = 2205, data = {filter = {flag = true, id = 1003}}},
        ---活动
        {dialogName = "mapSceneUI/newMapSceneActivity", openLevel = 1201, data = {filter = {flag = false, id = 1003}}},
        ---基地
        {dialogName = "Manor_Overview", openLevel = 2001},
        ---邮件
        {dialogName = "FriendSystem/FriendMail", openLevel = 1501},
    },
}

local function getMailIdx()
    local _status, _idx = RedDotModule.CheckModlue:checkMailAndAward()
    if _idx then
        return {idx = _idx}
    end
    return {idx = 3}
end

local MapSceneTopBtn = {
    ---零号计划
    {dialog = "mapSceneUI/guideLayer/zeroPlan", openLevel = 5008, red = RedDotModule.Type.MapSceneUI.ZeroPlan},
    ---福利
    {dialog = "welfareActivity", openLevel = 1301, red = RedDotModule.Type.WelfareActivity.WelfareActivity},
    ---每日任务
    {dialog = "mapSceneUI/dailyTask", openLevel = 3201, red = RedDotModule.Type.MapSceneUI.DailyTask},
    ---七日
    {dialog = "SevenDaysActivity", openLevel = 1312, red = RedDotModule.Type.SevenDays.SevenDays},
    ---幸运币
    {dialog = "fightResult/luckyCoin", openLevel = 1331, data = {idx = 2}},
    --争夺战
    {callback = module.GuildSeaElectionModule.OpenGrabWarFrame, openLevel = 2107, canOpen = module.GuildSeaElectionModule.CheckApplyTime},
    {callback = module.GuildSeaElectionModule.OpenGrabWarFrame, openLevel = 2107, canOpen = module.GuildSeaElectionModule.CheckFightTime},
}

---大地图 下方角按钮栏
local MapSceneBottomBtn = {
    ---伙伴
    {red = RedDotModule.Type.Hero.AllHero},
    ---背包
    {dialog = "ItemBagNew", openLevel = 2301},
    ---商店
    {red = RedDotModule.Type.Shop.All},
    ---公会
    {dialog = "newUnion/newUnionFrame", openLevel = 2101,red = RedDotModule.Type.Union.AllUnion},
    -- {mapName = 25, openLevel = 2101, red = RedDotModule.Type.Union.Union, teamDialog = "newUnion/newUnionFrame"},
    --地图
    {dialog = "bigMap/bigMap", openLevel = 2601, forbidMap = {67, 551, 601}},
    ---副本
    {dialog = "newSelectMap/selectMap"}
}

---大地图上方展开列表
local MapSceneTopListBtn = {
    ---购买体力
    {dialog = "ShopFrame", openLevel = 2401},
    ---查看成就
    {dialog = "achievement/achievementFrame", openLevel = 2701},
    ---更换形象
    {dialog = "mapSceneUI/newPlayerInfoFrame", openLevel = 2701},
    ---设置
    {dialog = "SettingFrame", openLevel = 2701},
}

local MapSceneBottomRole = {
    ---伙伴
    {dialog = "Role_Frame", openLevel = 1101, red = RedDotModule.Type.Hero.AllHero},
    ---阵容
    {dialog = "FormationDialog", openLevel = 1701},

    {dialog = "roleReborn/RoleRebornFrame"}
}

local MapSceneBottomShop = {
    ---抽卡
    {dialog = "DrawCard/newDrawCardFrame", openLevel = 1801, red = RedDotModule.Type.DrawCard.DrawCardFree},
    ---商店
    {dialog = "ShopFrame", openLevel = 2401, red = RedDotModule.Type.Shop.FlashSaleShopRefresh},
    ---拍卖行
    {dialog = "Trade_Dialog", openLevel = 5002},
}

local MapSceneBottomCompetition = {
    {dialog = "traditionalArena/traditionalArenaFrame", openLevel = 1902},
    {dialog = "PveArenaFrame", openLevel = 1911, red = RedDotModule.Type.Arena.Arena},
    {dialog = "trial/trialTower", openLevel = 3101},
    {dialog = "expOnline/expOnline", openLevel = 1921},
    {dialog = "PvpArena_Frame", openLevel = 1901, red = RedDotModule.Type.PVPArena.PVPArena},
    {dialog = "guild_pvp/GuildPVPJoinPanel", openLevel = 1911},

}

local MapSceneBottomLeaveNode = {
    --公会
    {mapName = 25, openLevel = 2101, red = RedDotModule.Type.Union.Union, teamDialog = "newUnion/newUnionFrame"},
    --庄园
    {mapName = 26, openLevel = 2001, teamDialog = "Manor_Overview", red = RedDotModule.Type.Manor.Quest},
    --大地图
    {dialog = "bigMap/bigMap"},
}

return {
    FightingBtnInfo = FightingBtnInfo,
    MapSceneBottomBtn = MapSceneBottomBtn,
    MapSceneTopBtn = MapSceneTopBtn,
    MapSceneTopListBtn = MapSceneTopListBtn,
    MapSceneBottomRole = MapSceneBottomRole,
    MapSceneBottomCompetition = MapSceneBottomCompetition,
    MapSceneBottomShop = MapSceneBottomShop,
    MapSceneBottomLeaveNode = MapSceneBottomLeaveNode,
}
