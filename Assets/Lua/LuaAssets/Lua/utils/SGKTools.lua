local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local battleCfg = require "config.battle"
local skill = require "config.skill"
local ActivityTeamlist = require "config.activityConfig"

local openLevel = require "config.openLevel"
local SGKTools = {}
local LockMapObj = nil
local LockMapObj_count = 0;
function SGKTools.LockMapClick(status,time)
    LockMapObj_count = LockMapObj_count + (status and 1 or -1);
    if LockMapObj_count < 0 then
        WARNING_LOG("SGKTools.LockMapClick count < 0", debug.traceback())
        LockMapObj_count = 0;
    end

    if LockMapObj_count > 0 then
        if LockMapObj == nil then
            LockMapObj = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/LockFrame.prefab"))
        end
        LockMapObj:SetActive(true)
        module.MapModule.SetMapIsLock(true)
    elseif LockMapObj_count == 0 then
        if LockMapObj then
            LockMapObj:SetActive(false)
        end
        module.MapModule.SetMapIsLock(false)
    end

    if status and time then
        SGK.Action.DelayTime.Create(time):OnComplete(function()
            SGKTools.LockMapClick(false)
        end)
    end
end

local is_open = false
local open_list = {}
function SGKTools.HeroShow(id,fun, delectTime, showDetail,IsHaveHero, sound)
    if is_open then
        open_list[#open_list+1] = {id, fun, delectTime, showDetail}
    else
        local heroInfo = showDetail and module.HeroModule.GetInfoConfig(id) or module.HeroModule.GetConfig(id)
        --ERROR_LOG("heroInfo============>>>>",sprinttb(heroInfo))
        if heroInfo then
            is_open = true
            local obj = SGK.ResourcesManager.Load("prefabs/base/HeroShow.prefab")
            if UnityEngine.GameObject.FindWithTag("UGUITopRoot") then
                obj = CS.UnityEngine.GameObject.Instantiate(obj, UnityEngine.GameObject.FindWithTag("UGUITopRoot").gameObject.transform)
            elseif UnityEngine.GameObject.FindWithTag("UITopRoot") then
                obj = CS.UnityEngine.GameObject.Instantiate(obj, UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject.transform)
            else
                obj = CS.UnityEngine.GameObject.Instantiate(obj)
            end
            local view = CS.SGK.UIReference.Setup(obj)

            --分享功能
            CS.UGUIClickEventListener.Get(view.Root.shareBtn.weixing.gameObject).onClick=function ()
                DialogStack.PushPrefStact("shareFrame",{name="HeroesShow"},view.Root)
            end

            local _removeFunc = function()
                if showDetail then
                    DispatchEvent("story_frame_hide_camera", false)
                end

                CS.UnityEngine.GameObject.Destroy(obj)
                --CS.UnityEngine.GameObject.Destroy(HeroOBJ)
                is_open = false
                if #open_list > 0 then
                    SGKTools.HeroShow(unpack(open_list[1]))
                    table.remove(open_list,1)
                elseif fun then
                    fun()
                end
                if showDetail then
                    DispatchEvent("stop_automationBtn",{automation = true,mandatory = false})
                end
                DispatchEvent("Continue_Show_DrawCard")
            end
            
            local _mode = showDetail and heroInfo.mode_id or heroInfo.__cfg.mode
            local _name = showDetail and heroInfo.name or heroInfo.__cfg.name
            local _title = showDetail and heroInfo.pinYin or heroInfo.__cfg.info_title
            local _info = showDetail and heroInfo.info or heroInfo.__cfg.info
            if showDetail then
                SGK.ResourcesManager.LoadAsync(view[SGK.UIReference],"prefabs/effect/UI/jues_appear.prefab",function (temp)
                    local HeroOBJ = GetUIParent(temp,obj.transform)
                    local HeroView = CS.SGK.UIReference.Setup(HeroOBJ)
                    local Animation = HeroView.jues_appear_ani.jues.gameObject:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation));
                    DispatchEvent("stop_automationBtn",{automation = false,mandatory = false,hide_story_camera = true})
                    DispatchEvent("story_frame_hide_camera", true)
                    Animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/".._mode.."/".._mode.."_SkeletonData.asset");
                    Animation:Initialize(true);
                    HeroView.jues_appear_ani.name_Text[UnityEngine.TextMesh].text = _name
                    HeroView.jues_appear_ani.name_Text[1][UnityEngine.TextMesh].text = _name
                    HeroView.jues_appear_ani.name_Text[2][UnityEngine.TextMesh].text = _name
                    HeroView.jues_appear_ani.name2_Text[UnityEngine.TextMesh].text = _title
    
                    HeroView.jues_appear_ani.bai_tiao:SetActive(not not showDetail)
                    HeroView.jues_appear_ani.bai_tiao.sanj_jsjs_bai.jies_Text[UnityEngine.TextMesh].text = _info
                    if delectTime then
                        HeroView.transform:DOLocalMove(Vector3(0, 0, 0), delectTime):OnComplete(function ( ... )
                            _removeFunc()
                        end)
                    end
                end)
            else
                view.Root:SetActive(true);
                if IsHaveHero then
                    view.Root.Bg:SetActive(false)
                elseif heroInfo.quest_id and heroInfo.quest_id ~= 0 then
                    local quest_cfg = module.QuestModule.GetCfg(heroInfo.quest_id)
                    if quest_cfg then
                        local rewardid = quest_cfg.cfg.raw.reward_id1
                        local heroBuff= require "hero.HeroBuffModule"
                        local buffId =heroBuff.GetBuffConfig(rewardid)
                        local parameterShowInfo = require "config.ParameterShowInfo"
                        local parameter = parameterShowInfo.Get(buffId.type)
                        view.Root.Bg.collectReward[UI.Text].text="收集奖励：".."全体" .. parameter.name .. "+" ..quest_cfg.cfg.raw.reward_value1
                        -- view.Root.Bg.collectReward.describe[UI.Text].text=parameter.desc
                        -- view.Root.Bg.collectReward.value[UI.Text].text="+" .. quest_cfg.cfg.raw.reward_value1
                        view.Root.Bg:SetActive(true)
                    else
                        view.Root.Bg:SetActive(false)
                    end
                else
                    view.Root.Bg:SetActive(false)
                end
                
                view.Root.info.name[UI.Text].text = _name;
                view.Root.info.title[UI.Text].text = _title;
                local cfg = module.HeroModule.GetConfig(id);
                view.Root.bg[CS.UGUISpriteSelector].index = cfg.role_stage - 1;
                view.Root.rare[CS.UGUISpriteSelector].index = cfg.role_stage - 1;
                local animation = view.Root.spine[CS.Spine.Unity.SkeletonGraphic];
                local pos,scale = DATABASE.GetBattlefieldCharacterTransform(tostring(_mode), "ui")
                view.Root.spine.transform.localPosition = pos * 100;
                view.Root.spine.transform.localScale = scale;
                SGK.ResourcesManager.LoadAsync(animation, "roles/".._mode.."/".._mode.."_SkeletonData.asset",function (resource)
                    DispatchEvent("stop_automationBtn",{automation = false,mandatory = false})
                    animation.skeletonDataAsset = resource;
                    animation.startingAnimation = "idle";
                    animation.startingLoop = true;
                    animation:Initialize(true);
                    if delectTime then
                        SGK.Action.DelayTime.Create(delectTime):OnComplete(function()
                            _removeFunc();
                        end)
                    end
                end)
            end

            if sound and sound ~= "0" then
                SGK.ResourcesManager.LoadAsync("sound/"..sound,typeof(UnityEngine.AudioClip),function (Audio)
                    view.Root[UnityEngine.AudioSource].clip = Audio
                    view.Root[UnityEngine.AudioSource]:Play()
                end)
            end
            view.Exit[CS.UGUIClickEventListener].onClick = function ()
                _removeFunc();
            end
        else
            ERROR_LOG(nil,"配置表role_info中"..id.."不存在")
        end
    end
end

function SGKTools.CloseFrame()
    DialogStack.Pop()
--[[
    if #DialogStack.GetPref_stact() > 0 or #DialogStack.GetStack() > 0 or SceneStack.Count() > 1 then
        DispatchEvent("KEYDOWN_ESCAPE")
    end
--]]
end

local monsterSkill = nil
function SGKTools.LoadMonsterSkill( role_id, role_lev )
    local _cfg = battleCfg.LoadNPC(role_id,role_lev)

    if not _cfg then
        ERROR_LOG("%d %d not exits battleCfg",role_id,role_lev);
        return
    end
    return _cfg;
end

function SGKTools.CloseStory()
    DispatchEvent("CloseStoryReset")
end

