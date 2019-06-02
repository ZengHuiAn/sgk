local ItemHelper = require"utils.ItemHelper"
local unionConfig = require "config.unionConfig"
local activityModule = require "module.unionActivityModule"
local MapConfig = require "config.MapConfig"
local NetworkService = require "utils.NetworkService";
local newUnionExploreBox = {}

function newUnionExploreBox:initData(data)
    self.cfg = data.cfg
    self.mapCfg = data.mapCfg
    self.order = data.order
    self.eventCfg = unionConfig.GetTeamAccident(self.cfg.eventId) or {}
    self.hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO, self.cfg.heroId)
    self.Manage = activityModule.ExploreManage
end

function newUnionExploreBox:initIcon()
    self.view.root.box:SetActive(false)
    self.view.root.boss:SetActive(false)
    self.view.root.map:SetActive(false)
    self.view.root.bossState:SetActive(false)
    if self.eventCfg.accident_type == 1 then
        self.boxNode = self.view.root.box
    elseif self.eventCfg.accident_type == 2 then
        self.boxNode = self.view.root.bossState.click
        self.view.root.boss:SetActive(true)
        self.view.root.bossState:SetActive(true)
        self:loadBoss(self.view.root.boss, self.eventCfg.mode_id, self.eventCfg.mode_type)
    elseif self.eventCfg.accident_type == 3 then

    elseif self.eventCfg.accident_type == 4 then
        self.boxNode = self.view.root.map
    end
    if self.boxNode then
        self.boxNode:SetActive(true)
    end
    self:initBox()
end

function newUnionExploreBox:initBox()
    if not self.boxNode then
        return
    end
    CS.UGUIClickEventListener.Get(self.boxNode.gameObject).onClick = function()
        self:click()
    end
end

function newUnionExploreBox:initLabel()
    self.label = self.view.root.label.Text[UI.Text]
    self.label.text = string.format(self.eventCfg.accident_des, self.hero_cfg.name, self.hero_cfg.name)
end

function newUnionExploreBox:click()
    for k,v in pairs(activityModule.ExploreManage:GetMapEventList(self.mapCfg.mapId)) do
        for j,p in pairs(v) do
            if p.uuid == self.cfg.uuid then
                if self.eventCfg.accident_type == 1 then        --宝箱
                    self.Manage:FinishEvent(self.mapCfg.mapId, self.order, self.cfg.uuid)
                elseif self.eventCfg.accident_type == 2 then    --战斗
                    DialogStack.Pop()
                    coroutine.resume(coroutine.create( function()
                        local _data = NetworkService.SyncRequest(3365, {nil, self.mapCfg.mapId, self.order, p.uuid})
                        if _data then
                            SceneStack.Push('battle', 'view/battle.lua', { fight_id = _data[3], fight_data = _data[4], callback = function(win, heros, fightid, starInfo, input_record)
                                if win then
                                    coroutine.resume(coroutine.create( function()
                                        local _data_ = NetworkService.SyncRequest(3367, {nil, self.mapCfg.mapId, self.order, p.uuid, starInfo, input_record})
                                        utils.EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", _data_[3], _data_[4]);
                                    end))
                                end
                            end})
                        end
                    end))
                elseif self.eventCfg.accident_type == 3 then    --boss

                elseif self.eventCfg.accident_type == 4 then    --地图

                end
                return
            end
        end
    end
    showDlgError(nil, "已完成")
end

function newUnionExploreBox:loadBoss(node, modeId, modeType)
    local _boss = node:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
    if modeId and _boss then
        local _path = "roles_small/"
        if modeType == 2 then
            _path = "roles/"
            local _scale = node.transform.localScale
            node.transform.localScale = Vector3(self.eventCfg.scale * _scale.x, self.eventCfg.scale * _scale.y, 1 * _scale.z)
        end
        node:GetComponent(typeof(SGK.DialogSprite)).enabled = (not (modeType == 2))
        SGK.ResourcesManager.LoadAsync(_boss, _path..modeId.."/"..modeId.."_SkeletonData.asset", function(o)
            if o then
                _boss.skeletonDataAsset = o
                _boss:Initialize(true)
                _boss.startingLoop = (modeType == 2)
                if modeType == 2 then
                    _boss.AnimationState:SetAnimation(0, "idle", true)
                else
                    local _sprite = node:GetComponent(typeof(SGK.DialogSprite))
                    _sprite:SetDirty()
                end
            else
                _boss.skeletonDataAsset = nil
            end
        end)
    end
end

function newUnionExploreBox:initBoss()
    self:loadBoss(self.view.root.npc, self.hero_cfg.mode)
end

function newUnionExploreBox:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initBg()
    self:initIcon()
    self:initBoss()
    self:initLabel()
    self:initBox()
end

function newUnionExploreBox:initBg()
    self.view.root.bg.Image[UI.Image]:LoadSprite("guanqia/tansuo/"..self.mapCfg.bgMap)
end

function newUnionExploreBox:Start(data)
    self:initData(data)
    self:initUi()
end

function newUnionExploreBox:listEvent()
    return {
        "LOCAL_EXPLORE_MAPEVENT_CHANGE",
    }
end

function newUnionExploreBox:onEvent(event, data)
    if event == "LOCAL_EXPLORE_MAPEVENT_CHANGE" then
        if self.eventCfg.accident_type == 1 then
            for k,v in pairs(activityModule.ExploreManage:GetMapEventList(self.mapCfg.mapId)) do
                for j,p in pairs(v) do
                    if p.uuid == self.cfg.uuid then
                        return
                    end
                end
            end
            self.view.root.gotBox:SetActive(true)
            self.view.root.box:SetActive(false)
        end
    end
end

return newUnionExploreBox
