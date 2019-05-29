--随机buff通用脚本
local info = ...

local cfg = _Skill.cfg.property_list
local pid = info.user_pid
local all, all_partners, enemies = FindAllRoles()
local creater = _Skill.game:GetEntity(_Skill.owner.RandomBuff.creater)
if creater then
    creater = creater:Export()
end

local function random(range, x)
	local random = pid or 99999

	if all_partners[2] then
		random = random * all_partners[2].mode - 666 * x
    end
    
    if all_partners[1] then
		random = random * all_partners[1].mode - 666 * x
	end

	if enemies[1] then
		random = random * all_partners[1].mode + 666 * x
	end

	local result = random%range + 1 

	return result
end

local function initTargets()
    local list = {}
    local partners = {}

    if pid then
        for _, v in ipairs(all_partners) do
            if v.Force.pid == pid then
                table.insert(partners, v)
            end
        end
    else
        partners = all_partners
    end
    
    if cfg[350001] then
        local count = cfg[350001]
        for i = 1,count,1 do
            if #enemies <= 0 then
                break
            end
    
            local index = random(#enemies, i)
            local role = enemies[index]
            table.insert(list, role)
            table.remove(enemies, index)
        end
    end
    
    if cfg[350002] then
        local count = cfg[350002]
        for i = 1,count,1 do
            if #partners <= 0 then
                break
            end
    
            local index = random(#partners, i)
            local role = partners[index]
            table.insert(list, role)
            table.remove(partners, index)
        end
    end
    
    if cfg[350003] then
        table.sort(enemies, function ()
            if a.hp/a.hpp ~= b.hp/b.hpp then
                return a.hp/a.hpp < b.hp/b.hpp
            end
            return a.uuid < b.uuid
        end)
        local count = cfg[350003]
        for i = 1,count,1 do
            if #enemies <= 0 then
                break
            end
    
            local role = enemies[1]
            table.insert(list, role)
            table.remove(enemies, 1)
        end
    end
    
    if cfg[350004] then
        table.sort(partners, function (a, b)
            if a.hp/a.hpp ~= b.hp/b.hpp then
                return a.hp/a.hpp < b.hp/b.hpp
            end
            return a.uuid < b.uuid
        end)
        local count = cfg[350004]
        for i = 1,count,1 do
            if #partners <= 0 then
                break
            end
    
            local role = partners[1]
            table.insert(list, role)
            table.remove(partners, 1)
        end
    end

    if cfg[350005] then
        list = {creater}
    end

    if #list == 0 then
        list = all
    end

    return list
end
------------------------------------------------------------------------------
local targets = info.choose and {info.target} or initTargets()

if info.auto_remove then
    if cfg[350070] then
        if not creater or creater.hp <= 0 then
            return
        end

        Common_FireWithoutAttacker(1100310, {creater}, {
            Hurt = creater.hpp * cfg[350070]/10000,
            Type = 20,
        })
    end

    if cfg[350110] then
        if not creater or creater.hp > 0 then
            return
        end

        Common_Relive(creater, creater, creater.hpp * cfg[350110]/10000 + 0.1)
    end
    
    return
end

if cfg[350080] then
    local have_role
    for k, v in ipairs(all_partners) do
        have_role = true
        break
    end
    
    if not have_role then 
        return 
    end

    if not creater then
        RemoveRandomBuff() 
        return
    end

    creater.focus_pid = pid
end
    
if cfg[350010] then
    local per = cfg[350011] and cfg[350011]/10000 or 1
    local round = cfg[350012] and cfg[350012]
    for _, v in ipairs(targets) do
        Common_UnitAddBuff(nil, v, cfg[350010], per, {round = round})
    end
end

if cfg[350020] then
    local ep = cfg[350020]
    for _, v in ipairs(targets) do
        Common_ChangeEp(v, ep, true)
    end
end

if cfg[350030] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            Hurt = (v.hpp - v.hp) * cfg[350030]/10000,
            Type = 20,
        })
    end
end

if cfg[350040] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            Hurt = v.hpp * cfg[350040]/10000,
            Type = 20,
        })
    end
end

if cfg[350050] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            TrueHurt = v.hp * cfg[350050]/10000,
            Type = 1,
        })
    end
end

if cfg[350060] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            TrueHurt = v.hpp * cfg[350060]/10000,
            Type = 1,
        })
    end
end

if cfg[350090] then
    Common_FireWithoutAttacker(_Skill.id, targets, {Type = 30})
    for _, v in ipairs(targets) do
        RepeatReomveBuff(v, cfg[350090], 100)
    end
end

if cfg[350100] then
    Common_FireWithoutAttacker(_Skill.id, targets, {Type = 30})
    for _, v in ipairs(targets) do
        Common_RemoveBuffRandom(v, {[3] = true, [1] = true}, cfg[350100])
    end
end

RemoveRandomBuff();