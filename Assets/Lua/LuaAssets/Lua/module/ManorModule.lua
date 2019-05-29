local playerModule = require "module.playerModule"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local HeroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local UserDefault = require "utils.UserDefault"
local openLevel = require "config.openLevel"

local manor_des = {};
manor_des[301] = {type = 301,des = "铜类别"};
manor_des[302] = {type = 302,des = "铁类别"};
manor_des[303] = {type = 303,des = "银类别"};
manor_des[304] = {type = 304,des = "金类别"};
manor_des[101] = {type = 101,des = "铜制品"};
manor_des[102] = {type = 102,des = "铁制品"};
manor_des[103] = {type = 103,des = "银制品"};
manor_des[104] = {type = 104,des = "金制品"};
manor_des[201] = {type = 201,des = "煤矿产"};
manor_des[202] = {type = 202,des = "铜矿产"};
manor_des[203] = {type = 203,des = "铁矿产"};
manor_des[204] = {type = 204,des = "银矿产"};
manor_des[401] = {type = 204,des = "普通"};
manor_des[402] = {type = 204,des = "勇者"};
manor_des[403] = {type = 204,des = "英雄"};
manor_des[404] = {type = 204,des = "史诗"};
manor_des[405] = {type = 204,des = "传说"};

local work_name = {};
work_name[1] = {"研究员", "分析师"};
work_name[2] = {"捶打者", "烧炉者", "淬火者", "抛光者"};
work_name[3] = {"挖掘者", "照明者", "运输者"};
work_name[4] = {"店长", "收银员", "推销员", "理货员"};

local dialog_list = {};
dialog_list[0] = {1,2,3,4,5};
dialog_list[1] = {1};--酒馆
--dialog_list[2] = {2};--商铺
-- dialog_list[2] = {2};--研究院
-- dialog_list[3] = {3};--工坊
dialog_list[4] = {2, 3, 4, 5};--矿洞

local manor_line_type_pos = nil;
local manor_line_type_line = nil;
local function LoadManorInfo(pos,type)
    type = type or 1;
	if manor_line_type_pos == nil then
        manor_line_type_pos = LoadDatabaseWithKey("manor_line_type", "location");
    end

    if manor_line_type_line == nil then
        manor_line_type_line = LoadDatabaseWithKey("manor_line_type", "line");
    end
    if type == 1 then
        if pos == nil then
            return manor_line_type_pos;
        end        
        return manor_line_type_pos[pos];
    else
        if pos == nil then
            return manor_line_type_line;
        end        
        return manor_line_type_line[pos];
    end

end

local manor_property_config = nil;
local function GetManorProperty(id)
    if manor_property_config == nil then
        manor_property_config = {};
        
        DATABASE.ForEach("manor_property", function(row)
            if manor_property_config[row.id] == nil then
                manor_property_config[row.id] = {};
            end
            if manor_property_config[row.id][row.type] == nil then
                manor_property_config[row.id][row.type] = {};
            end 
            manor_property_config[row.id][row.type] = row;       
        end)
    end
    --print("~~~~~~~~~~~~GetManorProperty",sprinttb(manor_property_config));
    if id == nil then
        return manor_property_config;
    end
    return manor_property_config[id];
end

local work_effect = nil;
local function GetManorWorkEffect(id)
    if work_effect == nil then
        work_effect = LoadDatabaseWithKey("incr_effect", "work_type");
    end
    if id == nil then
        return work_effect;
    end
   return work_effect[id]
end

local work_type = nil;
local function GetManorWorkType(id)
    if work_type == nil then
        work_type = LoadDatabaseWithKey("work_type", "id");
    end
    if id == nil then
        return work_type;
    end
   return work_type[id]
end

local manor_fight_config = nil;
local function GetManorFightConfig(id)
    if manor_fight_config == nil then
        manor_fight_config = LoadDatabaseWithKey("manor_fight_config", "gid");
    end
    if id == nil then
        return manor_fight_config;
    end
   return manor_fight_config[id]
end

local manor_grade = nil;
local function GetManorGradeConfig(id)
    if manor_grade == nil then
        manor_grade = LoadDatabaseWithKey("manor_grade", "gid");
    end
    if id == nil then
        return manor_grade;
    end
   return manor_grade[id]
end

