--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10101005 and GetFightData().wave == 2 and target.side == 2 then
        AddBattleDialog(1010100501)
    end
end