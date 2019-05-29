--各类计数
--AddRecord(id, type, value)
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
    local fight_type = GetBattleData().fight_type
    if local_fight_type[fight_type] then
        fight_type = local_fight_type[fight_type]
    end

    if fight_type < 10 then 
        fight_type = "0" .. fight_type
    end

    return tostring(fight_type)
end

local fight_type = "00"

function onStart(target, buff)
    fight_type = GetFightTypeStr()
end

function attackerAfterHit(target, buff, bullet)
    if target.side ~= 1 then return end
    --击杀类
    if bullet.target.hp <= 0 then
        local num_str_1 = "10" .. fight_type .. (bullet.target.mode - 10000)
        AddRecord(target.Force.pid, tonumber(num_str_1), "add", 1)
        if bullet.Element > 0 then
            local num_str_2 = "1" .. bullet.Element .. fight_type .. (bullet.target.mode - 10000)
            AddRecord(target.Force.pid, tonumber(num_str_2), "add", 1)
            print("_____________________________AddRecord", num_str_2)
        end
    end
end
