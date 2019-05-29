require "utils.init"

local Battle = require "battlefield/Battle"
local Skill = require "battlefield/Skill"
local HeroModule = require "module.HeroModule"
local battle_config = require "config/battle";
local skill_config = require "config/skill";
local ItemHelper = require "utils.ItemHelper"
local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local Thread = require "utils.Thread"
local Time = require "module.Time"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local HeroEvoConfig = require "hero.HeroEvo"
local HeroLevelup = require "hero.HeroLevelup"
local UserDefault = require "utils.UserDefault";
local NetworkService = require "utils.NetworkService"
local OpenLevelConfig = require "config.openLevel"
local fightModule = require "module.fightModule";

local BattlefieldView = {}

SceneService:StartLoading();
local System_Set_data=UserDefault.Load("System_Set_data");
local _WaitForEndOfFrame = function ( ... )
    
end --WaitForEndOfFrame;

local T = {
    FIGHT_START           = 1,
    MONSTER_ENTER         = 2,
    MONSTER_DEAD          = 3,
    PLAYER_READY          = 4,
    CHARACTER_DEAD        = 5,
    PLAYER_FINISHED       = 6,
    FIGHT_FINISHED        = 7,
    PLAYER_COMMAND        = 8,
    KILL_COMMAND          = 9,
    PLAYER_BACK           = 10,
    VOTE_TO_EXIT          = 11,
}

-- FOR DEBUG
-- _WaitForEndOfFrame = function() end
function BattlefieldView:ShowSkillInfoByIndex(index)
    local role = nil;
    if self._current_role and self.roles[self._current_role] then
        role = self.roles[self._current_role].role;
    end

    local skill = nil;
    if role and index then
        skill = role.skill_boxs[index];
    end

    if not skill then
        self.skillInfoPanel[UnityEngine.CanvasGroup].alpha =  0;
        self.skillInfoPanel[UnityEngine.CanvasGroup].interactable = false;
        self.skillInfoPanel[UnityEngine.CanvasGroup].blocksRaycasts = false;
        return;
    end

    local descs = module.TalentModule.GetSkillDetailDes(skill.id, role);
    local desc_str = "";
    for k, desc in ipairs(descs) do
        if desc and desc ~= "" then
            if k ~= 1 then
                desc_str = desc_str .. "\n· ";
            end
            desc_str = desc_str .. string.gsub(string.gsub(desc or "", "【", "<color=red>"), "】", "</color>");
        end
    end

    if index == 11 or index == 12 then
        desc_str = skill.desc
    end

    self.skillInfoPanel.NameText[UnityEngine.UI.Text].text    = skill.name;
    self.skillInfoPanel.Desc[UnityEngine.UI.Text].text        = (desc_str == "" and skill.desc) or desc_str  ;
    self.skillInfoPanel.CDText[UnityEngine.UI.Text]:TextFormat( (skill.skill_cast_cd == 0) and "无" or "{0}回合", skill.skill_cast_cd);
    local consume = skill.property[skill.consume_type];
    self.skillInfoPanel.ConsumeText[UnityEngine.UI.Text]:TextFormat( (consume == 0) and "无" or "{0}", consume);

    self.skillInfoPanel[UnityEngine.CanvasGroup]:DOKill()
    self.skillInfoPanel[UnityEngine.CanvasGroup].alpha = 1;
    self.skillInfoPanel[UnityEngine.CanvasGroup].interactable = true;
    self.skillInfoPanel[UnityEngine.CanvasGroup].blocksRaycasts = true;
end

local function CanvasGroupActive(view, active)
    view[UnityEngine.CanvasGroup].alpha = active and 1 or 0;
    view[UnityEngine.CanvasGroup].interactable = not not active;
    view[UnityEngine.CanvasGroup].blocksRaycasts = not not active;
end

local addon_list = {
    "Test",
    "RandomBuff",
}

function BattlefieldView:ForEachAddon(func)
    for _, v in ipairs(addon_list) do
        local addon = self.addons[v]
        if addon then
            func(addon);
        end
    end
end

function BattlefieldView:ForEachAddonCall(name, ...)
    for _, v in ipairs(addon_list) do
        local addon = self.addons[v]
        if addon and rawget(addon, name) then
            addon[name](...)
        end
    end
end

local function InstantiatePrefab(name, parent, cb)
    SGK.ResourcesManager.LoadAsync(name, function (prefab)
        if not prefab then
            print("load prefab failed", name)
            return;
        end

        local o 
        if parent then
            o = UnityEngine.GameObject.Instantiate(prefab);
        else
            o = UnityEngine.GameObject.Instantiate(prefab, parent);
        end
        if not o then
            print("Instantiate failed", name)
            return
        end

        o.transform.localPosition = Vector3.zero;
        o.transform.localScale = Vector3.one;
        o.transform.localRotation = Quaternion.identity;
        cb(o);
    end)
end

function BattlefieldView:Start()
    DispatchEvent("BATTLE_VIEW_READY");

    self.addons = {}
    self.gameObjectPool =  SGK.GameObjectPoolManager:getInstance();
    self.gameObjectPool =  SGK.GameObjectPoolManager:getInstance();

    local cache = TeamModule.GetTeamFightNotifyCache() or {};
    for _, data in ipairs(cache) do
        self:OnServerFightEvent(table.unpack(data));
    end
end

function BattlefieldView:StartGame(battle_info)
    print("BattlefieldView:Start");

    self.args = battle_info;

    self.force_sync_data = self.args.force_sync_data;

    local this = self;
    if _WaitForEndOfFrame == WaitForEndOfFrame then
        self.preload_co = StartCoroutine(function()
            this:preload(battle_info);
        end)
    else
        this:preload(battle_info);
    end
end

function BattlefieldView:OnDestroy()
    self:ForEachAddonCall("OnDestroy")
    SetTipsState(true)--显示正常物品获得及升级提示
    if self.preload_co then
        StopCoroutine(self.preload_co);
    end
    self.destroyed = true

    self.gameObjectPool:Clear();
end

function BattlefieldView:listEvent()
    return {
        "TEST_EVENT",
        "BATTLE_VIEW_START_WITH_FIGHT",
        "FIGHT_CHECK_RESULT",
        "FIGHT_DATA_SYNC",
        "ADD_OBJECT_TO_FIGHT_RESULT",
        "FIGHT_RESULT_RECORD",
        "FIGHT_RESULT_REPLAY",
        "server_notify_60",
        "HeroExpInfoChange",
        "TEAM_QUERY_NPC_REWARD_REQUEST",
        "Roll_Query_Respond",
        "LOCAL_GUIDE_CHANE",
        "LOCAL_FIGHTBTN_FIGHT_CLOSE",
        "FIGHT_FIALED",
        "ADD_BASE_COUNTDOWN"
    }
end

function BattlefieldView:onEvent(event, ...)
    if event == "BATTLE_VIEW_START_WITH_FIGHT" then
        self:StartGame(...);
    elseif event == "FIGHT_CHECK_RESULT" then
        local winner, rewards = ...;
        self:AppendRewards(rewards);
        if self.waiting_for_result then
            self.waiting_for_result = false;
            self:ShowReward(winner)
        end
    elseif event == "FIGHT_DATA_SYNC" then
        self:OnServerFightEvent(...);
    elseif event == "HIDE_PARTNER" then
        local stringValue, intValue, floatValue, boolValue = select(1, ...)

        local followCamera = self.view.battle.partnerStage[CS.FollowCamera];
        if boolValue then
            followCamera.enabled = false;
            self.view.battle.partnerStage.gameObject.transform.position = Vector3(0, 0, -1000);
        else
            followCamera.enabled = true;
        end
        CanvasGroupActive(self.view.battle.Canvas, not boolValue);
    elseif event == "ADD_OBJECT_TO_FIGHT_RESULT" then
        local obj = select(1, ...)
        print("ADD_OBJECT_TO_FIGHT_RESULT", obj)
        self.result_panel_game_object = obj;
        self:ActiveResultObject();
    elseif event == "FIGHT_RESULT_RECORD" then
        self:OnRecordClick();
    elseif event == "FIGHT_RESULT_REPLAY" then
        self:OnNextFightClick();
    elseif event == "server_notify_60" then
        self:OnNotifyFightReward(...)
    elseif event == "HeroExpInfoChange" then
        local ExpData=...
        self.HeroExpInfoList=self.HeroExpInfoList or {}
        self.HeroExpInfoList[ExpData[1]] = ExpData[2]
        self:UpdateStarView();
    elseif event == "TEAM_QUERY_NPC_REWARD_REQUEST" then
        local data = ...
        self.ShowExtraSpoilsData = #data.reward_content > 0
        if self:NeedSyncData() then
            if self.result_panel_used and self.result_panel_used[SGK.LuaBehaviour] then
                self.result_panel_used[SGK.LuaBehaviour]:Call("UpdatePubRewardData",{self.ShowExtraSpoilsData,self.ShowRollData})
            end
        end
    elseif event == "Roll_Query_Respond" then
        self.ShowRollData = true
    elseif event == "LOCAL_GUIDE_CHANE" then
        if ... ~= nil then
            local id = select(1, ...)
            if not self.battle_guide_list then self.battle_guide_list = {} end
            if not self.battle_guide_list[id] then
                self.game:Dispatch("BATTLE_GUIDE_CHANE", ...)
                self.battle_guide_list[id] = true
            end
        end
        module.guideModule.PlayByType(7)
        module.guideModule.PlayByType(70)
    elseif event == "LOCAL_FIGHTBTN_FIGHT_CLOSE" then
        self:assitButton_click() 
    elseif event == "FIGHT_FIALED" then
        TeamModule.SyncFightData(T.VOTE_TO_EXIT, {1});
    elseif event == "ADD_BASE_COUNTDOWN" then
        DialogStack.PushPref("activity/ProtectBaseCountdown",{uuid = ...}, self.view.battle.Canvas.RoundInfo);
    end
end

local function loadStarDesc(key, value1, value2)
    local _value1 = value1
    local _value2 = value2
    if key == 6 then    ---技能
        if value1 ~= 0 then
            _value1 = module.fightModule.GetDecCfgType(tonumber(value1))
        end
    elseif key == 7 or key == 8 then ---怪物
        if value1 ~= 0 then
            _value1 = battle_config.LoadNPC(_value1).name
        end
        if key ~= 8 then
            if value2 ~= 0 then
                _value2 = battle_config.LoadNPC(value2).name
            end
        end
    end
    return string.format(module.fightModule.GetStarDec(key) or "星星条件 " .. tostring(key)  .. " 不存在", _value1, _value2)
end

function BattlefieldView:OnNotifyFightReward(_, info)
    local type, rewards = info[1], info[2];   
    self:AppendRewards(rewards)
end

function BattlefieldView:AppendRewards(rewards)
    self.saved_rewards = self.saved_rewards or {};

    for _, v in ipairs(rewards or {}) do
        table.insert(self.saved_rewards, v);
    end

    if self.result_panel_used and self.result_panel_used[SGK.LuaBehaviour] then
        self.result_panel_used[SGK.LuaBehaviour]:Call("UpdateReward", self.saved_rewards)
    end
end

function BattlefieldView:UpdateStarView()
    if self:NeedSyncData() then
        return;
    end

--[[
    if not self.fight_result_is_win then
        return;
    end
    --]]

    if self.result_panel_used then
        local info = self:GetStarInfo(true);
        if #info > 0  and not self.showStar then
        	self.showStar = true
            self.result_panel_used[SGK.LuaBehaviour]:Call("SetResultType",{{info,self.fight_data.star,self.saved_rewards,self.game.statistics.partners,self.HeroExpInfoList}})
        end  
    end
    return true
end

function BattlefieldView:ShowReward(winner)
    print("BattlefieldView:ShowReward", winner, self.result_panel_game_object)
    local win = (winner == 1);

    self.exit_left = 15;
    self.view.battle.partnerStage:SetActive(false);
    self.view.battle.Canvas.timelinePanel:SetActive(false)
    self.view.battle.Canvas.TopRight:SetActive(false);
    self.view.battle.Canvas.EnemyBossUISlot:SetActive(false);
    self.view.battle.Canvas.RoundInfo:SetActive(false);
    self.view.battle.Canvas.UIRootTop:SetActive(false);

    if self.dialog_view then
        self.dialog_view:SetActive(false);
    end

    
    local panel = self.result_panel_used or SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/fightResult/FightResultFrame"));
    panel.transform:SetParent(self.view.battle.Canvas.UIRoot.transform, false);
    panel[SGK.LuaBehaviour]:Call("Init",{winner,self.args})
    if win then -- and self.fight_result_with_score then
        self.fight_result_is_win = true;
        if self.view.battle.Canvas.UIRoot.TeamCombatStatus then
            self.view.battle.Canvas.UIRoot.TeamCombatStatus:SetActive(false);
        end

        if self.fight_result_with_score and not self.showScore then
            self.showScore = true
            panel[SGK.LuaBehaviour]:Call("SetResultType",{self.fight_result_with_score,true})
        end     
        panel[SGK.LuaBehaviour]:Call("UpdateReward",self.saved_rewards)
    else
        if self.game.timeline:IsFailedByRoundLimit() then
            panel.FailedInfo:SetActive(true);
        end 
    end

    self.result_panel_used = panel;
    self:UpdateStarView()
    self:ActiveResultObject();
end

function BattlefieldView:ActiveResultObject()
    if self.result_panel_game_object and self.result_panel_used  and not self.AddedObject then
        self.AddedObject = true
        self.result_panel_used[SGK.LuaBehaviour]:Call("AddResultObject",self.result_panel_game_object)
    end
end

local function updateCharacterIcon(icon, role)
    if icon then
        local cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO,role.id)       
        utils.IconFrameHelper.Create(icon,
            {customCfg =
                {
                    icon = tostring(role.icon),
                    level = role.level,
                    role_stage = cfg.role_stage,
                    star = role.grow_star,
                    type=utils.ItemHelper.TYPE.HERO,
                }
            })
    end
end

function BattlefieldView:OnExitClick()
    SceneStack.Pop();
end

function BattlefieldView:EXIT_FIGHT()
    SceneStack.Pop();
end

