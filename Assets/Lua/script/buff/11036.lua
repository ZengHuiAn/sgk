--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100404 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010040401)
    end
end