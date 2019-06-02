
--[[
local c_schedule = CS.SGK.CoroutineService.Schedule;

local repeat_schedule_list = {};
local onece_schedule_list = {};
local schedule_tick = 0;
local schedule_pass = 0;
local profiler = require "perf.profiler"

c_schedule(function()
    profiler.start();

    for _, v in ipairs(repeat_schedule_list) do
        ASSERT(pcall(v));
    end

    schedule_pass = schedule_pass + UnityEngine.Time.deltaTime;

    local current_tick = math.floor(schedule_pass * 30);
    for i = schedule_tick + 1, current_tick do
        if onece_schedule_list[i] then
            for _, v  in ipairs(onece_schedule_list[i]) do
                ASSERT(pcall(v));
            end
            onece_schedule_list[i] = nil;
        end
    end
    schedule_tick = current_tick;

    if tonumber(profiler.time()) > 24 then
       print("c_schedule cost " .. profiler.time() .. "ms\n" .. profiler.report('TOTAL'));
    end
    profiler.stop();
end)

rawset(CS.SGK.CoroutineService, "Schedule", function(func)
    table.insert(repeat_schedule_list, func);
end)

rawset(CS.SGK.CoroutineService, "ScheduleOnce", function(func, delay)
    local tick = math.floor(delay * 30)
    if tick <= 0 then
        tick = 1;
    end

    tick = tick + schedule_tick;

    onece_schedule_list[tick] = onece_schedule_list[tick] or {}
    table.insert(onece_schedule_list[tick], func);
end)
--]]

function isNil(str)
    if not str or str == "" or str == "0" or str == 0 then
        return true;
    end

    return false; 
end

CS.UnityEngine.Application.targetFrameRate = 30;

if not CS.UnityEngine.Application.isEditor then
    print = function() end;
end

collectgarbage = function() end

local EventManager = require 'utils.EventManager';
function RegisterEventListener(script)
    if script.listEvent and script.onEvent then
        script.__event_listener_callback = script.__event_listener_callback or function(...)
            script:onEvent(...);
        end

        script.__event_listener_list = script.__event_listener_list or {};

        for _, event in ipairs(script:listEvent()) do
            if not script.__event_listener_list[event] then
                script.__event_listener_list[event] = true;
                -- print('RegisterEventListener', script, event);
                EventManager.getInstance():addListener(event, script.__event_listener_callback);
            end
        end
    end
end

function DispatchEvent(event, ...)
	-- print('DispatchEvent', event, ...);
    EventManager.getInstance():dispatch(event, ...)
end

function RemoveEventListener(script)
    if script.listEvent and script.__event_listener_callback and script.__event_listener_list then
        for event, _ in pairs(script.__event_listener_list) do
            -- print('RemoveEventListener', script, event);
            EventManager.getInstance():removeListener(event, script.__event_listener_callback);
        end
        script.__event_listener_list = {}
    end
end

ASSERT = ASSERT or function(success, ...)
    if not success then
        ERROR_LOG(...)
    end
    return success, ...
end

-- [[
local _coroutine_resume = coroutine.resume;
coroutine.resume = function(...)
    return ASSERT(_coroutine_resume(...))
end
--]]

if CS.UnityEngine.Application.isEditor and false then
    local ResourcesManager_Load = CS.SGK.ResourcesManager.Load;
    rawset(CS.SGK.ResourcesManager, "Load", function(...)
        local fileName = select(1, ...)
        WARNING_LOG("ResourcesManager.Load", fileName, debug.traceback())
        return ResourcesManager_Load(...);
    end)
end

--format 1: xx小时xx分xx秒
--format 2: 00:00:00
function GetTimeFormat(time,format,lenth)
    lenth = lenth or 3;
    local time_str = "";
    local day,hour,min,sec = 0,0,0,0;
    if format == 1 then     
        if time < 60 then
            sec = time;
        elseif time < 3600 then
            min = math.floor(time/60);
            sec = time%60;
        elseif time < 86400  then
            hour = math.floor(time/3600);
            min = math.floor((time%3600)/60);
        else
            day = math.floor(time/86400);
            hour = math.floor((time%86400)/3600);
            min = math.floor((time%3600)/60);
        end
        time_str = (day ~= 0 and (day.."天") or "")..(hour ~= 0 and (hour.."小时") or "")..(min ~= 0 and (min.."分") or "")..(sec ~= 0 and (sec.."秒") or "");
    elseif format == 2 then
        if lenth == 1 then
            sec = time;
            time_str = string.format("%02d",sec);
        elseif lenth == 2 then
            min = math.floor(time/60);
            sec = time%60;
            time_str = string.format("%02d"..":".."%02d",min,sec);
        elseif lenth == 3 then
            hour = math.floor(time/3600);
            min = math.floor((time%3600)/60);
            sec = time%60;
            time_str = string.format("%02d"..":".."%02d"..":".."%02d",hour,min,sec);
        end
    end
    return time_str;
