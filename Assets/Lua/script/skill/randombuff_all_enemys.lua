local list = {}
for k, v in ipairs(FindAllRoles()) do
    if v.side == 2 then
        table.insert(list, {target=v})
    end
end


return list