function BattlefieldView:OnRecordClick()
    self.exit_left = 99999;
    --local panel = self.view.battle.Canvas.StatisticsPanel or SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/battlefield/StatisticsPanel"));
    local panel = self.view.battle.Canvas.StatisticsPanel or SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/fightResult/StatisticsFrame"));
    panel.transform:SetParent(self.view.battle.Canvas.UIRoot.transform, false);
    panel.transform:SetAsLastSibling();
    self.view.battle.Canvas.StatisticsPanel = panel;

    panel:SetActive(true);

    panel.Damage[UnityEngine.UI.Toggle].isOn = true;
    --单人
    local list = {}
    for _, v in pairs(self.game.statistics.partners) do
        if v.role.pos < 100 then
            table.insert(list, v);
        end
    end

    table.sort(list, function(a,b)
        return a.role.pos < b.role.pos;
    end)

    local _partners = list
    --多人战斗
    if self:NeedSyncData() and self.fight_result_with_score then
        local _list = {}
        --[[--临时数据
            小队每个 成员 hero的 Icon,lv,
            local partner = {pid,heros={{id,icon,lv,damage,hurt,health},{}}
            local _partners = {partner1,partner2,partner...}
        --]]

        for _,v in pairs(self.fight_result_with_score) do
            table.insert(_list,{pid=v[1],heros={},damage=v[3],hurt=v[3],health=v[3]})
        end 
        _partners = _list
    end
    if next(_partners)~=nil then
        panel[SGK.LuaBehaviour]:Call("updateStatisticsPanel",{_partners,self:NeedSyncData()});
    end
end

--[[
local function ui_reader(view)
    return function(role)
        view:UNIT_INPUT(role,);
    end
end
--]]

function BattlefieldView:CallRoleAction(uuid, action, ...)
    local info = self.roles[uuid];
    if info and info.script then
        local func = info.script[action];
        if func then
            func(info.script, ...);
        end
    end
end

function BattlefieldView:NeedSyncData()
    return self.force_sync_data or (self.shared_object and next(self.shared_object))
end

local FIGHT_DATA_FROM_SERVER = true;
if UnityEngine.Application.isEditor then
    FIGHT_DATA_FROM_SERVER = true;
    if CS.System.IO.File.Exists("D:/sgk_local_fight_data.txt") then
        FIGHT_DATA_FROM_SERVER = false;
    end
end

local function loadLocalFightData(fight_id)
    local fight_data = {
        id = fight_id,
        attacker = {
            pid = playerModule.GetSelfID();
            roles = {

            }
        },

        defender = {
            pid = fight_id,
            roles = {
                
            }
        },
        seed = os.time(),
    }
    local skill_config = {}
    DATABASE.ForEach("weapon", function(data)
        skill_config[data.id] = data
    end)

    local game_data = battle_config.load(fight_id);
    local ref = 0;
    for i = 1, 5 do
        local hero = HeroModule.GetManager():GetByPos(i);
        
        if hero then
            ref = ref + 1;
            local propertys = {}

            for k, v in pairs(hero.property_list) do
                table.insert(propertys, {type = k, value = v });
            end

            table.insert(fight_data.attacker.roles, {
                refid = ref,
                id = hero.id,
                level = hero.level,
                pos = i,
                wave = 1,
                mode = hero.mode,
                skills = {
                    skill_config[hero.weapon_id].skill0,
                    skill_config[hero.weapon_id].skill1,
                    skill_config[hero.weapon_id].skill2,
                    skill_config[hero.weapon_id].skill3,
                    skill_config[hero.weapon_id].skill4
                },
                x = 0,
                y = 0,
                z = 0,
                propertys = propertys,
            });
        end
    end

    for k, round in ipairs(game_data.rounds) do
        for _, v in pairs(round.enemys) do
            ref = ref + 1;

            local propertys = {}
            for k, v in pairs(v.property_list) do
                table.insert(propertys, {type = k, value = v });
            end

            table.insert(fight_data.defender.roles, {
                refid = ref,
                id = v.id,
                level = v.level,
                pos = v.pos or v.role_pos,
                wave = k,
                mode = v.mode,
                share_mode = v.share_mode or 0,
                skills = {
                    v.skills[1] and v.skills[1].id or 0, 
                    v.skills[2] and v.skills[2].id or 0, 
                    v.skills[3] and v.skills[3].id or 0, 
                    v.skills[4] and v.skills[4].id or 0, 
                    v.enter_script and v.enter_script or 0
                },
                x = v.x or 0,
                y = v.z or 0,
                z = v.y or 0,

                propertys = propertys,
            });
        end
    end

    local fightModule = require "module.fightModule";
    local cfg = fightModule.GetPveConfig(fight_id);
    fight_data.star = {}

    fight_data.fight_type = cfg and cfg.fight_type or 0;
    fight_data.win_type = cfg and cfg.win_type or 0;
    fight_data.win_para = cfg and cfg.win_para or 0;

    if not cfg then
        fight_data.scene = "18hao";
    else
        fight_data.scene = cfg.scene_bg_id;

        if cfg.star1_type ~= 0 then
            table.insert(fight_data.star, {
                type = cfg.star1_type,
                v1 = cfg.star1_para1,
                v2 = cfg.star1_para2,
            })
        end

        if cfg.star2_type ~= 0 then
            table.insert(fight_data.star, {
                type = cfg.star2_type,
                v1 = cfg.star2_para1,
                v2 = cfg.star2_para2,
            })
        end
    end

    return fight_data;
end


local battle_scene_data = utils.UserDefault.LoadSessionData("battle_scene_data");

function BattlefieldView:LoadAddon(name, game)
    self.addonFunctions = self.addonFunctions or {}

    local skip = {
        Start=true, Preload=true, OnDestroy = true, Update = true,
    }

    local env = setmetatable({
        root = self,
        game = game,
        name = name,
        WaitForEndOfFrame = function() self:WaitForEndOfFrame()        end,
        print = function(...) print(string.format("[%s] ", name), ...) end,
        Load = function(...) return SGK.ResourcesManager.Load(...)     end,
        LoadAsync = function(...) SGK.ResourcesManager.LoadAsync(...)  end,
        ADDON = setmetatable({}, {__index=function(t, k) return self.addons[k]; end}),
        DispatchEvent = function(...) self.game.eventManager:dispatch(...) end;
        API = {},
        EVENT = {},
    }, {__index=function(t, k)
        if self.addonFunctions[k] then
            return self.addonFunctions[k];
        end
        return _G[k];
    end, __newindex=function(t, k, v)
        if not skip[k] and type(v) == "function" then
            self.addonFunctions[k] = v;
        end
        rawset(t, k, v);
    end});

    ERROR_LOG('LoadAddon');
    local func, message = loadfile("view/battle/addons_a/" .. name .. ".lua", "bt", env)
    if not func then
        if UnityEngine and UnityEngine.Application.isEditor then
            showDlgError(nil, "addon " .. name .. " load failed");
        end
        ERROR_LOG(message)
        return;
    end

    func();

    self.addons[name] = env;
end

function BattlefieldView:preload(battle_info)
    self.wait_for_loading = true;

    local fight_id = battle_info.fight_id;

    battle_info.round_timeout = battle_info.round_timeout or {}
    battle_info.hero_timeout = battle_info.hero_timeout or {}

    self.round_timeout = battle_info.round_timeout[1] or 999;
    self.hero_timeout  = battle_info.hero_timeout[1] or 999;

    if battle_info.fight_data and (FIGHT_DATA_FROM_SERVER or (self.arg and self.args.force_sync_data)) then
        self.fight_data = ProtobufDecode(battle_info.fight_data, "com.agame.protocol.FightData")
    else
        -- for debug
        print("<color=red>local fight data</color>");
        self.fight_data = loadLocalFightData(fight_id)
    end

    print("BattlefieldView:preload", self.fight_data.id, string.len(battle_info.fight_data or ""));

    -- load env
    DispatchEvent("LOADING_PROGRESS_UPDATE", 0.05, "加载战斗场景");

    _WaitForEndOfFrame()

    local preloadClass = {
        SGK.BattleCameraScriptAction,
        CS.NumberMovement,
        SGK.BattleCameraScriptAction,
        SGK.BattlefieldEventDispatcher,
        SGK.BattlefieldObjectAssistant,
        SGK.BattlefieldObjectEnemy,
        SGK.BattlefieldObjectPartner,
        SGK.BattlefieldObjectPet,
        SGK.BattlefieldObjectWithBar,
        SGK.BattlefieldSkillButton,
        SGK.BattlefieldTimelineItem,
        SGK.BattlefieldTimeout,
        SGK.BattlefiledHeadManager,
        CS.FollowTarget,
        CS.UGUISpriteSelector,
    }

    if not UnityEngine.GameObject.FindWithTag("battle_env") then
        local sceneName = self.fight_data.scene;
        if not self.fight_data.scene or self.fight_data.scene == "" then
            sceneName = "18hao";
        end

        -- SGK.BackgroundMusicService.PlayBattleMusic(sceneName);

        InstantiatePrefab("prefabs/battlefield/environment/" .. sceneName, function (env)
            env.name = sceneName;
        end)
    else
        -- SGK.BackgroundMusicService.PlayBattleMusic('default');
    end

    self.view = {battle = SGK.UIReference.Setup("battle_root")};
    
    local battle = self.view.battle.gameObject;
    rawset(self.view.battle, "transform", self.view.battle.gameObject.transform);

    self.partner_data_decode = {}
    for k, code in ipairs(self.args.partner_data or {}) do
        self.partner_data_decode[k] = ProtobufDecode(code, "com.agame.protocol.FightPlayer")
    end

    if #self.partner_data_decode > 0 then
        local members = { {pid = self.fight_data.attacker.pid, name = self.fight_data.attacker.name} }
        for _, v in ipairs(self.partner_data_decode) do
            table.insert(members, {pid = v.pid, name = v.name});
        end
        DialogStack.PushPref("TeamLoadFrame",{members = members}, self.view.battle.Canvas.gameObject)
    end

    -- find objects in scene
    DispatchEvent("LOADING_PROGRESS_UPDATE", 0.1, '设置场景')
    _WaitForEndOfFrame()
    self:SetupButton()
    self:FindSceneGameObject();

    -- move battle to target
    DispatchEvent("LOADING_PROGRESS_UPDATE", 0.15, "设置场景")
    _WaitForEndOfFrame()
    local anchor = UnityEngine.GameObject.FindWithTag("battle_anchor");
    if anchor then
        DispatchEvent("LOADING_PROGRESS_UPDATE", 0.15, "find anchor")
        -- battle.transform.position = anchor.transform.position;
        CS.FollowTarget.Follow(self.view.battle.gameObject, anchor, -1, true);

        self.battle_anchor_animator = anchor:GetComponent(typeof(UnityEngine.Animator));
        --if string.sub(tostring(self.battle_anchor_animator), 1, 5) ~= "null:" then
        if utils.SGKTools.GameObject_null(self.battle_anchor_animator) == false then
            -- self.battle_anchor_animator:SetInteger("Wave", 1);
        else
            self.battle_anchor_animator = nil;
        end
        self.battle_anchor_animator = nil;
    end

    -- load fight config
    DispatchEvent("LOADING_PROGRESS_UPDATE", 0.2, "加载战斗配置")
    _WaitForEndOfFrame()
    _WaitForEndOfFrame()

    local pid = nil;
    if battle_info.force_play_as_attacker then
        pid = self.fight_data.attacker.pid
    else
        pid = playerModule.GetSelfID()
    end

    local game = Battle(self.fight_data, pid);

    self.game = game;
    self.fight_id = fight_id;

    self.roles = {}
    self.pets = {};

    self.input_heros = {}

    -- load addons
    ERROR_LOG("!!!!!!!!!!!!!!!!!!!!!!!!!! 222222222")
    for _, v in ipairs(addon_list) do
        self:LoadAddon(v, self.game);
    end

    self:ForEachAddonCall("Preload")

    self:ForEachAddon(function(addon)
        for name, func in pairs(addon.EVENT) do
            self.game.eventManager:addListener(name, func);
        end
    end)

    -- preload mode and effect
    local n, r, ln = 0, 0, 0;
    DispatchEvent("LOADING_PROGRESS_UPDATE", 0.2, "加载战斗资源")
    _WaitForEndOfFrame()

    local preload_effect_list = {};

    self.partner_sorting_order = {}
    for k, v in pairs(self.fight_data.attacker.roles) do
        n = n + 1;

        --[[
        local list = battle_config.GetPreloadEffectList(v.id);
        for _, v in ipairs(list) do
            if not preload_effect_list["prefabs/effect/" .. v] then
                preload_effect_list["prefabs/effect/" .. v] = 1;
                n = n + 1;
            end
        end
        --]]

        local _, _, order = battle_config.GetModeFlip(v.mode, 1, v.pos);
        self.partner_sorting_order[v.mode] = order;
    end

    local list = {}
    for k, v in pairs(self.partner_sorting_order) do
        table.insert(list, {mode = k, order = v})
    end

    table.sort(list, function(a, b)
        if a.order == b.order then return a.mode < b.mode end
        return a.order < b.order;
    end)

    self.partner_sorting_order = {}
    local last_order, new_order = nil, 0;
    for k, v in ipairs(list) do
        if v ~= last_order then
            last_order = v;
            new_order = new_order + 1;
        end
        self.partner_sorting_order[v.mode] = new_order;
    end

    local max_wave = {};
    for k, v in pairs(self.fight_data.defender.roles) do
        n = n + 1;

        --[[
        local list = battle_config.GetPreloadEffectList(v.id);
        for _, ev in ipairs(list) do
            if not preload_effect_list["prefabs/effect/" .. ev] then
                preload_effect_list["prefabs/effect/" .. ev] = 1;
                n = n + 1;
            end
        end
        --]]
        max_wave[v.wave] = true;
    end

    self.max_wave = #max_wave;

    local function update_loading_info(info)
        r = r + 1;
        if r > n then
            r = n
        end;
        DispatchEvent("LOADING_PROGRESS_UPDATE", 0.2 + (r / n) * 0.7, info .. " " .. r .. "/" .. n);  _WaitForEndOfFrame();
    end

    DATABASE.Load("skillshow");
    DATABASE.Load("skill_music");

    preload_effect_list["prefabs/effect/UI/fx_death"] = 1;
    preload_effect_list["prefabs/battlefield/health_normal"] = 5;
    preload_effect_list["prefabs/battlefield/hurt_normal"] = 5;
    preload_effect_list["prefabs/effect/UI/fx_butten"] = 5;
    preload_effect_list["prefabs/effect/UI/fx_jues_act"] = 1;

    if self.fight_data.attacker.assists and #self.fight_data.attacker.assists > 0 then
        preload_effect_list["prefabs/effect/UI/fx_yuanzhu"] = 1;
    end

    if #max_wave > 1 then
        self.gameObjectPool:Prepare("prefabs/effect/UI/fx_sence_hei", 0);
    end

    local attacker_roles = {};

    local attacker, defender =  self.fight_data.attacker, self.fight_data.defender
    if pid == self.fight_data.defender.pid then
        self.work_as_defender = true;
        attacker, defender =  self.fight_data.defender, self.fight_data.attacker
    end
   
    for k, v in ipairs(attacker.roles) do
        table.insert(attacker_roles, v);
    end
    table.sort(attacker_roles, function(a,b) return a.pos < b.pos; end)

    local position_per_def = {
        {3},
        {2,4},
        {1,3,5},
        {1,2,3,4},
        {1,2,3,4,5},
    }

    -- local start_pos = ({2, 1, 1, 0, 0})[#attacker_roles] or 0;
    local positions = position_per_def[#attacker_roles];
    for k, v in ipairs(attacker_roles) do
        v.pos = positions[k];
        self.view.partner_objects[v.pos]:SetActive(true);
    end

    self.partner_show_mask = (#attacker_roles >= 4)
    if self.partner_show_mask then  self.partner_sorting_order = {}  end

    if self.args then
        self.args.fastforward = nil;
    end

    local always_show_role = nil;
    local this = self;
    local attacker_roles_info = {heros = {}};
    for k, v in ipairs(attacker.roles) do
        update_loading_info("加载角色");
        local role = self.game:AddRoleByRef(v.refid, 0);
        if role and not self.args.fastforward then
            self:CreateRole(role);
        end

        if role then
            local stageCfg = HeroEvoConfig.GetConfig(role.id);
            local cfg = stageCfg and stageCfg[role.grow_stage];
            local quaity = cfg and cfg.quality or 1;

            table.insert(attacker_roles_info.heros, {
                icon = role.icon,
                level = role.level,
                star = role.star,
                quality = quaity,
                refid = role.refid,
                sync_id = role.sync_id,
            })
        end

        if role then
            if #attacker_roles == 1 then
                self.always_show_role_id = role.id;
                always_show_role = role;
            end

            for _, v in ipairs(role.skill_boxs) do
                preload_effect_list[tostring(v.icon)] = 0;
            end
        end

        --[[
        local sounds = skill_config.GetSoundConfig(role.id);
        for _, v in ipairs(sounds) do
            preload_effect_list[v] = 0;
        end
        --]]
    end

    for k, v in ipairs(defender.roles) do
        update_loading_info("加载角色");
        local role = self.game:AddRoleByRef(v.refid, 0);
        if role and not self.args.fastforward and role.wave == 1 then
            self:CreateRole(role);
        end

        if v.pos == 11 then
            preload_effect_list["prefabs/battlefield/battle_warning"] = 1;
        end
    end

    for k, v in ipairs(attacker.assists or {}) do
        self.game:AddRoleByRef(v.refid);
    end

    for k, v in pairs(preload_effect_list) do
        update_loading_info("加载特效")
        self.gameObjectPool:Prepare(k, v);
    end

    self:UpdateSharedObject();

    print("BattlefieldView:preload done");

    self.view.battle.Canvas.roundTips.gameObject:SetActive(false);
    self.view.battle.Canvas.TopRight:SetActive(not battle_info.guideFight)

    if battle_info.guideFight then
        self.auto_input = false
        self:SetAutoInput(false)
    end
    
    if battle_info.worldBoss or battle_info.rankJJC then
        self:SetAutoInput(true)
        self.view.battle.Canvas.TopRight.recordButton:SetActive(false)
        self.view.battle.Canvas.TopRight.autoButton:SetActive(false)
    end
    if battle_info.rankJJC then--排位JJc 没有撤退
        self.view.battle.Canvas.TopRight.assitButton:SetActive(false)
    end

    print("BattlefieldView game start");

    local not_enter_script = false;

    if self.args.commandQueue then
        local commandQueue = self.args.commandQueue;
        if type(commandQueue) == "string" then
            commandQueue = ProtobufDecode(commandQueue, "com.agame.protocol.FightCommand").commands;
        end

        ERROR_LOG("push command queue", #commandQueue);

        for _, v in ipairs(commandQueue) do
            self.waiting_cmd_queue_item = v;
            ERROR_LOG("push command queue", v.type, v.tick, v.s_index);
            if v.skill == 99036 then
                if v.pid == self.game.pid then
                    self:SetAutoInput( v.target == 1, true )
                end
            elseif v.skill >= 99000 then
                -- no thing to do
            else
                self.game.commandQueue:Push(v);
            end
        end
    end

    if self.args.partner_data and #self.args.partner_data > 0 then
        if self.args.partner_data and #self.args.partner_data > 1 then -- 三人以上队伍才压缩到一半操作界面
            self.view.battle.partnerStage.slotCard[UnityEngine.Animator]:SetBool("half", true);
            self.view.battle.partnerStage.slotCard[1].partner[SGK.BattlefieldObjectPartner].half = true;
            self.view.battle.partnerStage.slotCard[2].partner[SGK.BattlefieldObjectPartner].half = true;
            self.view.battle.partnerStage.slotCard[3].partner[SGK.BattlefieldObjectPartner].half = true;
            self.view.battle.partnerStage.slotCard[4].partner[SGK.BattlefieldObjectPartner].half = true;
            self.view.battle.partnerStage.slotCard[5].partner[SGK.BattlefieldObjectPartner].half = true;
        end

        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/TeamMembers", function(prefab)
            local TeamMembers = SGK.UIReference.Instantiate(prefab)
            TeamMembers.transform:SetParent(self.view.battle.partnerStage.TeamSlot.Canvas.transform, false);
            self.view.TeamMembers = TeamMembers;

            self.view.TeamMembers[SGK.LuaBehaviour]:Call("AddMember", self.game.pid, attacker_roles_info.heros);

            for _, info in ipairs(self.partner_data_decode or {}) do
                local heros = {}
                for _, v in ipairs(info.roles) do
                    local stageCfg = HeroEvoConfig.GetConfig(v.id);
                    local cfg = stageCfg and stageCfg[v.grow_stage];
                    local quaity = cfg and cfg.quality or 1;
        
                    table.insert(heros, {
                        icon = v.mode,
                        level = v.level,
                        star = v.grow_star,
                        quality = quaity,
                        refid = v.refid,
                        sync_id = 0,
                    })
                end
                self.view.TeamMembers[SGK.LuaBehaviour]:Call("AddMember", info.pid, heros);
            end
        end);
    end

    if self:NeedSyncData() then
        self.game.commandQueue:AddWatcher(function(cmd)
            self:RecordCommandQueue(cmd)
        end)
    end

    _WaitForEndOfFrame();

    local function clean_cached_team_event_queue()
        if self.team_event_queue then
            local queue = self.team_event_queue;
            self.team_event_queue = nil;
            for _, v in ipairs(queue) do
                self:OnServerFightEvent(v[1], v[2])
            end
        end
    end

    if self.args.fastforward and self.args.fastforward.tick and self.args.fastforward.tick > 0 then
        self:ForEachAddonCall("Start")
        game:Start();

        print("play module start")

        local i = 0;
        while i < 600 and  self.game.timeline.tick < self.args.fastforward.tick do
            clean_cached_team_event_queue();

            self.game:Update(1);
            i = i + 1;
        end

        print("play module finished", self.game.timeline.tick)
        not_enter_script = true;

        local role = self.game.timeline[1];
        if role and role.reading then
            self:UNIT_INPUT(role);
        end
    end

    self.args.fastforward = nil;
    self.waiting_cmd_queue_item = nil;

    for k, v in ipairs(self.game.timeline) do
        self:CreateRole(v, not_enter_script);
        
        if v[7015] == 0 then
            self.timeline:Set(k, tostring(v.uuid), v.icon, v.side == 1)
        end
    end

    if self.args and self.args.is_replay then
        self.view.battle.Canvas.TopRight.nextButton.nameText:TextFormat("退出");
    end

    -- add listener
    local this = self;
    game:Watch('*', function(event, ...)
        local func = this[event];
        if func then
            func(this, ...)
        else
            -- print("!!! EVENT !!!", event, ...);
        end
    end);

    DispatchEvent("LOADING_PROGRESS_UPDATE", 1, '进入战斗');
    _WaitForEndOfFrame();

    if not not_enter_script then
        SceneService:FinishLoading();
        self:ForEachAddonCall("Start")
        game:Start();
    end

    if self:NeedSyncData() then
        TeamModule.SyncFightData(T.PLAYER_READY, true); -- 战斗已经准备好
    end

    if self:NeedSyncData() and self.game.timeline.winner == 1 and not self.waiting_cmd_queue_item then
        TeamModule.SyncFightData(T.MONSTER_ENTER, 0); -- 首次招怪
    end

    if battle_info.ui then
        battle_info.ui.transform:SetParent(self.view.battle.Canvas.UIRoot.transform, false);
    end

    DispatchEvent("LOADING_PROGRESS_DONE");

    --[[
    if _WaitForEndOfFrame == WaitForEndOfFrame then        
        WaitForSeconds(1);
    end
    --]]

    DispatchEvent("BATTLE_SCENE_READY");

    if self.team_event_queue then
        ERROR_LOG("team_event_queue count", #self.team_event_queue);
    end

    clean_cached_team_event_queue();

    if self.server_notify_fight_finished_with_winner then
        return;
    end

    self.wait_for_loading = nil;

    self.timeline:Fastforward();
    self.view.battle[UnityEngine.Animator]:SetBool("enter", true);

    self.view.battle.Canvas.RoundInfo:SetActive(self.game.timeline.total_round > 0);
    if self.game.timeline.win_round_limit then
        self.Round_Type = 1
    elseif self.game.timeline.failed_round_limit and self.game.timeline.failed_round_limit < 20 then
        self.Round_Type = 2
    else
        self.Round_Type = 0
    end
    self.view.battle.Canvas.RoundInfo.Image[CS.UGUISpriteSelector].index = self.Round_Type;

    --[[if self:NeedSyncData() then
        local team_info = TeamModule.GetTeamInfo()
        if team_info.leader then
            local pid = playerModule.GetSelfID()
            local leader_id = team_info.leader.pid
            if pid == leader_id then
                self.Button_Command.detail.buttons.button_2:SetActive(true)
                self.Button_Command.detail.buttons.button_3:SetActive(true)
                self.Button_Command:SetActive(true)
            end
        end  
    else
        self.Button_Command.solo_fight = true
    end]]

    -- SGK.ResourcesManager.SHOW_WARNING = true;
    -- DialogStack.PushPref("CurrencyChat",{Type = 1}, self.view.battle.Canvas.UIRootTop);
    if always_show_role then
        self:ShowPartner(always_show_role);
    end

    local timeout;
    if battle_info.round_timeout[2] then
        timeout = battle_info.round_timeout[2] - module.Time.now();
        if timeout < 0 then timeout = 0; end
    end

    if battle_info.hero_timeout[2] then
        timeout = battle_info.hero_timeout[2] - module.Time.now();
        if timeout < 0 then timeout = 0; end
    end

    if timeout then
        self:StartTimeCounting(timeout)
    elseif battle_scene_data.auto_input then
        self.auto_input_time = os.time() + 3;
    end

    if self.server_notify_fight_finished_with_winner then
        self:ShowReward(self.server_notify_fight_finished_with_winner)
    end
end

function BattlefieldView:RecordCommandQueue(cmd)
    if cmd.type == "MONSTER_HP_CHANGE" then
        if cmd.pid ~= 0 and cmd.value < 0 then
            DispatchEvent("Player_Accumulative_Harm", {pid=cmd.pid, value=-cmd.value});
        end

        if cmd.pid ~= self.game.pid then
            local role = self.game:GetRole(nil, cmd.refid, cmd.sync_id);
            if role then
                local name = "";
                if cmd.pid ~= 0 then
                    local player = module.playerModule.Get(cmd.pid);
                    if cmd.value < 0 then
                        self:UnitShowNumber(role, -cmd.value, "hitpoint",  "hurt_others", player and player.name or "")
                    else
                        self:UnitShowNumber(role, cmd.value, "hitpoint",  "health_others", player and player.name or "")
                    end
                end
            end
        end
    elseif cmd.type == "PLAYER_STATUS_CHANGE" then
        DispatchEvent("Player_Hero_Status_Change", {pid=cmd.pid, value=cmd.value, target=cmd.target});
        if cmd.target == 0 and cmd.pid ~= 0 and cmd.value == 1 then
            DispatchEvent("TeamLoadSlidingArea",{pid = cmd.pid,SlidingArea = 100})
        end
    end
end
--]]
function BattlefieldView:Update()
    -- local profiler = require "perf.profiler"
    -- profiler.start();

    if self.game and not self.wait_for_loading then

        self.game:Update(UnityEngine.Time.deltaTime);
        self:ForEachAddonCall("Update", UnityEngine.Time.deltaTime)

        for _, v in ipairs(self.game.timeline) do
            if v.UNIT_PropertyChange then
                v.UNIT_PropertyChange = false;
                self:UpdateObjectPropertyValue(v)
            end
        end

        self:ChatRef();
    end

    if self.auto_input_time then
        if os.time() <= self.auto_input_time then
            self.view.battle.Canvas.TopRight.autoButton.nameText[UnityEngine.UI.Text]:TextFormat("{0}", self.auto_input_time - os.time());
        elseif not self.auto_input then
            self:SetAutoInput(true);
            self.auto_input_time = nil;
        end
    end

    if self.current_press_skill_button_time and UnityEngine.Time.realtimeSinceStartup - self.current_press_skill_button_time >= self.skill_button_press_timeout then
        self:ShowSkillInfoByIndex(self.current_press_skill_button_idx);
    end

    -- if tonumber(profiler.time()) > 10 then
    --      print("Battle Update cost " .. profiler.time() .. "ms\n" .. profiler.report('TOTAL'));
    -- end
    -- profiler.stop();
end


function BattlefieldView:ChatRef()
    self.chat_time_left = (self.chat_time_left or 0) - UnityEngine.Time.deltaTime;
    if self.chat_time_left > 0 then
        return;
    end
    
    self.chat_time_left = 1;

    local channelName = {[0] = "系统",[1] = "世界",[6] = "私聊",[3] = "公会",[7] = "队伍",[8] = "好友",[10] = "组队",[100] = "地图"}
    local ChatData = module.ChatModule.GetNewChat()
    for i = 1,#ChatData do
        local label = self.view.battle.Canvas.ChatNode[i][UnityEngine.UI.Text];
        label.text = ""
        local desc = WordFilter.check(ChatData[i].message)
        if ChatData[i].channel == 0 then
            desc = ChatData[i].message
        end
        local desc_list = StringSplit(desc,"\n")
        if #desc_list > 1 then
            desc = ""
            for i =1,#desc_list do
                desc = desc..desc_list[i]
            end
        end
        local name = ChatData[i].fromname..":"
        if ChatData[i].channel == 0 then
            name = ""
        end
        label.text = label.text.."["..(channelName[ChatData[i].channel] or "未知").."]"..name..desc.."\n"
    end
end

function BattlefieldView:GetSharedObject(refid)
    if not self.shared_object then
        self.shared_object = {}

        for k, v in pairs(self.fight_data.defender.roles) do
            if v.share_mode and v.share_mode ~= 0 then
                self.shared_object[v.refid] = {
                    refid = v.refid, data = v,    side = 2,
                    mode = v.share_mode,
                    count = v.share_count
                }
            end
        end
    end
    return self.shared_object[refid]
end

local function SampleQueue(list)
    local idx = 0;
    return setmetatable({}, {__index={
        pop = function()
            idx = idx + 1;
            return list[idx];
        end}
    })
end

local function defaultValue(value, def)
    if (value == nil or value == 0) then
        return def;
    end

    return value;
end

function BattlefieldView:UNIT_Hurt(role, value, valueType, num_text)
    local script = self:UnitShowNumber(role, value, "hitpoint",  defaultValue(valueType, "hurt_normal"), num_text);
    if script then
        script:ShowWarning( (role.hp > 0) and 2 or 1);
    end
end

function BattlefieldView:UNIT_Health(role, value, valueType, num_text)
    self:UnitShowNumber(role, value, "hitpoint", defaultValue(valueType, "health_normal"), num_text);
end

function BattlefieldView:TIMELINE_BeforeAction(role)
    DispatchEvent("TeamLoadFinished")

    self.view.battle.Canvas.AssistInfo:SetActive(false)

    self:CameraLookAt(0);
    self:CameraMoveTo(0);

    if role.side == 1 and role.pos >= 1 and role.pos <= 5 then
        self:ShowSkillOfRole(role)
    else
        self:ShowSkillOfRole(nil)
    end

    if role.side == 1 and role.pos >= 1 and role.pos <= 5 then
        self:ShowPartner(role);
        -- self.view.battle.cameraController.cameraMoveTarget
        self.cameraController:CameraMoveReset(self.view.battle.CameraSlot[role.pos].transform, 0.3);
        -- self.view.battle.player.transform:DOMove(self.view.battle.CameraSlot[role.pos].transform.position, 0.3);
    else
        self.cameraController:CameraMoveReset(self.view.battle.CameraSlot[3].transform, 0.3);

        -- self.view.battle.player.transform.position = self.view.battle.CameraSlot[3].transform.position
        self:ShowPartner()
        self:CallRoleAction(role.uuid, "Active", true)

        if role.side ~= 1 then
            if self.enemy_action_effect == nil then
                self.enemy_action_effect = self.gameObjectPool:Get("prefabs/effect/UI/fx_jues_act");
            end

            if self.enemy_action_effect then
                self.enemy_action_effect.transform.position = self.roles[role.uuid].script.gameObject.transform.position;
                self.enemy_action_effect:SetActive(true);
            end
        end
    end

    self.exit_button_is_ready = true;
    self.current_action_role = role
    -- self:PlayRandomSound(role.id, 0, 4)
end

function BattlefieldView:TIMELINE_AfterAction()
    if self.enemy_action_effect then
        self.enemy_action_effect:SetActive(false);
    end

    self.current_action_role = nil
    -- self:ShowSkillOfRole(nil)
end

function BattlefieldView:OnDiamondClick()
    self:onSkillSelected(Skill.ID_DIAMOND, false);
end

--[[
function BattlefieldView:ChangeDiamond(idx)
end
--]]

function BattlefieldView:UnitShowNumber(role, value, point, type, name)
    if self.fastforward_mode then return end;

    local info = self.roles[role.uuid];
    local pos = info and info.script:GetPosition(point) or Vector3.zero;
    self.targetSelectorManager:AddUIEffect("prefabs/battlefield/" .. (type or 'hurt_normal'), pos, function(o)
        if not o then return; end
        local nm = o:GetComponent(typeof(CS.NumberMovement));
        if not nm.text then
            nm.text = o:GetComponent(typeof(UnityEngine.UI.Text));
        end
        nm.text.text = tostring(value);
        if nm.nameText ~= nil then
            nm.nameText.text = tostring(name or "")
        end
    end);
    return info and info.script;
end

function BattlefieldView:UnitShowBuffEffect(role, name, isUp)
    if not role then
        return;
    end

    self.BuffEffectList = self.BuffEffectList or {}
    self.BuffEffectList[role.uuid] = self.BuffEffectList[role.uuid] or {}
    table.insert(self.BuffEffectList[role.uuid], {name, isUp})
    if (#self.BuffEffectList[role.uuid] == 1) then
        self:CallAfter(0.1, function ()
            self:_UnitShowBuffEffect(role, name, isUp)
        end)
    end
end


function BattlefieldView:_UnitShowBuffEffect(role, name, isUp)
    if not role then
        return;
    end
    
    local info = self.roles[role.uuid];
    local pos = info and info.script:GetPosition("hitpoint") or Vector3.zero;
    self.targetSelectorManager:AddUIEffect("prefabs/battlefield/BuffTips", pos, function(o)
        if not o then return; end
        local nm = o:GetComponent(typeof(CS.NumberMovement));
        local view = SGK.UIReference.Setup(o);
        view.BuffTips_ani.Text[UnityEngine.UI.Text].text = name;
        view.BuffTips_ani[CS.UGUISelector].index = (isUp and 0 or 1);
    end);

    table.remove(self.BuffEffectList[role.uuid], 1)
    if #self.BuffEffectList[role.uuid] > 0 then
        self:CallAfter(0.1, function ()
            self:_UnitShowBuffEffect(role, self.BuffEffectList[role.uuid][1][1], self.BuffEffectList[role.uuid][1][2])
        end)
    end
end

function BattlefieldView:PET_ACTION(list, role)
    if self.fastforward_mode then return end;

    local go = nil;
    local parent = self.view.battle.partnerStage.petAttackPosition.gameObject.transform;

    local prefabName = nil;

    if #list == 1 then
        prefabName = (role.side == 1) and "fx_zhaoh_f_1" or "fx_zhaoh_f_1_di"
    elseif #list == 2 then
        prefabName = (role.side == 1) and "fx_zhaoh_f_2" or "fx_zhaoh_f_2_di"
    elseif #list >= 3 then
        prefabName = (role.side == 1) and "fx_zhaoh_f_3" or "fx_zhaoh_f_3_di"
    end

    if not prefabName then
       return;
    end

    go = self.gameObjectPool:Get('prefabs/effect/UI/' .. prefabName)
    
    go.transform.localPosition = Vector3.zero;
    go.transform.localScale = Vector3.one;
    go.transform.localRotation = Quaternion.identity;

    go.transform:SetParent(parent, false);
    go:SetActive(true);

    self.view.battle.GrayLayer:SetActive(false);

    if not go then
        return;
    end

    local side = list[1].side;
    self.view.battle.Canvas.AssistInfo:SetActive(true)
    self.view.battle.Canvas.AssistInfo.Text:TextFormat( (side == 1) and "我方召唤物行动" or "敌方召唤物行动")

    local view = SGK.UIReference.Setup(go);

    for i = 1, #list do
        if view[i] then
            local skeletonAnimation = view[i][CS.Spine.Unity.SkeletonAnimation];
            local skeletonDataName = string.format("roles/%s/%s_SkeletonData", list[i].mode, list[i].mode);
            skeletonAnimation:UpdateSkeletonAnimation(skeletonDataName)

            self.pet_skeleton_position = self.pet_skeleton_position or {};
            self.pet_skeleton_position[prefabName] = self.pet_skeleton_position[prefabName] or {}
            self.pet_skeleton_position[prefabName][i] = self.pet_skeleton_position[prefabName][i]  or skeletonAnimation.gameObject.transform.localPosition;

            CS.SkeletonAnimationAnchoredPosition.Attach(skeletonAnimation, "hitpoint");

            -- local pos = SGK.BattlefieldObject.GetSkeletonBonePosition("hitpoint");
            -- skeletonAnimation.gameObject.transform.localPosition = 
            --    self.pet_skeleton_position[prefabName][i]-pos * skeletonAnimation.gameObject.transform.localScale.x;

            local MaskableSkeletonAnimation = view[i][SGK.MaskableSkeletonAnimation]
            if MaskableSkeletonAnimation then
                MaskableSkeletonAnimation:UpdateStencil();
            end
        end
    end

    self.gameObjectPool:Release(go, 3);
end

function BattlefieldView:SetupButton()
    self.view.battle.Canvas.TopRight.autoButton:SetActive(OpenLevelConfig.GetStatus(3001))
    self.view.battle.Canvas.TopRight.assitButton:SetActive(OpenLevelConfig.GetStatus(3002))
    if UnityEngine.Application.isEditor then
        self.view.battle.Canvas.TopRight.recordButton:SetActive(true or OpenLevelConfig.GetStatus(3003))
    else
        self.view.battle.Canvas.TopRight.recordButton:SetActive(false)
    end
    self.view.battle.Canvas.TopRight.nextButton:SetActive(OpenLevelConfig.GetStatus(3004))
    self.view.battle.Canvas.TopRight.FightingBtn:SetActive(OpenLevelConfig.GetStatus(3005))

    local function updateDefAndIdle(obj, id)
        if OpenLevelConfig.GetStatus(id) then
            obj:SetActive(true);
        else
            obj:SetActive(false);
        end
    end

    updateDefAndIdle(self.view.battle.Canvas.SkillPanel.SkillDef, 3006);
    updateDefAndIdle(self.view.battle.Canvas.SkillPanel.SkillIdle, 3007);
    self.view.battle.Canvas.SkillPanel.SkillIdle:SetActive(false)


    self.current_press_skill_button_idx  = nil;
    self.current_press_skill_button_time = nil;
    self.skill_button_press_timeout = 0.5;

    for idx, btn in ipairs({"Skill1", "Skill2", "Skill3", "Skill4"}) do
        local listener = CS.UGUIPointerEventListener.Get(self.view.battle.Canvas.SkillPanel[btn].Button.gameObject);

        local button_index = idx;
        listener.onPointerDown = function()
            self.current_press_skill_button_idx = button_index;
            self.current_press_skill_button_time = UnityEngine.Time.realtimeSinceStartup;
        end

        listener.onPointerUp = function()
            self:ShowSkillInfoByIndex();
            if self.current_press_skill_button_time and 
                UnityEngine.Time.realtimeSinceStartup - self.current_press_skill_button_time < self.skill_button_press_timeout then
                self:onSkillSelected(button_index, false);
            end
            self.current_press_skill_button_idx = nil;
            self.current_press_skill_button_time = nil;
        end

        listener.onPointerExit = function()
            self.current_press_skill_button_idx = nil;
            self.current_press_skill_button_time = nil;            
            self:ShowSkillInfoByIndex();
        end
    end
end

function BattlefieldView:assitButton_click()
    if not self.timeline.winner and not self.exit_button_is_ready then
        showDlgError(nil, "还没有准备好")
        return;
    end

    if self:NeedSyncData() then
        if self.vote_end_time and Time.now() < self.vote_end_time then
            showDlgError(nil, "投票进行中")
            return;
        end
    end

    showDlg(nil,"确认退出战斗?", function()
        if self.args and self.args.callback then
            self.args.callback(false,self.input_heros)
        end

        if self:NeedSyncData() then
           TeamModule.SyncFightData(T.VOTE_TO_EXIT, {1});
            return;
        end

        module.EncounterFightModule.SetCombatTYPE(1)--保存玩家退出战斗的状态
        utils.MapHelper.ClearGuideCache(9999)
        SceneStack.Pop();
    end, function() end)
end

function BattlefieldView:autoButton_click()
    if self.auto_input or self.auto_input_time then
        self:SetAutoInput(false)
        self.auto_input_time = nil;
    else
        self:SetAutoInput(true)
        -- self.auto_input_time = os.time() + 3;
    end
end

function BattlefieldView:fightingBtn_click()
    local _obj = SGK.ResourcesManager.Load("prefabs/FightingBtn")
    CS.UnityEngine.GameObject.Instantiate(_obj, self.view.battle.PersistenceCanvas.transform)
end

function BattlefieldView:SetAutoInput(auto, from_server)
    if self:NeedSyncData() and not from_server then
        self.auto_input_time = auto and self.auto_input_time or nil
        self.view.battle.Canvas.TopRight.autoButton.nameText[UnityEngine.UI.Text]:TextFormat("...");
        self:SendServerCommand({
            pid     = self.game.pid,
            type    = "INPUT",
            refid   = 0,
            sync_id = 0,
            tick    = 0,
            skill   = 99036;
            target  = auto and 1 or 0;
        })
        return;
    end

    self.auto_input = auto;
    battle_scene_data.auto_input = auto;
    self.view.battle.Canvas.TopRight.autoButton.nameText[UnityEngine.UI.Text]:TextFormat(self.auto_input and "取消" or "自动");
    self.view.battle.Canvas.TopRight.autoButton[CS.UGUISpriteSelector].index = auto and 1 or 0;
    if auto then self:ShowSkillAdvise() end
    -- self.view.battle.Canvas.autoSkillTips:SetActive(auto);
    -- self.view.battle.Canvas.TopRight.autoButton.activeFlag:SetActive(auto);
    -- if self.Button_Command.solo_fight then self.Button_Command:SetActive(auto) end

    if self.auto_input and self._current_role then
        self:UNIT_INPUT();
    end
end

function BattlefieldView:ShowUIDisable(show)
    self.show_ui_disable = show
end

function BattlefieldView:ShowUI(show)    
    if self.show_ui_disable then
        return
    end

    CanvasGroupActive(self.view.battle.Canvas, show);

    for _, v in pairs(self.roles or {}) do
        if v.script.ui then
            v.script.ui:GetComponent(typeof(UnityEngine.CanvasGroup)).alpha = show and 1 or 0;
        end
    end
    -- CanvasGroupActive(self.view.battle.TargetCanvas, show);
end

function BattlefieldView:recordButton_click()
    if UnityEngine.Application.isEditor then
        if self.game.timeline.enter_script_count > 0 then
            return;
        end

        local l = {}
        for _, v in ipairs(self.game.timeline) do
            if v.side ~= 1 then            
                local value = -math.ceil(v.hpp / 5)
                if v.share_mode == 0 or not self:NeedSyncData() then
                    self.game.commandQueue:Push({
                        type    = "MONSTER_HP_CHANGE",
                        pid     = 0,
                        refid   = v.refid,
                        sync_id = v.sync_id,
                        value   = value,
                    })
                else
                    TeamModule.SyncFightData(T.KILL_COMMAND, {v.refid, v.sync_id, value});
                end
                return;
            end
        end
        return;
    end

    self:OnRecordClick();
end

function BattlefieldView:nextButton_click()
    if false then
        self.args.commandQueue = self.game.commandQueue:GetQueue();
        self.args.fastforward = {tick = self.game.timeline.tick};
        SceneStack.Replace("battle", "view/battle.lua", self.args);
        return;
    end

    self:ShowHeadPanel();
end

function BattlefieldView:OnNextFightClick()
    do
        self.args.commandQueue = self.game.commandQueue:GetQueue();
        self.args.is_replay = true;
        -- self.args.fastforward = {wave = self.game.timeline.wave, round = self.game.timeline.round}
        SceneStack.Replace("battle", "view/battle.lua", self.args);
        return;
    end
end

function BattlefieldView:FindSceneGameObject()
    self.view.partner_slots = {}
    self.view.partner_objects = {}
    for k, v in ipairs({"slot1", "slot2", "slot3", "slot4", "slot5"}) do
        self.view.partner_objects[k] = self.view.battle.partnerStage.slotCard[v].partner;
        self.view.partner_slots[k] = self.view.battle.partnerStage.slotCard[v];
    end
    -- self.view.partner_prefab = SGK.ResourcesManager.Load("prefabs/battlefield/partner");
    
    self.enemy_prefab = SGK.ResourcesManager.Load("prefabs/battlefield/enemy");
    self.enemy2_prefab = SGK.ResourcesManager.Load("prefabs/battlefield/enemy2");
    self.enemy_boss_prefab = SGK.ResourcesManager.Load("prefabs/battlefield/enemyBoss");

    self.view.enemy_slots = {}
    for _, v in ipairs({11, 21, 22, 23, 31, 32, 33, 34}) do
        self.view.enemy_slots[v] = self.view.battle.enemyStage["slot" .. v];
        self.view.enemy_slots[v].prefab = self.enemy_prefab;
    end

    self.view.enemy_slots[11].prefab = self.enemy_boss_prefab;

    for _, v in ipairs({31,32,33,34}) do
        self.view.enemy_slots[v].prefab = self.enemy2_prefab;
    end

    self.view.enemy_slots[1] = self.view.enemy_slots[21];
    self.view.enemy_slots[2] = self.view.enemy_slots[32];
    self.view.enemy_slots[3] = self.view.enemy_slots[22];
    self.view.enemy_slots[4] = self.view.enemy_slots[33];
    self.view.enemy_slots[5] = self.view.enemy_slots[23];

    self.pet_prefab = SGK.ResourcesManager.Load("prefabs/battlefield/pet");
    self.pet_prefab_enemy = SGK.ResourcesManager.Load("prefabs/battlefield/pet_enemy");


    -- self.partnerManager = self.view.battle.partnerStage[SGK.Battle.BattlefieldPartnerManager];
    -- self.enemyManager = self.view.battle.enemyStage[SGK.Battle.BattlefieldEnemyManager];
    self.timeline = self.view.battle.Canvas.timelinePanel[SGK.Battle.BattlefieldTimeline];

    local this = self;

    -- self.skillManager = self.view.battle.partnerStage[SGK.Battle.BattlefieldSkillManager];

    
    self.skillManager = self.view.battle.Canvas.SkillPanel[CS.BattlefieldSkillManager2]
    self.skillManager.selectedDelegate = function(index)
        this:onSkillSelected(index, false);
    end

    self.skillManager.changeSkillDelegate = function()
        self:ChangeSkillIcon();
    end

    SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/effect/UI/fx_btn_select", function(o)
        if not o then
            return;
        end
        self.skill_select_effect = SGK.UIReference.Instantiate(o)
        self.skill_select_effect.transform:SetParent(self.view.battle.Canvas.SkillPanel.transform, false)
        self.skill_select_effect:SetActive(false);
    end)

    SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/effect/UI/fx_btn_auto", function(o)
        if not o then
            return;
        end
        self.skill_cast_effect = SGK.UIReference.Instantiate(o)
        self.skill_cast_effect.transform:SetParent(self.view.battle.Canvas.SkillPanel.transform, false)
        self.skill_cast_effect:SetActive(false);
    end)

    SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/skill_tuijian", function(o)
        if not o then
            return
        end
        self.skill_advise_effect = SGK.UIReference.Instantiate(o)
        self.skill_advise_effect.transform:SetParent(self.view.battle.Canvas.SkillPanel.transform, false)
        self.skill_advise_effect.transform.localPosition = UnityEngine.Vector3(100, 0, 0);
    end)

    -- self.skill_select_effect = self.view.battle.partnerStage.skill_select_effect;
    -- self.skill_cast_effect   = self.view.battle.partnerStage.skill_cast_effect;
    -- self.Button_Command = self.view.battle.Canvas.UIRoot.command
    -- for i = 0, 3, 1 do
    --     self.Button_Command.detail.buttons["button_"..i][CS.UGUIClickEventListener].onClick = function()
    --         self:ShowFocusTargets(i)
    --     end
    -- end

    self.skillInfoPanel = self.view.battle.Canvas.SkillInfo;
    self.skillInfoPanel.ErrorInfo = self.view.battle.Canvas.ErrorInfo
    self.skillInfoPanel.CanvasGroup = self.skillInfoPanel[UnityEngine.CanvasGroup];
    self.SkillInfo_Show = battle_scene_data.SkillInfo_Show
    
    self.skillInfoPanel.guide[CS.UGUIClickEventListener].onClick = function () 
        self:ShowSkillGuide()
    end

    self.cameraController = self.view.battle.cameraController[SGK.Battle.BattleCameraController];
    self.cameraController:CameraMoveReset(self.view.battle.CameraSlot[3].transform, 0.1);
    self.cameraController:CameraLookReset(self.view.battle.enemyStage.slot11.transform, 0.1);

    self.view.battle.GrayLayer = self.view.battle.partnerStage.GrayLayer;

    self.targetSelectorManager = self.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];
    self.targetSelectorManager.selectedDelegate = function(...)
        this:onTargetSelected(...);
    end