function SGKTools.loadEffect(name,id,data)--给NPC或玩家身上加载一个特效
    if id then
        local _npc = module.NPCModule.GetNPCALL(id)
        if _npc then
            if _npc.effect_list and _npc.effect_list[name] and SGKTools.GameObject_null(_npc.effect_list[name]) ~= true then
                _npc.effect_list[name]:SetActive(false)
                _npc.effect_list[name]:SetActive(true)
            else
                module.NPCModule.LoadNpcEffect(id,name,true)
           end
        end
    else
        if not data or not data.pid then
            if not data then
                data = {pid = module.playerModule.GetSelfID()}
            else
                data.pid = module.playerModule.GetSelfID()
            end
        end
        DispatchEvent("loadPlayerEffect",{name = name,data = data})
    end
end
--给玩家加载一个特效可以重复
function SGKTools.loadTwoEffect( name,id,data )
    id = id or module.playerModule.GetSelfID()
    if not data then
        data = {pid = id,time = 1}
    else
        data.pid = id
        data.time = data.time or 1
    end
    DispatchEvent("LOAD_PLAYER_EFFECT",{name = name,data = data});
end

function SGKTools.DelEffect(name,id,data)--删除npc或玩家身上某个特效
    if id then
        local _npc = module.NPCModule.GetNPCALL(id)
        if _npc then
            if _npc.effect_list and _npc.effect_list[name] then
                if SGKTools.GameObject_null(_npc.effect_list[name]) == false then
                    UnityEngine.GameObject.Destroy(_npc.effect_list[name].gameObject)
                end
                _npc.effect_list[name] = nil
           end
        end
    else
        if not data or not data.pid then
            DispatchEvent("DelPlayerEffect",{name = name,data = {pid = module.playerModule.GetSelfID()}})
        else
            DispatchEvent("DelPlayerEffect",{name = name,data = data})
        end
    end
end

function SGKTools.SynchronousPlayStatus(data)
    local NetworkService = require "utils.NetworkService"
    NetworkService.Send(18046, {nil,data})--向地图中其他人发送刷新玩家战斗信息
end

function SGKTools.TeamAssembled()--队伍集结
    module.TeamModule.SyncTeamData(111)
end

