--行动前 阿尔
function onStart(target, buff)
    if GetFightData().fight_id == 10100103 then
        target[1211] = 200
        target[1723] = 40 --初始能量
    end
end

--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100402 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010040201)
    end
end

--角色死亡
function onEnd(target, buff)
    if GetFightData().fight_id == 10100402 and target.side == 2 then
        AddBattleDialog(1010040261)
    end
end