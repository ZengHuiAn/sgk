local openLevel = require "config.openLevel"
local selectMap = {}

function selectMap:Start(data)
    self.data = data
    self.openFlag = false
    if data and data.openFlag then
        self.openFlag = data.openFlag
    end
    self:initData(data)
    self:initUi()
    module.guideModule.PlayByType(1100, 0.3)
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
end

function selectMap:initData(data)
    self.cfg = {}
    local _list = module.fightModule.GetConfig()
    for k,v in pairs(_list) do
        if v.group == 1 then
            table.insert(self.cfg, v)
        end
    end
    table.sort(self.cfg, function(a, b)
        return a.chapter_id < b.chapter_id
    end)
    self.childeList = {}
    self.childCfg = {
        [1] = {name = "newSelectMap/selectChapter"},
        [2] = {name = "newSelectMap/selectChapter"},
        [3] = {name = "newSelectMap/newSelectTeam"},
        [4] = {name = "newSelectMap/selectChapter"},
    }
    if data then
        if data and data.idx then
            self.savedValues.idx = data.idx
        end
    end
    self.idx = self.savedValues.idx or 1
end

function selectMap:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
end

function selectMap:initScrollView()
    --self.scrollView = self.view.root.bottom.ScrollView[CS.UIMultiScroller]
    --self.scrollView.RefreshIconCallback = function (obj, idx)
    for idx=0,2 do
        local obj = self.view.root.bottom.itemNode["item"..(idx+1)]
        local _view = CS.SGK.UIReference.Setup(obj)
        local _cfg = self.cfg[idx + 1]
        _view.Toggle1.name[UI.Text].text = _cfg.name
        _view.Toggle1.namePng[CS.UGUISpriteSelector].index = idx
        _view.Toggle1[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view.Toggle1[UI.Toggle].onValueChanged:AddListener(function(value)
            if value then
                self.view.root.bottom.image.transform:DOMove(Vector3(_view.Toggle1.transform.position.x, self.view.root.bottom.image.transform.position.y, self.view.root.bottom.image.transform.position.z), 0.2):SetEase(CS.DG.Tweening.Ease.OutBack)
            end
            _view.Toggle1.arr:SetActive(value)
        end)
        local _status = true
        if _cfg.open_lv_id ~= 0 then
            _status = openLevel.GetStatus(_cfg.open_lv_id)
        end
        if _status then
            _view.Toggle1.namePng[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
        else
            _view.Toggle1.namePng[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
        end
        _view.Toggle1[UI.Toggle].interactable = _status
        _view.Toggle1[UI.Toggle].isOn = ((idx + 1) == self.idx)
        if _cfg.open_lv_id ~= 0 then
            _view.lock.Text[UI.Text].text = openLevel.GetCloseInfo(_cfg.open_lv_id)
        end
        _view.bg:SetActive(idx + 1 ~= #self.cfg)
        CS.UGUIClickEventListener.Get(_view.Toggle1.gameObject).onClick = function()
            if _status then
                self.idx = idx + 1
                self.savedValues.idx = self.idx
                self:showChilde(self.idx, {chapterId = _cfg.chapter_id,openFlag = self.openFlag})
            else
                _view.lock:SetActive(true)
                _view.lock.transform:DOLocalMove(Vector3(0, 0, 0), 0.5):SetRelative(true):OnComplete(function()
                    _view.lock:SetActive(false)
                end)
            end
        end
        obj:SetActive(true)
    end
    --self.scrollView.DataCount = #self.cfg
    local _obj = self.view.root.bottom.itemNode["item1"]
    if _obj then
        local _view = CS.SGK.UIReference.Setup(_obj)
        _view.Toggle1[UI.Toggle].isOn = true
        _view.Toggle1.arr:SetActive(true)
        self.view.root.bottom.image.transform.position = Vector3(_view.Toggle1.transform.position.x, self.view.root.bottom.image.transform.position.y, self.view.root.bottom.image.transform.position.z)
    end
    self:showChilde(self.idx, {chapterId = self.cfg[self.idx].chapter_id,openFlag = self.openFlag})
    self.view.root.bottom.itemNode["item"..self.idx].Toggle1[UI.Toggle].isOn = true
end

function selectMap:showChilde(i, data)
    if self.childCfg[i] then
        if self.childeList[i] then
            for k,v in pairs(self.childeList) do
                self.childeList[k]:SetActive(k == i)
            end
        else
            self.loadLock = true
            self.savedValues.selectMapData = {chapterId = self.cfg[self.idx].chapter_id,openFlag = self.openFlag}
            SGK.ResourcesManager.LoadAsync("prefabs/"..self.childCfg[i].name .. ".prefab",function(Obj)
                local obj = CS.UnityEngine.GameObject.Instantiate(Obj.transform,self.view.root.childRoot.gameObject.transform) 
                obj.name = "selectChapter_" .. i;
                local _view = CS.SGK.UIReference.Setup(obj)
                --_view.gameObject.transform.parent = self.view.root.childRoot.gameObject.transform;
                _view[SGK.LuaBehaviour]:Call("init",data)
                self.loadLock = false
                self.childeList[i] = obj.gameObject
                for k,v in pairs(self.childeList) do
                    self.childeList[k]:SetActive(k == i)
                end
                -- module.fightModule.SetNowSelectChapter({chapterId=1010, idx = 1, difficultyIdx = 1, chapterNum = 1})
                -- SceneStack.Push("newSelectMapUp")
            end)
        end
    end
end

function selectMap:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function selectMap:listEvent()
    return {
        "LOCAL_GUIDE_CHANE",
    }
end

function selectMap:onEvent(event, data)
    if event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(1100)
    end
end

return selectMap
