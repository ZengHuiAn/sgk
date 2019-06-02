local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local OpenLevel = require "config.openLevel"
local HeroModule=require "module.HeroModule";
local HeroEvo = require "hero.HeroEvo"
local heroStar = require"hero.HeroStar"

--请求角色重生
local function RoleReborn(gid,uuid)
    NetworkService.Send(207, {nil,gid,uuid})
end

local function TableAddCount(table,data)
    for i=1,#table do
        if table[i].id == data.id then
            table[i].count = table[i].count + data.count
            return table
        end
    end
    table[#table +1] = {id = data.id,count = data.count,type = data.type}
    return table
end

local function ExchangeEXP(exp)
    local expList = {}
    local shop = module.ShopModule.GetManager(3)
    ERROR_LOG("3号商店",exp,sprinttb(shop))
    local count = 0
    if exp >= shop.shoplist[1030004].product_item_value then
        count = math.floor(exp/shop.shoplist[1030004].product_item_value)
        exp = exp%shop.shoplist[1030004].product_item_value
        expList[#expList + 1]={id = shop.shoplist[1030004].consume_item_id1,count = count,type = shop.shoplist[1030004].consume_item_type1}
    end
    if exp >= shop.shoplist[1030003].product_item_value then
        count = math.floor(exp/shop.shoplist[1030003].product_item_value)
        exp = exp%shop.shoplist[1030003].product_item_value
        expList[#expList + 1]={id = shop.shoplist[1030003].consume_item_id1,count = count,type = shop.shoplist[1030003].consume_item_type1}
    end
    if exp >= shop.shoplist[1030002].product_item_value then
        count = math.floor(exp/shop.shoplist[1030002].product_item_value)
        exp = exp%shop.shoplist[1030002].product_item_value
        expList[#expList + 1]={id = shop.shoplist[1030002].consume_item_id1,count = count,type = shop.shoplist[1030002].consume_item_type1}
    end
    if exp >= shop.shoplist[1030001].product_item_value then
        count = math.floor(exp/shop.shoplist[1030001].product_item_value)
        exp = exp%shop.shoplist[1030001].product_item_value
        expList[#expList + 1]={id = shop.shoplist[1030001].consume_item_id1,count = count,type = shop.shoplist[1030001].consume_item_type1}
    end
    ERROR_LOG("经验结果",sprinttb(expList))
    return expList
end

local function ExchangeAdv(stage,heroId)
    local advList = {}
    local heroAdvCfg = HeroEvo.GetRoleAdvCfg(heroId)
    ERROR_LOG("进阶表",sprinttb(heroAdvCfg))
    for i=1,stage do
        local cfg = heroAdvCfg[i]
        for k,v in pairs(cfg.consume) do
            if #advList == 0 then
                advList[#advList + 1] = {id = v.id,count = v.value,type = v.type}
            else
                advList = TableAddCount(advList,{id = v.id,count = v.value,type = v.type})
            end
        end    
    end
    ERROR_LOG("进阶结果",sprinttb(advList)) 
    return advList
end

local function ExchangeStar(star,heroId)
    local starList = {}
    local heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    local _cfg = module.TalentModule.GetSkillSwitchConfig(heroId)
    local skill_heroId = heroId
    if _cfg then
        skill_heroId = _cfg[heroCfg.property_value].skill_star;
    end
    local _, _roleStar = heroStar.GetroleStarTab()
    local roleStarTab = _roleStar[skill_heroId]
    ERROR_LOG("升星表",sprinttb(roleStarTab))
    for i=1,star do
        local cfg = roleStarTab[i]
        for i=1,3 do
            if cfg["cost_id"..i] and cfg["cost_id"..i] ~= 0 then
                if #starList == 0 then
                    starList[#starList + 1] = {id = cfg["cost_id"..i],count = cfg["cost_value"..i],type = 41}
                else
                    starList = TableAddCount(starList,{id = cfg["cost_id"..i],count = cfg["cost_value"..i],type = 41})
                end
            end
        end    
    end
    ERROR_LOG("升星结果",sprinttb(starList))
    return starList
end

local function GetRoleRebornRewardList(heroId)
    local allList = {}
    local Hero = HeroModule.GetManager():Get(heroId)
    --ERROR_LOG("重生角色信息",self.Hero.pid,self.Hero.uuid,self.Hero.exp,sprinttb(self.Hero))
    local heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    local expList = ExchangeEXP(Hero.exp)
    allList = expList
    local advList = ExchangeAdv(heroCfg.stage,heroId)
    for k,v in pairs(advList) do
        TableAddCount(allList,v)
    end
    local starList = ExchangeStar(heroCfg.star,heroId)
    for k,v in pairs(starList) do
        TableAddCount(allList,v)
    end
    ERROR_LOG("获取重生资源列表",sprinttb(allList))
    return allList
end

--角色重生返回
EventManager.getInstance():addListener("server_respond_208", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    ERROR_LOG("重生返回",sprinttb(data))
    if err == 0 then
        ERROR_LOG("重生成功")
        utils.EventManager.getInstance():dispatch("ROLE_REBORN_SUCCESS")
    else
        ERROR_LOG("RoleReborn failed",err)
    end   
end)




-- 碎片转换

local viewTable = {}

local function ViewTableAdd(idx,data)
    --if not viewTable[idx] then
        viewTable[idx] = data
    -- else
    --     viewTable[idx].count = data.count 
    -- end 
end

local function ViewTableGet()
    return viewTable
end

local function ClearViewTable()
    viewTable = {}
end

local function GetTotal()
    local total = {}
    for k,v in pairs(viewTable) do
       if not total[v.id] then
            total[v.id] = v.count
        else
            total[v.id] = total[v.id] + v.count
        end
    end
    return total
end

return {
    RoleReborn = RoleReborn,
    GetRoleRebornRewardList = GetRoleRebornRewardList,

    ViewTableAdd = ViewTableAdd,
    ViewTableGet = ViewTableGet,
    ClearViewTable = ClearViewTable,
    GetTotal = GetTotal,
}
