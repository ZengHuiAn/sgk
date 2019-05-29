--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10101700 and GetFightData().round == 1 and target.side == 2 and target.Position.pos == 33 then
        AddBattleDialog(1010170001)
    end
        
    if GetFightData().fight_id == 10101701 and GetFightData().round == 1 and target.side == 2 and target.Position.pos == 31 then
        AddBattleDialog(1010170101)
    end
end