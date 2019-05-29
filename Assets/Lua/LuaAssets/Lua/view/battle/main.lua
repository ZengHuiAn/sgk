require "utils.init"

local Game = require "battlefield2.Game"
local EventManager = require "utils.EventManager"
local fightModule = require "module.fightModule"

local BattlefieldView = {}

SceneService:StartLoading();
local _WaitForEndOfFrame = WaitForEndOfFrame;

local addon_list = {
    -- "APIStub",
    -- "Decoder",
    "Sync",
    "Scene",
    "UI",
    "SkillPanel",
    "Role",
    "Bullet",
    "Buff",
    "Effect",
    "ResultPanel",
    "Pet",
    "ShowNumber",
    "BattleDialog",
    "RandomBuff",
    "ErrorInfo",
    "BattleGuide",
    "PartnerPannel",
    "Round",
    "MonsterInfo",
    "EventNeedPause",
    "RoleInfoPannel",
    "TeamPartnerPanel",
    "SingBar",
    "SpecialEffects",
    "SkillSound",
    "PartnerLoadPannel",
}

-- _WaitForEndOfFrame = function() end

function BattlefieldView:Start()
    self.wait_for_loading = true;
    self.addons = {}
    self.view = {battle = SGK.UIReference.Setup("battle_root")};

    DispatchEvent('BATTLE_VIEW_READY');
end

function BattlefieldView:WaitForEndOfFrame()
    assert(self.wait_for_loading, "WaitForEndOfFrame only avilable in preload")
    _WaitForEndOfFrame();
end

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
            local success, info = pcall(addon[name], ...)
            if not success then
                ERROR_LOG("ERROR in addon ", v, name, info)
            end
        end
    end
end

function BattlefieldView:OnDestroy()
    self:ForEachAddonCall("OnDestroy")
end

function BattlefieldView:listEvent()
    return {
        "BATTLE_VIEW_START_WITH_FIGHT",
        "FIGHT_CHECK_RESULT",
        "FIGHT_DATA_SYNC",
        "HeroExpInfoChange",
        "LOCAL_GUIDE_CHANE",
        "LOCAL_GUIDE_PASS",
        "GUIDE_SHOW_MASK",
        "ADD_BASE_COUNTDOWN",
        "FIGHT_FIALED",

        "TEAM_QUERY_NPC_REWARD_REQUEST",
        "Roll_Query_Respond",
        "ADD_OBJECT_TO_FIGHT_RESULT",
        "server_notify_60",
        "server_notify_16009",
    }
end

function BattlefieldView:onEvent(event, ...)
    if event == "BATTLE_VIEW_START_WITH_FIGHT" then
        self:StartGame(...);
    elseif self.eventManager then
        self.eventManager:dispatch(event, ...)
    else
        ERROR_LOG('self.eventManager = nil', event, ...);
    end
end

function BattlefieldView:StartGame(battle_info)
    self.args = battle_info;

    local this = self;
    if _WaitForEndOfFrame == WaitForEndOfFrame then
        self.preload_co = StartCoroutine(function()
            this:preload();
        end)
    else
        this:preload();
    end
end

function BattlefieldView:preload()
    -- create game logic
    if type(self.args.fight_data) == "table" then
        self.fight_data = self.args.fight_data;
    else
        self.fight_data = ProtobufDecode(self.args.fight_data, "com.agame.protocol.FightData")
    end

    self.message_queue = {}

    self.pid = self.args.pid or module.playerModule.GetSelfID();

    self.game = Game('client');
    
    self.eventManager = EventManager.New(true);

    -- load addons
    for _, v in ipairs(addon_list) do
        self:LoadAddon(v);
    end

    self:ForEachAddon(function(addon)
        for name, func in pairs(addon.EVENT) do
            self.eventManager:addListener(name, func);
        end
    end)

    self.game:WatchEvent('*', function(_, event, ...)
        self.eventManager:dispatch("RAW_BATTLE_EVENT", event, ...)
    end)

    self.game:WatchEvent('WAVE_ALL_ENTER', function()
        if self.speedUp and self.speedUp == 1 and self._speedUp then
            self.speedUp_revert_time = 1;
        end
    end)

    self.game:Start();

    self:ForEachAddonCall("Preload")
    self.eventManager:Tick();

    local apistub_list = {}

    self:ForEachAddon(function(addon)
        for name, func in pairs(addon.API or {}) do
            if self.game.API[name] and not apistub_list[name] then
                ERROR_LOG('duplicate api', name);
            end
            apistub_list[name] = (addon.name == "APIStub");
            self.game.API[name] = func
        end
    end)

    self.wait_for_loading = nil;

    self:ForEachAddonCall("Start")

    self.eventManager:Tick();

    SceneService:FinishLoading();

    self.game:DispatchEvent("AFTER_PRELOAD");
    EventManager.getInstance():dispatch("BATTLE_SCENE_READY");
