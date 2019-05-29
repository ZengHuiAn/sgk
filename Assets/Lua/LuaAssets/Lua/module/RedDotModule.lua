local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local activityModule = require "module.unionActivityModule"
local timeModule = require "module.Time"
local EventManager = require 'utils.EventManager'
local ItemModule = require "module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local heroModule = require "module.HeroModule"
local heroStar = require"hero.HeroStar"
local equipmentModule = require "module.equipmentModule"
local equipmentConfig = require "config.equipmentConfig"
local ShopModule = require "module.ShopModule"
local arenaModule = require 'module.arenaModule'
local TalentModule = require "module.TalentModule"
local HeroLevelup = require "hero.HeroLevelup"
local ManorManufactureModule = require "module.ManorManufactureModule"
local QuestModule = require "module.QuestModule"
local CommonConfig = require "config.commonConfig"
local OpenLevel = require "config.openLevel"
local HeroScroll = require "hero.HeroScroll"
local NotificationCenter = require "utils.NotificationCenter"
local ActivityConfig = require "config.activityConfig"
local UserDefault = require "utils.UserDefault"


local checkModlue = {}
local statusInfo = {}
local masterId = 11000
local MaxStar = 30

local returnType = {
    Close      = 1,
    LevelUp    = 1,
    GetItem    = 3,
    WeaponStar = 4,
    GoLevelUp  = 5,
}

function checkModlue:checkUninInfo()
    if unionModule.Manage:GetSelfUnion() then
        for i = 1, 3 do
            local _memb = unionModule.Manage:GetSelfInfo().awardFlag or {}
            local _conditionValue = unionConfig.GetTeamAward(i, unionModule.Manage:GetSelfUnion().unionLevel).condition_value
            if _memb[i] ~= 1 then
                if _conditionValue <= (unionModule.Manage:GetSelfUnion().todayAddExp or 0) then
                    statusInfo[checkModlue.Type.Union.Info.id] = true
                    return true
                end
            end
        end
    end
    statusInfo[checkModlue.Type.Union.Info.id] = false
    return false
end
--公会投资
function checkModlue:checkUnionInvestment()
    if unionModule.Manage:GetSelfUnion() then

        local sciene_lev = module.unionScienceModule.GetScienceInfo(24) and module.unionScienceModule.GetScienceInfo(24).level or 0
        -- ERROR_LOG("公会投资红点检测========>>>");
        if module.unionModule.Manage:GetSelfInfo().todayDonateCount and module.unionModule.Manage:GetSelfInfo().todayDonateCount < (sciene_lev+1)  then
            statusInfo[checkModlue.Type.Union.Investment.id] = true
            return statusInfo[checkModlue.Type.Union.Investment.id]
        end
    end
    statusInfo[checkModlue.Type.Union.Investment.id] = false
    return false
end

--检测捐献
function checkModlue:checkUnionDonationActivity()
    if unionModule.Manage:GetSelfUnion() then

        local sciene_lev = module.unionScienceModule.GetScienceInfo(13) and module.unionScienceModule.GetScienceInfo(13).level or 0
        if module.unionScienceModule.GetDonationInfo().donationCount and ((5+sciene_lev) - module.unionScienceModule.GetDonationInfo().donationCount) >=1  then

            -- ERROR_LOG(module.unionScienceModule.GetDonationInfo().donationCount);
            statusInfo[checkModlue.Type.Union.Donation.id] = true
            return true
        end
    end
    statusInfo[checkModlue.Type.Union.Donation.id] = false
    return false
end

function checkModlue:checkUnionJoin()
    if unionModule.Manage:GetSelfUnion() then
        for k,v in pairs(unionModule.Manage:GetApply()) do
            statusInfo[checkModlue.Type.Union.Join.id] = true
            return true
        end
    end
    statusInfo[checkModlue.Type.Union.Join.id] = false
    return false
end

--检测公会探险
function checkModlue:checkUnionExplore()
    if unionModule.Manage:GetSelfUnion() then
        if not OpenLevel.GetStatus(2102) then
            statusInfo[checkModlue.Type.Union.Explore.id] = false
            return false
        end
        for k,v in pairs(activityModule.ExploreManage:GetTeamInfo()) do

            -- ERROR_LOG("=======================>>>红点检测",sprinttb(v))
            if v.count == v.maxCount then
                -- ERROR_LOG("=======================>>>红点检测",sprinttb(v))
                statusInfo[checkModlue.Type.Union.Explore.id] = true
                return true
            else
                local info = v;
                if info and #info.rewardDepot > 0 then
                    -- ERROR_LOG("=======================>>>红点检测",sprinttb(v))
                    statusInfo[checkModlue.Type.Union.Explore.id] = true
                    return true
                end
            end
        end
        -- for k,v in pairs(unionConfig.GetExploremapMessage()) do
        --     if activityModule.ExploreManage:GetTeamInfo(k) then
        --         -- ERROR_LOG("红点检测==============>>>>>",sprinttb(v))
        --         statusInfo[checkModlue.Type.Union.Explore.id] = true
        --         return true
        --     end
        -- end
        for k,v in pairs(activityModule.ExploreManage:GetMapEventList()) do
             for j,p in pairs(v) do
                 for h,l in pairs(p) do
                     if l.beginTime < module.Time.now() then
                        -- ERROR_LOG("红点检测==============>>>>>",sprinttb(v))
                         statusInfo[checkModlue.Type.Union.Explore.id] = true
                         return true
                     end
                 end
             end
        end
    end
    statusInfo[checkModlue.Type.Union.Explore.id] = false
    return false
end


--检测公会物资
function checkModlue:checkUnionWish()
    if unionModule.Manage:GetSelfUnion() then
        if not OpenLevel.GetStatus(2103) then
            statusInfo[checkModlue.Type.Union.Wish.id] = false
            return false
        end
        for i,v in ipairs(activityModule.WishManage:GetWishInfoItem()) do
            if v.show then
                statusInfo[checkModlue.Type.Union.Wish.id] = true
                return true
            end
        end
        if activityModule.WishManage:GetWishInfo().has_draw_reward == 0 then
            statusInfo[checkModlue.Type.Union.Wish.id] = true
            return true
        end
        statusInfo[checkModlue.Type.Union.Wish.id] = false
        return false
    else
        return false
    end
end
function checkModlue:checkUnionActivityTime( cfg )   
        local total_pass = module.Time.now() - cfg.begin_time
        local count = math.floor(total_pass / cfg.period) * cfg.period
        local end_time = count + cfg.loop_duration + cfg.begin_time

        local start_time = end_time - cfg.loop_duration;

        if module.Time.now() >= start_time and module.Time.now() < end_time  then

            -- ERROR_LOG(start_time,module.Time.now(),end_time);
            return true
        end
        return false;

end

function checkModlue:checkAllUnionActivity()
    if unionModule.Manage:GetSelfUnion() then
        for k,v in pairs(unionConfig.GetActivity()) do
            if v.activity_type == 2 and checkModlue:checkUnionActivityTime(v) == true then
                statusInfo[checkModlue.Type.Union.UnionActivity.id]  = true;
                return true;
            end
        end
        return false
    else
        return false
    end
end

function checkModlue:checkUnionAll(  )
    if unionModule.Manage:GetSelfUnion() then
        statusInfo[checkModlue.Type.Union.AllUnion.id]  = checkModlue:checkUnionJoin() or checkModlue:checkUnionWish() or checkModlue:checkAllUnionActivity() or checkModlue:checkUnionExplore() or checkModlue:checkUnionDonationActivity() or checkModlue:checkUnionInvestment();
        return statusInfo[checkModlue.Type.Union.AllUnion.id];
    else
        return false
    end
end

function checkModlue:checkUnionActivity()
    if unionModule.Manage:GetSelfUnion() then
        local err = checkModlue:checkUnionExplore();
        -- ERROR_LOG(err);
        err = checkModlue:checkUnionWish();
        -- ERROR_LOG(err);
        err = checkModlue:checkUnionDonationActivity();
        -- ERROR_LOG(err);
        err = checkModlue:checkUnionInvestment();
        -- ERROR_LOG(err);
        

        statusInfo[checkModlue.Type.Union.Activity.id] = checkModlue:checkUnionExplore() or checkModlue:checkUnionWish() or checkModlue:checkUnionDonationActivity() or checkModlue:checkUnionInvestment();
        return statusInfo[checkModlue.Type.Union.Activity.id]
    else
        return false
    end
end

function checkModlue:checkUnion()
    if unionModule.Manage:GetSelfUnion() then
        statusInfo[checkModlue.Type.Union.Union.id] = checkModlue:checkUninInfo() or checkModlue:checkUnionJoin() or checkModlue:checkUnionActivity()
        return statusInfo[checkModlue.Type.Union.Union.id]
    else
        return false
    end
end

EventManager.getInstance():addListener("LOCAL_CHANGE_APPLYLIST", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)