function SGKTools.EffectGather(fun,icon,desc,delay)
    if not delay then
        local _item = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_woring_ui.prefab")
        local _obj = CS.UnityEngine.GameObject.Instantiate(_item, UnityEngine.GameObject.FindWithTag("UGUIRootTop").transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        _view.fx_woring_ui_1.gzz_ani.text_working[UI.Text].text = desc or "采集中"
        _view.fx_woring_ui_1.gzz_ani.icon_working[UI.Image]:LoadSprite("icon/" .. icon)
        UnityEngine.GameObject.Destroy(_obj, 2)
    else
        local _item = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_working_ui_n.prefab")
        local _obj=CS.UnityEngine.GameObject.Instantiate(_item,UnityEngine.GameObject.FindWithTag("UGUIRootTop").transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        CS.UnityEngine.GameObject.Destroy(_obj, delay)

        _view.fx_working_ui_n.gzzing_ani.ui.text_working[UI.Text].text = desc or SGK.Localize:getInstance():getValue("zhuangyuan_caiji_01")
        _view.fx_working_ui_n.gzzing_ani.ui.icon_working[UI.Image]:LoadSprite("icon/" .. icon)

        _view.fx_working_ui_n.gzzing_ani.ui.huan[UI.Image]:DOFillAmount(1,delay):OnComplete(function()
            _view.fx_working_ui_n.gzzing_ani[UnityEngine.Animator]:Play("ui_working_2")
            _item.transform:DOScale(Vector3.one,1)
        end)
    end
end

function SGKTools.BuildBossStatus(npcid,_type)
    local buildScienceConfig = require "config.buildScienceConfig"
    local QuestModule = require "module.QuestModule"

    local activityConfig = require "config.activityConfig"

    local info = QuestModule.CityContuctInfo()
    local monster_config = activityConfig.GetCityConfig(nil,nil,nil,npcid)

    if not monster_config then
        return false;
    end
    local technology = buildScienceConfig.GetScienceConfig(monster_config.map_id);


    if not technology[_type] then
        return false
    end

    local lockLev = technology[_type][1].city_level
    local cfg = monster_config;
    local lastLv = activityConfig.GetCityLvAndExp(info,cfg.type);
    -- npc_config[1].mapid

    if not lastLv or lastLv < lockLev then
        return false
    else
        return true
    end
end


function SGKTools.loadEffectVec3(name,Vec3,time,lock,fun,scale)--加载一个全屏的UI特效
    local eff = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/"..name..".prefab"),UnityEngine.GameObject.FindWithTag("UGUITopRoot"))
    local _scale = scale or 100
    eff.transform.localScale = Vector3(_scale,_scale,_scale)
    local lockObj = nil
    if lock then
        SGKTools.LockMapClick(true, time);
    end
    SGK.Action.DelayTime.Create(time):OnComplete(function()
        if fun then
            fun()
        end
        UnityEngine.GameObject.Destroy(eff.gameObject)
    end)
end

function SGKTools.StoryPlayFullscreenEffect(name,Vec3,time,lock,fun,scale)-- 加载StoryFrame用的全屏UI特效
    DispatchEvent("STORY_FULL_SCREEN_EFFECT", name,Vec3,time,lock,fun,scale)
end

local loadSceneEffectArr = {}
function SGKTools.loadSceneEffect(name,Vec3,time,lock,fun)
    if loadSceneEffectArr[name] then
        return;
    end
    ERROR_LOG("加载特效===========>>>>",name);
    local eff = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/"..name .. ".prefab"))
    if Vec3 then
        eff.transform.position = Vec3
    end
    local lockView = nil
    if lock then
        lockView = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/LockFrame.prefab"))
    end
    loadSceneEffectArr[name] = {eff,lockView}
    if time then
        SGK.Action.DelayTime.Create(time):OnComplete(function()
            if fun then    fun() end
            if lockView then
                UnityEngine.GameObject.Destroy(lockView.gameObject)
            end
        end)
    end
end

function SGKTools.DestroySceneEffect(name,time,fun)
    if not loadSceneEffectArr[name] then
        return;
    end
    
    if SGKTools.GameObject_null(loadSceneEffectArr[name]) or SGKTools.GameObject_null(loadSceneEffectArr[name][1]) then
        loadSceneEffectArr[name] = nil
        return;
    end
    print("============",sprinttb(loadSceneEffectArr[name]))
    if loadSceneEffectArr[name] and loadSceneEffectArr[name][1].activeSelf then
        if time then
            SGK.Action.DelayTime.Create(time):OnComplete(function()
                if fun then
                    fun()
                end
                CS.UnityEngine.GameObject.Destroy(loadSceneEffectArr[name][1].gameObject)
                if loadSceneEffectArr[name][2] then
                    CS.UnityEngine.GameObject.Destroy(loadSceneEffectArr[name][2].gameObject)
                end
                loadSceneEffectArr[name] = nil
            end)
        end
    end
end

function SGKTools.NPC_Follow_Player(id,type)
    DispatchEvent("NPC_Follow_Player",id,type)
end

function SGKTools.NPCDirectionChange(id,Direction)
    local npc = module.NPCModule.GetNPCALL(id)
    npc[SGK.MapPlayer].Default_Direction = Direction
end

local now_TaskId = nil
function SGKTools.GetTaskId()
    return now_TaskId
end

function SGKTools.SetTaskId(id)
    now_TaskId = id
end

function SGKTools.SetNPCSpeed(id,speed)
    if id then
        module.NPCModule.GetNPCALL(id)[UnityEngine.AI.NavMeshAgent].speed = speed
    end
end
--设置自己加载的NPC
function SGKTools.SetMAPNPCSpeed(obj,speed,off,per)
    if obj then
        if speed then
            obj[UnityEngine.AI.NavMeshAgent].speed = speed
        elseif off then
            obj[UnityEngine.AI.NavMeshAgent].speed = obj[UnityEngine.AI.NavMeshAgent].speed - off
        elseif per then
            obj[UnityEngine.AI.NavMeshAgent].speed = obj[UnityEngine.AI.NavMeshAgent].speed * per
        end
    end
end

function SGKTools.SetNPCTimeScale(id,TimeScale)
    if id then
        module.NPCModule.GetNPCALL(id).Root.spine[CS.Spine.Unity.SkeletonAnimation].timeScale = TimeScale
    end
end

function SGKTools.PLayerConceal(status,duration,delay)
    DispatchEvent("PLayer_Shielding",{pid = module.playerModule.GetSelfID(),x = (status and 0 or 1),status = true,duration = duration,delay = delay})
end

function SGKTools.PLayerConcealtwo(x,duration,delay)
    DispatchEvent("PLayer_Shielding",{pid = module.playerModule.GetSelfID(),x = x,status = true,duration = duration,delay = delay})
end

function SGKTools.TeamConceal(status,duration,delay)
    local members = module.TeamModule.GetTeamMembers()
    for k,v in ipairs(members) do
        DispatchEvent("PLayer_Shielding",{pid = v.pid,x = (status and 0 or 1),status = true,duration = duration,delay = delay})
    end
end

function SGKTools.TeamConcealtwo(x,duration,delay)
    local members = module.TeamModule.GetTeamMembers()
    for k,v in ipairs(members) do
        DispatchEvent("PLayer_Shielding",{pid = v.pid,x = x,status = true,duration = duration,delay = delay})
    end
end

function SGKTools.TeamScript(value)--全队执行脚本
    module.TeamModule.SyncTeamData(109,value)
end

function SGKTools.PlayerMoveZERO()--脱离卡位
    DispatchEvent("MAP_CHARACTER_MOVE_Player", {module.playerModule.GetSelfID(), 0, 0, 0, true});
end

function SGKTools.PlayerMove(x, y, z, pid)
    DispatchEvent("MAP_CHARACTER_MOVE_Player", {pid or module.playerModule.GetSelfID(), x, y, z});
end

function SGKTools.PlayerTransfer(x,y,z)--瞬移
    DispatchEvent("MAP_CHARACTER_MOVE_Player", {module.playerModule.GetSelfID(), x, y, z, true});
end

function SGKTools.ChangeMapPlayerMode(mode)
    DispatchEvent("MAP_FORCE_PLAYER_MODE", {pid = module.playerModule.GetSelfID(), mode = mode});
end

local ScrollingMarqueeView = nil
local ScrollingMarqueeDesc = {}
local ScrollingMarqueeText = {};
local ScrollingMarquee_lock = true
local IsMove = false
function SGKTools.ScrollingMarquee_Change(lock)
    ScrollingMarquee_lock = lock
end

local __next_index = 0;

local function string_trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function string_replace(s, a, b)
    return (s:gsub(a, b))
end


local function ScrollingMarquee_Append(desc, level)
    if desc  then
        desc = string_replace(string_replace(string_trim(desc), '\n', ' '), '\r', ' ');

        __next_index = __next_index + 1;
        table.insert(ScrollingMarqueeDesc, {desc = desc,level = level or 0, index = __next_index});

        table.sort(ScrollingMarqueeDesc,function (a,b)
            if a.level == b.level then return a.index < b.index end;
            return a.level > b.level
        end)
    end
end

local function ScrollingMarquee_Pop()
    if ScrollingMarqueeDesc[1] then
        local desc = ScrollingMarqueeDesc[1].desc;
        table.remove(ScrollingMarqueeDesc, 1);
        return desc;
    end
end

local function ScrollingMarquee_Count()
    return #ScrollingMarqueeDesc;
end

function SGKTools.showScrollingMarquee(desc,level)
    if ScrollingMarquee_lock then
        return
    end

    ScrollingMarquee_Append(desc, level);

    if ScrollingMarquee_Count() == 0 then
        return;
    end

    if ScrollingMarqueeView == nil then
        local root = UnityEngine.GameObject.FindWithTag("UGUIRoot")
        if not root then
            ERROR_LOG("ScrollingMarquee root is nil")
            return
        end
        local parent = CS.SGK.UIReference.Setup(root).ScrollingMarqueeRoot
        ScrollingMarqueeView = CS.SGK.UIReference.Setup(GetUIParent(SGK.ResourcesManager.Load("prefabs/base/ScrollingMarquee.prefab"),parent))

        ScrollingMarqueeView[UnityEngine.CanvasGroup]:DOFade(1,0.5):OnComplete(function( ... )
            SGKTools.showScrollingMarquee();
        end)
        return;
    end

    local text_count = #ScrollingMarqueeText
    local last_text = ScrollingMarqueeText[text_count];
    
    if last_text and last_text.anchoredPosition.x < - last_text.sizeDelta.x - 100 then
        last_text = nil;
    end

    if last_text then
        return;
    end

    local descText = SGK.UIReference.Instantiate(ScrollingMarqueeView.bg.desc, ScrollingMarqueeView.bg.transform);
    table.insert(ScrollingMarqueeText,descText.transform);
    
    local desc = ScrollingMarquee_Pop();
    descText:SetActive(true);
    descText[UnityEngine.UI.Text].text = desc;

    local width = ScrollingMarqueeView.bg.transform.sizeDelta.x;
    descText.transform:DOLocalMoveX(0, 0.1):OnComplete(function()
        local text_width = descText.transform.sizeDelta.x;
        
        local distance = text_width + width;

        local show_next_time = (text_width + 150)/ 80;
        SGK.Action.DelayTime.Create(show_next_time):OnComplete(function()
            SGKTools.showScrollingMarquee();
        end)

        descText.transform:DOLocalMoveX(-distance, distance / 80):OnComplete(function()
            SGKTools.showScrollingMarquee();
            for k, v in ipairs(ScrollingMarqueeText) do
                if v == descText.transform then
                    if k == #ScrollingMarqueeText then
                        ScrollingMarqueeView[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
                            if #ScrollingMarqueeText == 0 then
                                UnityEngine.GameObject.Destroy(ScrollingMarqueeView.gameObject);
                                ScrollingMarqueeView = nil;
                            end
                        end)
                    else
                        UnityEngine.GameObject.Destroy(descText);
                    end
                    table.remove(ScrollingMarqueeText, k)
                    break;
                end
            end
        end):SetEase(CS.DG.Tweening.Ease.Linear)
    end)
end

function SGKTools.Map_Interact(npc_id)
    local MapConfig = require "config.MapConfig"
    local npc_conf = MapConfig.GetMapMonsterConf(npc_id)
    if not npc_conf then
        ERROR_LOG("NPC_id->"..npc_id.."在NPC表中不存在")
        return
    end
    local mapid = npc_conf.mapid
    if SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId ~= mapid then
        SceneStack.EnterMap(mapid);
    end
    module.EncounterFightModule.GUIDE.Interact("NPC_"..npc_id);
end

function SGKTools.PlayGameObjectAnimation(name, trigger)
    local obj = UnityEngine.GameObject.Find(name);
    if not obj then
        print("object no found", name);
        return;
    end

    local animator = obj:GetComponent(typeof(UnityEngine.Animator));
    if animator then
        animator:SetTrigger(trigger);
    end
end

function SGKTools.StronglySuggest(desc)
    local obj = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/StronglySuggest.prefab"))
    local view = CS.SGK.UIReference.Setup(obj)
    view.desc[UnityEngine.UI.Text].text = desc
    view[UnityEngine.CanvasGroup]:DOFade(1,0.5):OnComplete(function ( ... )
       view[UnityEngine.CanvasGroup]:DOFade(0, 0.5):SetDelay(1):OnComplete(function ( ... )
            CS.UnityEngine.GameObject.Destroy(obj);
        end);
    end)
end

function SGKTools.FriendTipsNew(parent,pid,Toggle,data)
    local obj = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/FriendTipsNew.prefab"),parent[1])

    --obj.transform:SetParent(parent[2].transform,true)
    obj.transform.localScale = Vector3(1,1,1)
    --parent[2]:SetActive(true)
    local view = CS.SGK.UIReference.Setup(obj)
    view.Root.transform.position = parent[2].transform.position
    view.Root[UnityEngine.CanvasGroup]:DOFade(1,0.5)
    view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
        DispatchEvent("FriendTipsNew_close")
        --view.Root[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function( ... )
            UnityEngine.GameObject.Destroy(obj)
        --end)
    end
    if Toggle then
        for i = 1,#Toggle do
            view.Root.group[Toggle[i]]:SetActive(true)
            if Toggle[i] == 5 then
                local FriendData = module.FriendModule.GetManager(1,pid)
                view.Root.group[Toggle[i]].Text[UnityEngine.UI.Text].text = FriendData and FriendData.care == 1 and "取消关注" or "特别关注"
            elseif Toggle[i] == 3 then
                view.Root.group[Toggle[i]].Text[UnityEngine.UI.Text].text = ""
                module.TeamModule.GetPlayerTeam(pid,true,function( ... )
                    local ClickTeamInfo = module.TeamModule.GetClickTeamInfo(pid)
                    if ClickTeamInfo and ClickTeamInfo.members and ClickTeamInfo.members[1] and module.TeamModule.GetTeamInfo().id <= 0 then
                        view.Root.group[Toggle[i]].Text[UnityEngine.UI.Text].text = "申请入队"
                    else
                        view.Root.group[Toggle[i]].Text[UnityEngine.UI.Text].text = "邀请入队"
                    end
                end)
            end
            view.Root.group[Toggle[i]][CS.UGUIClickEventListener].onClick = function ( ... )
                if Toggle[i] == 1 then--加好友
                    utils.NetworkService.Send(5013,{nil,1,pid})
                elseif Toggle[i] == 5 then--特别关注
                    local FriendData = module.FriendModule.GetManager(1,pid)
                    if FriendData and FriendData.care == 1 then
                        utils.NetworkService.Send(5013,{nil,1,pid})
                    else
                        if module.FriendModule.GetcareCount() < 5 then
                            utils.NetworkService.Send(5013,{nil,3,pid})
                        else
                            showDlgError(nil,"特别关注已达上限")
                        end
                    end
                elseif Toggle[i] == 4 then--私聊
                    local ChatDataList = {}
                    if data then
                        for i = 1,#data do
                            ChatDataList[i] = data[i]
                        end
                    end
                    local ChatData = module.ChatModule.GetManager(8)
                    if ChatData and ChatData[pid] then
                        ChatData = ChatData[pid]
                        for i = 1,#ChatData do
                            if ChatData[i].status == 1 then
                                local FriendData = module.FriendModule.GetManager(nil,pid)
                                if FriendData and (FriendData.type == 1 or FriendData.type == 3) then
                                    --utils.NetworkService.Send(5005,{nil,{{ChatData[i].id,2}}})--已读取加好友通知
                                end
                            else
                                ChatDataList[#ChatDataList+1] = ChatData[i]
                            end
                        end
                    end
                    table.sort(ChatDataList,function(a,b)
                        return a.time < b.time
                    end)
                    -- local list = {data = ChatDataList,pid = pid}
                    -- DialogStack.PushPref("FriendChat",list,UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject)
                    DispatchEvent("FriendSystemlist_indexChange",{i = 1,pid = pid,name = module.playerModule.IsDataExist(pid).name})
                    --SGKTools.FriendChat()
                elseif Toggle[i] == 2 then--邀请入团
                     if module.unionModule.Manage:GetUionId() == 0 then
                        showDlgError(nil, "您还没有公会")
                    elseif module.unionModule.GetPlayerUnioInfo(pid).unionId ~= nil and module.unionModule.GetPlayerUnioInfo(pid).unionId ~= 0 then
                        showDlgError(nil, "该玩家已有公会")
                    else
                        local PlayerInfoHelper = require "utils.PlayerInfoHelper"
                        local openLevel = require "config.openLevel"
                        PlayerInfoHelper.GetPlayerAddData(pid, 7, function(addData)
                            local level = module.playerModule.Get(pid).level
                             if openLevel.GetStatus(2101,level) then
                            --if addData.UnionStatus then
                                if addData.RefuseUnion then
                                     showDlgError(nil,"对方已设置拒绝邀请")
                                 else
                                    module.unionModule.Invite(pid)
                                end
                            else
                                showDlgError(nil,"对方未开启公会功能")
                            end
                        end,true)
                    end
                elseif Toggle[i] == 3 then--邀请入队
                    -- local teamInfo = module.TeamModule.GetTeamInfo();
     --                if teamInfo.group ~= 0 then
                    --     module.TeamModule.Invite(pid)
                    -- else
                    --     showDlgError(nil,"请先创建一个队伍")
                    -- end
                    if view.Root.group[Toggle[i]].Text[UnityEngine.UI.Text].text == "申请入队" then
                        local ClickTeamInfo = module.TeamModule.GetClickTeamInfo(pid)
                        if ClickTeamInfo.upper_limit == 0 or (module.playerModule.Get().level >= ClickTeamInfo.lower_limit and  module.playerModule.Get().level <= ClickTeamInfo.upper_limit) then
                            module.TeamModule.JoinTeam(ClickTeamInfo.members[3])
                        else
                            showDlgError(nil,"你的等级不满足对方的要求")
                        end
                    else
                        local PlayerInfoHelper = require "utils.PlayerInfoHelper"
                        local openLevel = require "config.openLevel"
                        PlayerInfoHelper.GetPlayerAddData(pid, 7, function(addData)
                             --ERROR_LOG(sprinttb(addData))
                             --if addData.TeamStatus then
                             local level = module.playerModule.Get(pid).level
                             if openLevel.GetStatus(1601,level) then
                                 if addData.RefuseTeam then
                                     showDlgError(nil,"对方已设置拒绝邀请")
                                 else
                                    if module.TeamModule.GetTeamInfo().id <= 0 then
                                        module.TeamModule.CreateTeam(999,function ( ... )
                                            module.TeamModule.Invite(pid);
                                        end);--创建空队伍并邀请对方
                                    else
                                        module.TeamModule.Invite(pid);
                                    end
                                end
                            else
                                showDlgError(nil,"对方未开启组队功能")
                             end
                        end,true)
                    end
                elseif Toggle[i] == 8 then--拉黑
                    local FriendData = module.FriendModule.GetManager(1,pid)
                    if FriendData then
                        utils.NetworkService.Send(5013,{nil,2,pid})--朋友黑名单
                    else
                        utils.NetworkService.Send(5013,{nil,4,pid})--陌生人黑名单
                    end
                elseif Toggle[i] == 9 then--删除好友
                    showDlg(nil,"确定要删除该好友吗？",function()
                        utils.NetworkService.Send(5015,{nil,pid})
                    end,function ( ... )
                    end)
                elseif Toggle[i] == 6 then--礼物
                    DialogStack.PushPref("FriendBribeTaking",{pid = pid,name = module.playerModule.IsDataExist(pid).name},view.transform.parent.gameObject)
                elseif Toggle[i] == 7 then--进入基地
                    utils.MapHelper.EnterOthersManor(pid)
                else
                    ERROR_LOG("参数错误",Toggle[i])
                end
                --parent[2]:SetActive(false)
                DispatchEvent("FriendTipsNew_close")
                view.Root[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function( ... )
                    UnityEngine.GameObject.Destroy(obj)
                end)
            end
        end
    end
end

function SGKTools.FormattingNumber(Count)
    if Count > 1000000 then
        return SGKTools.GetPreciseDecimal(Count/1000000,1).."M"
    elseif Count > 1000 then
        return SGKTools.GetPreciseDecimal(Count/1000,1).."K"
    end
    return Count
end

function SGKTools.GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum;
        end
        n = n or 0;
        n = math.floor(n)
        if n < 0 then
        n = 0;
    end
    local nDecimal = 10 ^ n
    local nTemp = math.floor(nNum * nDecimal);
    local nRet = nTemp / nDecimal;
    return nRet;
end

function SGKTools.ChangeNpcDir(obj, direction)
    obj:GetComponent(typeof(SGK.MapPlayer)):SetDirection(direction)
end

function SGKTools.EnterMap(name)
    module.EncounterFightModule.GUIDE.EnterMap(name)
end

function SGKTools.Interact(name)
    module.EncounterFightModule.GUIDE.Interact(name)
end

function SGKTools.Stop()
    module.EncounterFightModule.GUIDE.Stop()
end

function SGKTools.GetCurrentMapName()
    module.EncounterFightModule.GUIDE.GetCurrentMapName()
end

function SGKTools.GetCurrentMapID()
    module.EncounterFightModule.GUIDE.GetCurrentMapID()
end

function SGKTools.StartPVEFight(fightID)
    module.EncounterFightModule.GUIDE.StartPVEFight(fightID)
end

function SGKTools.ON_Interact()
    module.EncounterFightModule.GUIDE.ON_Interact()
end

function SGKTools.GetInteractInfo()
    module.EncounterFightModule.GUIDE.GetInteractInfo()
end

function SGKTools.NPCInit(gameObject)
    module.EncounterFightModule.GUIDE.NPCInit(gameObject)
end

function SGKTools.StopPlayerMove(pid)
    DispatchEvent("LOCAL_MAPSCENE_STOPPLAYER_MOVE")
end

function SGKTools.ScientificNotation(number)
    local _item = number
    if _item >= 1000000 then
        _item = string.format("%.1f", _item/1000000).."M"
    elseif _item >= 1000 then
        _item = string.format("%.1f", _item/1000).."K"
    end
    return _item
end

---true为组队中
function SGKTools.GetTeamState()
    local teamInfo = module.TeamModule.GetTeamInfo() or {}
    return (teamInfo.id > 0)
end

--
function SGKTools.GetEnterOthersManor( other_level )
    if module.playerModule.Get().level < openLevel.GetCfg(2001).open_lev  then
        return;
    end
    if other_level < openLevel.GetCfg(2001).open_lev then
        return
    end
    if utils.SGKTools.GetTeamState() then
        if utils.SGKTools.isTeamLeader() then
            return true;
        else
            if module.TeamModule.GetAfkStatus() ~= true then
                return
            else
                return true;
            end
        end
    else
        return true;
    end
end

function SGKTools.PlayerMatching(id)
    if SceneStack.GetBattleStatus() then
        showDlgError(nil, "战斗内无法进行该操作")
        return
    end
    local teamInfo = module.TeamModule.GetTeamInfo()
    if teamInfo.group == 0 then
        if module.TeamModule.GetplayerMatchingType() ~= 0 then
            module.TeamModule.playerMatching(0)
        else
            if id == 0 or id == 999 or id == nil then
                return showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))--请选择一个目标
            end
            
            local CemeteryConf = require "config.cemeteryConfig"
            local cemeteryCfg = CemeteryConf.Getteam_battle_conf(id)
            if module.playerModule.Get().level < cemeteryCfg.limit_level then
                showDlgError(nil, "等级不足")
                return
            end

            module.TeamModule.playerMatching(id)
        end
    end
end

function SGKTools.SwitchTeamTarget( group )
    local teamInfo = module.TeamModule.GetTeamInfo()
    local _status = teamInfo.group ~= 0
    local CemeteryConf = require "config.cemeteryConfig"
    local cemeteryCfg = CemeteryConf.Getteam_battle_conf(group)
    if _status then
        
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
            return
        end

        if group == 0 or group == 999 then
            return showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))--请选择一个目标
        end
        if group ~= teamInfo.group then
            coroutine.resume( coroutine.create( function ( ... )
                local ret = utils.NetworkService.SyncRequest(18178,{nil, group})
                teamInfo = module.TeamModule.GetTeamInfo()
                
                if ret[2] == 0 then
                    if teamInfo.leader.pid == module.playerModule.Get().id then
                        if module.TeamModule.GetTeamInfo().auto_match then
                            module.TeamModule.TeamMatching(false)
                        else
                            local lv_limit = ActivityTeamlist.Get_all_activity(teamInfo.group).lv_limit
                            local unqualified_name = {}
                            for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
                                if v.level < lv_limit then
                                    unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
                                end
                            end
                            if #unqualified_name == 0 then
                                if teamInfo.group ~= 0 and teamInfo.group ~= 999 then
                                    module.TeamModule.TeamMatching(true)
                                else
                                    module.TeamModule.TeamMatching(false)
                                end
                            else
                                for i =1 ,#unqualified_name do
                                    module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
                                end
                            end
                        end
                    else
                        showDlgError(nil,SGK.Localize:getInstance():getValue("common_duiyuanpipei"))
                    end
                end
                
            end ) )

        else
            if teamInfo.leader.pid == module.playerModule.Get().id then
                if module.TeamModule.GetTeamInfo().auto_match then
                    module.TeamModule.TeamMatching(false)
                else
                    local lv_limit = ActivityTeamlist.Get_all_activity(teamInfo.group).lv_limit
                    local unqualified_name = {}
                    for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
                        if v.level < lv_limit then
                            unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
                        end
                    end
                    if #unqualified_name == 0 then
                        if teamInfo.group ~= 0 and teamInfo.group ~= 999 then
                            module.TeamModule.TeamMatching(true)
                        else
                            module.TeamModule.TeamMatching(false)
                        end
                    else
                        for i =1 ,#unqualified_name do
                            module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
                        end
                    end
                end
            else
                showDlgError(nil,SGK.Localize:getInstance():getValue("common_duiyuanpipei"))
            end
        end
    end
