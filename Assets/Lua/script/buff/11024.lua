--行动前 焱青
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 300 --速度
        target[1301] = 0 --防御
        target[1501] = 100000 --血量
        target[1001] = 20876 --攻击
    end
end

--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100704 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010070401)
    end
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010031)
        -- PlayBattleGuide(7003)
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end