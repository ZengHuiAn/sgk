local class = require "utils.class"

local Entity = require "battlefield2.Entity"

local DelaySystem     = require "battlefield2.system.Delay"
local BuffSystem      = require "battlefield2.system.Buff"
local BulletSystem    = require "battlefield2.system.Bullet"
local MagicFieldSystem= require "battlefield2.system.MagicField"
local EventSystem     = require "battlefield2.system.Event"
local RoundSystem     = require "battlefield2.system.Round"
local SkillSystem     = require "battlefield2.system.Skill"
local RoleSystem      = require "battlefield2.system.Role"
local PetSystem       = require "battlefield2.system.Pet"
local InputSystem     = require "battlefield2.system.Input"
local APISystem       = require "battlefield2.system.CommonAPI"
local SyncClient      = require "battlefield2.system.SyncClient"
local ShowNumber      = require "battlefield2.system.ShowNumber"
local AutoKill        = require "battlefield2.system.AutoKill"
local Statistics      = require "battlefield2.system.Statistics"
local RandomBuff      = require "battlefield2.system.RandomBuff"
local SingSkill       = require "battlefield2.system.SingSkill"
local AutoInput       = require "battlefield2.component.AutoInput"
local FightListener   = require "battlefield2.system.FightListener"

local Game = class({})

local Game_API = {}

ERROR_LOG = ERROR_LOG or print

function Game:_init_(name, systems)
    self.name = name;
    self.next_entity_uuid = 0;
    self.entities = {}

    self.systems = {
        APISystem,
        DelaySystem,
        EventSystem,
        SkillSystem,
        RoleSystem,
        BuffSystem,
        PetSystem,
        BulletSystem,
        MagicFieldSystem,
        InputSystem,
        ShowNumber,
        AutoKill,
        Statistics,
        RandomBuff,
        SingSkill,
        FightListener,
    }

    self.tick = 0;
    self.pass = 0;
    self.FRAME_RATE = 10;

    self.API = {}

    self.components = {}
end

function Game:AddSystem(system)
    if type(system) == "string" then
        local s = require("battlefield2.system." .. system);
        table.insert(self.systems, s);
        self:initSystem(s);
        return s;
    else
        table.insert(self.systems, system)
        self:initSystem(system);
        return system;
    end
end

function Game:AddEntity(entity)
    if entity.uuid and entity.uuid > 0 then
        if entity.uuid > self.next_entity_uuid then
            self.next_entity_uuid = entity.uuid;
        end
    else
        self.next_entity_uuid = self.next_entity_uuid + 1;
        entity.uuid = self.next_entity_uuid;
    end

    assert(self.entities[entity.uuid] == nil);

    self.entities[entity.uuid] = entity;

    entity:Start(self);

    for k, _ in pairs(entity.component) do
        self.components[k] = self.components[k] or {}
        self.components[k][entity.uuid] = entity;
    end

    self:DispatchEvent("ENTITY_ADD", entity.uuid, entity);

    return entity;
end

function Game:GetEntity(uuid)
    return self.entities[uuid];
end

function Game:RemoveEntity(uuid, opt)
    local e = self.entities[uuid]
    if not e then return end

    self:DispatchEvent("ENTITY_WILL_REMOVE", uuid, e, opt or {});

    self.entities[uuid] = nil;

    for k, _ in pairs(e.component) do
        assert(self.components[k])
        self.components[k][e.uuid] = nil;
    end

    self:DispatchEvent("ENTITY_REMOVED", uuid, e, opt or {});

    e:OnDestroy(self);
end

local function entity_sort(a, b ) 
    return a.uuid < b.uuid
end

function Game:FindAllEntityWithComponent(...)
    local list = {}
    local fist = select(1, ...)
    local entities = self.entities;
    if fist then
        entities = self.components[fist] or {}
    end

    for _, e in pairs(entities) do
        local skip = false;
        for _, v in ipairs({...}) do
            if not e:GetComponent(v) then
                skip = true;
                break;
            end
        end

        if not skip then
            table.insert(list, e);
        end
    end

    table.sort(list, entity_sort);

    return list;
end

function Game:initSystem(s)
    if s.Init then s.Init(self); end

    for event,func in pairs(s.EVENT or {}) do
        self:WatchEvent(event, function(game, event, ...)
            func(game, ...);
        end)
    end

    for name, api in pairs(s.API or {}) do
        self.API[name] = api;
    end
end

function Game:Init()
    self.API.GetTime = Game.GetTime
    self.API.GetTick = Game.GetTick
    -- self.API.RAND    = Game.RAND

    for _, v in ipairs(self.systems) do
        self:initSystem(v);
    end

    return self;
end

function Game:Start()
    for _, v in ipairs(self.systems) do
        if v.Start then v.Start(self); end
    end
