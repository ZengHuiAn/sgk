--kong
function onTick()
    Common_UnitConsumeActPoint(attacker, 1);
    for k, v in pairs(GetDeadList()) do
        Common_Relive(attacker, v, v.hpp)
    end
end