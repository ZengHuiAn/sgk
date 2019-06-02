local timeBoss = {}
local battleCfg = require "config.battle"

function timeBoss:Start()
    self:initData()
    self:initUi()
    module.guideModule.PlayByType(125,0.2)
end

function timeBoss:getIdx()
    local finish = 1;
    for i,v in ipairs(self.bossList) do
        local _quest = module.QuestModule.Get(v.id)
        if _quest and _quest.status == 0 then
            if _quest.status == 0 then
                return i
            elseif _quest.status == 1 then
                finish = i;
            end
        end
    end
    return finish;
end

function timeBoss:initData()
    self.bossList = {}
    for i,v in pairs(module.QuestModule.GetList(105)) do
        table.insert(self.bossList, v)
    end
    table.sort(self.bossList, function(a, b)
        return a.id < b.id
    end)
    self.idx = self.savedValues.idx or self:getIdx()
    self:upData()
end

function timeBoss:upData()
    self.questCfg = self.bossList[self.idx] or {}
    local _cfg = battleCfg.load(self.questCfg.event_id1).rounds[1].enemys
    self.bossCfg = _cfg[11];
    self.quest = module.QuestModule.Get(self.questCfg.id)
end

function timeBoss:upDescInfo()
    self.view.root.bottom.now[UI.Text].text = tostring(module.HeroModule.GetManager():GetCapacity())
    self.view.root.bottom.recommend[UI.Text].text = self.questCfg.button_des
    for i = 1, 2 do
        local _reward = self.questCfg.reward[i]
        self.view.root.bottom.kill.itemList[i]:SetActive(_reward ~= nil)
        if _reward then
            self.view.root.bottom.kill.itemList[i].icon:SetActive(self.quest and self.quest.status == 1)
            utils.IconFrameHelper.Create(self.view.root.bottom.kill.itemList[i].IconFrame1, {id = _reward.id, type = _reward.type, count = _reward.value, showDetail = true})
        else
            self.view.root.bottom.kill.itemList[i].icon:SetActive(false)
        end
    end
    self.view.root.bottom.time.itemList.item:SetActive(true)
    self.view.root.bottom.time.itemList.item.icon:SetActive(false)
    --if self.questCfg.reward[3] ~= nil then
        --local _reward = self.questCfg.reward[3]
        utils.IconFrameHelper.Create(self.view.root.bottom.time.itemList.item.IconFrame1, {id = self.questCfg.extrareward_id, type = self.questCfg.extrareward_type, count = self.questCfg.extrareward_value, showDetail = true})
        if self.quest.status == 0 then
            if (self.quest.accept_time + self.quest.extrareward_timelimit) <= module.Time.now() then
                self.view.root.bottom.time.itemList.item.icon[CS.UGUISpriteSelector].index = 1
                self.view.root.bottom.time.itemList.item.icon:SetActive(true)
            else
                self.view.root.bottom.time.itemList.item.icon:SetActive(false)
            end
        elseif self.quest.status == 1 then
            self.view.root.bottom.time.itemList.item.icon[CS.UGUISpriteSelector].index = 0
            self.view.root.bottom.time.itemList.item.icon:SetActive(true)
        end
    --end
end

function timeBoss:upBossInfo()
    self.view.root.bossName.Text[UI.Text].text = self.bossCfg.name
    local mode = self.bossCfg.mode;
    -- local mode = 11024;
    local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(mode), "timeMonster")
	if _pos and _scale then
		self.view.root.mask.bossAnim.transform.localPosition = _pos - Vector3(7.55,189.5,0)
		self.view.root.mask.bossAnim.transform.localScale = _scale
    end
    
    -- self.view.root.mask.bossAnim.transform.localScale = Vector3(0.35, 0.35, 1)
    self.view.root.mask.bossAnim[CS.Spine.Unity.SkeletonGraphic].skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..mode.."/"..mode.."_SkeletonData.asset")
    self.view.root.mask.bossAnim[CS.Spine.Unity.SkeletonGraphic]:Initialize(true)
    self.view.root.attackBtn[UI.Image].material = nil
    if self.quest and self.quest.status == 1 then
        self.view.root.mask.bossAnim[CS.Spine.Unity.SkeletonGraphic].material = SGK.QualityConfig.GetInstance().grayMaterial
        self.view.root.attackBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
    else
        if not self.quest then
            self.view.root.attackBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        end
        self.view.root.mask.bossAnim[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0, "idle", true)
    end
    self.view.root.bossKilled:SetActive(self.quest ~= nil and self.quest.status == 1)
end

function timeBoss:upUi()
    self:upBossInfo()
    self:upDescInfo()
end

function timeBoss:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.leftBtn.gameObject).onClick = function()
        if self.idx > 1 then
            self.idx = self.idx - 1
            self.savedValues.idx = self.idx
            self:upData()
            self:upUi()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.rightBtn.gameObject).onClick = function()
        if self.idx < #self.bossList then
            self.idx = self.idx + 1
            self.savedValues.idx = self.idx
            self:upData()
            self:upUi()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.upCapacity.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/stronger/newStrongerFrame")
    end
    CS.UGUIClickEventListener.Get(self.view.root.attackBtn.gameObject).onClick = function()
        if utils.SGKTools.isTeamLeader() or (not utils.SGKTools.GetTeamState()) then
            if not self.quest then
                showDlgError(nil, "击杀当前BOSS可解锁后续BOSS")
                return
            end
            if self.quest.status ~= 0 then
                showDlgError(nil, "已击杀")
                return
            end
            if self.quest and self.quest.status == 0 then
                module.fightModule.StartFight(self.questCfg.event_id1)
            end
        else
            showDlgError(nil, "你正在队伍中，无法进行该操作")
        end
    end
end

function timeBoss:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initBtn()
    self:upUi()
end

function timeBoss:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "PLAYER_LEVEL_UP",
        "LOCAL_GUIDE_CHANE",
    }
end

function timeBoss:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.id == self.questCfg.id then
            self:upData()
            self:upUi()
            module.QuestModule.AcceptSideQuest()
        end
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(125,0.2)
    end
end

function timeBoss:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true
end

return timeBoss