end

local diamond_skin = {
    "hong",
    "huang",
    "zi",
    "lv",
    "hei",
    "fen",
    "lan",
}

local pvp_enemy_offset = {
    [1] = {0,0,0},
    [2] = {0,0,0},
    [3] = {0,0,0},
    [4] = {0,0,0},
    [5] = {0,0,0},
}

local role_master_list = {
    {master = "airMaster",   index = 3, desc = "风系", colorindex = 0},
    {master = "dirtMaster",  index = 2, desc = "土系", colorindex = 1},
    {master = "waterMaster", index = 0, desc = "水系", colorindex = 2},
    {master = "fireMaster",  index = 1, desc = "火系", colorindex = 3},
    {master = "lightMaster", index = 4, desc = "光系", colorindex = 4},
    {master = "darkMaster",  index = 5, desc = "暗系", colorindex = 5},
}

local function GetRolePostionOffset(role)
    if role.side ~= 1 and pvp_enemy_offset[role.pos] then
        local value = pvp_enemy_offset[role.pos]
        return Vector3(value[1] + role.x,value[2] + role.y,value[3] + role.z)
    end
    return Vector3(role.x or 0, role.y or 0, role.z or 0)
end

local function GetMasterIcon(role, other_info)
    table.sort(role_master_list, function (a, b)
        if role[a.master] ~= role[b.master] then
            return role[a.master] > role[b.master]
        end
		return a.master > b.master
    end)
    
    if other_info and role[role_master_list[1].master] == role[role_master_list[2].master] then
        return {desc = "全系",  colorindex = 6}
    elseif other_info then
        return {desc = role_master_list[1].desc,  colorindex = role_master_list[1].colorindex}
    end

    if role[role_master_list[1].master] == role[role_master_list[2].master] then
        return 6
    else
        return role_master_list[1].index
    end
