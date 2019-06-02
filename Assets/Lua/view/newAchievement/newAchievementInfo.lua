local achievementModule = require "module.AchievementModule"
local newAchievementInfo = {}
local AchievementPool = CS.GameObjectPool.GetPool("Achievement");


function newAchievementInfo:Start(data)
    self.index = data.idx;
    self.second = data.second or -1;
    ERROR_LOG("-----------",self.second);
    
    self:initData(data)
    self:initUi()
    self:refreshAll();
end

function newAchievementInfo:refresh(data)
    self.select = 0;
    self:upData(data)
    self:initUi()
    self:refreshAll();
end

function newAchievementInfo:initData(data)
    self.firstViewList = {}
    self.sViewList = {}
    self:upData(data)

end

function newAchievementInfo:upData(data)
    if data then
        self.firstList = achievementModule.GetFirstQuest(data.idx)
        self.index = data.idx;
        self.flag_list = {}
        for k,v in pairs(self.firstList) do
            table.insert( self.flag_list, k )
        end

        table.sort( self.flag_list, function ( a,b )
            return a <b;
        end )
        -- self:refreshAll();
    end
end

function newAchievementInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    
    self:initScrollView()
end

function newAchievementInfo:refreshAll()
    self.view.root.bg.ExpBar[UI.Scrollbar].size = achievementModule.GetFinishCount(self.index) / #achievementModule.GetCfg(nil, self.index);
    self.view.root.bg.ExpBar.Text[UI.Text].text = achievementModule.GetFistCfg()[self.index].name;
    self.view.root.bg.ExpBar.number[UI.Text].text  = achievementModule.GetFinishCount(self.index) .."/".. #achievementModule.GetCfg(nil, self.index)
end



function newAchievementInfo:refreshNone(data,idx,obj,data)

end

