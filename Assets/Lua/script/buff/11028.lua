--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100504 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010050401)
    end
end