end


---true为队长
function SGKTools.isTeamLeader()
    local teamInfo = module.TeamModule.GetTeamInfo() or {}
    return (teamInfo.leader and teamInfo.leader.pid) and (module.playerModule.Get().id == teamInfo.leader.pid)
end

function SGKTools.CheckPlayerMode(mode)--查询玩家形象是否匹配
    local addData=utils.PlayerInfoHelper.GetPlayerAddData(0,8)
    return addData.ActorShow==mode
end

function SGKTools.ChecHeroFashionSuit(suitId,heroId)--查询Hero时装是否匹配
    local hero=utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    return hero.showMode==suitId
end

function SGKTools.InToDefensiveFortress()--进入元素暴走
    print("队长请求进入 元素暴走活动")
    if SceneStack.GetBattleStatus() then
        showDlgError(nil, "战斗内无法进行该操作")
    else
        local NetworkService = require "utils.NetworkService"
        NetworkService.Send(16127)
    end
end
--检查队伍中所有人是否跟随true
function SGKTools.CheckAllMemberAFK(  )
    if not utils.SGKTools.GetTeamState() then
        return nil
    end

    local teamInfo = module.TeamModule.GetTeamInfo()
    local members = teamInfo.members
    local list = {}
    if utils.SGKTools.isTeamLeader() then
        for i = 1,#members do

            if members[i].pid ~= teamInfo.leader.pid then
                if module.TeamModule.getAFKMembers(members[i].pid) then
                    return nil
                end
            end
        end
        return true;
    end
    return nil
