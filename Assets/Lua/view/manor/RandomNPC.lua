
local MapConfig = require "config.MapConfig"
local npcConfig = require "config.npcConfig"

local View = {}

function View:Start()
    local mapInfo = SceneStack.MapId("all");
    self.owner_pid = mapInfo.mapRoom or module.playerModule.GetSelfID();
    self.controller = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapWayMoveController));
    self.waiting_npc = {};
    self.npcs = {}
    self.enter_delay = math.random(10,50) / 10;
    print("查询", self.owner_pid);
    self.manager = module.ManorRandomQuestNPCModule.GetManager(self.owner_pid);
    
    self.manager:QueryNPC(true, true)
    
    -- self:Refresh();
    
    local now = os.time();
    self.watch_timeout = now + math.random(30, 45);
    self.query_timeout = now + 60;
end

function View:Update()
    local dt = UnityEngine.Time.deltaTime;

    local now = os.time();
    if self.watch_timeout and now >= self.watch_timeout then
        if now >= self.query_timeout then
            self.manager:QueryNPC(true, true)
        else
            self.manager:WatchNPC(true)
        end

        self.watch_timeout = now + math.random(30, 45);
        self.query_timeout = now + 60;
    end

    self.enter_delay  = self.enter_delay - dt;
    if self.enter_delay <= 0 then
        self.enter_delay = math.random(3,10) / 10;

        local npc_id = next(self.waiting_npc)
        if npc_id then
            self.waiting_npc[npc_id] = nil;
            self:CreateNPC(npc_id);
        end
    end

    self:CleanNPC(dt);
end

local function npcAlive(npc, now)
    return npc and ((npc.dead_time == 0) or (now < npc.dead_time));
end

function View:CleanNPC(dt)
    local now = module.Time.now();

    self.clean_time = self.clean_time or now
    if now == self.clean_time then return end;
    self.clean_time = now;

    local list = self.manager:QueryNPC();
    for npc_id, v in pairs(self.npcs) do
        if not npcAlive(list[npc_id], now) then
            print('NPC DEAD', npc_id)
            module.NPCModule.deleteNPC(npc_id)
            self.npcs[npc_id] = nil;
            self.waiting_npc[npc_id] = nil;
        end
    end
end

local function rd(time)
    if time == 0 then return '-' end;

    local d = os.date('*t', time);
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month, d.day, d.hour, d.min, d.sec);
end

local function npcQuestFinish(npc)
    if npc.quest ~= 0 then
        local quest = module.QuestModule.Get(npc.quest)
        if quest and quest.status ~= 0 then
            print("任务完成或放弃，隐藏NPC", npc.id)
            return true
            -- local alreadyInteract = false;
            -- for i,v in ipairs(npc.interact) do
            --     if v == module.playerModule.GetSelfID() then
            --         alreadyInteract = true;
            --     end
            -- end
            -- if alreadyInteract then
                
            -- end
        end
    end
    return false
end

function View:CreateNPC(npc_id)
    local list = self.manager:QueryNPC();
    if not list[npc_id] then return end;

    local npc = list[npc_id];
    local cfg = MapConfig.GetMapMonsterConf(npc_id)
    if not cfg then
        ERROR_LOG('id', npc_id, 'in config_all_npc, not exists')
        return
    end;

    if not npcAlive(npc, module.Time.now()) then
        print('NPC DEAD', npc_id)
        return
    end

    if npcQuestFinish(npc) then
        print('NPC QUEST FINISHED', npc_id)
        return
    end
    
    print('CreateNPC', npc.mode, cfg.name, rd(npc.dead_time), npc.quest, sprinttb(npc.interact));

    LoadNpc(cfg);
    self.npcs[npc_id] = {npc_id = npc_id}
end

function View:Refresh(pid)
    if pid and self.owner_pid ~= pid then return end;
    print('REFRESH', pid, self.owner_pid)
    local mapInfo = SceneStack.MapId("all");

    local new_npc_list = {}
    local list = self.manager:QueryNPC() or {};

    local now = module.Time.now();

    for npc_id, v in pairs(self.npcs) do
        if not npcAlive(list[npc_id], now) then
            print('NPC REMOVED', npc_id)
            module.NPCModule.deleteNPC(npc_id)
            self.npcs[npc_id] = nil;
        end
    end

    for npc_id, _ in pairs(self.waiting_npc) do
        if not npcAlive(list[npc_id], now) then
            self.waiting_npc[npc_id] = nil;
        end
    end

    for _, v in pairs(list) do
        if npcAlive(v, now) then
            if (not self.npcs[v.mode]) then
                self:CreateNPC(v.mode);
            end

            local opt = self.manager:GetNPCOperation(v.mode);
            if opt then
                if v.fight ~= 0 then
                    module.NPCModule.SetIcon(v.mode, "bn_tstzz");
                elseif v.quest ~= 0 then
                    module.NPCModule.SetIcon(v.mode, "bn_ts3");
                elseif v.drop ~= 0 and v.group ~= 2 then
                    module.NPCModule.SetIcon(v.mode, "79013");
                end
            else
                if v.quest ~= 0 and v.fight ~= 0 then
                    local quest = module.QuestModule.Get(v.quest);
                    if quest and quest.status ~= 1  then
                        module.NPCModule.SetIcon(v.mode, "bn_tstzz");
                    else
                        module.NPCModule.SetIcon(v.mode, nil);
                    end
                else
                    module.NPCModule.SetIcon(v.mode, nil);
                end
            end
            
        end
    end