end

function CheckActiveTime(cfg)
    if cfg.begin_time <= module.Time.now() and cfg.end_time > module.Time.now() then
		local delta = module.Time.now() - cfg.begin_time;
		if delta % cfg.period < cfg.duration then
			return true;
		end
	end	
	return false;
end

function SetButtonStatus(status, button, material, canClick)
    if button[CS.UGUIClickEventListener] == nil then
        return;
    end
    if button[CS.UGUIClickEventListener].interactable == status then
        return;
    end
    if button[CS.UGUISelectorGroup] then
        if status then
            button[CS.UGUISelectorGroup]:reset();
        else
            button[CS.UGUISelectorGroup]:setGray();
        end
    else
        if button[CS.UnityEngine.UI.Image] then
            if status then
                button[CS.UnityEngine.UI.Image].material = nil;
            elseif material ~= nil then
                button[CS.UnityEngine.UI.Image].material = material;
            end
        end
    end
    button[CS.UGUIClickEventListener].disableTween = not status;
    if canClick ~= nil then
        button[CS.UGUIClickEventListener].interactable = canClick;
    else
        button[CS.UGUIClickEventListener].interactable = status;
    end
end

function showPropertyChange(prop_name,delta,hero_name,time,space)
    time = time or 2
    space = space or 0.18
    hero_name = hero_name or ""
    local NGUIRoot = UnityEngine.GameObject.FindWithTag("UGUITopRoot")
    if NGUIRoot == nil then
        return;
    end
    local newprefabs = SGK.ResourcesManager.Load("prefabs/base/newCapacityTip.prefab")
    for i=1,#prop_name do
        if delta[i] ~= 0 then
            local delay = space * (i - 1);
            local obj = CS.UnityEngine.GameObject.Instantiate(newprefabs, NGUIRoot.gameObject.transform)
            if prop_name[i] == "战力" then
                -- local item = CS.SGK.UIReference.Setup(obj);
                -- if delta[i] > 0 then
                --     item.Text[UnityEngine.UI.Text]:TextFormat("+{0}", math.floor(delta[i]));
                -- else
                --     item.Text[UnityEngine.UI.Text]:TextFormat("{0}", math.floor(delta[i]));
                -- end
                -- item[UnityEngine.CanvasGroup]:DOFade(1,0.1):SetDelay(delay):OnComplete(function ( ... )
                --     item[UnityEngine.CanvasGroup]:DOFade(0, time):SetDelay(0.5);
                --     obj.transform:DOLocalMove(Vector3(0,250,0), time):OnComplete(function ( ... )
                --         CS.UnityEngine.GameObject.Destroy(obj);
                --     end);
                -- end)
            else
                local label = obj.transform:Find("Text"):GetComponent(typeof(UnityEngine.UI.Text));
                if delta[i] > 0 then
                    label:TextFormat("{0} {1}提升 +{2}", hero_name, prop_name[i], math.floor(delta[i]));
                else
                    label:TextFormat("{0} {1}下降 {2}", hero_name, prop_name[i], math.floor(delta[i]));
                end
                
                label:DOFade(1,0.1):SetDelay(delay):OnComplete(function ( ... )
                    label:DOFade(0, time):SetDelay(0.5);
                    obj.transform:DOLocalMove(Vector3(0,250,0), time):OnComplete(function ( ... )
                        CS.UnityEngine.GameObject.Destroy(obj);
                    end);
                end)
            end
        end
    end
end

function showCapacityChange(from,to)
    DispatchEvent("showCapacityChange", {from, to});
end

function TeamStory(storyid)
    module.TeamModule.SyncTeamData(103, storyid)--向队员发送剧情id
end
function TeamQuestModuleAccept(id)
    module.TeamModule.SyncTeamData(104, id)--向队员发送接任务id
end
function TeamQuestModuleSubmit(id)
    module.TeamModule.SyncTeamData(105, id)--向队员发送交任务id
end
function PlayerEnterMap(...)
    DispatchEvent("PlayerEnterMap",...)