EventManager.getInstance():addListener("LOCAL_EXPLORE_MAPEVENT_CHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)

EventManager.getInstance():addListener("LOCAL_UNION_EXPLORE_TEAMCHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)

EventManager.getInstance():addListener("LOCAL_UNION_REWARD_OK", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)

EventManager.getInstance():addListener("LOCAL_UNIONACTIVITY_GETOVER", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)

EventManager.getInstance():addListener("LOCAL_WISHDATA_CHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)

EventManager.getInstance():addListener("LOCAL_ASSISTDATA_CHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_UNION_CHANE")
end)


--背包 不主动check
--------------------------------------------------------------------
EventManager.getInstance():addListener("ITEM_INFO_CHANGE_BEFORE", function(event, data)
    local showTip=next(ItemModule.GetTempToBagList(data))~=nil
    if data == 1 then      ---碎片
        statusInfo[checkModlue.Type.Bag.Debris.id] = showTip
    elseif data == 4 then  ---商品
        statusInfo[checkModlue.Type.Bag.Goods.id] = showTip
    elseif data == 5 then  ---道具
        statusInfo[checkModlue.Type.Bag.Props.id] = showTip
    end
    DispatchEvent("LOCAL_REDDOT_BAG_CHANE")
end)

--0装备
--1铭文
--2其他
EventManager.getInstance():addListener("EQUIP_INFO_CHANGE_BEFORE", function(event, data)
    local showTip= next(equipmentModule.GetTempToBagList(data))~=nil
    if data == 0 then
        statusInfo[checkModlue.Type.Bag.Equip.id] = showTip
    elseif data == 1 then
        statusInfo[checkModlue.Type.Bag.Insc.id] = showTip
    else
        print("not find type", data)
    end
    DispatchEvent("LOCAL_REDDOT_BAG_CHANE")
end)

function checkModlue:checkBag()
    statusInfo[checkModlue.Type.Bag.Bag.id] = statusInfo[checkModlue.Type.Bag.Debris.id] or statusInfo[checkModlue.Type.Bag.Goods.id] or
                                              statusInfo[checkModlue.Type.Bag.Props.id] or statusInfo[checkModlue.Type.Bag.Equip.id] or
                                              statusInfo[checkModlue.Type.Bag.Insc.id]
    return statusInfo[checkModlue.Type.Bag.Bag.id]
end

function checkModlue:check7days()
    QuestModule.GetCfg();
    statusInfo[checkModlue.Type.SevenDays.SevenDays.id] = QuestModule.GetRedPointState();
    return statusInfo[checkModlue.Type.SevenDays.SevenDays.id];
end

local function NewGetHeroDegree(id,Type)
    local hero = module.HeroModule.GetManager():Get(id)
    if hero then
        local Hero_weapon_Stage = Type == nil and hero.stage or hero.weapon_stage
        local Hero_weapon_Slot = Type == nil and hero.stage_slot or hero.weapon_stage_slot
        local WeaponID = 0
        local role = module.HeroModule.GetConfig(id);
        if role then
            WeaponID = role.weapon
        end
        local HeroEvo = require "hero.HeroEvo"
        local HeroWeaponStage = require "hero.HeroWeaponStage"
        local NowStageHeroConf = hero and (Type == nil and HeroEvo.GetConfig(id)[hero.stage] or HeroWeaponStage.GetConfig(WeaponID)[hero.weapon_stage]) or nil
        local NextStageHeroConf = nil
        if Type == nil then
            NextStageHeroConf = HeroEvo.GetConfig(id)[hero.stage+1]
        else
            NextStageHeroConf = HeroWeaponStage.GetConfig(WeaponID)[hero.weapon_stage+1]
        end
        if NextStageHeroConf then
            local cfg = CommonConfig.Get(100 + Hero_weapon_Stage + 1);
            local heroLevel = cfg and cfg.para2 or 0;

            local LeftItemCount = module.ItemModule.GetItemCount(NextStageHeroConf.cost0_id1)
            local RightItemCount = module.ItemModule.GetItemCount(NextStageHeroConf.cost0_id2)

            local stage_slot_Sum = 0
            for i = 1,6 do
                local itemID = 0
                if i == 1 then
                    itemID = NowStageHeroConf.cost1_id
                elseif i == 2 then
                    itemID = NowStageHeroConf.cost2_id
                elseif i == 3 then
                    itemID = NowStageHeroConf.cost3_id
                elseif i == 4 then
                    itemID = NowStageHeroConf.cost4_id
                elseif i == 5 then
                    itemID = NowStageHeroConf.cost5_id
                elseif i == 6 then
                    itemID = NowStageHeroConf.cost6_id
                end
                local ItemCount = module.ItemModule.GetItemCount(itemID)
                if Hero_weapon_Slot[i] == 1 then--已装备
                    stage_slot_Sum = stage_slot_Sum + 1
                elseif (ItemCount ~= 0) and (ItemCount >= NowStageHeroConf["cost"..i.."_value"]) then--可装备
                    return true
                -- elseif module.ManorManufactureModule.CheckProduct(itemID) == 0 then--可生产
                --     return true
                end
            end

            if NextStageHeroConf.cost0_id1 ~= 0 and LeftItemCount < NextStageHeroConf.cost0_value1 then
                return false
            end
            if NextStageHeroConf.cost0_id2 ~= 0 and RightItemCount < NextStageHeroConf.cost0_value2 then
                return false
            end

            if stage_slot_Sum == 6 and hero.level >= heroLevel then
                return true--可进阶
            else
                if Type then
                    return false
                else
                    return NewGetHeroDegree(id,true)
                end
            end
        else
            return false
        end
    end
end

local function GetHeroDegree(id,Type)
    local hero = module.HeroModule.GetManager():Get(id)
    if hero then
        local Hero_weapon_Stage = Type == nil and hero.stage or hero.weapon_stage
        local Hero_weapon_Slot = Type == nil and hero.stage_slot or hero.weapon_stage_slot
        local WeaponID = 0
        local role = module.HeroModule.GetConfig(id);
        if role then
            WeaponID = role.weapon
        end
        local HeroEvo = require "hero.HeroEvo"
        local HeroWeaponStage = require "hero.HeroWeaponStage"
        local NowStageHeroConf = hero and (Type == nil and HeroEvo.GetConfig(id)[hero.stage] or HeroWeaponStage.GetConfig(WeaponID)[hero.weapon_stage]) or nil
        local NextStageHeroConf = nil
        if Type == nil then
            NextStageHeroConf = HeroEvo.GetConfig(id)[hero.stage+1]
        else
            NextStageHeroConf = HeroWeaponStage.GetConfig(WeaponID)[hero.weapon_stage+1]
        end
        if NextStageHeroConf then
            local cfg = CommonConfig.Get(100 + Hero_weapon_Stage + 1);
            local heroLevel = cfg and cfg.para2 or 0;
            local ItemCount = 0
            --print("zoe进阶检查红点",id,sprinttb(NextStageHeroConf))
            for i=1,4 do
                ItemCount = module.ItemModule.GetItemCount(NextStageHeroConf["cost0_id"..i])
                if NextStageHeroConf["cost0_id"..i] ~= 0 and ItemCount < NextStageHeroConf["cost0_value"..i] then
                    return false, {type = returnType.GetItem, itemType = 41, itemId = NextStageHeroConf["cost0_id"..i]}
                end
            end
            -- local LeftItemCount = module.ItemModule.GetItemCount(NextStageHeroConf.cost0_id1)
            -- local RightItemCount = module.ItemModule.GetItemCount(NextStageHeroConf.cost0_id2)
            -- if NextStageHeroConf.cost0_id1 ~= 0 and LeftItemCount < NextStageHeroConf.cost0_value1 then
            --     return false, {type = returnType.GetItem, itemType = 41, itemId = NextStageHeroConf.cost0_id1}
            -- end
            -- if NextStageHeroConf.cost0_id2 ~= 0 and RightItemCount < NextStageHeroConf.cost0_value2 then
            --     return false, {type = returnType.GetItem, itemType = 41, itemId = NextStageHeroConf.cost0_id2}
            -- end
            -- for i = 1, 6 do
            --     local _id = NextStageHeroConf["cost"..i.."_id"]
            --     if _id ~= 0 then
            --         if Hero_weapon_Slot[i] ~= 1 and (module.ItemModule.GetItemCount(_id) <= 0 or module.ItemModule.GetItemCount(_id) < NextStageHeroConf["cost"..i.."_value"])then
            --             return false, {type = returnType.GetItem, itemType = 41, itemId = _id}
            --         end
            --     end
            -- end
            if hero.level < heroLevel then
                return false, {type = returnType.GoLevelUp}
            end
            return true
        else
            return false
        end
    end
end

EventManager.getInstance():addListener("GIFT_INFO_CHANGE", function(event, data)
    DispatchEvent("LOCAL_REDDOT_HERO_CHANE")
end)

EventManager.getInstance():addListener("HERO_INFO_CHANGE", function(event, data)
    DispatchEvent("LOCAL_REDDOT_HERO_CHANE")
end)

---英雄
-------------------------------------------
function checkModlue:checkHeroLevel(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Hero.Level.id] then statusInfo[checkModlue.Type.Hero.Level.id] = {} end
    if heroId == masterId then
        statusInfo[checkModlue.Type.Hero.Level.id][heroId] = false
        return false, {type = returnType.Close}
    end
    local _hero = heroModule.GetManager():Get(heroId)
    local canlevelup = false;
    if _hero then
        if heroModule.GetManager():Get(masterId).level > _hero.level then
            canlevelup = HeroLevelup.CanOperate(_hero, heroModule.GetManager():Get(masterId).level)
        end
    else
        return false, {type = returnType.Close}
    end
    statusInfo[checkModlue.Type.Hero.Level.id][heroId] = canlevelup
    if canlevelup then
        return statusInfo[checkModlue.Type.Hero.Level.id][heroId]
    else
        return false, {type = returnType.LevelUp}
    end
    return false, {type = returnType.Close}
end

function checkModlue:checkHeroStar(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Hero.Star.id] then statusInfo[checkModlue.Type.Hero.Star.id] = {} end
    if not OpenLevel.GetStatus(1103) then
        statusInfo[checkModlue.Type.Hero.Star.id][heroId] = false
        return false, {type = returnType.Close}
    end
    local _hero = heroModule.GetManager():Get(heroId)
    if _hero then
        if _hero.star < MaxStar then
            local _, _roleStar = heroStar.GetroleStarTab()
            if _roleStar[heroId] then
                local _roleStarTab = _roleStar[heroId][_hero.star+1]
                if _roleStarTab then
                    if _roleStarTab.cost_value1 and ItemModule.GetItemCount(_roleStarTab.cost_id1) >= _roleStarTab.cost_value1 then
                        if _roleStarTab.cost_value2 and ItemModule.GetItemCount(_roleStarTab.cost_id2) >= _roleStarTab.cost_value2 then
                            local _nextCfgLevel = heroStar.GetCommonTab()[_hero.star+1]
                            if _nextCfgLevel["para2"]  and _nextCfgLevel["para2"] <= _hero.level then
                                statusInfo[checkModlue.Type.Hero.Star.id][heroId] = true
                                return true
                            else
                                statusInfo[checkModlue.Type.Hero.Star.id][heroId] = false
                                return false, {type = returnType.LevelUp}
                            end
                        else
                            statusInfo[checkModlue.Type.Hero.Star.id][heroId] = false
                            return false, {type = returnType.GetItem, itemType = 41, itemId = heroId+10000}
                        end
                    else
                        statusInfo[checkModlue.Type.Hero.Star.id][heroId] = false
                        return false, {type = returnType.GetItem, itemType = 41, itemId = 90002}
                    end
                end
            else
                ERROR_LOG("role_star cfg is nil,id",heroId)
            end
        end
    end
    statusInfo[checkModlue.Type.Hero.Star.id][heroId] = false
    return false, {type = returnType.Close}
end

function checkModlue:checkPartnerAdv(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Hero.PartnerAdv.id] then statusInfo[checkModlue.Type.Hero.PartnerAdv.id] = {} end
    if not OpenLevel.GetStatus(1106) then
        statusInfo[checkModlue.Type.Hero.PartnerAdv.id][heroId] = false
        return false, {type = returnType.Close}
    end
    if heroModule.GetManager():Get(heroId) then
        statusInfo[checkModlue.Type.Hero.PartnerAdv.id][heroId] = GetHeroDegree(heroId)
    end
    return statusInfo[checkModlue.Type.Hero.PartnerAdv.id][heroId]
end

function checkModlue:checkHeroAdv(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Hero.Adv.id] then statusInfo[checkModlue.Type.Hero.Adv.id] = {} end
    if not OpenLevel.GetStatus(1106) then
        statusInfo[checkModlue.Type.Hero.Adv.id][heroId] = false
        return false, {type = returnType.Close}
    end
    local _status, _tab = GetHeroDegree(heroId)
    if _status then
        statusInfo[checkModlue.Type.Hero.Adv.id][heroId] = true
        return true
    end
    return false, _tab
end

function checkModlue:checkHeroTalent(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Hero.Talent.id] then statusInfo[checkModlue.Type.Hero.Talent.id] = {} end
    local _hero = heroModule.GetManager():Get(heroId)
    if _hero then
        statusInfo[checkModlue.Type.Hero.Talent.id][heroId] = TalentModule.CanOperate(1, _hero.id, _hero.level)
    end
    return statusInfo[checkModlue.Type.Hero.Talent.id][heroId]
end

function checkModlue:checkHeroProfessional(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Hero.Professional.id] then statusInfo[checkModlue.Type.Hero.Professional.id] = {} end
    if not OpenLevel.GetStatus(1102) then
        statusInfo[checkModlue.Type.Hero.Professional.id][heroId] = false
        return false
    end
    local _hero = heroModule.GetManager():Get(heroId)
    if _hero then
        statusInfo[checkModlue.Type.Hero.Professional.id][heroId] = TalentModule.CanOperate(4, _hero.id, _hero) or TalentModule.CanOperate(5, _hero.id, _hero)
    end
    return statusInfo[checkModlue.Type.Hero.Professional.id][heroId]
end



---英雄武器
------------------------------------------
function checkModlue:checkWeaponLevel(heroId)
    -- if not heroId then return false end
    -- if not statusInfo[checkModlue.Type.Weapon.Level.id] then statusInfo[checkModlue.Type.Weapon.Level.id] = {} end
    -- local _weapon = heroModule.GetManager():Get(heroId)
    -- if _weapon then
    --     if _weapon.weapon_level < heroModule.GetManager():Get(masterId).level then
    --         local _expConfig = HeroLevelup.GetExpConfig(2)
    --         if _expConfig and _expConfig[_weapon.weapon_level + 1] then
    --             if (_expConfig[_weapon.weapon_level + 1] - _weapon.weapon_exp) <= ItemModule.GetItemCount(90002) then
    --                 statusInfo[checkModlue.Type.Weapon.Level.id][heroId] = true
    --                 return true
    --             end
    --         end
    --     end
    -- end
    -- statusInfo[checkModlue.Type.Weapon.Level.id][heroId] = false
    -- return false

    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Weapon.Level.id] then statusInfo[checkModlue.Type.Weapon.Level.id] = {} end
    statusInfo[checkModlue.Type.Weapon.Level.id][heroId] = false
    return false
end

function checkModlue:checkWeaponStar(heroId, needTalent)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Weapon.Star.id] then statusInfo[checkModlue.Type.Weapon.Star.id] = {} end
    if not OpenLevel.GetStatus(1107) then
        statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = false
        return false, {type = returnType.Close}
    end
    if needTalent == nil then
        if checkModlue:checkWeaponTalent(heroId) then
            statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = true
            return true, {type = returnType.WeaponStar}
        end
    end
    local _weapon = heroModule.GetManager():Get(heroId)
    if _weapon then
        if _weapon.weapon_star < MaxStar then
            local _nextCfg = heroStar.GetStarUpTab()[_weapon.weapon_star+1]
            local _nextCfgLevel = heroStar.GetCommonTab()[_weapon.weapon_star+1]
            local _roleStarTab = heroStar.GetWeaponStarTab()[_weapon.weapon] or {}
            if _nextCfg and  _nextCfgLevel and _roleStarTab[_weapon.weapon_star+1] then
                if _roleStarTab[_weapon.weapon_star+1].cost_id1 and _roleStarTab[_weapon.weapon_star+1].cost_value1 <= ItemModule.GetItemCount(_roleStarTab[_weapon.weapon_star+1].cost_id1) then
                    if _roleStarTab[_weapon.weapon_star+1].cost_id2 and _roleStarTab[_weapon.weapon_star+1].cost_value2 <= ItemModule.GetItemCount(_roleStarTab[_weapon.weapon_star+1].cost_id2) then
                        if _nextCfgLevel["para2"]  and _nextCfgLevel["para2"] <= _weapon.level then
                            statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = true
                            return true
                        else
                            statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = false
                            return false, {type = returnType.LevelUp}
                        end
                    else
                        statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = false
                        return false, {type = returnType.GetItem, itemType = 41, itemId = heroId + 11000}
                    end
                else
                    statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = false
                    return false, {type = returnType.GetItem, itemType = 41, itemId = 90002}
                end
            end
        end
    end
    statusInfo[checkModlue.Type.Weapon.Star.id][heroId] = false
    return false, {type = returnType.Close}