end
--检查自己是否跟随:跟随true,暂离false,队长nil
function SGKTools.CheckPlayerAfkStatus( pid )
    pid = pid or module.playerModule.Get().id;
    if utils.SGKTools.GetTeamState() and utils.SGKTools.isTeamLeader() then
        return nil;
    end
    if utils.SGKTools.GetTeamState() and not module.TeamModule.GetAfkStatus(pid) then
        return true; 
    end
end

function SGKTools.CheckDialog()
    if SceneStack.GetBattleStatus() then
        showDlgError(nil, "战斗内无法进行该操作")
        return false
    end
    if utils.SGKTools.GetTeamState() then
        showDlgError(nil, "队伍内无法进行该操作")
        return false
    end
    return true
end

function SGKTools.OpenGuildPvp( ... )
    local teamInfo = module.TeamModule.GetTeamInfo();
    if SceneStack.GetBattleStatus() or teamInfo.id > 0 then
        DialogStack.Push("guild_pvp/GuildPVPJoinPanel")
    else
        if SGKTools.isAlreadyJoined() then
            SceneStack.Push("GuildPVPPreparation", "view/guild_pvp/GuildPVPPreparation.lua")
        else
            DialogStack.Push("guild_pvp/GuildPVPJoinPanel")
        end
    end
end

function SGKTools.isAlreadyJoined( ... )
    local guild = module.unionModule.Manage:GetSelfUnion();
    if guild == nil then
        return false;
    end
    local GuildPVPGroupModule = require "guild.pvp.module.group"
    local list = GuildPVPGroupModule.GetGuildList();
    for _, v in ipairs(list) do
        if v.id == guild.id then
            return true
        end
    end
    return false;
end

function SGKTools.UnionPvpState()
    return true
    -- local GuildPVPGroupModule = require "guild.pvp.module.group"
    -- local status,fight_status = GuildPVPGroupModule.GetStatus();
    -- if GuildPVPGroupModule.GetMinOrder() == nil or GuildPVPGroupModule.GetMinOrder() == 1 or status == 0 then
    --     return true
    -- end
    -- showDlgError(nil, "公会战中无法操作")
    -- return false
end

function SGKTools.ClearMapPlayer(status)--是否清除地图所有玩家并锁定生成
    DispatchEvent("ClearMapPlayer",status)
end

function SGKTools.ShieldingMapPlayer()--屏蔽地图玩家
    local Shielding = module.MapModule.GetShielding()
    module.MapModule.SetShielding(not Shielding)
    Shielding = not Shielding
    local map_list = module.TeamModule.GetMapTeam()--拿到地图上所有队伍数据
    local teamInfo = module.TeamModule.GetTeamInfo()
    --ERROR_LOG(sprinttb(map_list))
    for k,v in pairs(map_list) do
        for i = 1,#v[2] do
            if teamInfo.id <= 0 or (teamInfo.id > 0 and v[3] ~= teamInfo.id) then
                DispatchEvent("PLayer_Shielding",{pid = v[2][i],x = (Shielding and 0 or 1)})
            end
        end
    end
    local MapGetPlayers = module.TeamModule.MapGetPlayers()
    for k,v in pairs(MapGetPlayers)do
        --ERROR_LOG(k)
        if module.playerModule.GetSelfID() ~= k then
            DispatchEvent("PLayer_Shielding",{pid = k,x = (Shielding and 0 or 1)})
        end
    end
end

function SGKTools.StoryEndEffect(desc1,desc2,desc3)--剧情某一章节结束特效
    utils.SGKTools.PopUpQueue(6,{desc1,desc2,desc3})
end

