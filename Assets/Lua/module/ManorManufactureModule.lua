local playerModule = require "module.playerModule"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local UserDefault = require "utils.UserDefault"
local ManorModule = require "module.ManorModule"
local HeroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local ShopModule = require "module.ShopModule"
local openLevel = require "config.openLevel"
--SetSiblingIndex
local C_MANOR_MANUFACTURE_QUERY_PRODUCT_LINE_REQUEST = 11001 --查询生产请求
-- [sn]
local C_MANOR_MANUFACTURE_QUERY_PRODUCT_LINE_RESPOND = 11002 --查询生产返回
-- [sn, result, [[line,gid,speed,gather_time], ...]]

local C_MANOR_MANUFACTURE_QUERY_PRODUCT_REQUEST = 11003 --查询生产列表请求
-- [sn]
local C_MANOR_MANUFACTURE_QUERY_PRODUCT_RESPOND = 11004 --查询生产列表返回
-- [sn, [ [gid,time, [[type,id,value],...], [[type,id,value], ...] ], ...] ]

local C_MANOR_MANUFACTURE_GATHER_REQUEST = 11005 -- 收获请求
-- [sn, line]
local C_MANOR_MANUFACTURE_GATHER_RESPOND = 11006 -- 收获返回
-- [sn, [line,gid]]

local C_MANOR_MANUFACTURE_PRODUCT_REQUEST = 11007 -- 开始生产请求
-- [sn, line, gid]
local C_MANOR_MANUFACTURE_PRODUCT_RESPOND = 11008 -- 开始生产返回
-- [sn, [line,gid,speed,gather_time]]

local C_MANOR_MANUFACTURE_SPEEDUP_REQUEST = 11009 -- 加速生产请求
-- [sn, line, speed]
local C_MANOR_MANUFACTURE_SPEEDUP_RESPOND = 11010 -- 加速生产返回
-- [sn, [line,gid,speed,gather_time]]

local C_MANOR_MANUFACTURE_ADDWORKER_REQUEST = 11011 -- 添加工人
-- [sn, line, id, pos]
local C_MANOR_MANUFACTURE_ADDWORKER_RESPOND = 11012 -- 添加工人返回
-- [sn, result]
local C_MANOR_MANUFACTURE_LEVELUP_REQUEST = 11013 -- 生产线升级
-- [sn, line, level]
local C_MANOR_MANUFACTURE_LEVELUP_RESPOND = 11014 -- 生产线升级返回

local C_MANOR_MANUFACTURE_QUERY_WORKMAN_INFO_REQUEST = 11017 --获取工人属性
--[sn, uuid]
local C_MANOR_MANUFACTURE_QUERY_WORKMAN_INFO_RESPOND = 11018 --获取工人属性返回
--[sn, result, power, power_upper_limit, power_change_speed, power_next_change_time, [property_id, property_value]]

local C_MANOR_MANUFACTURE_INCREASE_POWER_REQUEST = 11019 --提高工人活力请求
--[sn, uuid, consume_type, consume_id, consume_value, count]
local C_MANOR_MANUFACTURE_INCREASE_POWER_RESPOND = 11020 --提高工人活力返回
--[sn, result]

local C_MANOR_MANUFACTURE_INCREASE_LINE_STORAGE_REQUEST = 11021 --提高生产线临时存储量上限请求
local C_MANOR_MANUFACTURE_INCREASE_LINE_STORAGE_RESPOND = 11022 --提高生产线临时存储量上限返回

local C_MANOR_MANUFACTURE_INCREASE_LINE_ORDER_LIMIT_REQUEST = 11071 --提高生产线订单上限请求
local C_MANOR_MANUFACTURE_INCREASE_LINE_ORDER_LIMIT_RESPOND = 11072 --提高生产线订单上限返回

local C_MANOR_MANUFACTURE_FIGHT_REQUEST = 11023 --庄园副本请求
local C_MANOR_MANUFACTURE_FIGHT_RESPOND = 11024 --庄园副本返回

local C_MANOR_MANUFACTURE_FIGHT_RESULT_CHECK_REQUEST = 11025 --完成战斗的之后确认请求
local C_MANOR_MANUFACTURE_FIGHT_RESULT_CHECK_RESPOND = 11026 --完成战斗的之后确认返回

local C_MANOR_QUERY_TASK_REQUEST = 11029 --请求任务列表
local C_MANOR_QUERY_TASK_RESPOND = 11030 --请求任务列表返回

local C_MANOR_DISPATCH_TASK_REQUEST = 11031 --派遣任务
local C_MANOR_DISPATCH_TASK_RESPOND = 11032 --派遣任务返回

local C_MANOR_CHANGE_TASK_REQUEST = 11033 --刷新任务
local C_MANOR_CHANGE_TASK_RESPOND = 11034 --刷新任务返回

local C_MANOR_REWARD_TASK_REQUEST = 11035 --领取任务奖励
local C_MANOR_REWARD_TASK_RESPOND = 11036 --领取任务奖励返回

local C_MANOR_CANCEL_TASK_REQUEST = 11037 --取消酒馆任务
local C_MANOR_CANCEL_TASK_RESPOND = 11038

local C_MANOR_FINISH_TASK_REQUEST = 11039 --快速完成酒馆任务
local C_MANOR_FINISH_TASK_RESPOND = 11040
 
local C_MANOR_STAR_REWARD_INFO_REQUEST = 11051 --查询玩家星星数和星星宝箱的领奖状态
local C_MANOR_STAR_REWARD_INFO_RESPOND = 11052

local C_MANOR_STAR_REWARD_REQUEST = 11053 --获得星星宝箱奖励
local C_MANOR_STAR_REWARD_RESPOND = 11054 

local C_MANOR_REFRESH_ALLTASK_REQUEST = 11057 --刷新全部任务
local C_MANOR_REFRESH_ALLTASK_RESPOND = 11058

local C_MANOR_QUERY_LOG_REQUEST = 11073 --查询日志
local C_MANOR_QUERY_LOG_RESPOND = 11074 --查询日志返回

local C_MANOR_EVENT_REQUEST = 11075 --触发庄园事件
local C_MANOR_EVENT_RESPOND = 11076 --触发庄园事件返回

local C_MANOR_MANUFACTURE_UNLOCK_LINE_REQUEST = 11079 --解锁生产线
local C_MANOR_MANUFACTURE_UNLOCK_LINE_RESPOND = 11080

local C_MANOR_MANUFACTURE_QUERY_LINE_OPEN_STATUS_REQUEST = 11081 --查询生产线解锁状态
local C_MANOR_MANUFACTURE_QUERY_LINE_OPEN_STATUS_RESPOND = 11082

local C_MANOR_MANUFACTURE_QUERY_RANDOM_TASK_REQUEST = 11085 --查询每天更新的庄园任务
local C_MANOR_MANUFACTURE_QUERY_RANDOM_TASK_RESPOND = 11086

local C_MANOR_QUERY_QUEST_REQUEST = 11087 --庄园npc查询
local C_MANOR_QUERY_QUEST_RESPOND = 11088

local NOTIFY_MANOR_RANDOM_NPC_CHANGE = 11087 -- 庄园npc变化通知

local C_MANOR_ACCEPT_QUEST_REQUEST = 11089 --领取庄园NPC任务
local C_MANOR_ACCEPT_QUEST_RESPOND = 11090

local C_MANOR_MANUFACTURE_SPEEDUP_BY_WORKMAN_REQUEST = 11091 --使用工人加速
-- [sn, line, workman_uuid]
local C_MANOR_MANUFACTURE_SPEEDUP_BY_WORKMAN_RESPOND = 11092
-- [sn, result, [line,gid,speed,gather_time]]

local C_MANOR_MANUFACTURE_CANCEL_ORDER_REQUEST = 11093  --取消订单
-- [sn, line, gid, count]
local C_MANOR_MANUFACTURE_CANCEL_ORDER_RESPOND = 11094
-- [sn, result, [line,gid,speed,gather_time]]
local C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_PREPARE_REQUEST = 11107     --请求捣乱小人战斗
-- [sn, line, pid]
local C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_PREPARE_RESPOND = 11108

local C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_CHECK_REQUEST = 11109   --捣乱小人战斗确认
local C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_CHECK_RESPOND = 11110

local C_MANOR_STEAL_REQUEST = 11115     --偷取
-- [sn, pid, line]
local C_MANOR_STEAL_RESPOND = 11116     
-- [sn, result, lineInfo]
local C_MANOR_CLEAR_THIEF_FIGHT_PREPARE_REQUEST = 11111     --请求小偷战斗
-- [sn, pid, line, thief_id]
local C_MANOR_CLEAR_THIEF_FIGHT_PREPARE_RESPOND = 11112
-- [sn, result, fightid, fight_data]
local C_MANOR_CLEAR_THIEF_FIGHT_CHECK_REQUEST = 11113       --验证小偷战斗
-- [sn, win, starValue, code]
local C_MANOR_CLEAR_THIEF_FIGHT_CHECK_RESPOND = 11114       
-- [sn, result, win, reward, lineInfo]
local C_MANOR_MANUFACTURE_SPEEDUP_BY_ITEM_REQUEST = 11123   --消耗道具加速生产请求
-- [sn, line, id config_manor_energy表里的id字段]
local C_MANOR_MANUFACTURE_SPEEDUP_BY_ITEM_RESPOND = 11124
-- [sn, result, info]

local NOTIFY_MANOR_HERO_LEAVE_TAVERN = 1129 --英雄离开酒馆通知
local NOTIFY_MANOR_HERO_BACK_TAVERN = 1130 --英雄返回酒馆通知
local NOTIFY_MANOR_LUCKY_EVENT = 1131 --触发幸运事件通知
local NOTIFY_MANOR_POPULAR_EVENT = 1132 --触发流行事件通知

local NOTIFY_MANOR_EVENT = 1133 --庄园事件通知

local log_type = ""
local function TEST_LOG(type, ...)
    if log_type == "all" then
        print(...)
    elseif log_type == type then
        print(...)
    end
end

local worker_event_data = nil;
local function InitUserdata()
    local _t = os.date("*t", Time.now())
    worker_event_data = UserDefault.Load("worker_event_data", true)
    TEST_LOG("eat", "@@@@@@@@@@事件数据1", sprinttb(worker_event_data))
    if worker_event_data.time == nil  then
        worker_event_data.time = {}
        worker_event_data.time.month = _t.month 
        worker_event_data.time.day = _t.day
        UserDefault.Save();
    end

    if worker_event_data.data == nil or (worker_event_data.time.day ~= _t.day or worker_event_data.time.month ~= _t.month) then
        print("重置")
        worker_event_data.time.month = _t.month 
        worker_event_data.time.day = _t.day
        worker_event_data.data = {};
        worker_event_data.eatFood = {0,0,0};
        UserDefault.Save();
    end
    TEST_LOG("eat", "@@@@@@@@@@事件数据2", sprinttb(worker_event_data))
end

local function GetEfficiency(worker)
    local percent = worker.power/worker.powerlimit;
    if percent == 0 then
        return 0.2;
    -- elseif percent < 0.05 then
    --     return 0.4;   
    -- elseif percent < 0.2 then
    --     return 0.6;    
    -- elseif percent < 0.5 then
    --     return 0.8;
    -- elseif percent < 0.8 then
    --     return 0.9;
    else
        return 1;      
    end
end

local function GetActivePoint(line, worker, pos)
    local line_cfg = ManorModule.GetManorLineConfig(line);
    local adjust = 0;
    if worker == nil then
        return 0;
    end
    local effect = line_cfg.prop_effect[pos];
    local point = (worker.prop[effect.type] or 0) * (effect.ratio / 100);
    adjust = point * line_cfg.cfg.factor / 10000;

    return math.min(2, adjust);
end

local cur_fight_info = {};
local function GetCurFightInfo()
   return cur_fight_info
end

local function ON_SERVER_RESPOND(id, callback)
     EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
     EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local Sn2Data = {};
local ManorManufactureInfo = {}
local ManorLineVisitor = {};
ManorLineVisitor[-1] = 0;
ManorManufactureInfo.MAX_PRODUCT_LINE = 10;

function ManorManufactureInfo.New(pid)
    return setmetatable({
        pid = pid,
        product_list = {},
        product_line = {},
        line_state = {},
        worker = {},
        worker_state = {},
        worker_event = {},
        task = {},
    }, { __index = ManorManufactureInfo });
end

function ManorManufactureInfo:UpdateProductLineFromServerData(v)
    local idx = v[1];
    
    local orders,event,thieves = {},{},{}
    if v[22] then
        event = {
            line_produce_rate = v[22][1],
            line_produce_rate_begin_time = v[22][2],
            line_produce_rate_end_time = v[22][3],
            line_produce_rate_rate_reason = v[22][4],
            line_produce_rate_depend_fight = v[22][5],
            line_produce_rate_extra_data = v[22][6],
            line_speed_rate = v[22][7],
            line_speed_rate_begin_time = v[22][8],
            line_speed_rate_end_time = v[22][9],
            line_speed_rate_rate_reason = v[22][10],
            line_speed_rate_depend_fight = v[22][11],
            line_speed_rate_extra_data = v[22][12],
        }
    end
    if v[24] then
        for i,v in ipairs(v[24]) do
            local thief = {};
            thief.thief_id = v[1];
            thief.begin_time = v[2];
            thief.end_time = v[3];
            thief.depend_fight_id = v[4];
            thief.reward = v[5];
            table.insert(thieves, thief);
        end
    end
    self.product_line[idx] = {
        idx = idx,
        speed = v[2],
        next_gather_gid = v[3],
        next_gather_time = v[4],
        worker = v[6],
        orders = orders,
        curspeed_gather_time = v[7],--当前速度下完成时间
        next_speed_change_time = v[8],--下次速度变化时间
        storge1 = v[9],
        storge2 = v[10],
        storge3 = v[11],
        order_start_time = v[12],
        order_limit = v[13],
        level = v[14],
        storge4 = v[15],
        storge5 = v[16],
        storge6 = v[17],
        current_order_produce_rate = v[18],
        workman_speed = v[19],
        workman_produce_rate = v[20],
        storge_pool = v[21],
        event = event,
        event_start_time = v[23],
        thieves = thieves,
    }
    --print("生产线数据"..idx, sprinttb(v))
    for k, o in ipairs(v[5]) do
        orders[o[1]] = {
            order = k;
            gid = o[1],
            left_count = o[2],
            gather_count = o[3],
            count1 = o[4],
            count2 = o[5],
            count3 = o[6],
            count4 = o[7],
            count5 = o[8],
            count6 = o[9],
            product_pool = o[10],
            stolen_value1 = o[11],
            stolen_value2 = o[12],
            stolen_value3 = o[13],
            stolen_value4 = o[14],
            stolen_value5 = o[15],
            stolen_value6 = o[16],
        }
    end

    -- local line_cfg = ManorModule.GetManorLineConfig(idx);
    -- if self.worker ~= nil and line_cfg ~= nil then
    --     local point = 0;        
    --     if idx < 30 then
    --         local adjust = 0;
    --         for i=1,#line_cfg.prop_effect do
    --             local workerid = v[6][i];
    --             if workerid ~= nil and workerid ~= 0 and self.worker[workerid] ~= nil then
    --                 adjust = adjust + GetActivePoint(idx, self.worker[workerid], i);
    --             end
    --         end
    --         if idx < 10 then
    --             self.product_line[idx].effect_time = 1/(adjust + 1);
    --         elseif idx < 20 then
    --             self.product_line[idx].effect_gather = (adjust + 1);
    --         end
    --     else
    --         local adjust1,adjust2 = 0, 0;
    --         for i=1,4 do
    --             local workerid = v[6][i];
    --             if workerid ~= nil and workerid ~= 0 and self.worker[workerid] ~= nil then
    --                 if i <= 2 then
    --                     adjust1 = adjust1 + GetActivePoint(idx, self.worker[workerid], i);
    --                 else
    --                    adjust2 = adjust2 + GetActivePoint(idx, self.worker[workerid], i);
    --                 end
                    
    --             end
    --         end
    --         self.product_line[idx].effect_gather = (adjust1 + 1);
    --         self.product_line[idx].effect_time = 1/(adjust2 + 1);
    --     end
    -- end
    
    local produce_rate, reduce = 0, 1;
    for i,v in ipairs(self.product_line[idx].workman_produce_rate) do
        produce_rate = produce_rate + v;
    end
    for i,v in ipairs(self.product_line[idx].workman_speed) do
        if v ~= 0 then
            local _reduce = 100 / (100 + v);
            reduce = reduce * _reduce
        end
    end
    self.product_line[idx].effect_gather = 1 + produce_rate / 100;
    self.product_line[idx].effect_time = reduce;
    -- print("@@@生产线", idx, sprinttb(self.product_line[idx]));
    -- print("MANUFACTURE LINE", self.product_line[idx].idx, self.product_line[idx].speed, self.product_line[idx].next_gather_gid, self.product_line[idx].next_gather_time);
