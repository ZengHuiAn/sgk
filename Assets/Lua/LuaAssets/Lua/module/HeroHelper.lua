local heroStar = require"hero.HeroStar"
local HeroEvo = require "hero.HeroEvo"
local openLevel = require "config.openLevel"

local resourceGetTab = nil
local function GetResCfg(id)
    if not resourceGetTab then
        resourceGetTab = LoadDatabaseWithKey("resource_get", "id")
    end
    if id then
        return resourceGetTab[id]
    end
    return resourceGetTab
end

local masterId = 11000
local maxStarNum = 30
local _bookInfo = {}

local function heroLevelUp(count, hero, levelupExp)
    local _heroLevelup = require "hero.HeroLevelup"
    local _expConfig = _heroLevelup.GetExpConfig(1, hero)
    local all_exp = levelupExp
    local _item = {}
    for i,v in ipairs(count) do
        if v > 0 then
            table.insert(_item, {
                id = _bookInfo[i].id,
                type = 41,
                value = v
            })
        end
    end
    local _have = hero.exp + module.ItemModule.GetItemCount(90001)
    for i=1,4 do
        _have = _have + count[i] * _bookInfo[i].exp_value;
    end
    local level = 1;
    for i,v in ipairs(_expConfig) do
        if v > _have then
            level = i - 1;
            break;
        else
            level = i;
        end
    end
    DialogStack.PushPrefStact("mapSceneUI/Strongerdialog", {info = SGK.Localize:getInstance():getValue("bianqiang_shengji_queren_02", hero.name, level), title = SGK.Localize:getInstance():getValue("bianqiang_shengji_queren_01"), btnName = SGK.Localize:getInstance():getValue("bianqiang_shengji_queren_03"), levelupExp = levelupExp, item = _item, func = function()
        coroutine.resume(coroutine.create( function()
            for i,v in ipairs(count) do
                if v > 0 then
                    if not module.ShopModule.Buy(3, _bookInfo[i].exp_gid, v) then
                        print("兑换经验值err",_bookInfo[i].exp_gid)
                        return;
                    end
                end
                if i == 4 then
                    if hero.exp + all_exp > _expConfig[200] then
                        all_exp = _expConfig[200] - hero.exp;
                    end
                    module.HeroModule.GetManager():AddExp(hero.id, all_exp);
                end
            end
        end));
    end})
end

local function heroUpLevel(heroId)
    if not heroId or heroId == masterId then
        return
    end
    local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    if not _heroCfg then
        return
    end
    local _mastCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, masterId)
    local _heroLevelup = require "hero.HeroLevelup"
    local _expConfig = _heroLevelup.GetExpConfig(1, _mastCfg)
    local _levelupExp = _expConfig[_mastCfg.level] - _heroCfg.exp
    local _needExp = _levelupExp - module.ItemModule.GetItemCount(90001)
    local _haveExp = 0
    local _bookExp = {}
    local count = {0,0,0,0};

    local shopInfo = module.ShopModule.GetManager(3);
	if shopInfo and shopInfo.shoplist then
		_bookInfo = {};
		for k,v in pairs(shopInfo.shoplist) do
			local book = {};
			book.exp_value = v.product_item_value;
			book.exp_gid = v.gid;
			book.id = v.consume_item_id1;
			book.type = v.consume_item_type1;
			table.insert(_bookInfo, book);
		end
		table.sort(_bookInfo,function ( a,b )
			return a.exp_value < b.exp_value;
		end)
	end

    for i=1,4 do
        _bookExp[i] = module.ItemModule.GetItemCount(_bookInfo[i].id) * _bookInfo[i].exp_value
        _haveExp = _haveExp + _bookExp[i]
    end

    if _haveExp == 0 then
        showDlgError(nil, "经验卡不足")
        return;
    end

    if _needExp <= 0 then
        heroLevelUp(count, _heroCfg, _levelupExp)
        return
    elseif _haveExp > _needExp then
        for i=4,1,-1 do
            if _bookExp[i] > _needExp then
                local _count = math.floor(_needExp/_bookInfo[i].exp_value);
                local next_exp = 0;
                for j=i-1,1,-1 do
                    next_exp = next_exp + _bookExp[j];
                end
                if _needExp - _bookInfo[i].exp_value * _count == 0 then
                    count[i] = _count;
                    break;
                elseif next_exp >= (_needExp - _bookInfo[i].exp_value * _count) then
                    count[i] = _count;
                else
                    count[i] = math.ceil(_needExp/_bookInfo[i].exp_value)
                end
            else
                count[i] = module.ItemModule.GetItemCount(_bookInfo[i].id);
            end
            _needExp = _needExp - _bookInfo[i].exp_value * count[i];
            if _needExp <= 0 then
                break
            end
        end
    else
        local _have = _heroCfg.exp + module.ItemModule.GetItemCount(90001)
        for i=1,4 do
            count[i] = module.ItemModule.GetItemCount(_bookInfo[i].id);
            _have = _have + count[i] * _bookInfo[i].exp_value;
        end
        local level = 1;
        for i,v in ipairs(_expConfig) do
            if v > _have then
                level = i - 1;
                break;
            else
                level = i;
            end
        end
    end
    heroLevelUp(count, _heroCfg, _levelupExp)
