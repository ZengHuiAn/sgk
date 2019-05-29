common_enter(attacker)

if attacker.pos > 100 then Common_Sleep(attacker, 1) end

local temp = RAND(1, 50)/100;
Common_Sleep(attacker, temp)

if attacker.mode >= 11000 and attacker.mode <= 12000 and attacker.side ~= 1 then
    Common_FireBullet(19904, attacker, {attacker}, nil, {Type = 30})
end

UnitPlay(attacker, "ruchang", 0, {speed=1.0, duration = 2.0});

Common_Sleep(attacker, 0.4)