end

function ManorManufactureInfo:updateWorkerState(refresh)
    if refresh then        
        self.worker_state = {};
        for k,v in pairs(self.product_line) do
            for _,j in ipairs(v.worker) do
                if j ~= 0 then
                    local line = v.idx;
                    self.worker_state[j] = {};
                    self.worker_state[j].line = line;

                    if self.worker_event[j] and not self.worker_event[j].outside then
                        self.worker_event[j].where = line;
                    end
                    
                    if line == 1 then
                        self.worker_state[j].state = 5;
                    elseif line >= 2 and line <= 4 then
                        self.worker_state[j].state = 1;
                    elseif line >= 11 and line <= 14 then
                        self.worker_state[j].state = 2;
                    elseif line == 31 then
                        self.worker_state[j].state = 3;
                    else
                        self.worker_state[j].state = 0;
                    end
                    if v.next_gather_time > Time.now() then
                        self.worker_state[j].working = 1;
                    else
                        self.worker_state[j].working = 0;
                    end
                end
            end
        end
    end
    if self.task.list then
        for k,v in pairs(self.task.list) do
            if v.staff then
                for _,j in ipairs(v.staff) do
                    if j and j ~= 0 then
                        if self.worker_state[j] == nil then
                            self.worker_state[j] = {};
                        end
                        -- self.worker_state[j].state = 4;
                        -- self.worker_state[j].working = 1;
                        self.worker_state[j].task = 1;
                    end
                end
            end
        end
    end
end

function ManorManufactureInfo:updateTaskList(data)
    local list, count, compelet_count = data[3], data[4], data[5]
    self.task.list = {};
    for i,v in ipairs(list) do
        local task = {};
        task.gid = v[1];
        task.state = v[2];
        task.staff = v[6];
        if task.staff and #task.staff ~= 0 then
            for _,j in ipairs(task.staff) do
                if self.worker_state[j] == nil then
                    self.worker_state[j] = {};
                end
                self.worker_state[j].state = 4;
                self.worker_state[j].working = 1;
            end
        end
        task.begin_time = v[3] or 0;
        task.end_time = v[4] or 0;
        task.success = v[5] or 0;
        self.task.list[task.gid] = task;
    end
    self.task.change_count = count;
    if compelet_count then
        self.task.compelet_count = compelet_count;
    end
end

function ManorManufactureInfo:updateStarBoxState(data)
    self.task.starBox = {};
    self.task.starBox.count = data[3];
    self.task.starBox.status = data[4];
end

function ManorManufactureInfo:updateWorkerInfo(uuid, data)
    local worker = {};
    --worker.name = HeroModule.GetManager():GetByUuid(uuid).name;
    worker.power = data[3];
    worker.powerlimit = data[4];
    worker.delta = data[5];
    worker.nextchange = data[6];
    worker.prop = {};
    for i,v in ipairs(data[7]) do
        worker.prop[v[1]] = v[2];
    end
    setmetatable(worker.prop, {__index = function ( t,k )
        return 0;
    end})
    local line = data[8]
    worker.line = line;
    -- if line >= 1 and line <= 4 then
    --     worker_state = 1;
    -- elseif line >= 11 and line <= 14 then
    --     worker_state = 2;
    -- elseif line == 31 then
    --     worker_state = 3;
    -- else
    --     worker_state = 0;
    -- end

    worker.fight_count = {};
    for i,v in ipairs(data[9]) do
        if worker.fight_count[v[1]] == nil then
            worker.fight_count[v[1]] = {};
        end
        worker.fight_count[v[1]][v[2]] = v[3];
    end
    worker.event = data[10];
    worker.leave_time = data[11];
    worker.back_time = data[12];

    self.worker[uuid] = worker;
    if self.worker_event[uuid] == nil then
        self:InitWorkerEvent(uuid,worker);
    elseif not self.worker_event[uuid].outside then
        self.worker_event[uuid].where = line;
    end
    -- print("工人属性变化"..uuid, sprinttb(self.worker[uuid]))
end

function ManorManufactureInfo:InitWorkerEvent(uuid,worker)
    local event = {};
    if worker_event_data.data[uuid] == nil then
        worker_event_data.data[uuid] = {};
        worker_event_data.data[uuid].eatFood = {0,0,0}
        worker_event_data.data[uuid].startEatFood = 0;
        worker_event_data.data[uuid].endEatFood = 0;
        worker_event_data.data[uuid].startWait = 0;
        worker_event_data.data[uuid].waitForEat = 0;
    end
    event.uuid = uuid;
    if HeroModule.GetManager(self.pid) and HeroModule.GetManager(self.pid):GetByUuid(uuid) then
        event.name = HeroModule.GetManager(self.pid):GetByUuid(uuid).name;
    end
    event.eatFood = worker_event_data.data[uuid].eatFood;
    event.waitForEat = worker_event_data.data[uuid].waitForEat == 1;
    event.startEatFood = worker_event_data.data[uuid].startEatFood;
    event.endEatFood = worker_event_data.data[uuid].endEatFood;
    event.startWait = worker_event_data.data[uuid].startWait;
    event.where = worker.line;
    event.outside = false;
    event.moving = false;
    event.goOutsideTime = 0;
    event.goBackTime = 0;
    event.togo = 0;
    event.pos = 0;
    self.worker_event[uuid] = event;
end


function ManorManufactureInfo:SetWorkerEvent(uuid, data)
    if self.worker_event[uuid] ~= nil then
        for k,v in pairs(data) do
            if self.worker_event[uuid][k] ~= nil then
                self.worker_event[uuid][k] = v;
            end
        end
    end
end

function ManorManufactureInfo:RemoveProductLine(idx)
    self.product_line[idx] = nil;
end

function ManorManufactureInfo:GetLine(idx)
    if idx ~= nil then
        return self.product_line[idx];
    else
        return self.product_line;
    end
end

function ManorManufactureInfo:GetTask(gid)
    if gid then
        return self.task.list[gid];
    else
        return self.task;
    end
end

function ManorManufactureInfo:GetRandomTask()
    local list = module.QuestModule.GetList(103, 0)

    ERROR_LOG("random quest")
    for _, v in ipairs(list) do
        print('--->', v.id, v.name, v.status);
    end
    return #list > 0 and list[1].id or 0;

end

function ManorManufactureInfo:GetWorkerInfo(uuid,type)
    if type == nil or type == 1 then
        return self.worker[uuid];
    elseif type == 2 then
        return self.worker_state[uuid];
    elseif type == 3 then
        return self.worker_event[uuid];
    end
end

function ManorManufactureInfo:GetAllWorker()
    return self.worker;
end

local CheckWorkerFinish = false;
local QueryWorkerCount = 0;
function ManorManufactureInfo:CheckWorkerProperty(notRefresh, line)
    QueryWorkerCount = 0;
    local checkUUid = {};
    if line and self.product_line[line] then
        for i,v in ipairs(self.product_line[line].worker) do
            if v ~= 0 and i <= 5 then
                local uuid = v;
                if notRefresh then
                    if self.worker[uuid] == nil then
                        QueryWorkerCount = QueryWorkerCount - 1;
                        table.insert( checkUUid, uuid );
                    end
                else
                    if self.worker[uuid] == nil or (Time.now() > self.worker[uuid].nextchange) then
                        QueryWorkerCount = QueryWorkerCount - 1;
                        table.insert( checkUUid, uuid );
                    end
                end
            end
        end
    else
        local heros = HeroModule.GetManager(self.pid):Get();
        for k,v in pairs(heros) do
            local uuid = v.uuid;
            if notRefresh then
                if self.worker[uuid] == nil then
                    QueryWorkerCount = QueryWorkerCount - 1;
                    table.insert( checkUUid,v.uuid );
                end
            else
                if self.worker[uuid] == nil or (Time.now() > self.worker[uuid].nextchange) then
                    QueryWorkerCount = QueryWorkerCount - 1;
                    table.insert( checkUUid,v.uuid );
                end
            end
        end
    end
    if #checkUUid == 0 then
        CheckWorkerFinish = true;
        DispatchEvent("MANOR_MANUFACTURE_CHECK_WORKER_INFO_SUCCESS")
    end
    for i,v in ipairs(checkUUid) do
        self:QueryWorkerInfo(math.floor(v), 0, true);
    end
end

function ManorManufactureInfo:GetProductList(line)
    if line then
        return self.product_list[line];
    else
        return self.product_list;
    end
    
end

function ManorManufactureInfo:Gather(idx)
    if self.product_line[idx] == nil then
        return false;
    end
    print("收获",idx);
    return NetworkService.Send(C_MANOR_MANUFACTURE_GATHER_REQUEST, {nil, idx});
end

function ManorManufactureInfo:StartProduce(line, gid ,count)
    if self.product_line[line] == nil  then
        print("product line not exists")
        return false;
    end

    local product_info = self:GetProductList(line);
    if not product_info[gid] then
        print("product not exists");
        return false;
    end
    print(line.."开始生产"..gid.."数量"..(count or 1));
    return NetworkService.Send(C_MANOR_MANUFACTURE_PRODUCT_REQUEST, {nil, gid, count or 1});
end

function ManorManufactureInfo:Speedup(idx, speed)
    if self.product_line[idx] == nil or self.product_line[idx].next_gather_time <= Time.now() then
        return false;
    end
    return NetworkService.Send(C_MANOR_MANUFACTURE_SPEEDUP_REQUEST, {nil, idx, speed});
end

function ManorManufactureInfo:GetProductLineFromServer()
    -- print("查询", debug.traceback())
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_QUERY_PRODUCT_LINE_REQUEST, {nil, self.pid});
    Sn2Data[sn] = {pid = self.pid}
    if coroutine.isyieldable() then
        Sn2Data[sn].co = coroutine.running();
        coroutine.yield();
    end
end

function ManorManufactureInfo:GetProductListFromServer()
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_QUERY_PRODUCT_REQUEST)
    Sn2Data[sn] = self.pid
end

function ManorManufactureInfo:AddWorker(line, id, pos, select)
    print("工人上岗",line,id,pos)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_ADDWORKER_REQUEST,{nil,line, id, pos});
    Sn2Data[sn] = {line = line, id = id, select = select};
end

function ManorManufactureInfo:SendMineOrder(line)
    local product_line = self.product_line[line];
    local product_list = self.product_list[line];
    
    local gid = 0;
    for k,v in pairs(product_list) do
        gid = v.gid;
        break;
    end

    local canStart = false;
    if product_list and product_line and product_line.worker then
        for i,v in ipairs(product_line.worker) do
            if v ~= 0 then
               canStart = true;
               break;
            end
        end
        if canStart then
            local productlist = nil;
            for k,v in pairs(product_list) do
                if v.level_limit == product_line.level then
                    productlist = v;
                    break;
                end
            end
            if productlist then
                local pool = {};
                local pool1 = ManorModule.GetManufacturePool(productlist.product_pool1);
                local pool2 = ManorModule.GetManufacturePool(productlist.product_pool2);
                if pool1 then
                    for i,v in ipairs(pool1) do
                        table.insert(pool, v);
                    end
                end
                if pool2 then
                    for i,v in ipairs(pool2) do
                        table.insert(pool, v);
                    end
                end
                --计算每个订单生产数量期望
                local each_order_count, allWeight = 0, 0;
                for i,v in ipairs(pool) do
                    allWeight = allWeight + v.weight;
                end
                for i,v in ipairs(pool) do
                    each_order_count = each_order_count + v.item_value * (v.weight / allWeight);
                end

                local need_order_count = 0 --需要追加的订单
                local need_cancel_count = {} --需要取消的订单
                local count, left_count = 0,0;

                for gid,v in pairs(product_line.orders) do
                    if product_list[gid].level_limit < product_line.level then  --取消低等级订单
                        need_cancel_count[gid] = (need_cancel_count[gid] or 0) + v.left_count
                    else
                        left_count = left_count + v.left_count
                    end
                    if v.product_pool then
                        for i,j in ipairs(v.product_pool) do
                            count = count + j[3]
                        end
                    end
                end
                
                need_order_count = math.floor((product_line.storge_pool - count - math.ceil(each_order_count * left_count))/each_order_count);
                -- print("订单平衡", need_order_count, sprinttb(need_cancel_count))
                coroutine.resume(coroutine.create(function ()
                    for k,v in pairs(need_cancel_count) do
                        print("取消订单", line, k, v)
                        if v > 0 then
                            local data = NetworkService.SyncRequest(C_MANOR_MANUFACTURE_CANCEL_ORDER_REQUEST, {nil, line, k, v})
                            if data[2] ~= 0 then
                                ERROR_LOG("取消订单失败", data[2])
                            end
                        end
                    end
                    if need_order_count > 0 then
                        print("开始订单", line, productlist.gid, need_order_count)
                        local data = NetworkService.SyncRequest(C_MANOR_MANUFACTURE_PRODUCT_REQUEST, {nil, productlist.gid, need_order_count})
                        if data[2] ~= 0 then
                            ERROR_LOG("追加订单失败", data[2], productlist.gid)
                        end
                    end
                end))
                
            end
        end
    end
end

function ManorManufactureInfo:QueryWorkerInfo(uuid,refresh,isCheck)
    -- print("查询属性",uuid, self.pid);
    local isRefresh = refresh or 0;
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_QUERY_WORKMAN_INFO_REQUEST, {nil, uuid, isRefresh, self.pid});
    Sn2Data[sn] = {uuid = uuid, pid = self.pid, isCheck = isCheck};
end

function ManorManufactureInfo:AddWorkerEnergy(uuid, food)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_INCREASE_POWER_REQUEST, {nil, uuid, food.type, food.id, food.value, 1});
    Sn2Data[sn] = {uuid = uuid, addpower = food.add_energy, food_id = food.id};
end

function ManorManufactureInfo:StartFight(property_id, uuid, heros, condition)
    print("请求战斗",property_id, uuid,sprinttb(heros))
    cur_fight_info = {};
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_FIGHT_REQUEST, {nil, property_id, uuid, heros});
    Sn2Data[sn] = {uuid = uuid, condition = condition, property_id = property_id};
end

function ManorManufactureInfo:FightCheck(uuid, property_id, condition, fight_id, add_property)
    print("确认战斗",uuid, property_id, condition, fight_id, add_property);
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_FIGHT_RESULT_CHECK_REQUEST, {nil, uuid, property_id, condition, fight_id});
    Sn2Data[sn] = {uuid = uuid, add_property = add_property, property_id = property_id};
end

function ManorManufactureInfo:QueryTask()
    NetworkService.Send(C_MANOR_QUERY_TASK_REQUEST, {nil, 1});
end