end

function Game:Tick()
    for _, v in ipairs(self.systems) do
        if v.Tick then v.Tick(self); end
    end

    self.tick = self.tick + 1;
end

function Game:Update(dt)
    self.pass = self.pass + dt * self.FRAME_RATE;
    while self.pass >= 1 do
        self.pass = self.pass - 1
        self:Tick();
    end
end

function Game:Stop()
    for _, v in ipairs(self.systems) do
        if v.Stop then v.Stop(self); end
    end
end

function Game:DelayCall(tick, func, ctx)
    DelaySystem.Call(self, self.tick + tick, func, ctx);
end

function Game:CallAt(tick ,func, ctx)
    DelaySystem.Call(self, tick, func, ctx);
end

function Game:DispatchEvent(event, ...)
    EventSystem.Dispatch(self, event, ...)
end

function Game:WatchEvent(event, func)
    EventSystem.Watch(self, event, func);
end

function Game:TimeToTick(time)
    assert(type(time) == "number", debug.traceback());
    return math.floor(time * self.FRAME_RATE);
end

function Game:GetTime(after)
    return (self.tick + (after or 0)) / self.FRAME_RATE;
end

function Game:GetTick(after)
    return self.tick + (after and math.floor(after * self.FRAME_RATE) or 0)
end

function Game:LOG()
end

function Game:ERROR(...)
    ERROR_LOG(string.format('[%s%6.1f]', self.name or 'game', self.tick / self.FRAME_RATE), ...);
end

if false then
    function Game:LOG(...)
        print(string.format('[%s%6.1f]', self.name or 'game', self.tick / self.FRAME_RATE), ...);
    end
end

function Game:RAND(...)
    assert(false);
    return math.random(...)
end

function Game:CallAPI(api, ...)
    local func = self.API[api] or Game_API[api] or function()
        print('UNKNOWN API', api, debug.traceback());
    end

    return func(...)
end

function Game:Sleep(n)
    return DelaySystem.API.Sleep({game = self}, n);
end

local function CreateGame(...)
    return Game(...):Init(); 
end

function Game:GetSingleton(typeName)
    local list = self:FindAllEntityWithComponent(typeName)
    if list and #list > 0 then
        return list[1]:GetComponent(typeName);
    else
        local comp = require("battlefield2.component." .. typeName);
        local entity = Entity();
        local data = entity:AddComponent(typeName, comp());
        self:AddEntity(entity);
        return data;
    end
end

function Game:GetGlobalData()
    if self.round_info == nil then
        local list = self:FindAllEntityWithComponent("GlobalData");
        self.round_info = list[1] and list[1].GlobalData;
    end
    return self.round_info;
end

function Game:GetWinner()
    return self:GetGlobalData().final_winner;
end

function Game:Encode()
    local info = {self.tick, {}}

    local role_list = {}
    local other_list = {}
    
    for _, e in pairs(self.entities) do
        if e.Health and e.Input and e.Round then
            table.insert(role_list, e)
        else
            table.insert(other_list, e)  
        end
        --table.insert(info[2], e:Serialize())
    end

    for _, e in ipairs(role_list) do
        table.insert(info[2], e:Serialize())
    end

    for _, e in ipairs(other_list) do
        table.insert(info[2], e:Serialize())
    end

    return info;
end

function Game:Decode(data)
    self.tick = data[1]

    self.entities = {}

    for _, info in ipairs(data[2] or {}) do
        self:AddEntity(SyncClient.Decode(info));
    end
end

function Game:Input(uuid, ...)
    local entity = self:GetEntity(uuid)
    if entity and entity.Input then
        InputSystem.Push(entity.Input, ...)
    end
end

function Game:SetAutoInput(auto, pid)
    self.auto_input_entity = self.auto_input_entity or self:FindAllEntityWithComponent("AutoInput")[1];
    if not self.auto_input_entity then
        local entity = Entity();
        entity:AddComponent("AutoInput", AutoInput())
        self.auto_input_entity = self:AddEntity(entity);
    end

    self.auto_input_entity:SetAutoInput(auto, pid);

    if not auto then
        return
    end

    local list = self:FindAllEntityWithComponent("Input", "Force")
    for _, v in ipairs(list) do
        if v.Input.token and (pid == nil or (v.Force.pid == pid)) then
            InputSystem.Push(v.Input, "AUTO", "SKILL");
        end
    end
end

function Game:GetAutoInput(pid)
    self.auto_input_entity = self.auto_input_entity or self:FindAllEntityWithComponent("AutoInput")[1];
    if not self.auto_input_entity then
        return false;
    end

    return self.auto_input_entity:GetAutoInput(pid);
end

return CreateGame
