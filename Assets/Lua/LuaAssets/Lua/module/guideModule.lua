local rewardModule = require "module.RewardModule"
local MapConfig = require "config.MapConfig"
local ManorManufactureModule = require "module.ManorManufactureModule"
local UserDefault = require "utils.UserDefault"

local printLog = false

local guideCfg = nil
local guideTypeCfg = nil
local guideCfgByGroup = nil
local firstQuest = true
local storyDialogFlag = false
local groupIdFlag = true
local GuideDialogFlag= false
local breakList = {} --确保final_id完成后 后续的引导能够继续下去

local function printLogFunc(...)
    if printLog then
        print(...)
    end
end
local function GetCfg(id, type, groupId)
    if guideCfg == nil then
        guideCfg = {}
        guideTypeCfg = {}
        guideCfgByGroup = {}

-- [[
        DATABASE.ForEach("guide", function(data)
            --if data.id >= 7000 and data.id <= 7999 or data.id == 9901 then

            --else
                guideCfg[data.id] = data
                if not guideTypeCfg[data.guide_type] then guideTypeCfg[data.guide_type] = {} end
                table.insert(guideTypeCfg[data.guide_type], data)
                if not guideCfgByGroup[data.final_id] then guideCfgByGroup[data.final_id] = {} end
                table.insert(guideCfgByGroup[data.final_id], data)
            --end
        end)
--]]
    end
    if groupId then
        return guideCfgByGroup[groupId]
    end
    if type then
        return guideTypeCfg[type]
    end
    return guideCfg[id]
end

local showFlag = false

local useCfg = nil
local function loadUseCfg()
    if not useCfg then
        useCfg = {}
    end
end

local firstLogin = true
local function GetFirstLogin()
    return firstLogin
end

local function SetFirstLogin(bool)
    firstLogin = bool
end

local function ClearCacheByGroupId(groupId)
    if not useCfg then useCfg = {} end
    local _rewardFlag = rewardModule.Check(groupId)
    if _rewardFlag == rewardModule.STATUS.DONE then
        return
    end
    local _list = GetCfg(nil, nil, groupId)
    for i,v in ipairs(_list or {}) do
        if useCfg[v.id] then
            useCfg[v.id] = nil
        end
    end
    showFlag = false
    groupIdFlag = true
    storyDialogFlag = false
end

