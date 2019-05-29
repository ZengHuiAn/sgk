--行动前 陆游七
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 200 --速度
        target[1301] = 0 --防御
        target[1501] = 100000 --血量
        target[1001] = 4575 --攻击
        target[1723] = 80 --能量
    end
end

--大回合开始前
function onRoundStart(target, buff)
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010041)
        sleep(0.1)
        -- PlayBattleGuide(7005)
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end