end

function checkModlue:checkWeaponAdv(heroId)
    -- if not heroId then return false end
    -- if not statusInfo[checkModlue.Type.Weapon.Adv.id] then statusInfo[checkModlue.Type.Weapon.Adv.id] = {} end
    -- if heroModule.GetManager():Get(heroId) then
    --     statusInfo[checkModlue.Type.Weapon.Adv.id][heroId] = GetHeroDegree(heroId, 1)
    -- end
    -- return statusInfo[checkModlue.Type.Weapon.Adv.id][heroId]

    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Weapon.Adv.id] then statusInfo[checkModlue.Type.Weapon.Adv.id] = {} end
    statusInfo[checkModlue.Type.Weapon.Adv.id][heroId] = false
    return false
end

function checkModlue:checkWeaponTalent(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Weapon.Talent.id] then statusInfo[checkModlue.Type.Weapon.Talent.id] = {} end
    if not OpenLevel.GetStatus(1107) then
        statusInfo[checkModlue.Type.Weapon.Talent.id] = false
        return false
    end
    local _hero = heroModule.GetManager():Get(heroId)
    if _hero then
        statusInfo[checkModlue.Type.Weapon.Talent.id][heroId] = TalentModule.CanOperate(2, _hero.id, _hero.weapon_star)
    end
    return statusInfo[checkModlue.Type.Weapon.Talent.id][heroId]
end

function checkModlue:checkWeaponProfessional(heroId)
    if not heroId then return false end
    return false
end

function checkModlue:checkWeapon(heroId)
    if not heroId then return false end
    if not statusInfo[checkModlue.Type.Weapon.Weapon.id][heroId] then statusInfo[checkModlue.Type.Weapon.Weapon.id][heroId] = {} end
    statusInfo[checkModlue.Type.Weapon.Weapon.id][heroId] = checkModlue:checkWeaponLevel(heroId) or checkModlue:checkWeaponStar(heroId) or
                                                              checkModlue:checkWeaponAdv(heroId) or checkModlue:checkWeaponTalent(heroId) or
                                                              checkModlue:checkWeaponProfessional(heroId)
    return statusInfo[checkModlue.Type.Weapon.Weapon.id][heroId]
end


---装备
--------------------------------------
function checkModlue:checkEquipLevel(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Equip.Level.id] then statusInfo[checkModlue.Type.Equip.Level.id] = {} end

    statusInfo[checkModlue.Type.Equip.Level.id][uuid] = false
    return false, {type = returnType.Close}
    -- local _equip = equipmentModule.GetByUUID(uuid)
    -- if _equip then
    --     if heroModule.GetManager():Get(masterId).level > _equip.level then
    --         if equipmentConfig.UpLevelCoin()[_equip.level+1].value and equipmentConfig.UpLevelCoin()[_equip.level+1].value < ItemModule.GetItemCount(90002) then
    --             statusInfo[checkModlue.Type.Equip.Level.id][uuid] = true
    --             return true
    --         end
    --     end
    -- end
    -- statusInfo[checkModlue.Type.Equip.Level.id][uuid] = false
    -- return false
end

function checkModlue:checkEquipAdv(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Equip.Adv.id] then statusInfo[checkModlue.Type.Equip.Adv.id] = {} end
    statusInfo[checkModlue.Type.Equip.Adv.id][uuid] = false
    return false
end

function checkModlue:checkEquipUpQuality(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Equip.UpQuality.id] then statusInfo[checkModlue.Type.Equip.UpQuality.id] = {} end

    if not OpenLevel.GetStatus(1122) then
        statusInfo[checkModlue.Type.Equip.UpQuality.id][uuid] = false
        return false
    end

    local _equip = equipmentModule.GetByUUID(uuid)
    if _equip then
        if ItemModule.GetItemCount(_equip.cfg.swallow_id) >= (_equip.cfg.swallow + _equip.cfg.swallow_incr * (_equip.level - 1)) then
            if _equip.cfg.evo_id ~= 0 then
                statusInfo[checkModlue.Type.Equip.UpQuality.id][uuid] = true
                return true
            end
        end
    end
    statusInfo[checkModlue.Type.Equip.UpQuality.id][uuid] = false
    return false
end

function checkModlue:checkEquip(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Equip.Equip.id] then statusInfo[checkModlue.Type.Equip.Equip.id] = {} end
    statusInfo[checkModlue.Type.Equip.Equip.id][uuid] = checkModlue:checkEquipLevel(uuid) or checkModlue:checkEquipAdv(uuid) or
                                                        checkModlue:checkEquipUpQuality(uuid)
    statusInfo[checkModlue.Type.Equip.Equip.id][uuid] = false
    return statusInfo[checkModlue.Type.Equip.Equip.id][uuid]
end

function checkModlue:checkHeroUpEquipLevel(heroId)
    -- if not heroId then return false end
    -- if not heroModule.GetManager():Get(heroId) then return false end
    -- if not statusInfo[checkModlue.Type.Hero.UpEquipLevel.id] then statusInfo[checkModlue.Type.Hero.UpEquipLevel.id] = {} end
    -- for k,v in pairs(equipmentModule.GetHeroEquip(heroId)) do
    --     if v.type == 0 then
    --         if checkModlue:checkEquipLevel(v.uuid) then
    --             statusInfo[checkModlue.Type.Hero.UpEquipLevel.id][heroId] = true
    --             return true
    --         end
    --     end
    -- end
    -- statusInfo[checkModlue.Type.Hero.UpEquipLevel.id][heroId] = false
    -- return false
    if not heroId then return false, {type = returnType.Close} end
    if not statusInfo[checkModlue.Type.Hero.UpEquipLevel.id] then statusInfo[checkModlue.Type.Hero.UpEquipLevel.id] = {} end
    statusInfo[checkModlue.Type.Hero.UpEquipLevel.id][heroId] = false
    return false, {type = returnType.Close}
end

function checkModlue:checkHeroUpInscLevel(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.UpInscLevel.id] then statusInfo[checkModlue.Type.Hero.UpInscLevel.id] = {} end
    statusInfo[checkModlue.Type.Hero.UpInscLevel.id][heroId] = false
    return false, {type = returnType.Close}

    -- for k,v in pairs(equipmentModule.GetHeroEquip(heroId)) do
    --     if v.type == 1 then
    --         if checkModlue:checkInscLevel(v.uuid) then
    --             statusInfo[checkModlue.Type.Hero.UpInscLevel.id][heroId] = true
    --             return true
    --         end
    --     end
    -- end
    -- statusInfo[checkModlue.Type.Hero.UpInscLevel.id][heroId] = false
    -- return false
end

function checkModlue:checkHeroEquipRecommend(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.EquipRecommend.id] then statusInfo[checkModlue.Type.Hero.EquipRecommend.id] = {} end
    local _status = equipmentConfig.GetEquipOpenLevel(0, 7)
    if _status then
        local _list = module.EquipRecommend.Get(heroId, 0, 0)
        for k,v in pairs(_list) do
            local _equip = equipmentModule.GetHeroEquip(heroId, k)
            if equipmentConfig.GetEquipOpenLevel(0, k) then
                if not _equip or _equip.uuid ~= v then
                    statusInfo[checkModlue.Type.Hero.EquipRecommend.id][heroId] = true
                    return true
                end
            end
        end
        statusInfo[checkModlue.Type.Hero.EquipRecommend.id][heroId] = false
        return false
    else
        statusInfo[checkModlue.Type.Hero.EquipRecommend.id][heroId] = false
    end
    return statusInfo[checkModlue.Type.Hero.EquipRecommend.id][heroId]
end

