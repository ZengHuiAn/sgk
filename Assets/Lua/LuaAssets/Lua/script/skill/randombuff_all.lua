
local roles = FindAllRoles()

local list = {}

for _, v in ipairs(roles) do
	table.insert(list, {target = v})
end

return list