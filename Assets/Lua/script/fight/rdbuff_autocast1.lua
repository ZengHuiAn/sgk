--回合结束时，场上有ai，则随机ai点击此buff球
function onRoundStart(round, wave)
    local list = game:FindAllEntityWithComponent("Player")
    for k, v in ipairs(list) do
        if v.Player.pid <= 150000 then
            RandomBuffCast(RdBuff, v.Player.pid)
            break
        end
    end
end