local onlyOneFlag = true
local dialogFlag = true
local function setUseCfg(id)
    if useCfg then
        useCfg[id] = {}
        useCfg[id].key = id
        local _cfg = GetCfg(id)
        if _cfg then
            if _cfg.final_id == id then
                breakList[id] = true
                rewardModule.Gather(id)
            end
            if _cfg.group_id == id then
                dialogFlag = true
                local isShowId = UserDefault.Load("Local_isShowId",true)
                if _cfg.group_guide ~= 0 then
                    isShowId[#isShowId+1]=_cfg.group_guide
                    UserDefault.Save()
                end
            end
        end
        if groupIdFlag == _cfg.id then
            groupIdFlag = true
            onlyOneFlag = true
        end
        if _cfg.quese_id ~= 0 then
            module.QuestModule.Finish(_cfg.quese_id)
        end
        if _cfg.isback_main == 1 then
            DialogStack.CleanAllStack()
        end
        if _cfg.tp_npcid ~= 0 then
            local _npc = MapConfig.GetMapMonsterConf(_cfg.tp_npcid)
            if _npc and _npc.mapid then
                SceneStack.EnterMap(_npc.mapid, {func = function()
                    showFlag = false
                    module.EncounterFightModule.GUIDE.Interact("NPC_".._cfg.tp_npcid)
                end, guide = true, pos = {_npc.Position_x, _npc.Position_y, _npc.Position_z}})
            end
        end
        if _cfg.tp_mapid ~= 0 then
            SceneStack.EnterMap(_cfg.tp_mapid, {func = function()
                showFlag = false
            end, guide = true})
        end
        showFlag = false
        OperationQueueNext();
        if id ~= 1021 and id ~= 1026 then
            utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE",id)
        end
        if _cfg.NeedPass == 0 then
            utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_PASS",id)
        end
    end
end

local function RemoveGuideMask(needSet)
    local _guide = UnityEngine.GameObject.FindWithTag("GuideRoot")
    if type(showFlag) == "number" and needSet == nil then
        setUseCfg(showFlag)
    end
    if _guide then
        CS.UnityEngine.GameObject.Destroy(_guide.gameObject)
        return true
    end
    return false
end

local function showMask(node, id, story_id, needPass)
    -- ERROR_LOG("showMask", node, id, debug.traceback())
    local _cfg = GetCfg(id)
    
    if type(node) == "string" then
        node = CS.UnityEngine.GameObject.Find(node)
    end
    if not node and _cfg.talk_order ~= 3 then
        if _cfg.showNode == "0" then
            printLogFunc(id, "guideNode not find")
            showFlag = false
            groupIdFlag = true;
            -- setUseCfg(id)
            OperationQueueNext();
            return
        end
        node = CS.UnityEngine.GameObject.Find(_cfg.showNode)
        if not node then
            printLogFunc(id, "guideNode not find")
            showFlag = false
            groupIdFlag = true;
            -- setUseCfg(id)
            OperationQueueNext();
            return
        end
    end
    if not node then
        ERROR_LOG(id, "guideNode not find showMask")
        showFlag = false
        groupIdFlag = true;
        -- setUseCfg(id)
        return
    end
    
    GuideDialogFlag = false
    onlyOneFlag = false

    local _root = UnityEngine.GameObject.FindWithTag("UITopRoot") or UnityEngine.GameObject.FindWithTag("UGUIGuideRoot") or UnityEngine.GameObject.FindWithTag("UGUIRootTop") or UnityEngine.GameObject.FindWithTag("UGUIRoot")
    if _root then
        local _obj = CS.SGK.UIReference.Setup(_root)
        if _obj.UIGuideRoot then
            _root= _obj.UIGuideRoot.gameObject
        end
    end
    if _cfg.guide_type ~= 7 then
        if _cfg.guide_type ~= 70 then
            if _root then
                local _Obj = CS.SGK.UIReference.Setup(_root)
                if _Obj.transform.childCount > 0 then
                    ERROR_LOG(id, "root child is more")
                    --showFlag = false
                    --setUseCfg(id)
                    return
                end
            end
        end
    end

    if not _root then
        ERROR_LOG(id, "not find root")
        showFlag = false
        setUseCfg(id)
        return
    end
    -- if _cfg.guide_type ~= 0 then
    --     if _cfg.guide_type ~= 7 and _cfg.guide_type ~= 8 then
    --         if not node.gameObject.activeInHierarchy then
    --             printLogFunc(id, "guideNode activeInHierarchy")
    --             showFlag = false
    --             setUseCfg(id)
    --             return
    --         end
    --     end
    -- end
    if id ~= 7011 and id ~= 7012 and id ~= 7013 and id ~= 7023 and id ~= 7024 and id ~= 7025 then 
        utils.EventManager.getInstance():dispatch("GUIDE_SHOW_MASK")
        module.quickToUseModule.Clear()
    end
    utils.SGKTools.StopPlayerMove()
    local _item = SGK.ResourcesManager.Load("prefabs/mapSceneUI/item/guideNode.prefab")
    local obj = CS.UnityEngine.GameObject.Instantiate(_item.gameObject, _root.transform)
    local _view = CS.SGK.UIReference.Setup(obj)


    local function GetSize()
        local _h = (_cfg.height or 0)
        local _w = (_cfg.width or 0)
        local _showH = (_cfg.height_zhezhao or 0)
        local _showW = (_cfg.width_zhezhao or 0)
        local _pivot = UnityEngine.Vector2(0.5, 0.5);
        if node.transform.sizeDelta then
            _h = _h + node.transform.rect.height;
            _w = _w + node.transform.rect.width;
            _showH = _showH + node.transform.rect.height;
            _showW = _showW + node.transform.rect.width;
            _pivot = node.transform.pivot;
        end

        return _h, _w, _showH, _showW, _pivot;
    end

    local _h, _w, _showH, _showW, _pivot = GetSize();

    _view.mask[SGK.GuideMask].color = {r = 0, g = 0, b = 0, a = _cfg.isshow_zhezhao / 255}
    _view.circlesMask[UI.Image].color = {r = 0, g = 0, b = 0, a = _cfg.isshow_zhezhao / 255}
    -- _view.mask[SGK.GuideMask].color = {r = 0, g = 0, b = 0, a = 0}
    -- _view.circlesMask[UI.Image].color = {r = 0, g = 0, b = 0, a = 0}
    _view.mask[SGK.GuideMask].lookupTime = _cfg.lookup_time or 0.5
    local _callBcak = function()
        local _h, _w, _showH, _showW, _pivot = GetSize();

        _view.box.transform.pivot = _pivot
        _view.mask.transform.pivot = _pivot
        _view.circlesMask.transform.pivot = _pivot
        _view.showBox.transform.pivot = _pivot;

        local _nodePos = SGK.GuideMask.GetNodePos(node.gameObject)
        _view.box.transform.position = _nodePos + Vector3(_cfg.offset_x, _cfg.offset_y)

        _view.box.transform:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, _h)
        _view.box.transform:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Horizontal, _w)

        _view.showBox.transform.position = _view.box.transform.position
        _view.showBox.transform:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, _showH)
        _view.showBox.transform:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Horizontal, _showW)

        if _cfg.kuang_type == 2 then
            _view.mask[SGK.GuideMask]:setCirclePos(_view.showBox.transform.position)
            _view.mask[SGK.GuideMask].diameter = math.min(_view.showBox.transform.rect.height, _view.showBox.transform.rect.width) / 2
        end

        -- if _cfg.little_talking == 3 then
        --    _view.desc.transform.localPosition = _view.box.transform.localPosition + Vector3(0, _h, 0)
        -- elseif _cfg.little_talking == 2 then
        --    _view.desc.transform.localPosition = _view.box.transform.localPosition - Vector3(_view.desc.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width / 2 + _showW / 2, 0, 0)
        -- elseif _cfg.little_talking == 1 then
        --    _view.desc.transform.localPosition = _view.box.transform.localPosition + Vector3(_view.desc.transform:GetComponent(typeof(UnityEngine.RectTransform)).rect.width / 2 + _showW / 2, 0, 0)
        -- elseif _cfg.little_talking == 4 then
        --      _view.desc.transform.localPosition = _view.box.transform.localPosition - Vector3(0, _h, 0)
        -- end

        if _cfg.little_talking == 1 then
            _view.guide.transform.localPosition = _view.top.transform.localPosition;
        elseif _cfg.little_talking == 2 then
            _view.guide.transform.localPosition = _view.bottom.transform.localPosition;
        else 
            _view.guide.transform.localPosition = Vector3.zero;
        end
    end
    _callBcak()
    SGK.GuideMask.Get(_view.mask.gameObject):SetUpdateCallback(function()
        _callBcak()
    end)

    -- _view.box.rectangle:SetActive(_cfg.kuang_type == 1)
    -- _view.box.circles:SetActive(_cfg.kuang_type == 2)
    _view.circlesMask:SetActive(_view.box.circles.activeSelf)

    _view.mask[SGK.GuideMask].isCircle = _view.box.circles.activeSelf
    if _view.mask[SGK.GuideMask].isCircle then
        _view.mask[SGK.GuideMask].diameter = math.min(_showH, _showW) / 2
    end

    _view.desc:SetActive(false)
    -- for i = 1, 4 do
    --     _view.desc["arrow"..i]:SetActive(i == _cfg.little_talking)
    --     if i == _cfg.little_talking then
    --         _view.desc["arrow"..i].Image:SetActive(_cfg.little_talking_head == 1)
    --         _view.desc:SetActive(true)
    --         break
    --     end
    -- end
    -- _view.desc.info[UI.Text].text = _cfg.little_talking_des
    if _cfg.little_talking_head ~= 0 then
        _view.guide.Image.expression[CS.UGUISpriteSelector].index = _cfg.little_talking_head - 1;
        _view.guide.Image.expression:SetActive(true);
    end
    
    if _cfg.little_talking ~= 0 then
        if _cfg.little_talking_animation == 1 then
            _view.guide.gameObject.transform.localScale = Vector3(1, 0, 1);
            -- _view.guide[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
            _view.guide.gameObject.transform:DOScale(Vector3.one, 0.2):SetEase(CS.DG.Tweening.Ease.OutBack)
        else
            _view.guide.gameObject.transform.localScale = Vector3.one;
        end
    end

    _view.guide:SetActive(_cfg.little_talking ~= 0)

    _view.guide.info[UI.Text].text = _cfg.little_talking_des;

    -- _view.box.hand.transform.localScale = Vector3(_sizeX, _sizeY, 1)
    -- _view.box.hand.transform:DOScale(Vector3(_sizeX + 0.05, _sizeY + 0.05, 1), 0.3):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)

    -- _view.box.hand:SetActive(true)

    _view.mask[SGK.GuideMask].NeedPass = needPass
    _view:SetActive(false)
    _view:SetActive(true)

    local _func = function(...)
            local env = setmetatable({
                EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
                Interact = module.EncounterFightModule.GUIDE.Interact,
                GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
                GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
            }, {__index=_G})
            local _luaFunc = loadfile("guide/".."strongerGuide"..".lua", "bt", env)
            if _luaFunc then
                if tonumber(_cfg.gotowhere) == 28 then
                    DialogStack.CleanAllStack()
                end
                _luaFunc({cfg = {guideValue = tonumber(_cfg.gotowhere)}})
            end
        --end
    end
    if tonumber(_cfg.gotowhere) ~= 0 then
        SGK.GuideMask.Get(_view.mask.gameObject).onClick2 = _func
    end

    local _next = function ()
        if _cfg.showNode == "mapSceneUIRoot/bottom/allBtn/role/icon" then
            utils.EventManager.getInstance():dispatch("MapSceneUI_Role_Icon")
        end
        if story_id then
            RemoveGuideMask(true)
            LoadGuideStory(story_id, function()
                printLogFunc("guide", id, "over")
                setUseCfg(id)
            end)
            return
        end
        RemoveGuideMask()
        setUseCfg(id)
    end
    if _cfg.click_type == 1 then
        local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_guide_hand_1.prefab"), _view.box.transform)
        obj.transform.localPosition = Vector3.zero;
        SGK.GuideMask.Get(_view.mask.gameObject).onClick = _next
    elseif _cfg.click_type == 2 then
        local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_guide_hand_2.prefab"), _view.box.transform)
        obj.transform.localPosition = Vector3.zero;
        local GuideMask = SGK.GuideMask.Get(_view.mask.gameObject);
        if GuideMask.pressTime == nil then
            GuideMask.onClick = _next
            GuideMask.NeedPass = false;
        else
            SGK.GuideMask.Get(_view.mask.gameObject).pressTime = _cfg.press_args
            SGK.GuideMask.Get(_view.mask.gameObject).onPress = _next
        end
    end
