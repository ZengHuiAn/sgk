local MapConfig = require "config.MapConfig"
local mapSceneBossView = {}

function mapSceneBossView:Start()
    self:initUi()
    self:upData()
end

function mapSceneBossView:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initView()
end

function mapSceneBossView:initView()
    self.nextTime = self.view.root.nextTime[UI.Text]
    self.bossName = self.view.root.bossName[UI.Text]
    self.endTime = self.view.root.endTime[UI.Text]
    self.hp = self.view.root.hp[UI.Image]
    self.icon = self.view.root.icon[UI.Image]
    CS.UGUIClickEventListener.Get(self.view.root.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/worldBossReward", {idx = self.bossInfo.type})
    end
end

function mapSceneBossView:upData()
    self.bossInfo = module.worldBossModule.GetBossInfo(module.worldBossModule.Type.World)
    if self.bossInfo and self.bossInfo.type == module.worldBossModule.Type.World then
        local _npcCfg = MapConfig.GetMapMonsterConf(self.bossInfo.id)
        if _npcCfg then
            self.view.root:SetActive(_npcCfg.mapid == SceneStack.MapId())
        else
            self.view.root:SetActive(false)
        end
        self.bossCfg = module.worldBossModule.GetBossCfg(self.bossInfo.id) or {}
        self.hp.fillAmount = self.bossInfo.hp / self.bossInfo.allHp
        self.bossName.text = self.bossCfg.describe
        self.view.root.killed:SetActive(self.bossInfo.hp <= 0)
        self.icon:LoadSprite("propertyIcon/yuansu"..self.bossCfg.element)
    else
        self.view.root:SetActive(false)
    end
end

function mapSceneBossView:Update()
    if self.view.root.activeSelf then
        if self.endTime and self.bossInfo and self.bossInfo.beginTime then
            local _time = self.bossInfo.beginTime + self.bossInfo.duration - module.Time.now()
            if self.bossInfo.hp >= 0 then
                if _time >= 0 then
                    self.endTime.text = GetTimeFormat(_time, 2, 2).."后逃跑"
                else
                    self.endTime.text = ""
                end
            else
                self.endTime.text = ""
            end
        end
        if self.nextTime and self.bossInfo.nextTime then
            local _time = self.bossInfo.nextTime - module.Time.now()
            if _time >= 0 then
                self.nextTime.text = GetTimeFormat(_time, 2, 2).."后可发起战斗"
            else
                self.nextTime.text = ""
            end
        end
    end
end

function mapSceneBossView:showAttackInfo(data)
    if self.view.root.activeSelf then
        if data and data.pid and data.harm and data.oldHarm and data.harm - data.oldHarm > 0 then
            -- if module.playerModule.IsDataExist(data.pid) then
            module.worldBossModule.PlayeBossAttackAnim(data.type, data.harm - data.oldHarm, data.pid)
            -- else
            --     module.playerModule.Get(data.pid,(function()
            --         module.worldBossModule.PlayeBossAttackAnim(data.type, data.harm - data.oldHarm,  module.playerModule.IsDataExist(data.pid).name)
            --     end))
            -- end
        end
    end
end

function mapSceneBossView:listEvent()
    return {
        "LOCAL_WORLDBOSS_INFO_CHANGE",
        "LOCAL_WORLDBOSS_ATTACK_INFO",
    }
end

function mapSceneBossView:onEvent(event, data)
    if event == "LOCAL_WORLDBOSS_INFO_CHANGE" then
        self:upData()
    elseif event == "LOCAL_WORLDBOSS_ATTACK_INFO" then
        self:showAttackInfo(data)
    end
end

return mapSceneBossView