end

function BattlefieldView:CreateRole(role, no_enter_script, no_mask)
    local info = self.roles[role.uuid];
    if info and info.object then
        return;
    end

    if role.name == "assistant" then
        return;
    end

    self.roles[role.uuid] = info or {role = role, object = nil  }
    info = self.roles[role.uuid];

    local targetObject = nil;

    if role.side == 1 then
        targetObject = self.view.partner_objects[role.pos];
        targetObject:SetActive(true);
        local cfg = HeroModule.GetConfig(role.id) or battle_config.LoadNPC(role.id);

        if not cfg then
            WARNING_LOG('hero config', role.id, "not exists");
        end

        local mp_type = cfg and cfg.mp_type or 8000;
        local color

        if mp_type == 8000 then
            color = 0 -- SGK.QualityConfig.GetInstance().mpColor --  UnityEngine.ColorUtility.TryParseHtmlString('#4eaeff');
        elseif mp_type == 8001 then
            color = 1 -- SGK.QualityConfig.GetInstance().epColor -- UnityEngine.ColorUtility.TryParseHtmlString('#7bd721');
        elseif mp_type == 8002 then
            color = 2 -- SGK.QualityConfig.GetInstance().fpColor -- UnityEngine.ColorUtility.TryParseHtmlString('#d75d21');
        end

        if color then
            targetObject.UIPartner.MP[CS.BattlefieldProgressBar].color = color; -- .Value[UnityEngine.UI.Image].color = color;
        else
            targetObject.UIPartner.MP.gameObject:SetActive(false);
        end

        -- targetObject.UIPartner:SetActive(true);
        targetObject.UIPartner.element[CS.UGUISpriteSelector].index = GetMasterIcon(role)

        local mpName = "MP";
        if cfg and cfg.mp_type == 8001 then
            mpName = "EP";
        elseif cfg and cfg.mp_type == 8002 then
            mpName = "FP";
        end
        targetObject.UIPartner.MP[CS.BattlefieldProgressBar].title = mpName;
        
    else
        if self.view.enemy_slots[role.pos] and not info.object then
            local gameObject = UnityEngine.GameObject.Instantiate(self.view.enemy_slots[role.pos].prefab);
            gameObject.name = role.id .. "_" .. role.pos;
            gameObject.transform.parent = self.view.enemy_slots[role.pos].gameObject.transform;
            gameObject.transform.localPosition = GetRolePostionOffset(role);
            gameObject.transform.localScale = Vector3.one;
            targetObject = SGK.UIReference.Setup(gameObject);
        end
    end

    if targetObject == nil then
        return;
    end

    info.object = targetObject.gameObject;
    info.script = targetObject[SGK.BattlefieldObject];
    assert(info.script);

    if role.side == 1 then
        info.script:ShowMask(self.partner_show_mask);
        info.script.nameLabel.text = role.name;
    else
        self.targetObject_list = self.targetObject_list or {}
        self.targetObject_list[role.uuid] = targetObject
        local targetObject_UI = targetObject.UIEnemy or targetObject.UIBoss
        
        CS.UGUIPointerEventListener.Get(targetObject_UI.Sing_Bar.type.text.gameObject).onPointerDown = function(obj , pos)
            local info = self.battle_sing_bar_list[role.uuid]
            self.view.battle.Canvas.singbardetail[SGK.LuaBehaviour]:Call("UpdatePos", pos, info)
        end
    
        CS.UGUIPointerEventListener.Get(targetObject_UI.Sing_Bar.type.text.gameObject).onPointerUp = function()
            self.view.battle.Canvas.singbardetail[SGK.LuaBehaviour]:Call("PickBack")
        end
    end

    info.script.onTouchBegan = function(...) self:onEnemyTouchBegan(role.uuid, ...) end
    info.script.onTouchEnd = function(...) self:onEnemyTouchEnd(role.uuid, ...) end
    info.script.onTouchMove = function(...) self:onEnemyTouchMove(role.uuid, ...) end
    info.script.onTouchCancel = function() self:onEnemyTouchCancel(role.uuid) end

    if role.pos == 11 and targetObject.UIBoss then
        targetObject.UIBoss.transform:SetParent(self.view.battle.Canvas.EnemyBossUISlot.gameObject.transform, false);
        targetObject.UIBoss[CS.FollowSpineBone].enabled = false;
        targetObject.UIBoss.transform.localScale = Vector3.one;
        targetObject.UIBoss.element[CS.UGUISpriteSelector].index = GetMasterIcon(role)
    elseif role.side ~= 1 then
        targetObject.UIEnemy.element[CS.UGUISpriteSelector].index = GetMasterIcon(role)
    end

    info.script:SetName(role.name);
    local stageCfg = HeroEvoConfig.GetConfig(role.id);
    local cfg = stageCfg and stageCfg[role.grow_stage];
    info.script:SetQualityColor(utils.ItemHelper.QualityColorIcon(cfg and cfg.quality or 1));

    local flip, enemy_scale = battle_config.GetModeFlip(role.mode, role.side, role.pos);
    info.script.flip = flip;

    if role.side ~= 1 and enemy_scale then
        info.script:SetModeScale(Vector3(enemy_scale, enemy_scale, enemy_scale));
    end

    info.hide = false;
    info.script.onSpineEvent = function(eventName, strValue, intValue, floatValue)
        self.game:Dispatch("SPINE_ANIMATION_EVENT", role, eventName, strValue, intValue, floatValue);
    end

    if role.diamond_index > 0 then
        info.script:SetSkin( diamond_skin[role.diamond_index]);
    end

    if not no_enter_script
            and role.enter_script 
            and role.enter_script ~= 0 
            and role.enter_script ~= "0" 
            and role.side ~= 1 then
        info.object.transform.localPosition = UnityEngine.Vector3(0, 20, 0); -- :SetActive(false);
        info.hide = true;
    else
        if role.side == 1 then
            info.script:ChangeMode(tostring(role.mode), role.scale, "idle", false, self.partner_sorting_order[role.mode] or 2);
        else
            info.script:ChangeMode(tostring(role.mode), role.scale);
        end

        local stageCfg = HeroEvoConfig.GetConfig(role.id);
        local cfg = stageCfg and stageCfg[role.grow_stage];
        info.script:ChangeIcon(tostring(role.icon), 0 or role.level, cfg and cfg.quality or 1, role.grow_star);
        info.object.transform.localPosition = GetRolePostionOffset(role)
        info.script:ShowUI(true);
        -- self.view.battle.Canvas.Characters[CS.UGUISimpleLayout]:Layout();
        self:UpdateObjectPropertyValue(role);
    end

    local buffList = self.game.buffManager:Get(role);

    for _, v in ipairs(buffList) do
        self:BUFF_Add(v, role);
    end
end

function BattlefieldView:TIMELINE_Leave(role)
    print("BattlefieldView:TIMELINE_Leave", role.name)
    local info = self.roles[role.uuid];
    if info and info._Focus_Effect then
        self.gameObjectPool:Release(info._Focus_Effect);
    end

    if info and info.script then
        info.script:ShowUI(false);
    end
end

function BattlefieldView:UNIT_RELIVE(role)
    local info = self.roles[role.uuid];
    if not info or not info.object then
        return;
    end

    local stageCfg = HeroEvoConfig.GetConfig(role.id);
    local cfg = stageCfg and stageCfg[role.grow_stage];

    info.script:ChangeMode(tostring(role.mode), role.scale);
    info.script:ShowUI(true);
    self:UpdateObjectPropertyValue(role);

    info.script:SetQualityColor(utils.ItemHelper.QualityColorIcon(cfg and cfg.quality or 0));
    info.script:ShowWarning(0);

    info.dead = false;

    if info.script.icon then
        info.script.icon.image.gameObject:GetComponent(typeof(CS.ImageMaterial)).active = false;
        self.roles[role.uuid].script.icon.hpBar.gameObject:SetActive(true);
    end

    self:UnitChangeExposure(role, 0);    
    self:UnitPlay(role, "idle")

end

function BattlefieldView:TIMELINE_Enter(role)
    -- print(role.id, role.name, 'Enter')
    self:CreateRole(role)
end

function BattlefieldView:TIMELINE_Remove(role)
    -- print("TIMELINE_Remove", role.id, role.refid, role.name, role.side);
    if role.side ~= 1 then
        local info = self.roles[role.uuid];
        if info then
            UnityEngine.GameObject.Destroy(info.object, 1);
            self.roles[role.uuid] = nil;
        end
    else
        -- script:ShowWarning( (role.hp > 0) and 0 or 1);
    end
end

function BattlefieldView:TipsEffect(type, to_pos, round_change_callback)
    local animate_time = 0.3
    if not self["tips_effect"..type] then
        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/effect/UI/fx_ui_b_lizi", function(o)
            if not o then
                return
            end
            self["tips_effect"..type] = SGK.UIReference.Instantiate(o)
            self["tips_effect"..type].transform:SetParent(self.view.battle.PersistenceCanvas.transform, false)
            self["tips_effect"..type]:SetActive(false)
            self["tips_effect"..type].original_scale = self["tips_effect"..type].transform.localScale
            self["tips_effect"..type].original_localPosition = Vector3(0, 350, 0)
        end)

        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/effect/UI/fx_ui_b_lizi_hit", function(o)
            if not o then
                return
            end
            self["tips_effect"..type.."hit"] = SGK.UIReference.Instantiate(o)
            self["tips_effect"..type.."hit"].transform:SetParent(self.view.battle.PersistenceCanvas.transform, false)
            self["tips_effect"..type.."hit"].transform.position = to_pos.position
            self["tips_effect"..type.."hit"]:SetActive(false)
        end)
    end
    self["tips_effect"..type].transform.localPosition = self["tips_effect"..type].original_localPosition
    self["tips_effect"..type].transform.localScale = self["tips_effect"..type].original_scale
    self["tips_effect"..type]:SetActive(true)
    self["tips_effect"..type].transform:DOMove(to_pos.position, animate_time)
    self["tips_effect"..type].transform:DOScale(1, animate_time):OnComplete(function()
        self["tips_effect"..type]:SetActive(false)
        self["tips_effect"..type.."hit"] :SetActive(true)
        local toscale = to_pos.localScale * 1.6
        local fromscale = to_pos.localScale
        round_change_callback()
        to_pos:DOScale(toscale, 0.5):OnComplete(function ()
            to_pos:DOScale(fromscale, 0.5)
        end)    
        self:CallAfter(0.6, function() self["tips_effect"..type.."hit"] :SetActive(false) end)
    end)
end

function BattlefieldView:TIMELINE_BeforeWave()
    local roundTips = self.view.battle.Canvas.roundTips;
    roundTips.gameObject:SetActive(true);
    -- roundTips.Image[CS.UGUISpriteSelector].index = self.game.timeline.wave - 1;
    roundTips.text[UnityEngine.UI.Text].text = tostring(self.game.timeline.wave);

    roundTips:SetActive(true)  
    roundTips[UnityEngine.Animator]:Rebind()
    roundTips[UnityEngine.Animator]:Play("round_ani")

    self:CallAfter(1, function()
        self:TipsEffect("wave", self.view.battle.Canvas.WaveInfo.Text.transform, function ( ... )
            self.view.battle.Canvas.WaveInfo.Text[UnityEngine.UI.Text].text = string.format("第 %d/%d 波", self.game.timeline.wave, self.max_wave);
        end)
    end)

    if self.battle_anchor_animator then
    else
        if self.game.timeline.wave > 1 then
            self:ShowUI(false);            
            self:AddStageEffect(nil, "UI/fx_sence_hei");
            self:CallAfter(1, function ()
                self:ShowUI(true);
            end);
            
        end
    end

--[[
    -- roundTips[CS.DG.TweenBehaviour]:Restart();
    roundTips.gameObject.transform:DOScale(Vector3.one, 1.0):OnComplete(function()
        roundTips.gameObject:SetActive(false);
    end)
--]]
end

function BattlefieldView:TIMELINE_AfterWave()
    -- print("BattlefieldView:TIMELINE_AfterWave")
    self.game:Pause();

    local sleep = self.game.timeline:HaveMoreEnemy() and 2 or 1;

    self:CallAfter(sleep, function ()
        self.game:Resume();
    end);

    if self.battle_anchor_animator then
        self:CallAfter(2, function ()
            self.battle_anchor_animator:SetTrigger("NextWave");
        end);
    end
end

function BattlefieldView:TIMELINE_BeforeRound()
    local timeout = self.view.battle.Canvas.timeout[SGK.BattlefieldTimeout];
    if self.round_timeout > 0 and self.round_timeout < 500 and (self.hero_timeout == 0 or self.hero_timeout > 100) then
        self:StartTimeCounting(self.round_timeout)
    end

    self.view.battle.Canvas.RoundInfo:SetActive(self.game.timeline.total_round > 0); 
    
    self.view.battle.Canvas.waveTips.text[UnityEngine.UI.Text].text = tostring(self.game.timeline.total_round)
    self.view.battle.Canvas.waveTips:SetActive(true)  
    self.view.battle.Canvas.waveTips[UnityEngine.Animator]:Rebind()
    self.view.battle.Canvas.waveTips[UnityEngine.Animator]:Play("round_ani")

    local current_round_view 

    if self.Round_Type == 1 then
        current_round_view = self.game.timeline.win_round_limit - self.game.timeline.total_round
        local win_round_limit = self.game.timeline.win_round_limit - 1
        local rest_round = self.game.timeline.win_round_limit - self.game.timeline.total_round
        local desc = string.format("坚持回合战斗，坚持<color=#ffd800>%s</color>回合后战斗胜利\n剩余回合：<color=#ffd800>%s</color>", win_round_limit, rest_round);
        self.view.battle.Canvas.RoundInfo.detail.text_bg.Text[UnityEngine.UI.Text].text = desc
    elseif self.Round_Type == 2 then
        current_round_view = self.game.timeline.failed_round_limit - self.game.timeline.total_round
        local round_limit = self.game.timeline.failed_round_limit
        local current_round = self.game.timeline.total_round
        local desc = string.format("战斗共计<color=#ffd800>%s</color>回合，超过回合后战斗失败\n当前回合：<color=#ffd800>%s</color>", round_limit, current_round);
        self.view.battle.Canvas.RoundInfo.detail.text_bg.Text[UnityEngine.UI.Text].text = desc
    else
        current_round_view = self.game.timeline.total_round
        local round_limit = self.game.timeline.failed_round_limit or 20
        local current_round = self.game.timeline.total_round
        local desc = string.format("战斗共计<color=#ffd800>%s</color>回合，超过回合后战斗失败\n当前回合：<color=#ffd800>%s</color>", round_limit, current_round);
        self.view.battle.Canvas.RoundInfo.detail.text_bg.Text[UnityEngine.UI.Text].text = desc
    end
    self:ShowRoundDetail()


    self:CallAfter(1, function()
        self:TipsEffect("round", self.view.battle.Canvas.RoundInfo.round.transform, function( ... )
            self.view.battle.Canvas.RoundInfo.round.count:TextFormat("{0}", current_round_view)
        end)
    end)
end

function BattlefieldView:ShowRoundDetail()
    CS.UGUIPointerEventListener.Get(self.view.battle.Canvas.RoundInfo.Image.gameObject).onPointerDown = function()
        local detail = self.view.battle.Canvas.RoundInfo.detail
        if self:NeedSyncData() then
            detail:SetActive(true)
            return;
        end
    
        local info = self:GetStarInfo()

        if #info > 0 then
            detail.Stars.star_bg[CS.UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(detail.Stars.star_bg[CS.UnityEngine.RectTransform].sizeDelta.x, 4 + #info * 46)
            local sc = self.fight_data.star;
            local fight_info = fightModule.GetFightInfo(self.game.defender_pid)
            for i = 1, #info,1 do
                local star = detail.Stars["star"..i]
                if i == 1 then
                    star.text:TextFormat("战斗胜利");
                else
                    star.text:TextFormat("{0}", loadStarDesc(sc[i-1].type, sc[i-1].v1, sc[i-1].v2));
                end

                if fightModule.GetOpenStar(fight_info.star, i) ~= 0 then
                    star.text[CS.UGUISelector].index = 1;
                    star.icon[CS.UGUISpriteSelector].index = 0;
                    star.checker[CS.UGUISelector].index = 0;
                else
                    star.text[CS.UGUISelector].index = info[i] and 1 or 0;
                    star.icon[CS.UGUISpriteSelector].index = 1;
                    star.checker[CS.UGUISelector].index = info[i] and 1 or 0;
                end
                star:SetActive(true);
            end
        end    
        detail[CS.DG.Tweening.DOTweenAnimation]:DORestart(true)
        detail:SetActive(true)
    end

    CS.UGUIPointerEventListener.Get(self.view.battle.Canvas.RoundInfo.Image.gameObject).onPointerUp = function()
        self.view.battle.Canvas.RoundInfo.detail:SetActive(false)
    end
end

function BattlefieldView:SkillEffectFollow(effect, index)
    --[[
    self.view.battle.Canvas.SkillPanel.Skill1.Button.Mask:SetActive(index == 1)
    self.view.battle.Canvas.SkillPanel.Skill2.Button.Mask:SetActive(index == 2)
    self.view.battle.Canvas.SkillPanel.Skill3.Button.Mask:SetActive(index == 3)
    self.view.battle.Canvas.SkillPanel.Skill4.Button.Mask:SetActive(index == 4)
    do return end; -- skillManager
    --]]

    local buttons = {
        self.view.battle.Canvas.SkillPanel.Skill1.Button.transform,
        self.view.battle.Canvas.SkillPanel.Skill2.Button.transform,
        self.view.battle.Canvas.SkillPanel.Skill3.Button.transform,
        self.view.battle.Canvas.SkillPanel.Skill4.Button.transform,
    }
   
    if index and buttons[index] then
        effect:SetActive(true);
        CS.FollowTarget.Follow(effect.gameObject, buttons[index], -1, false, true) -- self.skillManager:GetButtonTransform(index);
        -- effect.transform.localScale = buttons[index].localScale;
    else
        effect:SetActive(false);
    end
end

function BattlefieldView:ShowSkillAdvise(index)
    if not index then
        self.skill_advise_effect:SetActive(false)
        return 
    end

    local buttons = {
        [1] = self.view.battle.Canvas.SkillPanel.Skill1.Button.transform,
        [2] = self.view.battle.Canvas.SkillPanel.Skill2.Button.transform,
        [3] = self.view.battle.Canvas.SkillPanel.Skill3.Button.transform,
        [4] = self.view.battle.Canvas.SkillPanel.Skill4.Button.transform,
        [13] = self.view.battle.Canvas.SkillPanel.SkillDiamon.Button.transform,
    }

    CS.FollowTarget.Follow(self.skill_advise_effect.gameObject, buttons[index], -1, false, true)
    self.skill_advise_effect:SetActive(true)        
end

function BattlefieldView:ShowPartner(role)
    local n = role and role.pos or 0;
    
    if n == 0 and self.always_show_role_id and self.roles[self.always_show_role_id] then
        role = self.roles[self.always_show_role_id].role;
        n = role.pos;
    end

    local skill_manager_action = nil;

    if role ~= self.show_partner_role then
        self.show_partner_role = role;

        local show = false;
        for i = 1, 5 do
            local script = self.view.battle.partnerStage.slotCard[i].partner[SGK.BattlefieldObject];
            if n < 1 or n > 5 then
                script:Active(false);
                -- script.gameObject:SetActive(true);
            elseif i == n then
                show = true;
                script:Active(true);
                -- script.gameObject:SetActive(true);
            else
                local offset = (i < n) and -n or (4 - n);
                script:Active(false, offset + 1);
                -- script.gameObject:SetActive(false);
            end
        end

        --[[
        if self.view.battle.partnerStage.TeamSlot then
                if not show then
                    self.view.battle.partnerStage.TeamSlot.transform:DOLocalMoveY(1.720, 0.1);
                else
                    self.view.battle.partnerStage.TeamSlot.transform:DOLocalMoveY(0.896, 0.1);
                end
        end
        --]]
    end

    if n == 0 then
        self.view.battle.Canvas.Characters:SetActive(false);
        self:ShowSkillOfRole(nil)
        self:SkillEffectFollow(self.skill_select_effect, nil)
        self:SkillEffectFollow(self.skill_cast_effect, nil)
    else
        if not self.args.partner_data or #self.args.partner_data == 0 then
            self.view.battle.Canvas.Characters:SetActive(true);
            self.view.battle.Canvas.Characters[CS.UGUISimpleLayout]:Layout();
            for i = 1, 5 do
                self.view.battle.Canvas.Characters[i].selector:SetActive(i == n);
            end
            -- self.view.battle.Canvas.Characters.selector.transform.anchoredPosition3D = self.view.battle.Canvas.Characters[n].transform.anchoredPosition3D;
        end
        self:ShowSkillOfRole(self.show_partner_role)
    end
end

function BattlefieldView:CleanDeadObject()
    -- remove pet
    for _, info in pairs(self.removed_pet_list or {}) do
        self:CallRoleAction(info.role.uuid, "RemovePet", info.pet.uuid);
    end
    self.removed_pet_list = {}

    for _, info in pairs(self.dead_role_list or {}) do
        self:UNIT_DEAD_(info);
    end

    self.dead_role_list = {};
end

function BattlefieldView:TIMELINE_EndAction(role)
    self:SkillEffectFollow(self.skill_cast_effect, nil)
    if role.side ~= 1 then
        self:CallRoleAction(role.uuid, "Active", false)
    end

    self.cameraController:CameraMoveReset()
    self.cameraController:CameraLookReset()

    self:HideAllSelector();

    local followCamera = self.view.battle.partnerStage[CS.FollowCamera];
    followCamera.enabled = true;

    self:CleanDeadObject();
    role.timeline_view_isaction = 1
    -- collectgarbage();
end

function BattlefieldView:TIMELINE_AfterRound()
    for k, v in pairs(self.roles) do
        v.role.timeline_view_isaction = 0
    end

    self.cameraController:CameraMoveReset()
    self.cameraController:CameraLookReset()

    self:ShowPartner();
    self:HideAllSelector();

    self:CleanDeadObject();

    -- collectgarbage();
end

function BattlefieldView:GetStarInfo(mustWin)
    local sc = self.fight_data.star;

    if not sc[1] then
        return {};
    end

    local info = {};
    
    info[1] = self.game:CheckStar(1);

    local win = ((not mustWin) or (self.game.timeline.winner == 1));

    for k, v in ipairs(sc) do
        info[k+1] = win and self.game:CheckStar(v.type, v.v1, v.v2)
    end

    return info;
end

function BattlefieldView:TIMELINE_Update()
    if self.destroyed then
        return;
    end

    local i = 0
    local add_round = nil

    for k, v in ipairs(self.game.timeline) do
        if v[7015] == 0 then
            if not add_round and v.timeline_view_isaction == 1 and v.name ~= "assistant" then
                i = i + 1 
                self.timeline:SetRound(i, "round", self.game.timeline.total_round + 1)
                add_round = true
            end

            i = i + 1 
            self.timeline:Set(i, tostring(v.uuid), v.icon, v.side == 1)
        end
    end

    -- if not add_round then
    --     local round = (self.game.timeline.total_round + 1) > 1 and (self.game.timeline.total_round + 1) or 2
    --     self.timeline:SetRound(i + 1, "round", round)
    -- end
end

function  BattlefieldView:UpdateSharedObject()
    local prefab = self.view.battle.Canvas.ShareedEnemyListPanel[1].gameObject;
    local parent = self.view.battle.Canvas.ShareedEnemyListPanel.gameObject.transform;

    self:GetSharedObject(0);

    for _, v in pairs(self.shared_object or {}) do
        if v.share_mode == 1 then 
            if v.view == nil then
                v.view = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, parent));
                v.view.gameObject:SetActive(true);
                v.view[UnityEngine.UI.Image]:LoadSprite("icon/" .. v.data.mode);
                
                CS.UGUIClickEventListener.Get(v.view.gameObject).onClick = function()
                    if v.data.share_count > 0 then
                        TeamModule.SyncFightData(T.MONSTER_ENTER, v.refid);
                    else
                        print("left count = 0")
                    end
                end
            end
            v.view.Count[UnityEngine.UI.Text].text = "x " .. tostring(v.data.share_count);
        end
    end