end

--避免同组引导在一次启动中出现2次
local useSameCfg = nil
local function loadUseSameCfg()
    if not useSameCfg then
        useSameCfg = {}
    end
end

local function SetUseSameCfg(sameId)
    if sameId == 0 then
        return
    end
    for k,v in pairs(useSameCfg) do
        if sameId == v then
            return
        end
    end
    useSameCfg[#useSameCfg+1]=sameId
end

local function CompareUseSameCfg(sameId)
    if sameId == 0 then
        return false
    end
    for k,v in pairs(useSameCfg) do
        if sameId == v then
            return true
        end
    end
    return false
end

--根据各种条件判断引导是否可以进行
local function canPlay(id)
    --do return; end
    local _cfg = GetCfg(id)
    local _gm = module.ItemModule.GetItemCount(9998)
    if _gm and _gm > 0 then
        return
    end
    if not _cfg then
        printLogFunc("not find", id)
        return
    end

    loadUseSameCfg()
    if CompareUseSameCfg(_cfg.group_guide) and _cfg.rely_id == 0 then
        return
    end
    local isShowId = UserDefault.Load("Local_isShowId",true)
    if isShowId ~= nil then
        for k,v in pairs(isShowId) do
            if id == 1005 then
                --print("检测是否为执行过的同组引导",sprinttb(isShowId),v)
            end
            if v == _cfg.group_guide then
                printLogFunc("is same group", id)
                return
            end
        end
    end
    if utils.UserDefault.Load("GMGuide", true).close then
        if id == 1401 and _cfg.final_id == 1409 then
            if module.QuestModule.CanSubmit(100042) then
                module.QuestModule.Finish(100042)
            end
        end
        return
    end
    if groupIdFlag ~= _cfg.group_id then
        if groupIdFlag ~= true then
            printLogFunc("in group", id, _cfg.group_id, groupIdFlag, showFlag)
            return
        end
    end
    if _cfg.isplay_fight == 0 and SceneStack.GetBattleStatus() then
        printLogFunc("fighting now", id)
        return
    end
    if _cfg.isplay_team == 0 and utils.SGKTools.GetTeamState() then
        printLogFunc("team now", id)
        return
    end
    -- local _guide = UnityEngine.GameObject.FindWithTag("GuideRoot")
    -- if _guide then
    --     printLogFunc("guide now", id, _guide.name, _guide.transform.parent.name)
    --     return
    -- end
    loadUseCfg()
    if not breakList[_cfg.final_id] then
        local _rewardFlag = rewardModule.Check(_cfg.final_id)
        if _rewardFlag == rewardModule.STATUS.ERROR then
            printLogFunc(id, _cfg.final_id, "not find by reward cfg")
            return
        end
        if _rewardFlag == rewardModule.STATUS.DONE then
            printLogFunc(id, "is finish by reward cfg")
            return
        end
    end
    if storyDialogFlag and _cfg.guide_type ~= 30 then
        if _cfg.guide_type ~= 0 then
            printLogFunc(id, "story dialog flage")
            return
        end
    end

    if showFlag then
        printLogFunc(id, "is show flage")
        return
    end

    if useCfg[id] then
        printLogFunc(id, "guide is finish")
        return
    end
    if _cfg.rely_id ~= 0 then
        if not useCfg[_cfg.rely_id] then
            local _flag = rewardModule.Check(_cfg.final_id)
            if _flag ~= rewardModule.STATUS.DONE then
                printLogFunc(id, "guide not exists")
                return
            end
            printLogFunc(id, "guide not exists")
            return
        end
    end
    for i = 1, 4 do
        if _cfg["event_type"..i] == 1 then  --玩家等级
            if not module.HeroModule.GetManager():Get(11000) or module.HeroModule.GetManager():Get(11000).level < _cfg["event_count"..i] then
                printLogFunc(id, "guide pass error 1")
                return
            end
        elseif _cfg["event_type"..i] == 2 then --拥有伙伴数量
            if module.HeroModule.GetHeroCount() < _cfg["event_count"..i] then
                printLogFunc(id, "guide pass error 2")
                return
            end
        elseif _cfg["event_type"..i] == 3 then --完成某场战斗
            if not module.fightModule.GetFightInfo(_cfg["event_id"..i]):IsPassed() then
                printLogFunc(id, "guide pass error 3")
                return
            end
        elseif _cfg["event_type"..i] == 4 then --获得了某个道具
            if module.ItemModule.GetItemCount(_cfg["event_id"..i]) < _cfg["event_count"..i] then
                printLogFunc(id, "guide pass error 4")
                return
            end
        elseif _cfg["event_type"..i] == 5 then --有伙伴可解锁时
            local _number = module.RedDotModule.GetStatus(module.RedDotModule.Type.Hero.ComposeNumber)
            if _number <= 0 then
                printLogFunc(id, "guide pass error 5")
                return
            end
        elseif _cfg["event_type"..i] == 6 then --完成某个任务
            local _id = _cfg["event_id"..i]
            local _quest = module.QuestModule.Get(_id)
            if not _quest or _quest.status ~= 1 then
                printLogFunc(id, "guide pass error 6")
                return
            end
        elseif _cfg["event_type"..i] == 7 then --上阵位置空时
            local _pos = _cfg["event_count"..i]
            local _heroFormation = module.HeroModule.GetManager():GetFormation()
            if _heroFormation[_pos] ~= 0 then
                local _flag = rewardModule.Check(_cfg.final_id)
                if _flag == rewardModule.STATUS.READY then
                    rewardModule.Gather(_cfg.final_id)
                end
                printLogFunc(id, "guide pass error 7_1")
                return
            else
                local _heroCount = module.HeroModule.GetHeroCount()
                local _count = 0
                for i,v in ipairs(_heroFormation) do
                    if v ~= 0 then
                        _count = _count + 1
                    end
                end
                if _count >= _heroCount then
                    printLogFunc(id, "guide pass error 7_2")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 8 then --开服七天
            if not module.QuestModule.GetSevenDayOpen() then
                printLogFunc(id, "guide pass error 8")
                return
            end
        elseif _cfg["event_type"..i] == 9 then  --装备
            local _roleId = _cfg["event_id"..i]
            local _pos = _cfg["event_count"..i]
            local _cfg = module.equipmentModule.GetHeroEquip(_roleId, _pos, 0)
            if _cfg then
                local _flag = rewardModule.Check(_cfg.final_id)
                if _flag == rewardModule.STATUS.READY then
                    rewardModule.Gather(_cfg.final_id)
                end
                printLogFunc(id, "guide pass error 9_1")
                return
            end
            if not module.equipmentModule.GetPosEquip(_pos) then
                printLogFunc(id, "guide pass error 9_2")
                return
            end
        elseif _cfg["event_type"..i] == 10 then --接到某个任务 未完成
            local _questId = _cfg["event_id"..i]
            if _questId and _questId ~= 0 then
                local _quest = module.QuestModule.Get(_questId)
                if not _quest then
                    --print("引导任务未完成错误1")
                    printLogFunc(id, "guide pass error 10_2")
                    return
                end
                if _quest and _quest.status ~= 0 then
                    --print("引导任务未完成错误2")
                    printLogFunc(id, "guide pass error 10_1")
                    return
                end
            else
                --print("引导任务未完成错误3")
                printLogFunc(id, "guide pass error 10_2")
                return
            end
        elseif _cfg["event_type"..i] == 11 then --在队伍中
            if not utils.SGKTools.GetTeamState() then
                printLogFunc(id, "guide pass error 11")
                return
            end
        elseif _cfg["event_type"..i] == 12 then --有无公会
            if not module.unionModule.Manage:GetSelfUnion() then
                printLogFunc(id, "guide pass error 12")
                return
            end
        elseif _cfg["event_type"..i] == 13 then --祈愿有几个东西
            if module.unionActivityModule.WishManage:GetWishInfo().progress > 0 then
                local _flag = rewardModule.Check(_cfg.final_id)
                if _flag == rewardModule.STATUS.READY then
                    rewardModule.Gather(_cfg.final_id)
                end
                printLogFunc(id, "guide pass error 13")
                return
            end
        elseif _cfg["event_type"..i] == 14 then --探险有几个东西
            for i,v in pairs(module.unionActivityModule.ExploreManage:GetTeamInfo()) do
                if v.heroTab then
                    for i,v in ipairs(v.heroTab) do
                        if v ~= 0 then
                            local _flag = rewardModule.Check(_cfg.final_id)
                            if _flag == rewardModule.STATUS.READY then
                                rewardModule.Gather(_cfg.final_id)
                            end
                            printLogFunc(id, "guide pass error 14")
                            return
                        end
                    end
                end
            end
        elseif _cfg["event_type"..i] == 15 then --庄园有无人工作
            local productInfo = ManorManufactureModule.Get();
            for k,v in pairs(productInfo:GetLine() or {}) do
                for i,p in ipairs(v.workers or {}) do
                    if p ~= 0 then
                        local _flag = rewardModule.Check(_cfg.final_id)
                        if _flag == rewardModule.STATUS.READY then
                            rewardModule.Gather(_cfg.final_id)
                        end
                        printLogFunc(id, "guide pass error 15")
                        return
                    end
                end
            end
        elseif _cfg["event_type"..i] == 16 then --是否拥有某个英雄
            if _cfg["event_id"..i] ~= 0 then
                if module.HeroModule.GetManager():Get(_cfg["event_id"..i]) then
                    local _flag = rewardModule.Check(_cfg.final_id)
                    if _flag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 16")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 17 then --一次性奖励
            if _cfg["event_id"..i] ~= 0 then
                local _flag = rewardModule.Check(_cfg["event_id"..i])
                if _flag ~= rewardModule.STATUS.READY then
                    local _finalFlag = rewardModule.Check(_cfg.final_id)
                    if _finalFlag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 17")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 18 then --在某个地图触发
            if _cfg["event_id"..i] ~= 0 then
                if _cfg["event_id"..i] ~= SceneStack.MapId() then
                    printLogFunc(id, "guide pass error 18")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 19 then --所有角色未进阶过
            local _heroList = module.HeroModule.GetSortHeroList(1)
            for i,v in ipairs(_heroList) do
                if v.stage ~= 0 then
                    local _finalFlag = rewardModule.Check(_cfg.final_id)
                    if _finalFlag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 19")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 20 then --所有角色未升星过
            local _heroList = module.HeroModule.GetSortHeroList(1)
            for i,v in ipairs(_heroList) do
                if v.star ~= 0 then
                    local _finalFlag = rewardModule.Check(_cfg.final_id)
                    if _finalFlag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 20")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 21 then --所有盗具未充能过
            local _heroList = module.HeroModule.GetSortHeroList(1)
            for i,v in ipairs(_heroList) do
                if v.weapon_star ~= 0 then
                    local _finalFlag = rewardModule.Check(_cfg.final_id)
                    if _finalFlag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 21")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 22 then --所有芯片未进阶过
            local _list = module.equipmentModule.GetEquip()
            for k,v in pairs(_list) do
                local _idx = tonumber(string.sub(tostring(v.id), -3, -3))
                if _idx ~= 0 then
                    local _finalFlag = rewardModule.Check(_cfg.final_id)
                    if _finalFlag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 22")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 23 then --某个角色某位置已装备了芯片/守护
            local _roleId = _cfg["event_id"..i]
            local _pos = _cfg["event_count"..i]
            local _cfg = module.equipmentModule.GetHeroEquip(_roleId, _pos, 0)
            if not _cfg then
                printLogFunc(id, "guide pass error 23")
                return
            end
        elseif _cfg["event_type"..i] == 24 then --某个角色某个位置装备的芯片可以进阶
            local _roleId = _cfg["event_id"..i]
            local _pos = _cfg["event_count"..i]
            local _cfg = module.equipmentModule.GetHeroEquip(_roleId, _pos, 0)
            if not _cfg then
                printLogFunc(id, "guide pass error 24_1")
                return
            else
                if not module.RedDotModule:GetStatus(module.RedDotModule.Type.Equip.UpQuality, _cfg.uuid) then
                    printLogFunc(id, "guide pass error 24_2")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 25 then --背包内有某个道具时标记完成
            if _cfg["event_id"..i] ~= 0 then
                local _count = module.ItemModule.GetItemCount(_cfg["event_id"..i])
                if _count >= _cfg["event_count"..i] then
                    local _finalFlag = rewardModule.Check(_cfg.final_id)
                    if _finalFlag == rewardModule.STATUS.READY then
                        rewardModule.Gather(_cfg.final_id)
                    end
                    printLogFunc(id, "guide pass error 25")
                    return
                end
            end
        elseif _cfg["event_type"..i] == 26 then
            if #DialogStack.GetStack() > 0 then
                printLogFunc(id, "guide pass error 26_1")
                return
            end
            if #DialogStack.GetPref_stact() > 0 then
                printLogFunc(id, "guide pass error 26_2")
                return
            end
        elseif _cfg["event_type"..i] == 27 then--某场战斗未完成
            if _cfg["event_id"..i] ~= 0 then
                local _battle = module.fightModule.GetFightInfo(_cfg["event_id"..i])
                if _battle then
                    local _count = 0
                    for i = 1, 3 do
                        if module.fightModule.GetOpenStar(_battle.star, i) ~= 0 then
                            _count = _count + 1
                        end
                    end
                    if _count > 0 then
                        -- local _finalFlag = rewardModule.Check(_cfg.final_id)
                        -- if _finalFlag == rewardModule.STATUS.READY then
                        --     rewardModule.Gather(_cfg.final_id)
                        -- end
                        -- printLogFunc(id, "guide pass error 27")
                        return
                    end
                end
            end
        elseif _cfg["event_type"..i] == 28 then
            if SceneStack.MapId() == _cfg["event_id"..i] then
                setUseCfg(_cfg.id)
                return
            end
        elseif _cfg["event_type"..i] == 29 then -- 某个引导完成时
            local _rewardFlag = rewardModule.Check(_cfg["event_id"..i])
            if _rewardFlag ~= rewardModule.STATUS.DONE then
                return
            end
        elseif _cfg["event_type"..i] == 30 then -- 某个引导未完成时
            local _rewardFlag = rewardModule.Check(_cfg["event_id"..i])
            if _rewardFlag == rewardModule.STATUS.DONE then
                return
            end
        elseif _cfg["event_type"..i] == 31 then --未完成某个任务(不管接没接到)
            local _id = _cfg["event_id"..i]
            local _quest = module.QuestModule.Get(_id)
            if _quest and _quest.status == 1 then
                printLogFunc(id, "guide pass error 31")
                return
            end
        end
    end
    return true
end

local GuideDialogId = nil
local function SetGuideDialogId(id)
    GuideDialogId = tonumber(id)
end

--canplay检测通过,切找到引导节点,则引导调用showmask

local waitTimeFlag = true

local GuideDialogId = nil
local function SetGuideDialogId(id)
    GuideDialogId = tonumber(id)
end

local function Play_in_queue(id, node, _cfg)
    GuideDialogId = nil;
    if not canPlay(id) then
        OperationQueueNext();
        return
    end

    if _cfg.isbegin_main == 1 then
        if dialogFlag then
            onlyOneFlag = false
            dialogFlag = false
            showFlag = id
            groupIdFlag = _cfg.group_id
            --print("zoe查看引导弹窗",id,groupIdFlag)
            local _root = UnityEngine.GameObject.FindWithTag("UGUITopRoot") or UnityEngine.GameObject.FindWithTag("UGUIGuideRoot") or UnityEngine.GameObject.FindWithTag("UGUIRootTop") or UnityEngine.GameObject.FindWithTag("UGUIRoot")
            if _root then
                local _obj = CS.SGK.UIReference.Setup(_root)
                if _obj.UIGuideRoot then
                    _root= _obj.UIGuideRoot.gameObject
                end
            end
            DialogStack.PushPref("mapSceneUI/guideLayer/guideDialog",{desc = _cfg.system_open_des,id = id,icon=_cfg.system_open_icon},_root)
            return
        end
        return
    end
    -- if type(node) == "string" then
    --     node = CS.UnityEngine.GameObject.Find(node)
    -- end
    -- if not node and _cfg.talk_order~=3 then
    --     if _cfg.showNode == "0" then
    --         if printLog then
    --             -- print(id, "guideNode not find")
    --         end
    --         OperationQueueNext();
    --         return
    --     end
    --     local _trynode = CS.UnityEngine.GameObject.Find(_cfg.showNode)
    --     if not _trynode then
    --         if printLog then
    --             -- print(id, "guideNode not find")
    --         end
    --         OperationQueueNext();
    --         return
    --     end
    -- end

    showFlag = id
    groupIdFlag = _cfg.group_id
    local _needPass = (_cfg.NeedPass == 1)
    utils.SGKTools.StopPlayerMove()
    utils.SGKTools.LockMapClick(true)
    --GuideDialogId = nil
    local delay = _cfg.sleep_time == 0 and 0.1 or _cfg.sleep_time;
    SetUseSameCfg(_cfg.group_guide)
    if _cfg.user_defined ~= "0" then
        local message = StringSplit(_cfg.user_defined,"|");
        if message[1] then
            local data = {};
            for i,v in ipairs(message) do
                if i > 1 then
                    table.insert(data, v);
                end
            end
            utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_OPT_"..message[1], data)
        end
    end
    if _cfg.story_id ~= 0 then
        if _cfg.talk_order == 1 then
            SGK.Action.DelayTime.Create(delay):OnComplete(function()
                utils.SGKTools.LockMapClick(false)
                showMask(node, id, _cfg.story_id, _needPass)
            end)
        elseif _cfg.talk_order == 3 then
            utils.SGKTools.LockMapClick(false)
            LoadGuideStory(_cfg.story_id, function()
                setUseCfg(id)
            end)
        elseif _cfg.talk_order == 4 then
            utils.SGKTools.LockMapClick(false)
            local _root = UnityEngine.GameObject.FindWithTag("UITopRoot") or UnityEngine.GameObject.FindWithTag("UGUIGuideRoot") or UnityEngine.GameObject.FindWithTag("UGUIRootTop") or UnityEngine.GameObject.FindWithTag("UGUIRoot")
            if _root then
                local _obj = CS.SGK.UIReference.Setup(_root)
                if _obj.UIGuideRoot then
                    _root = _obj.UIGuideRoot.gameObject
                end
            end
            DialogStack.PushPref("battleInstructions", {id = _cfg.story_id, des = _cfg.little_talking_des, func = function ()
                setUseCfg(id)
            end}, _root);
        else
            utils.SGKTools.LockMapClick(false)
            LoadGuideStory(_cfg.story_id, function()
                utils.SGKTools.LockMapClick(true)
                SGK.Action.DelayTime.Create(delay):OnComplete(function()
                    utils.SGKTools.LockMapClick(false)
                    showMask(node, id, nil, _needPass)
                end)
            end)
        end
    else
        SGK.Action.DelayTime.Create(delay):OnComplete(function()
            utils.SGKTools.LockMapClick(false)
            showMask(node, id, nil, _needPass)
        end)
    end
    return true
end

local function Play(id, node)
    local _cfg = GetCfg(id)
    if not canPlay(id) then
        return
    end
    -- print("播放", id)
    -- if not dialogFlag then
    --     return
    -- end
    -- if not onlyOneFlag then
    --     return
    -- end
    
    OperationQueuePush(Play_in_queue, id, node, _cfg)
end

--延迟time 执行play
local function PlayWaitTime(id, node, time)
    if canPlay(id) and waitTimeFlag then
        utils.SGKTools.LockMapClick(true)
        SGK.Action.DelayTime.Create(time or 0.5):OnComplete(function()
            utils.SGKTools.LockMapClick(false)
            Play(id, node)
            waitTimeFlag = true
        end)
       return true
    end
    return false
end

--通过类型执行 play
local function PlayByType(showType, waitTime, node)
    --print(sprinttb(GetCfg(nil, showType)))
    for i,v in ipairs(GetCfg(nil, showType) or {}) do
        if node then
            if waitTime then
                PlayWaitTime(v.id, node, tonumber(waitTime))
            else
                Play(v.id, node)
            end
        elseif v.showNode ~= "0" or v.talk_order == 4 then
            if waitTime then
                PlayWaitTime(v.id, v.showNode, tonumber(waitTime))
            else
                Play(v.id, v.showNode)
            end
        end
    end
end

local function GetFirstQuestFlag(flag)
    if flag == nil then
        return firstQuest
    else
        firstQuest = flag
    end
end

local function SetGMFlag(flag)
    utils.UserDefault.Load("GMGuide", true).close = flag
end

local QuestGuideTipStatus = nil
local SelectChapterGuide = {}
local SelectChapterDifficulty = {}

utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, data)
    --print("zoe查看断线重连引导")
    utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE",0)