end
function LoadMapName(id)
    local tempObj = SGK.ResourcesManager.Load("prefabs/base/MapName.prefab")
    local MapNameObj = GetUIParent(tempObj)
    local MapNameView = CS.SGK.UIReference.Setup(MapNameObj)
    local MapConfig = require "config.MapConfig"
    local mapCfg = MapConfig.GetMapConf(id);
    if not mapCfg then
        ERROR_LOG("mapid->"..id.."->nil\n"..debug.traceback())
        return
    end
    MapNameView.bg.title[UnityEngine.UI.Text].text = mapCfg.title
    MapNameView.bg.name[UnityEngine.UI.Text].text = mapCfg.map_name
    MapNameView.bg.title[UnityEngine.CanvasGroup]:DOFade(1, 0.5)
    MapNameView.bg.title.transform:DOLocalMove(Vector3(-100,25,0),0.5):OnComplete(function ( ... )
        MapNameView.bg.title[UnityEngine.CanvasGroup]:DOFade(0, 0.5):SetDelay(1)
        MapNameView.bg.title.transform:DOLocalMove(Vector3(100,25,0),0.5):OnComplete(function ( ... )

        end):SetDelay(1)
    end)--:SetEase(CS.DG.Tweening.Ease.InQuad)
    ---------------------------------------------------------------------------------------------------
    MapNameView.bg.name[UnityEngine.CanvasGroup]:DOFade(1, 0.5)
    MapNameView.bg.name.transform:DOLocalMove(Vector3(78,-25,0),0.5):OnComplete(function ( ... )
        MapNameView.bg.name[UnityEngine.CanvasGroup]:DOFade(0, 0.5):SetDelay(1)
        MapNameView.bg.name.transform:DOLocalMove(Vector3(-200,-25,0),0.5):OnComplete(function ( ... )
            CS.UnityEngine.GameObject.Destroy(MapNameObj);
        end):SetDelay(1)
    end)
end

require "utils.NPCOperation"

function StringSplit(szFullString, szSeparator)
    if not szFullString then
        return {};
    end
    local nFindStartIndex = 1 
    local nSplitIndex = 1 
    local nSplitArray = {} 
    while true do 
       local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex) 
       if not nFindLastIndex then 
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString)) 
        break 
       end 
       nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1) 
       nFindStartIndex = nFindLastIndex + string.len(szSeparator) 
       nSplitIndex = nSplitIndex + 1 
    end 
    return nSplitArray 
end

function GetUIParent(tempObj,parent)
    local obj = nil
    if parent then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,parent.gameObject.transform)
    elseif UnityEngine.GameObject.FindWithTag("UITopRoot") then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj, UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject.transform)
    elseif UnityEngine.GameObject.FindWithTag("UGUITopRoot") then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUITopRoot").gameObject.transform)
    elseif UnityEngine.GameObject.FindWithTag("UGUIRoot") then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
    else
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
    end
    return obj
end
function DlgMsg(data)
    DispatchEvent("showDlgMsg",data)
end
function showDlgMsg(msg, confirm, cancel, txtConfirm, txtCancel, time, confirmInfo,title)
    DispatchEvent("showDlgMsg", {msg = msg, confirm = confirm, cancel = cancel, txtConfirm = txtConfirm, txtCancel = txtCancel, time = time, confirmInfo = confirmInfo,title =title})
end

function showDlg(parent,msg,confirm,cancel,txtConfirm,txtCancel,layer)
    DispatchEvent("showDlgMsg", {msg = msg, confirm = confirm, cancel = cancel, txtConfirm = txtConfirm, txtCancel = txtCancel})
end

function showDlgError(parent,msg,type)
    DispatchEvent("showDlgError",{parent,msg,type})
end

function ShowChatWarning(msg)
    local tempObj = SGK.ResourcesManager.Load("prefabs/base/ChatWarning.prefab")
    local obj = nil;
    --DlgErrornum = DlgErrornum == 6 and 0 or DlgErrornum + 1 
    local NGUIRoot = UnityEngine.GameObject.FindWithTag("UGUIRoot")
    if NGUIRoot then
         obj = CS.UnityEngine.GameObject.Instantiate(tempObj, NGUIRoot.gameObject.transform)
    elseif UnityEngine.GameObject.FindWithTag("NGUIRoot") then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("NGUIRoot").gameObject.transform)
    else
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
    end
    local ErrorView = CS.SGK.UIReference.Setup(obj)
    ErrorView.desc[UnityEngine.UI.Text].text = msg
    --obj.transform:DOScale(Vector3(1,1,1),0.25):SetEase(CS.DG.Tweening.Ease.OutBounce):OnComplete(function( ... )
        obj:GetComponent("CanvasGroup"):DOFade(0,1):SetDelay(1):OnComplete(function( ... )
            CS.UnityEngine.GameObject.Destroy(obj)
        end)
    --end)
end