end

local function heroUpStar(heroId)
    if not heroId then
        return
    end
    local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    if not _heroCfg then
        return
    end
    local _star = _heroCfg.star
    local _coin = module.ItemModule.GetItemCount(90002)
    local _piece = module.ItemModule.GetItemCount(heroId+10000)
    local _coinNeed = 0
    local _pieceNeed = 0
    local _upStar = 0
    for i = 1, 31 do
        if _star >= maxStarNum then
            break
        end
        local _starUpTab = heroStar.GetStarUpTab()[_star+1]
        local _commonTab = heroStar.GetCommonTab()[_star+1]
        if not _starUpTab or not _commonTab then
            break
        end
        if _heroCfg.level < _commonTab["para2"] then
            break
        end
        if _coin < _starUpTab["total_coin"] then
            break
        end
        if _piece < _starUpTab["total_piece"] then
            break
        end
        _coin = _coin - _starUpTab["total_coin"]
        _piece = _piece - _starUpTab["total_piece"]

        _coinNeed = _coinNeed + _starUpTab["total_coin"]
        _pieceNeed = _pieceNeed + _starUpTab["total_piece"]

        _star = _star + 1
        _upStar = _upStar + 1
    end
    local _start = SGK.Localize:getInstance():getValue("huoban_shengxing_pangu_"..math.floor(_star / 6) + 1)
    local heroStar = require"hero.HeroStar"
    local _, _roleStarTab = heroStar.GetroleStarTab()
    DialogStack.PushPrefStact("mapSceneUI/Strongerdialog", {
        title = SGK.Localize:getInstance():getValue("bianqiang_shengxing_queren_01"),
        btnName = SGK.Localize:getInstance():getValue("bianqiang_shengxing_queren_03"),
        info = SGK.Localize:getInstance():getValue("bianqiang_shengxing_queren_02", _heroCfg.name, _start, _roleStarTab[heroId][_star].name, _star % 6),
        item = {
        [1] = {type = 41, id = 90002, value = _coinNeed},
        [2] = {type = 41, id = heroId+10000, value = _pieceNeed},
    }, func = function()
        for i = 1, _upStar do
            module.HeroModule.GetManager():AddRoleStar(heroId, 0)
        end
    end})
end

