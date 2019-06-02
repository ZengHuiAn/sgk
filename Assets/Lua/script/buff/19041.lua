--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100401 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010040101)
    end
end

--角色死亡
function onEnd(target, buff)
    if GetFightData().fight_id == 10100401 and target.side == 2 then
        AddBattleDialog(1010040161)
    end
end