local activityConfig = require "config.activityConfig"
local DialogCfg = require "config.DialogConfig"
local MapConfig = require "config.MapConfig"
local Time = require "module.Time"
local questModule = require "module.QuestModule"
local newMapSceneActivity = {}

function newMapSceneActivity:Start(data)
  --ERROR_LOG("data===>>",sprinttb(data))--{filter ={id = 1003,flag = false,}}
    ERROR_LOG("data-------->>>>>",sprinttb(data))
    -- if not data.filter then
    --    data={filter ={id = 1003,flag = false,}}
    -- end
    self._ActivetyList={}
    self:initData(data)
    self:initUi(data)
    self:initGuide()
    local _chat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
    local _chatView = CS.SGK.UIReference.Setup(_chat).UGUIResourceBar
    --_chatView.TopBar:SetActive(false)
    if self.view[SGK.DialogAnim] then
        self.view[SGK.DialogAnim]:PlayFullScreenBarStart(_chatView.TopBar.gameObject, _chatView.BottomBar.gameObject)
    end
    self.view.root.bottom.ScrollView[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward()
end

function newMapSceneActivity:initData(data)
    self.idx = self.savedValues.idx or 0
end

function newMapSceneActivity:initUi(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- self:initTop()--屏蔽顶部活跃度
    self:initBottom(data)
end

function newMapSceneActivity:upTop()
    for i = 1, #self.view.root.top.activityNode do
        local _view = self.view.root.top.activityNode[i]
        if module.ItemModule.GetItemCount(90012) >= activityConfig.ActiveCfg(i).limit_point then
            _view[CS.UGUISpriteSelector].index = 1
            _view.Text[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
        else
            _view[CS.UGUISpriteSelector].index = 0
            _view.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
        end
        if module.QuestModule.CanSubmit(i) then
            module.RedDotModule.PlayRedAnim(_view.tip)
            _view.tip:SetActive(true)
            self.view.root.top.rewardNode[i].rewards.Button[CS.UGUISelectorGroup]:reset()
        else
            _view.tip:SetActive(false)
            self.view.root.top.rewardNode[i].rewards.Button[CS.UGUISelectorGroup]:setGray()
        end
    end
    self.topSlider.size = module.ItemModule.GetItemCount(90012) / 100
    self.view.root.top.number[UI.Text].text = string.format("%s", module.ItemModule.GetItemCount(90012))
end

function newMapSceneActivity:initTop()
    self.topSlider = self.view.root.top.Scrollbar[UI.Scrollbar]
    for i = 1, #self.view.root.top.rewardNode do
        local _view = self.view.root.top.rewardNode[i]
        local _reward = _view.rewards.ScrollView[CS.UIMultiScroller]
        local _cfg = module.QuestModule.GetCfg(i)
        _reward.RefreshIconCallback = function (obj, idx)
            local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
            local _tab = _cfg.reward[idx + 1]
            utils.IconFrameHelper.Create(_objView.IconFrame, {id = _tab.id, type = _tab.type, count = _tab.value, showDetail = true})
            obj:SetActive(true)
        end
        _reward.DataCount = #_cfg.reward
    end
    for i = 1, #self.view.root.top.activityNode do
        local _view = self.view.root.top.activityNode[i]
        local _cfg = module.QuestModule.GetCfg(i)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            self.view.root.top.rewardNode[i]:SetActive(true)
            CS.UGUIClickEventListener.Get(self.view.root.top.rewardNode[i].rewards.Button.gameObject).onClick = function()
                if module.QuestModule.CanSubmit(i) then
                    coroutine.resume(coroutine.create(function()
                        self.view.root.top.rewardNode[i].rewards.Button[CS.UGUIClickEventListener].interactable = false
                        module.QuestModule.Finish(i)
                        self.view.root.top.rewardNode[i].rewards.Button[CS.UGUIClickEventListener].interactable = true
                    end))
                elseif module.QuestModule.Get(i).status == 1 then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_02"))
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_03"))
                end
            end
            self.view.root.top.mask:SetActive(true)
            CS.UGUIClickEventListener.Get(self.view.root.top.mask.gameObject).onClick = function()
                self.view.root.top.rewardNode[i]:SetActive(false)
                self.view.root.top.mask:SetActive(false)
            end
        end
    end
    self:upTop()
end

function newMapSceneActivity:getActivityTime(cfg)
    local total_pass = module.Time.now() - cfg.begin_time
    local period_pass = math.floor(total_pass % cfg.period)
    local period_begin = 0;
    if period_pass >= cfg.loop_duration then
        period_begin = cfg.begin_time + math.ceil(total_pass / cfg.period) * cfg.period
    else
        period_begin = cfg.begin_time + math.floor(total_pass / cfg.period) * cfg.period
    end
    return period_begin
end

function newMapSceneActivity:lockFunc(cfg,_activeCount)
    local _open = function(tabCfg)
        if tabCfg.lv_limit > module.HeroModule.GetManager():Get(11000).level then
            return true, {desc = SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit)}
        end
        if tabCfg.depend_quest_id ~= 0 then
            local _quest = module.QuestModule.GetCfg(tabCfg.depend_quest_id)
            if not _quest or _quest.status ~= 1 then
                if _quest then
                    return true, {desc = SGK.Localize:getInstance():getValue("huodong_lv_02", _quest.name)}
                end
            end
        end
        if cfg.advise_times ~= 0 then
            if cfg.advise_times <= _activeCount.finishCount then
                return true, {desc = SGK.Localize:getInstance():getValue("huosong_wancheng_01")}--已完成
            end
        end
        if tabCfg.begin_time > 0 and tabCfg.end_time > 0 and tabCfg.period > 0 and tabCfg.loop_duration then
            if activityConfig.CheckActivityOpen(tabCfg.id) == nil then
                return true, {desc = SGK.Localize:getInstance():getValue("common_weikaiqi")}
            elseif not activityConfig.CheckActivityOpen(tabCfg.id) then
                local _beginTime = self:getActivityTime(tabCfg)
                if tabCfg.activity_group ~= 0 then
                    return true, {beginTime = _beginTime}
                else
                    return true, {desc = os.date("%H:%M"..SGK.Localize:getInstance():getValue("common_kaiqi"), tabCfg.begin_time)}
                end
            end
        end
        return false
    end

    if cfg and cfg.activity_group ~= 0 then
        local _list = activityConfig.GetCfgByGroup(cfg.activity_group)
        local _desc = ""
        local _timeList = {}
        for i,v in ipairs(_list) do
            --ERROR_LOG("v----->>>>",sprinttb(v))
            local _op, _tab = _open(v)
            table.insert(_timeList, {idx = i, info = _tab})
            if not _op then
                return false
            end
        end
        local _timeIdx = 1
        local _min = 2^52
        for i,v in ipairs(_timeList) do
            if v.info and v.info.desc then
                return true, {desc = v.info.desc}
            end
            if (v.info.beginTime - module.Time.now()) < _min then
                _min = v.info.beginTime - module.Time.now()
                _timeIdx = v.idx
            end
        end
        return true, {desc = os.date("%H:%M"..SGK.Localize:getInstance():getValue("common_kaiqi"), _list[_timeIdx].begin_time)}
    elseif cfg then
        return _open(cfg)
    end
    return true
end

function newMapSceneActivity:goWhere(_tab)
    ERROR_LOG("_tab.gototype------------->>>>>>",_tab.gototype)
    ERROR_LOG("_tab.name------------->>>>>>",_tab.name)

    if self.idx == 1 and (not module.unionModule.Manage:GetSelfUnion()) then
        showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_05"))
        return
    end
    local _activeCount = activityConfig.GetActiveCountById(_tab.id)
    if _tab.advise_times ~= 0 and _tab.advise_times <= _activeCount.finishCount then
        showDlgError(nil, SGK.Localize:getInstance():getValue("huosong_wancheng_01"))
        return
    end
    if _tab.script ~= "0" then
        local env = setmetatable({
            EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
            Interact = module.EncounterFightModule.GUIDE.Interact,
            GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
            GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
        }, {__index=_G})
        local _func = loadfile("guide/".._tab.script..".lua", "bt", env)
        if _func then
            _func(_tab)
            return
        end
    end
    if _tab.gototype == 1 then
        local _npcCfg = MapConfig.GetMapMonsterConf(tonumber(_tab.findnpcname))
        if _npcCfg and _npcCfg.mapid then
            if not DialogCfg.CheckMap(_npcCfg.mapid) then
                return
            end
        end
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
            DialogStack.CleanAllStack()
            utils.SGKTools.Map_Interact(tonumber(_tab.findnpcname))
        else
            showDlgError(nil, "只有队长可以带领队伍前往")
        end
    elseif _tab.gototype == 2 then
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        if utils.SGKTools.CheckPlayerAfkStatus() then
            showDlgError(nil, "跟随状态下无法进入")
            return
        end
        if _tab.gotowhere == "answer/answer" then
            if module.QuestRecommendedModule.CheckActivity(module.QuestRecommendedModule.GetCfg(1)) then
                DialogStack.CleanAllStack()
                DialogStack.Push(_tab.gotowhere)
            else
                showDlg(nil,"当前活动未开放", function() end)
            end
        elseif _tab.gotowhere == "newSelectMap/selectMap" then
            DialogStack.CleanAllStack()
            DialogStack.Push(_tab.gotowhere, {idx = tonumber(_tab.findnpcname)})
        else
            DialogStack.CleanAllStack()
            DialogStack.Push(_tab.gotowhere)
        end
    elseif _tab.gototype == 3 then
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        SceneStack.Push(_tab.gotowhere, "view/".._tab.gotowhere..".lua")
    elseif _tab.gototype == 4 then
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        if not DialogCfg.CheckMap(tonumber(_tab.gotowhere)) then
            return
        end
        if tonumber(_tab.gotowhere) == 501 then
            SceneStack.EnterMap(501,{pos = module.trialModule.GetPos()})
        else
            SceneStack.EnterMap(tonumber(_tab.gotowhere))
        end
    elseif _tab.gototype == 5 then
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        local _list = activityConfig.GetCfgByGroup(1)
        if _list then
            for i,v in ipairs(_list) do
                local _questCfg = module.QuestRecommendedModule.GetQuest(tonumber(v.findnpcname))
                if _questCfg then
                    module.QuestModule.StartQuestGuideScript(_questCfg, true)
                    return
                end
            end
        end
            showDlgError(nil, "世界领主已被击杀")
    elseif _tab.gototype ==6 then
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        module.mazeModule.Start(601)
    else
        print("gototype", _tab.gototype, "error")
    end
end

function newMapSceneActivity:upInfoNode(cfg)
    local _view = self.view.root.infoNode
   -- ERROR_LOG("ding------->>>",sprinttb(cfg))
--top
    local _activeCount = activityConfig.GetActiveCountById(cfg.id)
    _view.root.top.bg[UI.Image]:LoadSprite(cfg.use_picture)
    _view.root.top.bg.icon[UI.Image]:LoadSprite("icon/"..cfg.icon)
    if cfg.des=="0" then
        cfg.des=""
    end
    if cfg.des2=="0" then
        cfg.des2=""
    end
    _view.root.top.desc[UI.Text].text = string.format("%s\n%s", cfg.des, cfg.des2)
    _view.root.top.worldBossInfo:SetActive(cfg.id == 2102)
    if _view.root.top.worldBossInfo.activeSelf then
        if module.worldBossModule.GetAccumulativeRankings() > 0 then
            _view.root.top.worldBossInfo[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_04", module.worldBossModule.GetAccumulativeRankings() or "未上榜")
        else
            _view.root.top.worldBossInfo[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_04", "未上榜")
        end
    end
--middle
    _view.root.middle.time.Text[UI.Text].text = cfg.activity_time
    if tonumber(cfg.lv_limit) <= module.HeroModule.GetManager():Get(11000).level then
        _view.root.middle.lv.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit)
    else
        _view.root.middle.lv.Text[UI.Text].text = "<color=#FF1514>"..SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit).."</color>"
    end
    _view.root.middle.mode.Text[UI.Text].text = cfg.parameter
--reward
    local _scrollView = _view.root.reward.ScrollView[CS.UIMultiScroller]
    local _reward = {}
    for i = 1, 3 do
        if cfg["reward_id"..i] ~= 0 then
            table.insert(_reward, {id = cfg["reward_id"..i], type = cfg["reward_type"..i], value = cfg["reward_value"..i] or 0})
        end
    end
    _scrollView.RefreshIconCallback = function(obj, idx)
        local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
        local _tab = _reward[idx + 1]
        utils.IconFrameHelper.Create(_objView.IconFrame, {id = _tab.id, type = _tab.type, count = _tab.value, showDetail = true})
        obj:SetActive(true)
    end
    _scrollView.DataCount = #_reward
--bottom
    local _lock, _infoTab = self:lockFunc(cfg,_activeCount)
    if _lock then
        _view.root.bottom.goWhere[CS.UGUISelectorGroup]:setGray()
    else
        _view.root.bottom.goWhere[CS.UGUISelectorGroup]:reset()
    end
    CS.UGUIClickEventListener.Get(_view.root.bottom.goWhere.gameObject).onClick = function()
        if _lock then
            showDlgError(nil, _infoTab.desc)
        else
            self:goWhere(cfg)
        end
    end

    CS.UGUIClickEventListener.Get(self.view.root.infoNode.mask.gameObject).onClick = function()
        self.view.root.infoNode:SetActive(false)
    end
------------活跃度-----------------
    -- local activitycfg = activityConfig.GetActivity(cfg.id)
    -- print(type(cfg.huoyuedu))
    -- self.huoyuedu1=0
    -- self.huoyuedu2=0
    -- if cfg.huoyuedu =="53|54" then
    --     self.huoyuedu1=53
    --     self.huoyuedu2=54
    -- elseif cfg.huoyuedu =="57|58" then
    --     self.huoyuedu1=57
    --     self.huoyuedu2=58
    -- else
    --     self.huoyuedu1= tonumber(cfg.huoyuedu)
    -- end
    -- _view.root.iconBg.activity:SetActive(self.huoyuedu1>0 or self.huoyuedu2>0 )
    -- -- ERROR_LOG("self.huoyuedu1------",self.huoyuedu1)
    -- -- ERROR_LOG("self.huoyuedu2------",self.huoyuedu2)
    -- -- ERROR_LOG("questModule.Get(self.huoyuedu1)----->>>",sprinttb(questModule.Get(self.huoyuedu1)))
    -- if self.huoyuedu2 ==0 then
    --     if questModule.Get(self.huoyuedu1) ~=nil then
    --         if questModule.Get(self.huoyuedu1).status~=1 then
    --             _view.root.iconBg.activity.ExpBar[UI.Scrollbar].size =0
    --             _view.root.iconBg.activity.ExpBar.number[UI.Text].text ="0".."/"..questModule.GetCfg(self.huoyuedu1)[1].cfg.raw.reward_value1
    --         else
    --             _view.root.iconBg.activity.ExpBar[UI.Scrollbar].size =1
    --             _view.root.iconBg.activity.ExpBar.number[UI.Text].text =questModule.GetCfg(self.huoyuedu1)[1].cfg.raw.reward_value1 .."/"..questModule.Get(self.huoyuedu1).cfg[1].cfg.raw.reward_value1
    --         end
    --     else
            
    --     end    
    -- else
    --     if not questModule.Get(self.huoyuedu2) then
    --         _view.root.iconBg.activity.ExpBar[UI.Scrollbar].size =0
    --         _view.root.iconBg.activity.ExpBar.number[UI.Text].text ="0".."/"..questModule.GetCfg(self.huoyuedu2)[1].cfg.raw.reward_value1
    --     elseif questModule.Get(self.huoyuedu2).status ~=1 then
    --         _view.root.iconBg.activity.ExpBar[UI.Scrollbar].size =0
    --         _view.root.iconBg.activity.ExpBar.number[UI.Text].text ="0".."/"..questModule.GetCfg(self.huoyuedu2)[1].cfg.raw.reward_value1
    --     else
    --         _view.root.iconBg.activity.ExpBar[UI.Scrollbar].size =1
    --         _view.root.iconBg.activity.ExpBar.number[UI.Text].text =questModule.GetCfg(self.huoyuedu2)[1].cfg.raw.reward_value1.."/"..questModule.GetCfg(self.huoyuedu2)[1].cfg.raw.reward_value1
    --     end
    -- end
end

function newMapSceneActivity:upTime(tab)
    if not tab then
        return
    end
    local _tab=tab._tab
    local total_pass=Time.now()-_tab.begin_time
    local period_pass=total_pass - math.floor(total_pass / _tab.period) * _tab.period
    local period_begin=0
    if period_pass >= _tab.loop_duration then
       period_begin=_tab.begin_time +math.ceil(total_pass / _tab.period) * _tab.period
    else
        period_begin=_tab.begin_time +math.floor(total_pass / _tab.period ) *_tab.period
    end 
    local _offTime =period_begin -Time.now()
    --ERROR_LOG("_offTime---->>",GetTimeFormat(_tab.begin_time,2))
    if _offTime >0 then
        tab._object.lock:SetActive(true)
       -- ERROR_LOG("tab-------->>>",sprinttb(_tab))
        --os.date("%H:%M开启",_tab.begin_time)
        return "<color=#FF0000FF>".._tab.activity_time.."开启".."</color>"
    else
        tab._object.lock:SetActive(false)
        local _endTime =_offTime + _tab.loop_duration
        if _endTime >0 then
           if _endTime >3600 then
             local hour=math.floor(_endTime/3600)
             local minute=math.floor((_endTime-hour*3600)/60)
             return  "剩余时间:"..hour.."时"..minute.."分" 
           else
             local minute=math.floor(_endTime/60)
             return  "剩余时间:".. minute.."分"
           end
        end
    end
end
function newMapSceneActivity:Update()
    if self._ActivetyList then
       for i,v in ipairs(self._ActivetyList) do
        v.object[UI.Text].text=self:upTime({_tab=v.tab,_object=v.object})
       -- ERROR_LOG("ding--->>>>>",v.object1.lockInfo.Text[UI.Text].text)
        if v.object1.lockInfo and v.object1.lockInfo.Text[UI.Text].text=="活动未开启" then
           v.object.lock:SetActive(true)
           v.object[UI.Text].text="<color=#FF0000FF>"..v.tab.activity_time.."开启".."</color>"
        else
           --v.object.lock:SetActive(false)
        end
       end
    end
end


function newMapSceneActivity:upMiddle(id)
    --ERROR_LOG("Time1---->>",math.floor(Time.now()))
    local _list = activityConfig.GetAllActivityTitle(1, id) or {} --——list是按钮相对的活动
      if id == 1004 then
          self.view.root.bg[CS.UGUISpriteSelector].index = 1
      else
          self.view.root.bg[CS.UGUISpriteSelector].index = 0
      end
    if id ==1002 then
        self.view.root.middle.childRoot1:SetActive(true)
        self.view.root.middle.childRoot2:SetActive(false)
        self.view.root.middle.childRoot3:SetActive(false)
        self.view.root.middle.childRoot4:SetActive(false)
        if self.view.root.middle.childRoot1.transform.childCount ==0 then
            DialogStack.PushPref("mapSceneUI/newSceneActivity", {id=id}, self.view.root.middle.childRoot1)
        end
    elseif id ==1004 then
        self.view.root.middle.childRoot2:SetActive(true)
        self.view.root.middle.childRoot1:SetActive(false)
        self.view.root.middle.childRoot3:SetActive(false)
        self.view.root.middle.childRoot4:SetActive(false)
        if self.view.root.middle.childRoot2.transform.childCount ==0 then
            DialogStack.PushPref("mapSceneUI/newSceneActivity", {id=id}, self.view.root.middle.childRoot2)
        end
    elseif id ==1005 then
        self.view.root.middle.childRoot3:SetActive(true)
        self.view.root.middle.childRoot1:SetActive(false)
        self.view.root.middle.childRoot2:SetActive(false)
        self.view.root.middle.childRoot4:SetActive(false)
        if self.view.root.middle.childRoot3.transform.childCount ==0 then
            DialogStack.PushPref("mapSceneUI/newSceneActivity", {id=id}, self.view.root.middle.childRoot3)
        end
    elseif id ==1003 then
        self.view.root.middle.childRoot4:SetActive(true)
        self.view.root.middle.childRoot1:SetActive(false)
        self.view.root.middle.childRoot2:SetActive(false)
        self.view.root.middle.childRoot3:SetActive(false)
        if self.view.root.middle.childRoot4.transform.childCount ==0 then
            DialogStack.PushPref("mapSceneUI/newSceneActivity", {id=id}, self.view.root.middle.childRoot4)
        end
    end
 end

function newMapSceneActivity:getTittleIdx(list, data)
    if data and data.activityId then
        for i,v in ipairs(list) do
            for k,p in pairs(activityConfig.GetAllActivityTitle(1, v.id)) do
                if p.id == data.activityId then
                    self.savedValues.idx = (i - 1)
                    self.idx = (i - 1)
                    self.showTittleCfg = p
                end
            end
        end
    end
end

function newMapSceneActivity:initBottom(data)
    local _cfg = activityConfig.GetBaseTittleByType(1)
    local _list = {}
    for k,v in pairs(_cfg) do
        if data.filter then
            if data.filter.flag then            --正选
                if v.id == data.filter.id then
                    table.insert(_list, v)
                end
            elseif v.id ~= data.filter.id then  --反选
                table.insert(_list, v)
            end
        else
            table.insert(_list, v)
        end
    end
    table.sort(_list, function(a, b)--_List存放的是按钮
        return a.id < b.id
    end)
    self.view.root.bottom:SetActive(data.filter == nil or not data.filter.flag);

    self:getTittleIdx(_list, data)
    self.bottomScrollView = self.view.root.bottom.ScrollView[CS.UIMultiScroller]
    self.bottomScrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = _list[idx + 1]
        _view.Toggle.Background.name[CS.UGUISpriteSelector].index = _cfg.id - 1002;

        _view.Image:SetActive((idx + 1) ~= #_list)
        _view.Toggle.Background.name.pvp:SetActive(_cfg.id == 1003)
        self.view.root.bottom.ScrollView.Viewport.Content.selectImage:SetActive(true)

        _view.Toggle.Label1.info:SetActive(false)
        if _cfg.activity_id ~= 0 then
            local _one, _ten = module.CemeteryModule.Query_Pve_Schedule(_cfg.activity_id)
            if _one and _ten then
                local _number = _one + _ten
                if _number >= 1 then
                    _view.Toggle.Label1.info[UI.Text].text = "<color=#00FF00>"..SGK.Localize:getInstance():getValue("common_cishu_02", _one + _ten).."</color>"
                else
                    _view.Toggle.Label1.info[UI.Text].text = "<color=#FF0000>"..SGK.Localize:getInstance():getValue("common_cishu_02", _one + _ten).."</color>"
                end
                _view.Toggle.Label1.info:SetActive(true)
            end
        end

        _view.Toggle[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
            if value then
                self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform:DOMove(Vector3(_view.Toggle.Background.transform.position.x, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.y, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.z), 0.2):SetEase(CS.DG.Tweening.Ease.OutBack)
            end
            _view.Toggle.Label1:SetActive(value)
        end)
        _view.Toggle[UI.Toggle].isOn = (idx == self.idx)
        CS.UGUIClickEventListener.Get(_view.Toggle.gameObject, true).onClick = function()
            self.idx = idx
            self.savedValues.idx = self.idx
            self._id=_cfg.id
            self:upMiddle(self._id)
        end
        obj:SetActive(true)
    end
    self.bottomScrollView.DataCount = #_list
    self.view.root.bottom.ScrollView.Viewport.Content[UnityEngine.RectTransform].rect.width = self.view.root.bottom.ScrollView.Viewport.Content[UnityEngine.RectTransform].rect.width + 50
    self.bottomScrollView:ScrollMove(self.idx)
    local _obj = self.bottomScrollView:GetItem(self.idx)
    if _obj then
        local _objView = CS.SGK.UIReference.Setup(_obj.gameObject)
        _objView.Toggle[UI.Toggle].isOn = true
        _objView.Toggle.Label1:SetActive(true)
        self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position = Vector3(_objView.Toggle.Background.transform.position.x, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.y, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.z)
        self._id=_list[self.idx+1].id
        self:upMiddle(self._id)
    end
    if self.showTittleCfg then
        if self.showTittleCfg.isunique == 0 then
            self.view.root.infoNode:SetActive(true)
            self:upInfoNode(self.showTittleCfg)
        else
            DialogStack.PushPrefStact("TeamPveEntrance", {gid = self.showTittleCfg.isunique})
        end
        self.showTittleCfg = nil
    end
end

-- function newMapSceneActivity:deActive()
--     utils.SGKTools.PlayDestroyAnim(self.view)
--     return true
-- end

function newMapSceneActivity:initGuide()
    module.guideModule.PlayByType(118,0.5)
end

function newMapSceneActivity:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "REFRESH_THE_TITLE",
    }
end

function newMapSceneActivity:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        -- self:upTop()--屏蔽顶部活跃度
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event =="REFRESH_THE_TITLE" then
        local _cfg=data.tab
        if _cfg.isunique == 0 then
            self.view.root.infoNode:SetActive(true)
            self:upInfoNode(_cfg)
        else
            DialogStack.PushPrefStact("TeamPveEntrance", {gid = _cfg.isunique, notPush = true})
        end
    end
end

return newMapSceneActivity