local function heroUpWeaponStar(heroId)
    if not heroId then
        return
    end
    local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    if not _heroCfg then
        return
    end
    local _star = _heroCfg.weapon_star
    local _coin = module.ItemModule.GetItemCount(90002)
    local _piece = module.ItemModule.GetItemCount(heroId+11000)
    local _coinNeed = 0
    local _pieceNeed = 0
    local _upStar = 0
    for i = 1, 31 do
        if _star >= maxStarNum then
            break
        end
        local _starUpTab = heroStar.GetStarUpTab()[_star+1]
        local _commonTab = heroStar.GetCommonTab()[_star+1]
        if not _starUpTab or not _commonTab then
            break
        end
        if _heroCfg.level < _commonTab["para2"] then
            break
        end
        if _coin < _starUpTab["total_coin"] then
            break
        end
        if _piece < _starUpTab["total_piece"] then
            break
        end
        _coin = _coin - _starUpTab["total_coin"]
        _piece = _piece - _starUpTab["total_piece"]

        _coinNeed = _coinNeed + _starUpTab["total_coin"]
        _pieceNeed = _pieceNeed + _starUpTab["total_piece"]

        _star = _star + 1
        _upStar = _upStar + 1
    end
    local _colorInfo = SGK.Localize:getInstance():getValue("common_quality_"..math.floor(_star / 6) + 1)
    DialogStack.PushPrefStact("mapSceneUI/Strongerdialog", {
        title = SGK.Localize:getInstance():getValue("bianqiang_daoneng_queren_01"),
        btnName = SGK.Localize:getInstance():getValue("bianqiang_daoneng_queren_03"),
        info = SGK.Localize:getInstance():getValue("bianqiang_daoneng_queren_02", _heroCfg.name, _colorInfo, _star % 6, _upStar),
        item = {
        [1] = {type = 41, id = 90002, value = _coinNeed},
        [2] = {type = 41, id = heroId+11000, value = _pieceNeed},
    }, func = function()
        for i = 1, _upStar do
            module.HeroModule.GetManager():AddRoleStar(heroId, 1)
        end
    end})
end

local function heroUpAdv(heroId)
    if not heroId then
        return
    end
    local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    if not _heroCfg then
        return
    end
    coroutine.resume(coroutine.create( function()
        for i = 1, 10 do
            local _nowStageHeroConf = HeroEvo.GetConfig(heroId)[_heroCfg.stage]
            if module.RedDotModule.GetStatus(module.RedDotModule.Type.Hero.Adv, heroId) then
                for j = 1, 6 do
                    local _id = _nowStageHeroConf["cost"..i.."_id"]
                    if  _heroCfg.stage_slot[j] ~= 1 and module.ItemModule.GetItemCount(_id) > 0 then
                        local _data = utils.NetworkService.SyncRequest(17, {nil, heroId, j, 0})
                    end
                end
                local _data = utils.NetworkService.SyncRequest(15, {nil, heroId, 0})
                DispatchEvent("WORKER_INFO_CHANGE",{uuid = _heroCfg.uuid});
                if _data[2] ~= 0 then
                    break
                end
            else
                break
            end
        end
    end))
end

local recommendedItemList = {}

local function checkRecommendedItem(id, idx)
    local _heroList = {}
    for i,v in ipairs(module.HeroModule.GetManager():GetFormation()) do
        if v ~= 0 then
            local _hero = module.HeroModule.GetManager():Get(v)
            if _hero then
                table.insert(_heroList, _hero)
            end
        end
    end
    local function getCount(tab)
        local _count = 0
        for i,v in ipairs(tab or {}) do
            if v == 1 then
                _count = _count + 1
            end
        end
        return _count
    end
    table.sort(_heroList, function(a, b)
        local _a = getCount(a.stage_slot)
        local _b = getCount(b.stage_slot)
        if _a == _b then
            return a.capacity > b.capacity
        end
        return _a > _b
    end)
    for i,v in ipairs(_heroList) do
        for j = 1, 6 do
            if v.stage_slot[j] ~= 1 then
                local _nowStageHeroConf = HeroEvo.GetConfig(v.id)[v.stage]
                if _nowStageHeroConf["cost"..j.."_id"] == id then
                    return {heroId = v.id, suitId = id, suitIdx = j, idx = idx}
                end
            end
        end
    end
end

