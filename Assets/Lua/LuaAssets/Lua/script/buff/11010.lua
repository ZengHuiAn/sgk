--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10101000 and GetFightData().wave == 2 and target.side == 2 then
        AddBattleDialog(1010100001)
    end

    if GetFightData().fight_id == 10102000 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010200001)
    end
end