function loadRollingSubtitles(id,fun)
    local tempObj = SGK.ResourcesManager.Load("prefabs/base/RollingSubtitles.prefab")
    local RollingSubtitles = GetUIParent(tempObj)
    local RollingSubtitlesView = CS.SGK.UIReference.Setup(RollingSubtitles)
    local StoryConfig = require "config.StoryConfig"
    RollingSubtitlesView.mask.desc[CS.InlineText].text = StoryConfig.GetStoryConf(id).dialog
    RollingSubtitlesView.mask.desc.transform:DOScale(Vector3(1,1,1),0.1):OnComplete(function ( ... )
        local y = RollingSubtitlesView.mask.desc[UnityEngine.RectTransform].sizeDelta.y + 250
        RollingSubtitlesView.mask.desc.transform:DOLocalMove(Vector3(0,y,0), RollingSubtitlesView.mask.desc[UnityEngine.RectTransform].sizeDelta.y/22):OnComplete(function ( ... )
            CS.UnityEngine.GameObject.Destroy(RollingSubtitles)
            if fun then
                fun()
            end
        end)
    end)
    RollingSubtitlesView.skipBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        CS.UnityEngine.GameObject.Destroy(RollingSubtitles)
        if fun then
            fun()
        end
    end
end
-- local StoryFrame = nil
-- function DeleteStory()
--     StoryFrame = nil
-- end
function LoadGuideStory(...)
    local StoryConfig = require "config.StoryConfig";
    return StoryConfig.ShowStory(...);
end

function LoadStory(...)
    LoadGuideStory(...)
end