end

function BattlefieldView:LoadAddon(name)
    self.addonFunctions = self.addonFunctions or {}

    local skip = {
        Start=true, Preload=true, OnDestroy = true, Update = true,
    }

    local env = setmetatable({
        root = self,
        game = self.game,
        name = name,
        WaitForEndOfFrame = function() self:WaitForEndOfFrame()        end,
        print = function(...) print(string.format("[%s] ", name), ...) end,
        Load = function(...) return SGK.ResourcesManager.Load(...)     end,
        LoadAsync = function(...) SGK.ResourcesManager.LoadAsync(...)  end,
        ADDON = setmetatable({}, {__index=function(t, k) return self.addons[k]; end}),
        DispatchEvent = function(...) self.eventManager:dispatch(...) end;
        DispatchGlobalEvent = function(...) DispatchEvent(...) end;
        LoadingProgress = function(percent, name)  DispatchEvent("LOADING_PROGRESS_UPDATE", percent, name) end,
        API = {},
        EVENT = {},
    }, {__index=function(t, k)
        if self.addonFunctions[k] then
            return self.addonFunctions[k];
        end

        if self.game.API[k] then
            return function(...) 
                return self.game.API[k]({game=self.game}, ...)
            end
        end

        return _G[k];
    end, __newindex=function(t, k, v)
        if not skip[k] and type(v) == "function" then
            self.addonFunctions[k] = v;
        end
        rawset(t, k, v);
    end});

    local func, message = loadfile("view/battle/addons/" .. name .. ".lua", "bt", env)
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

function BattlefieldView:Pause()
    -- ERROR_LOG('BattlefieldView:Pause', debug.traceback())
    if self.args.remote_server then
        ERROR_LOG("can not pause in this fight")
        return
    end

    self.pause = true
end

function BattlefieldView:Resume()
    -- ERROR_LOG('BattlefieldView:Resume', debug.traceback())
    self.pause = false
end

function BattlefieldView:GetPlayerSettings()
    return fightModule.player_settings
end

function BattlefieldView:SpeedUp(times)
    local game = self.server or self.game;
    self.view.battle.Canvas.TopRight:SetActive(false);
    self.view.battle.Canvas.timelinePanel:SetActive(false);
    self.game:DispatchEvent("BATTLE_SPEED_UP");
    if self.skill_pannel_show then
        self.game:DelayCall(4, function ()
            local targetSelectorManager = self.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];
            targetSelectorManager:Hide();
            game:SetAutoInput(0.1, self.pid);
            self.speedUp = times;
            self._speedUp = times;        
        end)
    else
        game:SetAutoInput(0.1, self.pid);
        self.speedUp = times;
        self._speedUp = times;
    end
end

function BattlefieldView:Update()
    if self.wait_for_loading then
        if self.eventManager then
            self.eventManager:Tick();
        end
        return;
    end

    local times = self.speedUp or 1
    local dt = UnityEngine.Time.deltaTime;

    if self.speedUp_revert_time then
        self.speedUp_revert_time = self.speedUp_revert_time - dt;
        if self.speedUp_revert_time <= 0 then
            self.speedUp = self._speedUp
            self.speedUp_revert_time = nil;
        end
    end

    -- self:ForEachAddonCall("Force_Update", dt)

    if self.pause then
        self:ForEachAddonCall("Update", dt)
        return
    end

    local last_wave = self.game.round_info and self.game.round_info.wave or 0
    for i = 1,times,1 do 
        if self.speedUp and last_wave ~= self.game.round_info.wave then 
            self.speedUp = 1
            break
        end

        if self.server and self.game ~= self.server then
            self.server:Update(dt);
        end
    
        self.game:Update(dt);
    end

    self.eventManager:Tick();

    self:ForEachAddonCall("Update", dt)
end

return BattlefieldView;
