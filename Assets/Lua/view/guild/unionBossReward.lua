local Time = require "module.Time"
local UnionConfig = require "config.UnionConfig"
local View = {}

function View:Start(data)
--    ERROR_LOG("data---->>>",sprinttb(data))
    self:initData()
    self:initUi()

    self.pid = module.playerModule.Get().id;
    self.view.root.bottom.Text[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_boss_mail")
end

function View:initData()
    local rewardList = module.worldBossModule.GetRankInfo(2).rankInfo or {}

    self.rewardList = {};

    for k,v in pairs(rewardList) do
        table.insert(self.rewardList,v);
    end

    table.sort( self.rewardList, function ( a,b )
        return a.rank <b.rank;
    end )

    -- ERROR_LOG("排行榜========",sprinttb(self.rewardList));
    
    self.bossInfo = module.worldBossModule.GetBossInfo(2) or {}

    self.bossCfg = module.worldBossModule.GetBossCfg(self.bossInfo.id) or {}
    self.selfRank = module.worldBossModule.GetRankInfo(2).selfInfo



    self.replayList = module.worldBossModule.GetReplayInfo(2).replayInfo or {};
end

function View:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.middle.infoBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guildboss_15"))
    end
    CS.UGUIClickEventListener.Get(self.view.root.giftBox.gameObject, true).onClick = function()
        DialogStack.PushPrefStact("guild/UnionBossRewardRank",2);
    end

    self:initTop()
    self:initMiddle()
    self:initBottom()
    self:upUi()
end

function View:initTop()
    self.bossName = self.view.root.top.bossName[UI.Text]
    self.bossDesc = self.view.root.top.bossDesc[UI.Text]
    self.bossTime = self.view.root.top.time[UI.Text]
    self.bossHp = self.view.root.top.hpBar[UI.Scrollbar]
    self.hpNumber = self.view.root.top.hpBar.number[UI.Text]
    self.bossIcon = self.view.root.top.IconFrame[SGK.LuaBehaviour]
    self.killedIcon = self.view.root.top.killed
    self.yuansu = self.view.root.top.yuansu[UI.Image]
    self.bossLevel = self.view.root.top.level[UI.Text]
    self.middleInfo = self.view.root.middle.info[UI.Text]
end

function View:upUi()
    self:upTop()
end

function View:Update()
    if self.bossTime and self.bossInfo and self.bossInfo.beginTime then
        local _time = self.bossInfo.beginTime + self.bossInfo.duration - module.Time.now()
        if self.bossInfo.hp > 0 then
            if _time >= 0 then
                self.bossTime.text = GetTimeFormat(_time, 2,2)
            else
                self.bossTime.text = ""
                self.killedIcon:SetActive(true)
                self.view.root.top.Image:SetActive(false);
                self.view.root.top.hpBar:SetActive(false)
            end
        else
            self.bossTime.gameObject:SetActive(false);
            self.view.root.top.Image:SetActive(false);
            self.bossTime.text = "已击杀"
            self.bossTime = nil
        end
    end
end

function View:upTop()
    self.bossName.text = self.bossCfg.describe
    self.bossDesc.text = self.bossCfg.skill_describe
    local _hp = self.bossInfo.hp
    if self.bossInfo.hp < 0 then
        _hp = 0
    end
    self.hpNumber.text = _hp.."/"..self.bossInfo.allHp
    self.bossHp.size =  _hp / self.bossInfo.allHp
    self.bossLevel.text = "强度 "..self.bossInfo.bossLevel
    -- self.middleInfo.text = SGK.Localize:getInstance():getValue("shijieboss_14", self.rewardList[1].lv_min, self.rewardList[1].lv_max)
    self.yuansu:LoadSprite("propertyIcon/yuansu"..self.bossCfg.element)
    self.killedIcon:SetActive(self.bossInfo.hp <= 0)
    self.view.root.top.hpBar:SetActive(self.bossInfo.hp > 0)
    
    utils.IconFrameHelper.Create(self.bossIcon, {customCfg = {
            icon    = self.bossCfg.icon,
            quality = 0,
            star    = 0,
            level   = self.bossInfo.bossLevel or 0,
    }, type = 42})
end

function View:initBottom()
    self.view.root.bottom.item.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(rewardObj, rewardIdx)
        local _rewardView = CS.SGK.UIReference.Setup(rewardObj.gameObject)
        local _rewardTab = self.bossCfg.reward[rewardIdx + 1]
        utils.IconFrameHelper.Create(_rewardView.IconFrame, {id = _rewardTab.id, type = _rewardTab.type, showDetail = true, count = 0,pos = 2})
        rewardObj:SetActive(true)
    end
    self.view.root.bottom.item.root.ScrollView[CS.UIMultiScroller].DataCount = not self.bossCfg and 0 or #self.bossCfg.reward
end

function View:initMiddle()
    self.scrollView = self.view.root.middle.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
        local index = idx +1

        local data = self.rewardList[index]


        ERROR_LOG("===排行数据=====",sprinttb(data));
        self:initItem(_objView,data);
        -- _objView.root.desc[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.describe, math.ceil(_att))
        -- local _rewardIdx = math.floor(_tab.reward_interval / 30) + 1
        -- if self.selfRank.flag[_rewardIdx] then
        --     _objView.root.finish:SetActive((self.selfRank.flag[_rewardIdx] & (1 << _tab.reward_interval % 30)) == (1 << _tab.reward_interval % 30))
        -- else
        --     _objView.root.finish:SetActive(false)
        -- end
        -- _objView.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(rewardObj, rewardIdx)
        --     local _rewardView = CS.SGK.UIReference.Setup(rewardObj.gameObject)
        --     local _rewardTab = _tab.reward[rewardIdx + 1]
        --     utils.IconFrameHelper.Create(_rewardView.IconFrame, {id = _rewardTab.id, type = _rewardTab.type, showDetail = true, count = _rewardTab.value})
        --     rewardObj:SetActive(true)
        -- end
        -- _objView.root.ScrollView[CS.UIMultiScroller].DataCount = #_tab.reward

        obj:SetActive(true)
    end
    self.scrollView.DataCount = (#self.rewardList or 0)

    if self.scrollView.DataCount and self.scrollView.DataCount==0 then
        self.view.root.middle.noRank:SetActive(true)
    else
        self.view.root.middle.noRank:SetActive(false)
    end
end


function View:initItem( item,data )
    local root = item.root.bg;

    data.pid = data.pid or self.pid;

    if self.pid == data.pid then
        root[CS.UGUISpriteSelector].index = 0;

        root.replay[UI.Button].interactable = false;
    else
        root[CS.UGUISpriteSelector].index = 1;
        root.replay[UI.Button].interactable = true;
    end

    utils.IconFrameHelper.Create(root.player, {pid = data.pid});

    root.harm[UI.Text].text = "累计伤害:"..(data.harm or 0);

    module.playerModule.Get(data.pid,function (_data)
        root.name[UI.Text].text = "名称:".._data.name;
    end)

    if data.rank then
        if data.rank <4 then
            root.rank[CS.UGUISpriteSelector].index = data.rank-1;

        else

        end
        root.rank.Text:SetActive(not (data.rank<4));
        root.rank.Text[UI.Text].text = data.rank;
    else
        root.rank.Text:SetActive(true);
        root.rank.Text[UI.Text].text = "未上榜";
    end
    CS.UGUIClickEventListener.Get(root.replay.gameObject, true).onClick = function()
        if not data.rank then
            showDlgError(nil,"目前没有回放");
            return;
        end

        local replay_data = self.replayList[math.floor(data.pid)];

        ERROR_LOG("回放",sprinttb(self.replayList),sprinttb(replay_data));
        if not replay_data or #replay_data == 0 then
           showDlgError(nil,"目前没有回放");
           return;
        end
        --DialogStack.Pop();
        SceneStack.Push('battle', 'view/battle.lua', {fight_data = replay_data[#replay_data].fightData,
            worldBoss = true})

    end



end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View