end

function BattlefieldView:TIMELINE_Finished()
    print("finished, winner", self.game.timeline.winner)

    self:GetSharedObject(0);
    if self:NeedSyncData() then
        if  self.game.timeline.winner == 1 and not self.waiting_cmd_queue_item then
            print("sync data !!!");
            TeamModule.SyncFightData(T.MONSTER_ENTER, 0);
            -- self.game:Pause();
        end
        return;
    end

    -- self.game:Pause();

    local do_not_exist = false;
    if self.args and self.args.callback then
        local code = ProtobufEncode({commands=self.game.commandQueue:GetQueue()}, "com.agame.protocol.FightCommand")
        local record = self.game:GetEventRecord();
        do_not_exist = self.args.callback(self.game.timeline.winner == 1, self.input_heros, self.fight_data.id, self:GetStarInfo(true), code, {
            record = record;
        });
        self.args.callback = nil;
        self.waiting_for_result = true;
    end

    if not do_not_exist then
        self:ShowReward(self.game.timeline.winner, nil)
    end
end

function BattlefieldView:OnServerFightEvent(cmd,data)
    if not self.game or self.team_event_queue then
        print('queue team event', cmd, data);
        self.team_event_queue = self.team_event_queue or {}        
        table.insert(self.team_event_queue, {cmd, data});
        return;
    end

    if cmd == T.PLAYER_COMMAND then
        local message = ProtobufDecode(data[1], "com.agame.protocol.FightCommand");
        if message then
            for _, v in ipairs(message.commands) do
                print("<color=red>server send player command</color>", v.type, v.tick, v.s_index)

                if self.args.fastforward and v.tick > self.args.fastforward.tick then
                    self.args.fastforward.tick = v.tick;
                end

                if v.type == "PLAYER_STATUS_CHANGE" and v.pid == 0 and v.target == 0 then
                    print("<color=red>server notify fight finished</color>", v.value)
                    local win = (v.value == 1)
                    if self.game.pid == self.game.defender_pid then
                        win = (v.value == 2);
                    end

                    DispatchEvent("TEAM_FIGHT_RESULT", win and 1 or 2);

                    self:CallAfter(1, function()
                        if self.args.callback then
                            self.args.callback(win, self.input_heros, self.fight_data.id, self:GetStarInfo(true), nil);
                            self.args.callback = nil;
                        end
                        self:ShowReward(v.value, nil);
                    end);
                    self.game.commandQueue:Push(v)
                elseif v.type == "INPUT" then
                    if v.skill == 99036 then -- change auto input status
                        if v.pid == self.game.pid then
                            self:SetAutoInput( v.target == 1, true )
                        end
                    elseif v.skill == 99035 then -- input failed
                        self._current_role = self.game.timeline[1].uuid;
                        self:UNIT_INPUT(); -- cancel current input
                    elseif v.skill == 99037 then -- fast forward
                        self:Fastforward(v.target, v.refid);
                    elseif v.skill == 99038 then -- partner bullet
                        if self.view.TeamMembers then
                            local role = self.game:GetRole(nil, v.target, v.value);
                            if role and self.roles[role.uuid] then
                                local toPostion = self.roles[role.uuid].script:GetPosition("hitpoint") or Vector3.zero;
                                self.view.TeamMembers[SGK.LuaBehaviour]:Call("CreateBullet", v.pid, v.refid, v.sync_id, toPostion);
                            end
                        end
                    elseif v.skill == 99039 then -- partner skill
                        if self.view.TeamMembers then
                            self.view.TeamMembers[SGK.LuaBehaviour]:Call("CastSkill", v.pid, v.refid, v.sync_id, v.value);
                        end
                    elseif v.skill == 98000 then
                        local role = self.game:GetRole(nil, v.refid, v.sync_id);
                        self:SetFocusTag_View(role, v.target)
                        self.game.commandQueue:Push(v);
                    elseif v.skill >= 99000 then
                        -- nothing
                    else
                        self.game.commandQueue:Push(v);
                    end
                else
                    self.game.commandQueue:Push(v);
                end
            end
        else
            print("parse server command failed");
        end
    elseif cmd == T.MONSTER_DEAD then
        local refid, count, pid = data[1], data[2], data[3];
        print('player', pid, 'monster', refid, 'dead, left count', count);
        local info = self:GetSharedObject(refid);
        if info then
            info.count = count;
            self:UpdateSharedObject();
        end
    elseif cmd == T.PLAYER_FINISHED then
        local pid = data;
        print('player', pid, 'finished fight');
    elseif cmd == T.PLAYER_READY then
        print("PLAYER_READY", data);
        DispatchEvent("TeamLoadSlidingArea",{pid = data,SlidingArea = 100})
    elseif cmd == T.FIGHT_FINISHED then
        print('<color=red>fight finished</color>', data[1], data[2]);
        if data[2] then
            self.fight_result_with_score = {}
            for _, v in ipairs(data[2] or {}) do
                table.insert(self.fight_result_with_score, {v[1], v[2], v[4], v[3]});
            end
        end

        if self.wait_for_loading then
            DispatchEvent("LOADING_PROGRESS_DONE");
            DispatchEvent("TeamLoadFinished");
            self:ShowReward(data[1]);
        else
            self.server_notify_fight_finished_with_winner = data[1];
        end
    elseif cmd == T.VOTE_TO_EXIT then
        local status = data[1];
        ERROR_LOG("VOTE_TO_EXIT", unpack(data));
        if status == 3 then
            self:StartVoteToExit(data[2], data[3], data[4]);
        elseif status == 0 then
            DispatchEvent("PlayerVoteRef", {{data[2], 0}} );
            self:CallAfter(1, function()
                self.vote_end_time = nil;
                DispatchEvent("PlayerVoteFinish");
            end)
        elseif status == 1 then
            DispatchEvent("PlayerVoteRef", {{data[2], 1}} );
        end
    end
end


function BattlefieldView:OnApplicationPause(status)
    if not self.wait_for_loading and self:NeedSyncData() then
        TeamModule.SyncFightData(T.PLAYER_READY, status and 3 or 4);
    end
end

function BattlefieldView:Fastforward(tick, timeout)
    print("play module start", tick, timeout, module.Time.now())
-- [[
    self.fastforward_mode = true;
    local i = 0;
    while i < 600 and self.game.timeline.tick <= tick do
        self.game:Update(1, tick);
        i = i + 1;
    end

    self.fastforward_mode = false;
--]]
    print("play module finished", self.game.timeline.tick)
    -- not_enter_script = true;

    local role = self.game.timeline[1];
    if role and role.reading then
        self:UNIT_INPUT(role);
    end
    self.timeline:Fastforward();

    if timeout > 0 then
        timeout = timeout + 1518263653;
        self:StartTimeCounting(timeout - module.Time.now())
    end
end

function BattlefieldView:StartVoteToExit(pids, pid, end_time)
    self.vote_end_time = end_time;
    local player = module.playerModule.Get(pid);

    DialogStack.PushPref("PlayerVote", {
        EndTime = end_time,
        list = pids,
        oneselfVote = function(status)
            TeamModule.SyncFightData(T.VOTE_TO_EXIT, {status});
        end,
        --title = (player and player.name or "") .. "申请结束战斗",
        title = "<size=44>申</size>请投降",
    });
end

function BattlefieldView:AppendHurtSyncData(sync_id, hp, change, pid, hurt_index)
    self.hurt_sync_queue = self.hurt_sync_queue or {index=0};
    self.hurt_sync_queue[hurt_index] = {sync_id, hp, change, pid, hurt_index}
end

function BattlefieldView:CurrentRoleAutoInput()
    if self._current_role and not self:NeedSyncData() then
        local role = self.roles[self._current_role].role;
        if role then
            self.game.commandQueue:Push({
                pid     = self.game.pid,
                type    = "INPUT",
                refid   = role.refid,
                sync_id = role.sync_id,
                skill   = 0;
                target  = 0;
            })
        end
    end
end

function BattlefieldView:StartTimeCounting(time)
    -- if self.fastforward_mode then return; end;
    self.is_input_timeout = false;
    local timeout = self.view.battle.Canvas.timeout[SGK.BattlefieldTimeout];
    timeout:StartWithTime(time);
    self.view.battle.Canvas.timeout:SetActive(true);
    timeout.onTimeout = function()
        self.is_input_timeout = true;
        self:HideAllSelector();
        self:CurrentRoleAutoInput();
        self.view.battle.Canvas.autoSkillTips:SetActive(true);
    end
end

function BattlefieldView:UNIT_INPUT(role)
    self:SkillEffectFollow(self.skill_cast_effect, nil)
    self:SkillEffectFollow(self.skill_select_effect, nil)

    if self._current_role and not role then
        role = self.roles[self._current_role].role;
    end
    
    if not role then
        print("no found");
        return;
    end

    if not self.auto_input_inited then
        self.auto_input_inited = true;
    end

    self._current_role = role.uuid;
    self.skillInfoPanel.ErrorInfo:SetActive(false);
    self:ShowSkillInfoByIndex()
    self.view.battle.GrayLayer:SetActive(false);
    self.targetSelectorManager:Hide();
    self:ShowUI(true);

    if role.side ~= 1 and role.share_mode == 2 then
        if self.hero_timeout > 0 and self.hero_timeout  < 100 then
            self.view.battle.Canvas.timeout:SetActive(false);
        end
        return;
    end

    if self.hero_timeout > 0 and self.hero_timeout  < 100 and self.last_timeout_hero ~= role.uuid then
        self.is_input_timeout = false;
        self.last_timeout_hero = role.uuid;
        self:StartTimeCounting(self.hero_timeout)
    end

    if self.is_input_timeout then
        self.view.battle.Canvas.autoSkillTips:SetActive(true);
        return self:CurrentRoleAutoInput();
    end

    if role.side == 1 and role.pos >= 1 and role.pos <= 5 then
        self.view.battle.Canvas.SkillPanel:SetActive(true);
        self:ShowPartner(role);
    else
        self:CallRoleAction(role.uuid, "Active", true)
    end

    if self.auto_input then
        if not self:NeedSyncData() then
            self.game.commandQueue:Push({
                pid     = self.game.attacker_pid,
                type    = "INPUT",
                refid   = role.refid,
                sync_id = role.sync_id,
                skill   = 0;
                target  = 0;
            })
        end
        self.view.battle.TargetCanvas.btnCancel:SetActive(false);
        return;
    else
        --[[
        local skill_boxs = role.skill_boxs;
        for i = 1, 4 do
            local skill = skill_boxs[i];
            if skill then skill:Check() end
        end    

        local index = role:GetAutoScript():Call();
        self:CallAfter(0.2 , function ()
            self:ShowSkillAdvise(index);
        end)
        self:onSkillSelected(1, true);
        ]]
    end

    self.view.battle.TargetCanvas.btnCancel:SetActive(false);
end

function BattlefieldView:SendServerCommand(cmd)
    -- ERROR_LOG('SEND SERVER COMMAND', cmd.type);
    cmd.pid = self.game.pid;
    module.TeamModule.SyncFightData(T.PLAYER_COMMAND, {ProtobufEncode({commands={cmd}}, "com.agame.protocol.FightCommand")})
end

function BattlefieldView:PlayRandomSound(role, skill, type)
    local sounds = skill_config.GetSoundConfig(role, skill, type);
    if sounds and #sounds > 0 then
        self:PlaySound(sounds[math.random(1, #sounds)]);
    end
end

function BattlefieldView:onSkillSelected(index, no_skill_desc)
    if no_skill_desc == nil then
        no_skill_desc = self.skill_desc_toggle;
    end
    self.skill_desc_toggle = no_skill_desc;

    if self.auto_input_time or self.auto_input then
        self.view.battle.Canvas.autoSkillTips:SetActive(true);
        return;
    end

    if self.is_input_timeout then
        self.view.battle.Canvas.autoSkillTips:SetActive(true); -- TODO: 超时
        return;
    end

    if index == 11 and not OpenLevelConfig.GetStatus(3006) then
        return
    end

    if index == 12 and not OpenLevelConfig.GetStatus(3007) then
        return
    end

    index = tonumber(index);

    self.targetSelectorManager:Hide();

    if not self._current_role then
        return;
    end

    if not self.roles[self._current_role] then
        return;
    end

    local role = self.roles[self._current_role].role;
    if not role then
        print("no role found")
        return;
    end

    local skill = role.skill_boxs[index];
    if not skill then
        print("skill no found", index);
        self:ShowSkillInfoByIndex()
        return;
    end

    if index >= 1 and index <= 4 then
        self:SkillEffectFollow(self.skill_select_effect, index);
    else
        self:SkillEffectFollow(self.skill_select_effect, nil);
    end

    role:CheckSkillStatus(index);

    if skill.id and not no_skill_desc then
        -- update skill panel
        -- self:ShowSkillInfoByIndex(self.skillInfoPanel, true)
    else
        self:ShowSkillInfoByIndex()
    end

    if skill.current_cd > 0 then
        self:PlayRandomSound(role.id, skill.id, 3)
    elseif skill.disabled then
        self:PlayRandomSound(role.id, skill.id, 2)
    else
        self:PlayRandomSound(role.id, skill.id, 1)
    end

    if skill.disabled then
        print("skill is disabled", skill.name)
        self.skillInfoPanel.ErrorInfo:SetActive(true);
        self.skillInfoPanel.ErrorInfo.Text[UnityEngine.UI.Text].text = skill.error_info;
        self:UpdatePartnerStageBySkillTargetList(role, skill, true);
        return;
    else
        self.skillInfoPanel.ErrorInfo:SetActive(false);
    end

    if #skill.target_list == 0 then
        print("target list == 0", skill.name)

        local cmd = {
            pid     = self.game.attacker_pid,
            type    = "INPUT",
            refid   = role.refid,
            sync_id = role.sync_id,
            tick    = self.game.timeline.tick,
            skill   = index;
            target  = 0;
        };

        if self:NeedSyncData() then
            self:SendServerCommand(cmd)
        else
            self._current_role = nil;
            self.game.commandQueue:Push(cmd)
        end

        return;
    end

    self.waiting_input_skill_index = index;
    self.waiting_input_target_index = nil;

    self:UpdatePartnerStageBySkillTargetList(role, skill, true);
end

function BattlefieldView:UpdatePartnerStageBySkillTargetList(role, skill, showTargetSelector)
    showTargetSelector = not not showTargetSelector;

    local showAllPartner = false;
    local forceHideSkillPanel = false;
    local have_enemy = false;
    for _, v in ipairs(skill.target_list) do
        local pos = 0;
        local uuid = -1;
        if v.target == "enemy" then
            pos = (role.side == 1) and -2 or -1;
            uuid = pos
            have_enemy = true;
        elseif v.target == "partner" then
            pos = (role.side == 1) and -1 or -2;
            uuid = pos
        else
            pos = v.target.pos;
            uuid = v.target.uuid;
            have_enemy = have_enemy or (v.target.side ~= 1);
        end

        local main = v.target.owner == 0 and v.target or v.target.owner;
        if pos == -1 or ( main and main.side == 1 and main.uuid ~= role.uuid) then
            showAllPartner = true;
        end

        if main and main.side == 1 and self.view.TeamMembers then
            forceHideSkillPanel = true;
        end

        if showTargetSelector then
            local type = 1;
            if main and main.side == 1 then
                type = 1;  -- 按钮不互相挤开
                if self.view.TeamMembers and showAllPartner and #skill.target_list > 1 and (v.target.pos == 2 or v.target.pos == 4) then
                    type = 3; -- 按钮位置向下偏移
                end
            end
            self.targetSelectorManager:Show(uuid, self.roles[uuid] and self.roles[uuid].script, type, v.button, "UI/fx_butten_start");--table.unpack(v.effects or {}));
        end
    end

    if showAllPartner then
        self:ShowPartner();
        self:SkillEffectFollow(self.skill_cast_effect, nil)
        self:SkillEffectFollow(self.skill_select_effect, nil)
    elseif role.side == 1 and role.pos >= 1 and role.pos <= 5 then
        self:ShowPartner(role);
    end

    if role.side == 1 and not have_enemy and #skill.target_list > 0 then
        self.view.battle.GrayLayer:SetActive(true);
    else
        self.view.battle.GrayLayer:SetActive(false);
    end

    if role.side == 1 then
        self:ShowSkillOfRole(role, forceHideSkillPanel or showAllPartner);
    end

    return showAllPartner;
end

function BattlefieldView:onTargetSelected(uuid)
    if self.is_input_timeout then
        self.view.battle.Canvas.autoSkillTips:SetActive(true); -- TODO: 超时
        return;
    end

    local role = self.roles[self._current_role].role;
    if uuid == -1 then
        uuid = (role.side == 1) and "partner" or "enemy"
    elseif uuid == -2 then
        uuid = (role.side == 1) and "enemy" or "partner"
    end

    local skill_index = self.waiting_input_skill_index;
    local skill = role.skill_boxs[skill_index];

    local target = nil;

    for k, v in ipairs(skill.target_list or {}) do
        if v.target == uuid or v.target.uuid == uuid then
            target = k;
            break;
        end
    end

    self:HideAllSelector();

    self._current_role = nil;
    self.waiting_input_skill_index = nil;
    
    local cmd = {
        type    = "INPUT",
        pid     = self.game.attacker_pid,
        refid   = role.refid,
        sync_id = role.sync_id,
        skill   = skill_index;
        tick    = self.game.timeline.tick,
        target  = target;
    };

    if self:NeedSyncData() then
        self:SendServerCommand(cmd)
    else
        self.game.commandQueue:Push(cmd)
    end

    if role.side == 1 then
        self:ShowSkillOfRole(role);
    end

    self.view.battle.TargetCanvas.btnCancel:SetActive(false);
end

function BattlefieldView:UNIT_CAST_SKILL(role, skill)
    local index = skill and skill.index;
    self:PlayRandomSound(role.id, skill.id, 5)
    -- print("!!!!!!!!!!", role.name, 'UNIT_CAST_SKILL', skill.index, self.skillManager:IsActive());

    if role.side == 1 and index and index >= 1 and index <= 4 then
        self:SkillEffectFollow(self.skill_cast_effect, index)
        self:SkillEffectFollow(self.skill_select_effect, nil)
    end

    self:UpdatePartnerStageBySkillTargetList(role, skill);

    if self.view.TeamMembers then
        self.view.TeamMembers[SGK.LuaBehaviour]:Call("CastSkill", self.game.attacker_pid, role.refid, role.sync_id, skill.icon);
    end
end

function BattlefieldView:SKILL_CANCEL_SELECTED()
    self:UNIT_INPUT();
end

function BattlefieldView:SKILL_1_SELECTED()
    self:onSkillSelected(1, false)
end

function BattlefieldView:SKILL_2_SELECTED()
    self:onSkillSelected(2, false)
end

function BattlefieldView:SKILL_3_SELECTED()
    self:onSkillSelected(3, false)
end

function BattlefieldView:SKILL_4_SELECTED()
    self:onSkillSelected(4, false)
end

function BattlefieldView:SKILL_DIAMOND_SELECTED()
    self:onSkillSelected(Skill.ID_DIAMOND, false);
end

function BattlefieldView:SKILL_IDLE_SELECTED()
    self:onSkillSelected(12, false)
end

function BattlefieldView:SKILL_DEF_SELECTED()
    self:onSkillSelected(11, false)
end

function BattlefieldView:ShowSkillOfRole(role, hideSkillPanel)
    if not role or role.side ~= 1 then
        self.skillManager:Hide()
        self.show_skill_target = role;
        self.view.battle.TargetCanvas.btnCancel:SetActive(false)
        return;
    end

    if self.show_skill_target == role then
        -- if not self.skill_icon_changing then
            self:ChangeSkillIcon(true);
        -- end

        -- [[
        if role.skill_boxs[Skill.ID_DIAMOND] then
            self.skillManager:Show(true);
        else
            self.skillManager:Show(false);
        end
        --]]
    else
        self.skill_icon_changing = true;
        if role.skill_boxs[Skill.ID_DIAMOND] then
            self.skillManager:Switch(true);
        else
            self.skillManager:Switch(false);
        end
    end

    self.show_skill_target = role;

    if hideSkillPanel ~= nil then
        CanvasGroupActive(self.view.battle.Canvas.SkillPanel, not hideSkillPanel);
        if hideSkillPanel and self._current_role and not self.auto_input then
            self.view.battle.TargetCanvas.btnCancel:SetActive(true)
        else
            self.view.battle.TargetCanvas.btnCancel:SetActive(false)
        end
    end
end

function BattlefieldView:ChangeSkillIcon(use_animate)
    self.skill_icon_changing = false;
    local role = self.show_skill_target or self.current_action_role or self.game.timeline.current_running_obj 
    if not role then
        return;
    end

    -- self:ChangeOneSkillIcon(role.skill_boxs[1], self.view.battle.TargetCanvas.SkillPanel.Skill1);
    self:ChangeOneSkillIcon(role.skill_boxs[2], self.view.battle.Canvas.SkillPanel.Skill2, use_animate);
    self:ChangeOneSkillIcon(role.skill_boxs[3], self.view.battle.Canvas.SkillPanel.Skill3, use_animate);
    self:ChangeOneSkillIcon(role.skill_boxs[4], self.view.battle.Canvas.SkillPanel.Skill4, use_animate);
    self:ChangeOneSkillIcon(role.skill_boxs[12], self.view.battle.Canvas.SkillPanel.SkillIdle);
    self:ChangeOneSkillIcon(role.skill_boxs[11], self.view.battle.Canvas.SkillPanel.SkillDef);

    if role.skill_boxs[Skill.ID_DIAMOND] then
        self.view.battle.Canvas.SkillPanel.SkillDiamon.Button[CS.UGUISpriteSelector].index = role.diamond_index - 1;
    end
end

function BattlefieldView:ChangeOneSkillIcon(skill, node, use_animate)
    if not skill or not node then
        return;
    end

    if not node.Button then
        node.Name[UnityEngine.UI.Text].text = skill.name;
        node[CS.UGUIColorSelector].index = (skill.current_cd > 0) and 1 or 0;
        return
    end

    local sprite = SGK.ResourcesManager.Load("icon/" .. skill.icon, typeof(UnityEngine.Sprite));
    if not use_animate then
        node.Button[UnityEngine.UI.Image].sprite = sprite;
    end
    node.Button[CS.CardFlipImage].sprite = sprite;
    node.Name[UnityEngine.UI.Text].text = skill.name;

    node.Button[CS.UGUIColorSelector].index = (skill.disabled or skill.current_cd > 0) and 1 or 0;

    if node.Button.Cooldown then
        node.Button.Cooldown[UnityEngine.UI.Text].text = (skill.current_cd > 0) and tostring(skill.current_cd) or ""
    end
end

function BattlefieldView:SKILL_CHANGE(role, skill)
    if not self.game.timeline.current_running_obj and not self.current_action_role then
        return;
    end

    local role = self.current_action_role or self.game.timeline.current_running_obj

    self:ShowSkillOfRole(role);
end

function BattlefieldView:HideAllSelector()
    self.targetSelectorManager:Hide();
    self:ShowSkillInfoByIndex()
    -- self.view.battle.GrayLayer:SetActive(false);
end

function BattlefieldView:CallAfter(n, func) 
    SGK.Action.DelayTime.Create(n):OnComplete(func):SetTarget(self.view.battle.gameObject):Play();
end

--[[
function BattlefieldView:UnitAddBuff(role, uuid, icon)
    self:getRoleManager(role):AddBuff(role.pos, uuid, icon)
end

function BattlefieldView:UnitRemoveBuff(role, uuid)
    self:getRoleManager(role):RemoveBuff(role.pos, uuid);
end
--]]
function BattlefieldView:ChangeBuffEffect(buff, effect)
    if type(effect) ~= "table" then
        ERROR_LOG("buff effect must be a table")
        return
    end

    if buff.effect.gameObject then
        self.gameObjectPool:Release(buff.effect.gameObject)
    end

    effect.duration = -1
    buff.effect = effect
    self:UnitAddEffect(buff.target, buff.effect.name, buff.effect, function(o)
        buff.effect.gameObject = o
    end)
end

function BattlefieldView:BUFF_Add(buff, role)
    if buff.cfg and buff.cfg ~= 0 then
        for i= 1, 3, 1 do
            if buff.attacker.uuid == buff.target.uuid and buff.attacker.pos >= 100 then
                break
            end

            local effect = buff.cfg["buff_effect"..i]
            if effect and effect ~= "" and effect ~= "0" then
                self:UnitShowBuffEffect(buff.target, effect, string.find(effect,"up"))
            end
        end

        if buff[7096] > 0 then
            self:UnitShowBuffEffect(buff.target, "护盾值up", true)
        end
    end

    if type(buff.effect) == "table"  then
        buff.effect.duration = buff.effect.duration or -1;
        if buff.effect.duration < 0 and not buff.effect.effect_auto_hide_type then
            buff.effect.effect_auto_hide_type = 1;
        end

        self:UnitAddEffect(role, buff.effect.name, buff.effect, function(o)
            buff.effect.gameObject = o;
        end);

        if buff.effect.duration > 0 then
            buff.effect.gameObject = nil;
        end
    else
        buff.effect = {};
    end
    
    if buff.icon and buff.icon ~= 0 and buff.hide == 0 then
        self:CallRoleAction(role.uuid, "AddBuff", buff.id, tostring(buff.icon));
    end
end

function BattlefieldView:BUFF_Remove(buff, role)
    if type(buff.effect) == "table" and buff.effect.gameObject then
        self.gameObjectPool:Release(buff.effect.gameObject);
    end

    self:CallRoleAction(role.uuid, "RemoveBuff", buff.id);
end

function BattlefieldView:UnitPlay(role, action)
    if self.fastforward_mode then return end

    if not role then
        ERROR_LOG("UnitPlaye call with nil", debug.traceback())
	    return;
    end
    self:CallRoleAction(role.uuid, "Play", action, "idle");
end

function BattlefieldView:UnitPlayLoopAction(role, action)
    if self.fastforward_mode then return end

    if not role then
        ERROR_LOG("UnitPlaye call with nil", debug.traceback())
	    return;
    end
    self:CallRoleAction(role.uuid, "Play", action);
end

function BattlefieldView:UpdateObjectPropertyValue(role)
    local mp, mpp = role.mp, role.mpp;

    local cfg = HeroModule.GetConfig(role.id) or battle_config.LoadNPC(role.id);
    if cfg and cfg.mp_type == 8001 then
        mp, mpp = role.ep, role.epp;
    elseif cfg and cfg.mp_type == 8002 then
        mp, mpp = role.fp, role.fpp
    end

    self:CallRoleAction(role.uuid, "UpdateProperty", role.hp, role.hpp, mp, mpp, role.shield);

    if self.view.TeamMembers then
        self.view.TeamMembers[SGK.LuaBehaviour]:Call("SetHP", self.game.attacker_pid, role.refid, role.sync_id, role.hp / role.hpp);
    end
end

local function AfterLoadEffect(o, position, sortOrder, parent)
    if o then
        o:SetActive(true);
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localScale = Vector3.one;
        transform.localRotation = Quaternion.identity;

        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o;
end

function BattlefieldView:LoadEffectAsync(effectName, position, sortOrder, callback)
    if effectName and effectName ~= "" and effectName ~= "0" and effectName ~= 0 then
        local effctFilePath = "prefabs/effect/" .. effectName;
        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], effctFilePath, function(prefab)
            local effect = self.gameObjectPool:Get(effctFilePath);
            callback(AfterLoadEffect(effect, position, sortOrder, self.view.battle.transform));
        end)
    else
        callback(nil);
    end
