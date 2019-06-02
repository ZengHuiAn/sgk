local achievementModule = require "module.AchievementModule"
local newAchievement = {}

function newAchievement:Start(data)
    data = data or {}
    if data and data.idx then
        self.toogle = data.idx
        self.second = data.second  or -1
    end

    if self.toogle == 0 then
        self.second = nil
    end

    self:initData()
    self:initUi()
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
end

function newAchievement:initData()
    self.titileList = achievementModule.GetFistCfg()
    self.childCfg = {
        [1] = {name = "newAchievement/newAchievementAll"},
        [2] = {name = "newAchievement/newAchievementInfo"},
    }
    self.childList = {}
    self.loadLock = true
end

function newAchievement:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
end

function newAchievement:loadChild(i, data)
    for k,v in pairs(self.childList) do
        v:SetActive(false)
    end
    local height = (i == 1) and 307 or 170
    self.view.root.bg_mask[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.root.bg_mask[UnityEngine.RectTransform].sizeDelta.x,height);
    if self.childList[i] then
        self.childList[i]:SetActive(true)
        self.childList[i]:GetComponent(typeof(SGK.LuaBehaviour)):Call("refresh", data)
    else
        if self.loadLock then
            self.loadLock = false
            DialogStack.PushPref(self.childCfg[i].name, data, self.view.root.childRoot.transform, function(obj)
                self.loadLock = true
                self.childList[i] = obj
            end)
        end
    end
end

function newAchievement:initScrollView()
    self.view.root.ScrollView.Viewport.Content[CS.ScrollViewContent].RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject).root
        local _cfg = self.titileList[idx]
        if _cfg then
            _view.Toggle.name[UI.Text].text = _cfg.name
            _view.Toggle.red:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.FirstAchievenment, _cfg.id) > 0)
        else
            _view.Toggle.name[UI.Text].text = "总览"
            _view.Toggle.red:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.Achievement))
        end
        CS.UGUIClickEventListener.Get(_view.Toggle.gameObject).onClick = function()
            
        end
        _view.Toggle[UI.Toggle].onValueChanged:RemoveAllListeners()
        
        _view.Toggle[UI.Toggle].onValueChanged:AddListener(function ( status )
            
            _view.Toggle.name[UI.Text].color = status and UnityEngine.Color.black or UnityEngine.Color.white;
            if status then
                if _cfg then
                    self:loadChild(2, {idx = _cfg.id,second = self.second})
                    self.second = nil
                else
                    self:loadChild(1)
                end
            end
        end)

        obj:SetActive(true)
    end
    self.view.root.ScrollView.Viewport.Content[CS.ScrollViewContent].DataCount = (#self.titileList + 1)

    
    local function UpdateFirst( ... )
        local _obj = self.view.root.ScrollView.Viewport.Content[CS.ScrollViewContent]:GetItem(self.toogle)
        if _obj then
            local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
            _view.root.Toggle[UI.Toggle].isOn = true
            _view.root.Toggle.name[UI.Text].color = UnityEngine.Color.black
            -- self.dropdown:RefreshShownValue();
        end
        ERROR_LOG(self.toogle);
        if self.toogle then
            local item = self.view.root.ScrollView.Viewport.Content[CS.ScrollViewContent]:GetItem(self.toogle);
            if item then
                local _view = CS.SGK.UIReference.Setup(item.gameObject).root
                _view.Toggle[UI.Toggle].onValueChanged:Invoke();
                _view.Toggle.name[UI.Text].color = UnityEngine.Color.black
            end
        else
            self:loadChild(1)
        end

    end
    self.update = UpdateFirst
end

function newAchievement:Update( ... )

    if self.update then
        self.update();
        self.update = nil
    end
    if self.isfresh then
        self.view.root.ScrollView.Viewport.Content[CS.ScrollViewContent]:ItemRef()
        self.isfresh = nil
    end
end

function newAchievement:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newAchievement:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.type == 31 or data.type == 30 then
            self.isfresh = true
        end
    end
end

return newAchievement
