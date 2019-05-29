--行动前 马仕达
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 500
        target[1301] = 0 --防御
        target[1501] = 150000 --血量
        target[1001] = 10021 --攻击
        target[1723] = 80 --能量
    end
end

--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10101004 and GetFightData().wave == 2 and target.side == 2 then
        AddBattleDialog(1010100401)
    end
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010011)
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end