end)
-- --切换场景前销毁引导
utils.EventManager.getInstance():addListener("SCENE_BEFORE_LOAD", function(event, data)
    if showFlag then
        ERROR_LOG("切换场景前销毁引导");
        RemoveGuideMask(false)
    end
end)

---切换场景重置showFlag
utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, data)
    -- groupIdFlag = true
    -- showFlag = false
    if not GuideDialogId then
        if utils.SGKTools.Athome() then
            utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE")
        end
    else
        GuideDialogFlag = true
        utils.EventManager.getInstance():dispatch("GUIDE_DIALOG_CLOUSE",{id = GuideDialogId})
    end
end)

utils.EventManager.getInstance():addListener("EQUIPMENT_INFO_CHANGE", function(event, data)
    utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE")
end)

utils.EventManager.getInstance():addListener("SHOP_INFO_CHANGE", function(event, data)
    utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE")
end)

utils.EventManager.getInstance():addListener("LOCAL_SOTRY_DIALOG_START", function(event, data)
    storyDialogFlag = true
end)

utils.EventManager.getInstance():addListener("LOCAL_SOTRY_DIALOG_CLOSE", function(event, data)
    storyDialogFlag = false
    if GuideDialogFlag then
        --print("zoe你你你你你你")
    else
        --print("zoe我我我我我我我我我我")
        utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE",0)
    end
end)