local manor_task_equation = nil;
local function GetManorTaskEquationConfig(type)
    if manor_task_equation == nil then
        manor_task_equation = {}
        DATABASE.ForEach("manor_task_equation", function(row)
            if manor_task_equation[row.task_type] == nil then
                manor_task_equation[row.task_type] = {};
            end
            for i=1,4 do
                if row["property_type"..i] ~= 0 then
                    table.insert(manor_task_equation[row.task_type], {id = row["property_type"..i], ratio = row["property_ratio"..i]})
                end
            end
        end)
    end
    if type == nil then
        return manor_task_equation;
    end
   return manor_task_equation[type]
end

local work_energy = nil;
local energy_cfg = {};
local function GetManorWorkEnergy(id)
    if work_energy == nil then
        work_energy = LoadDatabaseWithKey("manor_energy", "gid");
        for k,v in pairs(work_energy) do
            energy_cfg[v.id] = v;
        end
    end
    if id ~= nil then
       return energy_cfg[id]
    end
   return work_energy;
end


local manor_fight_add = nil;
local manor_fight_add_by_fight = nil;
local function GetManorFightAdd(get_type, id, grade)
    if manor_fight_add == nil then
        manor_fight_add_by_fight = {}
        manor_fight_add = {};
        
        DATABASE.ForEach("manor_fight_add", function(row)
            if manor_fight_add[row.property] == nil then
                manor_fight_add[row.property] = {};
            end
            manor_fight_add[row.property][row.condition] = row;
            manor_fight_add_by_fight[row.fight_id] = row;
        end)
    end

    if get_type == 1 then
        if grade ~= nil then
            return manor_fight_add[id][grade];
        end
        return manor_fight_add[id];
    else
        return manor_fight_add_by_fight[id];
    end
end

local manor_line_config = nil;
local function GetManorLineConfig(line)
    if manor_line_config == nil then
        manor_line_config = {};
        
        DATABASE.ForEach("manor_line_cfg", function(row)
            local prop_list = {};
            for i=1,5 do
                if row["property_id"..i] ~= 0 then
                   local prop = {};
                   prop.type = row["property_id"..i];
                   prop.ratio = row["property_percent"..i];
                   table.insert(prop_list, prop);
                end
            end

            if manor_line_config[row.line] == nil then
                manor_line_config[row.line] = {};
            end

            manor_line_config[row.line].cfg = row;
            manor_line_config[row.line].prop_effect = prop_list;
        end)
    end

    if line ~= nil then
        return manor_line_config[line];
    end
    return manor_line_config;
end

local function GetManorDes(id)
    return manor_des[id];
end

local function GetWorkName(line)
    if line == 1 then
       return work_name[1];
    elseif line <= 10 then
       return work_name[2];
    elseif line <= 20 then
       return work_name[3];
    else
        return work_name[4];
    end
end

local function GetDialogList(index)
    local interval = 0;
    if index == 0 then
        interval = 0;
    elseif index == 1 then
        interval = 1;
    elseif index >= 2 and index <= 5 then
        interval = 4;
    end
    return dialog_list[interval];
end

local function GeyPosByInterval(interval)
    return dialog_list[interval];
end

local pub_event = nil;
local function GetManorPubEvent(gid)
    if pub_event == nil then
        pub_event = LoadDatabaseWithKey("pub_event_pool", "gid");
    end
    if gid == nil then
        return pub_event;
    end
   return pub_event[gid]
end

local mine_event = nil;
local function GetManorMineEvent(gid,type)
    type = type or 1;
    if mine_event == nil then
        mine_event = {};
        mine_event.type = {};
        mine_event.cfg = {}
        DATABASE.ForEach("mine_event", function(row)
            mine_event.cfg[row.gid] = row;
            if row.event_type == 2 then
                mine_event.type[row.line] = {};
            end
        end)
    end

    if type == 1 then
       if gid == nil then
            return mine_event.cfg;
        end
       return mine_event.cfg[gid]
    else
        return mine_event.type;
    end
    
end

local shop_event = nil;
local function GetManorShopEvent(gid,type)
    type = type or 1;
    if shop_event == nil then
        shop_event = {};
        shop_event.type = {};
        shop_event.cfg = {}
        DATABASE.ForEach("shop_event", function(row)
            if row.event_type == 2 then
                shop_event.type[row.line] = {};
            end
            shop_event.cfg[row.gid] = row;
        end)
    end
    if type == 1 then
        if gid == nil then
            return shop_event.cfg;
        end
        return shop_event.cfg[gid]
    else
        return shop_event.type;
    end
end