end

function View:listEvent()
    return {
        "MANOR_RANDOM_NPC_CHANGE",
        "QUEST_INFO_CHANGE",
        "npc_init_succeed",
        "NPC_OBJ_INFO_CHANGE",
    }
end

function View:onEvent(event, ...)
    if event == "MANOR_RANDOM_NPC_CHANGE" then
        self:Refresh(...)
    elseif event == "NPC_OBJ_INFO_CHANGE" then
        local gid, obj = ...;
        if self.npcs[gid] then
            self.npcs[gid].obj = obj;
        end
    elseif event == "QUEST_INFO_CHANGE" then
        local quest = ...;
        local list = self.manager:QueryNPC() or {};
        local now = module.Time.now();
        for npc_id, v in pairs(self.npcs) do
            if list[npc_id] and npcAlive(list[npc_id], now) then
                if npcQuestFinish(list[npc_id]) then
                    print('NPC REMOVED', npc_id)
                    module.NPCModule.deleteNPC(npc_id)
                    self.npcs[npc_id] = nil;
                elseif quest and list[npc_id].quest == quest.id and list[npc_id].fight ~= 0 then
                    if list[npc_id].group == 3 then
                        module.fightModule.StartFight(list[npc_id].fight, false)
                    else
                        local teamInfo = module.TeamModule.GetTeamInfo();
                        if teamInfo.group == 0 then
                            module.fightModule.StartFight(list[npc_id].fight, false)
                        else
                            utils.SGKTools.StartTeamFight(list[npc_id].fight) 
                        end
                    end
                end
            end
        end
    elseif event == "npc_init_succeed" then
        local npc_id = ...;
        local list = self.manager:QueryNPC() or {};
        if self.npcs[npc_id] and list[npc_id] and list[npc_id].group == 2 then
            local time = list[npc_id].dead_time - module.Time.now();
            if time > 0 then
                print("倒计时", npc_id, time)
                DispatchEvent("UpdateNpcCountDown", {gid = npc_id, time = time})
            end
        end
    end
end

--[[
function View:Interact(gid, ...)
    local list = self.manager:QueryNPC() or {};
    local npc = list[gid];
    if not npc then
        ERROR_LOG('npc disappeared')
        return;
    end

    local menuName = nil;

    local operation = nil;

    if npc.quest ~= 0 then
        local quest = module.QuestModule.Get(npc.quest)
        if not quest or quest.status == 2 then
            menuName = "接任务" .. npc.flag;
        elseif quest.status == 0 then
            menuName = "交任务" .. npc.flag;
        elseif quest.status == 1 then
            ERROR_LOG('quest is finished')
            menuName = "测试 " .. npc.flag;  -- TODO: test
        end
    elseif npc.fight ~= 0 then
        menuName = "开战" .. npc.flag;
    elseif npc.drop ~= 0 then
        menuName = "领奖" .. npc.flag;
    end

    for _, v in ipairs(npc.interact) do
        if v.pid == module.playerModule.GetSelfID() then
            -- 已经交互过
            menuName = "测试 " .. npc.flag;  -- TODO: test
            -- LoadStory(999999,function () end,true) return;
        end
    end

    ERROR_LOG('-----', npc.quest, npc.fight, npc.drop, menuName);
    LoadStory(999999,function ()            
    end,true)

    -- AssociatedLuaScript("guide/NpcTalk.lua", ...)
    if menuName then
        local menus = {}
        table.insert(menus, {name=menuName, auto = false, action = function()
            self:DoServerInteract(gid)
            DispatchEvent("KEYDOWN_ESCAPE")
        end})
        SetStoryOptions(menus)
    end
end

function View:DoServerInteract(gid)
    local list = self.manager:QueryNPC() or {};
    local npc = list[gid];
    if not npc then
        ERROR_LOG('npc disappeared')
        return;
    end

    local operation = nil;
    if npc.quest ~= 0 then
        local quest = module.QuestModule.Get(npc.quest)
        print('quest', quest and quest.status or '-');
        if not quest or quest.status == 2 then
            operation = 0;
            local aa, err = module.QuestModule.CanAccept(npc.quest, true)
            if not aa then
                ERROR_LOG("quest can't accept", err);
                return;
            end
        elseif quest.status == 0 then
            operation = 1;
        elseif quest.status == 1 then
            ERROR_LOG('quest is finished')
            operation = 1; -- TODO: test
            -- return;
        end
    end

    if self.manager:InteractNPC(gid, operation) then
        self.watch_timeout = math.random(30, 45);
    end
end
--]]

return View;
