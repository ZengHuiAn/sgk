--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10101204 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010120401)
    end

    if GetFightData().fight_id == 10102001 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010200101)
    end
end