local chat_config = nil;
local function GetManorChat(id, line, work_type)
    if chat_config == nil then
        chat_config = {};
        DATABASE.ForEach("chatting", function(row)
            if chat_config[row.role_id] == nil then
                chat_config[row.role_id] = {};
            end
            if chat_config[row.role_id][row.line] == nil then
                chat_config[row.role_id][row.line] = {};
            end
            local chat_cfg = setmetatable({}, {__index = row});
            chat_cfg.working_words = {};
            chat_cfg.blank_words = {};
            chat_cfg.working_click_words = {};
            chat_cfg.blank_click_words = {};
            chat_cfg.en_empty_click_words = {};
            for i=1,2 do
                if row["working_words"..i] then
                    table.insert( chat_cfg.working_words, row["working_words"..i] )
                end
                if row["blank_words"..i] then
                    table.insert( chat_cfg.blank_words, row["blank_words"..i] )
                end
                if row["working_click_words"..i] then
                    table.insert( chat_cfg.working_click_words, row["working_click_words"..i] )
                end
            end
            for i=1,4 do
                if row["blank_click_words"..i] then
                    table.insert( chat_cfg.blank_click_words, row["blank_click_words"..i] )
                end
                if row["en_empty_click_words"..i] then
                    table.insert( chat_cfg.en_empty_click_words, row["en_empty_click_words"..i] )
                end
            end
            chat_config[row.role_id][row.line][row.work_type] = chat_cfg;
        end)
    end
    if id == nil then
        return chat_config;
    end
    if chat_config[id] and chat_config[id][line] then
        return chat_config[id][line][work_type];
    else
        return nil;
    end
end

local chat_config2 = nil;
local function GetManorChat2(id)
    if chat_config2 == nil then
        chat_config2 = {};
        DATABASE.ForEach("chatting_two", function(row)
            if chat_config2[row.role_id] == nil then
                chat_config2[row.role_id] = {};
            end
            local chat_cfg = setmetatable({}, {__index = row});
            chat_cfg.eating_before = {};
            chat_cfg.eating_ing = {};
            chat_cfg.eating_finish = {};
            chat_cfg.gambling_victory = {};
            chat_cfg.gambling_ing = {};
            chat_cfg.gambling_defeat = {};
            chat_cfg.hanging_out = {};
            for i=1,2 do
                if row["eating_before"..i] then
                    table.insert( chat_cfg.eating_before, row["eating_before"..i] )
                end
                if row["eating_ing"..i] then
                    table.insert( chat_cfg.eating_ing, row["eating_ing"..i] )
                end
                if row["eating_finish"..i] then
                    table.insert( chat_cfg.eating_finish, row["eating_finish"..i] )
                end
                if row["gambling_victory"..i] then
                    table.insert( chat_cfg.gambling_victory, row["gambling_victory"..i] )
                end
                if row["gambling_ing"..i] then
                    table.insert( chat_cfg.gambling_ing, row["gambling_ing"..i] )
                end
                if row["gambling_defeat"..i] then
                    table.insert( chat_cfg.gambling_defeat, row["gambling_defeat"..i] )
                end
                if row["hanging_out"..i] then
                    table.insert( chat_cfg.hanging_out, row["hanging_out"..i] )
                end
            end
            chat_config2[row.role_id] = chat_cfg;
        end)
    end
    if id == nil then
        return chat_config2;
    end

    return chat_config2[id];
end

local manor_life_config = nil;
local function GetManorLifeConfig(id, type)
    if manor_life_config == nil then
        manor_life_config = {};
        DATABASE.ForEach("manor_life2", function(row)
            manor_life_config[row.role_id] = manor_life_config[row.role_id] or {};
            manor_life_config[row.role_id][row.type] = row;
        end)
    end
    return manor_life_config[id] and manor_life_config[id][type];
end

local manor_outside_config = nil;
local function GetManorOutsideConfig(gid)
    if manor_outside_config == nil then
        manor_outside_config = LoadDatabaseWithKey("chatting_outside", "gid");
    end
    if gid == nil then
        return manor_outside_config;
    end
    return manor_outside_config[gid]
end

local manor_talker_config = nil;
local function GetManorTalkerConfig(gid)
    if manor_talker_config == nil then
        manor_talker_config = LoadDatabaseWithKey("chatting_outside_two", "gid");
    end
    if gid == nil then
        return manor_talker_config;
    end
    return manor_talker_config[gid]
end

local manor_rumour_config = nil;
local function GetManorRumourConfig(gid)
    if manor_rumour_config == nil then
        manor_rumour_config = LoadDatabaseWithKey("rumour", "gid");
    end
    if gid == nil then
        return manor_rumour_config;
    end
    return manor_rumour_config[gid]
end

