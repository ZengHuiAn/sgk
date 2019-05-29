local fightNote = {}

function fightNote:Start()
    self:initData()
    self:initUi()
end

function fightNote:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
end

function fightNote:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.questList[idx + 1]
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(rObj ,rIdx)
            local _rView = CS.SGK.UIReference.Setup(rObj.gameObject)
            local _rCfg = _cfg.reward[rIdx + 1]
            utils.IconFrameHelper.Create(_rView.IconFrame, {type = _rCfg.type, id = _rCfg.id, count = _rCfg.value, showDetail = true})
            rObj:SetActive(true)
        end
        _view.root.ScrollView[CS.UIMultiScroller].DataCount = #_cfg.reward
        _view.root.getBtn:SetActive(false)
        _view.root.goBtn:SetActive(false)
        _view.root.done:SetActive(false)

        _view.root.getBtn:SetActive(module.QuestModule.CanSubmit(_cfg.id))
        _view.root.goBtn:SetActive(not _view.root.getBtn.activeSelf and (_cfg.status ~= 1))
        _view.root.done:SetActive(_cfg.status == 1)

        _view.root.ExpBar[UI.Scrollbar].size = module.QuestModule.GetOtherRecords(_cfg, 1) / _cfg.condition[1].count
        _view.root.ExpBar.number[UI.Text].text = module.QuestModule.GetOtherRecords(_cfg, 1).."/".._cfg.condition[1].count

        CS.UGUIClickEventListener.Get(_view.root.getBtn.gameObject).onClick = function()
            _view.root.getBtn[CS.UGUIClickEventListener].interactable = false
            _view.root.getBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(_cfg.uuid)
                _view.root.getBtn[CS.UGUIClickEventListener].interactable = true
                _view.root.getBtn[UI.Image].material = nil
            end))
        end
        CS.UGUIClickEventListener.Get(_view.root.goBtn.gameObject).onClick = function()
            DialogStack.Pop()
            DialogStack.Push("newSelectMap/newGoCheckpoint", {gid = _cfg.event_id1})
        end

        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.questList
end

function fightNote:initData()
    local _list = module.QuestModule.GetList(16)
    self.questList = {}
    for k,v in pairs(_list) do
        if v.status == 0 then
            table.insert(self.questList, v)
        end
    end
    table.sort(self.questList, function(a, b)
        local _idA = a.id
        local _idB = b.id
        if module.QuestModule.CanSubmit(a.id) then
            _idA = _idA - 1000
        end
        if module.QuestModule.CanSubmit(b.id) then
            _idB = _idB - 1000
        end
        if a.status == 1 then
            _idA = _idA + 1000
        end
        if b.status == 1 then
            _idB = _idB + 1000
        end
        return _idA < _idB
    end)
end

function fightNote:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function fightNote:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        self:initData()
        self.scrollView.DataCount = #self.questList
        --self.scrollView:ItemRef()
    end
end


return fightNote
