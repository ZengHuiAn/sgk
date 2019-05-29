--行动前 肖斯塔娅
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 600
        target[1301] = 0 --防御
        target[1501] = 100000 --血量
        target[1001] = 15200 --攻击
        target[1723] = 80 --能量
    end

    if GetFightData().fight_id == 10100202 then
        target[1211] = 600
    end
end

--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100904 and GetFightData().round == 1 and target.side == 2 then
        AddBattleDialog(1010090401)
    end
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010001)
        -- PlayBattleGuide(7001)
    end


    if GetFightData().fight_id == 10100202 then
        if GetFightData().round == 1 then
            AddBattleDialog(1010020201)
            Sleep(0.1)
            PlayBattleGuide(7031)
        end
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end