function checkModlue:checkHeroInscRecommend(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.InscRecommend.id] then statusInfo[checkModlue.Type.Hero.InscRecommend.id] = {} end
    local _status = equipmentConfig.GetEquipOpenLevel(0, 1)
    if _status then
        local _list = module.EquipRecommend.Get(heroId, 1, 0)
        for k,v in pairs(_list) do
            local _equip = equipmentModule.GetHeroEquip(heroId, k)
            if equipmentConfig.GetEquipOpenLevel(0, k) then
                if not _equip or _equip.uuid ~= v then
                    statusInfo[checkModlue.Type.Hero.InscRecommend.id][heroId] = true
                    return true
                end
            end
        end
        statusInfo[checkModlue.Type.Hero.InscRecommend.id][heroId] = false
        return false
    else
        statusInfo[checkModlue.Type.Hero.InscRecommend.id][heroId] = false
    end
    return statusInfo[checkModlue.Type.Hero.InscRecommend.id][heroId]
end

function checkModlue:checkHeroUpEquipQuality(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.UpEquipQuality.id] then statusInfo[checkModlue.Type.Hero.UpEquipQuality.id] = {} end
    statusInfo[checkModlue.Type.Hero.UpEquipQuality.id][heroId] = false
    if not OpenLevel.GetStatus(1122) then
        return false, {type = returnType.Close}
    end
    local _flag = false
    local _id = 0
    for k,v in pairs(equipmentModule.GetHeroEquip(heroId)) do
        if v.type == 0 and v.suits == 0 then
            if checkModlue:checkEquipUpQuality(v.uuid) then
                statusInfo[checkModlue.Type.Hero.UpEquipQuality.id][heroId] = true
                return true
            else
                if v.cfg.evo_id ~= 0 and not _flag then
                    _flag = true
                    _id = v.cfg.swallow_id
                end
            end
        end
    end
    if _flag then
        return false, {type = returnType.GetItem, itemType = 41, itemId = _id}
    end
    return false, {type = returnType.Close}
end

function checkModlue:checkHeroEquip(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.Equip.id] then statusInfo[checkModlue.Type.Hero.Equip.id] = {} end
    -- for k,v in pairs(equipmentModule.GetHeroEquip(heroId)) do
    --     if v.type == 0 and v.suits == 0 then
    --         if checkModlue:checkEquip(v.uuid) then
    --             statusInfo[checkModlue.Type.Hero.Equip.id][heroId] = true
    --             return true
    --         end
    --     end
    -- end
    --2018.09.14hero 有可穿戴装备无红点提示
    for i = 1, 12 do--2018.0828.有可穿戴装备时的红点提示
        if not equipmentModule.GetHeroEquip(heroId, i) or equipmentModule.GetHeroEquip(heroId, i) and not equipmentModule.GetHeroEquip(heroId, i).uuid then
            if equipmentModule.GetPlace()[equipmentModule.HashBinary[i]] then
                if OpenLevel.GetEquipOpenLevel(0, i) then
                    for k,v in pairs(equipmentModule.GetPlace()[equipmentModule.HashBinary[i]]) do
                        if v.heroid == 0 then
                            statusInfo[checkModlue.Type.Hero.Equip.id][heroId] = true
                            return true
                        end
                    end
                end
            end
        end
    end
    statusInfo[checkModlue.Type.Hero.Equip.id][heroId] = false
    return false
end

function checkModlue:checkHeroHaveEquip(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.HaveEquip.id] then statusInfo[checkModlue.Type.Hero.HaveEquip.id] = {} end
    --[==[for i = 1, 12 do
        if equipmentModule.GetHeroEquip(heroId, i) then
            if not equipmentModule.GetHeroEquip(heroId, i).uuid then
                if equipmentModule.GetPlace()[equipmentModule.HashBinary[i]] then
                    if OpenLevel.GetEquipOpenLevel(0, i) then
                        for k,v in pairs(equipmentModule.GetPlace()[equipmentModule.HashBinary[i]]) do
                            if v.heroid == 0 then
                                statusInfo[checkModlue.Type.Hero.HaveEquip.id][heroId] = true
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    --[===[--]==]
    for i = 1, 12 do--2018.0828.有可穿戴装备时的红点提示
        if not equipmentModule.GetHeroEquip(heroId, i) or equipmentModule.GetHeroEquip(heroId, i) and not equipmentModule.GetHeroEquip(heroId, i).uuid then
            if equipmentModule.GetPlace()[equipmentModule.HashBinary[i]] then
                if OpenLevel.GetEquipOpenLevel(0, i) then
                    for k,v in pairs(equipmentModule.GetPlace()[equipmentModule.HashBinary[i]]) do
                        if v.heroid == 0 then
                            statusInfo[checkModlue.Type.Hero.HaveEquip.id][heroId] = true
                            return true
                        end
                    end
                end
            end
        end
    end
    --]===]
    statusInfo[checkModlue.Type.Hero.HaveEquip.id][heroId] = false
    return false
end


---铭文
--------------------------------------------
function checkModlue:checkInscLevel(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Insc.Level.id] then statusInfo[checkModlue.Type.Insc.Level.id] = {} end
    local _insc = equipmentModule.GetByUUID(uuid)
    if _insc then
        if heroModule.GetManager():Get(masterId).level > _insc.level then
            local _cfg = equipmentConfig.EquipLeveUpTab(_insc.level)
            local _nextCfg = equipmentConfig.EquipLeveUpTab(_insc.level + 1)
            if _cfg and _nextCfg then
                if (_nextCfg.value - _cfg.value) < ItemModule.GetItemCount(equipmentConfig.EquipLeveUpTab(1).id) then
                    statusInfo[checkModlue.Type.Insc.Level.id][uuid] = true
                    return true
                end
            end
        end
    end
    statusInfo[checkModlue.Type.Insc.Level.id][uuid] = false
    return false
end

function checkModlue:checkInscAdv(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Insc.Adv.id] then statusInfo[checkModlue.Type.Insc.Adv.id] = {} end
    statusInfo[checkModlue.Type.Insc.Adv.id][uuid] = false
    return false
end

function checkModlue:checkInscUpQuality(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Insc.UpQuality.id] then statusInfo[checkModlue.Type.Insc.UpQuality.id] = {} end
    local _insc = equipmentModule.GetByUUID(uuid)
    if _insc then
        local _count = 0
        local _needId = 0
        for k,v in pairs(equipmentModule.GetAttribute(uuid)) do
            local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
            local _max = _scroll.max_value + _scroll.lev_max_value * (_insc.level - 1)
            if v.allValue < _max then
                _count = _count + _scroll.grow_cost_value
                _needId = _scroll.grow_cost_id
            end
        end
        if _count > 0 then
            if ItemModule.GetItemCount(_needId) >= _count then
                statusInfo[checkModlue.Type.Insc.UpQuality.id][uuid] = true
                return true
            end
        end
    end
    statusInfo[checkModlue.Type.Insc.UpQuality.id][uuid] = false
    return false
end

function checkModlue:checkInsc(uuid)
    if not uuid then return false end
    if not statusInfo[checkModlue.Type.Insc.Insc.id] then statusInfo[checkModlue.Type.Insc.Insc.id] = {} end
    statusInfo[checkModlue.Type.Insc.Insc.id][uuid] = checkModlue:checkInscLevel(uuid) or checkModlue:checkInscAdv(uuid) or
                                                      checkModlue:checkInscUpQuality(uuid)
    statusInfo[checkModlue.Type.Insc.Insc.id][uuid] = false
    return statusInfo[checkModlue.Type.Insc.Insc.id][uuid]
end

function checkModlue:checkHeroInsc(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.Insc.id] then statusInfo[checkModlue.Type.Hero.Insc.id] = {} end
    for k,v in pairs(equipmentModule.GetHeroEquip(heroId)) do
        if v.type == 1 and v.suits == 0 then
            if checkModlue:checkInsc(v.uuid) then
                statusInfo[checkModlue.Type.Hero.Insc.id][heroId] = true
                return true
            end
        end
    end
    statusInfo[checkModlue.Type.Hero.Insc.id][heroId] = false
    return false
end


function checkModlue:checkHero(heroId)
    if not heroId then return false end
    if not heroModule.GetManager():Get(heroId) then return false end
    if not statusInfo[checkModlue.Type.Hero.Hero.id] then statusInfo[checkModlue.Type.Hero.Hero.id] = {} end
    statusInfo[checkModlue.Type.Hero.Hero.id][heroId] = --[[ checkModlue:checkHeroLevel(heroId) or ]] checkModlue:checkHeroStar(heroId) or
                                                        checkModlue:checkPartnerAdv(heroId) or --[[ checkModlue:checkHeroTalent(heroId) or ]]
                                                        checkModlue:checkHeroEquip(heroId) or
                                                        checkModlue:checkHeroHaveEquip(heroId) --[[ or checkModlue:checkWeaponStar(heroId) ]]
    return statusInfo[checkModlue.Type.Hero.Hero.id][heroId]
end

function checkModlue:checkAllHero()
    local online = heroModule.GetManager():GetFormation();
    for i,v in ipairs(online) do
        if v ~= 0 and checkModlue:checkHero(v) then
            statusInfo[checkModlue.Type.Hero.AllHero.id] = true
            return true
        end
    end
    statusInfo[checkModlue.Type.Hero.AllHero.id] = false
    return false
end

---新手引导用 获取合成数量
function checkModlue:checkHeroComposeNumber()
    local count = 0
    for k,v in pairs(heroModule.GetConfig()) do
        local _info = ShopModule.GetManager(6, v.id)
        if _info and _info[1] then
            if not heroModule.GetManager():Get(v.id) then
                if (ItemModule.GetItemCount(_info[1].consume_item_id1) > 0) and (ItemModule.GetItemCount(_info[1].consume_item_id1) >= _info[1].consume_item_value1) then
                    count = count + 1
                end
            end
        end
    end
    statusInfo[checkModlue.Type.Hero.ComposeNumber.id] = count
    return (count > 0)
end

---英雄合成数量
function checkModlue:checkHeroCompose()
    local count = 0
    for k,v in pairs(heroModule.GetConfig()) do
        local _info = ShopModule.GetManager(6, v.id)
        if _info and _info[1] then
            if not heroModule.GetManager():Get(v.id) then
                if (ItemModule.GetItemCount(_info[1].consume_item_id1) > 0) and (ItemModule.GetItemCount(_info[1].consume_item_id1) >= _info[1].consume_item_value1) then
                    count = count + 1
                end
            end
        end
    end
    if count == 0 then
        --statusInfo[checkModlue.Type.Hero.Compose.id] = checkModlue:checkAllHero()
        --return statusInfo[checkModlue.Type.Hero.Compose.id]
        statusInfo[checkModlue.Type.Hero.Compose.id] = false;
        return statusInfo[checkModlue.Type.Hero.Compose.id];
    else
        statusInfo[checkModlue.Type.Hero.Compose.id] = count
        return (count > 0)
    end
end

