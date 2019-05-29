local worldBossReplay = {}
local worldBossModule = require "module.worldBossModule";
local Time = require("module.Time")


function worldBossReplay:Start(data)
    if data then
        self.idx = data.idx
    else
        self.idx = self.savedValues.idx or 1
    end
    self.savedValues.idx = self.idx
    self:initUi();
    coroutine.resume(coroutine.create( function ( ... )
        local rank = worldBossModule.queryRankInfo();
       
        self.view.root.selfRank.Text[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_04", (rank[3] ~=-1 and rank[3] or "未上榜"))
        ERROR_LOG("今日最佳排行",sprinttb(rank));
    end) )
    CS.UGUIClickEventListener.Get(self.view.root.selfRank.infoBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shijieboss_19"))
    end

    self:initData();
    self:initCurrent();
    worldBossModule.LaterRankInfo(function ( _data )
        ERROR_LOG("========获取排行信息===========",sprinttb(_data));
        self.later = _data;
        self.index = self:GetCurrentIndex();

        self:initTopUI();
    end);


    -- self:initData({idx = self.idx})
    -- self:initUi()
    -- self:upUi()
end

function worldBossReplay:GetCurrentIndex()
    local worldbossList = worldBossModule.GetBossConfig(1)
    local index = 0;
    for i=1,#worldbossList do
        if worldbossList[i].id == self.bossinfo.id then
            index = i
        end
    end

    return index
end


function worldBossReplay:initCurrent()
    local bossinfo = worldBossModule.GetBossInfo(1);
    self.bossinfo = bossinfo


    ERROR_LOG("当前Boss信息",sprinttb(bossinfo));
end


function worldBossReplay:initTopUI()
    local worldbossList = worldBossModule.GetBossConfig(1)
    -- ERROR_LOG("本场boss配置",sprinttb(worldbossList));


    local monster_root = self.view.root.battleInfo.monsters;
    for i=1,#worldbossList do
        self:initTopItem(monster_root["monster"..i],worldbossList[i],i);
    end

    ERROR_LOG("========>>>>",sprinttb(self.bossinfo));
    if not self.bossinfo or not self.bossinfo.id then
        monster_root["monster1"][UI.Toggle].isOn = true;
    end
    -- monster_root[UI.ToggleGroup]:SetAllTogglesOff();
end


function worldBossReplay:initTopItem( item,data ,index)
    utils.IconFrameHelper.Create(item.IconFrame, {customCfg = {
            icon    = data.icon,
            quality = 0,
            star    = 0,
            level   =  0,
    }, type = 42})
    local bossinfo = worldBossModule.GetBossInfo(1);
    for i=1,3 do
        item.status[i]:SetActive(false);
    end

    if index < self.index then
        item.status["end"]:SetActive(true);
    elseif index == self.index then

        if self.bossinfo.hp <=0 then
            item.status["end"]:SetActive(true);
        else
            item.status["start"]:SetActive(true);
        end
    elseif index > self.index then
        item.status["doing"]:SetActive(true);
    end

    item[UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( status )
        item.select:SetActive(status);
        if status then

            item.transform:DOScale(UnityEngine.Vector3(1.3,1.3,1),0.2);
            self:initBossDesc(data.describe,data.skill_describe);
            self:initFlag(item,data);

            if index < self.index then
                --已结束
                self:initTime(data,1);
                local later = self.later[#self.later - (self.index -index)+1];
                
                self:initScrollView(1,later)
            elseif index == self.index then
                self:initTime(data,2);
                
                --当前boss
                self:initScrollView(2)
            elseif index > self.index then
                self:initTime(data,3);
               
                --下一个boss
                self:initScrollView(3)
            end
        else
            item.transform:DOScale(UnityEngine.Vector3(1,1,1),0.2);
        end
    end)


    if self.bossinfo.id == data.id then
        item[UnityEngine.UI.Toggle].isOn = true
    else
        item[UnityEngine.UI.Toggle].isOn = false
    end
end


--type 3 隐藏所有排行榜
function worldBossReplay:initNext()
    self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta.x,440);
    self.view.root.CurrentRank:SetActive(false);
    self.scrollView.DataCount = 0;
end


function worldBossReplay:initNoneSelf(  )
    local _objView = CS.SGK.UIReference.Setup(self.view.root.CurrentRank.gameObject)
    _objView:SetActive(true)
    _objView.root.rankIcon:SetActive(false)
    _objView.root.rankNumber:SetActive(true)
    _objView.root.rankNumber[UI.Text].text = "未上榜"
    local pid = module.playerModule.Get().id;
    utils.IconFrameHelper.Create(_objView.root.IconFrame, {pid = pid
    , func = function()
        if module.playerModule.IsDataExist(pid) then
            _objView.root.name[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_01", module.playerModule.IsDataExist(pid).name)
        end
    end})
    _objView.root.damage[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_02", 0)
end

function worldBossReplay:initScrollView(type,data)
    self.view.root.CurrentRank:SetActive(false);
    self.view.root.noRank:SetActive(false);
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    if type == 3 then
        self:initNext();
        self.view.root.noRank:SetActive(true);
        self.view.root.CurrentRank:SetActive(false);
        self.scrollView.gameObject:SetActive(false);

        return;
    elseif type == 1 then
        ERROR_LOG("===============过时排行榜",sprinttb(data));

        if not data or #data.allrank == 0  then
            self.view.root.noRank:SetActive(true);
            self.view.root.CurrentRank:SetActive(false);
            self.scrollView.gameObject:SetActive(false);
            return
        end

        self.scrollView.gameObject:SetActive(true);
        if not data or not data.selfrank or not data.selfrank.pid then
            self:initNoneSelf();
            ERROR_LOG("未上榜");
            self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta.x,330);
        else
            self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta.x,440);
        end
        
        self.scrollView.RefreshIconCallback = function(obj, idx)
            local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
            local _tab = data.allrank[idx + 1]
            if _tab.rank <= 3 then
                _objView.root.rankIcon[CS.UGUISpriteSelector].index = (_tab.rank - 1)
            end
            _objView.root.rankIcon:SetActive(_tab.rank <= 3)
            _objView.root.rankNumber:SetActive(_tab.rank > 3)
            _objView.root.rankNumber[UI.Text].text = tostring(_tab.rank)
            _objView.root.damage[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_02", _tab.harm)
            utils.IconFrameHelper.Create(_objView.root.IconFrame, {pid = _tab.pid, func = function()
                if module.playerModule.IsDataExist(_tab.pid) then
                    _objView.root.name[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_01", module.playerModule.IsDataExist(_tab.pid).name)
                end
            end})
            _objView.root.replay:SetActive(false);

            obj:SetActive(true)
        end

        self.scrollView.DataCount = #data.allrank
        if data.selfrank and data.selfrank.rank then
            self.scrollView:ScrollMove(data.selfrank.rank -1 or 0);
        end

        return;
    end
    ERROR_LOG("排名信息",sprinttb(self.replayList));
    if #self.replayList == 0 then
        self.view.root.noRank:SetActive(true);
        self.view.root.CurrentRank:SetActive(false);
        self.scrollView.gameObject:SetActive(false);
        return;
    end
    self.scrollView.gameObject:SetActive(true);
    if not self.selfRank or not self.selfRank.pid  then
         self:initNoneSelf();
        self.view.root.CurrentRank:SetActive(true);
         self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta.x,330);
    else
        self.view.root.CurrentRank:SetActive(false);
        local _objView = CS.SGK.UIReference.Setup(self.view.root.CurrentRank.gameObject)
        local _tab = self.selfRank
        _objView.root.rankIcon:SetActive(_tab.rank <= 3)
        _objView.root.rankNumber:SetActive(_tab.rank > 3)
        _objView.root.rankNumber[UI.Text].text = tostring(_tab.rank)

        self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta.x,440);
    end


    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
        local _tab = self.replayList[idx + 1]
        if _tab.rank <= 3 then
            _objView.root.rankIcon[CS.UGUISpriteSelector].index = (_tab.rank - 1)
        end
        _objView.root.rankIcon:SetActive(_tab.rank <= 3)
        _objView.root.rankNumber:SetActive(_tab.rank > 3)
        _objView.root.rankNumber[UI.Text].text = tostring(_tab.rank)
        _objView.root.damage[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_02", _tab.harm)
        utils.IconFrameHelper.Create(_objView.root.IconFrame, {pid = _tab.pid, func = function()
            if module.playerModule.IsDataExist(_tab.pid) then
                _objView.root.name[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_01", module.playerModule.IsDataExist(_tab.pid).name)
            end
        end})
        _objView.root.replay:SetActive(type == 2);

        CS.UGUIClickEventListener.Get(_objView.root.replay.gameObject).onClick = function()
            local _data = module.worldBossModule.GetReplayInfo(self.idx).replayInfo
            if _data and _data[_tab.pid] and _data[_tab.pid][#_data[_tab.pid]] then
                DialogStack.Pop();
                SceneStack.Push('battle', 'view/battle.lua', {fight_data = _data[_tab.pid][#_data[_tab.pid]].fightData,
                worldBoss = true})
            else
                showDlgError(nil, "暂无战报")
            end
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.replayList
end


function worldBossReplay:initFlag( item ,data)
    -- if data then
    --     -- body
    -- end
end

--status  --1结束  --2进行中  --3未开始
function worldBossReplay:initTime( data,status)
    self.end_time = self.bossinfo.beginTime+self.bossinfo.duration;
    if status == 2 then
        if self.end_time < Time.now() or self.bossinfo.hp <= 0 then
           self.end_time = nil;
           self.view.root.monsterInfo.time[UI.Text].text = "<color=red>已结束</color>"
        end
    elseif status == 1 then

        self.view.root.monsterInfo.time[UI.Text].text = "<color=red>已结束</color>"
        self.end_time = nil

    elseif status == 3 then
        self.view.root.monsterInfo.time[UI.Text].text = "<color=red>未开始</color>"
        self.end_time = nil
    end
end


function worldBossReplay:Update( ... )
    if self.end_time then
        local time = self.end_time-Time.now();

        if time>0 then

            self.view.root.monsterInfo.time[UI.Text].text = "<color=#22FFB9FF>"..GetTimeFormat(time, 2,2).."</color>"
        else
            self.end_time = nil
            self.view.root.monsterInfo.time[UI.Text].text = "<color=red>已结束</color>"
        end
    end
end

function worldBossReplay:initBossDesc(name,desc)
    self.view.root.monsterInfo.bossDesc[UI.Text].text = desc;
    self.view.root.monsterInfo.name[UI.Text].text = name;
end

function worldBossReplay:initData()
    self.replayList = {}
    self.selfRank = module.worldBossModule.GetRankInfo(1).selfInfo
    for k,v in pairs(module.worldBossModule.GetRankInfo(1).rankInfo or {}) do
        if v.harm > 0 then
            table.insert(self.replayList, v)
        end
    end
    table.sort(self.replayList, function(a, b)
        return a.rank < b.rank
    end)
end

function worldBossReplay:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    -- CS.UGUIClickEventListener.Get(self.view.root.bottom.info.gameObject).onClick = function()
    --     utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shijieboss_17"))
    -- end
    -- self:initTop()
end

function worldBossReplay:initTop()
    -- CS.UGUIClickEventListener.Get(self.view.root.bottom.replay.gameObject).onClick = function()
    --     local _data = module.worldBossModule.GetReplayInfo(self.idx).replayInfo
    --     if _data and self.selfRank and _data[self.selfRank.pid] and _data[self.selfRank.pid][#_data[self.selfRank.pid]] then
    --         SceneStack.Push('battle', 'view/battle.lua', {fight_data = _data[self.selfRank.pid][#_data[self.selfRank.pid]].fightData,
    --         worldBoss = true})
    --     else
    --         showDlgError(nil, "暂无战报")
    --     end
    -- end
    -- self:initScrollView()
    -- self:initInfo()
end



function worldBossReplay:initInfo()
    self.rankInfo = self.view.root.bottom.rank[UI.Text]
    self.damageInfo = self.view.root.bottom.damage[UI.Text]
    self.todayHarmInfo = self.view.root.bottom.todayHarm[UI.Text]
end

function worldBossReplay:upUi()
    self:upInfo()
end

function worldBossReplay:upInfo()
    if self.selfRank then
        self.rankInfo.text = SGK.Localize:getInstance():getValue("shijieboss_04", self.selfRank.rank or "未上榜")
        self.damageInfo.text = SGK.Localize:getInstance():getValue("shijieboss_05", self.selfRank.todayHarm or "0")
        self.todayHarmInfo.text = SGK.Localize:getInstance():getValue("shijieboss_18", self.selfRank.harm or "0")
    else
        self.rankInfo.text = SGK.Localize:getInstance():getValue("shijieboss_04", "未上榜")
        self.damageInfo.text = SGK.Localize:getInstance():getValue("shijieboss_05", "0")
        self.todayHarmInfo.text = SGK.Localize:getInstance():getValue("shijieboss_18", "0")
    end
end

function worldBossReplay:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return worldBossReplay