local task_info = nil;
local function GetManorTaskInfo(gid)
    if task_info == nil then
        task_info = LoadDatabaseWithKey("manor_task_item", "gid");
    end
    if gid == nil then
        return task_info;
    end
   return task_info[gid]
end

local task_cfg = nil;
local function GetManorTaskConfig(gid)
    if task_cfg == nil then
        task_cfg = LoadDatabaseWithKey("manor_task", "gid");
    end
    if gid == nil then
        return task_cfg;
    end
   return task_cfg[gid]
end

local task_starbox_cfg = nil;
local function GetManorTaskStarBoxConfig(gid)
    if task_starbox_cfg == nil then
        task_starbox_cfg = LoadDatabaseWithKey("manor_task_starbox", "gid");
    end
    if gid == nil then
        return task_starbox_cfg;
    end
   return task_starbox_cfg[gid]
end

local manor_open_cfg = nil;
local function GetManorOpenConfig(line, pos)
    if manor_open_cfg == nil then
        manor_open_cfg = {};
        DATABASE.ForEach("manor_line_open", function(row)
            if manor_open_cfg[row.line] == nil then
                manor_open_cfg[row.line] = {};
            end
            manor_open_cfg[row.line][row.line_pos] = row;
        end)
    end
    pos = pos or 0;
    if line == nil then
        return manor_open_cfg
    else
        return manor_open_cfg[line][pos]
    end
end

local manor_property_lv = nil;
local function GetManorPropertyLevel(type, level)
    if manor_property_lv == nil then
        manor_property_lv = {};
        DATABASE.ForEach("manor_property_lv", function(row)
            if manor_property_lv[row.work_type] == nil then
                manor_property_lv[row.work_type] = {};
            end
            manor_property_lv[row.work_type][row.work_level] = row;
        end)
    end
    if level == nil then
        return manor_property_lv[type]
    else
        return manor_property_lv[type][level]
    end
end

local manor_event_cfg = nil;
local function GetManorEventConfig(id)
    if manor_event_cfg == nil then
        manor_event_cfg = LoadDatabaseWithKey("manor_event", "id");
    end
    if id == nil then
        return manor_event_cfg;
    end
    return manor_event_cfg[id];
end

local npc_table = nil;
local function GetManorNpcTable(gid)
    if npc_table == nil then
        npc_table = LoadDatabaseWithKey("manor_npc_table", "mode");
    end
    if gid == nil then
        return npc_table;
    end
   return npc_table[gid]
end

local manor_npc_cfg = nil;
local manor_npc_cfg_by_quest = nil;
local function LoadManorNpc()
    manor_npc_cfg = {};
    manor_npc_cfg_by_quest = {};
    DATABASE.ForEach("manor_npc", function(row)
        manor_npc_cfg[row.npc_gid] = row;
        if manor_npc_cfg_by_quest[row.quest] == nil then
            manor_npc_cfg_by_quest[row.quest] = {};
        end
        table.insert(manor_npc_cfg_by_quest[row.quest], row);
    end)
end

local manor_level_up_cfg = nil;
local function GetManorLevelUpConfig(line, level)
    manor_level_up_cfg = {};
    DATABASE.ForEach("manor_level_up", function(row)
        if manor_level_up_cfg[row.line] == nil then
            manor_level_up_cfg[row.line] = {};
        end
        manor_level_up_cfg[row.line][row.line_level] = row;
    end)
    if level then
        return manor_level_up_cfg[row.line][row.line_level];
    end
    return manor_level_up_cfg[line];
end

local function GetManorNpcConfig(id)
    if manor_npc_cfg == nil then
        LoadManorNpc()
    end
    if id then
        return manor_npc_cfg[id]
    end
    return manor_npc_cfg
end

local function GetManorNpcConfigByQuest(id)
    if manor_npc_cfg_by_quest == nil then
        LoadManorNpc()
    end
    if id then
        print("读取任务", id, sprinttb(manor_npc_cfg_by_quest[id]))
        return manor_npc_cfg_by_quest[id]
    end
    return manor_npc_cfg_by_quest
end

local ALLOT_NUM = 3;

