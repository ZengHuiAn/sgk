local list = {}
for k, v in ipairs(FindAllRoles()) do
    if v.Force.side == 1 then
        table.insert(list, {target=v})
    end
end

return list