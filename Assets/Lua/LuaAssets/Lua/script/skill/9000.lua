common_enter(attacker)

if attacker.mode >= 11000 and attacker.mode <= 12000 and attacker.side ~= 1 then
    local temp = RAND(1, 30)/100;
    Common_Sleep(attacker, temp)
    Common_FireWithoutAttacker(19904, {attacker}, {Type = 30})
end

UnitPlay(attacker, "idle_talk")
Common_Sleep(attacker, 0.5)
