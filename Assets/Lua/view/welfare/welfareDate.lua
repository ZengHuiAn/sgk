local timeModule = require "module.Time"
local QuestModule = require "module.QuestModule"
local welfareDate = {}

function welfareDate:Start()

end
function welfareDate:Init()
    self:initData()
    self:initUi()
end

function welfareDate:initData()
    self.questList = {1011001, 1011002}
end

function welfareDate:getDuration(id)
    local cfg = QuestModule.GetCfg(id)
    if cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 then
        local total_pass = timeModule.now() - cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / cfg.period) * cfg.period
        local period_begin = timeModule.now() - period_pass;
        local _begin = os.date("*t", period_begin)
        local _end = os.date("*t", period_begin + cfg.duration)
        if _begin.hour < 10 then
            _begin.hour = "0".._begin.hour
        end
        if _begin.min < 10 then
            _begin.min = "0".._begin.min
        end
        if _end.hour < 10 then
            _end.hour = "0".._end.hour
        end
        if _end.min < 10 then
            _end.min = "0".._end.min
        end
        return _begin.hour..":".._begin.min.."-".._end.hour..":".._end.min
    end
end


function welfareDate:inTime(id)
    local cfg = QuestModule.GetCfg(id)
    if cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 then
        local total_pass = timeModule.now() - cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / cfg.period) * cfg.period
        local period_begin = timeModule.now() - period_pass;
        if timeModule.now() > period_begin and timeModule.now() < (period_begin + cfg.duration) then
            coroutine.resume(coroutine.create(function()
                QuestModule.Accept(id)
                self.nowQuestId = id
                self:upBtn()
            end))
            return true
        end
    end
    return false
end

function welfareDate:upQuest()
    if not self:inTime(self.questList[2]) then
        self:inTime(self.questList[1])
    end
    self:upBtn()
end

function welfareDate:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:upQuest()
    self.view.bg.time[UI.Text].text = self:getDuration(self.questList[1])..", "..self:getDuration(self.questList[2])
    CS.UGUIClickEventListener.Get(self.view.getBtn.gameObject).onClick = function()
        if self.view.getBtn[CS.UGUISpriteSelector].index == 1 then--时间未到
            showDlgError(nil,SGK.Localize:getInstance():getValue("yuehui_1"))
        elseif self.view.getBtn[CS.UGUISpriteSelector].index == 2 then--已吃饱
            showDlgError(nil,SGK.Localize:getInstance():getValue("yuehui_2"))
        else
            if self.nowQuestId then
               if module.QuestModule.CanSubmit(self.nowQuestId) then
                    self.view.getBtn[CS.UGUIClickEventListener].interactable = false
                    self.view.getBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                    self.view.anim[SGK.UGUISpriteAnimation]:Play()
                    self.view.anim.transform:DOLocalMoveZ(0, 2):OnComplete(function()
                        coroutine.resume(coroutine.create(function()
                            QuestModule.Finish(self.nowQuestId)
                            self.view.anim[SGK.UGUISpriteAnimation]:Stop()
                            self.view.getBtn[CS.UGUIClickEventListener].interactable = true
                            self.view.getBtn[UI.Image].material = nil
                        end))
                    end)
                else

               end
            end
        end
    end
end

function welfareDate:upBtn()
    if self.nowQuestId then
        local _quest = module.QuestModule.Get(self.nowQuestId)
        if _quest then
            if _quest.status == 1 then
                self.view.getBtn[CS.UGUISpriteSelector].index = 2
                self.view.anim[CS.UGUISpriteSelector].index = 2
                return
            elseif _quest.status == 0 then
                self.view.getBtn[CS.UGUISpriteSelector].index = 0
                self.view.anim[CS.UGUISpriteSelector].index = 0
                return
            end
        end
    end
    self.view.getBtn[CS.UGUISpriteSelector].index = 1
    self.view.anim[CS.UGUISpriteSelector].index = 2
end

function welfareDate:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function welfareDate:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data then
            for k,v in pairs(self.questList) do
                if v == data.id then
                    self:upQuest()
                    break
                end
            end
        end
    end
end

return welfareDate
