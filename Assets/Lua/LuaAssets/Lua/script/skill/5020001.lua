--我方所有伙伴恢复20能量
local all, partners, enemies = FindAllRoles()

if next(partners) then
    for _, v in ipairs(partners) do
        Common_ChangeEp(v, 20, true)
    end
end
RemoveRandomBuff();