utils.EventManager.getInstance():addListener("PushPref_Load_success", function(event, data)
    utils.EventManager.getInstance():dispatch("LOCAL_GUIDE_CHANE")
end)

utils.EventManager.getInstance():addListener("KEYDOWN_ESCAPE_ONLY", function(event, data)
    if not waitTimeFlag then
        return
    end
    if not UnityEngine.Application.isEditor then
        local _guide = UnityEngine.GameObject.FindWithTag("GuideRoot")
        if _guide then
            return
        end
    end

    if type(showFlag) == "number" then
        setUseCfg(showFlag)
    end
    showFlag = false
    groupIdFlag = true;
    if not RemoveGuideMask() then
        DispatchEvent("KEYDOWN_ESCAPE")
    else
        OperationQueueNext();
    end
end)

utils.EventManager.getInstance():addListener("GUIDE_DIALOG_CLOUSE", function(event, data)
    local cfg = GetCfg(data.id)
    if cfg.story_id ~= 0 then
        LoadGuideStory(cfg.story_id, function()
            showFlag = data.id
            groupIdFlag = cfg.group_id
            setUseCfg(data.id)
        end)
     else
        showFlag = data.id
        groupIdFlag = cfg.group_id
        setUseCfg(data.id)
    end
end)

local storyFlag = {}
local function GetStoryFlag(id)
    if storyFlag[id] then
        return storyFlag[id]
    else
        return false
    end