local function AllotFriendToQuest(quest_id)
    local manor_friend_quest = UserDefault.Load("manor_friend_quest", true)
    if manor_friend_quest.quest and manor_friend_quest.quest[quest_id] then
        local already_select_friend = {};
        for i,v in ipairs(manor_friend_quest.quest[quest_id]) do
            if v.pid ~= 0 then
                already_select_friend[v.pid] = {idx = i, flag = 0};
            end
        end
        local canSelect = {}
        local friend_list = module.FriendModule.GetManager();
        for i,v in ipairs(friend_list) do
            if already_select_friend[v.pid] then
                already_select_friend[v.pid].flag = 1;
            elseif v.level >= openLevel.GetCfg(2001).open_lev then
                table.insert(canSelect, v.pid);
            end
        end
        --检查上次分配的好友是否存在已被删除的
        for k,v in pairs(already_select_friend) do
            if v.flag == 0 then
                manor_friend_quest.quest[quest_id][v.idx].pid = 0;
            end
        end
        for i=1,ALLOT_NUM do
            if #canSelect == 0 then
                break;
            end
            if manor_friend_quest.quest[quest_id][i].pid == 0 then
                -- if i == 1 then--在最近上线的好友中选一个
                --     module.playerModule.GetPlayerList(canSelect, function (players)
                --         if  then
                            
                --         end
                --     end)
                -- end
                local idx = math.random(1, #canSelect)
                manor_friend_quest.quest[quest_id][i].pid = canSelect[idx];
                table.remove(canSelect, idx);
            end
        end
        UserDefault.Save();
    end
end

local function AllotFriendQuest(quest_id)
    local manor_friend_quest = UserDefault.Load("manor_friend_quest", true)
    manor_friend_quest.quest = manor_friend_quest.quest or {};
    local cfg = GetManorNpcConfigByQuest(quest_id);
    if cfg == nil then
        return;
    end
    local allnpc = {};
    for i,v in ipairs(cfg) do
        table.insert(allnpc, v.npc_gid)
    end
    local allot = {};
    for i=1,ALLOT_NUM do
        allot[i] = {
            npc = {},
            pid = 0,
        }
    end
    while #allnpc > 0 do        --将相关任务NPC分为3组，每组至少一个
        local idx = math.random(1, #allnpc);
        local flag = true;
        for i,v in ipairs(allot) do
            local empty = true;
            for _,j in pairs(v.npc) do
                empty = false
                break;
            end
            if empty then
                flag = false;
                allot[i].npc[allnpc[idx]] = {active = true};
                break;
            end
        end
        if flag then
            local _idx = math.random(1, ALLOT_NUM);
            allot[_idx].npc[allnpc[idx]] = {active = true};
        end
        table.remove(allnpc, idx)
    end
    manor_friend_quest.quest[quest_id] = allot;
    AllotFriendToQuest(quest_id)
    print("分配好友", sprinttb(manor_friend_quest.quest))
end

local otherManorStatus = {};
local function GetOtherManorStatus(pid, func)
    if otherManorStatus[pid] == nil or Time.now() - otherManorStatus[pid].time > 10 then
        otherManorStatus[pid] = {};
        otherManorStatus[pid].time = Time.now();
        local news, steal, quest, event = 0, 0, 0, 0;
        local _quest = module.QuestModule.GetList(23, 0)[1];
        local manor_friend_quest = UserDefault.Load("manor_friend_quest", true)
        if _quest and manor_friend_quest.quest and manor_friend_quest.quest[_quest.id] then
            for i,v in ipairs(manor_friend_quest.quest[_quest.id]) do
                if v.pid == pid then
                    for _,j in pairs(v.npc) do
                        if j.active then
                            quest = 1;
                            break;
                        end
                    end
                    break;
                end
            end
        end
    
        local manorProductInfo = module.ManorManufactureModule.Get(pid);
        manorProductInfo:GetProductLineFromServer();
        for i,v in ipairs(dialog_list[4]) do
            local canSteal = manorProductInfo:CanSteal(LoadManorInfo(v).line)
            if canSteal then
                steal = 1;
                break;
            end
        end
        
        local checkInteract = function (npc)
            for _, v in ipairs(npc.interact) do
                if v.pid == module.playerModule.GetSelfID() then
                    return false;
                end
            end
            local quest = module.QuestModule.Get(npc.quest)
            if quest and quest.status ~= 0 then
                return false;
            end
            return true
        end
        local manager = module.ManorRandomQuestNPCModule.GetManager(pid);
        local random_npc = manager:QueryNPC(true)
        for k,v in pairs(random_npc) do
            if event == 0 and v.group == 3 and checkInteract(v) then
                event = 1;
            end
            if news == 0 and v.group == 2 and checkInteract(v) then
                news = 1;
            end
            if event + news == 2 then
                break;
            end
        end
        otherManorStatus[pid].status = {news, steal, quest, event}
    end
    if func then
        func(table.unpack(otherManorStatus[pid].status))
    end
    return table.unpack(otherManorStatus[pid].status)
end

local manor_manufacture_pool = nil;
local function GetManufacturePool(id)
    if manor_manufacture_pool == nil then
        manor_manufacture_pool = {};
        DATABASE.ForEach("manor_manufacture_pool", function(row)
            if manor_manufacture_pool[row.pool_id] == nil then
                manor_manufacture_pool[row.pool_id] = {};
            end
            table.insert(manor_manufacture_pool[row.pool_id], row);
        end)
    end
    return manor_manufacture_pool[id]
end

local manor_riddle = nil;
local function GetManorRiddle(id)
    if manor_riddle == nil then
        manor_riddle = LoadDatabaseWithKey("manor_riddle", "mode_id");
    end
    if id == nil then
        return manor_riddle;
    end
   return manor_riddle[id]
end

local manor_log = {};
local manor_log_str = {};
local manor_log_volume = 100;
local function AddLog(log,sort)
    -- if #manor_log == manor_log_volume then
    --     table.remove(manor_log, 1);
    -- end
    if manor_log[log.day] == nil then
        manor_log[log.day] = {};
        manor_log[log.day].day = log.day;
        manor_log[log.day].date = log.date;
        manor_log[log.day].week = log.week;
        manor_log[log.day].log = {}
    end
    table.insert(manor_log[log.day].log, log);
    -- if sort then
    --     table.sort(manor_log[log.day].log,function ( a,b )
    --         if a.time ~= b.time then
    --             return a.time > b.time
    --         end
    --        return a.id < b.id
    --     end)
    -- end
end

--1 英雄外出
--2 英雄归来
--3 幸运
--4 流行
local log_id = 0;
local function SetLogDes(data,msg)
    local log = {}
    local sort = false
    log.time = data.time;
    -- print("日志", sprinttb(data))
    --log.time_str = os.date("%Y-%m-%d  %H:%M ",math.floor(data.time))
    log.day = tonumber(os.date("%j",math.floor(data.time)))
    log.date = os.date("%Y/%m/%d",math.floor(data.time))
    log.week = tonumber(os.date("%w",math.floor(data.time)))
    log.hour = os.date("%H:%M ",math.floor(data.time))
    log_id = log_id + 1;
    log.id = log_id; 
    log.str = "";
    log.show = true;
    if data.type == 1 then     
        local hero = HeroModule.GetManager():GetByUuid(data.uuid);
        if hero == nil then
            return;
        end
        log.str = hero.name.."从酒馆离开了。";
    elseif data.type == 2 then
        local hero = HeroModule.GetManager():GetByUuid(data.uuid);
        if hero == nil then
            return;
        end
        local des = GetManorPubEvent(data.event_id).event_des;
        local _str = "";
        if data.power ~= 0 then
            _str = tostring(data.power);
        end
        if data.reward[1] ~= nil then
            log.reward = data.reward;
        end
        if _str ~= "" then
            log.str = string.format(des, hero.name, _str);
        else
            log.str = string.format(des, hero.name);
        end
    elseif data.type == 3 then
        local event_cfg = GetManorMineEvent(data.event_list[1][1]);
        if event_cfg and event_cfg.event_tittle then
            log.str = GetManorMineEvent(data.event_list[1][1]).event_tittle;
            local reward = {};
            for i,v in ipairs(data.event_list) do
                table.insert(reward, {v[2], v[3], v[4]})
            end
            log.reward = reward;
        end
    elseif data.type == 4 then
        if data.line == 31 then
            local item = ItemHelper.Get(data.discount_type, data.discount_id);
            local event_cfg = GetManorShopEvent(data.gid);
            if item and event_cfg then
                log.str = string.format(event_cfg.des, item.name, (data.discount - 100).."%", GetTimeFormat(data.active_time, 1));
            end
        elseif data.line == 2 then
            local item = ItemHelper.Get(data.product_type, data.product_id);
            local event_cfg = GetManorShopEvent(data.gid);
            if item then
                log.str = string.format(event_cfg.des, item.name, math.floor((data.discount - 100)/100 * data.product_value), GetTimeFormat(data.active_time, 1));
            end
        end
        log.discount = data.discount;
        log.gid = data.gid;
    elseif data.type == 5 then
        local item_name = "";
        for i,v in ipairs(data.product) do
            local item = ItemHelper.Get(v.type, v.id)
            if item_name ~= "" then
                item_name = item_name .. "、"
            end
            item_name = item_name..item.name;
        end
        -- local reward_name = "";
        -- for i,v in ipairs(data.reward) do
        --     local item = ItemHelper.Get(v[1], v[2])
        --     if reward_name ~= "" then
        --         reward_name = reward_name .. "、"
        --     end
        --     reward_name = reward_name..item.name..v[3].."个";
        -- end
        log.str = "成功出售"..item_name.."，获得了:";
        log.reward = data.reward;
    elseif data.type == 6 then
        local hero = HeroModule.GetManager():GetByUuid(data.workman);
        if hero then
            local bulid = LoadManorInfo(data.line,2).des_name;
            log.str = hero.name.."开始在"..bulid.."工作了。"
        end
    -- elseif data.type == 7 then
    --     sort = true;
    --     str = "商铺来了一位流浪商人，带来了很多新鲜玩意。"
    -- elseif data.type == 8 then
    --     sort = true;
    --     str = "流浪商人已经离开~"
    elseif data.type == 8 then
        local event_cfg = GetManorEventConfig(data.cfg_id);
        if event_cfg then
            local bulid = LoadManorInfo(data.line,2).des_name;
            log.str = string.format("%s在%s中载歌载舞，严重影响了众人的工作效率，%s产量降低%s%%", event_cfg.npc_name, bulid, bulid, math.floor(math.abs(data.effect_percent))); 
        end
    elseif data.type == 11 then
        local event_cfg = GetManorEventConfig(data.cfg_id);
        if event_cfg then
            local bulid = LoadManorInfo(data.line,2).des_name;
            log.str = "loading..."
            log.show = false;
            playerModule.Get(data.opt_id, function ()
                log.show = true;
                log.str = string.format("%s帮助你赶走了捣乱的人，使得%s重新恢复了秩序", playerModule.Get(data.opt_id).name, bulid)
            end)
        end
    elseif data.type == 12 then
        -- local bulid = LoadManorInfo(data.line,2).des_name;
        log.str = "loading..."
        log.show = false;
        playerModule.Get(data.thief, function ()
            log.show = true;
            log.str = string.format("%s偷偷溜进你的庄园顺手带走了：", playerModule.Get(data.thief).name)
        end)
        log.reward = data.item;
    elseif data.type == 13 then
        log.str = "loading..."
        log.show = false;
        playerModule.Get(data.opt_id, function ()
            log.show = true;
            log.str = string.format("%s见义勇为，打败了前来偷盗的小偷，挽回了庄园的损失", playerModule.Get(data.opt_id).name)
        end)
    elseif data.type == 20 then
        local bulid = LoadManorInfo(data.line,2).des_name;
        local _str = bulid.."内"
        local _str1,_str2 = "",""
        if data.lazy_heros and #data.lazy_heros > 0 then
            for i,v in ipairs(data.lazy_heros) do
                if _str1 ~= "" then
                    _str1 = _str1.."、";
                end
                local hero_cfg = HeroModule.GetConfig(v[1]); 
                _str1 = _str1..hero_cfg.name;
            end
            _str1 = _str1.."在制作物品时偷懒了一小会，订单延误了"..GetTimeFormat(data.add_time, 1);
        end
        if data.hardworking_heros and #data.hardworking_heros > 0 then
            for i,v in ipairs(data.hardworking_heros) do
                if _str2 ~= "" then
                    _str2 = _str2.."、";
                end
                local hero_cfg = HeroModule.GetConfig(v[1]); 
                _str2 = _str2..hero_cfg.name;
            end
            _str2 = _str2.."在制作物品时灵感迸发，加快订单制作"..GetTimeFormat(data.reduce_time, 1);
        end
        log.str = _str.._str1.._str2;
    end
    if log.str ~= "" then
        AddLog(log,sort);
        if msg then
            DispatchEvent("MANOR_LOG_CHANGE")
        end
    end
end

local function GetLog()
    return manor_log;
end

EventManager.getInstance():addListener("MANOR_ADD_LOG", function (event, data)
    if data.type == nil  then
        return;
    end
    SetLogDes(data,true);
end);

EventManager.getInstance():addListener("QUEST_INFO_CHANGE", function (event, data)
    local quest = data;
    if quest and quest.type and quest.type == 23 then
        local manor_friend_quest = UserDefault.Load("manor_friend_quest", true)
        print("庄园任务变化", quest.status)
        if quest.status == 0 then
            AllotFriendQuest(quest.id);
        elseif manor_friend_quest.quest then
            manor_friend_quest.quest[quest.id] = nil;
            UserDefault.Save();
        end
    end
end);

EventManager.getInstance():addListener("Friend_INFO_CHANGE", function (event, data)
    local quest = module.QuestModule.GetList(23, 0)[1];
    if quest then
        AllotFriendToQuest(quest.id);
    end
end);

return {
	LoadManorInfo = LoadManorInfo,
	GetManorWorkEffect = GetManorWorkEffect,
	GetManorWorkType = GetManorWorkType,
    GetManorProperty = GetManorProperty,
    GetManorDes = GetManorDes,
    GetWorkName = GetWorkName,
    GetManorWorkEnergy = GetManorWorkEnergy,
    GetManorFightConfig = GetManorFightConfig,
    GetManorFightAdd = GetManorFightAdd,
    GetManorLineConfig = GetManorLineConfig,
    GetManorTaskInfo = GetManorTaskInfo,
    GetManorTaskConfig = GetManorTaskConfig,
    GetManorGradeConfig = GetManorGradeConfig,
    GetManorMineEvent = GetManorMineEvent,
    GetManorShopEvent = GetManorShopEvent,
    SetLogDes = SetLogDes,
    GetLog = GetLog,
    GetDialogList = GetDialogList,
    GetManorOpenConfig = GetManorOpenConfig,
    GetManorChat = GetManorChat,
    GetManorChat2 = GetManorChat2,
    GetManorLifeConfig = GetManorLifeConfig,
    GetManorOutsideConfig = GetManorOutsideConfig,
    GetManorTaskEquationConfig = GetManorTaskEquationConfig,
    GetManorPropertyLevel = GetManorPropertyLevel,
    GetManorEventConfig = GetManorEventConfig,
    GetManufacturePool = GetManufacturePool,
    GetManorTalkerConfig = GetManorTalkerConfig,
    GetManorRumourConfig = GetManorRumourConfig,
    GetManorTaskStarBoxConfig = GetManorTaskStarBoxConfig,
    GetManorNpcTable = GetManorNpcTable,
    GeyPosByInterval = GeyPosByInterval,
    GetManorNpcConfig = GetManorNpcConfig,
    GetManorNpcConfigByQuest = GetManorNpcConfigByQuest,
    GetOtherManorStatus = GetOtherManorStatus,
    GetManorRiddle = GetManorRiddle,
    GetManorLevelUpConfig = GetManorLevelUpConfig,
}
--DialogStack.PushPref("ItemDetailFrame", {InItemBag=1,id = selectedItem.id,uuid=selectedItem.uuid,type = selectedItem.type,func = nil},self.view.gameObject)
--DialogStack.PushPrefStact

-- 评定工人  C_MANOR_MANUFACTURE_EVALUATE_WORKMAN_REQUEST
-- {
-- request: 11015 
--     request[1] = sn
--     request[2] = uuid
--     request[3] = [
--             property_id,
--             property_value,
--              ]  
            
-- respond: 11016
--     respond[1] = sn
--     respond[2] = result
-- }

-- 获取工人属性 C_MANOR_MANUFACTURE_QUERY_WORKMAN_INFO_REQUEST
-- {
-- request: 11017
--     request[1] = sn
--     request[2] = uuid
    
-- respond; 11018
--     respond[1] = sn
--     respond[2] = ret
--     respond[3] = power
--     respond[4] = power_upper_limit
--     respond[5] = power_change_speed
--     respond[6] = power_next_change_time
--     respond[7] = [
--             property_id,
--             property_value,
--         ]
-- }

-- 提高工人活力请求 C_MANOR_MANUFACTURE_INCREASE_POWER_REQUEST
-- {
-- request:11019
--     request[1] = sn
--     request[2] = uuid
--     request[3] = consume_type
--     request[4] = consume_id
--     request[5] = consume_value
--     request[6] = count
-- respond:11020
--     result[1] = sn
--     result[2] = ret  
-- }

-- 提高生产线临时存储量上限请求 C_MANOR_MANUFACTURE_INCREASE_LINE_STORAGE_REQUEST
-- {
-- request:11021
--     request[1] = sn
--     request[2] = line
--     request[3] = index
--     request[4] = consume_type
--     request[5] = consume_id
--     request[6] = consume_value
--     request[7] = count
-- respond:11022
--     result[1] = sn
--     result[2] = ret  
-- }

-- 11023   -- 庄园副本请求
-- request[1] = 请求的次数
-- request[2] = property_id

-- 11024   -- 庄园请求返回
-- respond[1] = 请求的次数
-- respond[2] = 返回码
-- respond[3] = {}     -- { id, attacker, defender, scene }

-- 11025   -- 完成战斗的之后确认请求
-- request[1] = 请求的次数
-- request[2] = workman_id

-- 11026   -- 完成战斗的之后确认返回
-- respond[1] = 请求的次数
-- respond[2] = 返回码