local recommendItemFlag = true
local function ShowRecommendedItem()
    SGK.Action.DelayTime.Create(1.5):OnComplete(function()
        if recommendItemFlag then
            local i = 1
            while i <= #recommendedItemList do
                local _tab = checkRecommendedItem(recommendedItemList[i], i)
                if _tab and _tab.heroId then
                    recommendItemFlag = false
                    DispatchEvent("RECOMMENDED_ITEM_CHANGE", _tab)
                    return
                else
                    table.remove(recommendedItemList, i)
                end
            end
        end
    end)
end

local function RemoveShowRecommendedItem(idx)
    table.remove(recommendedItemList, idx)
    recommendItemFlag = true
    ShowRecommendedItem()
end

utils.EventManager.getInstance():addListener("LOCAL_DIALOGSTACK_POP", function(event, data)
    recommendItemFlag = true
end)

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, data)
    recommendItemFlag = true
end)

utils.EventManager.getInstance():addListener("LOCAL_PLACEHOLDER_CHANGE", function(event, data)
    for i,v in pairs(module.equipmentModule.GetPlace() or {}) do
        for k,p in pairs(v) do
            if p.heroid == 0 then
                DispatchEvent("LOCAL_EQUIP_INFO_BEFORE", p.uuid)
                break
            end
        end
    end
end)

utils.EventManager.getInstance():addListener("ITEM_INFO_CHANGE", function(event, data)
    do return end
    if data and data.gid and openLevel.GetStatus(1106) then
        local _cfg = utils.ItemHelper.Get(41, data.gid)
        if _cfg.sub_type == 55 then
            for i = 1, data.count do
                table.insert(recommendedItemList, data.gid)
            end
            ShowRecommendedItem()
        end
    end
end)

local fashionSuitTab=nil
local fashionSuitCfgByShowMode=nil
local fashionSuitBySuitId=nil
local function GetHeroFashionSuitConfig(heroid)
    if not fashionSuitTab then
        fashionSuitTab= {}
        fashionSuitCfgByShowMode={}
        fashionSuitBySuitId={}
        DATABASE.ForEach("fashion", function(v)
            local conditions={}
            for i=1,6 do
                if v["quest_id"..i]~=0 then
                    table.insert(conditions,v["quest_id"..i])
                end
            end

            local _temp=setmetatable(  {
                                    showMode = v.fashion_id,
                                    suitId=v.is_get,
                                    finishQuest = v.quest_id6,
                                    conditions=conditions
                                },{__index=v}
                            )
            if v.is_get~=0 then
                fashionSuitBySuitId[v.is_get]=_temp
            end
            fashionSuitCfgByShowMode[v.role_id]=fashionSuitCfgByShowMode[v.role_id] or {}
            fashionSuitCfgByShowMode[v.role_id][v.fashion_id]=_temp

            fashionSuitTab[v.role_id] = fashionSuitTab[v.role_id] or {}
            table.insert(fashionSuitTab[v.role_id],_temp)

        end)
    end
    for k,v in pairs(fashionSuitTab) do
        table.sort(v,function (a,b)
            return a.suitId<b.suitId
        end)
    end
    if heroid then
        return fashionSuitTab[heroid]
    else
        return fashionSuitTab
    end
end

local function GetFashionSuitsCfgBySuitId(suitId)
    if not fashionSuitBySuitId then
        GetHeroFashionSuitConfig()
    end
    return fashionSuitBySuitId[suitId]
end

local function GetFashionSuitsCfgByShowMode(heroId,showMode)
    if not fashionSuitCfgByShowMode then
        GetHeroFashionSuitConfig()
    end

    if heroId and showMode then
        return fashionSuitCfgByShowMode[heroId][showMode]
    end
end

local function GetDefaultMode(heroId)
    local _showMode=0
    if not fashionSuitTab then
        GetHeroFashionSuitConfig()
    end
    local suitTab=GetHeroFashionSuitConfig(heroId)
    if suitTab then
        for i=1,#suitTab do
            if suitTab[i].suitId == 0 then
                _showMode = suitTab[i].showMode
                break
            end
        end
    else
        _showMode = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId).mode
        --ERROR_LOG("hero suit cfg is nil",heroId)
    end
    return _showMode