function ManorManufactureInfo:ChangeTask(gid)
    print("刷新任务", gid)
    NetworkService.Send(C_MANOR_CHANGE_TASK_REQUEST, {nil, gid, 1});
end

function ManorManufactureInfo:DispatchTask(gid, staff)
    local sn = NetworkService.Send(C_MANOR_DISPATCH_TASK_REQUEST, {nil, gid, staff, 1});
    Sn2Data[sn] = {gid = gid, staff = staff};
end

function ManorManufactureInfo:RewardTask(gid)
    print("完成任务", gid)
    local sn = NetworkService.Send(C_MANOR_REWARD_TASK_REQUEST, {nil, gid, 1});
    Sn2Data[sn] = {gid = gid, staff = self:GetTask(gid).staff};
end

function ManorManufactureInfo:CancelTask(gid)
    print("取消任务", gid)
    local sn = NetworkService.Send(C_MANOR_CANCEL_TASK_REQUEST, {nil, gid, 1});
    Sn2Data[sn] = {gid = gid, staff = self:GetTask(gid).staff};
end

function ManorManufactureInfo:FinishTask(gid)
    print("快速完成任务", gid)
    local sn = NetworkService.Send(C_MANOR_FINISH_TASK_REQUEST, {nil, gid, 1});
    Sn2Data[sn] = {gid = gid, staff = self:GetTask(gid).staff};
end

function ManorManufactureInfo:GetStarBoxInfoFromServer()
    print("查询宝箱信息")
    NetworkService.Send(C_MANOR_STAR_REWARD_INFO_REQUEST, {nil, 1});
end

function ManorManufactureInfo:RewardStarBox(gid)
    print("领取宝箱", gid)
    local sn = NetworkService.Send(C_MANOR_STAR_REWARD_REQUEST, {nil, gid, 1});
end

function ManorManufactureInfo:RefreshAllTask()
    print("刷新全部任务")
    NetworkService.Send(C_MANOR_REFRESH_ALLTASK_REQUEST, {nil, 1});
end

function ManorManufactureInfo:UpgradeStorgage(line, type, id, add_storage)
    print("提高上限", line,type,id)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_INCREASE_LINE_STORAGE_REQUEST, {nil, line, type, id, 1, 1});
    Sn2Data[sn] = {add_storage = add_storage, line = line};
end

function ManorManufactureInfo:UpgradeOrderLimit( line )
    NetworkService.Send(C_MANOR_MANUFACTURE_INCREASE_LINE_ORDER_LIMIT_REQUEST, {nil, line, 41, 90006, 50, 1});
end

function ManorManufactureInfo:TriggerEvent( type,line )
    NetworkService.Send(C_MANOR_EVENT_REQUEST, {nil, type, line});
end

function ManorManufactureInfo:QueryLog()
    NetworkService.Send(C_MANOR_QUERY_LOG_REQUEST);
end

function ManorManufactureInfo:GetLineState( line )
    if line == 0 then
        local player = playerModule.Get(self.pid);
        return player.level >= openLevel.GetCfg(2002).open_lev;
    end
    if self.line_state[line] == nil then
        return false;
    else
        return self.line_state[line];
    end
end

function ManorManufactureInfo:UnlockLine( line )
    print("解锁", line)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_UNLOCK_LINE_REQUEST, {nil, line})
    Sn2Data[sn] = line;
end

function ManorManufactureInfo:QueryLineState(line)
    -- print("查询生产线状态", line,  self.pid)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_QUERY_LINE_OPEN_STATUS_REQUEST, {nil, line, self.pid})
    Sn2Data[sn] = {line = line, pid = self.pid};
end

function ManorManufactureInfo:SpeedUpByWorker(line, uuid)
    print("工人加速", line, uuid)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_SPEEDUP_BY_WORKMAN_REQUEST, {nil, line, uuid})
    Sn2Data[sn] = {line = line, uuid = uuid};
end

function ManorManufactureInfo:SpeedUpByFood(line, id)
    print("食物加速", line, id)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_SPEEDUP_BY_ITEM_REQUEST, {nil, line, id})
    Sn2Data[sn] = {line = line, id = id};
end

function ManorManufactureInfo:CancelOrder(line, gid, count)
    print("取消订单", line, gid, count)
    NetworkService.Send(C_MANOR_MANUFACTURE_CANCEL_ORDER_REQUEST, {nil, line, gid, count})
end

function ManorManufactureInfo:StartTroubleManFight(line, event_type)
    print("请求战斗", line)
    local sn = NetworkService.Send(C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_PREPARE_REQUEST, {nil, line, self.pid, event_type})
    Sn2Data[sn] = {line = line, pid = self.pid};
end

function ManorManufactureInfo:CheckTroubleManFight(win, starValue, code)
    print("战斗确认", win, starValue, code)
    local sn = NetworkService.Send(C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_CHECK_REQUEST, {nil, win, starValue, code})
    Sn2Data[sn] = self.pid;
end

function ManorManufactureInfo:Steal(line)
    print("偷取", line)
    local sn = NetworkService.Send(C_MANOR_STEAL_REQUEST, {nil, self.pid, line})
    Sn2Data[sn] = {line = line, pid = self.pid};
end

function ManorManufactureInfo:StartThiefFight(line, thief_id)
    print("请求战斗", line, thief_id)
    local sn = NetworkService.Send(C_MANOR_CLEAR_THIEF_FIGHT_PREPARE_REQUEST, {nil, self.pid, line, thief_id})
    Sn2Data[sn] = {line = line, pid = self.pid};
end

function ManorManufactureInfo:ThiefFightCheck(win, starValue, code)
    print("战斗确认", win, starValue, code)
    local sn = NetworkService.Send(C_MANOR_CLEAR_THIEF_FIGHT_CHECK_REQUEST, {nil, win, starValue, code})
    Sn2Data[sn] = self.pid;
end

function ManorManufactureInfo:UpgradeLine(line, level)
    print("生产线升级", line, level)
    local sn = NetworkService.Send(C_MANOR_MANUFACTURE_LEVELUP_REQUEST, {nil, line, level})
    Sn2Data[sn] = {line = line, level = level};
end
function ManorManufactureInfo:CanSteal(line)
    local line_cfg = ManorModule.GetManorLineConfig(line).cfg;
    if line_cfg.steal_item ~= 0 and module.ItemModule.GetItemCount(line_cfg.steal_item) <= 0 then
        return false
    end
    if self.product_line[line] then
        if #self.product_line[line].thieves > 0 and Time.now() < self.product_line[line].thieves[1].end_time then
            return false;
        end
        for k,v in pairs(self.product_line[line].orders) do
            for i=1,6 do
                if v["count"..i] ~= 0 then
                    if v["count"..i]/(v["count"..i] + v["stolen_value"..i]) > line_cfg.steal_guarantee/10000 then
                        if math.floor(v["count"..i] * line_cfg.every_steal / 10000) >= 1 then
                            return true;
                        end
                    end
                end
            end
            for i,j in ipairs(v.product_pool) do
                if j[3]/(j[3] + j[4]) > line_cfg.steal_guarantee/10000 then
                    if math.floor(j[3] * line_cfg.every_steal / 10000) >= 1 then
                        return true;
                    end
                end
            end
        end
    end
    return false
end

local player_manufacture_info = {}
local function GetManufactureInfo(pid)
    pid = pid or playerModule.GetSelfID();
    if player_manufacture_info[pid] == nil then
        player_manufacture_info[pid] = ManorManufactureInfo.New(pid)
    end
    return player_manufacture_info[pid];
end

-- local first = true
-- local function StartQuerySchedule()
--     if first then
--         local last_query_time = 0;

--         SGK.CoroutineService.Schedule(function()
--             if os.time() - last_query_time < 30 then
--                 return;
--             end
--             last_query_time = os.time();
--             print("定时查询属性")
--             local manager = HeroModule.GetManager();
--             local hero = manager:Get(11000);
--             if hero then
--                 local info = GetManufactureInfo();
--                 info:QueryWorkerInfo(hero.uuid)
--             end
--         end);
--         first = false;
--     end
-- end
local InManorScene = false;
local IsSelfManor = true;
local ManorOwner = nil;
local PauseActive = false;
local CalDinnerTimeFinish = false;
math.randomseed(tostring(os.time()):reverse():sub(1, 7))


local EnterManorScene = false;
local EatWaitList = {};
   -- event.uuid = uuid;
    -- event.eatFood = worker_event_data.data[uuid].eatFood;
    -- --event.waitForEat = false;
    -- event.startEatFood = 0;
    -- event.endEatFood = 0;
    -- event.startWait = 0;
    -- event.endWait = 0;
    -- event.where = worker.line;
    -- event.outside = false;
    -- event.pos = 0;
