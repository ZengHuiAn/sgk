Common_UnitConsumeActPoint(attacker, 1);
local all_targets = Pet_targets()
Common_Sleep(attacker, 0.6);

FireRandomTarget(1903210, attacker, all_targets, nil, {
	Hurt = attacker.ad,
	Type = 4,
	Element = 3,
	Attacks_Total = GetPetCount(attacker),
})

Common_Sleep(attacker, 0.3)