EventManager.getInstance():addListener("SHOP_INFO_CHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

local login = false
local last_sync_time = 50
local nextTime = 50
local activityStartList = {}
local activityEndList = {}
SGK.CoroutineService.Schedule(function()
    if login and last_sync_time >= 0 then
        last_sync_time = last_sync_time - UnityEngine.Time.deltaTime
        if last_sync_time <= 0 then
            last_sync_time = nextTime
            for k,_actCf in pairs(ActivityConfig.GetActivity()) do
                if _actCf.loop_duration and _actCf.loop_duration > 0 and _actCf.loop_duration < 86400 then
                    if not activityStartList[k] or not activityEndList[k] then
                        if _actCf.begin_time >= 0 and _actCf.end_time >= 0 and _actCf.period >= 0 then
                            local total_pass = module.Time.now() - _actCf.begin_time
                            local period_pass = total_pass - math.floor(total_pass / _actCf.period) * _actCf.period
                            local period_begin = module.Time.now() - period_pass
                            if (module.Time.now() > period_begin and module.Time.now() < (period_begin + _actCf.loop_duration)) then
                                if not activityStartList[k] then
                                    DispatchEvent("LOCAL_ACTIVITY_STATUS_CHANGE", {id = k, status = true})
                                end
                                activityStartList[k] = true
                            end
                            if module.Time.now() > (period_begin + _actCf.loop_duration) then
                                if not activityEndList[k] then
                                    DispatchEvent("LOCAL_ACTIVITY_STATUS_CHANGE", {id = k, status = false})
                                end
                                activityEndList[k] = true
                            end
                        end
                    end
                end
            end
        end
    end
end)


local _sync_time = 30
local _timer_Delay = 0
local timeDelay=60*5
local System_Set_data=UserDefault.Load("System_Set_data");
local activityBeforeNoticeTab = {}
local activityOnTimeNoticeTab = {}
--游戏内通知
SGK.CoroutineService.Schedule(function()
    if login and _timer_Delay >= 0 then
        _timer_Delay = _timer_Delay - UnityEngine.Time.deltaTime
        if _timer_Delay <= 0 then
            _timer_Delay = _sync_time

            for k,_actCf in pairs(ActivityConfig.GetActivity()) do
                if _actCf.begin_time > 0 and _actCf.end_time > 0 and _actCf.period > 0 and _actCf.loop_duration and _actCf.loop_duration%86400~=0 then
                    local total_pass = timeModule.now() - _actCf.begin_time
                    local period_pass =  math.floor(total_pass / _actCf.period)
                    --cfg.period刷新时间  --cfg.loop_duration周期持续时间
                    local period_begin = _actCf.begin_time + (period_pass+1) * _actCf.period
                    --周期结束时间
                    local period_end = _actCf.end_time + (period_pass+1) * _actCf.period
                    --游戏内 提前5分钟 跑马灯
                    if not activityBeforeNoticeTab[k] and timeModule.now()+timeDelay < period_begin then
                        --周期开始 记录
                        activityBeforeNoticeTab[k] = true
                        --ERROR_LOG("注册5分钟通知",k,_actCf.name,period_begin-timeModule.now()-timeDelay,timeModule.now(),period_begin)
                    end
  
                    if activityBeforeNoticeTab[k] and timeModule.now()+timeDelay >= period_begin and timeModule.now()+timeDelay< period_end then
                        local playerLv = module.playerModule.Get().level
                        if playerLv>=_actCf.lv_limit then
                            System_Set_data.ActivityNoticeStatus = System_Set_data.ActivityNoticeStatus==nil and true or System_Set_data.ActivityNoticeStatus
                            if System_Set_data.ActivityNoticeStatus then
                                local noticeStr = _actCf.announcement2 and _actCf.announcement2 ~= "" and _actCf.announcement2 ~= "0" and SGK.Localize:getInstance():getValue(_actCf.announcement2) or string.format("%s马上开始",_actCf.name)
                                utils.SGKTools.showScrollingMarquee(noticeStr,1)
                                --ERROR_LOG("5分钟通知",k,_actCf.name)
                            end
                        end
                        --过期 移除
                        activityBeforeNoticeTab[k] = nil
                    end
                    --游戏内及时通知
                    if not activityOnTimeNoticeTab[k] and timeModule.now()<= period_begin and _actCf.Notice ==1 then
                        activityOnTimeNoticeTab[k] = true
                        --ERROR_LOG("注册及时通知",k,_actCf.name,period_begin-timeModule.now(),timeModule.now(),period_begin) 
                    end

                    if activityOnTimeNoticeTab[k] and timeModule.now() >= period_begin and timeModule.now()< period_end then
                        local playerLv = module.playerModule.Get().level
                        if playerLv>=_actCf.lv_limit then
                            if _actCf.announcement1 and _actCf.announcement1 ~= "" and _actCf.announcement1 ~= "0" then
                                local noticeStr = SGK.Localize:getInstance():getValue(_actCf.announcement1) or string.format("%s马上开始",_actCf.name)
                                utils.SGKTools.showScrollingMarquee(noticeStr,1)
                                --ERROR_LOG("及时通知",k,_actCf.name)
                            end
                        end
                        activityOnTimeNoticeTab[k] = nil
                    end
                end
            end
        end
    end
end)

--限时活动5分钟前通知
local ActivityAlreadySend = {};
utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, data)
    login = true
    local ActivityCfgTab=ActivityConfig.GetActivity()
    module.playerModule.Get(nil,(function( ... )
        local playerLv = module.playerModule.Get().level
        for k,v in pairs(ActivityCfgTab) do
            local cfg=v
            if cfg.begin_time > 0 and cfg.end_time > 0 and cfg.period > 0 and cfg.loop_duration and cfg.loop_duration%86400~=0 then
                local total_pass = timeModule.now() - cfg.begin_time
                local period_pass =  math.floor(total_pass / cfg.period)
                --cfg.period刷新时间  --cfg.loop_duration周期持续时间
                local period_begin = cfg.begin_time + (period_pass+1) * cfg.period
                --登录游戏后注册一次 周期内推送
                --ERROR_LOG("添加==",cfg.name,playerLv,cfg.lv_limit,period_begin-timeModule.now()-timeDelay)
                if timeModule.now()+timeDelay <= period_begin and not ActivityAlreadySend[period_begin] and playerLv>= cfg.lv_limit then
                    ActivityAlreadySend[period_begin] = true;
                    --ERROR_LOG("添加====推送",cfg.name,period_begin-timeDelay - timeModule.now())
                    --NotificationCenter.AddNotification(period_begin -timeDelay- timeModule.now(),string.format("%s马上开始",cfg.name),nil,nil,string.format("%s",cfg.name))
                    NotificationCenter.AddNotification(period_begin -timeDelay,string.format("%s马上开始",cfg.name),nil,nil,string.format("%s",cfg.name))
                end
            end
        end
    end))
end)

local AlreadySend = {};
local function CheckNotification()
    if OpenLevel.GetStatus(1301) then
        local questIdTab = {1011002,1011001}
        for k,v in ipairs(questIdTab) do
            local cfg = module.QuestModule.GetCfg(v)
            if cfg and cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 then
                local total_pass = timeModule.now() - cfg.begin_time
                local period_pass = math.floor(total_pass % cfg.period)
                local period_begin = 0;
                if period_pass >= cfg.duration then
                    period_begin = cfg.begin_time + math.ceil(total_pass / cfg.period) * cfg.period
                else
                    period_begin = cfg.begin_time + math.floor(total_pass / cfg.period) * cfg.period
                end
                if timeModule.now() < period_begin and AlreadySend[period_begin] == nil then
                    AlreadySend[period_begin] = true;
                    -- ERROR_LOG("添加推送",period_begin);
                    --NotificationCenter.AddNotification(period_begin - timeModule.now(), "快来领取时之力吧~", nil,nil, "time_power")
                    NotificationCenter.AddNotification(period_begin, "快来领取时之力吧~", nil,nil, "time_power")
                end
            end
        end
    end
end

----福利
function checkModlue:checkWelfareActivity()
    statusInfo[checkModlue.Type.WelfareActivity.WelfareActivity.id] = checkModlue:checkDailyDraw() or checkModlue:checkLuckyDraw_Time()
    CheckNotification();
    return statusInfo[checkModlue.Type.WelfareActivity.id]
end

function checkModlue:checkDailyDraw()
    local ItemCount =module.ItemModule.GetItemCount(90017)
    statusInfo[checkModlue.Type.WelfareActivity.DailyDraw.id] =not not (ItemCount>0)
    return statusInfo[checkModlue.Type.WelfareActivity.DailyDraw.id]
end

function checkModlue:checkLuckyDraw_Time()
    statusInfo[checkModlue.Type.WelfareActivity.LuckyDraw_Time.id] = false
    local questIdTab = {1011002,1011001}
    for k,v in pairs(questIdTab) do
        local cfg = module.QuestModule.GetCfg(v)
        if cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 then
            local total_pass = timeModule.now() - cfg.begin_time
            local period_pass = total_pass - math.floor(total_pass / cfg.period) * cfg.period
            local period_begin = timeModule.now() - period_pass;
            if timeModule.now() > period_begin and timeModule.now() < (period_begin + cfg.duration) then
                local _quest = module.QuestModule.Get(v)
                if _quest and _quest.status == 1 then

                else
                    statusInfo[checkModlue.Type.WelfareActivity.LuckyDraw_Time.id] = true
                end
            end
        end
    end
    return statusInfo[checkModlue.Type.WelfareActivity.LuckyDraw_Time.id]
end

---竞技场
-----------------------------------------------------
function checkModlue:checkArenaFirst()
    if statusInfo[checkModlue.Type.Arena.First.id] == nil then
        statusInfo[checkModlue.Type.Arena.First.id] = true
    end
    return statusInfo[checkModlue.Type.Arena.First.id]
end

function checkModlue:checkArenaInfo()
    if not arenaModule.GetArenaData() then
        arenaModule.ApplyJoinArena()
        return false
    end
    if arenaModule.GetArenaData() then
        for i = 1, 3 do
            if arenaModule.GetArenaData().GetRewardStatus[i] then
                if arenaModule.GetArenaData().winNum >= 3 * i and arenaModule.GetArenaData().GetRewardStatus[i].IsGet == 0 then
                    statusInfo[checkModlue.Type.Arena.Info.id] = true
                    return true
                end
            end
        end
    end
    statusInfo[checkModlue.Type.Arena.Info.id] = false
    return false
end

