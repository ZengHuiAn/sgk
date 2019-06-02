--行动前 石心子
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 400
        target[1301] = 0 --防御
        target[1501] = 150000 --血量
        target[1001] = 22010 --攻击
        target[1723] = 80 --能量
    end
end

--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100303 and GetFightData().round == 4 and target.side == 2 then
        AddBattleDialog(1010030301)
    end

    if GetFightData().fight_id == 10101002 and GetFightData().wave == 2 and target.side == 2 then
        AddBattleDialog(1010100201)
    end
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010021)
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end