end
--兑换时装
local function GetSuitByItem(hero,suitId)
    local productSuit = module.ShopModule.GetManager(8,suitId) and module.ShopModule.GetManager(8,suitId)[1];
    if productSuit then
        local consumeId=productSuit.consume_item_id1
        local consumePrice=productSuit.consume_item_value1
        local targetGid=productSuit.gid
        local ownCount=module.ItemModule.GetItemCount(consumeId)
        local storage = productSuit.storage
        if ownCount>=consumePrice then
            if storage>=1 then
                module.ShopModule.BuyTarget(8, targetGid, 1, hero.uuid)
            else
                print("时装存量不足",storage);
            end
        else
            print("时装兑换资源不足", consumeId, ownCount, consumePrice);
        end
    else
        ERROR_LOG("时装已停售",suitId);
    end
end

local function GetModeCfg(headIcon,pid)
    local pid =pid or module.PlayerModule.GetSelfID()
    local _headCfg=utils.PlayerInfoHelper.GetHeadCfg(headIcon)

    if _headCfg then
        local _hero = module.HeroModule.GetManager(pid):Get(_headCfg.id)
        if _hero then--拥有该hero
            return _hero.showMode
        else
            return _headCfg.mode
        end
    else
        return headIcon
    end
end

local function GetShowIcon(heroId)
    local _hero = module.HeroModule.GetManager():Get(heroId)
    if _hero then
        if _hero.showMode ~=GetDefaultMode(heroId) then--如果英雄穿着时装
            local suitCfg=GetFashionSuitsCfgByShowMode(heroId,_hero.showMode)
            if suitCfg then
                return suitCfg.showMode
            else
                ERROR_LOG("hero"..heroId.."suit".._hero.showMode.."不存在")
            end
        else
            return _hero.cfg.icon
        end
    end
end

--获取英雄加了几点
local function GetTalentCount(heroId)
    local _count = 0
    local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    local _type = 2
    if heroId == 11000 then
        local _cfg = module.TalentModule.GetSkillSwitchConfig(heroId)
        _type = _cfg[_hero.property_value].type
    end
    for i,v in ipairs(module.TalentModule.GetTalentData(_hero.uuid, _type) or {}) do
        _count = _count + v
    end
    return _count
end

local addExpByItemCfg = nil
local function checkAddExpByItem(gid)
    if not addExpByItemCfg then
        addExpByItemCfg = LoadDatabaseWithKey("add_exp_by_item", "gid")
    end
    local _cfg = addExpByItemCfg[gid]
    if _cfg then
        local _count = module.ItemModule.GetItemCount(_cfg.item_id)
        if _count >= _cfg.item_value then
            return true
        end
    end
end

local function AddExpByItem(heroUuid ,gid)
    if not gid then
        print("AddExpByItem gid nil")
        return
    end
    if checkAddExpByItem(gid) then
        return utils.NetworkService.SyncRequest(94, {nil, heroUuid, gid})
    end
end

return {
    HeroUpLevel = heroUpLevel,
    HeroUpStar = heroUpStar,
    HeroUpWeaponStar = heroUpWeaponStar,
    HeroUpAdv = heroUpAdv,
    GetResCfg = GetResCfg,
    ShowRecommendedItem = ShowRecommendedItem,
    RemoveShowRecommendedItem = RemoveShowRecommendedItem,


    GetModeCfg=GetModeCfg,--获取形象
    GetFashionSuits=GetHeroFashionSuitConfig,--获取时装配置 --hero
    GetDefaultMode=GetDefaultMode,--获取默认时装Id
    GetCfgByShowMode=GetFashionSuitsCfgByShowMode,--通过形象Id获取配置
    GetCfgBySuitId=GetFashionSuitsCfgBySuitId,--通过时装获得配置
    GetHeroSuit=GetSuitByItem,

    GetShowIcon=GetShowIcon,--英雄对应的时装头像
    GetTalentCount = GetTalentCount,
    AddExpByItem = AddExpByItem,
}