local StoryOptionsData = {}
local StoryOptionsDataList = {}
function SetStoryOptions(data,state,id)
    for i = 1,#data do
         if id then
            if not StoryOptionsDataList[id] then
                StoryOptionsDataList[id] = {}
            end
            StoryOptionsDataList[id][#StoryOptionsDataList[id]+1] = data[i]
        else
            StoryOptionsData[#StoryOptionsData + 1] = data[i]
        end
    end
    if state then
        StoryOptions(data)
    end
end
function LoadStoryOptions(id)
    if id then
        StoryOptions(StoryOptionsDataList[id])
        StoryOptionsDataList[id] = {}
    else
        StoryOptions(StoryOptionsData)
        StoryOptionsData = {}
    end
end
local StoryOptionsObj = nil
local StoryOptionsView = {}
function StoryOptions(data)
    -- local StoryOptionsData = {}
    -- if data.Groups ~= nil then
    --     print(sprinttb(data.Groups))
    --     StoryOptionsData = data.Groups
    -- elseif data.path ~= nil then
    --    StoryOptionsData = dofile(UnityEngine.Application.dataPath.."/lua/"..data.path)
    -- end
    --print("菜单",sprinttb(data))
    local StoryFrame = DialogStack.GetPref_list("StoryFrame")
    if not StoryFrame or not StoryFrame.gameObject then
        --print("雾剧情........")
        -- local _p = UnityEngine.GameObject.FindWithTag("UGUIGuideRoot") or UnityEngine.GameObject.FindWithTag("UGUIRootTop")
        -- DialogStack.PushPref("StoryFrame",nil, _p)
        -- return
    else
        if not StoryFrame.gameObject then
            return
        end
        if not StoryFrame.gameObject.activeInHierarchy then
            return
        end
    end
    if #data == 0 then
        return
    end
    if StoryOptionsObj == nil then
        local tempObj = SGK.ResourcesManager.Load("prefabs/base/StoryOptionsFrame.prefab")
        StoryOptionsObj = GetUIParent(tempObj)
    end
    local StoryView = CS.SGK.UIReference.Setup(StoryOptionsObj)
    local TempData = data and data or StoryOptionsData
    --print("菜单2222",sprinttb(TempData))
    local lock = false
    for i = 1,#TempData do
        if TempData[i].childAlignment then
            StoryView.border.options[UI.GridLayoutGroup].childAlignment = UnityEngine.TextAnchor.LowerCenter
        else
            --StoryView.border.options[UI.GridLayoutGroup].childAlignment = UnityEngine.TextAnchor.LowerRight
        end
        if TempData[i].lock then
            lock = true
        end
        local coverage = false
        for j = 1,#StoryOptionsView do
            if StoryOptionsView[j].name[UI.Text].text == TempData[i].name then
                coverage = true
                break
            end
        end
        if coverage then
            break
        end
        local descObj = CS.UnityEngine.GameObject.Instantiate(StoryView.border.options[1].gameObject, StoryView.border.options.gameObject.transform)
        local descView = CS.SGK.UIReference.Setup(descObj)
        StoryOptionsView[#StoryOptionsView+1] = descView
        if TempData[i].guideName then
            descObj.name = TempData[i].guideName
        end
        descView:SetActive(true)
        descView.name[UnityEngine.UI.Text].text = TempData[i].name
        if TempData[i].effect then
            --ERROR_LOG(TempData[i].effect)
            local effect = SGK.ResourcesManager.Load("prefabs/"..TempData[i].effect .. ".prefab")
            if effect then
                GetUIParent(effect,descView.transform)
            else
                ERROR_LOG("prefabs/"..TempData[i].effect.."不存在")
            end
        end
        descView[CS.UGUIClickEventListener].onClick = function ( ... )
            if TempData[i].action then
                ASSERT(coroutine.resume(coroutine.create(TempData[i].action)));
                --DispatchEvent("KEYDOWN_ESCAPE")
            end
            TempData[i].action = nil
            --StoryOptionsData = {}
            CS.UnityEngine.GameObject.Destroy(StoryOptionsObj)
            StoryOptionsObj = nil
            StoryOptionsView = {}
        end
        if TempData[i].icon then
            descView.icon[UnityEngine.UI.Image]:LoadSprite("Story/"..TempData[i].icon,function ( ... )
                descView.icon[UnityEngine.UI.Image]:SetNativeSize();
            end)
            descView.icon:SetActive(true)
        else
            descView.icon:SetActive(false)
        end
        if TempData[i].size and #TempData[i].size > 2 then
            descView.icon[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(TempData[i].size[1],TempData[i].size[2])
        end
        if descView.icon.activeSelf then
            descView.name[UnityEngine.RectTransform].localPosition = Vector3(descView.icon[UnityEngine.RectTransform].sizeDelta.x/2,0,0)
        end
        if TempData[i].auto then
            StoryOptionsObj.gameObject.transform:DOScale(Vector3(1,1,1),0.5):OnComplete(function()
                if TempData[1].action then
                    ASSERT(coroutine.resume(coroutine.create(TempData[1].action)));
                end
                TempData[1].action = nil
                --StoryOptionsData = {}
                CS.UnityEngine.GameObject.Destroy(StoryOptionsObj)
                StoryOptionsObj = nil
                StoryOptionsView = {}
            end)--:SetDelay(0)
        end
    end
    module.guideModule.PlayByType(30, 0.5)
    local count = StoryView.border.options.transform.childCount - 1
    --StoryView.border[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(278.4,62 + count*55)
    StoryView.mask[CS.UGUIClickEventListener].onClick = function ( ... )
        if not lock then
            --StoryOptionsData = {}
            CS.UnityEngine.GameObject.Destroy(StoryOptionsObj)
            StoryOptionsObj = nil
            StoryOptionsView = {}
            DispatchEvent("CloseStoryReset")
            --DialogStack:Pop();
        end
    end
    StoryView.resetBtn[CS.UGUIPointerEventListener].onPointerDown = function ( ... )
        DispatchEvent("StoryFrameRecall",0.1)
    end
    StoryView.resetBtn[CS.UGUIPointerEventListener].onPointerUp = function ( ... )
        DispatchEvent("StoryFrameRecall")
    end
    local StoryFrame = DialogStack.GetPref_list("StoryFrame")
    if StoryFrame and StoryFrame.gameObject and StoryFrame.gameObject.activeSelf then
        StoryView.bottom:SetActive(true)
    else
        StoryView.bottom:SetActive(false)
    end
end
function DeleteStoryOptions()
    CS.UnityEngine.GameObject.Destroy(StoryOptionsObj)
    StoryOptionsObj = nil
    StoryOptionsView = {}
    DispatchEvent("CloseStoryReset")
    --DialogStack:Pop();
end

local AssociatedLuaScriptRecord = {}

function AssociatedLuaScript(path,...)
    if AssociatedLuaScriptRecord[path] == nil then
        AssociatedLuaScriptRecord[path] = loadfile(path,"bt", _G) or function() end;
    end

    return AssociatedLuaScriptRecord[path](...);

--[[
    ERROR_LOG("AssociatedLuaScript", path, debug.traceback())
    local s = loadfile(path,"bt", _G)(...)
    if s == nil then
        s = true
    end

    return s
--]]
end

function PlayerTips(data)
    local tempObj = SGK.ResourcesManager.Load("prefabs/base/FriendTips.prefab")
    --local NGUIRoot = UnityEngine.GameObject.FindWithTag("UGUIRoot");
    local NetworkService = require "utils.NetworkService";
    local unionModule = require "module.unionModule"
    local playerModule = require "module.playerModule"
    local obj = nil;
    --if NGUIRoot then
         obj = GetUIParent(tempObj)
    -- else
    --     return
    -- end
    if data and data.name and data.level and data.pid then
        local TipsView = CS.SGK.UIReference.Setup(obj)

        TipsView.Root.name[UnityEngine.UI.Text].text = data.name..""
        playerModule.GetCombat(data.pid,function ( ... )
            TipsView.Root.combat[UnityEngine.UI.Text].text = "战力:<color=#FEBA00>"..tostring(math.ceil(playerModule.GetFightData(data.pid).capacity)).."</color>"
        end)
        local unionName = unionModule.GetPlayerUnioInfo(data.pid).unionName
        if unionName then
            TipsView.Root.guild[UnityEngine.UI.Text]:TextFormat("公会:{0}", unionName);
        else
            unionModule.queryPlayerUnioInfo(data.pid,(function ( ... )
                unionName = unionModule.GetPlayerUnioInfo(data.pid).unionName or "无"
                TipsView.Root.guild[UnityEngine.UI.Text]:TextFormat("公会:", unionName);
            end))
        end
        local objClone = nil
        if TipsView.Root.hero.transform.childCount == 0 then
            local tempObj = SGK.ResourcesManager.Load("prefabs/base/newCharacterIcon.prefab")
            objClone = CS.UnityEngine.GameObject.Instantiate(tempObj,TipsView.Root.hero.transform)
            objClone.transform.localPosition = Vector3.zero
        else
            objClone = TipsView.Root.hero.transform:GetChild(0)
        end
        local PLayerIcon = SGK.UIReference.Setup(objClone)
        if playerModule.IsDataExist(data.pid) then
            local head = playerModule.IsDataExist(data.pid).head ~= 0 and playerModule.IsDataExist(data.pid).head or 11001
            --TipsView.obj.hero.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
            PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = head,level = playerModule.IsDataExist(data.pid).level,name = "",vip=0},true)
        else
            playerModule.Get(data.pid,(function( ... )
                local head = playerModule.IsDataExist(data.pid).head ~= 0 and playerModule.IsDataExist(data.pid).head or 11001
               --TipsView.obj.hero.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
               PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = head,level = playerModule.IsDataExist(data.pid).level,name = "",vip=0},true)
            end))
        end
        TipsView.Root.Btn1[CS.UGUIClickEventListener].onClick = (function ( ... )
            --加好友
            NetworkService.Send(5013,{nil,1,data.pid})--添加好友
            CS.UnityEngine.GameObject.Destroy(obj)
        end)

        TipsView.Root.Btn2[CS.UGUIClickEventListener].onClick = (function ( ... )
            --邀请入团
            if module.unionModule.Manage:GetUionId() == 0 then
                showDlgError(nil, "您还没有公会")
            elseif module.unionModule.GetPlayerUnioInfo(data.pid).unionId ~= nil and module.unionModule.GetPlayerUnioInfo(data.pid).unionId ~= 0 then
                showDlgError(nil, "该玩家已有公会")
            else
                module.unionModule.Invite(data.pid)
            end
            CS.UnityEngine.GameObject.Destroy(obj)
        end)

        TipsView.Root.Btn3[CS.UGUIClickEventListener].onClick = (function ( ... )
            --拉黑
            NetworkService.Send(5013,{nil,2,data.pid})
            CS.UnityEngine.GameObject.Destroy(obj)
        end)
       
        TipsView.Root.Btn4[CS.UGUIClickEventListener].onClick = (function ( ... )
            --邀请入队
            local teamInfo = module.TeamModule.GetTeamInfo();
            if teamInfo.group ~= 0 then
                module.TeamModule.Invite(data.pid)
            else
                showDlgError(nil,"请先创建一个队伍")
            end
        end)
        TipsView.mask[CS.UGUIClickEventListener].onClick = (function ( ... )
            CS.UnityEngine.GameObject.Destroy(obj)
        end)
    end
end

-- 打印表的格式的方法
local function _sprinttb(tb, tabspace)
    tabspace =tabspace or ''
    local str =string.format(tabspace .. '{\n' )
    for k,v in pairs(tb or {}) do
        if type(v)=='table' then
            if type(k)=='string' then
                str =str .. string.format("%s%s =\n", tabspace..'  ', k)
                str =str .. _sprinttb(v, tabspace..'  ')
            elseif type(k)=='number' then
                str =str .. string.format("%s[%d] =\n", tabspace..'  ', k)
                str =str .. _sprinttb(v, tabspace..'  ')
            end
        else
            if type(k)=='string' then
                str =str .. string.format("%s%s = %s,\n", tabspace..'  ', tostring(k), tostring(v))
            elseif type(k)=='number' then
                str =str .. string.format("%s[%s] = %s,\n", tabspace..'  ', tostring(k), tostring(v))
            end
        end
    end
    str =str .. string.format(tabspace .. '},\n' )
    return str
end

function sprinttb(tb, tabspace)
    if CS.UnityEngine.Application.isEditor then
        local function ss()
            return _sprinttb(tb, tabspace);
        end
        return setmetatable({}, {
            __concat = ss,
            __tostring = ss,
        });
    else
        return "";
    end
end

function BIT(toNum)
    local tmp = {}
    while toNum > 0 do
        tmp[#tmp+1] = toNum % 2 ;
        toNum = math.floor(toNum / 2);
    end
    return tmp;
end

local ui_reference_metatable = {
    __index = function(t, k)
        if type(k) == "table" and typeof(k) and t.gameObject then
            return t.gameObject:GetComponent(typeof(k));
        else
            local value = t.gameObject[k];
            if type(value) == "function" then
                return function(c, ...)
                    return value( (c == t) and t.gameObject or c, ...)
                end
            else
                return value;
            end
        end
    end,
    __newindex = function(t, k, v)
        local value = t.gameObject[k];
        if value and type(value) ~= "function" then
            t.gameObject = v;
        else
            rawset(t, k, v);
        end
    end
}
local Type_CS_SGK_UIReference = typeof(CS.SGK.UIReference);

local function __get_ref(t)
    local ref = rawget(t, "UIReference");
    if ref == nil then
        ref = t.gameObject:GetComponent(Type_CS_SGK_UIReference);
        rawset(t, "UIReference", ref or false);
    end
    return ref and ref or nil;
end

local function SetupViewByUIReference(root)
    if root == nil then
        return nil
    end

    return setmetatable({gameObject = root}, {__len = function(t)
        local ref = __get_ref(t); 
		return ref and ref.refs.Length or 0;
	end, __index = function(t, k)
        if type(k) == "table" and typeof(k) and t.gameObject then -- GetComponent
            return t.gameObject:GetComponent(typeof(k));
        end

        local ref = __get_ref(t); 

        local child = ref and ref:Get(k);
        if child then
            local childRef = SetupViewByUIReference(child);
            rawset(t, k, childRef);
            return childRef;
        end

        local value = t.gameObject[k];

        if type(value) == "function" then
            return function(c, ...)
                return value( (c == t) and t.gameObject or c, ...)
            end
        else
            return value;
        end
    end, __newindex = function(t, k, v)
        local value = t.gameObject[k];
        if value and type(value) ~= "function" then
            t.gameObject[k] = v;
        else
            rawset(t, k, v);
        end
    end})
end

--中文占2个字符 英文占1个字符
--取出中文字符个数
--总个数加上中文个数
function GetUtf8Len(Str)
    local uc = 0
    for uchar in string.gmatch(Str, "[\\0-\127\194-\244][\128-\191]*") do
        if #uchar ~= 1 then
            uc = uc + 1
        end
    end
    local len  = string.len(Str)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(Str, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt + uc
end


-- 5.3 
unpack = unpack or table.unpack

-- Spine
Spine = CS.Spine

-- UnityEngine
UnityEngine = CS.UnityEngine;
Vector3 = CS.UnityEngine.Vector3
Quaternion = UnityEngine.Quaternion
UI = CS.UnityEngine.UI

-- SGK
SGK = CS.SGK

require "utils.Sync"
SyncLoad = SGK.ResourcesManager.Load;
-- [[
SGK.ResourcesManager.Load = function ( ... )
    if ... == "prefabs/effect/UI/fx_woring_ui.prefab" then
        ERROR_LOG(..., debug.traceback());
    end


    local co = coroutine.running();

    if not co or not coroutine.isyieldable() then
        -- print("LoadAsset:", ...)
        return SyncLoad(...);
    end

    local p = {...};
    local n = false;
    local ret = nil;


    table.insert(p, function (obj)
        ret = obj;
        if n then
            coroutine.resume(co);
        end
        n = true;
    end)
    
    SGK.ResourcesManager.LoadAsync(unpack(p))
    if not n then
        n = true;
        coroutine.yield();
    end
    return ret;
end
-- ]]

require "utils.LuaBehaviourHelper"

DATABASE = require "utils.ConfigReader";
DATABASE.GetBattlefieldCharacterTransform = SGK.Database.GetBattlefieldCharacterTransform;

local mt = getmetatable(CS.UGUIClickEventListener);
local index = mt.__index;
local nindex = mt.__newindex;
local call = mt.__call;
setmetatable(CS.UGUIClickEventListener, {__index = index,
__newindex = function (t, k, v)
    if k == "onClick" then
        v = function ( ... )
            Sync(v);
        end
    end
    nindex(t, k, v);
end,
__call = call})

function LoadDatabaseWithKey(name, field)
    local data_list = {};
    DATABASE.ForEach(name, function(row, idx)
        local mainkey;
        if field then
            mainkey = row[field];
        else
            mainkey = i;
        end

        if mainkey ~= nil then
            data_list[mainkey] = row;
        end
    end);
    return data_list;
end

local language = {
    [1] = "Chinese",
    [2] = "English",
}
SGK.Localize:getInstance().language = language[1]
DATABASE.ForEach("language", function(row, idx)
    for i,v in ipairs(language) do
        SGK.Localize:getInstance():addCfg(row.key, v, row[v])
    end
end)

rawset(SGK.UIReference, "Setup", function(tag)
    local v;
    if tag == nil or type(tag) == "string" then
        v = SetupViewByUIReference(UnityEngine.GameObject.FindWithTag(tag or "ui_reference_root") );
    else
        v = SetupViewByUIReference(tag)
    end
    return v;    
end);

rawset(SGK.UIReference, "Instantiate", function(prefab, ...)
    return SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab.gameObject or prefab, ...));
end)

if CS.UnityEngine.UI.Image.LoadSpriteWithExt == nil then
    rawset(CS.UnityEngine.UI.Image, "LoadSpriteWithExt", function(image, ...)
        image:LoadSprite(...)
    end)
end

-- coroutine
StartCoroutine = function(func, ...) 
	local success, info = coroutine.resume(coroutine.create(func), ...);
	if not success then
		ERROR_LOG(info)
	end
end

local util = require "xlua.util"
Yield = util.async_to_sync(function(to_yield, cb)
	SGK.CoroutineService.YieldAndCallback(to_yield, cb);
end);

function WaitForEndOfFrame()
	Yield(UnityEngine.WaitForEndOfFrame());
end

function WaitForSeconds(n)
    Yield(UnityEngine.WaitForSeconds(n));
end

function HTTPRequest(url, postData, header)
    local www
    if postData then
        local form = UnityEngine.WWWForm();

        for k, v in pairs(postData) do
            form:AddField(k, v);
        end

        www = UnityEngine.WWW(url, form.data, header or {})
    else
        www = UnityEngine.WWW(url, nil, header or {})
    end

    Yield(www)

    return www.bytes, www.error
end

function Sleep(n, dont_check_scene)
	local co = coroutine.running();
	if co == nil or not coroutine.isyieldable() then
		assert(false, "can't sleep in main thread");
        return;
	end

	local scene_index = SceneService.sceneIndex;

    CS.SGK.CoroutineService.ScheduleOnce(function()
		ASSERT(coroutine.resume(co))
	end, n or 0)

	coroutine.yield();

	if not dont_check_scene and scene_index ~= SceneService.sceneIndex then
		error('scene changed, stop sleeping thread');
	end
end

utils = setmetatable({}, {__index=function(t, k)
    return require ("utils." .. k);
end})

module = setmetatable({}, {__index=function(t, k)
    return require ("module." .. k);
end})

-- require "utils.network";
SceneStack = require "utils.SceneStack"
DialogStack = require "utils.DialogStack"
ModuleMgr = require "module.ModuleMgr"
ClientCmder = require "module.Cmd.ClientCmder"

ThreadEvalWithGameObject = function(fileName, chunkName, behaviour, ...)
    local func = loadfile(fileName, 'bt', setmetatable({
        this = behaviour,
    }, {__index=_G}));
    utils.Thread.Eval(func, ...)
end

ThreadEval = function(fileName, chunkName, ...)
    local func = loadfile(fileName, chunkName);
    utils.Thread.Eval(func, ...)
end

require "network"
require "utils.class"
local protobuf = require "protobuf"
protobuf.register(SGK.ResourcesManager.Load("proto.pb.bytes").bytes)
function ProtobufEncode(msg, protocol)
    return protobuf.encode(protocol, msg);
end

function ProtobufDecode(code, protocol)
    return protobuf.decode(protocol, code);
end

function get_source_line(f)
    local t = debug.getinfo(f)
    if t then
        return t.short_src .. ":" .. t.linedefined;
    end
end

ItemIconPool = CS.GameObjectPool.GetPool("ItemIcon");

require "WordFilter"
WordFilter.init(SGK.ResourcesManager.Load("Word.txt").text);

require "utils.TipManager"
require "utils.TitleHelper"
local WELLRNG512a_ = require "WELLRNG512a"
function WELLRNG512a(seed)
    local rng = WELLRNG512a_.new(seed);
    return setmetatable({rng=rng}, {__call=function(t)
        return WELLRNG512a_.value(t.rng);
    end})
end

setmetatable(_G, {__index=function(t, k)
    ERROR_LOG("GLOBAL NAME", k, "NOT EXISTS", debug.traceback())
end, __newindex = function(t, k, v)
    ERROR_LOG("SET GLOBAL NAME", k, v, debug.traceback())
    rawset(t, k, v);
end})

require "module.init"

SceneStack.Start("login_scene2", "view/login_scene2.lua");