end

function BattlefieldView:CreateBullet(from, to, name, cfg)
    if self.fastforward_mode then return end

    cfg = cfg or {};
    local duration = cfg.duration or 0.5;

    if name == nil then
        return;
    end

    local to_hitpoint = cfg.hitpoint or "hitpoint"
    local toPostion = self.roles[to.uuid] and self.roles[to.uuid].script:GetPosition(to_hitpoint) or Vector3.zero;

    self:LoadEffectAsync(name, nil, nil, function(bullet)
        if not bullet then
            return;
        end

        bullet.transform.position = self.roles[from.uuid] and self.roles[from.uuid].script:GetPosition("hitpoint") or Vector3.zero;

        bullet.transform:LookAt(toPostion, Vector3(0, 0, 1))
        bullet.transform.localEulerAngles = Vector3(bullet.transform.localEulerAngles.x, bullet.transform.localEulerAngles.y, 0)
        bullet.transform:DOMove(toPostion, duration):Play();

        self.gameObjectPool:Release(bullet, duration);
    end);

    if false and self.view.TeamMembers and from.side == 1 then
        if to.side == 2 then
            local refid, sync_id = from.refid, from.sync_id;
            if from.owner ~= 0 then
                refid, sync_id = from.owner.refid, from.owner.sync_id;
            end
            self.view.TeamMembers[SGK.LuaBehaviour]:Call("CreateBullet", self.game.attacker_pid, refid, sync_id, toPostion);
        end
    end
end

function BattlefieldView:BULLET_targetAfterHit(target, bullet)
    if self.fastforward_mode then return end

    if bullet.hurt_final_value > 0 then
        local info = self.roles[target.uuid];
        if info and info.object then
            local animate = info.object:GetComponent(typeof(UnityEngine.Animator));
            if animate then
                animate:SetTrigger("Hit");
            end
        end
    end
end

function BattlefieldView:UpdateRoleEpBar(role)
    local info = self.roles[role.uuid];
    if info and info.object then
        local script
        if role.pos == 11 then
            script = self.view.battle.Canvas.EnemyBossUISlot:GetComponentsInChildren(typeof(CS.BattleEnergyBar))
        else
            script = info.object:GetComponentsInChildren(typeof(CS.BattleEnergyBar));
        end

        if script then
            script[0]:SetValue(role.ep, role.side)
        end
    end
end

function BattlefieldView:UnitShow(role, hide)
    local info = self.roles[role.uuid]
    if info and info.object then
        info.object.transform.localPosition = hide and UnityEngine.Vector3(500, 0, 0) or GetRolePostionOffset(role)
        -- info.object:SetActive(not hide);
    end

    if info and not hide and info.hide then
        info.hide = false;
        
        info.script:ChangeMode(tostring(info.role.mode), info.role.scale);
        info.object.transform.localPosition = GetRolePostionOffset(info.role)

        info.script:ShowUI(true);

        self:UpdateObjectPropertyValue(info.role)
    end
end

function BattlefieldView:UnitAddEffect(role, effectName, cfg, callback)

    if self.fastforward_mode then return end

    if not effectName then
        return
    end

    cfg = cfg or {}
    local point = cfg.hitpoint or "hitpoint"
    local offset = cfg.offset and Vector3(unpack(cfg.offset)) or Vector3.zero;

    local duration = cfg.duration or 3
    local scale = cfg.scale or 1;
    
    scale = scale * (role.effect_scale > 0 and role.effect_scale or 1);

    local rotation = cfg.rotation or 0;

    local info = self.roles[role.uuid];
    if info and info.object then
        local sortOrder;
        if role.side == 1 then
            sortOrder = 5;
        end

        self:LoadEffectAsync(effectName, nil, sortOrder, function(o)
            if o == nil then
                return;
            end

            o.transform:Rotate(Vector3.forward * rotation);
            if info.pet and info.pet.owner
                and self.roles[info.pet.owner.uuid] 
                and self.roles[info.pet.owner.uuid].script
                and self.roles[info.pet.owner.uuid].script.petBar then
                local sx = self.roles[info.pet.owner.uuid].script.petBar.localScale.x;
                scale = scale * sx / 0.5;
            end

            if cfg.spine_action then
                local objects = o.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation), true)
                objects[0].AnimationState:SetAnimation(0 , cfg.spine_action, false)
            end

            if cfg.text then
                local objects = o.transform:GetComponentsInChildren(typeof(UnityEngine.TextMesh), true)
                if type(cfg.text) == "string" then
                    for i = 1, objects.Length do
                        if objects[i-1].gameObject.tag == "big_skill" then
                            objects[i-1].text = cfg.text;
                            break;
                        end
                    end
                elseif type(cfg.text) == "table" then
                    local slots = {};
                    for i = 1, objects.Length do
                        if objects[i-1].gameObject.tag == "big_skill" then
                            table.insert(slots, objects[i-1]);
                        end
                    end

                    for k, v in ipairs(cfg.text) do
                        if slots[k] then
                            slots[k].text = v
                        end
                    end
                end
            end

            local cameraScripts = o:GetComponents(typeof(SGK.BattleCameraScriptAction));
            if cameraScripts then
                for i = 0, cameraScripts.Length - 1 do
                    local script = cameraScripts[i]
                    if script.autoTarget then
                        script.target = info.object.transform;
                    else
                        script.target = self.view.battle.player.gameObject.transform;
                    end
                end
            end

            if duration > 0 then
                self.gameObjectPool:Release(o, duration);
            else
                callback(o);
                -- return o;
            end

            info.script:AddEffectToSlot(point, o, offset, cfg.effect_auto_hide_type or 0)
            o.transform.localScale = Vector3.one * scale;
            if cfg.opposite then o.transform.localScale = Vector3(1, 1, -1) * scale end
        end);
    end
end

function BattlefieldView:UpdateSkeletonDataAsset(skeletonAnimation, name, hitpoint)
    CS.SkeletonAnimationAnchoredPosition.Attach(skeletonAnimation, hitpoint);
    skeletonAnimation:UpdateSkeletonAnimation(string.format("roles/%s/%s_SkeletonData", name, name));
end

function BattlefieldView:SkipCurrentEffect()
    if self:NeedSyncData() then
        return
    end
    
    self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(false)
    if not self.current_long_time_effect then
        return
    end

    self.current_long_time_effect:SetActive(false)
    self.current_long_time_effect = nil
    self.game:CleanSleep()
end

function BattlefieldView:AddStageEffect(role, id, index, duration, cfg)
    if self.fastforward_mode then return end

    local skill_cfg = self.game:API_GetSkillEffectCfg(nil, id)
    if not skill_cfg then
        return
    end

    local effectName = skill_cfg["stage_effect_"..index]
    if effectName == "" or effectName == 0 or effectName == "0" then
        return    
    end

    cfg = cfg or {};
    if cfg.click_skip and self.auto_input and not self:NeedSyncData() then
        self.game:CleanSleep()
        return
    end

    if role and effectName == "UI/fx_zhaohuanwu" and role.side ~= 1 then
        effectName = "UI/fx_zhaohuanwu_di"
    end

    local position = cfg.offset and Vector3(unpack(cfg.offset)) or Vector3.zero;

    local duration = duration or 1.0;
    local scale = cfg.scale or 1;
    local rotation = cfg.rotation or 0;

    local hitpoint = cfg.hitpoint or "root";

    if effectName then
        self:LoadEffectAsync(effectName, position, nil, function(o)
            if o == nil then
                return;
            end

            if o.tag == "camera_skill_effect" then
                o.transform.parent = self.view.battle.player.MainCamera.CameraEffectSlot.transform;
                o.transform.localPosition = position;
            end

            if cfg.spine_action then
                local objects = o.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation), true)
                objects[0].AnimationState:SetAnimation(0 , cfg.spine_action, false)
            end

            o.transform.localScale = Vector3.one * scale;
            if cfg.opposite then o.transform.localScale = Vector3(1, 1, -1) * scale end
            o.transform.localRotation = Quaternion.Euler(0, 0, rotation);

            if cfg.mode then
                local objects = o.transform:GetComponentsInChildren(typeof(Spine.Unity.SkeletonAnimation), true)
                for i = 1, objects.Length do
                    if objects[i-1].gameObject.tag == "big_skill" then
                        self:UpdateSkeletonDataAsset(objects[i-1], cfg.mode, hitpoint)
                    end
                end
            end

            if cfg.modes then
                local slots = {};
                local objects = o.transform:GetComponentsInChildren(typeof(Spine.Unity.SkeletonAnimation), true)
                for i = 1, objects.Length do
                    if objects[i-1].gameObject.tag == "big_skill" then
                        table.insert(slots, objects[i-1]);
                    end
                end

                for k, v in ipairs(cfg.modes) do
                    if slots[k] then
                        self:UpdateSkeletonDataAsset(slots[k], v, hitpoint)
                    end
                end
            end

            if cfg.Halo_icon then
                local slots = {};
                local objects = o.transform:GetComponentsInChildren(typeof(UnityEngine.SpriteRenderer), true)
                for i = 1, objects.Length do
                    if objects[i-1].gameObject.tag == "big_skill" then
                        table.insert(slots, objects[i-1]);
                    end
                end

                for k, v in ipairs(cfg.Halo_icon) do
                    if slots[k] then
                        slots[k].sprite = SGK.ResourcesManager.Load("icon/" .. v, typeof(UnityEngine.Sprite));
                    end
                end
            end

            if cfg.text then
                local objects = o.transform:GetComponentsInChildren(typeof(UnityEngine.TextMesh), true)
                if type(cfg.text) == "string" then
                    for i = 1, objects.Length do
                        if objects[i-1].gameObject.tag == "big_skill" then
                            objects[i-1].text = cfg.text;
                            break;
                        end
                    end
                elseif type(cfg.text) == "table" then
                    local slots = {};
                    for i = 1, objects.Length do
                        if objects[i-1].gameObject.tag == "big_skill" then
                            table.insert(slots, objects[i-1]);
                        end
                    end

                    for k, v in ipairs(cfg.text) do
                        if slots[k] then
                            slots[k].text = v
                        end
                    end
                end
            end

            if cfg.click_skip then
                self.current_long_time_effect = o
                self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(true)
                self:CallAfter(duration, function ()
                    self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(false)
                    self.current_long_time_effect = nil
                end)
            end
            
            self.gameObjectPool:Release(o, duration);
        end);
    end
end


function BattlefieldView:UNIT_DEAD(role)
    
    print(role.name, 'DEAD');
    self:PlayRandomSound(role.id, 0, 6)

    self.dead_role_list = self.dead_role_list or {}
    
    if role.side ~= 1 then
        -- local o = self.game.timeline[1];
        if not self.game.timeline.running then -- (o and o.reading) or (self.game.timeline.winner) then
            self:UNIT_DEAD_(self.roles[role.uuid]);
        else
            self.dead_role_list[role.uuid] = self.roles[role.uuid];
        end
    end

    self:UnitChangeExposure(role, -1);

    if self.roles[role.uuid].script.icon then
        self.roles[role.uuid].script.icon.image.gameObject:GetComponent(typeof(CS.ImageMaterial)).active = true;
        self.roles[role.uuid].script.icon.hpBar.gameObject:SetActive(false);
    end

    self.roles[role.uuid].script:ShowWarning(1);
    self.roles[role.uuid].script:SetQualityColor(UnityEngine.Color.red);

    self:UpdateObjectPropertyValue(role)

    if role.side ~= 1 and self._current_role and self.waiting_input_skill_index then
        self:onSkillSelected(self.waiting_input_skill_index);
    end
end

function BattlefieldView:UNIT_DEAD_(info)
    local gameObject = info.object;
    local script     = info.script;

    if info.dead then
        return;
    end

    info.dead = true;
    script:ChangeMode("");
    script:ShowUI(false);

    if self.fastforward_mode then return end

    self:LoadEffectAsync("UI/fx_death", gameObject.transform.position, nil, function(death)
        if death then
            death.transform.parent = gameObject.transform.parent;
            death.transform.localPosition = gameObject.transform.localPosition;
            death.transform.localScale = Vector3.one;
            death.transform.localRotation = Quaternion.identity;
        end
    end)