function SGKTools.StoryEndEffectCallBack(data,fun)
    local desc1,desc2,desc3 = data[1],data[2],data[3]
    local obj = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/Effect/UI/jvqing_end.prefab"))
    local LockMapObj = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/LockFrame.prefab"))
    local LockMapObj_view = CS.SGK.UIReference.Setup(LockMapObj)
    local _view = CS.SGK.UIReference.Setup(obj)
    _view.end_ani.tiedoor_2.zhanjie[UnityEngine.TextMesh].text = desc1
    _view.end_ani.tiedoor_2.biaoti[UnityEngine.TextMesh].text = desc2
    _view.end_ani.tiedoor_2.kaiqi[UnityEngine.TextMesh].text = desc3
    LockMapObj_view[CS.UGUIClickEventListener].onClick = function ( ... )
        _view.end_ani[UnityEngine.Animator]:Play("tiedoor_ani2")
        SGK.Action.DelayTime.Create(1):OnComplete(function()
            UnityEngine.GameObject.Destroy(obj)
            UnityEngine.GameObject.Destroy(LockMapObj)
            if fun then
                fun()
            end
        end)
    end
end

function SGKTools.Iphone_18(fun_1,fun_2, info)
    local obj = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/Iphone18.prefab"))
    local _view = CS.SGK.UIReference.Setup(obj)
    local _anim = _view.phone_bg[UnityEngine.Animator]
    if info then
        _view.phone_bg.Text[UI.Text].text = info.text
    end
    SGK.BackgroundMusicService.Pause()
    _anim:Play("phone_ani1")
    SGK.Action.DelayTime.Create(0.3):OnComplete(function()
        if info and info.soundName then
            _view[SGK.AudioSourceVolumeController]:Play("sound/"..info.soundName .. ".mp3")
        end
        _anim:Play("phone_ani2")
    end)
    _view.phone_bg.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        _anim:Play("phone_ani3")
        SGK.Action.DelayTime.Create(0.5):OnComplete(function()
            SGK.BackgroundMusicService.UnPause()
            if fun_1 then
                fun_1()
            end
            UnityEngine.GameObject.Destroy(obj)
        end)
    end
    _view.phone_bg.nBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        _anim:Play("phone_ani4")
        SGK.Action.DelayTime.Create(0.5):OnComplete(function()
            SGK.BackgroundMusicService.UnPause()
            if fun_2 then
                fun_2()
            end
            UnityEngine.GameObject.Destroy(obj)
        end)
    end
end

function SGKTools.TreasureBox(func)
    -- if not func then
    --     return
    -- end
    local obj = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_baoxiang.prefab"))
    local _view = CS.SGK.UIReference.Setup(obj)
    _view.baoxiang[CS.UGUIClickEventListener].onClick = function ( ... )
        _view.baoxiang.daiji_1:SetActive(false)
        _view.baoxiang.baozha_2:SetActive(true)
        SGK.Action.DelayTime.Create(2.0):OnComplete(function()
            if func then
                func()
            end
            UnityEngine.GameObject.Destroy(obj)
        end)
    end
end