local AlreadyCalDinnerTime = false;
local function CalManorWorkerDinnerTime()
    local waitNum = 4;
    local dinnerNum = 5;
    local info = GetManufactureInfo();
    local __t = os.date("*t", Time.now());
    local dinnerTime = 0
    local needCal = false;
    if __t.hour == 8 and __t.min < 30 then
        if worker_event_data.eatFood[1] == 0 then
            needCal = true;
        end
        dinnerTime = 1;
    elseif __t.hour == 12 and __t.min < 30 then
        if worker_event_data.eatFood[2] == 0 then
            needCal = true;
        end
        dinnerTime = 2;
    elseif __t.hour == 18 and __t.min < 30 then
        if worker_event_data.eatFood[3] == 0 then
            needCal = true;
        end
        dinnerTime = 3;
    end

    if dinnerTime == 0 then --没到吃饭时间
        TEST_LOG("eat", "没到吃饭时间")
        return;
    end

    local dinner_worker = {};
    EatWaitList = {};
    if needCal then
        TEST_LOG("eat", "需要计算吃饭时间")
        for k,v in pairs(info.worker) do
            local event = info.worker_event[k];
            info.worker_event[k].waitForEat = false;
            if event then
                if v.line == -1 then
                    event.startEatFood = Time.now();
                    event.endEatFood = Time.now() + math.random(6,18) * 10;
                    event.startWait = 0;
                    event.waitForEat = false;
                    dinnerNum = dinnerNum - 1;
                else
                    event.startEatFood = 0;
                    event.endEatFood = 0;
                    event.startWait = 0;
                    event.waitForEat = false;
                end
                table.insert(dinner_worker,event);
            end
        end
    else
        TEST_LOG("eat", "不需要计算吃饭时间",sprinttb(info.worker_event))
        local waiting = {};
        for k,v in pairs(info.worker) do
            local event = info.worker_event[k];
            if event then
                if event.endEatFood ~= 0 then
                    table.insert(dinner_worker,event);
                    if event.endEatFood <= Time.now() then
                        info.worker_event[k].startWait = 0;
                        info.worker_event[k].startEatFood = 0;
                        info.worker_event[k].endEatFood = 0;
                        info.worker_event[k].where = v.line;
                        info.worker_event[k].outside = false;
                        info.worker_event[k].waitForEat = false;
                    elseif (event.startEatFood == 0 or event.startEatFood <= Time.now()) and event.endEatFood > Time.now() then
                        info.worker_event[k].startWait = 0;
                        info.worker_event[k].startEatFood = 0;
                        info.worker_event[k].where = -1;
                        info.worker_event[k].outside = true;
                        info.worker_event[k].waitForEat = false;
                    elseif (event.startWait == 0 or event.startWait <= Time.now()) and event.startEatFood > Time.now() then
                        info.worker_event[k].startWait = 0;
                        info.worker_event[k].waitForEat = true;
                        info.worker_event[k].outside = true;
                        table.insert(waiting, event);
                    end
                end
            end
        end
        
        if #waiting ~= 0 then
            table.sort(waiting, function ( a,b )
                if a.startEatFood ~= b.startEatFood then
                    return a.startEatFood < b.startEatFood
                end
                return a.uuid < b.uuid
            end)
            
            for i,v in ipairs(waiting) do
                table.insert(EatWaitList, v)
                info.worker_event[v.uuid].where = 100 + i;
            end
            DispatchEvent("MANOR_NPC_WAIT", {waiting = waiting})
        end
        TEST_LOG("eat", "正在排队",sprinttb(EatWaitList));
    end
    AlreadyCalDinnerTime = true;

    if #dinner_worker == 0 then --全都吃完了
        CalDinnerTimeFinish = true;
        return;
    end
    if not needCal then --不需要重新计算吃饭时间
        CalDinnerTimeFinish = true;
        return;
    end

    -- TEST_LOG("eat", "#############测试1",sprinttb(dinner_worker));
    local random_worker = {};
    for i=1,#dinner_worker do
        local idx = math.random(1,#dinner_worker);
        table.insert(random_worker,dinner_worker[idx]);
        table.remove( dinner_worker,idx );
    end
    -- TEST_LOG("eat", "#############测试2",sprinttb(random_worker));
    local simTime = Time.now() + 2;
    while true do
        local NextEatDinner = {};
        local NotEatDinner = {};
        for i,v in ipairs(random_worker) do
            local _event = info.worker_event[v.uuid];
            if _event.eatFood[dinnerTime] == 0 and  _event.endEatFood ~= 0 and simTime >= _event.endEatFood then
                info.worker_event[v.uuid].eatFood[dinnerTime] = 1;
                dinnerNum = dinnerNum + 1;
                TEST_LOG("eat", simTime,_event.name.."吃完", dinnerNum);
            end
            if _event.startEatFood == 0 then
                if _event.startWait ~= 0 then
                    table.insert( NextEatDinner,v );
                end
                table.insert( NotEatDinner,v );
            end
        end

        if #NotEatDinner == 0 then
            print("跳出",simTime)
            break;
        end
        if dinnerNum > 0 then
            if #NextEatDinner > 0 then
                info.worker_event[NextEatDinner[1].uuid].startEatFood = simTime;
                info.worker_event[NextEatDinner[1].uuid].endEatFood = simTime + math.random(3,12) * 10;
                waitNum = waitNum + 1;
                TEST_LOG("eat", simTime,info.worker_event[NextEatDinner[1].uuid].name.."排完队开始吃", waitNum, dinnerNum - 1);
            else
                info.worker_event[NotEatDinner[1].uuid].startEatFood = simTime;
                info.worker_event[NotEatDinner[1].uuid].endEatFood = simTime + math.random(3,12) * 10;
                TEST_LOG("eat", simTime,info.worker_event[NotEatDinner[1].uuid].name.."直接开始吃", dinnerNum - 1);
            end
            dinnerNum = dinnerNum - 1;
        elseif waitNum > 0 then
            for i,v in ipairs(NotEatDinner) do
                if v.startWait == 0 then
                    info.worker_event[v.uuid].startWait = simTime;
                    waitNum = waitNum - 1;
                    TEST_LOG("eat", simTime,info.worker_event[v.uuid].name.."开始排队", waitNum);
                    break;
                end
            end
        end
        simTime = simTime + math.random(1,2);
    end
    CalDinnerTimeFinish = true;
    TEST_LOG("eat", "#############测试3",sprinttb(info.worker_event));
    worker_event_data.eatFood[dinnerTime] = 1;
    
end

local function SaveWorkerEvent()
    TEST_LOG("eat", "保存事件",sprinttb(worker_event_data));
    local info = GetManufactureInfo();
    for k,v in pairs(info.worker_event) do
        if worker_event_data.data[v.uuid] == nil then
            worker_event_data.data[uuid] = {};
        end
        worker_event_data.data[v.uuid].eatFood = v.eatFood
        worker_event_data.data[v.uuid].startEatFood = v.startEatFood;
        worker_event_data.data[v.uuid].endEatFood = v.endEatFood;
        worker_event_data.data[v.uuid].startWait = v.startWait;
        worker_event_data.data[v.uuid].waitForEat = v.waitForEat and 1 or 0;
    end
    UserDefault.Save();
end

local function GetBuildingName(line)
    if line == nil then
        return nil;
    elseif line == -1 then
        return "tavern"
    elseif line == 0  then
        return "exit1"
    elseif line == 1  then
        return "institute"
    elseif line > 1 and line < 10 then
        return "manufacture"
    elseif line >= 10 and line < 20 then
        return "mine"
    elseif line >= 30 and line < 40 then
        return "store"
    elseif line >= 100 then
        return "talk1"
    end
end


local function PushWaitList(uuid,from)
    local info = GetManufactureInfo();
    local worker = info.worker_event[uuid];
    if #EatWaitList < 4 then
        table.insert( EatWaitList, worker)
        info.worker_event[uuid].outside = true;
        info.worker_event[uuid].where = 100 + #EatWaitList;
        TEST_LOG("eat", info.worker_event[uuid].name.."开始排队",GetBuildingName(from), "list"..#EatWaitList)
        DispatchEvent("MANOR_NPC_MOVE", {uuid = uuid, from = GetBuildingName(from), to = "list"..#EatWaitList, type = "eating"})
    else
        ERROR_LOG("EatWaitList is overflow", sprinttb(EatWaitList), worker.name)
    end
end

local function PopWaitList(uuid,to)
    local info = GetManufactureInfo();
    local worker = info.worker_event[uuid];
    if #EatWaitList > 0 then
        table.remove(EatWaitList, 1);
        TEST_LOG("eat", worker.name.."排完队吃饭",GetBuildingName(to),sprinttb(EatWaitList));
        DispatchEvent("MANOR_NPC_MOVE", {uuid = uuid, to = GetBuildingName(to), type = "eating"})
        if #EatWaitList > 0 then
            for i,v in ipairs(EatWaitList) do
                info.worker_event[uuid].outside = true;
                info.worker_event[v.uuid].where = 100 + i;
                TEST_LOG("eat", info.worker_event[v.uuid].name.."往前移动","list"..i)
                DispatchEvent("MANOR_NPC_MOVE", {uuid =v.uuid, to = "list"..i, type = "eating"})
            end
        end
    else
        ERROR_LOG("EatWaitList is empty")
    end
end

local function RemoveFromWaitList(uuid)
    local pos = 0;
    for i,v in ipairs(EatWaitList) do
        if uuid == v.uuid then
            pos = i;
            break;
        end
    end
    if pos ~= 0 then
        local info = GetManufactureInfo();
        DispatchEvent("MANOR_REMOVE_NPC", {id = EatWaitList[pos].uuid})
        table.remove(EatWaitList, pos);
        if #EatWaitList > 0 then
            for i,v in ipairs(EatWaitList) do
                info.worker_event[uuid].outside = true;
                local where = 100 + i;
                if info.worker_event[v.uuid].where ~= where then
                    info.worker_event[v.uuid].where = where;
                    TEST_LOG("eat", info.worker_event[v.uuid].name.."往前移动","list"..i)
                    DispatchEvent("MANOR_NPC_MOVE", {uuid =v.uuid, to = "list"..i, type = "eating"})
                end
            end
        end
    end
end

local OutsideWorker = {};
local function CheckWorkerGoOutside()
    local canStart = true;
    local __t = os.date("*t", Time.now());
    if (__t.hour == 8 and __t.min < 40) or (__t.hour == 7 and __t.min > 50) then
        canStart = false;
    elseif (__t.hour == 12 and __t.min < 40) or (__t.hour == 11 and __t.min > 50) then
        canStart = false;
    elseif (__t.hour == 18 and __t.min < 40) or (__t.hour == 17 and __t.min > 50) then
        canStart = false;
    end
    if not canStart then   
        return;
    end
    for k,v in pairs(ManorLineVisitor) do --可访问建筑索引
        ManorLineVisitor[k] = 0;
    end
    OutsideWorker = {};
    local InsideWorker = {};
    local info = GetManufactureInfo();
    for k,v in pairs(info.worker_event) do
        local worker_state = info.worker_state[v.uuid];
        if worker_state == nil or worker_state.state ~= 4 then
            if v.outside or v.togo ~= 0 then
                if v.togo ~= 0 and ManorLineVisitor[v.togo] then
                    ManorLineVisitor[v.togo] = ManorLineVisitor[v.togo] + 1;
                elseif ManorLineVisitor[v.where] then
                    ManorLineVisitor[v.where] = ManorLineVisitor[v.where] + 1;
                end
                table.insert(OutsideWorker,v)
            else
                table.insert(InsideWorker,v)
            end
        end
    end
    local canVisit = {};
    for k,v in pairs(ManorLineVisitor) do
        if v < 1 then
            table.insert(canVisit,k)
        end
    end
    if #canVisit == 0 then
        TEST_LOG("out","建筑物访客空间已满",sprinttb(ManorLineVisitor));
        return;
    end
    if #InsideWorker == 0 then
        TEST_LOG("out","所有人都已外出");
        return;
    end
    local count = #InsideWorker;
    for i=1,count do
        local idx = math.random(1, #InsideWorker);
        local worker_event = InsideWorker[idx];
        local gid = HeroModule.GetManager():GetByUuid(worker_event.uuid).id;
        local life_cfg = ManorModule.GetManorLifeConfig(gid, 5);
        if life_cfg then
            local worker_state = info.worker_state[worker_event.uuid];
            local chance = 0;
            if worker_state then
                if worker_state.working == 1 then
                    chance = life_cfg.working_rate;
                else
                    chance = life_cfg.unworking_rate;
                end
            else
                chance = life_cfg.free_rate;
            end
            local _canVisit = {};
            for i,v in ipairs(canVisit) do
                if GetBuildingName(info.worker_event[worker_event.uuid].where) ~= GetBuildingName(v) then
                    table.insert( _canVisit, v);
                end
            end

            if chance >= math.random(1,100) and #_canVisit ~= 0 then
                info.worker_event[worker_event.uuid].goOutsideTime = Time.now();
                info.worker_event[worker_event.uuid].goBackTime = Time.now() + math.random(60,300);
                local pos = math.random(1, #_canVisit);
                info.worker_event[worker_event.uuid].outside = true;
                info.worker_event[worker_event.uuid].togo = _canVisit[pos];
                table.remove(_canVisit, pos);
                table.insert(OutsideWorker,info.worker_event[worker_event.uuid]);
                TEST_LOG("out",info.worker_event[worker_event.uuid].name.."触发闲逛,从"..GetBuildingName(info.worker_event[worker_event.uuid].where).."去"..GetBuildingName(info.worker_event[worker_event.uuid].togo),
                sprinttb(info.worker_event[worker_event.uuid]));
                break;
            end
        end
        table.remove(InsideWorker,idx);
        -- if #_canVisit == 0 then
        --     break;
        -- end
    end
end

local function CheckWorkerOutsideState()
    local _outsideWorker = {};
    local info = GetManufactureInfo();
    for i,v in ipairs(OutsideWorker) do --闲逛
        if v.goBackTime ~= 0 and Time.now() >= v.goBackTime then
            local delta = Time.now() - v.goBackTime;
            local from = info.worker_event[v.uuid].where;
            local to = info.worker[v.uuid].line;
            info.worker_event[v.uuid].goBackTime = 0;
            info.worker_event[v.uuid].goOutsideTime = 0;
            info.worker_event[v.uuid].where = info.worker[v.uuid].line;
            info.worker_event[v.uuid].togo = 0;
            if delta > 30 then
                info.worker_event[v.uuid].outside = false;
                info.worker_event[v.uuid].moving = false;
                --结束移动
            elseif delta > 5 then
                info.worker_event[v.uuid].outside = true;
                info.worker_event[v.uuid].moving = true;
                --返回途中
                DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(from), to = GetBuildingName(to), type = "outside", args = {random = true, goback = true}});
            else
                info.worker_event[v.uuid].outside = true;
                info.worker_event[v.uuid].moving = true;
                DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(from), to = GetBuildingName(to), type = "outside", args = {random = false, goback = true}});
                --开始返回
            end
        elseif v.goOutsideTime ~= 0 and Time.now() >= v.goOutsideTime then
            local delta = Time.now() - v.goOutsideTime;
            local from = info.worker_event[v.uuid].where;
            local to = info.worker_event[v.uuid].togo;
            info.worker_event[v.uuid].goOutsideTime = 0;
            info.worker_event[v.uuid].outside = true;
            info.worker_event[v.uuid].where = info.worker_event[v.uuid].togo;
            info.worker_event[v.uuid].togo = 0;
            if delta > 30 then
                info.worker_event[v.uuid].moving = false;
                --结束移动
            elseif delta > 5 then
                info.worker_event[v.uuid].moving = true;
                --闲逛途中
                DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(from), to = GetBuildingName(to), type = "outside", args = {random = true, goback = false}});
            else
                info.worker_event[v.uuid].moving = true;
                --开始闲逛
                DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(from), to = GetBuildingName(to), type = "outside", args = {random = false, goback = false}});
            end
        end
        if info.worker_event[v.uuid].outside then
            table.insert(_outsideWorker,info.worker_event[v.uuid]);
        end
   end
   OutsideWorker = _outsideWorker;
end

local function GetOutsideWorker()
    local _outsideWorker = {};
    for i,v in ipairs(OutsideWorker) do
        _outsideWorker[i] = v;
    end
    return _outsideWorker;
end

local taskTeamInfo = {};
local function GetTaskTeamInfo(gid)
    if gid then
        return taskTeamInfo[gid];
    end
    return taskTeamInfo;
end

local function SetTaskTeamInfo(gid, data)
    if taskTeamInfo[gid] then
        if data ~= nil then
            for k,j in pairs(data) do
                if taskTeamInfo[gid][k] ~= nil then
                    taskTeamInfo[gid][k] = j;
                end
            end
            DispatchEvent("MANOR_TASK_TEAM_CHANGE",{gid = gid, data = data});
        else
            taskTeamInfo[gid] = nil;
        end
    end
end

local MAX_VISITOR = 3;
local VisitorManager = {};
local NeedScreenVisitor = true;

function VisitorManager.New()
    return setmetatable({
        visitors = {},
        canShowVisitos = {},
    },{__index = VisitorManager})
end

function VisitorManager:ScreenVisitor()
    if NeedScreenVisitor then
        local visitorConfig = ManorModule.GetManorOutsideConfig();
        self.canShowVisitos = {}
        for k,v in pairs(visitorConfig) do
            local quest = module.QuestModule.Get(v.condition_id)
            -- if quest then
            --     print("任务", v.condition_id, quest.status)
            -- else
            --     print("任务不存在", v.condition_id)
            -- end
            if quest and quest.status == 1 and self.visitors[v.gid] == nil then
                table.insert(self.canShowVisitos, v.gid)
            end
        end
    end
    return self.canShowVisitos;
end

--判断任务本身以及任务的分支是否完成
local function IsNextQuest(id)
    local quest = module.QuestModule.Get(id);
    if quest then
        if quest.status == 0 then
            return true;
        elseif quest.status == 1 then
            local branch = utils.SGKTools.TaskQuery(id)
            if branch and #branch > 0 then
                local finish = 0;
                for j,v in ipairs(branch) do
                    local _quest = module.QuestModule.Get(v.quest);
                    if _quest and _quest.status == 1 then
                        finish = finish + 1;
                    end
                end
                if finish == 0 then
                    return true;
                end
            else
                return false
            end
        end
    end
    return false
end

