
local timeModule = require "module.Time"
local QuestModule = require "module.QuestModule"
local RewardItemShowCfg = require "config.RewardItemShow"

local luckyDraw_time = {}

function luckyDraw_time:Start()
    -- self:initData()
    -- self:initUi()
    -- self:upUi()
end
function luckyDraw_time:Init()
    self:initData()
    self:initUi()
    self:upUi()
end

function luckyDraw_time:getDuration(id)
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

function luckyDraw_time:getTime(id)
    local cfg = QuestModule.GetCfg(id)
    if cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 then
        local total_pass = timeModule.now() - cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / cfg.period) * cfg.period
        local period_begin = timeModule.now() - period_pass
        return period_begin, (period_begin + cfg.duration)
    end
end

function luckyDraw_time:inTime(id)
    -- if QuestModule.Get(id) then
    --     if QuestModule.Get(id).status ~= 0 and math.ceil(QuestModule.Get(id).accept_time / 86400) == math.ceil(timeModule.now() / 86400) then
    --         return true
    --     end
    -- end
    local cfg = QuestModule.GetCfg(id)
    if cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 then
        local total_pass = timeModule.now() - cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / cfg.period) * cfg.period
        local period_begin = timeModule.now() - period_pass;
        if timeModule.now() > period_begin and timeModule.now() < (period_begin + cfg.duration) then
            QuestModule.Accept(id)
            self.nowQuestId = id
            return true
        end
    end
    return false
end

function luckyDraw_time:initData()
    self.nowQuestId = 0
    self.rotateFlag = true
    self.lastId = 0
    self.questIdTab = {1011001, 1011002}
    self:upQuest()
end

function luckyDraw_time:upQuest()
    if not self:inTime(self.questIdTab[2]) then
        self:inTime(self.questIdTab[1])
    end
    -- self.lastId = self.questIdTab[1]
    -- local _b, _e = self:getTime(self.questIdTab[1])
    -- if timeModule.now() > _e then
    --     self.lastId = self.questIdTab[2]
    --     return
    -- end
    -- local _b2, _e2 = self:getTime(self.questIdTab[2])
    -- if timeModule.now() > _e2 then
    --     self.lastId = self.questIdTab[1]
    -- end
end

function luckyDraw_time:showOpenTips(id)
    local _quest = QuestModule.Get(id)
    if _quest and _quest.status == 1 then
        if math.ceil(_quest.accept_time / 86400) == math.ceil(timeModule.now() / 86400) then
            showDlgError(nil, "本次宝箱已开启")
            return true
        end
    end
    return false
end

function luckyDraw_time:showTips()
    if self:showOpenTips(self.questIdTab[1]) or self:showOpenTips(self.questIdTab[2]) then
        return
    end
    showDlgError(nil, "未到开启时间")
    --showDlgError(nil, "下次开启时间为"..self:getDuration(self.lastId))
end

