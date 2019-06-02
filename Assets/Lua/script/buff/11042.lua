--行动前 小混混
-- function onStart(target, buff)
--     if GetFightData().fight_id == 10100100 then
--         --target[1301] = 0 --防御
--         -- target[1501] = 230 --血量
--         --target[1001] = 50 --攻击
--     end
-- end

--大回合开始前
--[[
function onRoundStart(target, buff)
    if GetFightData().fight_id == 11010101 and GetFightData().round == 1 then
        AddBattleDialog(1101010101)
    end

    if GetFightData().fight_id == 11010101 and GetFightData().round == 2 then
        AddBattleDialog(1101010111)
    end
end
]]