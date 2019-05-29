local fight_achievement_list = {
    --[战斗id] = { 成就条件 = 成就id }
    [11701] = { all_alive = 18105002 },
    [10101] = { all_alive = 18105004 },
    [10201] = { all_alive = 18105006 },
	[10301] = { all_alive = 18105008 },
    [10401] = { all_alive = 18105010 },
    [10501] = { all_alive = 18105012 },
	[10601] = { all_alive = 18105014 },
    [10701] = { all_alive = 18105016 },
    [10801] = { all_alive = 18105018 },
	[10901] = { all_alive = 18105020 },
    [11001] = { all_alive = 18105022 },
    [110101] = { all_alive = 18105024 },
	[110201] = { all_alive = 18105026 },
    [110301] = { all_alive = 18105028 },
    [110401] = { all_alive = 18105030 },
	[110501] = { all_alive = 18105032 },
    [110601] = { all_alive = 18105034 },
    [110701] = { all_alive = 18105036 },
	[110801] = { all_alive = 18105038 },
	[110901] = { all_alive = 18105040 },
    [111001] = { all_alive = 18105042 },
}

local fight_events_list = {
     --[战斗id] = { 战场buff = buff id }
     [80000014] = {fight_buff_partner = 4000007},
}

local events_list_bytype = {
    --[战斗type] = { 每一波怪随机挑选一个增加一个buff = buff id }
    [1111111] = { add_buff_onRdEnemy = {1111111, 222222222, 3333333} }
}

local achievements = fight_achievement_list[__fight_id]
local fight_events = fight_events_list[__fight_id]
local events_bytype = events_list_bytype[__fight_type]

function onWaveStart()
    --每一波怪随机挑选一个增加一个buff
    if events_bytype and events_bytype.add_buff_onRdEnemy then
        local buffs = events_bytype.add_buff_onRdEnemy
        local buff_id = buffs[RAND(1, #buffs)]
        local all, all_partners, enemies = FindAllRoles()
        local target = enemies[RAND(1, #enemies)]
        Common_UnitAddBuff(target, target, buff_id)
    end
end

local local_fight_type = {
    [101] = 1,
    [102] = 2,
    [103] = 3,
    [104] = 4,
    [105] = 5,
    [106] = 6,
    [107] = 7,
}

local function GetFightTypeStr()
    local fight_type = __fight_type
    if local_fight_type[fight_type] then
        fight_type = local_fight_type[fight_type]
    end

    if fight_type < 10 then 
        fight_type = "0" .. fight_type
    end

    return tostring(fight_type)
end
local fight_type = GetFightTypeStr()

function onFightEnd(round, wave, winner)
    --全部存活
    if achievements and achievements.all_alive then
        local all_roles = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');
        local all_Players = game:FindAllEntityWithComponent('Player');

        local have_dead_list = {}
        for _, role in ipairs(all_roles) do
            if role.Force.side == 1 and not role:Alive() then
                have_dead_list[role.Force.pid] = true
            end
        end

        for _, player in ipairs(all_Players) do
            if not have_dead_list[player.Player.pid] then
                AddRecord(player.Player.pid, achievements.all_alive, "add", 1)
            end
        end
    end

    --队伍中有某个mode的角色，完成某个玩法
    if winner == 1 then
        print("___________________________________fight win")
        local all = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');
        for _, role in ipairs(all) do
            if role.Force.side == 1 then
                local num_str_1 = "17" .. fight_type .. (role.Config.mode - 10000)
                AddRecord(role.Force.pid, tonumber(num_str_1), "add", 1)        
            end
        end
    end
end

local fight_buff_list = {}
function afterAllEnter(round, wave)
    if fight_events and fight_events.fight_buff_partner then
        local buff_id = fight_events.fight_buff_partner
        local all, all_partners, enemies = FindAllRoles()
        for k, v in ipairs(all_partners) do
            if v["BuffID_".. buff_id] == 0 then
                Common_UnitAddBuff(v, v, buff_id)
            end
        end
    end
end