EventManager.getInstance():addListener("SELF_INFO_CHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

function checkModlue:checkArena()
    statusInfo[checkModlue.Type.Arena.Arena.id] = checkModlue:checkArenaFirst() or checkModlue:checkArenaInfo()
    return statusInfo[checkModlue.Type.Arena.Arena.id]
end

function checkModlue:checkManor()
   statusInfo[checkModlue.Type.Manor.Manor.id] = checkModlue:checkTavern() or checkModlue:checkManufacture() or checkModlue:checkManorRandomNpc();
   return statusInfo[checkModlue.Type.Manor.Manor.id];
end

function checkModlue:checkTavern()
    local productInfo = ManorManufactureModule.Get();
    local task = productInfo:GetTask();
    statusInfo[checkModlue.Type.Manor.Tavern.id] = false;
    --有任务完成了
    if task.list then
        local canStart = 0;
        for k,v in pairs(task.list) do
            if v.state == 1 then
                canStart = canStart + 1;
            elseif v.state == 2 and v.end_time <= timeModule.now() then
                statusInfo[checkModlue.Type.Manor.Tavern.id] = true;
                return statusInfo[checkModlue.Type.Manor.Tavern.id];
            end
        end
        --有派遣次数没用完
        if canStart > 0 and task.compelet_count then 
            if task.compelet_count < 6 then
                statusInfo[checkModlue.Type.Manor.Tavern.id] = true;
                return statusInfo[checkModlue.Type.Manor.Tavern.id];
            end
        end
    end
    --有宝箱没领
    if task.starBox and task.starBox.count then
        local task_starbox_cfg = module.ManorModule.GetManorTaskStarBoxConfig();
        for i,v in ipairs(task_starbox_cfg) do
            if task.starBox.count >= v.star_value and task.starBox.status[i] == 0 then
                statusInfo[checkModlue.Type.Manor.Tavern.id] = true;
                return statusInfo[checkModlue.Type.Manor.Tavern.id];
            end
        end
    end

    return statusInfo[checkModlue.Type.Manor.Tavern.id];
end

function checkModlue:checkManufacture()
    local _canOperate, _canGather, _overView = false, false, false;
    local manorInfo = module.ManorModule.LoadManorInfo(nil, 1)
    for i,v in ipairs(manorInfo) do
        if v.line ~= 0 then
            local canGather, empty, doing, canSteal, monster, thieves = ManorManufactureModule.CheckProductlineStatus(v.line, module.playerModule.GetSelfID())
            _canOperate = _canOperate or canGather or monster or thieves;
            _overView = _overView or canGather or monster;
            _canGather = _canGather or canGather;
            if _canOperate and _canGather and _overView then
                break;
            end
        end
    end

    statusInfo[checkModlue.Type.Manor.Manufacture.id] = _canOperate;
    return _canOperate, _canGather, _overView
end

function checkModlue:checkManorRandomNpc()
    local pid = module.playerModule.GetSelfID()
    local manager = module.ManorRandomQuestNPCModule.GetManager(pid);    
    local list = manager:QueryNPC();
    statusInfo[checkModlue.Type.Manor.RandomNpc.id] = false
    for _,npc in pairs(list) do
        if npc.dead_time == 0 or module.Time.now() < npc.dead_time then
            local finish = false
            for _, v in ipairs(npc.interact) do
                if v.pid == pid then
                    finish = true;
                    break;
                end
            end
            if not finish then
                if npc.quest ~= 0 then
                    local quest = module.QuestModule.Get(npc.quest);
                    if quest == nil or quest.status == 2 then
                        statusInfo[checkModlue.Type.Manor.RandomNpc.id] = true;
                        break;
                    end
                else
                    statusInfo[checkModlue.Type.Manor.RandomNpc.id] = true;
                    break;
                end
            end
        end
    end
    return statusInfo[checkModlue.Type.Manor.RandomNpc.id];
end

function checkModlue:checkStore()
    local productInfo = ManorManufactureModule.Get();
    local productList = productInfo:GetProductList(31);
    local productLine = productInfo:GetLine(31);

    local haveGood = false;
    for k,v in pairs(productList or {}) do
        if ItemModule.GetItemCount(v.consume[1].id) > 0 then
            haveGood = true;
            break;
        end
    end

    local saleing = false;
    if haveGood then
        for k,v in pairs(productLine.orders) do
            if v.left_count > 0 then
               saleing = true;
               break;
            end
        end
    end
    statusInfo[checkModlue.Type.Manor.Store.id] = haveGood and (not saleing);
    return haveGood and (not saleing)
end

function checkModlue:checkQuest()
    local manager = module.ManorRandomQuestNPCModule.GetManager();
    local npc_quest = manager:QueryNPC();
    local canAccept = false;
    for k,v in pairs(npc_quest) do
        if v.status == - 1 or v.status == 2 then
            canAccept = true;
            break
        end
    end
    statusInfo[checkModlue.Type.Manor.Quest.id] = canAccept
    return canAccept;
end

EventManager.getInstance():addListener("MANOR_NPC_QUEST_CHANGE", function(event, pid)
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

function checkModlue:checkDataBox()
    statusInfo[checkModlue.Type.DataBox.DataBox.id] = checkModlue:checkNpcData() or checkModlue:checkUnionData() or checkModlue:checkAchievement();
    return statusInfo[checkModlue.Type.DataBox.DataBox.id];
end

function checkModlue:checkNpcData(npc_id, ignore)
    if ignore == nil then
        ignore = true
    end
    local User_DataBox = UserDefault.Load("User_DataBox", true);
    if User_DataBox.data == nil then
        User_DataBox.data = {};
    end
    local status = false;
    local biographyCfg = {};
    if npc_id then
        table.insert(biographyCfg, module.DataBoxModule.GetBiographyConfig(npc_id))
    else
        biographyCfg = module.DataBoxModule.GetBiographyConfig();
    end
    for k,v in pairs(biographyCfg) do
        for i=1,6 do
            if not ignore then
                if v["clue_quest"..i] and v["clue_quest"..i] ~= 0 then
                    local quest_id = v["clue_quest"..i];
                    local quest = module.QuestModule.Get(quest_id);
                    if quest and quest.status == 1 and User_DataBox.data[quest_id] ~= 1 then
                        statusInfo[checkModlue.Type.DataBox.NpcData.id] = true;
                        return statusInfo[checkModlue.Type.DataBox.NpcData.id]
                    end
                end
                if v["bigclue_quest"..i] and v["bigclue_quest"..i] ~= 0 then
                    local quest_id = v["bigclue_quest"..i];
                    local quest = module.QuestModule.Get(quest_id);
                    if quest and quest.status == 1 and User_DataBox.data[quest_id] ~= 1 then
                        statusInfo[checkModlue.Type.DataBox.NpcData.id] = true;
                        return statusInfo[checkModlue.Type.DataBox.NpcData.id]
                    end
                end
            end
            if v["reward_quest"..i] and v["reward_quest"..i] ~= 0 then
                local quest_id = v["reward_quest"..i];
                local quest = module.QuestModule.Get(quest_id);
                if quest and quest.status == 0 and module.QuestModule.CanSubmit(quest_id) then
                    statusInfo[checkModlue.Type.DataBox.NpcData.id] = true;
                    return statusInfo[checkModlue.Type.DataBox.NpcData.id]
                end
            end
        end
    end
    statusInfo[checkModlue.Type.DataBox.NpcData.id] = status;
    return statusInfo[checkModlue.Type.DataBox.NpcData.id]
end

function checkModlue:checkUnionData(id, ignore)
    if ignore == nil then
        ignore = true
    end
    local User_DataBox = UserDefault.Load("User_DataBox", true);
    if User_DataBox.data == nil then
        User_DataBox.data = {};
    end

    local status = false;
    local consortiaConfig = {};
    if id then
        table.insert(consortiaConfig, module.DataBoxModule.GetConsortiaConfig(id))
    else
        consortiaConfig = module.DataBoxModule.GetConsortiaConfig();
    end
    for k,v in pairs(consortiaConfig) do
        for i=1,6 do
            if not ignore then
                if v["bigclue_quest"..i] and v["bigclue_quest"..i] ~= 0 then
                    local quest_id = v["bigclue_quest"..i];
                    local quest = module.QuestModule.Get(quest_id);
                    if quest and quest.status == 1 and User_DataBox.data[quest_id] ~= 1 then
                        statusInfo[checkModlue.Type.DataBox.UnionData.id] = true;
                        return statusInfo[checkModlue.Type.DataBox.UnionData.id]
                    end
                end
            end
            if v["reward_quest"..i] and v["reward_quest"..i] ~= 0 then
                local quest_id = v["reward_quest"..i];
                local quest = module.QuestModule.Get(quest_id);
                if quest and quest.status == 0 and module.QuestModule.CanSubmit(quest_id) then
                    statusInfo[checkModlue.Type.DataBox.UnionData.id] = true;
                    return statusInfo[checkModlue.Type.DataBox.UnionData.id]
                end
            end
        end
    end
    statusInfo[checkModlue.Type.DataBox.UnionData.id] = status;
    return statusInfo[checkModlue.Type.DataBox.UnionData.id]
end

-------------聊天-----------------
function checkModlue:checkChatShow()
    statusInfo[checkModlue.Type.Chat.ChatShow.id] = module.ChatModule.GetShowChatRed(false)
end


--------------成就----------------
function checkModlue:checkAchievement()
    for k,v in pairs(module.AchievementModule.GetSecondCfg()) do
        local _quest = module.QuestModule.Get(v.id)
        if _quest and _quest.status == 1 and module.QuestModule.CanSubmit(v.reward_quest_id) then
            statusInfo[checkModlue.Type.Achievement.Achievement.id] = true
            return true
        end
    end
    for k,v in pairs(module.AchievementModule.GetAllCfg()) do
        local _quest = module.QuestModule.Get(v.Third_quest_id)
        if _quest and module.QuestModule.CanSubmit(v.reward_quest_id) then
            statusInfo[checkModlue.Type.Achievement.Achievement.id] = true
            return true
        end
    end
    statusInfo[checkModlue.Type.Achievement.Achievement.id] = false
    return false
end

function checkModlue:checkSecAchievenment(id)
    local _count = 0
    for i,v in ipairs(module.AchievementModule.GetCfg(nil, nil, id)) do
        local _quest = module.QuestModule.Get(v.Third_quest_id)
        if _quest and module.QuestModule.CanSubmit(v.reward_quest_id) then
            _count = _count + 1
        end
    end
    if not statusInfo[checkModlue.Type.Achievement.SecAchievement.id] then
        statusInfo[checkModlue.Type.Achievement.SecAchievement.id] = {}
    end
    statusInfo[checkModlue.Type.Achievement.SecAchievement.id][id] = _count
    return (_count > 0)
end

function checkModlue:checkFirstAchievenment(id)
    local _count = 0
    local _cfgList = module.AchievementModule.GetFirstQuest(id)
    if _cfgList then
        for k,v in pairs(_cfgList) do
            for i,p in ipairs(v) do
                local _quest = module.QuestModule.Get(p.Third_quest_id)
                if _quest and module.QuestModule.CanSubmit(p.reward_quest_id) then
                    _count = _count + 1
                end
            end
        end
    end
    if not statusInfo[checkModlue.Type.Achievement.FirstAchievenment.id] then
        statusInfo[checkModlue.Type.Achievement.FirstAchievenment.id] = {}
    end
    statusInfo[checkModlue.Type.Achievement.FirstAchievenment.id][id] = _count
    return (_count > 0)
end

EventManager.getInstance():addListener("Mail_INFO_CHANGE", function(event, data)
    checkModlue:checkMail()
    checkModlue:checkMailAndAward()
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

EventManager.getInstance():addListener("NOTIFY_REWARD_CHANGE", function(event, data)
    checkModlue:checkMailAndAward()
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

function checkModlue:checkMail()
    statusInfo[checkModlue.Type.Mail.Mail.id] = module.MailModule.GetMailStatus()
    return statusInfo[checkModlue.Type.Mail.Mail.id]
end

function checkModlue:checkMailAndAward()
    local AwardModule = require "module.AwardModule"
    statusInfo[checkModlue.Type.Mail.MailAndAward.id] = true
    if checkModlue:checkMail() then
        return true, 3
    end
    if #AwardModule.GetAward() > 0 then
        return true, 6
    end
    statusInfo[checkModlue.Type.Mail.MailAndAward.id] = false
    return false
end

function checkModlue:checkFriend()
    local _func = function()
        local ChatManager = require 'module.ChatModule'
        self.listData = {}
        local ChatData = ChatManager.GetManager(6)--私聊内容
        if ChatData then
            for k,v in pairs(ChatData)do
                if #v > 0 then
                    local tempData = v[#v]
                    local count = ChatManager.GetPrivateChatData(tempData.fromid)
                    if count and count > 0 then
                        return true
                    end
                end
            end
        end
        ChatData = ChatManager.GetManager(8)--好友通知
        if ChatData then
            for k,v in pairs(ChatData)do
                if #v > 0 and v[1].status == 1 then
                    return true
                end
            end
        end
        ChatData = ChatManager.GetSystemMessageList()--系统离线消息
        for k,v in pairs(ChatData) do
            for i = 1,#v do
                if v[i][6] and v[i][6] == 0 then
                    return true
                end
            end
        end
        return false
    end
    statusInfo[checkModlue.Type.Mail.Friend.id] = _func()
    return statusInfo[checkModlue.Type.Mail.Friend.id]
end


EventManager.getInstance():addListener("Chat_INFO_CHANGE", function(event, data)
    checkModlue:checkFriend()
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)
EventManager.getInstance():addListener("PrivateChatData_CHANGE", function(event, data)
    checkModlue:checkFriend()
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)
EventManager.getInstance():addListener("Mail_Delete_Succeed", function(event, data)
    checkModlue:checkFriend()
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)
EventManager.getInstance():addListener("SystemMessageListRedDotChange", function(event, data)
    checkModlue:checkFriend()
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)


function checkModlue:checkDrawCardFree()
    local _status = false
    if OpenLevel.GetStatus(1801) then
        if module.ActivityModule.GetDrawCardRedDot then
            _status = module.ActivityModule.GetDrawCardRedDot()
        end
    end
    statusInfo[checkModlue.Type.DrawCard.DrawCardFree.id] = _status
    return statusInfo[checkModlue.Type.DrawCard.DrawCardFree.id]
end

--限时商店刷新提示
function checkModlue:checkFlashSaleShopRefresh()
    local _status = false
    if OpenLevel.GetStatus(2401) then
        _status = ShopModule.GetFlashSaleShopStatus()
    end
    statusInfo[checkModlue.Type.Shop.FlashSaleShopRefresh.id] = _status
    return statusInfo[checkModlue.Type.Shop.FlashSaleShopRefresh.id]
end

function checkModlue:checkShopAll()
    statusInfo[checkModlue.Type.Shop.All.id] = checkModlue:checkDrawCardFree() or checkModlue:checkFlashSaleShopRefresh();
    return statusInfo[checkModlue.Type.Shop.All.id];
end

function checkModlue:checkSelectMapGiftBox(gid)
    local _tab = module.RewardModule.GetConfigByType(2, gid) or {}
    local _status = false
    if not statusInfo[checkModlue.Type.SelectMap.GiftBox.id] then
        statusInfo[checkModlue.Type.SelectMap.GiftBox.id] = {}
    end
    statusInfo[checkModlue.Type.SelectMap.GiftBox.id][gid] = false
    local _count = 0
    for i,v in ipairs(_tab or {}) do
        if module.RewardModule.Check(v.id) == module.RewardModule.STATUS.READY then
            _status = true
            statusInfo[checkModlue.Type.SelectMap.GiftBox.id][gid] = _status
            return true
        end
        if module.RewardModule.Check(v.id) == module.RewardModule.STATUS.DONE then
            _count = _count + 1
        end
    end
    if _count == #_tab then
        return false, 1
    end
    return false, 2
end

local function JoinRequestChange()
    local waiting = module.TeamModule.GetTeamWaitingList(3)
    local count = 0
    for k, v in pairs(waiting) do
        count = count + 1
    end
    local teamInfo = module.TeamModule.GetTeamInfo();
    local applyBtn = false
    if count > 0 and teamInfo.leader.pid == module.playerModule.Get().id then
        applyBtn = true
    end
    statusInfo[checkModlue.Type.MainUITeam.TeamJoinRequest.id] = applyBtn
end

function checkModlue:checkMainUITeam()
    return statusInfo[checkModlue.Type.MainUITeam.MainUITeam.id] or false
end

function checkModlue:checkTeamJoinRequest()
    JoinRequestChange()
    return statusInfo[checkModlue.Type.MainUITeam.TeamJoinRequest.id] or false
end

EventManager.getInstance():addListener("TEAM_JOIN_REQUEST_CHANGE", function(event, data)
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

EventManager.getInstance():addListener("JOIN_CONFIRM_REQUEST", function(event, data)
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

EventManager.getInstance():addListener("delApply_succeed", function(event, data)
    DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
end)

function checkModlue:checkPVPCanFight(id)
    local info = module.PVPArenaModule.GetPlayerInfo();
    local arena_property = module.PVPArenaModule.GetArenaProperty(id);
    if arena_property and info then
        local count = id == 1 and info.matching_count or info.pvp_matching_count;
        if arena_property.pvparena_times - count > 0 and CheckActiveTime(arena_property) then
            return true;
        end
    end
    return false;
end

function checkModlue:checkPVPArena()
    local status = false;
    if OpenLevel.GetStatus(1901) and ItemModule.GetItemCount(90033) > 0 then
        local date = os.date("*t", module.Time.now())
        if date.wday == 0 or date.wday == 6 then
            if module.PVPArenaModule.CheckCapacity() then
                status = true;
            elseif checkModlue:checkPVPCanFight(1) or checkModlue:checkPVPCanFight(2) then
                status = true;
            end
        end
    end
    statusInfo[checkModlue.Type.PVPArena.PVPArena.id] = status;
    return statusInfo[checkModlue.Type.PVPArena.PVPArena.id];
end


function checkModlue:checkActivity()
    statusInfo[checkModlue.Type.Activity.Activity.id] = false
    if OpenLevel.GetStatus(1201) then
        for i = 1, 5 do
            if module.QuestModule.CanSubmit(i) then
                statusInfo[checkModlue.Type.Activity.Activity.id] = true
                return true
            end
        end
    end
    return false
end

function checkModlue:MapSceneUIMap()
    statusInfo[checkModlue.Type.MapSceneUI.Map.id] = false
    statusInfo[checkModlue.Type.MapSceneUI.Map.id] = checkModlue:checkQuest()
    return statusInfo[checkModlue.Type.MapSceneUI.Map.id]
end
--每日任务
function checkModlue:checkDailyTask()
    statusInfo[checkModlue.Type.MapSceneUI.DailyTask.id] = false
    for i = 1, 5 do
        if module.QuestModule.CanSubmit(i) then
            statusInfo[checkModlue.Type.MapSceneUI.DailyTask.id] = true
            return true
        end
    end
    local _list = module.QuestModule.GetList(21)
    for i,v in pairs(_list) do
        if module.QuestModule.CanSubmit(v.id) then
            statusInfo[checkModlue.Type.MapSceneUI.DailyTask.id] = true
            return true
        end
    end
    return statusInfo[checkModlue.Type.MapSceneUI.DailyTask.id]
end
--历练笔记奖励
function checkModlue:checkDailyCheckPointTask()
    statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] = false
    local questList = QuestModule.GetList(22)--每日副本任务
    if #questList >0 then
        for k,v in pairs(questList) do
            local startTime = os.time({day=CS.System.DateTime.Now.Day, month = CS.System.DateTime.Now.Month, year = CS.System.DateTime.Now.Year, hour = 0, minute = 0, second = 0})
            if v.accept_time >= startTime and (v.status == 0 or v.status == 1) then
                local cooperaQuest = module.CooperationQuestModule.GetCfg(v.id) or false
                if not cooperaQuest then--单人任务
                    if module.QuestModule.CanSubmit(v.id) then
                        statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] = true 
                        break
                    end
                else
                    module.CooperationQuestModule.Get(nil,v.id,cooperaQuest.share,function ()
                        local cooperaInfo = module.CooperationQuestModule.Get(nil,v.id,cooperaQuest.share)
                        if cooperaInfo and not statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] then
                            if cooperaInfo.status == 0 and cooperaInfo.partnerPid~=0 and not statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] then
                                local _quest1 = module.QuestModule.Get(v.id)
                                if _quest1 and _quest1.status == 1 and not statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] then
                                    local targetId = cooperaQuest.share == 2 and cooperaInfo.quest_id or cooperaQuest.share_id
                                    if targetId and not statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] then
                                        module.QuestModule.GetOtherQuest(cooperaInfo.partnerPid,targetId,v.id,nil,function ()
                                            local _quest2 = module.QuestModule.GetOtherQuest(cooperaInfo.partnerPid,targetId,v.id)
                                            if _quest2 and _quest2.status == 1 then
                                                statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id] = true 
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end  
    end
    return statusInfo[checkModlue.Type.CheckPoint.DailyCheckPointTask.id]
end

function checkModlue:checkZeroPlan()
    statusInfo[checkModlue.Type.MapSceneUI.ZeroPlan.id] = false
    for i,v in ipairs(module.zeroPlanModule.GetQuestList()) do
        if v.quest_id ~= 0 then
            if module.QuestModule.CanSubmit(v.quest_id) then
                statusInfo[checkModlue.Type.MapSceneUI.ZeroPlan.id] = true
                return true
            end
        end
    end
    return false
end

--排位JJC奖励
function checkModlue:checkTraditionalArenaRewards()
    statusInfo[checkModlue.Type.RankArena.Rewards.id] = checkModlue:checkTraditionalArenaScoreRewards() or checkModlue:checkTraditionalArenaRankRewards()
    return statusInfo[checkModlue.Type.RankArena.Rewards.id] 
end
--排位JJC积分奖励
function checkModlue:checkTraditionalArenaScoreRewards()
    statusInfo[checkModlue.Type.RankArena.ScoreRewards.id] = false
    local rewardType = 2
    local scoreReward = module.traditionalArenaModule.GetScoreRewards(rewardType)
    for i=1,#scoreReward do
        if scoreReward[i] and scoreReward[i].questLimit and scoreReward[i].quest_id then
            if module.QuestModule.CanSubmit(scoreReward[i].quest_id) then
                
                statusInfo[checkModlue.Type.RankArena.ScoreRewards.id] = true
                break
            end
        else
            ERROR_LOG("scoreReward is nil")
        end
    end

    return statusInfo[checkModlue.Type.RankArena.ScoreRewards.id]
end
--排位JJC排位奖励
function checkModlue:checkTraditionalArenaRankRewards()
    statusInfo[checkModlue.Type.RankArena.RankRewards.id] = false
    local rewardType = 1
    local rankRewards = module.traditionalArenaModule.GetScoreRewards(rewardType)
    local selfPos = module.traditionalArenaModule.GetSelfRankPos() or 9999
    for i=1,#rankRewards do
        if rankRewards[i] and rankRewards[i].consume then
            local id,value = rankRewards[i].consume.id,rankRewards[i].consume.value
            if id and value then
                local ownCount = module.ItemModule.GetItemCount(id) 
                if rankRewards[i].status and ownCount>= value and rankRewards[i].rankPos >=selfPos then               
                    statusInfo[checkModlue.Type.RankArena.RankRewards.id] = true
                    break
                end
            else
                ERROR_LOG("rankRewards id or value is nil,id,value",id,value)
            end
        else
            ERROR_LOG("rankRewards is nil")
        end
    end
    return statusInfo[checkModlue.Type.RankArena.RankRewards.id]
end

function checkModlue:checkFriendChat()
    statusInfo[checkModlue.Type.FriendChat.Chat.id] = false
    local ChatManager = require "module.ChatModule"
    local ChatData = ChatManager.GetManager(6)--私聊内容
    if ChatData then
        for k,v in pairs(ChatData)do
            if #v > 0 then
                local tempData = v[#v]
                local count = ChatManager.GetPrivateChatData(tempData.fromid)
                if count and count > 0 then
                    statusInfo[checkModlue.Type.FriendChat.Chat.id] = true
                    break
                end
            end
        end
    end
    ChatData = ChatManager.GetManager(8)--好友通知
    if ChatData then
        for k,v in pairs(ChatData)do
            if #v > 0 and v[1].status == 1 then
                statusInfo[checkModlue.Type.FriendChat.Chat.id] = true
                break
            end
        end
    end
    ChatData = ChatManager.GetSystemMessageList()--系统离线消息
    for k,v in pairs(ChatData) do
        for i = 1,#v do
            if v[i][6] and v[i][6] == 0 then
                statusInfo[checkModlue.Type.FriendChat.Chat.id] = true
                break
            end
        end
    end
    return statusInfo[checkModlue.Type.FriendChat.Chat.id]
end

EventManager.getInstance():addListener("ARENA_FORMATION_CHANGE", function(event, data)
    if data.type == 2 or data.type == 3 then
        DispatchEvent("LOCAL_REDDOT_MAPSCENE_CHANE")
    end
end)

EventManager.getInstance():addListener("Chat_INFO_CHANGE", function(event, data)
    if data and data.channel == 7 then
        statusInfo[checkModlue.Type.MainUITeam.MainUITeam.id] = true
        DispatchEvent("LOCAL_REDDOT_MAPSCENE_TEAM")
    end
end)

checkModlue.Type = {
    Union = {
        --是否有公会
        Union      = {id = 1000, check = checkModlue.checkUnion},
        --公会信息
        Info       = {id = 1001, check = checkModlue.checkUninInfo},
        Member     = {id = 1002},
        --有人加入
        Join       = {id = 1003, check = checkModlue.checkUnionJoin},
        --活动
        Activity   = {id = 1004, check = checkModlue.checkUnionActivity},
        Explore    = {id = 1005, check = checkModlue.checkUnionExplore},
        Wish       = {id = 1006, check = checkModlue.checkUnionWish},
        --公会活动
        UnionActivity = {id = 1007, check = checkModlue.checkAllUnionActivity},

        Donation   = {id = 1008, check = checkModlue.checkUnionDonationActivity},
        Investment = {id = 1009,check = checkModlue.checkUnionInvestment},

        --检测所有公会红点

        AllUnion   = {id = 1010,check =checkModlue.checkUnionAll },
        
    },
    Bag = {
        Bag        = {id = 2000, check = checkModlue.checkBag},
        Debris     = {id = 2001}, ---碎片
        Goods      = {id = 2002}, ---商品
        Props      = {id = 2003}, ---道具
        Equip      = {id = 2004}, ---装备
        Insc       = {id = 2005}, ---铭文
    },
    Hero = {
        Hero            = {id = 3000, check = checkModlue.checkHero},
        Level           = {id = 3001, check = checkModlue.checkHeroLevel},        ---升级
        Star            = {id = 3002, check = checkModlue.checkHeroStar},         ---升星
        Adv             = {id = 3003, check = checkModlue.checkHeroAdv},          ---进阶
        Talent          = {id = 3004, check = checkModlue.checkHeroTalent},       ---天赋
        Professional    = {id = 3005, check = checkModlue.checkHeroProfessional}, ---职业点
        Equip           = {id = 3006, check = checkModlue.checkHeroEquip},        ---英雄身上的装备
        HaveEquip       = {id = 3007, check = checkModlue.checkHeroHaveEquip},    ---英雄身上是否有空位置可以装备
        AllHero         = {id = 3008, check = checkModlue.checkAllHero},
        Insc            = {id = 3009, check = checkModlue.checkHeroInsc},
        Compose         = {id = 3010, check = checkModlue.checkHeroCompose},        ---合成
        ComposeNumber   = {id = 3011, check = checkModlue.checkHeroComposeNumber},  ---合成数量新手引导用
        UpEquipLevel    = {id = 3012, check = checkModlue.checkHeroUpEquipLevel},   ---检查英雄装备升级
        UpInscLevel     = {id = 3013, check = checkModlue.checkHeroUpInscLevel},    ---检查英雄铭文升级
        EquipRecommend  = {id = 3014, check = checkModlue.checkHeroEquipRecommend}, ---检查一键装备 只检查开放等级
        InscRecommend   = {id = 3014, check = checkModlue.checkHeroInscRecommend},  ---检查一键装备 只检查开放等级
        UpEquipQuality  = {id = 3015, check = checkModlue.checkHeroUpEquipQuality}, ---装备进阶
        PartnerAdv      = {id = 3016, check = checkModlue.checkPartnerAdv}          ---伙伴进阶 带可激活
    },
    Weapon = {
        Weapon          = {id = 4000, check = checkModlue.checkWeapon},
        Level           = {id = 4001, check = checkModlue.checkWeaponLevel},
        Star            = {id = 4002, check = checkModlue.checkWeaponStar},
        Adv             = {id = 4003, check = checkModlue.checkWeaponAdv},
        Talent          = {id = 4004, check = checkModlue.checkWeaponTalent},
        Professional    = {id = 4005, check = checkModlue.checkWeaponProfessional},
    },
    Equip = {
        Equip           = {id = 5000, check = checkModlue.checkEquip},
        Level           = {id = 5001, check = checkModlue.checkEquipLevel},
        Adv             = {id = 5002, check = checkModlue.checkEquipAdv},
        UpQuality       = {id = 5003, check = checkModlue.checkEquipUpQuality},
    },
    Insc = {
        Insc            = {id = 6000, check = checkModlue.checkInsc},
        Level           = {id = 6001, check = checkModlue.checkInscLevel},
        Adv             = {id = 6002, check = checkModlue.checkInscAdv},
        UpQuality       = {id = 6003, check = checkModlue.checkInscUpQuality},
    },
    Arena = {
        Arena           = {id = 7000, check = checkModlue.checkArena},
        First           = {id = 7001, check = checkModlue.checkArenaFirst},
        Info            = {id = 7002, check = checkModlue.checkArenaInfo},
    },
    Manor = {
        Manor           = {id = 8000, check = checkModlue.checkManor},
        Tavern          = {id = 8001, check = checkModlue.checkTavern},
        Store           = {id = 8002, check = checkModlue.checkStore},
        Manufacture     = {id = 8003, check = checkModlue.checkManufacture},
        Quest           = {id = 8004, check = checkModlue.checkQuest},
        RandomNpc       = {id = 8005, check = checkModlue.checkManorRandomNpc},
    },
    Chat = {
        ChatShow        = {id = 9001, check = checkModlue.checkChatShow},
    },
    SevenDays = {
        SevenDays       = {id = 10000, check = checkModlue.check7days},
    },
    Achievement = {
        Achievement     = {id = 20000, check = checkModlue.checkAchievement},
        SecAchievement  = {id = 20001, check = checkModlue.checkSecAchievenment},
        FirstAchievenment = {id = 20002, check = checkModlue.checkFirstAchievenment},
    },
    Mail = {
        Mail            = {id = 30000, check = checkModlue.checkMail},
        MailAndAward    = {id = 30001, check = checkModlue.checkMailAndAward},
        Friend          = {id = 30002, check = checkModlue.checkFriend},
    },
    SelectMap = {
        GiftBox         = {id = 40001, check = checkModlue.checkSelectMapGiftBox},
    },
    WelfareActivity = {
        WelfareActivity = {id = 50001, check = checkModlue.checkWelfareActivity},
        DailyDraw       = {id = 50002, check = checkModlue.checkDailyDraw},
        LuckyDraw_Time  = {id = 50003, check = checkModlue.checkLuckyDraw_Time},
    },
    DrawCard = {
        DrawCardFree    = {id = 60002, check = checkModlue.checkDrawCardFree},
    },
    MainUITeam = {
        MainUITeam      = {id = 70001, check = checkModlue.checkMainUITeam},
        TeamJoinRequest = {id = 70002, check = checkModlue.checkTeamJoinRequest},
    },
    PVPArena = {
        PVPArena        = {id = 80001, check = checkModlue.checkPVPArena},
    },
    Activity = {
        Activity        = {id = 90001, check = checkModlue.checkActivity},
    },
    MapSceneUI = {
        Map             = {id = 100001, check = checkModlue.MapSceneUIMap},
        DailyTask       = {id = 100002, check = checkModlue.checkDailyTask},
        ZeroPlan        = {id = 100003, check = checkModlue.checkZeroPlan},
    },
    DataBox = {
        DataBox         = {id = 110000, check = checkModlue.checkDataBox},
        NpcData         = {id = 110001, check = checkModlue.checkNpcData},
        UnionData       = {id = 110002, check = checkModlue.checkUnionData},
    },
    Shop = {
        All                     = {id = 120000, check = checkModlue.checkShopAll},
        FlashSaleShopRefresh    = {id = 120001, check = checkModlue.checkFlashSaleShopRefresh},
 
    },
    CheckPoint = {--推图
        DailyCheckPointTask = {id = 130000, check = checkModlue.checkDailyCheckPointTask},
    },
    RankArena = {--排位JJC
        Rewards         = {id = 140000, check = checkModlue.checkTraditionalArenaRewards},
        ScoreRewards    = {id = 140001, check = checkModlue.checkTraditionalArenaScoreRewards},
        RankRewards     = {id = 140002, check = checkModlue.checkTraditionalArenaRankRewards},
    },
    FriendChat = {--好友消息
        Chat            = {id = 150000, check = checkModlue.checkFriendChat},
    },
}

local function getStatus(typeId, id, node,new)
    if typeId and typeId.check then
        typeId:check(id)
    end
    local status = false;
    if id then
        status = statusInfo[typeId.id][id] or false;
    else
        status = typeId and statusInfo[typeId.id] or false;
    end
    if node then
        if status then
            node.gameObject.transform:DOKill()
            node.gameObject.transform.localScale = Vector3.one
            if new and node[UI.Image] then
                node[UI.Image]:DOFade(0.3,0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
            else
                node.gameObject.transform:DOScale(Vector3(1.2, 1.2, 1.2),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
            end
        end
        node.gameObject:SetActive(status);
    end
    return status
end

local function playRedAnim(node)
    if node then
        node.gameObject.transform:DOKill()
        node.gameObject.transform.localScale = Vector3.one
        node.gameObject.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
    end
end

local function closeRedDot(type)
    statusInfo[type.id] = false
    if not type.mustCheck then
        DispatchEvent("LOCAL_REDDOT_CLOSE")
    end
end

return {
    Type = checkModlue.Type,
    GetStatus = getStatus,
    CloseRedDot = closeRedDot,
    CheckModlue = checkModlue,
    PlayRedAnim = playRedAnim,
}