function VisitorManager:CheckVisitor()
    local canVisit = {}
    for k,v in pairs(ManorLineVisitor) do --可访问建筑索引
        if k ~= -1 then
            canVisit[k] = 0;
        end
    end

    -- canVisit[11] = 0
    local count = 0;
    local canTalk = true;
    for k,v in pairs(self.visitors) do
        for i,j in ipairs(v.togo) do
            if j < 100 then
                canVisit[j] = canVisit[j] + 1;
            else
                canTalk = false;
            end
        end
        count = count + 1;
    end

    if count >= MAX_VISITOR then
        TEST_LOG("visit","外来访客人数已满",sprinttb(self.visitors));
        return;
    end

    local _canVisit = {};
    for k,v in pairs(canVisit) do
        if v < 1 then
            table.insert(_canVisit,k)
        end
    end

    local canShowVisitors = self:ScreenVisitor();
    if #canShowVisitors == 0 then
        TEST_LOG("visit","没有可用的访客");
        return;
    end
    --根据权重随机访客
    local _visitors = {};
    local allWeight = 0;
    for i,v in ipairs(canShowVisitors) do
        local visitorConfig = ManorModule.GetManorOutsideConfig(v);
        allWeight = allWeight + visitorConfig.weight;
        table.insert(_visitors, {gid = v, weight = allWeight});
    end
    local _weight = math.random(0, allWeight);
    local index = 1;
    for i,v in ipairs(_visitors) do
        if _weight <= v.weight then
            index = i;
            break;
        end
    end

    local info = {};
    info.pos = 0;
    info.where = 0;
    info.togo = {}
    info.moving = false;
    info.gid = _visitors[index].gid;
    info.quest_step = 0;
    -- if canTalk then--判断访客是否有未完成的任务
    --     local visitorConfig = ManorModule.GetManorOutsideConfig(info.gid);
    --     for i=1,6 do
    --         if visitorConfig["quest"..i] ~= 0 then
    --             if IsNextQuest(visitorConfig["quest"..i]) then
    --                 info.quest_step = i;
    --                 break;
    --             end
    --         end
    --     end
    -- end

    -- if info.quest_step ~= 0 then
    --     info.next_move_time = {Time.now() + math.random(1,10)};
    --     table.insert(info.togo, 100)
    --     table.insert(info.next_move_time, info.next_move_time[1] + 3600);
    -- else
    if #_canVisit == 0 then
        info.next_move_time = {};
        TEST_LOG("visit","建筑物外来访客空间已满",sprinttb(canVisit));
        DispatchEvent("MANOR_ADD_VISITOR", info.gid)
    else
        info.next_move_time = {Time.now() + math.random(20,30)};
        local togo_count = math.random(1,math.min(#_canVisit,3));
        for i=1,togo_count do
            local idx = math.random(1, #_canVisit)
            local pos = _canVisit[idx];
            table.insert(info.togo, pos)
            table.insert(info.next_move_time, info.next_move_time[i] + 1000);
            table.remove(_canVisit,idx);
        end
    end
    TEST_LOG("visit","触发外来访客",sprinttb(info));
    self.visitors[info.gid] = info;
end

function VisitorManager:CheckVisitorState()
    local clear = {};
    for k,v in pairs(self.visitors) do
        for i,j in ipairs(v.next_move_time) do
            if Time.now() >= j then
                self.visitors[k].pos = i;
            else
                break;
            end
        end
        if self.visitors[k].pos > #v.togo then
            table.insert(clear, k);
        else
            self.visitors[k].where = v.togo[self.visitors[k].pos];
            self.visitors[k].moving = false;
        end
    end
    for i,v in ipairs(clear) do
        self.visitors[v] = nil;
        table.insert(self.canShowVisitos, v);
    end
end

function VisitorManager:SetVisitorInfo(gid, data)
    if self.visitors[gid] then
        if data ~= nil then
            for k,j in pairs(data) do
                if self.visitors[gid][k] ~= nil then
                    self.visitors[gid][k] = j;
                end
            end
        else
            self.visitors[gid] = nil;
            table.insert(self.canShowVisitos, gid);
        end
    end
end

function VisitorManager:GetVisitor(id)
    if id then
        return self.visitors[id];
    end 
    return self.visitors;
end

local manor_visitor_info = {}
local function GetVisitorManager(pid)
    pid = pid or playerModule.GetSelfID();
    if manor_visitor_info[pid] == nil then
        manor_visitor_info[pid] = VisitorManager.New(pid)
    end
    return manor_visitor_info[pid];
end

local function ScreenTalker()
    local talkerConfig = ManorModule.GetManorTalkerConfig();
    local canShowTalkers = {}
    for k,v in pairs(talkerConfig) do
        local quest = module.QuestModule.Get(v.condition_id)
        if quest and quest.status == 1 then
            table.insert(canShowTalkers, v.gid)
        end
    end
    return canShowTalkers
end

local manro_talker_info = nil;
local function CheckTalker()
    if manro_talker_info then
        local quest_id = manro_talker_info.cfg["quest"..manro_talker_info.step];
        if not IsNextQuest(quest_id) then
            manro_talker_info = nil;
        end
    end
    if manro_talker_info == nil then
        local canShowTalkers = ScreenTalker();
        if #canShowTalkers ~= 0 then
            local talkers = {}
            for i,v in ipairs(canShowTalkers) do
                local talkerConfig = ManorModule.GetManorTalkerConfig(v);
                for i=1,6 do
                    if talkerConfig["quest"..i] ~= 0 then
                        if IsNextQuest(talkerConfig["quest"..i]) then
                            table.insert(talkers, {step = i, cfg = talkerConfig})
                            break;
                        end
                    end
                end
            end
            
            -- talkers = {};
            -- table.insert(talkers, {step = 1, cfg = ManorModule.GetManorTalkerConfig(24)})
            if #talkers ~= 0 then
                manro_talker_info = talkers[math.random(1, #talkers)];
            end
        else
            print("没有可用对话NPC")
        end
    end
    print("信息",sprinttb(manro_talker_info))
    return manro_talker_info;
end

local function ResetTalker()
    manro_talker_info = nil;
end

local function IsInDinnerTime()
    local eat = false;
    local __t = os.date("*t", Time.now());
    if __t.hour == 8 and __t.min < 30 then
        eat = true;
    elseif __t.hour == 12 and __t.min < 30 then
        eat = true;
    elseif __t.hour == 18 and __t.min < 30 then
        eat = true;
    end
    
    if AlreadyCalDinnerTime then
        if eat then
            return false;
        else
            AlreadyCalDinnerTime = eat;
            return false;
        end
    else
        return eat;
    end  
end

local const = 3600;
local offset = 20; 

local QUEST_NPC = {};
local luckline = {};
local popularline = {};
local next_luck_time = {};
local next_popular_time = {};

local last_query_time = os.time();
local last_event_time = os.time();
local last_goOutside_time = os.time() + math.random(30, 60);--math.random(30, 60)
local last_shop_time = 0;
local last_visitor_time = os.time() + math.random(5, 10);--math.random(60, 90)
local last_worker_event_time = 0;
local shop_close_time = 0;
SGK.CoroutineService.Schedule(function()
    if InManorScene and not PauseActive and IsSelfManor then
        if os.time() - last_query_time >= 30 then
            print("定时查询属性")
            last_query_time = os.time();
            local manager = HeroModule.GetManager();
            local info = GetManufactureInfo();
            local hero = manager:Get(11000);
            if hero then
                info:QueryWorkerInfo(hero.uuid)
            end

            -- if info.product_line then
            --     local canGather = false;
            --     if info.product_line[31] then
            --         for k,v in pairs(info.product_line[31].orders) do
            --             if v.gather_count > 0 then
            --                 canGather = true;
            --             end
            --         end
            --     end
            --     if canGather then
            --         info:Gather(31);
            --     end
            -- end
        end

        if os.time() >= last_visitor_time then
            GetVisitorManager():CheckVisitor();
            last_visitor_time = os.time() + math.random(60, 90);
        end
        
        if os.time() >= last_goOutside_time then --工人闲逛触发
            last_goOutside_time = os.time() + math.random(15, 30);
            CheckWorkerGoOutside();
        end

        if #QUEST_NPC > 0 then
            if Time.now() >= QUEST_NPC[1].move_time then
                local info = GetManufactureInfo();
                info.npc_quest[QUEST_NPC[1].quest_id].move = true;
                if Time.now() >= QUEST_NPC[1].move_time + 10 then
                    DispatchEvent("MANOR_ADD_QUEST_NPC", QUEST_NPC[1].quest_id, "quest"..info.npc_quest[QUEST_NPC[1].quest_id].pos, "quest"..info.npc_quest[QUEST_NPC[1].quest_id].pos);
                else
                    DispatchEvent("MANOR_ADD_QUEST_NPC", QUEST_NPC[1].quest_id, "exit1", "quest"..info.npc_quest[QUEST_NPC[1].quest_id].pos);
                end
                table.remove(QUEST_NPC, 1);
            end
        end

        if os.time() - last_event_time >= 2 then --庄园事件
           last_event_time = os.time();
           local info = GetManufactureInfo();
           local visitorManager = GetVisitorManager();
           for k,v in pairs(next_luck_time) do
                if os.time() >= v then
                    next_luck_time[k] = next_luck_time[k] + math.floor(const * (100 + math.random(0,offset))/100);
                    --print(k,"下次触发幸运时间",os.date("%Y-%m-%d  %H:%M:%S",math.floor(next_luck_time[k])))
                    if info.product_line[k] then
                        local empty = true;
                        for i,v in ipairs(info.product_line[k].worker) do
                            if v ~= 0 then
                                empty = false;
                                break;
                            end
                        end
                        if not empty then
                            --print("请求幸运事件",k);
                            info:TriggerEvent(2,k);
                        end  
                    end
                end
           end
        --    for k,v in pairs(next_popular_time) do
        --         if os.time() >= v then
        --             next_popular_time[k] = next_popular_time[k] + math.floor(const * (100 + math.random(0,offset))/100);
        --             --print("请求流行事件",k);
        --             info:TriggerEvent(1,k);
        --         end
        --    end

            for i,v in ipairs(OutsideWorker) do --闲逛
                if not info.worker_event[v.uuid].moving then
                    if v.goBackTime ~= 0 and Time.now() >= v.goBackTime then
                        local from = info.worker_event[v.uuid].where;
                        local to = info.worker[v.uuid].line;
                        info.worker_event[v.uuid].goBackTime = 0;
                        info.worker_event[v.uuid].goOutsideTime = 0;
                        info.worker_event[v.uuid].where = info.worker[v.uuid].line;
                        info.worker_event[v.uuid].moving = true;
                        --开始返回
                        DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(from), to = GetBuildingName(to), type = "outside", args = {random = false, goback = true}});
                    elseif v.goOutsideTime ~= 0 and Time.now() >= v.goOutsideTime then
                        local from = info.worker_event[v.uuid].where;
                        local to = info.worker_event[v.uuid].togo;
                        info.worker_event[v.uuid].goOutsideTime = 0;
                        -- info.worker_event[v.uuid].outside = true;
                        info.worker_event[v.uuid].where = info.worker_event[v.uuid].togo;
                        info.worker_event[v.uuid].togo = 0;
                        info.worker_event[v.uuid].moving = true;
                        --开始闲逛
                        DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(from), to = GetBuildingName(to), type = "outside", args = {random = false, goback = false}});
                    end
                end
           end

           for k,v in pairs(visitorManager.visitors) do --外来访客
                if v.next_move_time[v.pos + 1] and Time.now() >= v.next_move_time[v.pos + 1] and not v.moving then
                    visitorManager.visitors[k].pos = v.pos + 1;
                    visitorManager.visitors[k].moving = true;
                    if visitorManager.visitors[k].pos > #v.togo then
                        local from = v.where;
                        visitorManager.visitors[k].where = 0;
                        DispatchEvent("MANOR_NPC_MOVE", {uuid = v.gid, from = GetBuildingName(from), to = "exit"..math.random(1,2), type = "visit", args = {random = false}});
                        -- DispatchEvent("MANOR_NPC_MOVE", {uuid = v.gid, from = GetBuildingName(from), to = "exit2", type = "visit", args = {random = false}});
                    else
                        local from = v.where;
                        if from == nil then
                            ERROR_LOG(sprinttb(v))
                        end
                        visitorManager.visitors[k].where = v.togo[visitorManager.visitors[k].pos];
                        local to = visitorManager.visitors[k].where;
                        DispatchEvent("MANOR_NPC_MOVE", {uuid = v.gid, from = GetBuildingName(from), to = GetBuildingName(to), type = "visit", args = {random = false}});
                    end
                end
           end
        end

        if os.time() - last_worker_event_time >= 1 then --生活事件
            last_worker_event_time = os.time();
            local info = GetManufactureInfo();
            -- if EnterManorScene and CheckWorkerFinish then
            --     EnterManorScene = false
            --     CalManorWorkerDinnerTime();
            --     SaveWorkerEvent();
            -- end
            if CheckWorkerFinish and not CalDinnerTimeFinish then
                if IsInDinnerTime() then
                    CalManorWorkerDinnerTime();
                    SaveWorkerEvent();
                end
            end

            if CalDinnerTimeFinish then
                local worker_count, end_eat = 0,0;
                for k,v in pairs(info.worker_event) do
                    -- print(v.name, sprinttb(v))
                    local worker_state = info.worker_state[v.uuid];
                    if worker_state == nil or worker_state.state ~= 4 then
                        worker_count = worker_count + 1;
                        if v.startWait ~= 0 and v.startWait <= Time.now() and v.startEatFood > Time.now() and not v.waitForEat then
                            info.worker_event[v.uuid].startWait = 0;
                            info.worker_event[v.uuid].waitForEat = true;
                            PushWaitList(v.uuid, info.worker[v.uuid].line)
                            local gid = HeroModule.GetManager():GetByUuid(v.uuid).id;
                            local chat_cfg = ManorModule.GetManorChat2(gid);
                            if chat_cfg then
                                DispatchEvent("MANOR_NPC_SPEAK",v.uuid, 1, chat_cfg.eating_before[math.random(1,2)])
                            end
                            --DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(info.worker[v.uuid].line), to = "list"})
                        elseif v.startEatFood ~= 0 and v.startEatFood <= Time.now() and v.endEatFood > Time.now() and v.where ~= -1 and info.worker[v.uuid].line ~= -1 then
                            info.worker_event[v.uuid].where = -1;
                            info.worker_event[v.uuid].startEatFood = 0;
                            if v.waitForEat then
                                info.worker_event[v.uuid].waitForEat = false;
                                PopWaitList(v.uuid, -1)
                                --DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = "list", to = "tavern"})
                            else
                                info.worker_event[v.uuid].outside = true;
                                TEST_LOG("eat", info.worker_event[v.uuid].name.."开始吃饭",info.worker[v.uuid].line,GetBuildingName(info.worker[v.uuid].line), "tavern")
                                DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = GetBuildingName(info.worker[v.uuid].line), to = "tavern", type = "eating"})
                                local gid = HeroModule.GetManager():GetByUuid(v.uuid).id;
                                local chat_cfg = ManorModule.GetManorChat2(gid);
                                if chat_cfg then
                                    DispatchEvent("MANOR_NPC_SPEAK",v.uuid, 1, chat_cfg.eating_before[math.random(1,2)])
                                end
                            end                     
                        elseif v.endEatFood ~= 0 and v.endEatFood <= Time.now() and v.where == -1 and info.worker[v.uuid].line ~= -1 then
                            info.worker_event[v.uuid].endEatFood = 0;
                            info.worker_event[v.uuid].outside = false;
                            info.worker_event[v.uuid].where = info.worker[v.uuid].line;
                            TEST_LOG("eat", info.worker_event[v.uuid].name.."吃完","tavern", GetBuildingName(info.worker[v.uuid].line),info.worker[v.uuid].line)
                            DispatchEvent("MANOR_NPC_MOVE", {uuid = v.uuid, from = "tavern", to = GetBuildingName(info.worker[v.uuid].line), type = "eating"})
                            local gid = HeroModule.GetManager():GetByUuid(v.uuid).id;
                            local chat_cfg = ManorModule.GetManorChat2(gid);
                            if chat_cfg then
                                DispatchEvent("MANOR_NPC_SPEAK",v.uuid, 1, chat_cfg.eating_finish[math.random(1,2)])
                            end
                        elseif v.endEatFood == 0 then
                            end_eat = end_eat + 1;
                        end
                    elseif v.endEatFood ~= 0 then
                        info.worker_event[v.uuid].startWait = 0;
                        info.worker_event[v.uuid].startEatFood = 0;
                        info.worker_event[v.uuid].endEatFood = 0;
                        info.worker_event[v.uuid].waitForEat = false;
                        info.worker_event[v.uuid].outside = false;
                        info.worker_event[v.uuid].where = info.worker[v.uuid].line;
                    end
                end
                if worker_count == end_eat then
                    TEST_LOG("eat","所有人已经吃完")
                    CalDinnerTimeFinish = false;
                end
            end
        end

        -- if shop_close_time == 0 and os.time() - last_shop_time >= 600 then
        --     last_shop_time = os.time();
        --     ShopModule.Query(32);
        -- end

        -- if shop_close_time ~= 0 and os.time() >= shop_close_time then
        --     DispatchEvent("MANOR_ADD_LOG", {type = 8, time = shop_close_time})
        --     shop_close_time = 0;
        -- end
    end
end);

 
EventManager.getInstance():addListener("ENTER_MANOR_SCENE",function(event)
    EnterManorScene = true;
end);

local login_order = false;
local prepare_line,prepare_list  = false, false;
local query_log = false;
local needInit = false;

local function SendLoginOrder()
    if prepare_line and prepare_list then
        login_order = false;
        local info = GetManufactureInfo();
        for k,v in pairs(info.product_line) do
            local manorInfo = ManorModule.LoadManorInfo(v.idx, 2);	
            if manorInfo and info.line_state[v.idx] == nil then
                info:QueryLineState(v.idx);
            end
        end

        if not query_log then
            query_log = true;
            NetworkService.Send(C_MANOR_QUERY_LOG_REQUEST);
        end
    end
end

local function ManorInit()
    -- ERROR_LOG("初始化")
    login_order = true;
    local player = playerModule.Get();
    NetworkService.Send(C_MANOR_MANUFACTURE_QUERY_PRODUCT_REQUEST);
    NetworkService.Send(C_MANOR_MANUFACTURE_QUERY_PRODUCT_LINE_REQUEST, {nil, player.id});
    if player.level >= openLevel.GetCfg(2002).open_lev then
        NetworkService.Send(C_MANOR_QUERY_TASK_REQUEST,{nil,1});
    end
    

    luckline = ManorModule.GetManorMineEvent(nil,2);
    -- popularline = ManorModule.GetManorShopEvent(nil,2);
    
    
    for k,v in pairs(luckline) do
        next_luck_time[k] = os.time();
    end
    -- for k,v in pairs(popularline) do
    --     next_popular_time[k] = os.time();
    -- end
end

EventManager.getInstance():addListener("LOGIN_SUCCESS", function() 
    if worker_event_data == nil then
        InitUserdata();
    end

    playerModule.Get(nil, function ()
        local player = playerModule.Get();
        if player.level >= openLevel.GetCfg(2001).open_lev then
            ManorInit();
        else
            needInit = true;
        end
    end)
end);

EventManager.getInstance():addListener("WORKMAN_TITLE_CHANGE",function(event, uuid)
    local info = GetManufactureInfo();
    info:QueryWorkerInfo(uuid);
end);

-- EventManager.getInstance():addListener("MANOR_SHOP_OPEN",function(event, data)
--     if shop_close_time == 0 then
--         DispatchEvent("MANOR_ADD_LOG", {type = 7, time = data.begin_time})
--         shop_close_time = data.end_time;
--     end
-- end);

local productIDToGid = nil;
local dependIDToGid = nil
local function GetProductAndDependIndex()
   if productIDToGid == nil then
      productIDToGid = {};
      dependIDToGid = {};
      local info = GetManufactureInfo();
      for i=1,2 do
        for k,v in pairs(info.product_list[i]) do
            productIDToGid[v.reward[1].id] = k;
            dependIDToGid[v.depend_item] = k;
        end
      end
   end
   return productIDToGid, dependIDToGid;