--[[
    SGK.Action.DelayTime.Create(1):OnComplete(function()
        local dead_actions = {"animation0", "animation1", "animation2"}
        script:ChangeMode("00001", 1.0, dead_actions[math.random(1,#dead_actions)]);
    end):SetTarget(self.view.gameObject):Play();
--]]
end

function BattlefieldView:PET_Enter(role, pet)
    if not self.roles[pet.uuid] then
        local petObject = UnityEngine.GameObject.Instantiate( (pet.side == 1) and self.pet_prefab or self.pet_prefab_enemy);
        local script =  petObject:GetComponent(typeof(SGK.BattlefieldObjectPet));

        self:CallRoleAction(role.uuid, "AddPet", pet.uuid, petObject);
        script:ChangeMode(tostring(pet.icon));
        self.roles[pet.uuid] = {role = role, pet = pet, object = petObject, script = script, pet_script = script};
    end

    -- print("!!!", pet.uuid, pet.count)
    -- self.roles[pet.uuid].pet_script:UpdateUI(pet:hp_percent(), pet:first_cd(), pet.count, pet.order);
end

function BattlefieldView:UpdatePet(role, pet)
    self.removed_pet_list = self.removed_pet_list or {};
    self.removed_pet_list[pet.uuid] = nil;

    local info = self.roles[pet.uuid] 
    if info and info.pet_script then
        info.pet_script:UpdateUI(pet:hp_percent(), pet:first_cd(), pet.count, pet.order);
    end
end

function BattlefieldView:RemovePet(role, pet, force)
    self.removed_pet_list = self.removed_pet_list or {};
    self.removed_pet_list[pet.uuid] = {role=role, pet=pet};


    if force then
        self:CallRoleAction(role.uuid, "RemovePet", pet.uuid);
        self.removed_pet_list[pet.uuid] = nil;
    else
        local info = self.roles[pet.uuid] 
        if info then
            self.roles[info.pet.uuid] = nil; 
            if info.pet_script then
                info.pet_script:UpdateUI(0, 0, pet.count, pet.order);
            end
        end
    end
end

function BattlefieldView:CameraMoveTo(pos, offset, time)
    -- do return end;

    pos = pos or 0;
    offset = offset and Vector3(unpack(offset)) or Vector3.zero;
    time = time or 0.1;

    local target = self.view.partner_slots[pos] or self.view.enemy_slots[pos];
    local transform = target and target.gameObject.transform;
    
    self.cameraController:CameraMoveTo(transform, offset, time);
end

function BattlefieldView:CameraLookAt(pos, offset, time)
    -- do return end;

    pos = pos or 0;
    offset = offset and Vector3(unpack(offset)) or Vector3.zero;
    time = time or 0.1;

    local target = self.view.partner_slots[pos] or self.view.enemy_slots[pos];
    local transform = target and target.gameObject.transform;

    self.cameraController:CameraLookAt(transform, offset, time);
end

function BattlefieldView:EnemyMoveFront(target, offset) 
    if self.fastforward_mode then return end

    local info = self.roles[target.uuid]
    if info and info.object then
        offset = offset and Vector3(unpack(offset)) or Vector3.zero;
        offset = self.view.battle.transform.position + offset + Vector3(0, 0, -1);
        info.object.transform:DOMove(offset, 0.1):Play();
    end
end

function BattlefieldView:EnemyMoveBack(target) 
    if self.fastforward_mode then return end

    local info = self.roles[target.uuid]
    if info and info.object then
        info.object.transform:DOMove(GetRolePostionOffset(target), 0.1):Play()
    end
end

function BattlefieldView:PlaySound(sound) 
    if self.fastforward_mode then return end

    if self.audioSource == nil then
        self.audioSource = self.view.battle.partnerStage[SGK.AudioSourceVolumeController]
    end
    -- self.audioSource.volume=System_Set_data.StoryVoice or 0.5
    self.audioSource:Play("sound/" .. sound)
end

function BattlefieldView:CHANGE_SCENE(name)
    if self.fastforward_mode then return end
    
    local name = name or self.fight_data.scene
    if name == "" or name == "0" or name == 0 then
        name = "18hao"
        print("fight scene not found !=======!")
    end
    
    local oldScene = UnityEngine.GameObject.FindWithTag("battle_env");
    if oldScene and oldScene.name == name then
        return;
    end

    SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/environment/" .. name, function(prefab)
        if prefab == nil then
            print('fight scene', name, 'not exists');
            return;
        end

        local env = UnityEngine.GameObject.Instantiate(prefab)
        env.name = name;
        
        if oldScene then
            UnityEngine.GameObject.Destroy(oldScene)
        end

        local anchor = UnityEngine.GameObject.FindWithTag("battle_anchor");
        if anchor then
            DispatchEvent("LOADING_PROGRESS_UPDATE", 0.15, "find anchor")
            self.view.battle.gameObject.transform.position = anchor.transform.position;
            CS.FollowTarget.Follow(self.view.battle.gameObject, anchor, -1, true);
            self.battle_anchor_animator = anchor:GetComponent(typeof(UnityEngine.Animator));
            --if string.sub(tostring(self.battle_anchor_animator), 1, 5) ~= "null:" then
            if utils.SGKTools.GameObject_null(self.battle_anchor_animator) == false then
                -- self.battle_anchor_animator:SetInteger("Wave", self.game.timeline.wave);
            else
                self.battle_anchor_animator = nil;
            end
            self.battle_anchor_animator = nil;
        end
    end)
end

function BattlefieldView:ShowTotalHurt(role, value)

    if role ~= self.game.timeline.current_running_obj or role ~= self.current_action_role then
        return
    end

    if not self.total_hurt then
        self.total_hurt = self.view.battle.TargetCanvas.total_hurt
    end

    if not self.total_hurt.activeSelf and self.total_hurt.show_count == 0 then
        self.total_hurt.value = 0
    end

    if role ~= self.total_hurt.current_role or self.total_hurt.current_round ~= self.game.timeline.total_round then
        self.total_hurt.value = 0
        self.total_hurt.show_count = 0
    end

    self.total_hurt.value = self.total_hurt.value + value
    self.total_hurt.Text[UnityEngine.UI.Text].text = tostring(self.total_hurt.value)
    self.total_hurt[SGK.LuaBehaviour]:Call("Refresh")


    self.total_hurt.show_count = self.total_hurt.show_count + 1
    self.total_hurt:SetActive(self.total_hurt.show_count > 1)
    self.total_hurt.current_role = role
    --补漏，并不严谨
    self.total_hurt.current_round = self.game.timeline.total_round
end

function BattlefieldView:ClearTotalHurt(id)
    if self.total_hurt_list then
        self.total_hurt_list[id] = nil
    end
end

function BattlefieldView:SHOW_DIALOG(role, text, duration, effect, cfg)
    if self.fastforward_mode then return end

    local time = os.time()
    if role.dialog_time and (time - role.dialog_time < 4) then
        return
    end
    role.dialog_time = time

    if effect then
        self:UnitAddEffect(role, effect, {
            text = text,
            duration = duration,
            hitpoint = "head",
            offset = cfg.offset,
            scale = cfg.scale
        })
    else
        self.targetSelectorManager:ShowDialog(self.roles[role.uuid] and self.roles[role.uuid].script, text, duration);
    end
end

function BattlefieldView:UnitChangeColor(target, color, params)
    local info = self.roles[target.uuid];
    if info and info.script then
        info.script:SetColor(UnityEngine.Color(color[1]/255, color[2]/255, color[3]/255), params and params.duration or 600);
    end
end

function BattlefieldView:UnitChangeAlpha(target, alpha)
    local info = self.roles[target.uuid];
    if info and info.script then
        info.script:SetAlpha(alpha);
    end
end

function BattlefieldView:UnitChangeExposure(target, exposure, params) 
    local info = self.roles[target.uuid];
    if info and info.script then
        info.script:SetExposure(exposure);
    end
end

function BattlefieldView:UnitChangeSkin(target, skinName)
    self.view.partner_objects[target.pos].UIPartner.element[CS.UGUISpriteSelector].index = GetMasterIcon(target)
    local info = self.roles[target.uuid];
    if info and info.script then
        info.script:SetSkin(skinName);
    end
end

function BattlefieldView:ASSISTANT_BEFORE_ACTION(_, role)
    if self.fastforward_mode then return end

    self.view.battle.Canvas.AssistInfo:SetActive(true)
    self.view.battle.Canvas.AssistInfo.Text:TextFormat("我方援助角色行动")
end

function BattlefieldView:ASSISTANT_ACTION(_, role)
    if self.fastforward_mode then return end

    local parent = self.view.battle.partnerStage.assetAttackPosition.gameObject.transform;
    
    local go = self.gameObjectPool:Get('prefabs/effect/UI/fx_yuanzhu')

    go.transform.localPosition = Vector3.zero;
    go.transform.localScale = Vector3.one;
    go.transform.localRotation = Quaternion.identity;
    
    go.transform:SetParent(parent, false);
    go:SetActive(true);

    local view = SGK.UIReference.Setup(go);

    local skeletonAnimation = view[1][CS.Spine.Unity.SkeletonAnimation];

    local skeletonDataName = string.format("roles/%s/%s_SkeletonData", role.mode, role.mode);
    
    skeletonAnimation:UpdateSkeletonAnimation(skeletonDataName)

    -- self.assistant_local_position = self.assistant_local_position or skeletonAnimation.gameObject.transform.localPosition;
    CS.SkeletonAnimationAnchoredPosition.Attach(skeletonAnimation, "hitpoint")

    -- local pos = SGK.BattlefieldObject.GetSkeletonBonePosition(skeletonAnimation, "hitpoint");
    -- skeletonAnimation.gameObject.transform.localPosition = -pos;

    local MaskableSkeletonAnimation = view[1][SGK.MaskableSkeletonAnimation]
    if MaskableSkeletonAnimation then
        MaskableSkeletonAnimation:UpdateStencil();
    end

    self.gameObjectPool:Release(go, 3);
end

function BattlefieldView:ShowHeadPanel()
    if self.view.battle.Canvas.RoleInfoPanel_loading then
        return;
    end

    self.view.battle.Canvas.RoleInfoPanel_loading = true

    if self.view.battle.Canvas.RoleInfoPanel == nil then
        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/RoleInfoPanel", function(o)
            self.view.battle.Canvas.RoleInfoPanel = SGK.UIReference.Instantiate(o);
            self.view.battle.Canvas.RoleInfoPanel.transform:SetParent(self.view.battle.PersistenceCanvas.transform, false);
            self:ShowHeadPanelAfterLoad();
        end)
    else
        self:ShowHeadPanelAfterLoad();
    end
end

function BattlefieldView:ShowHeadPanelAfterLoad()
    self.view.battle.Canvas.RoleInfoPanel_loading = nil;

    local headManager = self.view.battle.Canvas.RoleInfoPanel[SGK.BattlefiledHeadManager];

    headManager:Clear();

    local prefab = self.view.battle.Canvas.RoleInfoPanel.IconFrame.gameObject;
    

    local listener = nil;
    for uuid, v in pairs(self.roles) do
        if not v.hide and v.role.hp > 0 then
            if v.pet and v.pet.hp <= 0 then
            else 
                local icon = nil
                local info = nil;
                if v.pet then
                    icon = SGK.UIReference.Setup(headManager:Show(v.script, prefab, 0));
                    info = {
                        icon = v.pet.icon,
                        quality = 0,
                        star = 0,
                        level = v.pet.level,
                        pos = 0,
                    }
                    if v.pet.owner.pos == 11 then
                        icon.transform.position = v.script.gameObject.transform.position;
                    end
                else
                    local stageCfg = HeroEvoConfig.GetConfig(v.role.id);
                    local cfg = stageCfg and stageCfg[v.role.grow_stage];
                    icon = SGK.UIReference.Setup(headManager:Show(v.script, prefab, (v.role.side == 1) and v.role.pos or 0));
                    info = {
                        icon = v.role.icon,
                        quality = cfg and cfg.quality or 1,
                        star = v.role.grow_star,
                        level = v.role.level,
                        pos = (v.role.side == 1) and v.role.pos or 0,
                    }
                end

                utils.IconFrameHelper.Create(icon, {customCfg = info, type = 42});

                CS.UGUIClickEventListener.Get(icon.gameObject).onClick = function()
                    self:ShowRoleDetail(uuid);
                end
                --[[
                listener.onClick = function()
                    self:ShowRoleDetail(uuid);
                end
                --]]
            end
        end
    end
    self.view.battle.Canvas.RoleInfoPanel:SetActive(true)
end

local function rate_divide(str)
	local t_str = str;
	local args = {};
	while string.find(t_str,"%%s") ~= nil do
		local pos = string.find(t_str,"%%s");
		local next_str = string.sub(t_str,pos + 2,pos + 3);
		if next_str == "%%" then
			table.insert(args, 100);
		else
			table.insert(args, 1);
		end
		t_str = string.gsub(t_str,"%%s","", 1)
	end
	return args
end

local function NewLine(str)
    if string.find( str,"\n") then
        return str
    end

    if #str > 12 then
        local str_1 = string.sub(str, 1, 9)
        local str_2 = string.sub(str, 10, -1)
        local final_str = str_1.."\n"..str_2
        return final_str
    else
        return str
    end
end

local function buff_desc_init(buff)
    if not buff.cfg or buff.cfg == 0 or buff.cfg.desc == "" then
        buff._desc_cfg = (buff.desc ~= 0 and buff.desc) or ""
        if buff.env._desc_cfg_add then
            buff._desc_cfg = buff._desc_cfg .. buff.env._desc_cfg_add(buff)
        end    
        return buff
    end

    local rate_list = rate_divide(buff.cfg.desc)
    local value_list = {}
    for i = 1,3,1 do
        local string_value = buff.cfg["value_"..i] == 0 and buff.target[buff.id] or buff.cfg["value_"..i]
        local rate = rate_list[i] and rate_list[i] or 1
        local value = (rate == 1) and math.floor(string_value/rate) or string_value/rate
        table.insert(value_list, value);
    end
    if string.find(buff.cfg.desc,"%%s") then
        local success, info = pcall(string.format, buff.cfg.desc, value_list[1], value_list[2], value_list[3])
        if not success then
            ERROR_LOG("buff id"..buff.id.."misdescription");
            buff._desc_cfg = buff.cfg.desc
        else
            buff._desc_cfg = string.format(buff.cfg.desc, value_list[1], value_list[2], value_list[3])
        end
    else
        buff._desc_cfg = buff.cfg.desc
    end

    if buff.env._desc_cfg_add then
        buff._desc_cfg = buff._desc_cfg .. buff.env._desc_cfg_add(buff)
    end

    return buff
end

function BattlefieldView:ShowRoleDetail(uuid)
    if self.view.battle.Canvas.RoleInfoPanel == nil then
        if self.view.battle.Canvas.RoleInfoPanel_loading then
            return;
        end
    
        self.view.battle.Canvas.RoleInfoPanel_loading = true
    
        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/RoleInfoPanel", function(o)
            self.view.battle.Canvas.RoleInfoPanel_loading = nil;
            if o then
                self.view.battle.Canvas.RoleInfoPanel = SGK.UIReference.Instantiate(o);
                self.view.battle.Canvas.RoleInfoPanel.transform:SetParent(self.view.battle.Canvas.UIRoot.transform, false);
                self:ShowRoleDetail(uuid);
            end
        end)
        return;
    end

    self.view.battle.Canvas.RoleInfoPanel:SetActive(true);

    local info = self.roles[uuid];
    if not info then
        return
    end

    local role = info.pet or info.role;

    local headManager = self.view.battle.Canvas.RoleInfoPanel[SGK.BattlefiledHeadManager];
    headManager:Clear();

    local dialog = self.view.battle.Canvas.RoleInfoPanel.Dialog;
    dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue(role.side == 1 and "biaoti_juesexinxi_01" or "biaoti_guaiwuxinxi_01")

    if info.pet then
        utils.IconFrameHelper.Create(dialog.HeroInfo.IconFrame, {customCfg={
            icon    = role.icon,
            quality = 0,
            star    = 0,
            level   = role.level,
        }, type = 42});
    else
        local stageCfg = HeroEvoConfig.GetConfig(role.id);
        local cfg = stageCfg and stageCfg[role.grow_stage];
        utils.IconFrameHelper.Create(dialog.HeroInfo.IconFrame, {customCfg = {
            icon    = role.icon,
            quality = cfg and cfg.quality or 1,
            star    = role.grow_star,
            level   = role.level,
        }, type = 42});
    end

    local ShowAsRole = (role.id <= 19999 and role.owner == 0) or (role.npc_type == 3) 

    if ShowAsRole then
        if role.Ai_Title ~= 0 then
            dialog.HeroInfo.RoletitleBG.Roletitle[UnityEngine.UI.Text].text = role.Ai_Title
        else
            local heroCfg = module.HeroModule.GetManager():Get(role.id or 11000)
            local _title = module.titleModule.GetTitleStatus(heroCfg)
            dialog.HeroInfo.RoletitleBG.Roletitle[UnityEngine.UI.Text].text = (_title == "称号" and "暂无称号") or _title
        end
    else
        dialog.HeroInfo.RoletitleBG:SetActive(false)
    end
    dialog.HeroInfo.NameLabel[UnityEngine.UI.Text].text = role.name;

    local mp, mpp = role.mp, role.mpp;
    local cfg = HeroModule.GetConfig(role.id) or battle_config.LoadNPC(role.id);

    local hpRevert = role.hpRevert;
    local mpRevert = role.mpRevert;
    local mpName = "MP";
    local mp, mpp = role.mp, role.mpp;
    local color = 0-- UnityEngine.ColorUtility.TryParseHtmlString('#4eaeff');
    if cfg and cfg.mp_type == 8001 then
        mpName = "EP";
        mpRevert = role.epRevert;
        color = 1
        mp, mpp = role.ep, role.epp;
    elseif cfg and cfg.mp_type == 8002 then
        mpName = "FP";
        mpRevert = 0;
        mp, mpp = role.fp, role.fpp;
        color = 2
    elseif not cfg or cfg.mp_type ~= 8000 then
        mpName = "XP";
        mpRevert = 0;
        mp, mpp = 0, 0
        color = nil;
    end

    dialog.HeroInfo.HP[CS.BattlefieldProgressBar]:SetValue(math.floor(role.hp), math.floor(role.hpp));
    dialog.HeroInfo.element.master[CS.UGUISpriteSelector].index = GetMasterIcon(role)
    dialog.HeroInfo.element.Text[CS.UGUIColorSelector].index = GetMasterIcon(role, true).colorindex
    dialog.HeroInfo.element.Text[UnityEngine.UI.Text].text = GetMasterIcon(role, true).desc
    if mpp > 0 then
        dialog.HeroInfo.MP[CS.BattlefieldProgressBar].color = color;
        dialog.HeroInfo.MP:SetActive(true);
        dialog.HeroInfo.MP[CS.BattlefieldProgressBar].title = mpName;
        dialog.HeroInfo.MP[CS.BattlefieldProgressBar]:SetValue(math.floor(mp), math.floor(mpp));
    else
        dialog.HeroInfo.MP:SetActive(false);
    end

    if ShowAsRole then
        dialog.EnemySkillList:SetActive(false)
        dialog.RoleStarList:SetActive(true)
        dialog.RoleSkillList:SetActive(true)

        local skill_boxs = role.skill_boxs;
        for i = 1, 4 do
            local skill = skill_boxs[i];
            if not skill then
                dialog.RoleSkillList["Skill"..i]:SetActive(false);
            else
                local sprite = SGK.ResourcesManager.Load("icon/" .. skill.icon, typeof(UnityEngine.Sprite));
                dialog.RoleSkillList["Skill"..i][UnityEngine.UI.Image].sprite = sprite;   
                local descs = module.TalentModule.GetSkillDetailDes(skill.id, role);
                local desc_str = "";
                for k, desc in ipairs(descs) do
                    if desc and desc ~= "" then
                        if k ~= 1 then
                            desc_str = desc_str .. "\n· ";
                        end
                        desc_str = desc_str .. string.gsub(string.gsub(desc or "", "【", "<color=red>"), "】", "</color>");
                    end
                end

                CS.UGUIPointerEventListener.Get(dialog.RoleSkillList["Skill"..i].gameObject).onPointerDown = function(obj , pos)
                    local info = {
                        name           = skill.name,
                        cost           = skill[8000] or 0,
                        skilltype      = skill.skill_type,
                        cd             = skill.property.skill_cast_cd,
                        skilltargets   = skill.skill_place_type + 10,
                        desc           = desc_str,
                    }
                    dialog[SGK.LuaBehaviour]:Call("UpdateSkillDetails", pos, info)
                end
            
                CS.UGUIPointerEventListener.Get(dialog.RoleSkillList["Skill"..i].gameObject).onPointerUp = function()
                    dialog[SGK.LuaBehaviour]:Call("PickBackSkillDetails")
                end      
                dialog.RoleSkillList["Skill"..i]:SetActive(true)  
            end
        end

        if not self.skillDocTab then
            local heroStar = require"hero.HeroStar"
            self.skillDocTab, self.roleStarTab = heroStar.GetroleStarTab()
        end
    
        local star_list = self.skillDocTab[role.id]
        local star_cfg = self.roleStarTab[role.id]
    
        for i = 1, 5, 1 do
            if not star_list or not star_cfg then
                break
            end

            local name = star_list[i].name
            if not name then
                break
            end

            local _count = 0
            local _desc = ""
            for i = 1, role.grow_star do
                if star_cfg[i].name == name then
                    _count = _count + 1
                    _desc = star_cfg[i].desc
                end
            end
    
            dialog.RoleStarList["Star"..i].level[UI.Text].text = "^".._count
            local sprite = SGK.ResourcesManager.Load("icon/" .. star_list[i].icon, typeof(UnityEngine.Sprite));
            if sprite then
                dialog.RoleStarList["Star"..i][UnityEngine.UI.Image].sprite = sprite
            else
                ERROR_LOG("===========!!!!!!!!!"..star_list[i].icon.."资源缺失")
            end

            if _count == 0 then
                dialog.RoleStarList["Star"..i][UnityEngine.UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            else
                dialog.RoleStarList["Star"..i][UnityEngine.UI.Image].material = nil
            end
    
            CS.UGUIPointerEventListener.Get(dialog.RoleStarList["Star"..i].gameObject).onPointerDown = function(obj , pos)
                local info = {
                    desc = _desc
                }
                dialog[SGK.LuaBehaviour]:Call("UpdateOtherDetails", pos, info)
            end
        
            CS.UGUIPointerEventListener.Get(dialog.RoleStarList["Star"..i].gameObject).onPointerUp = function()
                dialog[SGK.LuaBehaviour]:Call("PickBackOtherDetails")
            end         
        end
    else
        dialog.EnemySkillList:SetActive(true)
        dialog.RoleStarList:SetActive(false)
        dialog.RoleSkillList:SetActive(false)
        local skill_boxs = role.skill_boxs;
        for i = 1, 4 do
            local skill = skill_boxs[i];
            if not skill then
                dialog.EnemySkillList["Skill"..i]:SetActive(false);
            else
                dialog.EnemySkillList["Skill"..i]:SetActive(true);
                dialog.EnemySkillList["Skill"..i].name[UI.Text].text = skill.name
                dialog.EnemySkillList["Skill"..i].desc[UI.Text].text = skill.desc
            end
        end
    end

    local buffList = self.game.buffManager:Get(role);
    local suit_buff = {}
    local passive_buff = {}
    local other_buff = {}

    for _, buff in ipairs(buffList) do
        if buff.id >= 1200001 and buff.id <= 1299999 then
            table.insert(suit_buff, buff)
        elseif buff.id >= 1100001 and buff.id <= 1999999 then
            table.insert(passive_buff, buff)
        else
            table.insert(other_buff, buff)
        end
    end

    if ShowAsRole then
        dialog.SuitList.Title.Text[UI.Text].text = "套装效果"
        local suit_descs = ""
        if next(suit_buff) then
            table.sort(suit_buff, function (a, b) 
                return a.id < b.id
            end)

            for i = 1,#suit_buff do
                local buff = buff_desc_init(suit_buff[i])
                suit_descs = suit_descs.."<color=#6e4800>"..buff.desc_head.."</color>"..":"..buff._desc_cfg.."\n"
            end
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleLeft
        else
            suit_descs = "还未获得套装效果"
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleCenter
        end
        dialog.SuitList.descview.Text[UI.Text].text = suit_descs
    else
        dialog.SuitList.Title.Text[UI.Text].text = "被动技能"
        local suit_descs = ""
        if next(passive_buff) then
            table.sort(passive_buff, function (a, b) 
                return a.id < b.id
            end)

            for i = 1,#passive_buff do
                local buff = buff_desc_init(passive_buff[i])
                suit_descs = suit_descs.."<color=#6e4800>"..buff.desc_head.."</color>"..":"..buff._desc_cfg.."\n"
            end
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleLeft
        else
            suit_descs = "没有被动技能"
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleCenter
        end
        dialog.SuitList.descview.Text[UI.Text].text = suit_descs
    end

    if next(other_buff) then
        local buffObject = {};
        local prefab = dialog.BuffList.buffview.content.buff

        for _, buff in ipairs(other_buff) do
            if buff.icon and buff.icon ~= "0" and buff.icon ~= "" and buff.icon ~= 0 then
                if buffObject[buff.id] then
                    buffObject[buff.id].count = buffObject[buff.id].count + 1;
                    buffObject[buff.id].obj.count[UnityEngine.UI.Text].text = string.format("x%d", buffObject[buff.id].count)
                else
                    local obj = SGK.UIReference.Instantiate(prefab.gameObject, dialog.BuffList.buffview.content.transform)
                    buffObject[buff.id] = {obj = obj, count = 1}
                    obj.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. buff.icon)
                    if buff.desc_head == 0 or buff.desc_head == "" or buff.desc_head == "0" then
                        ERROR_LOG("===========!!!!!!!!!",buff.id)
                    end
                    obj.nametext[UnityEngine.UI.Text].text = buff.desc_head
                    obj.namebg[CS.UGUISpriteSelector].index = buff.isDebuff

                    if buff.round > 20 or buff.round <= 0 then
                        obj.Roundimage:SetActive(false)
                        obj.round:TextFormat("永久")
                        obj.round[UnityEngine.UI.Text].fontSize = 20
                        obj.round.transform.localPosition = Vector3(1, obj.round.transform.localPosition.y, 0)
                    else
                        obj.round:TextFormat("{0}", buff.round)
                    end                    

                    CS.UGUIPointerEventListener.Get(obj.gameObject).onPointerDown = function(obj , pos)
                        local _buff = buff_desc_init(buff)            
                        local info = {
                            desc = _buff._desc_cfg
                        }
                        dialog[SGK.LuaBehaviour]:Call("UpdateOtherDetails", pos, info)
                    end
                
                    CS.UGUIPointerEventListener.Get(obj.gameObject).onPointerUp = function()
                        dialog[SGK.LuaBehaviour]:Call("PickBackOtherDetails")
                    end         
            
                    obj:SetActive(true)
                    headManager:Record(obj.gameObject)
                end
            end
        end
    end

    dialog:SetActive(true);