function newAchievementInfo:initScrollView(isChange)
    -- ERROR_LOG(sprinttb(self.firstViewList));
    if not isChange then
        for i,v in pairs(self.firstViewList) do
            CS.UnityEngine.GameObject.Destroy(v.gameObject)
        end
        self.firstViewList = {}
        self.sViewList = {}
    end

    -- ERROR_LOG(sprinttb(self.firstList));
    self.select = -1
    local content1 = self.view.root.bg.ScrollView.Viewport.Content.smallTitle1
    self.content1 = content1
    local detail = self.view.root.bg.ScrollView.Viewport.Content.detail
    self.detail = detail
    local content2 = self.view.root.bg.ScrollView.Viewport.Content.smallTitle2
    self.content2 = content2
    detail[CS.ScrollViewContent].RefreshIconCallback = (function (Obj,idx)
        local i = idx +1
        local p = self._tempList[i]
        -- ERROR_LOG(sprinttb(p));
        local _sObj =Obj
        local _sView = SGK.UIReference.Setup(_sObj)
        -- ERROR_LOG(p.name,p.button_des);
        _sView.root.name[UI.Text].text = p.name
        _sView.root.desc[UI.Text].text = p.button_des
        local rewardCfg = module.QuestModule.Get(p.next_id)
        
        _sView.root.time[UI.Text].text = os.date(SGK.Localize:getInstance():getValue("chengjiu_03"), p.finish_time)
                _sView.root.rewardList:SetActive(not rewardCfg or rewardCfg.status~=1)
                local Config = module.QuestModule.GetCfg(p.next_id);
                for i=1,2 do
                    local _rView = _sView.root.rewardList["reward"..i];
                    local _rCfg = Config.reward[i];
                    if _rCfg then
                        _rView:SetActive(_rCfg)
                        utils.IconFrameHelper.Create(_rView, {id = tonumber(_rCfg.id), type =tonumber(_rCfg.type), showDetail = true, count = tonumber(_rCfg.value)})
                    end
                end
                
                local isRed = module.QuestModule.CanSubmit(p.next_id);
                
                
                _sView.root.bg.tishi:SetActive(isRed)
                _sView.root.time:SetActive(rewardCfg and rewardCfg.status == 1)
                _sView.root.getBtn:SetActive(not rewardCfg or rewardCfg.status ~= 1)
                -- _sView.rewardList[CS.UIMultiScroller].DataCount = #(p.reward or {})
                local _material = nil
                if not _sView.root.bg.tishi.activeSelf then
                    _material = SGK.QualityConfig.GetInstance().grayMaterial
                end
                _sView.root.getBtn[UI.Image].material = _material
                local _record = module.QuestModule.GetOtherRecords(p, 1)
                local _conditionValue = p.condition[1].count
                
                -- ERROR_LOG();
                _sView.root.bg.ExpBar[UI.Scrollbar].size = _record / _conditionValue
                
                _sView.root.bg.ExpBar.number[UI.Text].text = (_record >_conditionValue and _conditionValue or _record).. "/".. _conditionValue
                
                _sView.root.bg[CS.UGUISpriteSelector].index = (not rewardCfg or rewardCfg.status ~= 1) and 0 or 1
                
                CS.UGUIClickEventListener.Get(_sView.root.getBtn.gameObject).onClick = function()
                    if _sView.root.bg.tishi.activeSelf then
                        _sView.root.getBtn[CS.UGUIClickEventListener].interactable = false
                        _sView.root.getBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                        coroutine.resume(coroutine.create(function()
                    module.QuestModule.Finish(rewardCfg.id)
                    _sView.root.getBtn[CS.UGUIClickEventListener].interactable = true
                    _sView.root.getBtn[UI.Image].material = nil
                end))
            end
        end
    end)
    content2[CS.ScrollViewContent].RefreshIconCallback = (function (Obj,idx)
        local index = idx +1
        local view_data = self.flag_list[index+content2[CS.ScrollViewContent].DataCount];
        local _firstCfg = module.QuestModule.GetCfg(view_data)
        local v = self.firstList[view_data]
        -- ERROR_LOG(sprinttb(self.firstList),index);
        local _view = SGK.UIReference.Setup(Obj)
        
        _view.top.name[UI.Text].text = _firstCfg.name
        local _redCount = module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.SecAchievement, _firstCfg.id)
        _view.top.red:SetActive(_redCount > 0)
        local _tempList = {}
        local _finishCount = 0
        for i,p in ipairs(v) do
            local _questCfg = module.QuestModule.Get(p.Third_quest_id)
            if _questCfg then
                if _questCfg.status == 1 then
                    _finishCount = _finishCount + 1
                end
                table.insert(_tempList, _questCfg)
            end
            -- ERROR_LOG("---------------->>>>",sprinttb(_questCfg));
        end


        table.sort(_tempList, function(a, b)
            local _aId = a.id
            local _bId = b.id
            if a.status == 1 then
                _aId = _aId + 10000
            end
            if b.status == 1 then
                _bId = _bId + 10000
            end
            if module.QuestModule.CanSubmit(a.next_id) then
                _aId = _aId - 100000
            end
            if module.QuestModule.CanSubmit(b.next_id) then
                _bId = _bId - 100000
            end
            return _bId > _aId
        end)
        local _redCount = module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.SecAchievement, _firstCfg.id)
        _view.top.red:SetActive(_redCount > 0)
        
        -- ERROR_LOG(_finishCount);
        _view.top.ExpBar.number[UI.Text].text = _finishCount.."/"..#_tempList
        _view.top.ExpBar[UI.Scrollbar].size = _finishCount / #_tempList

        _view.top.bg[UI.Toggle].onValueChanged:RemoveAllListeners()
        -- _view.top.arr.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,0,-180));
        -- _view.top.bg[UI.Toggle].onValueChanged:AddListener(function(status)
        --     print(idx,status,self.select)
        --     if status then
                
        --     else
        --         _view.top.arr.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,0,-180));
        --     end
        -- end);
        CS.UGUIClickEventListener.Get(_view.top.bg.gameObject,true).onClick = function (obj)

            print("=====",idx)
            _view.top.arr.transform:DORotate(Vector3(0, 0, 0), 0.2)
            self.select = content1[CS.ScrollViewContent].DataCount + idx +1
            detail[CS.ScrollViewContent].DataCount = #_tempList
            content1[CS.ScrollViewContent].DataCount = self.select
            content2[CS.ScrollViewContent].DataCount = #self.flag_list - self.select
            self._tempList = _tempList
        end

        _view.top.bg[CS.UGUISpriteSelector].index = 1
        _view.top.arr.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,0,-180));
        print("========",idx,self.select)

    end)
    -- content1[CS.ScrollViewContent].DataCount = #self.flag_list
    content1[CS.ScrollViewContent].RefreshIconCallback = (function (Obj,idx)
        local index = idx +1
        local view_data = self.flag_list[index];
        local _firstCfg = module.QuestModule.GetCfg(view_data)
        local v = self.firstList[view_data]
        -- ERROR_LOG(view_data,sprinttb(self.firstList),index);
        local _view = SGK.UIReference.Setup(Obj)
        
        _view.top.name[UI.Text].text = _firstCfg.name
        local _redCount = module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.SecAchievement, _firstCfg.id)
        _view.top.red:SetActive(_redCount > 0)
        local _tempList = {}
        local _finishCount = 0
        for i,p in ipairs(v) do
            local _questCfg = module.QuestModule.Get(p.Third_quest_id)
            if _questCfg then
                if _questCfg.status == 1 then
                    _finishCount = _finishCount + 1
                end
                table.insert(_tempList, _questCfg)
            end
            -- ERROR_LOG("---------------->>>>",sprinttb(_questCfg));
        end
        table.sort(_tempList, function(a, b)
            local _aId = a.id
            local _bId = b.id
            if a.status == 1 then
                _aId = _aId + 10000
            end
            if b.status == 1 then
                _bId = _bId + 10000
            end
            if module.QuestModule.CanSubmit(a.next_id) then
                _aId = _aId - 100000
            end
            if module.QuestModule.CanSubmit(b.next_id) then
                _bId = _bId - 100000
            end
            return _bId > _aId
        end)
        local _redCount = module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.SecAchievement, _firstCfg.id)
        _view.top.red:SetActive(_redCount > 0)
        
        -- ERROR_LOG(_finishCount);
        _view.top.ExpBar.number[UI.Text].text = _finishCount.."/"..#_tempList
        _view.top.ExpBar[UI.Scrollbar].size = _finishCount / #_tempList

        _view.top.bg[UI.Toggle].onValueChanged:RemoveAllListeners()
        CS.UGUIClickEventListener.Get(_view.top.bg.gameObject,true).onClick = function (obj)


            if (content1[CS.ScrollViewContent].DataCount == idx + 1 and self.select ~= -1) then
                self.select = -1
                detail[CS.ScrollViewContent].DataCount = 0
                content1[CS.ScrollViewContent].DataCount = #self.flag_list
                content2[CS.ScrollViewContent].DataCount = 0
                self._tempList = nil
            else
                
                self.select = idx +1
                detail[CS.ScrollViewContent].DataCount = #_tempList
                content1[CS.ScrollViewContent].DataCount = self.select
                content2[CS.ScrollViewContent].DataCount = #self.flag_list - self.select
                self._tempList = _tempList
            end
        end
        if self.select == -1 then
            _view.top.bg[CS.UGUISpriteSelector].index = 1
            _view.top.arr.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,0,-180));
        else
            if self.select == idx +1 then
                _view.top.arr.transform:DORotate(Vector3(0, 0, 0), 0.2)
            else
                _view.top.arr.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,0,-180));
            end
            _view.top.bg[CS.UGUISpriteSelector].index = self.select == idx +1  and 0 or 1
        end
    end)
    content1[CS.ScrollViewContent].DataCount = #self.flag_list
    detail[CS.ScrollViewContent].DataCount = 0

    if self.second and self.second ~= -1 then
        self.callback = function ( ... )

            local item_obj = content1[CS.ScrollViewContent]:GetItem(self.second);
            ERROR_LOG(self.second,item_obj);
            if item_obj then
                ERROR_LOG("+++++>>>error2");

                    -- content1[CS.ScrollViewContent].DataCount
                    local item_obj = content1[CS.ScrollViewContent]:GetItem(self.second);
                    local _view = CS.SGK.UIReference.Setup(item_obj.gameObject)
                    if CS.UGUIClickEventListener.Get(_view.top.bg.gameObject,true).onClick then
                        CS.UGUIClickEventListener.Get(_view.top.bg.gameObject,true).onClick();
                    end
            else
                ERROR_LOG("+++++>>>error");
            end
            self.second = -1
        end
    end
    StartCoroutine(function ( ... )
        WaitForEndOfFrame()
        WaitForSeconds(0.1)
        if self.callback then
            self.callback()
        end
    end)
end

function newAchievementInfo:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newAchievementInfo:Update( ... )
    -- if self.next_update_time and self.next_update_time ~=0 then
        
    --     if self.callback then
            
    --         self.callback = nil
    --     end
    -- end
end

function newAchievementInfo:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.type == 31 then
            self.content1[CS.ScrollViewContent]:ItemRef()
            self.content2[CS.ScrollViewContent]:ItemRef()
            self.detail[CS.ScrollViewContent]:ItemRef()
        end
    end
end

return newAchievementInfo