end

-- local item_price = {};
-- local function GetItemPrice(id)
--     if item_price[id] == nil then
--         local info = GetManufactureInfo();
--         for k,v in pairs(info.product_list[31]) do
--             if v.consume[1].id == id then
--                 item_price[id] = v.reward[1].value;
--                 return item_price[id];
--             end
--         end
--         return 0;
--     else
--         return item_price[id];
--     end
-- end

-- 0 可生产
-- 1 生产列表中没有该物品
-- 2 未研究该物品
-- 3 材料不足

local function CheckProduct(id)
    local info = GetManufactureInfo();
    for i=1,4 do
        if info.product_list and info.product_list[i] then
            local product_list = info.product_list[i];
            for k,v in pairs(product_list) do
                if id == v.reward[1].id then
                    if v.depend_item ~= 0 and ItemModule.GetItemCount(v.depend_item) == 0 then
                        --没有依赖物品
                        return 2;
                    end
                    for j,x in ipairs(v.consume) do
                        if ItemModule.GetItemCount(x.id) < x.value then
                            --材料不足
                            return 3;
                        end
                    end
                    return 0;
                end
            end
        end
    end
    return 1;
end

local function GetManorStatus()
    if ManorOwner == nil then
        ManorOwner = playerModule.GetSelfID();
    end
    return IsSelfManor,ManorOwner
end

local function ShowProductSource(id, interval, teleport, callback)
    local _,pid = GetManorStatus();
    local info = GetManufactureInfo(pid);
    if interval and interval ~= 0 then
        local pos = ManorModule.GeyPosByInterval(interval);
        if pos == nil or #pos == 0 then
            return;
        end
        local index = pos[1];
        local manorInfo = ManorModule.LoadManorInfo();	
        local unlock_cfg = ManorModule.GetManorOpenConfig(manorInfo[index].line);
        local state = info:GetLineState(manorInfo[index].line)
        if state then
            if index == 1 then
                if IsSelfManor then
                    if teleport then
                        DispatchEvent("Player_Teleport",function ()
                            DialogStack.Push("manor/Manor_Tavern_View",{index = index, callback = callback});
                        end)
                    else
                        DialogStack.Push("manor/Manor_Tavern_View",{index = index, callback = callback});
                    end
                else
                    showDlgError(nil, "只有基地主人才能进入")
                    if callback then
                        callback();
                    end
                end
                
            -- elseif index == 2 then
            --     if teleport then
            --         DispatchEvent("Player_Teleport",function ()
            --             DialogStack.Push("Manor_Store_Dialog",{index = index, callback = callback});
            --         end)
            --     else
            --         DialogStack.Push("Manor_Store_Dialog",{index = index, callback = callback});
            --     end
            -- elseif index >= 2 and index <= 3 then
            --     if teleport then
            --         DispatchEvent("Player_Teleport",function ()
            --             DialogStack.Push("Manor_WorkStation_Dialog",{index = index, callback = callback});
            --         end)
            --     else
            --         DialogStack.Push("Manor_WorkStation_Dialog",{index = index, callback = callback});
            --     end
            elseif index >= 2 and index <= 5 then
                if teleport then
                    DispatchEvent("Player_Teleport",function ()
                        DialogStack.Push("Manor_Mine_Dialog",{index = index, callback = callback});
                    end)
                else
                    DialogStack.Push("Manor_Mine_Dialog",{index = index, callback = callback});
                end
            end
        else
            if IsSelfManor then
                if HeroModule.GetManager():Get(11000).level < unlock_cfg.open_level then
                    showDlgError(nil, "等级达到"..unlock_cfg.open_level.."级后才能解锁")
                else
                    -- showDlgError(nil, "请到基地总览处解锁")
                    DialogStack.Push("Manor_Overview",{interval = index, callback = callback});
                end
            else
                showDlgError(nil, "该建筑未解锁")
            end
            callback();
        end
    elseif id and id ~= 0 then
        for k,v in pairs(info.product_list) do
            for i,j in pairs(v) do
                if (j.reward[1] and j.reward[1].id == id) or (j.reward[2] and j.reward[2].id == id) or (j.reward[3] and j.reward[3].id == id) or (j.depend_item and j.depend_item == id) then
                    local product_id = id;
                    if j.depend_item == id then
                        product_id = j.reward[1].id;
                    end
                    local state = info:GetLineState(j.line);
                    local unlock_cfg = ManorModule.GetManorOpenConfig(j.line);
                    if state then
                        if j.line > 1 and j.line <= 3 then
                            DialogStack.Push("Manor_WorkStation_Production",{line = j.line, product_id = product_id, callback = callback});
                        elseif j.line > 3 and j.line <= 10 then
                            local manorInfo = ManorModule.LoadManorInfo(j.line, 2);	
                            DialogStack.Push("Manor_Mine_Dialog",{index = manorInfo.location, callback = callback});
                        end
                    else
                        if HeroModule.GetManager():Get(11000).level < unlock_cfg.open_level then
                            showDlgError(nil, "等级达到"..unlock_cfg.open_level.."级后才能解锁")
                        else
                            showDlgError(nil, "请到基地总览处解锁")
                        end
                        callback();
                    end
                end
            end
        end
    end
end

local manor_property_change = {};
local function GetPropChange()
    return manor_property_change;
end

local function CleanPropChange()
    manor_property_change = {};
end

local function SetInManorScene(tip, pid)
    pid = pid or playerModule.GetSelfID();
    if tip then
        CheckWorkerOutsideState();
        GetVisitorManager():CheckVisitorState();
    else
        QUEST_NPC = {};
        taskTeamInfo = {};
    end
    InManorScene = tip;
    IsSelfManor = pid == playerModule.GetSelfID();
    ManorOwner = pid;
    CalDinnerTimeFinish = false;
    DispatchEvent("MANOR_SCENE_CHANGE", tip, pid)
end

local function SetPauseActive(status)
    PauseActive = status;
end

local function GetDinnerState()
    return CalDinnerTimeFinish;
end

local function GetInManorScene()
    local inscene = InManorScene
    return inscene;
end

local function CheckOthersProductlineState(pid)
    local info = GetManufactureInfo(pid);
    local cfg = ManorModule.LoadManorInfo(nil, 1)
    for i,v in pairs(cfg) do
        if v.line ~= 0 then
            info:QueryLineState(v.line)
        end
    end
end

local function CheckThiefOwner(line)
    local _,owner = GetManorStatus();
    local info = GetManufactureInfo(owner);
    if info.product_line[line] and info.product_line[line].thieves[1] and info.product_line[line].thieves[1].thief_id == playerModule.GetSelfID() then
        return true;
    end
    return false;
end

local cfg_product_list = {};

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_QUERY_PRODUCT_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    -- print("@@@生产列表返回", sprinttb(data));
    if result ~= 0 then
        print("query manor manufacture product list failed",result)
        return; 
    end
    
    local info = GetManufactureInfo(Sn2Data[sn]);
    info.product_list = {};
    for _, v in ipairs(data[3] or {}) do
        local gid = v[1];
        local line = v[2];
        --print(line.."号线列表",sprinttb(v))
        local product = {
            gid = gid,
            line = line,
            time = {min = v[3], max = v[4]},
            count = {min = v[5], max = v[6]}, 
            depend_item = v[7],
            type = v[10],
            consume = {},
            reward = {},
            material_type = v[11],
            show_type = v[12],
            discount = v[13],
            begin_time = v[14],
            end_time = v[15],
            level_limit = v[16],
            product_pool1 = v[17],
            product_pool2 = v[18]
        }

        for _, cv in ipairs(v[8] or {}) do
            if cv[3] ~= 0 then
                table.insert(product.consume, {type=cv[1],id=cv[2],value=cv[3]});
            end
        end

        for _, rv in ipairs(v[9] or {}) do
            table.insert(product.reward, {type=rv[1],id=rv[2],value=rv[3]});  
        end
        cfg_product_list[gid] = product;
        info.product_list[line] = info.product_list[line] or {}
        info.product_list[line][gid] = product;
    end

    prepare_list = true;

    if login_order then
        SendLoginOrder();
    end
    EventManager.getInstance():dispatch("MANOR_MANUFACTURE_PRODUCT_LIST_CHANGE")
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_QUERY_PRODUCT_LINE_RESPOND, function(event, cmd, data)
    -- [sn, result, [[line,gid,speed,gather_time], ...]]
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("query manor manufacture product line failed",result)
        return; 
    end
    -- print("<color=red>@@@@@@@@@@@@生产线</color>",Sn2Data[sn], sprinttb(data));
    local info = GetManufactureInfo(Sn2Data[sn] and Sn2Data[sn].pid);
    info.product_line = {};

    for _, v in ipairs(data[3]) do
        info:UpdateProductLineFromServerData(v);
    end
    info:updateWorkerState(true);

    if IsSelfManor then
        prepare_line = true;
    
        if login_order then
            SendLoginOrder();
        end
    end
    if Sn2Data[sn] and Sn2Data[sn].co then
        coroutine.resume(Sn2Data[sn].co);
    end
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE", {pid = Sn2Data[sn] and Sn2Data[sn].pid})
    Sn2Data[sn] = nil;
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_PRODUCT_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("manor manufacture start product failed",result)
        DispatchEvent("MANOR_STORE_STALL_FAILED");
        return; 
    end

    local info = GetManufactureInfo();
    info:UpdateProductLineFromServerData(data[3]);
    
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE", {type = 1})
    DispatchEvent("MANOR_STORE_STALL_SUCCESS");
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_GATHER_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("manor manufacture gather failed")
        return; 
    end

    print("收获结果",sprinttb(data))
    local info = GetManufactureInfo();

    info:UpdateProductLineFromServerData(data[3]);

    if data[3][1] > 10 and  data[3][1] < 20 then
        info:SendMineOrder(data[3][1]);
    end
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE")

    for _, v in ipairs(data[4] or {}) do
        print(table.unpack(v));
    end

    -- local manor_store_data = UserDefault.Load("manor_store_data", true);
    -- if data[4][1] and data[4][1][2] == 90002 and data[3][1] == 31 then
    --     if manor_store_data.lastday ~= nil and manor_store_data.lastday == Time.day()then
    --         manor_store_data.today_reward =  manor_store_data.today_reward + data[4][1][3];
    --     else
    --         manor_store_data.lastday = Time.day();
    --         manor_store_data.today_reward = data[4][1][3];
    --     end
    -- end

    DispatchEvent("MANOR_MANUFACTURE_GATHER_SUCCESS",{line = data[3][1], reward = data[4]});
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_SPEEDUP_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("manor manufacture speedup failed")
        DispatchEvent("MANOR_MANUFACTURE_SPEEDUP_FAILED")
        return;
    end

    local info = GetManufactureInfo();
    info:UpdateProductLineFromServerData(data[3]);
    DispatchEvent("MANOR_MANUFACTURE_SPEEDUP_SUCCESS")
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE")
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_SPEEDUP_BY_WORKMAN_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("manor manufacture speedup by worker failed")
        return;
    end
    print("加速成功")
    local info = GetManufactureInfo();
    info:UpdateProductLineFromServerData(data[3]);
    if Sn2Data[sn] and Sn2Data[sn].uuid then
        if info.worker[Sn2Data[sn].uuid] then
            info.worker[Sn2Data[sn].uuid].power = info.worker[Sn2Data[sn].uuid].power - 50;
        end
        info:QueryWorkerInfo(Sn2Data[sn].uuid)
    end
    DispatchEvent("MANOR_MANUFACTURE_SPEEDUPBYWORKER_SUCCESS")
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE")
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_SPEEDUP_BY_ITEM_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("manor manufacture speedup by item failed")
        return;
    end
    print("加速成功")
    local info = GetManufactureInfo();
    info:UpdateProductLineFromServerData(data[3]);
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE")
    DispatchEvent("MANOR_MANUFACTURE_SPEEDUPBYITEM_SUCCESS")
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_CANCEL_ORDER_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("manor manufacture cancel order failed")
        return;
    end
    print("取消成功", sprinttb(data))
    local info = GetManufactureInfo();
    info:UpdateProductLineFromServerData(data[3]);
    DispatchEvent("MANOR_MANUFACTURE_CANCEL_SUCCESS")
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE")
end)


ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_ADDWORKER_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("工人上岗返回",sprinttb(data));
    if result ~= 0 then
        print("manor manufacture add worker failed",result)
        return; 
    end

    local info = GetManufactureInfo();
    for _, v in ipairs(data[3]) do
        info:UpdateProductLineFromServerData(v);
    end
    if Sn2Data[sn].line > 10 and Sn2Data[sn].line < 20 then
       info:SendMineOrder(Sn2Data[sn].line);
    end
    
    if Sn2Data[sn].select then
        info:QueryWorkerInfo(Sn2Data[sn].select);
    end
    info:updateWorkerState(true);
    DispatchEvent("MANOR_MANUFACTURE_WORKER_CHANGE",{select = Sn2Data[sn].select, id = Sn2Data[sn].id})
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_QUERY_WORKMAN_INFO_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("查询属性失败",--[[ HeroModule.GetManager(Sn2Data[sn].pid):GetByUuid(Sn2Data[sn].uuid).name, ]]Sn2Data[sn].uuid, result,sprinttb(data))
        return;
    end

    -- print("查询属性返回",Sn2Data[sn].uuid, HeroModule.GetManager(Sn2Data[sn].pid):GetByUuid(Sn2Data[sn].uuid).name, sprinttb(data))
    local info = GetManufactureInfo(Sn2Data[sn].pid);

    info:updateWorkerInfo(Sn2Data[sn].uuid,data)
    if Sn2Data[sn] and Sn2Data[sn].isCheck then
        QueryWorkerCount = QueryWorkerCount + 1;
        if QueryWorkerCount == 0 then
            CheckWorkerFinish = true;
            DispatchEvent("MANOR_MANUFACTURE_CHECK_WORKER_INFO_SUCCESS")
        end
    else
        DispatchEvent("MANOR_MANUFACTURE_WORKER_INFO_CHANGE", {uuid = Sn2Data[sn].uuid})
    end
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_INCREASE_POWER_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("添加活力失败", result)
        return;
    end
    local info = GetManufactureInfo();
    info:QueryWorkerInfo(Sn2Data[sn].uuid)
    DispatchEvent("MANOR_MANUFACTURE_EAT_FOOD", {food_id = Sn2Data[sn].food_id})
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_FIGHT_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("请求战斗失败", result)
        return;
    end
    local fight_id = data[3];
    local fight_data = data[4];
    print("~~~战斗数据", sprinttb(data));


    local fightInfo = ManorModule.GetManorFightAdd(1, Sn2Data[sn].property_id, Sn2Data[sn].condition);
    local info = GetManufactureInfo();
    local uuid = Sn2Data[sn].uuid;
    SceneStack.Push('battle', 'view/battle.lua', { fight_id = fight_id, fight_data = fight_data, callback = function(win, heros)
        local result = 0
        if win then
            result = 1;
        end
        cur_fight_info.result = result;
        cur_fight_info.uuid = uuid;
        cur_fight_info.property = fightInfo.property;
        cur_fight_info.add_property = fightInfo.add_property;
        cur_fight_info.value = info.worker[uuid].prop[fightInfo.property];
        --print("副本测试",sprinttb(cur_fight_info))

        local prefab = SGK.ResourcesManager.Load("prefabs/base/Manor_Fight_Result.prefab");
        local obj = UnityEngine.Object.Instantiate(prefab);
        -- obj.transform:SetParent(panel.gameObject.transform,false);

        EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", result);
        EventManager.getInstance():dispatch("ADD_OBJECT_TO_FIGHT_RESULT", obj);
        if win then
            info:FightCheck(uuid, fightInfo.property, fightInfo.condition, fightInfo.fight_id, fightInfo.add_property);
            return true;
        end
    end } );

    DispatchEvent("MANOR_MANUFACTURE_WORKER_FIGHT_INFO", {fight_id = fight_id, fight_data = fight_data});
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_FIGHT_RESULT_CHECK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("战斗确认失败", result)
        return;
    end
    local info = GetManufactureInfo();
    info:QueryWorkerInfo(Sn2Data[sn].uuid);
    table.insert(manor_property_change, Sn2Data[sn])