end

local function GetOnlyOneFlag()
    return onlyOneFlag 
end

local function SetStoryFlag(id,bool)
    storyFlag[id] = bool
end
local createCharacterGuideCfg = {
    [1] = {questId = 100102, storyId = 10100201, fightId = 11010100, func = function()
        module.QuestModule.Finish(100101)
            --coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(100102)
                SceneStack.ClearBattleToggleScene()
                --SceneStack.Push("newSelectMapUp")
                utils.EventManager.getInstance():dispatch("NEW_PALYER_STORY_OVER")
                --SceneStack.EnterMap(29)
            --end))
        end},
    [2] = {questId = 100103, storyId = 101000301, func = function()
        --storyFlag = true
        --print("第二部剧情")
        module.fightModule.StartFight(11010100, false, function()
            --coroutine.resume(coroutine.create(function()
                module.QuestModule.Accept(100104)
                SceneStack.ClearBattleToggleScene()
                --SceneStack.Push("newSelectMapUp")
                --utils.EventManager.getInstance():dispatch("NEW_PALYER_STORY_OVER")
                --SceneStack.EnterMap(29)
            --end))
        end)
    end},
    [3] = {questId = 100103, storyId = 101004001, func = function()
        --coroutine.resume(coroutine.create(function()    
            module.QuestModule.Finish(100103)
            module.QuestModule.Get(100103).status = 1
            module.QuestModule.Accept(100104)
            SceneStack.ClearBattleToggleScene()
            --module.fightModule.SetNowSelectChapter({chapterId=1010, idx = 1, difficultyIdx = 1, chapterNum = 1})
            --SceneStack.Push("newSelectMapUp")
            utils.EventManager.getInstance():dispatch("NEW_PALYER_STORY_OVER")
        --end))
    end},
    -- [4] = {questId = 10004,storyId = 10000401,func = function()
    --     DialogStack.PushPref("mapSceneUI/guideLayer/createCharacter", {func = function()
    --         module.QuestModule.Finish(10004)
    --         module.QuestModule.Accept(20001)
    --         utils.SGKTools.CloseFrame()
    --     end}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    -- end},
}

local function IsGuiding()
    return type(groupIdFlag) == "number";
end

return {
    GetCfg = GetCfg,
    GetFirstLogin = GetFirstLogin,
    SetFirstLogin = SetFirstLogin,
    Play = Play,
    PlayWaitTime = PlayWaitTime,
    PlayByType = PlayByType,
    RemoveGuideMask = RemoveGuideMask,
    GetStatus = canPlay,
    ClearCacheByGroupId = ClearCacheByGroupId,
    GetFirstQuestFlag = GetFirstQuestFlag,
    SetGMFlag = SetGMFlag,
    QuestGuideTipStatus = QuestGuideTipStatus,
    SelectChapterGuide = SelectChapterGuide,
    SelectChapterDifficulty = SelectChapterDifficulty,
    CreateCharacterGuideCfg = createCharacterGuideCfg,
    SetGuideDialogId = SetGuideDialogId,

    GetStoryFlag = GetStoryFlag,
    SetStoryFlag = SetStoryFlag,
    GetOnlyOneFlag = GetOnlyOneFlag,
    IsGuiding = IsGuiding
}
