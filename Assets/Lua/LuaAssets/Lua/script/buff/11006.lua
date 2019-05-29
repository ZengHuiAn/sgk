--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10102003 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010200301)
    end
end