end)

ON_SERVER_RESPOND(C_MANOR_QUERY_TASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("查询任务失败", result)
        return;
    end
    print("查询任务列表", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    DispatchEvent("MANOR_TASK_INFO_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_CHANGE_TASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("刷新任务失败", result)
        if result == 3 then
            DispatchEvent("MANOR_TASK_EMPTY");
        end     
        return;
    end
    -- print("刷新任务", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    DispatchEvent("MANOR_TASK_INFO_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_DISPATCH_TASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("任务派遣失败", result)
        return;
    end

    print("任务派遣", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    if Sn2Data[sn] and Sn2Data[sn].staff then
        for i,v in ipairs(Sn2Data[sn].staff) do
            info:QueryWorkerInfo(v);
        end
    end
    info:updateWorkerState(false);

    local task = info:GetTask(Sn2Data[sn].gid);
    -- local taskinfo = {};
    -- taskinfo.enter = false;
    -- taskinfo.enter_time = 0;
    -- taskinfo.out_time = 0;
    -- taskinfo.moving = false;
    -- taskinfo.staff = task.staff;
    -- taskinfo.gid = task.gid;
    -- taskTeamInfo[task.gid] = taskinfo;

    for i,v in ipairs(task.staff) do
        if info.worker_event[v] then
            if info.worker_event[v].where > 100 then
                RemoveFromWaitList(v);
            else
                DispatchEvent("MANOR_REMOVE_NPC", {id = v})
            end
            info.worker_event[v].where = -1;
            info.worker_event[v].outside = false;
            info.worker_event[v].moving = false;
            info.worker_event[v].goOutsideTime = 0;
            info.worker_event[v].goBackTime = 0;
            info.worker_event[v].togo = 0;
            info.worker_event[v].pos = 0;
        end
    end

    DispatchEvent("MANOR_TASK_INFO_CHANGE");
    DispatchEvent("MANOR_DISPATCH_TASK_SUCCEED", Sn2Data[sn]);
end)

ON_SERVER_RESPOND(C_MANOR_REWARD_TASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("完成任务失败", result)
        if result == 3 then
            DispatchEvent("MANOR_TASK_EMPTY");
        end     
        return;
    end
    print("完成任务", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    info:GetStarBoxInfoFromServer();
    DispatchEvent("MANOR_SHOW_REWARD", {gid = Sn2Data[sn].gid, reward = data[6]});--data[7] 特殊奖励
    if Sn2Data[sn] and Sn2Data[sn].staff then
        for i,v in ipairs(Sn2Data[sn].staff) do
            info:QueryWorkerInfo(v);
        end
    end
    info:updateWorkerState(true);

    DispatchEvent("MANOR_TASK_INFO_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_CANCEL_TASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("取消任务失败", result)    
        return;
    end
    print("取消任务", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    if Sn2Data[sn] and Sn2Data[sn].staff then
        for i,v in ipairs(Sn2Data[sn].staff) do
            info:QueryWorkerInfo(v);
        end
    end
    info:updateWorkerState(true);
    DispatchEvent("MANOR_TASK_INFO_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_FINISH_TASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("快速完成任务失败", result)    
        DispatchEvent("MANOR_FINISH_TASK_FAILED", result);
        return;
    end
    print("快速完成任务", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    info:GetStarBoxInfoFromServer();
    if Sn2Data[sn] and Sn2Data[sn].staff then
        for i,v in ipairs(Sn2Data[sn].staff) do
            info:QueryWorkerInfo(v);
        end
    end
    info:updateWorkerState(true);
    DispatchEvent("MANOR_TASK_INFO_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_STAR_REWARD_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("领取宝箱失败", result)    
        return;
    end
    print("领取宝箱返回", sprinttb(data))    
    local info = GetManufactureInfo();
    info:updateStarBoxState(data);
    DispatchEvent("MANOR_TASK_STARBOX_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_STAR_REWARD_INFO_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("查询宝箱信息失败", result)    
        return;
    end
    print("宝箱信息", sprinttb(data))    
    local info = GetManufactureInfo();
    info:updateStarBoxState(data);
    DispatchEvent("MANOR_TASK_STARBOX_CHANGE");
end)

ON_SERVER_RESPOND(C_MANOR_REFRESH_ALLTASK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("刷新任务失败", result)    
        return;
    end
    print("刷新任务", sprinttb(data))
    local info = GetManufactureInfo();
    info:updateTaskList(data);
    DispatchEvent("MANOR_TASK_INFO_CHANGE");
    DispatchEvent("MANOR_REFRESH_ALLTASK_SUCCESS");
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_INCREASE_LINE_STORAGE_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("提高上限失败", result)  
        return;
    end
    local info = GetManufactureInfo();
    if Sn2Data[sn] then
        info.product_line[Sn2Data[sn].line].storge_pool = info.product_line[Sn2Data[sn].line].storge_pool + Sn2Data[sn].add_storage;
        DispatchEvent("MANOR_INCREASE_LINE_STORAGE", info.product_line[Sn2Data[sn].line].storge_pool);
    end
    info:GetProductLineFromServer();
end)


ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_INCREASE_LINE_ORDER_LIMIT_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("提高订单上限失败", result)  
        return;
    end
    local info = GetManufactureInfo();
    info:GetProductLineFromServer();
    DispatchEvent("MANOR_INCREASE_LINE_ORDER_LIMIT");
end)

local needCheckLine = {};

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_UNLOCK_LINE_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("解锁生产线失败", result)  
        return;
    end
    print("解锁生产线", result)  
    local info = GetManufactureInfo();
    info.line_state[Sn2Data[sn]] = true;
    if needCheckLine[Sn2Data[sn]] then
        needCheckLine[Sn2Data[sn]] = nil;
    end
    -- DispatchEvent("MANOR_LINE_STATE_CHANGE",{line = Sn2Data[sn]});
    DispatchEvent("MANOR_UNLOCK_LINE_SUCCEED",{line = Sn2Data[sn]});
end)

local check_order = {};

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_QUERY_LINE_OPEN_STATUS_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local state = data[3]
    if result ~= 0 then
        print("查询生产线状态失败", result)  
        return;
    end
    local info = GetManufactureInfo(Sn2Data[sn].pid);
    info.line_state[Sn2Data[sn].line] = (state == 1);   
    -- ERROR_LOG("查询生产线状态返回",Sn2Data[sn].pid, Sn2Data[sn].line, sprinttb(info.line_state))
    if IsSelfManor then
        if state ~= 1 then
            local unlock_cfg = ManorModule.GetManorOpenConfig(Sn2Data[sn].line);
            if unlock_cfg.consume_id1 == 0 and unlock_cfg.consume_id2 == 0 and unlock_cfg.consume_id3 == 0 then
                if HeroModule.GetManager():Get(11000).level >= unlock_cfg.open_level then
                    info:UnlockLine(Sn2Data[sn].line);
                    return;
                end
                needCheckLine[Sn2Data[sn].line] = true;
            end
        elseif needCheckLine[Sn2Data[sn].line] then
            needCheckLine[Sn2Data[sn].line] = nil;
        end
        if state == 1 and ManorLineVisitor[Sn2Data[sn].line] == nil then
            ManorLineVisitor[Sn2Data[sn].line] = 0;
        end
        
        if Sn2Data[sn].line and Sn2Data[sn].line > 10 and Sn2Data[sn].line < 20 and state == 1 then
            if check_order[Sn2Data[sn].line] == nil or not check_order[Sn2Data[sn].line] then
                check_order[Sn2Data[sn].line] = true;
                info:SendMineOrder(Sn2Data[sn].line);
            end
        end
    end 

    DispatchEvent("MANOR_LINE_STATE_CHANGE", {line = Sn2Data[sn].line, pid = Sn2Data[sn].pid});
end)

ON_SERVER_RESPOND(C_MANOR_EVENT_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local time = data[3];
    if result ~= 0 then
        return;
    end
    --print("触发间隔", time);
end)

ON_SERVER_RESPOND(C_MANOR_ACCEPT_QUEST_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local quest_id = data[3];
    if result ~= 0 then
        return;
    end
    -- print("领取任务", sprinttb(data));
end)

ON_SERVER_RESPOND(C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_PREPARE_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("请求战斗失败", result)
        return;
    end
    local fight_id = data[3];
    local fight_data = data[4];
    print("~~~战斗数据", sprinttb(data));

    local info = GetManufactureInfo(Sn2Data[sn].pid);
    SceneStack.Push('battle', 'view/battle.lua', { fight_id = fight_id, fight_data = fight_data, callback = function(win, heros, fightid, starInfo, input_record)
        local result = 0;
        if win then
            result = 1
        end
        info:CheckTroubleManFight(result, starInfo, input_record);
        if win then
            return true;
        end
    end})
end)

ON_SERVER_RESPOND(C_MANOR_RESET_LINE_PRODUCE_RATE_FIGHT_CHECK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result == 3 then
        showDlgError(nil, "很遗憾，捣乱者已经被其他玩家消灭了")
    end
    if result ~= 0 then
        print("确认战斗失败", result)
        return;
    end
    DispatchEvent("FIGHT_CHECK_RESULT", data[3], data[4]);
    print("确认战斗返回", sprinttb(data));
end)

ON_SERVER_RESPOND(C_MANOR_STEAL_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        return;
    end
    print("偷取成功", sprinttb(data))
    local info = GetManufactureInfo(Sn2Data[sn].pid);
    info:UpdateProductLineFromServerData(data[3]);
    DispatchEvent("MANOR_MANUFACTURE_STEAL_SUCCESS")
    DispatchEvent("MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE")
end)

ON_SERVER_RESPOND(C_MANOR_CLEAR_THIEF_FIGHT_PREPARE_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("请求战斗失败", result)
        return;
    end
    local fight_id = data[3];
    local fight_data = data[4];
    print("~~~战斗数据", sprinttb(data));

    local info = GetManufactureInfo(Sn2Data[sn].pid);
    SceneStack.Push('battle', 'view/battle.lua', { fight_id = fight_id, fight_data = fight_data, callback = function(win, heros, fightid, starInfo, input_record)
        local result = 0;
        if win then
            result = 1
        end
        info:ThiefFightCheck(result, starInfo, input_record);
        if win then
            return true;
        end
    end})
end)

ON_SERVER_RESPOND(C_MANOR_CLEAR_THIEF_FIGHT_CHECK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result == 3 then
        showDlgError(nil, "很遗憾，小偷已经被其他玩家消灭了")
    end
    if result ~= 0 then
        print("确认战斗失败", result)
        return;
    end
    DispatchEvent("FIGHT_CHECK_RESULT", data[3], data[4]);
    print("确认战斗返回", sprinttb(data));
end)

ON_SERVER_RESPOND(C_MANOR_MANUFACTURE_LEVELUP_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("升级失败", result)
        return;
    end
    local info = GetManufactureInfo();
    if Sn2Data[sn] then
        if Sn2Data[sn].line > 10 and Sn2Data[sn].line < 20 then
            info.product_line[Sn2Data[sn].line].level = Sn2Data[sn].level;
            info:SendMineOrder(Sn2Data[sn].line);
        end
    end
    info:GetProductLineFromServer();
    DispatchEvent("MANOR_LEVELUP_SUCCESS");
end)


ON_SERVER_RESPOND(C_MANOR_QUERY_LOG_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        return;
    end
    -- print("日志返回", sprinttb(data[3]))
    local log_tab = {};
    for i,v in ipairs(data[3]) do
        local log = nil;
        if v[1] == 1 then
            local gid = v[2][1];
            local discount = v[2][2];
            local begin_time = v[2][3];
            local end_time = v[2][4];
            if cfg_product_list[gid] then
                local line = cfg_product_list[gid].line; -- v[2][5] or 31;
                local info = GetManufactureInfo();
                if info.product_list[line] and info.product_list[line][gid] and Time.now() < end_time then
                    info.product_list[line][gid].discount = discount;
                    info.product_list[line][gid].begin_time = begin_time;
                    info.product_list[line][gid].end_time = end_time;
                end
                log = {type = 4,time = begin_time ,active_time = end_time - begin_time, gid = gid, line = line, discount = discount, 
                discount_type = info.product_list[line][gid].consume[1].type, discount_id = info.product_list[line][gid].consume[1].id,
                product_type = info.product_list[line][gid].reward[1].type, product_id = info.product_list[line][gid].reward[1].id, product_value = info.product_list[line][gid].reward[1].value}
            end
        elseif v[1] == 2 then
            local event_time = v[2][1][5];
            if event_time then
                log = {type = 3, time = event_time, event_list = v[2]};
            end          
        elseif v[1] == 3 then
            local uuid = v[2][1];
            local event_id = v[2][2];
            local leave_time = v[2][3];
            local back_time = v[2][4];
            log = {type = 1, uuid = uuid, event_id = event_id, back_time = back_time, leave_time = leave_time, time = leave_time};
        elseif v[1] == 4 then
            local uuid = v[2][1];
            local event_id = v[2][2];
            local leave_time = v[2][3];
            local back_time = v[2][4];
            local reward = v[2][5];
            local power = v[2][6];
            log = {type = 2, uuid = uuid, event_id = event_id, reward = reward, power = power, time = back_time};
        elseif v[1] == 5 then
            local line = v[2][1];
            local gid = v[2][2];
            local reward = v[2][3];
            local time = v[2][4];
            local product = {};
            local info = GetManufactureInfo();
            if line == 31 then
                if info.product_list[line] and info.product_list[line][gid] then
                    table.insert(product, info.product_list[line][gid].consume[1])
                end
                log = {type = v[1], line = line, product = product, reward = reward, time = time}
            end
        elseif v[1] == 6 then
            local workman =  v[2][1];
            local conflict_line =  v[2][2];--原来呆的生产线
            local line =  v[2][3];
            local primary_man =  v[2][4];--位置上原来的人
            local time =  v[2][5];
            log = {type = v[1], workman = workman, conflict_line = conflict_line, line = line, primary_man = primary_man, time = time}
        elseif v[1] == 8 then
            -- print("日志内容", v[1], sprinttb(v))
            local line = v[2][1];
            local time = v[2][2];
            local effect_percent = v[2][3];
            local cfg_id = v[2][4];
            log = {type = v[1], line = line, time = time, effect_percent = effect_percent, cfg_id = cfg_id}
        elseif v[1] == 11 then
            local line = v[2][1];
            local time = v[2][2];
            local opt_id = v[2][3];
            log = {type = v[1], line = line, time = time, opt_id = opt_id}
        elseif v[1] == 12 then
            local line = v[2][1];
            local time = v[2][2];
            local thief = v[2][3];
            local item = v[2][4];
            log = {type = v[1], line = line, time = time, thief = thief, item = item}
        elseif v[1] == 13 then
            local line = v[2][1];
            local time = v[2][2];
            local thief = v[2][3];
            local opt_id = v[2][4];
            log = {type = v[1], line = line, time = time, thief = thief, opt_id = opt_id}
        elseif v[1] == 20 then
            local line = v[2][1];
            local time = v[2][2];
            local add_time = v[2][3];
            local reduce_time = v[2][4];
            local lazy_heros = v[2][5];
            local hardworking_heros = v[2][6];
            log = {type = v[1], line = line, time = time, add_time = add_time, reduce_time = reduce_time, lazy_heros = lazy_heros, hardworking_heros = hardworking_heros}
        end
        if log then
            table.insert(log_tab, log);
        end
    end
    
    table.sort(log_tab,function ( a,b )
        return a.time < b.time;
    end)
    for i,v in ipairs(log_tab) do
        local msg = false;
        if i == #log_tab then
            msg = true;
        end
        ManorModule.SetLogDes(v,msg);
    end
    
end)

-- local NOTIFY_MANOR_HERO_LEAVE_TAVERN = 1129 --英雄离开酒馆通知
-- local NOTIFY_MANOR_HERO_BACK_TAVERN = 1130 --英雄返回酒馆通知
-- local NOTIFY_MANOR_LUCKY_EVENT = 1131 --触发幸运事件通知
-- local NOTIFY_MANOR_POPULAR_EVENT = 1132 --触发流行事件通知
ON_SERVER_NOTIFY(NOTIFY_MANOR_EVENT, function ( event, cmd, data ) 
    local type = data[1];  -- type 1流行事件  2幸运事件 3离开酒馆 4返回酒馆 5收获订单 6雇佣工人 8产生了降低产率的小人 11打败了降低产率的小人 12偷东西事件 13赶走小偷 20偷懒或勤奋时间
    local event = data[2];
    if type == 1 then
        local gid = event[1];
        local discount = event[2];
        local begin_time = event[3];
        local end_time = event[4];
        local line = event[5] or 31;

        --showDlgError(nil, "触发流行事件");

        local info = GetManufactureInfo();
        if info.product_list[line] and info.product_list[line][gid] then
            info.product_list[line][gid].discount = discount;
            info.product_list[line][gid].begin_time = begin_time;
            info.product_list[line][gid].end_time = end_time;
            DispatchEvent("MANOR_ADD_LOG", {type = 4,time = begin_time,active_time = end_time - begin_time, gid = gid, line = line, discount = discount, 
            discount_type = info.product_list[line][gid].consume[1].type, discount_id = info.product_list[line][gid].consume[1].id,
            product_type = info.product_list[line][gid].reward[1].type, product_id = info.product_list[line][gid].reward[1].id, product_value = info.product_list[line][gid].reward[1].value})
        end
        DispatchEvent("MANOR_POPULAR_EVENT", {gid = gid, discount = discount, begin_time = begin_time, end_time = end_time});
    elseif type == 2 then
        local event_list = event;
        -- local item_type = event[1][2];
        -- local item_id = event[1][3];
        -- local item_value = event[1][4];
        local event_time = event[1][5];

        --showDlgError(nil, "触发幸运事件");
        -- print("触发幸运事件", sprinttb(event))
        DispatchEvent("MANOR_ADD_LOG", {type = 3, time = event_time, event_list = event_list})
        DispatchEvent("MANOR_LUCKY_EVENT", {event_list = event_list});
    elseif type == 3 then
        local uuid = event[1];
        local event_id = event[2];
        local leave_time = event[3];
        local back_time = event[4];
        --showDlgError(nil, uuid.."触发英雄离开酒馆");
        -- print("触发英雄离开酒馆", sprinttb(event))
        local info = GetManufactureInfo();
        if info.worker[uuid] then
            info.worker[uuid].event = 1;
            info.worker[uuid].leave_time = leave_time;
            info.worker[uuid].back_time = back_time;
        end
        --info:QueryWorkerInfo(uuid);
        DispatchEvent("MANOR_ADD_LOG", {type = 1, uuid = uuid, event_id = event_id, back_time = back_time, leave_time = leave_time, time = leave_time})
        DispatchEvent("MANOR_HERO_LEAVE_TAVERN", {uuid = uuid, event_id = event_id})
    elseif type == 4 then
        local uuid = event[1];
        local event_id = event[2];
        local leave_time = event[3];
        local back_time = event[4];
        local reward = event[5];
        local power = event[6];
        --showDlgError(nil, uuid.."触发英雄返回酒馆");
        -- print("触发英雄返回酒馆", sprinttb(event))
          local info = GetManufactureInfo();
        if info.worker[uuid] then
            info.worker[uuid].event = 0;
            info.worker[uuid].leave_time = 0;
            info.worker[uuid].back_time = 0;
            info.worker[uuid].power = power;
        end
        DispatchEvent("MANOR_ADD_LOG", {type = 2, uuid = uuid, event_id = event_id, reward = reward, power = power, time = back_time})
        DispatchEvent("MANOR_HERO_BACK_TAVERN", {uuid = uuid, event_id = event_id, reward = reward, power = power})
    elseif type == 5 then
        local line = event[1];
        local gid = event[2];
        local reward = event[3];
        local time = event[4];
        -- print("收获订单",sprinttb(event),sprinttb(data));
        local product = {};
        local info = GetManufactureInfo();
        if line == 31 then
            if info.product_list[line] and info.product_list[line][gid] then
                table.insert(product, info.product_list[line][gid].consume[1])
            end
            DispatchEvent("MANOR_ADD_LOG", {type = type, line = line, product = product, reward = reward, time = time})
        end
    elseif type == 6 then
        local workman = event[1];
        local conflict_line = event[2];--原来呆的生产线
        local line = event[3];
        local primary_man = event[4];--位置上原来的人
        local time = event[5];

        -- print("雇佣工人",sprinttb(event));
        DispatchEvent("MANOR_ADD_LOG", {type = type, workman = workman, conflict_line = conflict_line, line = line, primary_man = primary_man, time = time})
    elseif type == 8 then
        local line = event[1];
        local time = event[2];
        local effect_percent = event[3];
        local cfg_id = event[4];
        DispatchEvent("MANOR_ADD_LOG", {type = type, line = line, time = time, effect_percent = effect_percent, cfg_id = cfg_id});
    elseif type == 11 then
        local line = event[1];
        local time = event[2];
        local opt_id = event[3];
        DispatchEvent("MANOR_ADD_LOG", {type = type, line = line, time = time, opt_id = opt_id});
    elseif type == 12 then
        local line = event[1];
        local time = event[2];
        local thief = event[3];
        local item = event[4];
        DispatchEvent("MANOR_ADD_LOG", {type = type, line = line, time = time, thief = thief, item = item});
    elseif type == 13 then
        local line = event[1];
        local time = event[2];
        local thief = event[3];
        local opt_id = event[4];
        DispatchEvent("MANOR_ADD_LOG", {type = type, line = line, time = time, thief = thief, opt_id = opt_id});
    elseif type == 20 then
        local line = event[1];
        local time = event[2];
        local add_time = event[3];
        local reduce_time = event[4];
        local lazy_heros = event[5];
        local hardworking_heros = event[6];
        DispatchEvent("MANOR_ADD_LOG", {type = type, line = line, time = time, add_time = add_time, reduce_time = reduce_time, lazy_heros = lazy_heros, hardworking_heros = hardworking_heros});
    end
end)


-- ON_SERVER_NOTIFY(NOTIFY_MANOR_HERO_LEAVE_TAVERN, function ( event, cmd, data )
--     local uuid = data[1];
--     local event_id = data[2];
--     local leave_time = data[3];
--     local back_time = data[4];
--     --showDlgError(nil, uuid.."触发英雄离开酒馆");
--     print("触发英雄离开酒馆", sprinttb(data))
--     local info = GetManufactureInfo();
--     if info.worker[uuid] then
--         info.worker[uuid].event = 1;
--         info.worker[uuid].leave_time = leave_time;
--         info.worker[uuid].back_time = back_time;
--     end
--     --info:QueryWorkerInfo(uuid);
--     DispatchEvent("MANOR_ADD_LOG", {type = 1, uuid = uuid, event_id = event_id, back_time = back_time, leave_time = leave_time})
    
--     DispatchEvent("MANOR_HERO_LEAVE_TAVERN", {uuid = uuid, event_id = event_id})
-- end)

-- ON_SERVER_NOTIFY(NOTIFY_MANOR_HERO_BACK_TAVERN, function ( event, cmd, data )
--     local uuid = data[1];
--     local event_id = data[2];
--     local reward = data[5];
--     local power = data[6];
--     --showDlgError(nil, uuid.."触发英雄返回酒馆");
--     print("触发英雄返回酒馆", sprinttb(data))
--       local info = GetManufactureInfo();
--     if info.worker[uuid] then
--         info.worker[uuid].event = 0;
--         info.worker[uuid].leave_time = 0;
--         info.worker[uuid].back_time = 0;
--         info.worker[uuid].power = power;
--     end
--     -- local info = GetManufactureInfo();
--     -- info:QueryWorkerInfo(uuid);
--     DispatchEvent("MANOR_ADD_LOG", {type = 2, uuid = uuid, event_id = event_id, reward = reward, power = power})
--     DispatchEvent("MANOR_HERO_BACK_TAVERN", {uuid = uuid, event_id = event_id, reward = reward, power = power})
-- end)

-- ON_SERVER_NOTIFY(NOTIFY_MANOR_LUCKY_EVENT, function ( event, cmd, data )
--     local event_list = data[1];
--     local item_type = data[2];
--     local item_id = data[3];
--     local item_value = data[4];

--     showDlgError(nil, "触发幸运事件");
--     print("触发幸运事件", sprinttb(data))
--     DispatchEvent("MANOR_ADD_LOG", {type = 3, event_list = data})
--     DispatchEvent("MANOR_LUCKY_EVENT", {event_list = event_list});
-- end)

-- ON_SERVER_NOTIFY(NOTIFY_MANOR_POPULAR_EVENT, function ( event, cmd, data )
--     local gid = data[1];
--     local discount = data[2];
--     local begin_time = data[3];
--     local end_time = data[4];
--     local line = data[5] or 31;

--     showDlgError(nil, "触发流行事件");
--     print("触发流行事件", sprinttb(data))

--     local info = GetManufactureInfo();
--     if info.product_list[line] and info.product_list[line][gid] then
--         info.product_list[line][gid].discount = discount;
--         info.product_list[line][gid].begin_time = begin_time;
--         info.product_list[line][gid].end_time = end_time;
--         DispatchEvent("MANOR_ADD_LOG", {type = 4, line = line, discount = discount, discount_type = info.product_list[line][gid].consume[1].type, discount_id = info.product_list[line][gid].consume[1].id})
--     end

--     DispatchEvent("MANOR_POPULAR_EVENT", {gid = gid, discount = discount, begin_time = begin_time, end_time = end_time});
-- end)

EventManager.getInstance():addListener("WORKER_INFO_CHANGE", function (event, data)
    if InManorScene then
        local info = GetManufactureInfo();
        info:QueryWorkerInfo(data.uuid, 1);
    end   
end);

EventManager.getInstance():addListener("PLAYER_LEVEL_UP", function (event, data)
    for k,v in pairs(needCheckLine) do
        local unlock_cfg = ManorModule.GetManorOpenConfig(k);
        if data >= unlock_cfg.open_level then
            local info = GetManufactureInfo();
            info:UnlockLine(k);
        end
    end  
    if data >= openLevel.GetCfg(2001).open_lev and needInit then
        needInit = false;
        ManorInit();
    end
end);

--[[
EventManager.getInstance():addListener("QUEST_INFO_CHANGE", function (event, data)
    NeedScreenVisitor = true;
    local info = GetManufactureInfo();
    local refresh = false;
    for k,v in pairs(info.npc_quest) do
        local quest = module.QuestModule.Get(k);
        if quest then
            info.npc_quest[k].status = quest.status;
            refresh = true;
        end
    end
    if InManorScene and refresh then
        module.QuestModule.NotifyNpcStatusChange();
    end
end);
--]]

EventManager.getInstance():addListener("MANOR_START_THIEF_FIGHT", function (event, data)
    local _,owner = GetManorStatus();
    local line = data;
    local info = GetManufactureInfo(owner);
    if info.product_line[line] and info.product_line[line].thieves[1] then
        info:StartThiefFight(line, info.product_line[line].thieves[1].thief_id);
    end
end);

local function CanSteal(pid, productLine)
    if pid == playerModule.GetSelfID() then
        return false;
    end
    local line_cfg = ManorModule.GetManorLineConfig(productLine.idx).cfg;
    if productLine and line_cfg then
        if line_cfg.steal_item ~= 0 and module.ItemModule.GetItemCount(line_cfg.steal_item) <= 0 then
            return false
        end
        if #productLine.thieves > 0 and Time.now() < productLine.thieves[1].end_time then
            return false;
        end
        for k,v in pairs(productLine.orders) do
            for i=1,6 do
                if v["count"..i] ~= 0 then
                    if v["count"..i]/(v["count"..i] + v["stolen_value"..i]) > line_cfg.steal_guarantee/10000 then
                        if math.floor(v["count"..i] * line_cfg.every_steal / 10000) >= 1 then
                            return true;
                        end
                    end
                end
            end
            for i,j in ipairs(v.product_pool) do
                if j[3]/(j[3] + j[4]) > line_cfg.steal_guarantee/10000 then
                    if math.floor(j[3] * line_cfg.every_steal / 10000) >= 1 then
                        return true;
                    end
                end
            end
        end
    end
    return false
end

local function CheckProductlineStatus(line, pid)
    pid = pid or ManorOwner or playerModule.GetSelfID();
    local _canGather, _empty, _doing, _canSteal, _monster, _thieves = false, false, false, false, false, false;
    local info = GetManufactureInfo(pid);
    local state = info:GetLineState(line);
    if state then
        local productLine = info:GetLine(line);
        if productLine ~= nil then
            _empty = true;
            for i,v in ipairs(productLine.worker) do
                if v ~= 0 then
                    _empty = false;
                    break;
                end
            end
            _doing = productLine.next_gather_gid ~= 0;
            for k,j in pairs(productLine.orders) do
                if line > 10 and line <= 20 then
                    local allCount = 0;
                    for i=1,4 do
                        if j.product_pool[i] then
                            allCount = allCount + j.product_pool[i][3]
                        end
                    end
                    if allCount >= productLine.storge_pool then
                        _canGather = true;
                        break;
                    end
                elseif j.gather_count > 0 then
                    _canGather = true;
                    break;
                end
            end
            --检查捣乱者
            if productLine.event and productLine.event.line_produce_rate_extra_data ~= 0 and productLine.event.line_produce_rate_end_time > Time.now() then
                _monster = true;
            end
            --检查小偷
            if #productLine.thieves > 0 and Time.now() < productLine.thieves[1].end_time then
                _thieves = true;
            else--没有小偷才能偷取
                _canSteal = CanSteal(pid, productLine)
            end
        end
    end
    return _canGather, _empty, _doing, _canSteal, _monster, _thieves
end

return {
    Get = GetManufactureInfo,
    GetProductAndDependIndex = GetProductAndDependIndex,
    GetActivePoint = GetActivePoint,
    --StartQuerySchedule = StartQuerySchedule,
    -- GetItemPrice = GetItemPrice,
    CheckProduct = CheckProduct,
    ShowProductSource = ShowProductSource,
    GetPropChange = GetPropChange,
    CleanPropChange = CleanPropChange,
    GetCurFightInfo = GetCurFightInfo,
    SetInManorScene = SetInManorScene,
    GetInManorScene = GetInManorScene,
    SaveWorkerEvent = SaveWorkerEvent,
    GetDinnerState = GetDinnerState,
    GetOutsideWorker = GetOutsideWorker,
    GetTaskTeamInfo = GetTaskTeamInfo,
    SetTaskTeamInfo = SetTaskTeamInfo,
    GetVisitorManager = GetVisitorManager,
    SetPauseActive = SetPauseActive,
    GetManorStatus = GetManorStatus,
    CheckOthersProductlineState = CheckOthersProductlineState,
    CheckThiefOwner = CheckThiefOwner,
    CheckTalker = CheckTalker,
    ResetTalker = ResetTalker,
    CheckProductlineStatus = CheckProductlineStatus,
}