end

function BattlefieldView:PlayBattleGuide(id, delay)
    utils.MapHelper.PlayGuide(id, delay or 1)
end

function BattlefieldView:AddConversation(role, message, bg, sound)
    if self.fastforward_mode then return end

    if not self.dialog_view then
        self.dialog_view = SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/battlefield/BattleDialog"));
        self.dialog_view.transform:SetParent(self.view.battle.Canvas.ConversationRoot.transform, false);
    end 

    local info = {
        bg = bg or 0,
        name = role.name,
        icon = role.icon,
        side =  role.side;
        message = message;
        sound = sound;
    }

    self.dialog_view[SGK.LuaBehaviour]:Call("Add", info);
    self:ShowUI(true)
    self:BattlePause()
end

function BattlefieldView:GuideChangeScene(map)
    SceneStack.ClearBattleToggleScene()
    SceneStack.EnterMap(map, {fight = true, fightGuideMode = true})
end

function BattlefieldView:BattlePause()
    self.game:Pause()
end

function BattlefieldView:BattleResume()
    self.game:Resume()
end

function BattlefieldView:MonsterInfoNext(role)
    if self.monsterInfo_view then
        UnityEngine.GameObject.Destroy(self.monsterInfo_view.gameObject);  
        self.monsterInfo_view = nil      
    end
    self:ShowUIDisable(false)    
    self:ShowUI(true)
    self:BattleResume()
    self.monster_info_list[role.uuid] = nil
    for k, v in pairs(self.monster_info_list) do
        self:ShowMonsterInfo(v)
        break
    end
end

function BattlefieldView:ShowMonsterInfo(role)
    if not self.monster_info_cfg then
        self.monster_info_cfg = {}
        DATABASE.ForEach("debut", function(data)
            self.monster_info_cfg[data.id] = data
        end)
    end

    SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.UIReference], "prefabs/battlefield/MonsterInfo", function(o)
        BattlefieldView:ShowMonsterInfo__(role, o)
    end)
end

function BattlefieldView:ShowMonsterInfo__(role, prefab)
    local info = self.monster_info_cfg[role.id]
    if not info then
        print("load config failed !!! ======================= !!!");
        return
    end

    local _flag = module.RewardModule.Check(info.one_time_id)
    if _flag == module.RewardModule.STATUS.ERROR then
        print("onetime config not found !!! ====================== !!!")
        return
    end

    self.monster_info_list = self.monster_info_list or {}
    self.monster_info_list[role.uuid] = role

    if _flag == module.RewardModule.STATUS.DONE then---------------------首次登场
        self:MonsterInfoNext(role)
        return
    end

    if not self.monsterInfo_view then
        self.monsterInfo_view = SGK.UIReference.Instantiate(prefab);
        self.monsterInfo_view.transform:SetParent(self.view.battle.transform, false);
    else
        return;
    end

    self:BattlePause()
    self:ShowUI(false)    
    self:ShowUIDisable(true)

    self.monsterInfo_view.root.view.infobg_1.desc1[UI.Text].text = info.characteristic
    self.monsterInfo_view.root.view.infobg_1.desc2[UI.Text].text = info.restrain
    self.monsterInfo_view.root.view.desc[UI.Text].text = info.describe
    self.monsterInfo_view.root.jues_appear_guai.jues_appear_ani.weixiandu["weixiandu_"..info.grade]:SetActive(true)

    local name_Text = self.monsterInfo_view.root.jues_appear_guai.jues_appear_ani.transform:GetComponentsInChildren(typeof(UnityEngine.TextMesh), true)
    for i = 1, name_Text.Length do
        if name_Text[i-1].gameObject.tag == "big_skill" then
            name_Text[i-1].text = role.name
        end
    end
    
    local objects = self.monsterInfo_view.transform:GetComponentsInChildren(typeof(Spine.Unity.SkeletonAnimation), true)
    for i = 1, objects.Length do
        if objects[i-1].gameObject.tag == "big_skill" then
            self:UpdateSkeletonDataAsset(objects[i-1], role.mode, "root");
        end
    end

    self.monsterInfo_view.root.jues_appear_guai.jues_appear_ani.jues.role.transform.localPosition = Vector3(info.battle_x, info.battle_y, 0);
    self.monsterInfo_view.root.jues_appear_guai.jues_appear_ani.jues.role.transform.localScale = Vector3.one * info.scale;
    
    CS.UGUIClickEventListener.Get(self.monsterInfo_view.root.mask.gameObject, true).onClick = function() 
        self:MonsterInfoNext(role)
    end

    SGK.Action.DelayTime.Create(0.15):OnComplete(function()
        self.monsterInfo_view.root.mask.gameObject:SetActive(true)
        self.monsterInfo_view.root.jues_appear_guai.jues_appear_ani.jues.role[CS.Spine.Unity.SkeletonAnimation].AnimationState:SetAnimation(0 , "ruchang", false)
        self.monsterInfo_view.root.jues_appear_guai.jues_appear_ani.jues.role[CS.Spine.Unity.SkeletonAnimation].AnimationState:AddAnimation(0 , "idle", true, 0)
    end)

    SGK.Action.DelayTime.Create(5):OnComplete(function()
        if self.monster_info_list[role.uuid] then
            self:MonsterInfoNext(role)
        end
    end)

    self.monsterInfo_view.gameObject:SetActive(true);

    module.RewardModule.Gather(info.one_time_id)
end


function BattlefieldView:ShowBattleWarning(type, offset)
    if type == 1 then
        local show_warning = false
        for k, v in pairs(self.roles) do
            if v.role.pos == 11 then
                show_warning = true
            end
        end

        if self.show_warning_wave == self.game.timeline.wave or not show_warning then
            return
        else
            self.show_warning_wave = self.game.timeline.wave
        end
    end

    self.view.battle.Canvas.EnemyBossUISlot[UnityEngine.CanvasGroup].alpha = 0
    local pos = (offset and Vector3(offset[1], offset[2], offset[3])) or Vector3.zero;
    self.targetSelectorManager:AddUIEffect("prefabs/battlefield/battle_warning", pos, function(o)
        if not o then return; end
        local view = SGK.UIReference.Setup(o);
        view[UnityEngine.RectTransform].anchorMin = UnityEngine.Vector2(0, 0.5)
        view[UnityEngine.RectTransform].anchorMax = UnityEngine.Vector2(1, 0.5)
        view[UnityEngine.RectTransform].offsetMin = UnityEngine.Vector2(0, 0)
        view[UnityEngine.RectTransform].offsetMax = UnityEngine.Vector2(0, 0)

        if type == 1 then
            view.fx_boss_enter:SetActive(true)
        else
            view.fx_insist:SetActive(true)
        end
        UnityEngine.GameObject.Destroy(view.gameObject, 3.6)
    end)
    self.game:Pause()
    self:CallAfter(3.6, function ()
        self.game:Resume()
        self:CallAfter(0.3, function ()
            self.view.battle.Canvas.EnemyBossUISlot[UnityEngine.CanvasGroup].alpha = 1
        end)
    end)
end

function BattlefieldView:showErrorInfo(desc)
    self.skillInfoPanel.ErrorInfo:SetActive(true);
    self.skillInfoPanel.ErrorInfo.Text[UnityEngine.UI.Text].text = desc;
end

function BattlefieldView:ShowSkillGuide()
    if not self.skill_guide then
        self.skill_guide = SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/battlefield/element_guide"));
        self.skill_guide.transform:SetParent(self.view.battle.Canvas.transform, false);
        self.skill_guide.transform.localPosition = Vector3.zero
        self.skill_guide:SetActive(true)
    else
        self.skill_guide:SetActive(true)
    end
end

function BattlefieldView:BattleChatClick(enabled)
    self.view.battle.Canvas.UIRootTop[UnityEngine.UI.GraphicRaycaster].enabled = enabled
end

function BattlefieldView:ShowBattleHalo(skill)
    if not skill then
        self.view.battle.Canvas.BattleHalo:SetActive(false)
        return
    end

    if not self.SetupButton_Halo then
        CS.UGUIPointerEventListener.Get(self.view.battle.Canvas.BattleHalo.icon.gameObject).onPointerDown = function()
            self.view.battle.Canvas.BattleHalo.detail[CS.DG.Tweening.DOTweenAnimation]:DORestart(true)
            self.view.battle.Canvas.BattleHalo.detail:SetActive(true)
        end

        CS.UGUIPointerEventListener.Get(self.view.battle.Canvas.BattleHalo.icon.gameObject).onPointerUp = function()
            self.view.battle.Canvas.BattleHalo.detail:SetActive(false)
        end
        self.SetupButton_Halo = true
    end

    self.view.battle.Canvas.BattleHalo:SetActive(true)
    local descs = module.TalentModule.GetSkillDetailDes(skill.id, skill.owner);
    local desc_str = "";
    for k, desc in ipairs(descs) do
        if desc and desc ~= "" then
            if k ~= 1 then
                desc_str = desc_str .. "\n· ";
            end
            desc_str = desc_str .. string.gsub(string.gsub(desc or "", "【", "<color=red>"), "】", "</color>");
        end
    end
    self.view.battle.Canvas.BattleHalo.detail.Text[UnityEngine.UI.Text].text = (desc_str == "" and skill.desc) or desc_str
    local sprite = SGK.ResourcesManager.Load("icon/" .. skill.icon, typeof(UnityEngine.Sprite));
    self.view.battle.Canvas.BattleHalo.icon[UnityEngine.UI.Image].sprite = sprite;
end

function BattlefieldView:Button_Command_switch()
    if not self.Command_detail_abled then
        self.Button_Command.detail:SetActive(true)
        self.Command_detail_abled = true
    else
        self.Button_Command.detail:SetActive(false)
        self.Command_detail_abled = false
    end
end

function BattlefieldView:ShowFocusTargets(type)
    if type == 0 then
        self:SetFocusTag(nil, 0)
    else
        self:ShowFocusSelect(type)
    end
end

function BattlefieldView:SetFocusTag(target, type)
    self:SetFocusTag_View(target, type)
    self:SetFocusTag_Battle(target, type)
end

function BattlefieldView:SetFocusTag_View(target ,type)
    if target == nil then
        for _, v in pairs(self.roles) do
            self:SetFocusTag_View(v.role, type)
        end
        return;
    end

    local info = self.roles[target.uuid];
    if info and info._Focus_Effect then
        self.gameObjectPool:Release(info._Focus_Effect)
        info._Focus_Effect = nil
    end

    if type == 0 then return end

    local effect_list = {
        [1] = "UI/fx_jihuo_kongzhi",
        [2] = "UI/fx_jihuo_tingshou",
        [3] = "UI/fx_jihuo_jihuo",
    }

    self:UnitAddEffect(target, effect_list[type], {hitpoint = "head", duration = -1}, function(o)
        info._Focus_Effect = o;
    end);
end

function BattlefieldView:SetFocusTag_Battle(role ,type)
    if self:NeedSyncData() then
        self:SendServerCommand({
            pid     = self.game.pid,
            type    = "INPUT",
            refid   = role and role.refid or 0,
            sync_id = role and role.sync_id or 0,
            tick    = self.game.timeline.tick,
            skill   = 98000;
            target  = type;
        })
    else
        self.game:SetBattleFocusTag(role, type)
    end
end

function BattlefieldView:ShowFocusSelect(type)
    if self.view.battle.Canvas.RoleInfoPanel_loading then
        return;
    end

    self.view.battle.Canvas.RoleInfoPanel_loading = true

    if self.view.battle.Canvas.RoleInfoPanel == nil then
        SGK.ResourcesManager.LoadAsync(self.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/RoleInfoPanel", function(o)
            self.view.battle.Canvas.RoleInfoPanel = SGK.UIReference.Instantiate(o);
            self.view.battle.Canvas.RoleInfoPanel.transform:SetParent(self.view.battle.Canvas.UIRoot.transform, false);
            self:ShowFocusSelectAfterLoad(type);
        end)
    else
        self:ShowFocusSelectAfterLoad(type);
    end
end

function BattlefieldView:ShowFocusSelectAfterLoad(type)
    self.view.battle.Canvas.RoleInfoPanel_loading = nil;

    local headManager = self.view.battle.Canvas.RoleInfoPanel[SGK.BattlefiledHeadManager];

    headManager:Clear();

    local prefab = self.view.battle.Canvas.RoleInfoPanel.IconFrame.gameObject;
    
    local listener = nil;
    for uuid, v in pairs(self.roles) do
        if not v.hide and v.role.hp > 0 and v.role.side == 2 then
            local icon = nil
            local info = nil;
            if v.pet then
                icon = SGK.UIReference.Setup(headManager:Show(v.script, prefab, 0));
                info = {
                    icon = v.pet.icon,
                    quality = 0,
                    star = 0,
                    level = v.pet.level,
                    pos = 0,
                }
                if v.pet.owner.pos == 11 then
                    icon.transform.position = v.script.gameObject.transform.position;
                end
            else
                local stageCfg = HeroEvoConfig.GetConfig(v.role.id);
                local cfg = stageCfg and stageCfg[v.role.grow_stage];
                icon = SGK.UIReference.Setup(headManager:Show(v.script, prefab, (v.role.side == 1) and v.role.pos or 0));
                info = {
                    icon = v.role.icon,
                    quality = cfg and cfg.quality or 1,
                    star = v.role.grow_star,
                    level = v.role.level,
                    pos = (v.role.side == 1) and v.role.pos or 0,
                }
            end

            utils.IconFrameHelper.Create(icon, {customCfg = info, type = 42});

            local target = v.role;
            CS.UGUIClickEventListener.Get(icon.gameObject).onClick = function()
                self.view.battle.Canvas.RoleInfoPanel:SetActive(false)
                self:SetFocusTag(target ,type)
            end
        end
    end
    self.view.battle.Canvas.RoleInfoPanel:SetActive(true)
end

function BattlefieldView:SetSingBar(target, active, values)
    if not self.targetObject_list[target.uuid].UIEnemy and not self.targetObject_list[target.uuid].UIBoss then
        return
    end

    local target_obj = self.targetObject_list[target.uuid].UIEnemy or self.targetObject_list[target.uuid].UIBoss
    local target_bar = target_obj.Sing_Bar 

    if not active then
        target_bar[SGK.LuaBehaviour]:Call("CleanSingBar")
        self.view.battle.Canvas.singbardetail[SGK.LuaBehaviour]:Call("PickBack")
        return
    end

    if not values.certainly_increase or not values.current or not values.beat_back then
        ERROR_LOG("sing values not found")
        return
    end

    if not self.battle_sing_bar_list then
        self.battle_sing_bar_list = {}
    end

    if not self.battle_sing_bar_list[target.uuid] then
        self.battle_sing_bar_list[target.uuid] = {}
    end

    self.battle_sing_bar_list[target.uuid].current = values.current
    self.battle_sing_bar_list[target.uuid].next = values.certainly_increase + values.beat_back

    if values.total then
        self.battle_sing_bar_list[target.uuid].total = values.total
        self.battle_sing_bar_list[target.uuid].name = values.name
        self.battle_sing_bar_list[target.uuid].type = values.type

        target_bar:SetActive(true)
        target_bar[SGK.LuaBehaviour]:Call("CreateSingBar", values.type, values.total, values.current, values.certainly_increase, values.beat_back)
    else
        target_bar[SGK.LuaBehaviour]:Call("SetSingBar", values.current, values.certainly_increase, values.beat_back)
    end
end

function BattlefieldView:SetTargetRingMenuActive(active, uuid, pos)
    if not self.target_ring_menu and active then
        self.target_ring_menu = SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/battlefield/BattlefieldTargetRingMenu"));
        self.target_ring_menu.transform:SetParent(self.view.battle.PersistenceCanvas.transform, false);
        self.target_ring_menu:SetActive(false);
    end

    if self.target_ring_menu then
        if active then
            if pos then
                self.targetSelectorManager:SetUIPosition(self.target_ring_menu.FillImage.transform, pos);
            end

            self.target_ring_menu.FillImage[CS.UIRingMenuFillImage]:StartFill()
            local role = self.roles[uuid].role;
            self.target_ring_menu.Menu.Menu1:SetActive(role.side ~= 1)
            self.target_ring_menu.Menu.Menu2:SetActive(role.side ~= 1)
            self.target_ring_menu.Menu.Menu3:SetActive(role.side ~= 1)

            self.target_ring_menu.Menu[CS.UIRingMenu].onClick = function(n)
                self:SetTargetRingMenuActive(false);

                if self.roles[uuid] == nil then
                    return;
                end

                local t = { [0] = 1, 2, 3, 0};

                if t[n] == 0 then
                    return self:ShowRoleDetail(uuid);
                end

                self:SetFocusTag(role, t[n]);
            end
        end

        self.target_ring_menu:SetActive(active);
    end
end

function BattlefieldView:onEnemyTouchBegan(uuid, pos)
    if not self.roles[uuid] then return;  end
    self.target_ring_menu_start = CS.UnityEngine.Time.realtimeSinceStartup;
    self:SetTargetRingMenuActive(true, uuid, self.roles[uuid].script:GetPosition("hitpoint")) --  pos);
end

function BattlefieldView:onEnemyTouchEnd(uuid, pos)
    if not self.roles[uuid] then return; end
    local role = self.roles[uuid].role;
    if CS.UnityEngine.Time.realtimeSinceStartup - self.target_ring_menu_start < 0.5 then
        self:SetTargetRingMenuActive(false);
    end

    if self.target_ring_menu then
        -- self.target_ring_menu.FillImage[CS.UIRingMenuFillImage]:TouchEnd()
    end
    -- ERROR_LOG("onEnemyTouchEnd", role.id, role.name)
end

function BattlefieldView:onEnemyTouchMove(uuid, pos)
    -- local role = self.roles[uuid].role;
    -- ERROR_LOG("onEnemyTouchMove", role.id, role.name)
end

function BattlefieldView:onEnemyTouchCancel(uuid)
    if not self.roles[uuid] then return; end
    local role = self.roles[uuid].role;
    -- ERROR_LOG("onEnemyTouchCancel", role.id, role.name)
    if CS.UnityEngine.Time.realtimeSinceStartup - self.target_ring_menu_start < 0.5 then
        self:SetTargetRingMenuActive(false);
    end

    if self.target_ring_menu then
        -- self.target_ring_menu.FillImage[CS.UIRingMenuFillImage]:TouchEnd()
    end
end

function BattlefieldView:UnitChangeMode(role, mode_id)
    local info = self.roles[role.uuid];
    info.script:ChangeMode(tostring(mode_id), role.scale, "idle", false, self.partner_sorting_order[role.mode] or 2);
end

return BattlefieldView;