function SGKTools.ShowTaskItem(conf,fun,parent)
    --ERROR_LOG(sprinttb(conf))
    local ItemList = {}
    if conf.reward_id1 ~= 0 and conf.reward_id1 ~= 90036 then--必得
        ItemList[#ItemList+1] = {type = conf.reward_type1,id = conf.reward_id1,count = conf.reward_value1,mark =1}
    end
    if conf.reward_id2 ~= 0 and conf.reward_id2 ~= 90036 then--必得
        ItemList[#ItemList+1] = {type = conf.reward_type2,id = conf.reward_id2,count = conf.reward_value2,mark = 1}
    end
    if conf.reward_id3 ~= 0 and conf.reward_id3 ~= 90036 then--必得
        ItemList[#ItemList+1] = {type = conf.reward_type3,id = conf.reward_id3,count = conf.reward_value3,mark = 1}
    end
    if conf.drop_id ~= 0 then
        local Fight_reward = SmallTeamDungeonConf.GetFight_reward(conf.drop_id)
        if Fight_reward then
            local _level = module.HeroModule.GetManager():Get(11000).level
            for i = 1,#Fight_reward do
                if _level >= Fight_reward[i].level_limit_min and _level <= Fight_reward[i].level_limit_max then
                    local repetition = false
                    for j = 1,#ItemList do
                        if ItemList[j].id == Fight_reward[i].id then
                            repetition = true
                            break
                        end
                    end
                    if not repetition then
                        ItemList[#ItemList+1] = {type = Fight_reward[i].type,id = Fight_reward[i].id,count = 0,mark = 2}--概率获得
                    end
                end
            end
        end
    end
    local ItemHelper = require "utils.ItemHelper"
    local list = {}
    for i = 1,#ItemList do
        if i > 6 then
            break
        end
        local item = ItemHelper.Get(ItemList[i].type, ItemList[i].id);
        if item.id ~= 199999 and (ItemList[i].type ~= ItemHelper.TYPE.ITEM or item.cfg.is_show == 1) then
            list[#list+1] = ItemList[i]
        end
    end
    DialogStack.PushPref("ShowPreFinishTip", {itemTab = list, fun = fun},parent or UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    --DialogStack.PushPrefStact("mapSceneUI/GiftBoxPre", {itemTab = list,interactable = true, fun = fun,textName = "<size=40>任</size>务报酬",textDesc = "",not_exit = true},parent or UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject.transform)
end

function SGKTools.NpcTalking(npc_gid)
    --npc对话闲聊
    local npcConfig = require "config.npcConfig"
    local MapConfig = require "config.MapConfig"
    local gid = MapConfig.GetMapMonsterConf(npc_gid).npc_id
    if gid == 0 then
        ERROR_LOG("all_npc表里的gid列的"..npc_gid.."在config_arguments_npc表中的npc_id列中不存在")
        return
    end
    local NpcTalkingList = npcConfig.Get_npc_talking(gid)
    local NpcList = npcConfig.GetNpcFriendList()
    local item_id = NpcList[gid].arguments_item_id
    local value = module.ItemModule.GetItemCount(item_id)
    local name = npcConfig.GetnpcList()[gid].name
    local suitable_npc_list = {}
    --ERROR_LOG(tostring(value),sprinttb(NpcTalkingList))
    if NpcTalkingList then
        local weight_sum = 0
        for i =1,#NpcTalkingList do
            if value >= NpcTalkingList[i].min and value <= NpcTalkingList[i].max then
                weight_sum = weight_sum + NpcTalkingList[i].weight
                suitable_npc_list[#suitable_npc_list+1] = NpcTalkingList[i]
            end
        end
        local rom = math.random(1,weight_sum)
        weight_sum = 0
        for i = 1,#suitable_npc_list do
            weight_sum = weight_sum + suitable_npc_list[i].weight
            if rom <= weight_sum then
                local shop_id = suitable_npc_list[i].shop_type
                local shop_item_gid = suitable_npc_list[i].shop_gid
                if shop_id ~= 0 then
                    module.ShopModule.GetManager(shop_id)
                end
                LoadStory(suitable_npc_list[i].story_id,function ( ... )
                    --ERROR_LOG(shop_id,shop_item_gid)
                    if shop_id ~= 0 then
                        local shop_item_list = module.ShopModule.GetManager(shop_id).shoplist[shop_item_gid].product_item_list
                        --ERROR_LOG(shop_id,shop_item_gid,sprinttb(module.ShopModule.GetManager(shop_id).shoplist))
                        local old_value = value
                        module.ShopModule.Buy(shop_id,shop_item_gid,1,nil,function( ... )
                            local now_value = module.ItemModule.GetItemCount(item_id) - value
                            if now_value >= 1 then
                                showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_npc_tips_01",name,"+"..now_value))
                            end
                        end)
                    end
                end)
                return
            end
        end
    end
end

function SGKTools.FlyItem(pos,itemlist)
    local parent = UnityEngine.GameObject.FindWithTag("UGUIRootTop")
    local prefab = SGK.ResourcesManager.Load("prefabs/base/IconFrame.prefab");
    for i = 1,#itemlist do
        local ItemIconView = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, parent.transform));
        utils.IconFrameHelper.Create(ItemIconView, {id = itemlist[i].id,type = itemlist[i].type,count = itemlist[i].count,showName=true})        -- if itemlist[i].type == ItemHelper.TYPE.HERO then

        ItemIconView.transform.position = Vector3(itemlist[i].pos[1],itemlist[i].pos[2],itemlist[i].pos[3])
        ItemIconView.transform.localScale = Vector3.one*0.8
        ItemIconView.transform:DOMove(Vector3(pos[1],pos[2],pos[3]),1):OnComplete(function( ... )
            ItemIconView:AddComponent(typeof(UnityEngine.CanvasGroup)):DOFade(0,0.5):OnComplete(function( ... )
                UnityEngine.GameObject.Destroy(ItemIconView.gameObject)
            end)--:SetDelay(1)
        end)
    end
end

function SGKTools.GetNPCBribeValue(npc_id)
    local ItemModule = require "module.ItemModule"
    local npcConfig = require "config.npcConfig"
    local npc_Friend_cfg = npcConfig.GetNpcFriendList()[npc_id]
    if not npc_Friend_cfg then
        return 0,0
    end
    local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
    local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
    local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
    local relation_index = 0
    for i = 1,#relation do
        if relation_value >= tonumber(relation[i]) then
            relation_index = i
        end
    end
    return relation_value,relation_index
end

function SGKTools.OpenNPCBribeView(npc_id)
    local ItemModule = require "module.ItemModule"
    local npcConfig = require "config.npcConfig"
    local npc_Friend_cfg = npcConfig.GetNpcFriendList()[npc_id]
    DialogStack.PushPref("npcBribeTaking",{id = npc_Friend_cfg.npc_id,item_id = npc_Friend_cfg.arguments_item_id})
end

function SGKTools.FriendChat(pid,name,desc)
    local ChatManager = require 'module.ChatModule'
    utils.NetworkService.Send(5009,{nil,pid,3,desc,""})
    ChatManager.SetManager({fromid = pid,fromname = name,title = desc},1,3)--0聊天显示方向1右2左
end

--好友排行榜名次变化Tip
function SGKTools.RankListChangeTipShow(data,func)
    local tempObj = SGK.ResourcesManager.Load("prefabs/rankList/rankListChangeTip.prefab")
    local obj = nil;
    local UIRoot = UnityEngine.GameObject.FindWithTag("UITopRoot")
    if UIRoot then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UIRoot.gameObject.transform)
    end
    local TipsRoot = CS.SGK.UIReference.Setup(obj)
    local _view=TipsRoot.view
    local type=data and data.type
    local pids=data and data.pids

    CS.UGUIClickEventListener.Get(TipsRoot.mask.gameObject, true).onClick = function()
        if func then
            func()
        end
        UnityEngine.GameObject.Destroy(obj);
    end

    local RankListModule = require "module.RankListModule"
    local rankCfg=RankListModule.GetRankCfg(type)

    local desc= SGK.Localize:getInstance():getValue("paihangbang_tongzhihaoyou_01",SGK.Localize:getInstance():getValue(rankCfg.name))
    _view.item.typeText[UI.Text].text=SGK.Localize:getInstance():getValue(rankCfg.name)
    _view.item.Text[UI.Text].text="超越好友!"

    _view.Icon[UI.Image]:LoadSprite("rankList/"..rankCfg.icon)
    _view.item.Icon[UI.Image]:LoadSprite("rankList/"..rankCfg.icon);

    CS.UGUIClickEventListener.Get(_view.Button.gameObject).onClick = function()
        for i=1,#pids do
            local _pid = pids[i]
            if module.playerModule.IsDataExist(_pid) then
                local _name = module.playerModule.IsDataExist(_pid).name
                SGKTools.FriendChat(_pid,_name,desc)
            else
                module.playerModule.Get(_pid,(function( ... )
                    local _name = module.playerModule.IsDataExist(_pid).name
                    SGKTools.FriendChat(_pid,_name,desc)
                end))
            end

        end
        if func then
            func()
        end
        UnityEngine.GameObject.Destroy(obj);
    end
end

--学会图纸Tip
function SGKTools.LearnedDrawingTipShow(data,func)
    local tempObj = SGK.ResourcesManager.Load("prefabs/Tips/LearnedDrawingTip.prefab")
    local obj = nil;
    local UIRoot = UnityEngine.GameObject.FindWithTag("UITopRoot")
    if UIRoot then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UIRoot.gameObject.transform)
    end
    local TipsRoot = CS.SGK.UIReference.Setup(obj)
    local _view=TipsRoot.Dialog

    local _id=data and data[1]

    local _item=utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,_id);
    utils.IconFrameHelper.Create(_view.Content.IconFrame,{customCfg=setmetatable({count=0},{__index=_item})});
    _view.Content.Image.tip.Text[UI.Text].text=_item.name

    CS.UGUIClickEventListener.Get(_view.Content.Btns.Ensure.gameObject).onClick = function()
        local ManorManufactureModule = require "module.ManorManufactureModule"
        ManorManufactureModule.ShowProductSource(_id)
        if func then
            func()
        end
        UnityEngine.GameObject.Destroy(obj);
    end

    local _DoClosefunc=function()
        if func then
            func()
        end
        UnityEngine.GameObject.Destroy(obj);
    end
    CS.UGUIClickEventListener.Get(_view.Content.Btns.Cancel.gameObject).onClick = _DoClosefunc
    CS.UGUIClickEventListener.Get(TipsRoot.gameObject, true).onClick = _DoClosefunc
    CS.UGUIClickEventListener.Get(_view.Close.gameObject).onClick = _DoClosefunc
end

--获得BuffTip
function SGKTools.GetBuffTipShow(data,func)
    local tempObj = SGK.ResourcesManager.Load("prefabs/Tips/GetBuffTip.prefab")
    local obj = nil;
    local UIRoot = UnityEngine.GameObject.FindWithTag("UITopRoot")
    if UIRoot then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UIRoot.gameObject.transform)
    end
    local TipsRoot = CS.SGK.UIReference.Setup(obj)
    local _view = TipsRoot.view

    CS.UGUIClickEventListener.Get(_view.mask.gameObject, true).onClick = function()
        if func then
            func()
        end
        UnityEngine.GameObject.Destroy(obj);
    end
    local _buffId,_value = data[1],data[2]
    local heroBuffModule = require "hero.HeroBuffModule"
    local buffCfg = heroBuffModule.GetBuffConfig(_buffId)
    if buffCfg then
        if buffCfg.hero_id ~=0 then
            _view.item.Icon[UI.Image]:LoadSprite("icon/" ..buffCfg.hero_id)
        end
        local ParameterConf = require "config.ParameterShowInfo";
        _view.item.Image.Text[UI.Text]:TextFormat("{0}<color=#8A4CC7FF>+{1}</color>", ParameterConf.Get(buffCfg.type).name, _value * buffCfg.value);
    end
end

--通过modeId 检查mode是否存在，不存在则返回默认mode
--path="roles_small/"  or "roles/"  or "manor/qipao/"
--suffix="_SkeletonData" or "_Material"
function SGKTools.loadExistSkeletonDataAsset(path,HeroId,mode,suffix)
    HeroId = HeroId or 11000
    suffix = suffix or "_SkeletonData.asset"
    print("load", path..mode.."/"..mode..suffix)
    local skeletonDataAsset = SGK.ResourcesManager.Load(path..mode.."/"..mode..suffix);
    if skeletonDataAsset == nil then
        local defaultMode = module.HeroHelper.GetDefaultMode(HeroId) or 11000;
        skeletonDataAsset = SGK.ResourcesManager.Load(path..defaultMode.."/"..defaultMode..suffix) or SGK.ResourcesManager.Load(path.."11000/11000"..suffix)
    end
    return skeletonDataAsset
end

--点击显示 Item name
--ori--0(Arrow target Top) 1(Arrow target bottom)
--off_y
function SGKTools.ShowItemNameTip(node,str,ori,off_y)
    local Arrangement={["Top"]=0,["Bottom"]=1}
    local _orientation=ori or Arrangement.Top
    local _off_y=off_y or 0
    local objClone
    CS.UGUIPointerEventListener.Get(node.gameObject, true).onPointerDown = function(go, pos)
        objClone=CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/ClickTipItem.prefab"),node.transform)
        local view=CS.SGK.UIReference.Setup(objClone)
        view.Text[UI.Text].text=str or ""

        view.topArrow:SetActive(_orientation == Arrangement.Top);
        view.bottomArrow:SetActive(_orientation == Arrangement.Bottom);
        if _orientation == Arrangement.Top then
            view[UnityEngine.RectTransform].pivot = CS.UnityEngine.Vector2(0,1);
            view[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(-20,-off_y);
        else
            view[UnityEngine.RectTransform].pivot = CS.UnityEngine.Vector2(0.5, 0);
            view[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,_off_y);
        end
        view:SetActive(true)
        view.transform:DOScale(Vector3.one,0.1):OnComplete(function ( ... )
            view[UnityEngine.CanvasGroup].alpha =  1
        end)
    end
    CS.UGUIPointerEventListener.Get(node.gameObject, true).onPointerUp = function(go, pos)
        if objClone then
            CS.UnityEngine.GameObject.Destroy(objClone)
        end
    end
end

function SGKTools.ShowDlgHelp(desc,title,parent)
    local tempObj = SGK.ResourcesManager.Load("prefabs/base/ShowDlgHelp.prefab")
    local obj = nil;
    local UIRoot = parent or UnityEngine.GameObject.FindWithTag("UITopRoot")
    if UIRoot then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UIRoot.gameObject.transform)
    end
    local TipsRoot = CS.SGK.UIReference.Setup(obj)
    TipsRoot.Dialog.Btn.Text[UI.Text].text = "知道了"
    if desc then
        TipsRoot.Dialog.describe[UI.Text].text = desc
    end
    if title then
        TipsRoot.Dialog.Title[UI.Text].text = title
    end
    TipsRoot.mask[CS.UGUIClickEventListener].onClick = function ( ... )
        UnityEngine.GameObject.Destroy(obj);
    end
    TipsRoot.Dialog.Close[CS.UGUIClickEventListener].onClick = function ( ... )
        UnityEngine.GameObject.Destroy(obj);
    end
    TipsRoot.Dialog.Btn[CS.UGUIClickEventListener].onClick = function ( ... )
        UnityEngine.GameObject.Destroy(obj);
    end
end

function SGKTools.OpenActivityTeamList(Activity_id)
    --showDlgError(nil,"暂无开放")
    local list = {}
    list[2] = {id = Activity_id}
    DialogStack.Push('TeamFrame',{idx = 2,viewDatas = list});
end

function SGKTools.StartActivityMatching(Activity_id)
    local TeamModule = require "module.TeamModule"
    local ActivityTeamlist = require "config.activityConfig"
    if Activity_id then
        local cfg = ActivityTeamlist.Get_all_activity(Activity_id)
        if cfg then
            showDlgError(nil,"正在匹配"..cfg.name)
            TeamModule.playerMatching(Activity_id)
        end
    end
end

function SGKTools.matchingName(name)
    if not name then
        return ""
    end
    if string.len(name) < 12 then
        return name
    end
    local _a = string.sub(name, 1, 5)
    local _b = string.sub(name, -6)
    if _a == "<SGK>" and _b == "</SGK>" then
        return "陆水银"
    end
    return name
end

function SGKTools.PlayDestroyAnim(view)
    if view and utils.SGKTools.GameObject_null(view) == false then

        local _dialogAnim = view:GetComponent(typeof(SGK.DialogAnim))
        if _dialogAnim and utils.SGKTools.GameObject_null(_dialogAnim) == false then
            local co = coroutine.running()
            _dialogAnim.destroyCallBack = function()
                coroutine.resume(co)
            end
            _dialogAnim:PlayDestroyAnim()
            coroutine.yield()
        end
    end
end
local function ROUND(t)
    local START_TIME = 1467302400
    local PERIOD_TIME = 3600 * 24
    return math.floor((t-START_TIME)/PERIOD_TIME);
end

local function random_range(rng, min, max)
    local WELLRNG512a_ = require "WELLRNG512a"
    assert(min <= max)
    local v  = WELLRNG512a_.value(rng);
    return min + (v % (max - min + 1))
end

function SGKTools.GetTeamPveIndex(id)
    local WELLRNG512a_ = require "WELLRNG512a"
    local Time = require "module.Time"
    return random_range(WELLRNG512a_.new(id + ROUND(Time.now())), 1, 4);
end

function SGKTools.GetGuildTreasureIndex(id,index)
    local WELLRNG512a_ = require "WELLRNG512a"
    local Time = require "module.Time"
    return random_range(WELLRNG512a_.new(id + ROUND(Time.now())), 1, index);
end

function SGKTools.GameObject_null(obj)
    if string.sub(tostring(obj), 1, 5) == "null:" then
        return true
    elseif tostring(obj) == "null: 0" then
        return true
    elseif obj == nil then
        return true
    end
    return false
end

function SGKTools.StartTeamFight(gid)
    utils.NetworkService.Send(16070, {nil,gid})
end

function SGKTools.TaskQuery(id)
    local taskConf = require "config.taskConf"
    local quest_id = module.QuestModule.GetCfg(id).next_quest_menu
    return taskConf.Getquest_menu(quest_id)
end

function SGKTools.NpcChatData(pid,desc)
    local ChatManager = require 'module.ChatModule'
    local npcConfig = require "config.npcConfig"
    local cfg = npcConfig.GetnpcList()[pid]
    if cfg then
        ChatManager.SetData({nil,nil,{pid,cfg.name,1},6,desc})
    else
        showDlgError(nil,"npcid->"..gid.."在true_npc表中不存在")
    end
end

function SGKTools.UpdateNpcDirection(npc_id,pid)
    pid = pid or module.playerModule.Get().id
    DispatchEvent("UpdateNpcDirection_playerinfo",{pid = pid,npc_id = npc_id})
end

function SGKTools.ResetNpcDirection(npc_id)
    DispatchEvent("UpdateNpcDirection_npcinfo",{gid = npc_id})
end

function SGKTools.GetQuestColor(iconName, desc)
    if iconName == "bg_rw_1" then
        desc = string.format("<color=#00A99FFF>%s</color>", desc)
    elseif iconName == "bg_rw_2" then
        desc = string.format("<color=#CC7504FF>%s</color>", desc)
    elseif iconName == "bg_rw_3" then
        --desc = string.format("<color=#CC7504FF>%s</color>", desc)
    elseif iconName == "bg_rw_4" then
        desc = string.format("<color=#D75D67FF>%s</color>", desc)
    elseif iconName == "bg_rw_5" then
        desc = string.format("<color=#1371B2FF>%s</color>", desc)
    elseif iconName == "bg_rw_6" then
        desc = string.format("<color=#9118C3FF>%s</color>", desc)
    elseif iconName == "bg_rw_7" then
        desc = string.format("<color=#898E00FF>%s</color>", desc)
    elseif iconName == "bg_rw_8" then
        desc = string.format("<color=#3AA400FF>%s</color>", desc)
    end
    return desc
end
function SGKTools.get_title_frame(str)
    local title = ""
    local num = string.len(str)
    for i = 1,math.floor(num/3) do
        local start = (i-1) * 3 + 1
        if i == 1 then
            title = "<size=44>"..str:sub(start, start + 2).."</size>"
        else
            title = title..str:sub(start, start + 2)
        end
    end
    return title
end
local activityConfig = require "config.activityConfig";
function SGKTools.GetActivityIDByQuest(quest_id)
    return activityConfig.GetActivityCfgByQuest(quest_id);
end

function SGKTools.MapCameraMoveTo(npc_id)
    local controller = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    if not controller then
        return;
    end

    if not npc_id then
        controller:ControllPlayer(module.playerModule.GetSelfID())
    else
        local obj = module.NPCModule.GetNPCALL(npc_id)
        if obj then
            controller:ControllPlayer(0);
            controller.playerCamera.target = obj.transform;
        end
    end
end

--移动相机到目标身上
function SGKTools.MapCameraMoveToTarget(transform)
    local controller = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    if not controller then
        return;
    end
    controller:ControllPlayer(0);
    controller.playerCamera.target = transform;
end

function SGKTools.GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.gameObject.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

function SGKTools.MapCameraMoveTo(npc_id)
    local controller = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    if not controller then
        return;
    end

    if not npc_id then
        controller:ControllPlayer(module.playerModule.GetSelfID())
    else
        local obj = module.NPCModule.GetNPCALL(npc_id)
        if obj then
            controller:ControllPlayer(0);
            controller.playerCamera.target = obj.transform;
        end
    end
end

-- event 1 - 10 已经使用
function SGKTools.MapBroadCastEvent(event, data)
    utils.NetworkService.Send(18046, {nil,{event, module.playerModule.GetSelfID(), data}})--向地图中其他人发送消息
end

function SGKTools.Athome()
    if SceneStack.HomeMapId[SceneStack.MapId()] then
        return true
    end
    return false
end

local containers = {}
function SGKTools.SaveContainers(key, value, default)
    if key == nil then
        return;
    end
    if value ~= nil then
        containers[key] = value;
    elseif default ~= nil and containers[key] == nil then
        containers[key] = default;
    end
    return containers[key];
end

function SGKTools.PlayEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation =rotation and  Quaternion.Euler(rotation) or Quaternion.identity;
        transform.localScale = scale and scale*Vector3.one or Vector3.one
        if layerName then
            o.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            for i = 0,transform.childCount-1 do
                transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            end
        end
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function SGKTools.GetSceneEffect( name )
    if not loadSceneEffectArr[name] then
        return;
    end
    
    if SGKTools.GameObject_null(loadSceneEffectArr[name]) or SGKTools.GameObject_null(loadSceneEffectArr[name][1]) then
        loadSceneEffectArr[name] = nil
        return;
    end
    return true
end

return SGKTools
