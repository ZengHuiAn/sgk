local errorinfo_list = {
    [1] = "技能还在冷却中",
    [2] = "能量不足",
    [3] = "血量不足",
    [4] = "没有目标",
    [5] = "封印状态下无法使用该技能",
    [6] = "没有阵亡队友",
    [7] = "技能释放失败",
    [8] = "只有队长可以进行此操作",
    [9] = "全员自动中，无法进行此操作",
}

function showErrorInfo(id)
    root.view.battle.Canvas.ErrorInfo:SetActive(true);
    root.view.battle.Canvas.ErrorInfo.Text[UnityEngine.UI.Text].text = errorinfo_list[id];
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "SHOW_ERROR_INFO" then
        if root.speedUp then return end
        local info = ...
        showErrorInfo(info.id)
    end
end
