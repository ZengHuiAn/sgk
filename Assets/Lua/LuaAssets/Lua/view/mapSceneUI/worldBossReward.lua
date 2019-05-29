local worldBossReward = {}

function worldBossReward:Start(data)
    if data then
        self.idx = data.idx
    else
        self.idx = self.savedValues.idx or 1
    end
    self.savedValues.idx = self.idx
    self:initData({idx = self.idx})
    self:initUi()

    self.end_time = self.bossInfo.beginTime + self.bossInfo.duration;
    if self.bossInfo.hp == 0 then
        self.end_time = nil
        self.bossTime.text = "已结束"
    end
end

function worldBossReward:initData(data)
    self.rewardList = module.worldBossModule.GetBossRewardCfg(data.idx, module.HeroModule.GetManager():Get(11000).level) or {}
    self.bossInfo = module.worldBossModule.GetBossInfo(data.idx) or {}
    self.bossCfg = module.worldBossModule.GetBossCfg(self.bossInfo.id) or {}
    self.selfRank = module.worldBossModule.GetRankInfo(data.idx).selfInfo
end

function worldBossReward:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end

    CS.UGUIClickEventListener.Get(self.view.root.attack.gameObject, true).onClick = function()
        module.worldBossModule.worldBossHunting(true,self.bossInfo.id);
        DialogStack.Pop()
    end

    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.replay.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/worldBossReplay", {idx = self.idx})
    end

    CS.UGUIClickEventListener.Get(self.view.root.giftBox.gameObject).onClick = function()
        DialogStack.PushPrefStact("guild/UnionBossRewardRank",1);
    end
    -- giftBox
    CS.UGUIClickEventListener.Get(self.view.root.middle.back.infoBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shijieboss_15"))
    end
    self:initTop()
    self:initMiddle()
    self:initBottom()
    self:upUi()
end

function worldBossReward:initTop()
    self.bossName = self.view.root.top.bossName[UI.Text]
    self.bossDesc = self.view.root.top.bossDesc[UI.Text]
    self.bossTime = self.view.root.top.time[UI.Text]
    self.bossHp = self.view.root.top.hpBar[UI.Scrollbar]
    self.hpNumber = self.view.root.top.hpBar.number[UI.Text]
    self.bossIcon = self.view.root.top.IconFrame[SGK.LuaBehaviour]
    self.killedIcon = self.view.root.top.killed
    self.yuansu = self.view.root.top.yuansu[UI.Image]
    self.bossLevel = self.view.root.top.level[UI.Text]
    self.middleInfo = self.view.root.middle.back.info[UI.Text]
end

function worldBossReward:upUi()
    self:upTop()
end

function worldBossReward:Update()
    if self.bossTime and self.bossInfo and self.bossInfo.beginTime then
        local _time = self.bossInfo.beginTime + self.bossInfo.duration - module.Time.now()
        if self.bossInfo.hp >= 0 then
            if _time >= 0 then
                self.bossTime.text = GetTimeFormat(_time, 2,2)
            else
                self.bossTime.text = "已结束"
                
                
                coroutine.resume( coroutine.create( function ( ... )
                    -- body
                    module.worldBossModule.QueryAll();
                end ) )
                self.bossTime = nil
            end
        else
            self.bossTime.text = "已结束"
            self.bossTime = nil

            coroutine.resume( coroutine.create( function ( ... )
                -- body
                module.worldBossModule.QueryAll();
            end ) )
        end
    end


end

function worldBossReward:upTop()
    self.bossName.text = self.bossCfg.describe
    self.bossDesc.text = self.bossCfg.skill_describe
    local _hp = self.bossInfo.hp
    if self.bossInfo.hp < 0 then
        _hp = 0
    end

    ERROR_LOG("=>>.",sprinttb(self.bossInfo));
    self.hpNumber.text = _hp.."/"..self.bossInfo.allHp
    self.bossHp.size =  _hp / self.bossInfo.allHp
    self.bossLevel.text = "强度 "..self.bossInfo.bossLevel
    self.middleInfo.text = SGK.Localize:getInstance():getValue("shijieboss_14", self.rewardList[1].lv_min, self.rewardList[1].lv_max)
    self.yuansu:LoadSprite("propertyIcon/yuansu"..self.bossCfg.element)
    self.killedIcon:SetActive(self.bossInfo.hp <= 0)
    self.view.root.top.hpBar:SetActive(self.bossInfo.hp > 0)
    self.view.root.top.time:SetActive(self.bossInfo.hp > 0)
    self.view.root.top.Image:SetActive(self.bossInfo.hp > 0)
    self.view.root.attack:SetActive(self.bossInfo.hp > 0)
    utils.IconFrameHelper.Create(self.bossIcon, {customCfg = {
            icon    = self.bossCfg.icon,
            quality = 0,
            star    = 0,
            level   = self.bossInfo.bossLevel or 0,
    }, type = 42})
end

function worldBossReward:initBottom()
    self.view.root.bottom.item.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(rewardObj, rewardIdx)
        local _rewardView = CS.SGK.UIReference.Setup(rewardObj.gameObject)
        local _rewardTab = self.bossCfg.reward[rewardIdx + 1]
        utils.IconFrameHelper.Create(_rewardView.IconFrame, {id = _rewardTab.id, type = _rewardTab.type, showDetail = true, count = 0})
        rewardObj:SetActive(true)
    end
    ERROR_LOG("==================",sprinttb(self.bossCfg));
    self.view.root.bottom.item.root.ScrollView[CS.UIMultiScroller].DataCount = #self.bossCfg.reward
end

function worldBossReward:initMiddle()
    self.scrollView = self.view.root.middle.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
        local _tab = self.rewardList[idx + 1]
        --local _att = self.bossInfo.allHp * (_tab.damage_limit / 10000)
        local _att = _tab.damage
        _objView.root.desc[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.describe, math.ceil(_att))
        local _rewardIdx = math.floor(_tab.reward_interval / 30) + 1
        if self.selfRank and self.selfRank.flag[_rewardIdx] then
            _objView.root.finish:SetActive((self.selfRank.flag[_rewardIdx] & (1 << _tab.reward_interval % 30)) == (1 << _tab.reward_interval % 30))
        else
            _objView.root.finish:SetActive(false)
        end
        _objView.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(rewardObj, rewardIdx)
            local _rewardView = CS.SGK.UIReference.Setup(rewardObj.gameObject)
            local _rewardTab = _tab.reward[rewardIdx + 1]
            utils.IconFrameHelper.Create(_rewardView.IconFrame, {id = _rewardTab.id, type = _rewardTab.type, showDetail = true, count = _rewardTab.value})
            rewardObj:SetActive(true)
        end
        _objView.root.ScrollView[CS.UIMultiScroller].DataCount = #_tab.reward

        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.rewardList
end

function worldBossReward:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return worldBossReward
