--大回合开始前
function onRoundStart(target, buff)
    if GetFightData().fight_id == 10100803 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010080301)
    end
end