function luckyDraw_time:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.hourNode = self.view.hour
    self.minuteNode = self.view.minute
    self.startBtn = self.view.start
    self.timeDec = self.view.label.time[UI.Text]

    CS.UGUIClickEventListener.Get(self.view.giftBox.icon.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/GiftBoxPre", {itemTab = RewardItemShowCfg.Get(RewardItemShowCfg.TYPE.LUCKY_DRAW_TIME), textName = "宝箱奖励"}, UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
    end

    CS.UGUIClickEventListener.Get(self.startBtn.gameObject).onClick = function()
        if not self.rotateFlag then
            return
        end
        if self.nowQuestId ~= 0 then
            local _quest = QuestModule.Get(self.nowQuestId)
            if _quest and _quest.status == 0 then
                self.rotateFlag = false
                local _obj = self:playEffect("fx_box_01", Vector3(0, 0, 0), self.view.giftBox.icon.gameObject)
                --self.hourNode.gameObject.transform:DOLocalRotate(Vector3(0, 0, (-360 * 2) + 30 * math.random(1, 12)), 6):OnComplete(function( ... )
                    self.hourNode.gameObject.transform:DOLocalRotate(Vector3(0, 0, (-360 * 5) - 30 * math.random(1, 12)), 4):OnComplete(function( ... )
                        self.startBtn[CS.UGUIClickEventListener].interactable = false
                        self.startBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                        coroutine.resume(coroutine.create(function()
                            QuestModule.Finish(self.nowQuestId)
                            self.startBtn[CS.UGUIClickEventListener].interactable = true
                        end))
                        self:playEffect("fx_box_kai_blue", Vector3(0, 0, 0), self.view.giftBox.icon.gameObject, true)
                        CS.UnityEngine.GameObject.Destroy(_obj)
                    end):SetEase(CS.DG.Tweening.Ease.OutQuad)
                --end):SetEase(CS.DG.Tweening.Ease.OutQuad)
                -- self.minuteNode.gameObject.transform:DOLocalRotate(Vector3(0, 0, (-360 * 14) + self.minuteNode.gameObject.transform.localEulerAngles.z), 5):OnComplete(function()
                --     self.minuteNode.gameObject.transform:DOLocalRotate(Vector3(0, 0, (-360 * 10) + self.minuteNode.gameObject.transform.localEulerAngles.z), 5):SetEase(CS.DG.Tweening.Ease.OutQuad)
                -- end):SetEase(CS.DG.Tweening.Ease.InQuad)
                return
            end
        end
        self:showTips()
        --showDlgError(nil, "不可领取")
    end
    self.timeDec.text = self:getDuration(self.questIdTab[1])..", "..self:getDuration(self.questIdTab[2])
end

function luckyDraw_time:upUi()
    self.startBtn[UI.Image].material = nil
    self.view.bg.clock[UI.Image].material = nil
    self.view.giftBox.bg[UI.Image].material = nil
    self.view.giftBox.icon[UI.Image].material = nil
    self.view.hour.Image[UI.Image].material = nil
    self.view.minute.Image[UI.Image].material = nil
    if self.nowQuestId ~= 0 then
        local _quest = QuestModule.Get(self.nowQuestId)
        if _quest then
            if _quest.status == 0 then
                return
            end
        end
    end
    self.view.bg.clock[UI.Image].material = self.startBtn[CS.UnityEngine.MeshRenderer].materials[0]
    self.startBtn[UI.Image].material = self.startBtn[CS.UnityEngine.MeshRenderer].materials[0]
    self.view.giftBox.bg[UI.Image].material = self.startBtn[CS.UnityEngine.MeshRenderer].materials[0]
    self.view.giftBox.icon[UI.Image].material = self.startBtn[CS.UnityEngine.MeshRenderer].materials[0]
    self.view.hour.Image[UI.Image].material = self.startBtn[CS.UnityEngine.MeshRenderer].materials[0]
    self.view.minute.Image[UI.Image].material = self.startBtn[CS.UnityEngine.MeshRenderer].materials[0]
end

function luckyDraw_time:playEffect(effectName, position, node, delete, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        --transform.localScale = Vector3.zero
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
        if delete then
            local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
            UnityEngine.Object.Destroy(o, _obj.main.duration)
        end
    end
    return o
end

function luckyDraw_time:Update()
    -- if self.hourNode and self.minuteNode then
    --     if self.rotateFlag then
    --         local _now = os.date("*t", timeModule.now())
    --         local _hour = (360 / 12) * (_now.hour + (_now.min / 60))
    --         local _min = (360 / 60) * (_now.min + (_now.sec / 60))
    --         self.hourNode.gameObject.transform.localEulerAngles = Vector3(0, 0, -_hour)
    --         self.minuteNode.gameObject.transform.localEulerAngles = Vector3(0, 0, -_min)
    --     end
    -- end
    self:upQuest()
end

function luckyDraw_time:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function luckyDraw_time:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:upUi()
    end
end

return luckyDraw_time
