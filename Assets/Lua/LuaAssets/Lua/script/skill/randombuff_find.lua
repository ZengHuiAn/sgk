local all, all_partners, enemies = FindAllRoles()
local cfg = _Skill.cfg.property_list

local list = {}
local partners = {}
local pid = ...

if pid then
	for _, v in ipairs(all_partners) do
		if v.Force.pid == pid then
			table.insert(partners, v)
		end
	end
else
	partners = all_partners
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

if #list == 0 then
	list = all
end

local _list = {}
for _, v in ipairs(list) do
	table.insert(_list, {target = v})
end

return _list